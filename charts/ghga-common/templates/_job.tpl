{{- define "ghga-common.job" -}}
{{- if .Values.job.enabled -}}
---
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ include "common.names.fullname" . }}
  namespace: {{ include "common.names.namespace" . | quote }}
  labels: {{- include "common.labels.standard" . | nindent 4 }}
    app: {{ include "common.names.fullname" . }}
    {{- if .Values.labels }}
    {{- include "common.tplvalues.render" ( dict "value" .Values.labels "context" $ ) | nindent 4 }}
    {{- end }}
    {{- if .Values.commonLabels }}
    {{- include "common.tplvalues.render" ( dict "value" .Values.commonLabels "context" $ ) | nindent 4 }}
    {{- end }}
  annotations:
    configmap-hash: {{ include (print $.Template.BasePath "/configmap.yml") . | sha256sum }}
    {{- if .Values.annotations }}
    {{- include "common.tplvalues.render" ( dict "value" .Values.annotations "context" $) | nindent 4 }}
    {{- end }}
    {{- if .Values.commonAnnotations }}
    {{- include "common.tplvalues.render" ( dict "value" .Values.commonAnnotations "context" $) | nindent 4 }}
    {{- end }}
spec:
  template:
    metadata:
      annotations:
        configmap-hash: {{ include (print $.Template.BasePath "/configmap.yml") . | sha256sum }}
        {{- if .Values.podAnnotations }}
        {{- .Values.podAnnotations | toYaml | nindent 8 }}
        {{- end }}
        helm.sh/revision: {{ .Release.Revision | quote }}
      labels: {{- include "common.labels.standard" . | nindent 8 }}
        app: {{ include "common.names.fullname" . }}
        {{- if .Values.podLabels }}
        {{- include "common.tplvalues.render" (dict "value" .Values.podLabels "context" $) | nindent 8 }}
        {{- end }}
    spec:
      restartPolicy: {{ .Values.job.restartPolicy | default "Never" }}
      {{- if .Values.backoffLimit }}
      backoffLimit: {{ .Values.backoffLimit }}
      {{- end }}
      serviceAccountName: {{ include "common.names.fullname" . }}
      {{- if .Values.imagePullSecrets }}
      imagePullSecrets: {{- include "common.tplvalues.render" (dict "value" .Values.imagePullSecrets "context" $) | nindent 8 }}
      {{- end }}
      containers:
      {{- range $container := .Values.containers }}
        - image: {{ include "common.images.image" (dict "imageRoot" $.Values.image "global" $.Values.global "chart" $.Chart ) }}
          imagePullPolicy: {{ default (eq $.Values.image.tag "latest" | ternary "Always" "IfNotPresent") $.Values.image.pullPolicy }}
          {{- include "ghga-common.command-args" (list $ $container.cmd)  | nindent 10 }}
          {{- if $.Values.args }}
          args: {{- include "common.tplvalues.render" (dict "value" $.Values.args "context" $) | nindent 12 }}
          {{- end }}
          {{- if $.Values.envVars }}
          env: {{ include "common.tplvalues.render" (dict "value" $.Values.envVars "context" $) | nindent 12 }}
          {{- end }}
          volumeMounts:
            - name: {{ $container.config.name | default "config" }}
              mountPath: /home/{{ $container.config.appuser | default "appuser" }}/.{{ $.Values.configPrefix }}.yaml
              subPath: .{{ $.Values.configPrefix }}.yaml
              readOnly: true
            {{- if $.Values.extraVolumeMounts }}
            {{- include "common.tplvalues.render" (dict "value" $.Values.extraVolumeMounts "context" $) | nindent 12 }}
            {{- end }}
      {{- end }}
      volumes:
      {{- range $container := .Values.containers }}
        - name: {{ $container.config.name | default "config" }}
          configMap:
            name: {{ include "common.names.fullname" $ }}
            items:
            - key: {{ $container.config.key | default "parameters" }}
              path: .{{ $.Values.configPrefix }}.yaml
      {{- end }}
        {{- if .Values.extraVolumes }}
        {{- include "common.tplvalues.render" ( dict "value" .Values.extraVolumes "context" $) | nindent 8 }}
        {{- end }}
{{- end -}}
{{- end -}}
