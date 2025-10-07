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
      {{- if (gt (len $firstContainer.command) 0) }}
      command:
        {{- range $i, $cmd := $firstContainer.command }}
        - {{ $cmd }}
        {{ end }}
      {{ end }}
      {{- if (gt (len $firstContainer.args) 0) }}
      args:
        {{- range $i, $arg := $firstContainer.args }}
        - {{ $arg }}
        {{ end }}
      {{ end }}
      {{- if (gt (len $firstContainer.variables) 0) }}
      env:
        {{- range $variableName, $variableValue := $firstContainer.variables }}
        - name: {{ $variableName }}
          value: "{{ $variableValue }}"
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
{{ end }}