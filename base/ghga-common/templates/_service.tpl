{{- define "ghga-common.service" -}}
---
apiVersion: v1
kind: Service
metadata:
  name: {{ include "common.names.fullname" . }}
  namespace: {{ include "common.names.namespace" . | quote }}
  labels: {{- include "common.labels.standard" . | nindent 4 }}
    {{- if .Values.commonLabels }}
    {{- include "common.tplvalues.render" ( dict "value" .Values.commonLabels "context" $ ) | nindent 4 }}
    {{- end }}
  {{- if or .Values.service.annotations .Values.commonAnnotations }}
  annotations:
    {{- if .Values.service.annotations }}
    {{- include "common.tplvalues.render" ( dict "value" .Values.service.annotations "context" $ ) | nindent 4 }}
    {{- end }}
    {{- if .Values.commonAnnotations }}
    {{- include "common.tplvalues.render" ( dict "value" .Values.commonAnnotations "context" $ ) | nindent 4 }}
    {{- end }}
  {{- end }}
spec:
  type: {{ .Values.service.type }}
  {{- if .Values.service.sessionAffinity }}
  sessionAffinity: {{ .Values.service.sessionAffinity }}
  {{- end }}
  {{- if .Values.service.sessionAffinityConfig }}
  sessionAffinityConfig: {{- include "common.tplvalues.render" (dict "value" .Values.service.sessionAffinityConfig "context" $) | nindent 4 }}
  {{- end }}
  {{- if and .Values.service.clusterIP (eq .Values.service.type "ClusterIP") }}
  clusterIP: {{ .Values.service.clusterIP }}
  {{- end }}
  {{- if (and (eq .Values.service.type "LoadBalancer") (not (empty .Values.service.loadBalancerIP))) }}
  loadBalancerIP: {{ .Values.service.loadBalancerIP }}
  {{- end }}
  {{- if and (eq .Values.service.type "LoadBalancer") .Values.service.loadBalancerSourceRanges }}
  loadBalancerSourceRanges: {{- toYaml .Values.service.loadBalancerSourceRanges | nindent 4 }}
  {{- end }}
  {{- if or (eq .Values.service.type "LoadBalancer") (eq .Values.service.type "NodePort") }}
  externalTrafficPolicy: {{ .Values.service.externalTrafficPolicy | quote }}
  {{- end }}
  ports: {{- include "common.tplvalues.render" (dict "value" .Values.service.ports "context" $) | nindent 4 }}
  selector: {{- include "common.labels.matchLabels" . | nindent 4 }}
{{- end -}}
