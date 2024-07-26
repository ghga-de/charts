{{- define "ghga-common.serviceaccount" -}}
{{- if .Values.serviceaccount.create }}
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ .Release.Name }}
  labels:
    app: {{ .Release.Name }}
{{- end }}
{{- end -}}
