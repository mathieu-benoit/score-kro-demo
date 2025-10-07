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
      {{- if ne $firstContainer.livenessProbe nil }}
      livenessProbe:
        {{- if ne $firstContainer.livenessProbe.httpGet nil }}
        httpGet:
          port: {{ $firstContainer.livenessProbe.httpGet.port }}
          path: {{ $firstContainer.livenessProbe.httpGet.path }}
        {{ end }}
        {{- if ne $firstContainer.livenessProbe.exec nil }}
        exec:
          command:
          {{- range $command := $firstContainer.livenessProbe.exec.command }}
          - {{ $command }}
          {{ end }}
        {{ end }}
      {{ end }}
      {{- if ne $firstContainer.readinessProbe nil }}
      readinessProbe:
        {{- if ne $firstContainer.readinessProbe.httpGet nil }}
        httpGet:
          port: {{ $firstContainer.readinessProbe.httpGet.port }}
          path: {{ $firstContainer.readinessProbe.httpGet.path }}
        {{ end }}
        {{- if ne $firstContainer.readinessProbe.exec nil }}
        exec:
          command:
          {{- range $command := $firstContainer.readinessProbe.exec.command }}
          - {{ $command }}
          {{ end }}
        {{ end }}
      {{ end }}
{{ end }}