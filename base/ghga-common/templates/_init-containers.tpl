{{- define "ghga-common.initContainers" -}}
{{- if .Values.initContainers -}}
{{- range $index, $container := .Values.initContainers }}
- name: {{ $container.name | default (printf "init-%d" $index) }}
  image: {{ $container.image | default (include "common.images.image" (dict "imageRoot" $.Values.image "global" $.Values.global "chart" $.Chart)) }}
  imagePullPolicy: {{ $container.imagePullPolicy | default (eq $.Values.image.tag "latest" | ternary "Always" "IfNotPresent") $.Values.image.pullPolicy }}
  {{- if $container.command }}
  command: {{- toYaml $container.command | nindent 4 }}
  {{- end }}
  {{- if $container.args }}
  args: {{- toYaml $container.args | nindent 4 }}
  {{- end }}
  {{- if $container.env }}
  env: {{- toYaml $container.env | nindent 4 }}
  {{- end }}
  {{- $envVars := include "ghga-common.env-vars" $ | fromYaml | dig "envVars" list -}}
  {{- if and (not $container.env) $envVars }}
  env: {{- include "common.tplvalues.render" (dict "value" $envVars "context" $) | nindent 4 }}
  {{- end }}
  {{- if $.Values.containerSecurityContext.enabled }}
  securityContext: {{- omit $.Values.containerSecurityContext "enabled" | toYaml | nindent 4 }}
  {{- end }}
  {{- if $container.resources }}
  resources: {{- toYaml $container.resources | nindent 4 }}
  {{- end }}
  volumeMounts:
    {{- include "common.tplvalues.render" (dict "value" (include "ghga-common.configVolumeMount" $ | fromYaml | list) "context" $) | nindent 4 }}
    {{- if $.Values.extraVolumeMounts }}
    {{- include "common.tplvalues.render" (dict "value" $.Values.extraVolumeMounts "context" $) | nindent 4 }}
    {{- end }}
    {{- if $container.volumeMounts }}
    {{- include "common.tplvalues.render" (dict "value" $container.volumeMounts "context" $) | nindent 4 }}
    {{- end }}
{{- end }}
{{- end -}}
{{- end -}}