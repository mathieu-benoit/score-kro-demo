{{ range $i, $m := (reverse .Manifests) }}
{{ if ne $m.kind "Namespace" }}
{{ $i := sub (len $.Manifests) (add $i 1) }}
- op: delete
  path: {{ $i }}
{{ end }}
{{ end }}

{{ $namespace := .Namespace }}
{{ range $name, $spec := .Workloads }}
{{ $service := $spec.service }}
{{ $resources := $spec.resources }}
{{ $firstContainerName := index (keys $spec.containers) 0 }}
{{ $firstContainer := get $spec.containers $firstContainerName }}
- op: set
  path: -1
  value:
    apiVersion: kro.run/v1alpha1
    kind: Workload
    metadata:
      name: {{ $name }}
      {{ if ne $namespace "" }}
      namespace: {{ $namespace }}
      {{ end }}
    spec:
      image: {{ $firstContainer.image }}
      {{- if and $firstContainer.command (gt (len $firstContainer.command) 0) }}
      command:
        {{- range $i, $cmd := $firstContainer.command }}
        - {{ $cmd }}
        {{ end }}
      {{ end }}
      {{- if and $firstContainer.args (gt (len $firstContainer.args) 0) }}
      args:
        {{- range $i, $arg := $firstContainer.args }}
        - {{ $arg }}
        {{ end }}
      {{ end }}
      {{- if and $firstContainer.variables (gt (len $firstContainer.variables) 0) }}
      env:
        {{- range $variableName, $variableValue := $firstContainer.variables }}
        - name: {{ $variableName }}
          value: "{{ $variableValue }}"
        {{ end }}
      {{ end }}
      {{- if $firstContainer.resources }}
      resources:
        {{- if $firstContainer.resources.limits }}
        limits:
          memory: {{ $firstContainer.resources.limits.memory }}
          cpu: {{ $firstContainer.resources.limits.cpu }}
        {{ end }}
        {{- if $firstContainer.resources.requests }}
        requests:
          memory: {{ $firstContainer.resources.requests.memory }}
          cpu: {{ $firstContainer.resources.requests.cpu }}
        {{ end }}
      {{ end }}
      {{- if $firstContainer.livenessProbe }}
      livenessProbe:
        {{- if $firstContainer.livenessProbe.httpGet }}
        httpGet:
          port: {{ $firstContainer.livenessProbe.httpGet.port }}
          path: {{ $firstContainer.livenessProbe.httpGet.path }}
        {{ end }}
        {{- if $firstContainer.livenessProbe.exec }}
        exec:
          command:
          {{- range $command := $firstContainer.livenessProbe.exec.command }}
          - {{ $command }}
          {{ end }}
        {{ end }}
      {{ end }}
      {{- if $firstContainer.readinessProbe }}
      readinessProbe:
        {{- if $firstContainer.readinessProbe.httpGet }}
        httpGet:
          port: {{ $firstContainer.readinessProbe.httpGet.port }}
          path: {{ $firstContainer.readinessProbe.httpGet.path }}
        {{ end }}
        {{- if $firstContainer.readinessProbe.exec }}
        exec:
          command:
          {{- range $command := $firstContainer.readinessProbe.exec.command }}
          - {{ $command }}
          {{ end }}
        {{ end }}
      {{ end }}
      {{- if $service }}
      service:
        ports:
          {{- range $portName, $port := $service.ports }}
          - name: {{ $portName }}
            port: {{ $port.port }}
            targetPort: {{ $port.targetPort }}
            protocol: {{ $port.protocol }}
          {{ end }}
      {{ end }}
      {{- range $resourceName, $resource := $resources }}
      {{- if eq $resource.type "route" }}
      route:
        host: {{ substituteValue $name $resource.params.host }}
        path: {{ $resource.params.path }}
        port: {{ $resource.params.port }}
      {{ end }}
      {{- if eq $resource.type "horizontal-pod-autoscaler" }}
      hpa:
        targetCPUUtilization: {{ $resource.params.targetCPUUtilizationPercentage | default 80 }}
        targetMemoryUtilization: {{ $resource.params.targetMemoryUtilization | default 80 }}
        minReplicas: {{ $resource.params.minReplicas | default 1 }}
        maxReplicas: {{ $resource.params.maxReplicas | default 1 | max $resource.params.minReplicas }}
      {{ end }}
      {{- if eq $resource.type "redis" }}
      inClusterRedis: true
      {{ end }}
      {{ end }}
{{ end }}