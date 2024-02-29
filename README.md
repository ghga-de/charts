# The GHGA Library for Kubernetes

Configurations for most GHGA microservice, ready to launch on Kubernetes using [Kubernetes Helm](https://github.com/helm/helm).

## TL;DR

```bash
helm repo add ghga https://ghga-de.github.io/charts
helm search repo ghga
helm install my-release ghga/<chart>
```

```bash
# Update dependencies for all charts
find ./charts -maxdepth 1 -type d -exec sh -c 'chart_name=$(basename "$1"); echo "Updating dependencies for chart: $chart_name"; helm dep up "$1"' sh {} \;
```
