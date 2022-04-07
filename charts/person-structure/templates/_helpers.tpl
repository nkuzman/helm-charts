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
{{ toYaml .Values.customVolumes | default "" }}
- name: {{ include "person-structure.name" . }}-secret
  secret:
    secretName: {{ include "person-structure.name" . }}-secret
    items:
      - path: password.conf
        key: password.conf
- name: {{ include "person-structure.name" . }}-configmap
  configMap:
    name: {{ include "person-structure.name" . }}-configmap
- name: truststore
{{- if .Values.mountTrustStoreFromSecret.enabled }}
  secret:
    secretName: {{ .Values.mountTrustStoreFromSecret.secretName }}
{{- if and .Values.mountTrustStoreFromSecret.certPath .Values.mountTrustStoreFromSecret.keyPath }}
    items:
      - path: {{ .Values.mountTrustStoreFromSecret.certPath }}
        key: {{ .Values.mountTrustStoreFromSecret.certPath }}
      - path: {{ .Values.mountTrustStoreFromSecret.keyPath }}
        key: {{ .Values.mountTrustStoreFromSecret.keyPath }}
{{- end }}
{{- else }}
  emptyDir:
    medium: "Memory"
{{- end }}
{{- if .Values.mountKeyStoreFromSecret.enabled }}
- name: keystore
  secret:
    secretName: {{ .Values.mountKeyStoreFromSecret.secretName }}
{{- end }}
{{- if .Values.mountKeyStoreFromSecret.path }}
    items:
      - path: {{ .Values.mountKeyStoreFromSecret.path }}
        key: {{ .Values.mountKeyStoreFromSecret.path }}
{{- end }}
{{- end }}

{{/*
Mounts for person-structure application
*/}}
{{- define "person-structure.mounts" -}}
{{ toYaml .Values.customMounts | default "" }}
- mountPath: /mnt/k8s/secrets/
  name: {{ include "person-structure.name" . }}-secret
- mountPath: /usr/app/config
  name: {{ include "person-structure.name" . }}-configmap
{{- if .Values.mountTrustStoreFromSecret.enabled }}
- mountPath: /mnt/k8s/tls-server/key.pem
  name: truststore
{{- if .Values.mountTrustStoreFromSecret.keyPath }}
  subPath: {{ .Values.mountTrustStoreFromSecret.keyPath }}
{{- end }}
- mountPath: /mnt/k8s/tls-server/cert.pem
  name: truststore
{{- if .Values.mountTrustStoreFromSecret.certPath }}
  subPath: {{ .Values.mountTrustStoreFromSecret.certPath }}
{{- end }}
{{/* else if initcontainer TODO */}}
{{- else }}
- mountPath: /mnt/k8s/tls-server
  name: truststore
{{- end }}
{{- if .Values.mountKeyStoreFromSecret.enabled }}
- mountPath: {{ .Values.mountKeyStoreFromSecret.location }}
  name: keystore
{{- end }}
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
