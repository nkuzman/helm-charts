{{/*
Expand the name of the chart.
*/}}
{{- define "payment-order.name" -}}
{{/*- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" */}}
{{- default .Release.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "payment-order.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "payment-order.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "payment-order.labels" -}}
helm.sh/chart: {{ include "payment-order.chart" . }}
app: {{ include "payment-order.name" . }}
project: HolisticPay
{{ include "payment-order.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "payment-order.selectorLabels" -}}
app.kubernetes.io/name: {{ include "payment-order.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Volumes
*/}}
{{- define "payment-order.volumes" -}}
{{ toYaml .Values.customVolumes | default "" }}
- name: {{ .Release.Name }}-secret
  secret:
    secretName: {{ .Release.Name }}-secret
    items:
      - path: password.conf
        key: password.conf
- name: {{ .Release.Name }}-configmap
  configMap:
    name: {{ .Release.Name }}-configmap
{{- if .Values.mountTrustStoreFromSecret.enabled }}
- name: truststore
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
- name: truststore
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
Mounts for payment-order application
*/}}
{{- define "payment-order.mounts" -}}
{{ toYaml .Values.customMounts | default "" }}
- mountPath: /mnt/k8s/secrets/
  name: {{ .Release.Name }}-secret
- mountPath: /usr/app/config
  name: {{ .Release.Name }}-configmap
{{- if .Values.mountTrustStoreFromSecret.enabled }}
- mountPath: /mnt/k8s/tls-server/key.pem
  name: {{ .Release.Name }}-tls
{{- if .Values.mountTrustStoreFromSecret.keyPath }}
  subPath: {{ .Values.mountTrustStoreFromSecret.keyPath }}
{{- end }}
- mountPath: /mnt/k8s/tls-server/cert.pem
  name: {{ .Release.Name }}-tls
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
{{- define "payment-order.passwords" -}}
{{ tpl (.Files.Get "config/password.conf") . | b64enc }}
{{- end }}

{{/*
Application logger
*/}}
{{- define "payment-order.logger" -}}
{{ tpl (.Files.Get "config/log4j2.xml") . }}
{{- end }}
