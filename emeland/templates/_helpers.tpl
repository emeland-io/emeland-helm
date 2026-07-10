{{/*
Expand the name of the chart.
*/}}
{{- define "emeland.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "emeland.fullname" -}}
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
{{- define "emeland.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "emeland.labels" -}}
helm.sh/chart: {{ include "emeland.chart" . }}
{{ include "emeland.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "emeland.selectorLabels" -}}
app.kubernetes.io/name: {{ include "emeland.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "emeland.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "emeland.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Web UI server container image
*/}}
{{- define "emeland.serverImage" -}}
{{- printf "%s/%s:%s" .Values.image.server.registry .Values.image.server.repository (.Values.image.server.tag | default .Chart.AppVersion) -}}
{{- end }}

{{/*
In-cluster web UI server base URL (no trailing slash).
*/}}
{{- define "emeland.serverInternalUrl" -}}
{{- printf "http://%s-server:%v" (include "emeland.fullname" .) .Values.service.port -}}
{{- end }}

{{/*
In-cluster modelsrv API base URL for sensor event push (must end with /api/).
*/}}
{{- define "emeland.modelsrvApiUrl" -}}
{{- printf "%s/api/" (include "emeland.serverInternalUrl" .) -}}
{{- end }}

{{/*
In-cluster phase0 filter API base URL (must end with /api/).
*/}}
{{- define "emeland.filterApiUrl" -}}
{{- printf "http://%s-filter:%v/api/" (include "emeland.fullname" .) .Values.filter.service.port -}}
{{- end }}

{{/*
modelsrv-k8s-sensor subchart fullname (mirrors modelsrv-k8s-sensor.fullname).
*/}}
{{- define "emeland.k8sSensorFullname" -}}
{{- $sensor := index .Values "modelsrv-k8s-sensor" }}
{{- if $sensor.fullnameOverride }}
{{- $sensor.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default "modelsrv-k8s-sensor" $sensor.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
In-cluster k8s-sensor modelsrv REST API base URL (no trailing slash).
Uses the supplemental -api Service when the bundled subchart does not expose port 8080.
*/}}
{{- define "emeland.k8sSensorApiServiceUrl" -}}
{{- $port := .Values.filter.k8sSensor.apiPort | default 8080 -}}
{{- printf "http://%s-api:%v" (include "emeland.k8sSensorFullname" .) $port -}}
{{- end }}

{{/*
In-cluster k8s-sensor modelsrv event publisher API (must end with /api/).
*/}}
{{- define "emeland.k8sSensorPublisherApiUrl" -}}
{{- printf "%s/api/" (include "emeland.k8sSensorApiServiceUrl" .) -}}
{{- end }}

{{/*
modelsrv filter container image (phase0 integrity checks)
*/}}
{{- define "emeland.filterImage" -}}
{{- printf "%s/%s:%s" .Values.image.filter.registry .Values.image.filter.repository (.Values.image.filter.tag | default .Chart.AppVersion) -}}
{{- end }}

{{/*
Tools container image
*/}}
{{- define "emeland.toolsImage" -}}
{{- printf "%s/%s:%s" .Values.image.tools.registry .Values.image.tools.repository (.Values.image.tools.tag | default .Chart.AppVersion) -}}
{{- end }}

{{/*
Git sensor container image
*/}}
{{- define "emeland.gitsensorImage" -}}
{{- printf "%s/%s:%s" .Values.image.gitsensor.registry .Values.image.gitsensor.repository (.Values.image.gitsensor.tag | default .Chart.AppVersion) -}}
{{- end }}

{{/*
In-cluster git sensor modelsrv REST API base URL (must end with /api/).
*/}}
{{- define "emeland.gitsensorApiUrl" -}}
{{- printf "http://%s-gitsensor:%v/api/" (include "emeland.fullname" .) .Values.gitsensor.listenPort -}}
{{- end }}

{{/*
Local filter modelsrv REST API base URL for sidecars in the filter pod (must end with /api/).
*/}}
{{- define "emeland.filterLocalApiUrl" -}}
http://127.0.0.1:8080/api/
{{- end }}

{{- define "emeland.gitsensorDeployKeySecretName" -}}
{{- if .Values.gitsensor.existingSecret }}
{{- .Values.gitsensor.existingSecret }}
{{- else }}
{{- printf "%s-gitsensor-deploy-key" (include "emeland.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Whether to render an inline deploy key Secret for the git sensor.
*/}}
{{- define "emeland.gitsensorCreateDeployKeySecret" -}}
{{- if and .Values.gitsensor.enabled (not .Values.gitsensor.existingSecret) .Values.gitsensor.deployKey.privateKey .Values.gitsensor.deployKey.publicKey }}
{{- true }}
{{- end }}
{{- end }}
