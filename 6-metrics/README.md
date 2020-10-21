# Step x: Metrics

In this step, we will add a logging platform and forward our application logs to it. 

## Goals

* Install Prometheus
* Install Grafana
* Modify application configuration so that prometheus could scrape metrics
* Look at app metrics in Grafana

## Tasks

#### Install Prometheus using the Helm chart

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add stable https://kubernetes-charts.storage.googleapis.com/
helm install prometheus prometheus-community/prometheus
```

Make sure everything is running:
```yaml
kubectl get pods
```

#### Install Grafana usisng the Helm chart

```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm install grafana grafana/grafana
```

Note the password in the output of `helm install`. You will need to it to login to Grafana.

#### Add Prometheus datasource to Grafana

First, port-forward Grafana service so we can reach it locally.

```bash
kubectl port-forward svc/grafana 3000:80
```

Next, go to `http://localhost:3000` in your browser.

