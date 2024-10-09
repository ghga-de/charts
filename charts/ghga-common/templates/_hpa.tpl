{{- define "ghga-common.hpa" -}}
{{- if .Values.autoscaling.enabled }}
---
apiVersion: {{ include "common.capabilities.hpa.apiVersion" ( dict "context" $ ) }}
kind: HorizontalPodAutoscaler
metadata:
  name: {{ include "common.names.fullname" . }}
  namespace: {{ include "common.names.namespace" . | quote }}
  labels: {{- include "common.labels.standard" . | nindent 4 }}
    {{- if .Values.commonLabels }}
    {{- include "common.tplvalues.render" ( dict "value" .Values.commonLabels "context" $ ) | nindent 4 }}
    {{- end }}
  {{- if .Values.commonAnnotations }}
  annotations: {{- include "common.tplvalues.render" ( dict "value" .Values.commonAnnotations "context" $ ) | nindent 4 }}
  {{- end }}
spec:
  scaleTargetRef:
    apiVersion: {{ include "common.capabilities.deployment.apiVersion" . }}
    kind: Deployment
    name: {{ include "common.names.fullname" . }}
  minReplicas: {{ .Values.autoscaling.minReplicas }}
  maxReplicas: {{ .Values.autoscaling.maxReplicas }}
  metrics:
  {{- if .Values.autoscaling.targetCPU }}
    - type: Resource
      resource:
        name: cpu
      {{- if semverCompare "<1.23-0" (include "common.capabilities.kubeVersion" .) }}
        targetAverageUtilization: {{ .Values.autoscaling.targetCPU }}
      {{- else }}
        target:
          type: Utilization
          averageUtilization: {{ .Values.autoscaling.targetCPU }}
      {{- end }}
  {{- end }}
  {{- if .Values.autoscaling.targetMemory }}
    - type: Resource
      resource:
        name: memory
      {{- if semverCompare "<1.23-0" (include "common.capabilities.kubeVersion" .) }}
        targetAverageUtilization: {{ .Values.autoscaling.targetMemory }}
      {{- else }}
        target:
          type: Utilization
          averageUtilization: {{ .Values.autoscaling.targetMemory }}
      {{- end }}
  {{- end }}
  {{- if .Values.autoscaling.metrics }}
  {{- include "common.tplvalues.render" (dict "value" .Values.autoscaling.metrics "context" $) | nindent 4 }}
  {{- end }}
{{- end }}
{{- end -}}