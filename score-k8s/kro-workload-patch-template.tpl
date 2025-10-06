{{ range $i, $m := (reverse .Manifests) }}
{{ if ne $m.kind "Namespace" }}
{{ $i := sub (len $.Manifests) (add $i 1) }}
- op: delete
  path: {{ $i }}
{{ end }}
{{ end }}

{{ range $name, $spec := .Workloads }}
{{ $firstContainerName := index (keys $spec.containers) 0 }}
{{ $firstContainer := get $spec.containers $firstContainerName }}
- op: set
  path: -1
  value:
    apiVersion: kro.run/v1alpha1
    kind: Workload
    metadata:
      name: {{ $name }}
    spec:
      image: {{ $firstContainer.image }}
{{ end }}