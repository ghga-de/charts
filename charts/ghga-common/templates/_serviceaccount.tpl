{{- define "ghga-common.serviceaccount" -}}
{{- if .Values.serviceAccount.create }}
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ include "common.names.fullname" . }}
  labels: {{- include "common.labels.standard" . | nindent 4 }}
    app: {{ include "common.names.fullname" . }}
{{- end }}
{{- end -}}