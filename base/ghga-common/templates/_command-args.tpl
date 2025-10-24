{{/*
ghga-common.command-args will take the original run command and
prepends it with a failsafe routine that injects all existing secrets from vault.

@param The original command to run the microservice
*/}}
{{- define "ghga-common.command-args" -}}
{{- $argsList := (kindOf (index . 1) | eq "string") | ternary (list (index . 1)) (index . 1) }}
{{- dict "command" (index . 2) | toYaml }}
{{- if (index . 0).Values.vaultAgent.enabled }}
{{ $argsList = prepend $argsList "if [ -d /vault/secrets ]; then for f in /vault/secrets/*; do if [ -f \"$f\" ]; then . \"$f\"; fi; done; fi" }}
{{- end }}
{{- dict "args" $argsList | toYaml }}
{{- end -}}
