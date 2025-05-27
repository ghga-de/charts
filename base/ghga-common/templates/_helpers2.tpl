{{- define "ghga-common.serviceName2" -}}
{{- if .Values.serviceName -}}
    {{ .Values.serviceNamePrefix | empty | ternary .Values.serviceName (cat .Values.serviceNamePrefix "-" .Values.serviceName ) | nospace }}
{{- end -}}
{{- end -}}