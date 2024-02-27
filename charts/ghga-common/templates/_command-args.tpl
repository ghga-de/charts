{{/*
ghga-common.command-args will take the original run command and
prepends it with a failsafe routine that injects all existing secrets from vault.

@param The original command to run the microservice
*/}}

{{- define "ghga-common.black-secret-value" -}}
'{ value = $2; gsub(/^ +| +$/, "", value); OFS=FS; len = length(value); left = substr(value, 1, 2); middle = "***"; right = substr(value, len - 1); print $1 OFS left middle right }'
{{- end -}}

{{/* Config file name is not always equal to config_prefix */}}
{{- define "ghga-common.log-config-params" -}}
echo "[$(date +"%T")] Config file service values";
cat .*.yaml | grep -i -v -E "({{ .Values.logConfigBlacklist | join "|"}})";
echo "[$(date +"%T")] Secret config file service values";
cat .*.yaml | grep -i -E "({{ .Values.logConfigBlacklist | join "|"}})" | awk -F":" {{ include "ghga-common.black-secret-value" . }};
{{- end -}}

{{- define "ghga-common.log-environment-params" -}}
echo "[$(date +"%T")] Service environment values";
env | grep -i {{ .Values.config_prefix }} | grep -i -v -E "({{ .Values.logConfigBlacklist | join "|"}})";
echo "[$(date +"%T")] Secret service environment values";
env | grep -i {{ .Values.config_prefix }} | grep -i -E "({{ .Values.logConfigBlacklist | join "|"}})" | awk -F= {{ include "ghga-common.black-secret-value" . }};
{{- end -}}

{{- define "ghga-common.export-vault-secrets" -}}
if [ -d "/vault/secrets" ]; then
  for f in /vault/secrets/*; do
    [ -f "$f" ] && . "$f";
  done
fi;
{{- end -}}

{{- define "ghga-common.command-args" -}}
command: ["sh", "-c"]
args:
  - echo "[$(date +"%T")] Running prepended commands";
    {{- if .Values.sourceVaultSecrets | default true }}
    echo "[$(date +"%T")] Export environment values from Vault secret files";
    {{- include "ghga-common.export-vault-secrets" . | nindent 4 }}
    {{- end }}    
    {{- if .Values.logConfig | default false }}
    {{- include "ghga-common.log-config-params" . | nindent 4 }}
    {{- include "ghga-common.log-environment-params" . | nindent 4 }}
    {{- end }}
    echo "[$(date +"%T")] Running service command";
    {{ .Values.serviceCommand }};
{{- end -}}
