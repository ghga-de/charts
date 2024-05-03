{{- define "ghga-common.image-pull-secrets" -}}
{{- if .Values.imagePullSecretName -}}
imagePullSecrets:
  - name: {{ .Values.imagePullSecretName }}
{{- end -}}
{{- end -}}
