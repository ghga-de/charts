{{- define "ghga-common.image-pull-secrets" -}}
{{- $secretName := .Values.imagePullSecretName -}}
{{- if $secretName -}}
imagePullSecrets:
  - name: {{ $secretName }}
{{- end -}}
{{- end -}}
