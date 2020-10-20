# Step x: Logging

In this step, we will add a logging platform and forward our application logs to it. 

## Goals

* Install and configure Elastic, Kibana, and Fluentd on Kubernetes. 

## Tasks

#### Deploy ECK (Elastic Cloud on Kubernetes)

First, we will deploy the Elastic operator (ECK) on Kubernetes. The line below comes from [Elastic docs](https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-deploy-eck.html).

```bash
kubectl apply -f https://download.elastic.co/downloads/eck/1.2.1/all-in-one.yaml
```

#### Deploy Elastic cluster

Now we can use the ECK operator to create an Elastic cluster.

```yaml
apiVersion: elasticsearch.k8s.elastic.co/v1
kind: Elasticsearch
metadata:
  name: kubecon
  namespace: kube-system
spec:
  version: 7.9.2
  nodeSets:
    - name: default
      count: 1
      podTemplate:
        spec:
          containers:
            - name: elasticsearch
              env:
                - name: ES_JAVA_OPTS
                  value: -Xms1g -Xmx1g
              resources:
                requests:
                  memory: 1Gi
                limits:
                  memory: 1Gi
```

Make sure the cluster is healthy:

```bash
$ kubectl get elasticsearch -n kube-system
NAME      HEALTH   NODES   VERSION   PHASE   AGE
kubecon   green    1       7.9.2     Ready   6m54s
```

#### Deploy Kibana cluster

```yaml
apiVersion: kibana.k8s.elastic.co/v1
kind: Kibana
metadata:
  name: kubecon
  namespace: kube-system
spec:
  version: 7.9.2
  count: 1
  elasticsearchRef:
    name: kubecon
```

Make sure all components have come up and are healthy

```bash
$ kubectl get kibana -n kube-system
NAME      HEALTH   NODES   VERSION   AGE
kubecon   green    1       7.9.2     79s
```

#### Log in to the Kibana instance

First, get the username and password from the secret:

```bash
kubectl get secret -n kube-system kubecon-es-elastic-user -o go-template='{{.data.elastic | base64decode}}'
```

Port-forward the Kibana service so we can access it locallyL

```bash
kubectl port-forward -n kube-system service/kubecon-kb-http 5601
```

Go to https://localhost:5601 in your browser and log in using the `elastic` user and the password from above.

#### Forward application logs with Fluentd

Next, we need to deploy Fluentd as a daemonset and configure it to forward all logs to Elastic.

Create the fluentd daemonset:

```bash
kubectl apply -f fluentd.yaml
```

Make sure fluentd is running:

```bash
$ kubectl get ds fluentd -n kube-system
NAME      DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
fluentd   1         1         1       1            1           <none>          17s
```

#### Create logging index in Kibana

Go to the Kibana UI at https://localhost:5601. Then navigate to "Discover" under "Kibana".
