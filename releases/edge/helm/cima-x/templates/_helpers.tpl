{{/*
Chart name.
*/}}
{{- define "cima-x.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
PVC name — hard-coded to ais-edge so it stays stable across releases
and matches the claimName referenced throughout all pod/deployment templates.
*/}}
{{- define "cima-x.pvcName" -}}
ais-edge
{{- end }}

{{/*
Common labels applied to every resource.
*/}}
{{- define "cima-x.labels" -}}
helm.sh/chart: {{ include "cima-x.name" . }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/name: {{ include "cima-x.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
DICOM tag mapping env vars — included in sort, upload, and associate pods.
*/}}
{{- define "cima-x.dicomTagEnv" -}}
- name: XINGEST_PROJECT
  value: {{ .Values.xnatIngest.dicomTagMapping.project | quote }}
- name: XINGEST_SUBJECT
  value: {{ .Values.xnatIngest.dicomTagMapping.subject | quote }}
- name: XINGEST_VISIT
  value: {{ .Values.xnatIngest.dicomTagMapping.visit | quote }}
- name: XINGEST_SESSION
  value: {{ .Values.xnatIngest.dicomTagMapping.session | quote }}
{{- end }}

{{/*
Common xnat-ingest env vars shared by all three pods.
*/}}
{{- define "cima-x.xnatIngestCommonEnv" -}}
- name: XINGEST_DELETE
  value: {{ .Values.xnatIngest.delete | quote }}
- name: XINGEST_DEIDENTIFY
  value: {{ .Values.xnatIngest.deidentify | quote }}
- name: XINGEST_SPACES_TO_UNDERSCORES
  value: {{ .Values.xnatIngest.spacesToUnderscores | quote }}
{{- end }}

{{/*
Shared volume definitions for xnat-ingest pods.
*/}}
{{- define "cima-x.xnatIngestVolumes" -}}
volumes:
- name: storage
  persistentVolumeClaim:
    claimName: {{ include "cima-x.pvcName" . }}
{{- end }}

{{/*
Shared volumeMount for xnat-ingest pods.
*/}}
{{- define "cima-x.xnatIngestVolumeMount" -}}
- name: storage
  mountPath: /data
{{- end }}
