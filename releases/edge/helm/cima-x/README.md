## Prerequisites

- MicroK8s (or any Kubernetes cluster) with Helm v3 and kubectl installed
- NodePorts 30042, 30842, and host port 445 must be free on the node

## Quick install

The setup script handles everything — namespace, secrets, and chart install:

```bash
bash helm/setup.sh
```

It will prompt for all credentials and site-specific values, then install the chart.

To pass a values override file (see `helm/my-values.yaml`):

```bash
bash helm/setup.sh helm/my-values.yaml
```

## Manual installation

If you prefer to install step by step:

### 1. Edit values

Copy and edit the site values template:

```bash
cp helm/my-values.yaml helm/my-site.yaml
# edit my-site.yaml for your site
```

### 2. Create the namespace

```bash
kubectl create namespace ais-edge
```

### 3. Create required secrets

**Orthanc** (web UI and REST API users):

```bash
echo '{"admin": "changeme"}' > users.json
kubectl create secret generic orthanc-credentials \
  --from-literal=users.json='{"admin": "changeme"}' \
  -n ais-edge
```

**Samba** (file share login):

```bash
kubectl create secret generic samba-credentials \
  --from-literal=username=<user> \
  --from-literal=password=<pass> \
  -n ais-edge
```

**XNAT** (required before running upload):

```bash
kubectl create secret generic xnat-credentials \
  --from-literal=server=https://xnat.example.org \
  --from-literal=username=<user> \
  --from-literal=password=<pass> \
  -n ais-edge
```

### 4. Install

```bash
helm install cima-x helm/cima-x -f helm/my-site.yaml -n ais-edge
```

After install, Helm prints connection URLs and example commands for the site.

## Verify

```bash
kubectl get pods -n ais-edge
kubectl get pvc  -n ais-edge
kubectl get svc  -n ais-edge
```

All pods should reach `Running` status. The xnat-ingest pods (sort, upload, associate) are intentionally idle — they run `sleep infinity` until invoked manually.

## Running the pipeline

Data flows: Orthanc (or Samba) -> sort -> upload -> associate

**Sort** (organise DICOM files from Orthanc into sessions):

```bash
kubectl exec -it sort -n ais-edge -- \
  xnat-ingest sort /data/orthanc-storage /data/staging/sorted --recursive
```

**Upload** (push sorted sessions to XNAT):

```bash
kubectl exec -it upload -n ais-edge -- \
  xnat-ingest upload /data/staging/sorted $XINGEST_SERVER
```

**Associate**:

```bash
kubectl exec -it associate -n ais-edge -- \
  xnat-ingest associate /data/cima-export /data/staging/sorted \
    --associated-files 'medimage/vnd.siemens.syngo-mr.xa.rda' \
      '{PatientName}/**/*.rda' \
      '.*\.(?P<id>\d+)\.\d+\.\d+\.(?P<resource>[^.]+)'
```

## Upgrade

```bash
helm upgrade cima-x . -f my-site.yaml -n ais-edge
```

## Uninstall

```bash
helm uninstall cima-x -n ais-edge
```

The PersistentVolume, PersistentVolumeClaim, and namespace are annotated with `helm.sh/resource-policy: keep` and will not be deleted. Data on disk is not affected.

## Configuration reference

| Key | Default | Description |
|-----|---------|-------------|
| `namespace` | `ais-edge` | Target namespace |
| `storageClassName` | `hostpath-pipeline` | Storage class for PV/PVC |
| `storage.hostPath` | `/data/ais-edge` | Host directory for pipeline data |
| `storage.capacity` | `1500Gi` | PV/PVC size |
| `orthanc.nodePorts.dicom` | `30042` | External port for DICOM receipt |
| `orthanc.nodePorts.http` | `30842` | External port for Orthanc web UI |
| `samba.shareName` | `cima-x` | SMB share name |
| `xnatIngest.dicomTagMapping` | see values.yaml | DICOM tag to XNAT field mapping |
| `storageClass.create` | `true` | Create the storage class — set to false if it already exists |
