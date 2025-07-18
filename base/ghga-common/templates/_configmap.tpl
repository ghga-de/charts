{{- define "ghga-common.configmap" -}}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "common.names.fullname" . }}
  namespace: {{ include "common.names.namespace" . | quote }}
data:
{{- range $container := .Values.containers }}
  parameters-{{ $container.type }}: |
    {{- $parameters := merge (get $.Values.parameters $container.type) $.Values.parameters.default -}}
    {{- $parameters := omit $parameters "db_name" "api_root_path" "service_name" "service_instance_id" -}}  
    {{- $parameters | toYaml | nindent 4 }}
    {{- include "ghga-common.kafkaTopicsParameters" $ | nindent 2 }}
    {{- if (include "ghga-common.apiBasePath" $) }}
    api_root_path: {{ include "common.tplvalues.render" (dict "value" (include "ghga-common.apiBasePath" $) "context" $) }}
    {{- end }}
    {{- if (include "ghga-common.dbName" $) }}
    db_name: {{ include "common.tplvalues.render" (dict "value" (include "ghga-common.dbName" $) "context" $) }}
    {{- end }}
    {{- if eq $container.type "consumer"}}
    {{- if (include "ghga-common.serviceNameConsumer" $) }}
    service_name: {{ include "common.tplvalues.render" (dict "value" (include "ghga-common.serviceNameConsumer" $) "context" $) }}
    {{- end }}
    service_instance_id: {{ include "common.tplvalues.render" (dict "value" (include "ghga-common.serviceInstanceIdConsumer" $) "context" $) }}
    {{- else }}
    {{- if (include "ghga-common.serviceName" $) }}
    service_name: {{ include "common.tplvalues.render" (dict "value" (include "ghga-common.serviceName" $) "context" $) }}
    {{- end }}
    {{- if (include "ghga-common.serviceInstanceId" $) }}
    service_instance_id: {{ include "common.tplvalues.render" (dict "value" (include "ghga-common.serviceInstanceId" $) "context" $) }}
    {{- end }}
    {{- end }}
{{- end }}
  parameters: |
    {{- $parameters := .Values.parameters.default }}
    {{- $parameters := omit $parameters "db_name" "api_root_path" "service_name" "service_instance_id" -}}  
    {{- $parameters | toYaml | nindent 4 }}
    {{- include "ghga-common.kafkaTopicsParameters" . | nindent 2 }}
    {{- if (include "ghga-common.apiBasePath" $) }}
    api_root_path: {{ include "common.tplvalues.render" (dict "value" (include "ghga-common.apiBasePath" $) "context" $) }}
    {{- end }}
    {{- if (include "ghga-common.dbName" $) }}
    db_name: {{ include "common.tplvalues.render" (dict "value" (include "ghga-common.dbName" $) "context" $) }}
    {{- end }}
    {{- if (include "ghga-common.serviceName" $) }}
    service_name: {{ include "common.tplvalues.render" (dict "value" (include "ghga-common.serviceName" $) "context" $) }}
    {{- end }}
    {{- if (include "ghga-common.serviceInstanceId" $) }}
    service_instance_id: {{ include "common.tplvalues.render" (dict "value" (include "ghga-common.serviceInstanceId" $) "context" $) }}
    {{- end }}
{{- end -}}
