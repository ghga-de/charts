{{/* Transforms topic values to serivce config parameters. */}}
{{- define "ghga-common.kafkaTopicsParameters" -}}
{{- if .Values.kafkaTopicsParameters }}
{{- $topics := merge (.Values.global.topics | default dict) .Values.topics -}}
{{- range $key, $value := $topics -}}
{{- if $value.topic }}
  {{- if or (not $value.topic.name) (eq $value.topic.name "wildcard") }}
  {{- continue }}
  {{- end }}
  {{ $value.topic.name }}: {{ $.Values.topicPrefix | empty | ternary $value.topic.value (cat $.Values.topicPrefix "-" $value.topic.value ) | nospace }}
{{- end -}}
{{- if $value.type }}
  {{ $value.type.name }}: {{ $value.type.value }}
{{- end -}}
{{- if $value.types }}
{{- range $key, $value := $value.types }}
  {{ $value.name }}: {{ $value.value }}
{{- end }}
{{- end -}}
{{- end -}}
{{- end }}
{{- if .Values.kafkaUser.enabled }}
  kafka_ssl_password: ""
  kafka_ssl_cafile: /cluster-ca-cert/ca.crt
  kafka_ssl_certfile: /kafka-secrets/user.crt
  kafka_ssl_keyfile: /kafka-secrets/user.key
  kafka_security_protocol: SSL
{{- end }}
{{- end -}}
{{- define "ghga-common.kafkauser" -}}
---
{{- if .Values.kafkaUser.enabled -}}
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaUser
metadata:
  labels:
    strimzi.io/cluster: {{ .Values.kafkaUser.clusterName }}
  name: {{ .Release.Namespace }}-{{ include "common.names.fullname" . }}
  namespace: {{ .Values.kafkaUser.clusterNamespace }}
spec:
  authentication:
    type: tls
  authorization:
    acls:
    {{- with .Values.topics }}
    {{- range $topicKey, $topicValue := . }}
    {{- if eq $topicKey "wildcard" }}
    - operations:
        {{- with $topicValue.topic.roles }}
          {{- range $role := . }}
        - {{ $role }}
          {{- end }}
        {{- end }}
      resource:
        name: '{{ $topicValue.topic.value }}'
        patternType: literal
        type: topic
    {{- else if and (eq $topicKey "deadLetterQueueRetry") $.Values.serviceName }}
    - operations:
        {{- with $topicValue.topic.roles }}
          {{- range $role := . }}
        - {{ $role }}
          {{- end }}
        {{- end }}
      resource:
        name: '{{ $.Values.topicPrefix | empty | ternary (cat $topicValue.topic.value "-") (cat $.Values.topicPrefix "-" $topicValue.topic.value "-") | nospace }}'
        patternType: prefix
        type: topic
    {{- else }}
    - operations:
        {{- with $topicValue.topic.roles }}
          {{- range $role := . }}
        - {{ $role }}
          {{- end }}
        {{- end }}
      resource:
        name: '{{ $.Values.topicPrefix | empty | ternary $topicValue.topic.value (cat $.Values.topicPrefix "-" $topicValue.topic.value ) | nospace }}'
        patternType: literal
        type: topic
    {{- end }}
    {{- end }}
    {{- end }}
    - operations:
        - All
      resource:
        name: '*'
        patternType: literal
        type: group
    type: simple
  template:
    secret:
      metadata:
        annotations:
          reflector.v1.k8s.emberstack.com/reflection-allowed: "true"
          reflector.v1.k8s.emberstack.com/reflection-allowed-namespaces: {{ .Release.Namespace }}
          reflector.v1.k8s.emberstack.com/reflection-auto-enabled: "true"
{{- end -}}
{{- end -}}
