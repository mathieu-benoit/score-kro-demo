# Lessons learned with Kro

We explored KRO because we liked the concept, but we quickly found that its basic approach didn’t fit our day-to-day needs as engineers. As discussed in the Reddit thread, many teams with advanced requirements hit similar limitations.

Our goal:
Provide developers a simple way to deploy applications using a predefined `CustomResource` designed by platform engineers, following best practices.

You can easily predefine standard configurations (resource limits, probes, securityContext, etc.) for simple apps. But as soon as developers need to adjust basic values like environment variables or ports, we hit limitations — and documentation was lacking.

We collected our learnings below.

TOC:
- [Lessons learned with Kro](#lessons-learned-with-kro)
    - [Generic Type Limitations](#generic-type-limitations)
  - [Complex types limitations](#complex-types-limitations)
  - [Namespace Limitations](#namespace-limitations)
  - [Day-2 Operations Limitations](#day-2-operations-limitations)
  - [A new attack surface? FIXME](#a-new-attack-surface-fixme)
  - [Is KRO mature enough for production?](#is-kro-mature-enough-for-production)
  - [Improvement Ideas for KRO](#improvement-ideas-for-kro)

### Generic Type Limitations

We wanted a simple way to let developers define environment variables — just a list of key/value pairs. However, KRO didn’t support this directly.

We ended up defining custom types:

```yaml
types:
  port:
    name: string
    protocol: string
    containerPort: integer | required
  envVar:
    name: string
    value: string
```

Then used them like this:

```yaml
spec:
  schema:
    ...
    env: "[]envVar"
```

Example developer CR:

```yaml
apiVersion: kro.run/v1alpha1
kind: Workload
metadata:
  name: podinfo-app
  namespace: test
spec:
  env:
    - name: PODINFO_UI_COLOR
      value: "#34577c"
    - name: PODINFO_UI_MESSAGE
      value: ""
```

<img src="../images/demo-1.png" alt="rounded image" width="1000" style="border-radius:7%;" />

You are limited to simple types (`string`, `integer`, `boolean`, `float`). For anything more complex (arrays, objects, maps), you should define custom types manually.

## Complex types limitations

You are maybe asking why not just to try to define more complex types directly in KRO?

Example: creating more complex types like `rbacRule`:

```yaml
types:
  rbacRule:
    apiGroups: "[]string"
    resources: "[]string"
    verbs: "[]string"

rbacRules: "[]rbacRule"
```

So you can see. You need to create a new type which contains arrays of strings. And then you will create an array of this new type.

Or nested maps:

```yaml
values:
  clusterRole:
    labels: 'map[string]string | default={"eks.amazonaws.com/component": "coredns", "k8s-app": "kube-dns"}'
```

One limitation of CEL is that it is intentionally not Turing-complete — it does not support loops such as for or while, or recursive functions, and only allows simple expressions using filters or functions like all() and exists() over arrays.

## Namespace Limitations

Another issue: creating `Workload` CRs in the same namespace as the app.
If the namespace doesn’t exist yet, you can’t apply the CR (it’s namespace-scoped).
We had to add a workaround — deploying a `Namespace` manifest with Argo CD before the `Workload` CR.

Example:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: kro-man-podinfo
  labels:
    app.kubernetes.io/managed-by: argocd
    pod-security.kubernetes.io/enforce: restricted
```

However, this feels wrong — developers shouldn’t deal with PodSecurityStandards (PSS) or namespaces.
Those should be handled by the platform or tool itself, not as an add step.

We explored various workarounds (default vs. restricted namespaces, flags, conditional logic), but it became messy and unmaintainable.
This led us to reconsider using KRO as the main deployment mechanism.

## Day-2 Operations Limitations

Even if you solve Day-1 issues, Day-2 operations remain challenging.
As a platform team, you want to offer **self-service for developers** while also enforcing **golden paths and operational safety**.

Let’s say the platform team updates the `Workload` definition to version `v2` — adding or removing fields like:

```yaml
- id: serviceAccount2
  template:
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: ${schema.metadata.name}-2
```

Developers get no notification or migration path.
Removed fields aren’t cleaned up, and redeployments can fail due to strict decoding errors.

You can version the RGD, but without an upgrade process, migration is painful — a common Day-2 challenge.

Using Score can help here, thanks to templating, versioning, and validation, but that also means skipping KRO entirely.

## A new attack surface? FIXME

When many applications and infrastructure components are created from a single CustomResource definition based on an RGD, a small change to that RGD can have big consequences.

If an attacker can modify the RGD, they could add a deployment that uses a malicious container image. That change would be applied to every CustomResource that depends on the RGD, effectively pushing the compromise to all derived workloads.
This risk is amplified because there is often no version pinning or strong validation in place. There may be no SHA256 checks, no signature verification, and no easy way to require reviewed or signed changes. That makes it easy for a single unauthorized or unreviewed modification to escalate into a widespread security incident.

This shows the need for strict access control, clear change review processes, and image verification to protect the platform and the teams that rely on it.

## Is KRO mature enough for production?

We’re not against KRO — it’s a great idea — but for production-grade use cases, it feels too early. But it also still a young project.
We wanted to understand why so many teams struggle with abstraction tools like KRO and share the insights with you and also with the KRO project.

But you also should keep in mind, that just few tools like KRO exists, which are not a tools for composing Kubernetes resources for simple applications, it would already be useful — but it can do much more. KRO allows you to compose any kind of resource within Kubernetes, including cloud resources such as AWS S3 Buckets or RDS Instances by using the AWS Controllers for Kubernetes (ACK) or GCP Config Connector (KCC) or Azure Service Operator (ASO).

KRO still has its limitations, but when combined with tools like Score, you can overcome many of them and get the best of both worlds. Of course, this adds another layer of complexity, so you need to decide what kind of self-service experience you want to provide to your developers.

The key takeaway is that you need to understand your specific use case — abstraction can be both helpful and harmful, depending on how and where you apply it.

## Improvement Ideas for KRO

* **Namespace creation:** Add a flag in the CustomResource to auto-create namespaces if they don’t exist.
* **Dry-run CLI:** A `kro --dry-run` command to preview generated resources.
* **More complex examples:** Include documentation for advanced use cases (e.g. generic types).
* **Better Day-2 operations support:**
  * Handling new RGD versions gracefully.
  * Automatic field addition/removal with proper synchronization.
* **Improved developer experience:**
  * Clearer logs and event messages.
  * More accessible error handling (not just in operator logs).