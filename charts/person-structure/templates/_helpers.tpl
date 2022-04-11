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
- name: keystore
{{- if .Values.mountKeyStoreFromSecret.enabled }}
  secret:
    secretName: {{ .Values.mountKeyStoreFromSecret.secretName }}
{{- if and .Values.mountKeyStoreFromSecret.certPath .Values.mountKeyStoreFromSecret.keyPath }}
    items:
      - path: {{ .Values.mountKeyStoreFromSecret.certPath }}
        key: {{ .Values.mountKeyStoreFromSecret.certPath }}
      - path: {{ .Values.mountKeyStoreFromSecret.keyPath }}
        key: {{ .Values.mountKeyStoreFromSecret.keyPath }}
{{- end }}
{{- else }}
  emptyDir:
    medium: "Memory"
{{- end }}
{{- if .Values.mountTrustStoreFromSecret.enabled }}
- name: truststore
  secret:
    secretName: {{ .Values.mountTrustStoreFromSecret.secretName }}
{{- end }}
{{- if .Values.mountTrustStoreFromSecret.path }}
    items:
      - path: {{ .Values.mountTrustStoreFromSecret.path }}
        key: {{ .Values.mountTrustStoreFromSecret.path }}
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
{{- if .Values.mountKeyStoreFromSecret.enabled }}
- mountPath: /mnt/k8s/tls-server/key.pem
  name: keystore
{{- if .Values.mountKeyStoreFromSecret.keyPath }}
  subPath: {{ .Values.mountKeyStoreFromSecret.keyPath }}
{{- end }}
- mountPath: /mnt/k8s/tls-server/cert.pem
  name: keystore
{{- if .Values.mountKeyStoreFromSecret.certPath }}
  subPath: {{ .Values.mountKeyStoreFromSecret.certPath }}
{{- end }}
{{/* else if initcontainer TODO */}}
{{- else }}
- mountPath: /mnt/k8s/tls-server
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
