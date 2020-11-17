# Step 8: Consul (optional)

In this step, you will install Consul service mesh on your Kubernetes
cluster.

## Goals

* Install Consul service mesh
* Configure Consul's ingress gateway

## Tasks

**Windows users:** This section does not yet work on Windows.

### Uninstall NGINX
We will be using Consul for our ingress controller so we first need to
uninstall NGINX.

```bash
kubectl delete -f 4-networking/nginx-ingress.yaml
```

### Install Consul
To install Consul, add its Helm repo:

```bash
helm repo add hashicorp https://helm.releases.hashicorp.com
"hashicorp" has been added to your repositories
```

Then create a `values.yaml` file for your installation:
```yaml
global:
  name: consul
server:
  replicas: 1
  bootstrapExpect: 1
connectInject:
  enabled: true
controller:
  enabled: true
ingressGateways:
  enabled: true
  defaults:
    affinity: ""
  gateways:
    - name: ingress-gateway
      replicas: 1
      service:
        type: ClusterIP
        ports:
        - port: 80
```

Install Consul:

```bash
helm install consul hashicorp/consul -f values.yaml --wait
```

This may take 2-3 minutes.

### Patch Ingress
Because you're running on `kind` you need to patch Consul's ingress deployment
so it binds to the right port. `kubectl patch` edits a resource currently
running in Kubernetes.

```bash
kubectl patch deployment consul-ingress-gateway -p '[{"op":"add","path":"/spec/template/spec/containers/0/ports/1/hostPort","value":80}]' --type "json"
```

Wait for the deployment to roll out:

```bash
kubectl rollout status deploy/consul-ingress-gateway --watch
```

### View Consul UI
You can now view the Consul UI by port-forwarding:

```bash
kubectl port-forward svc/consul-ui 8500:80
```

And navigating to [http://localhost:8500/ui/](http://localhost:8500/ui/)

### Add api to the service mesh

The `api` service doesn't show up in the UI right now because it's not part of
the service mesh.

To add it to the service mesh we need to add the `consul.hashicorp.com/connect-injected: true` annotation:

```bash
kubectl patch deployment api -p '[{"op":"add","path":"/spec/template/metadata/annotations/consul.hashicorp.com~1connect-inject","value":"true"}]' --type "json"
```

Wait for the deployment to be ready:

```bash
kubectl rollout status deploy/api --watch
```

You should now see the `api` service in the Consul UI.

### Configure Ingress

You need to configure our ingress controller to route to our API service.

First, create a resource that sets the protocol of API to "http":

```bash
cat <<EOF | kubectl apply -f -
apiVersion: consul.hashicorp.com/v1alpha1
kind: ServiceDefaults
metadata:
  name: api
spec:
  protocol: http
EOF
```

Next, configure the ingress gateway
```bash
kubectl exec consul-server-0 -- echo '{"Kind":"ingress-gateway","Listeners":[{"Port":80,"Protocol":"http","Services":[{"Hosts":["api"],"Name":"api"}]}],"Name":"ingress-gateway"}' | consul config write -
```

### Test Ingress

We can test that our ingress is working by curling `http://api`:

```bash
curl http://api
{
  "name": "api-k8s",
  "uri": "/",
  "type": "HTTP",
  "ip_addresses": [
    "10.244.0.43"
  ],
  "start_time": "2020-10-21T16:46:04.921302",
  "end_time": "2020-10-21T16:46:04.921705",
  "duration": "402.9µs",
  "body": "Hello World",
  "code": 200
}
```

### Inject Failures
Now that our service mesh is working, let's try out some cool features.

We can cause our `api` service to return a 500 50% of the time:

```bash
kubectl patch deployment api -p '[{"op":"add","path":"/spec/template/spec/containers/0/env/1","value":{"name": "ERROR_RATE", "value": "0.5"}}]' --type "json"
```

Wait for the rollout:

```bash
kubectl rollout status deploy/api --watch
```

Now when you `curl http://api` you should see errors 50% of the time:
```bash
curl http://api
{
  "name": "api-k8s",
  "uri": "/",
  "type": "HTTP",
  "ip_addresses": [
    "10.244.0.54"
  ],
  "code": 500,
  "error": "Service error automatically injected"
}
```

### Resolve Failures
Because we're running a service mesh, we can configure it to automatically retry
failed requests:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: consul.hashicorp.com/v1alpha1
kind: ServiceRouter
metadata:
  name: api
spec:
  routes:
    - destination:
        numRetries: 3
        retryOnStatusCodes: [500]
EOF
```

Now when you `curl http://api` you shouldn't see any errors!

```bash
curl http://api
{
  "name": "api-k8s",
  "uri": "/",
  "type": "HTTP",
  "ip_addresses": [
    "10.244.0.54"
  ],
  "start_time": "2020-10-21T16:55:45.057104",
  "end_time": "2020-10-21T16:55:45.057368",
  "duration": "263.8µs",
  "body": "Hello World",
  "code": 200
}
```
