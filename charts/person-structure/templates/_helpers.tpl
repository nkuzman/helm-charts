{{/*
Expand the name of the chart.
*/}}
{{- define "person-structure.name" -}}
{{- default .Release.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "person-structure.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "person-structure.labels" -}}
helm.sh/chart: {{ include "person-structure.chart" . }}
app: {{ include "person-structure.name" . }}
project: HolisticPay
{{ include "person-structure.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "person-structure.selectorLabels" -}}
app.kubernetes.io/name: {{ include "person-structure.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Volumes
*/}}
{{- define "person-structure.volumes" -}}
{{- with .Values.customVolumes -}}
{{- toYaml . | default "" }}
{{ "" }}
{{- end -}}
- name: {{ include "person-structure.name" . }}-secret
  secret:
    secretName: {{ include "person-structure.name" . }}-secret
    items:
      - path: password.conf
        key: password.conf
- name: {{ include "person-structure.name" . }}-configmap
  configMap:
    name: {{ include "person-structure.name" . }}-configmap
- name: liquibase-config
  configMap:
    name: {{ include "person-structure.name" . }}-liquibase-configmap
- name: server-cert
{{- if .Values.mountServerCertFromSecret.enabled }}
  secret:
    secretName: {{ .Values.mountServerCertFromSecret.secretName }}
{{- if and .Values.mountServerCertFromSecret.certPath .Values.mountServerCertFromSecret.keyPath }}
    items:
      - path: {{ .Values.mountServerCertFromSecret.certPath }}
        key: {{ .Values.mountServerCertFromSecret.certPath }}
      - path: {{ .Values.mountServerCertFromSecret.keyPath }}
        key: {{ .Values.mountServerCertFromSecret.keyPath }}
{{- end }}
{{- else }}
  emptyDir:
    medium: "Memory"
{{- end }}
{{- if .Values.mountKeyStoreFromSecret.enabled }}
- name: keystore
  secret:
    secretName: {{ .Values.mountKeyStoreFromSecret.secretName }}
{{- if .Values.mountKeyStoreFromSecret.keyStoreName }}
    items:
      - path: {{ .Values.mountKeyStoreFromSecret.keyStoreName }}
        key: {{ .Values.mountKeyStoreFromSecret.keyStoreName }}
{{- end }}
{{- end }}
{{- if .Values.mountTrustStoreFromSecret.enabled }}
- name: truststore
  secret:
    secretName: {{ .Values.mountTrustStoreFromSecret.secretName }}
{{- if .Values.mountTrustStoreFromSecret.trustStoreName }}
    items:
      - path: {{ .Values.mountTrustStoreFromSecret.trustStoreName }}
        key: {{ .Values.mountTrustStoreFromSecret.trustStoreName }}
{{- end }}
{{- end }}
{{- if and .Values.logger.logDirMount.enabled .Values.logger.logDirMount.spec }}
- name: logdir
{{- toYaml .Values.logger.logDirMount.spec | nindent 2 }}
{{- end }}
{{- end }}

{{/*
Mounts for person-structure application
*/}}
{{- define "person-structure.mounts" -}}
{{- with .Values.customMounts -}}
{{- toYaml . | default "" }}
{{ "" }}
{{- end -}}
- mountPath: /mnt/k8s/secrets/
  name: {{ include "person-structure.name" . }}-secret
- mountPath: /usr/app/config
  name: {{ include "person-structure.name" . }}-configmap
{{- if .Values.mountServerCertFromSecret.enabled }}
- mountPath: /mnt/k8s/tls-server/key.pem
  name: server-cert
{{- if .Values.mountServerCertFromSecret.keyPath }}
  subPath: {{ .Values.mountServerCertFromSecret.keyPath }}
{{- end }}
- mountPath: /mnt/k8s/tls-server/cert.pem
  name: server-cert
{{- if .Values.mountServerCertFromSecret.certPath }}
  subPath: {{ .Values.mountServerCertFromSecret.certPath }}
{{- end }}
{{- else }}
- mountPath: /mnt/k8s/tls-server
  name: server-cert
{{- end }}
{{- if .Values.mountKeyStoreFromSecret.enabled }}
- mountPath: {{ .Values.mountKeyStoreFromSecret.location }}
  name: keystore
{{- end }}
{{- if .Values.mountTrustStoreFromSecret.enabled }}
- mountPath: {{ .Values.mountTrustStoreFromSecret.location }}
  name: truststore
{{- end }}
{{- if and .Values.logger.logDirMount.enabled .Values.logger.logDirMount.spec }}
- mountPath: {{ .Values.logger.logDir }}
  name: logdir
{{- end}}
{{- end }}

{{/*
Application secrets
*/}}
{{- define "person-structure.passwords" -}}
{{ tpl (.Files.Get "config/password.conf") . | b64enc }}
{{- end }}

{{/*
Application logger
*/}}
{{- define "person-structure.logger" -}}
{{ tpl (.Files.Get "config/log4j2.xml") . }}
{{- end }}

{{/*
Liquibase changelog
*/}}
{{- define "person-structure.changelog" -}}
{{ tpl (.Files.Get "config/liquibase/db.changelog-master.yaml") . }}
{{- end }}

{{/*
Liquibase changelog
*/}}
{{- define "person-structure.liquibase-config" -}}
{{ tpl (.Files.Get "config/liquibase/liquibase.properties") . }}
{{- end }}
