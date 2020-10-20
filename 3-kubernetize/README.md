## Overview
In this stage, you will deploy the `api` service to Kubernetes.

## Start Kubernetes
For this tutorial you will be running Kubernetes locally on your
machine using `kind`. `kind` stands for "Kubernetes in Docker" and is an
easy way to run Kubernetes locally.

If you haven't already started `kind`, run the start script:`

```bash
./k8s/start-kind.sh

 ✓ Ensuring node image (kindest/node:v1.19.1) 🖼
 ✓ Preparing nodes 📦
 ✓ Writing configuration 📜
 ✓ Starting control-plane 🕹️
 ✓ Installing CNI 🔌
 ✓ Installing StorageClass 💾
Set kubectl context to "kind-kind"
You can now use your cluster with:

kubectl cluster-info --context kind-kind

Have a nice day! 👋
```

**NOTE:** If you get an error like:
```
ERROR: failed to create cluster: docker run error: command "docker run --hostname kind-control-plane
 --name kind-control-plane --label io.x-k8s.kind.role=control-plane --privileged --security-opt seccomp=unconfined
 --security-opt apparmor=unconfined --tmpfs /tmp --tmpfs /run --volume /var --volume /lib/modules:/lib/modules:ro --detach
 --tty --label io.x-k8s.kind.cluster=kind --net kind --restart=on-failure:1 --publish=0.0.0.0:80:80/TCP --publish=0.0.0.0:443:443/TCP
 --publish=127.0.0.1:61433:6443/TCP kindest/node:v1.19.1@sha256:98cf5288864662e37115e362b23e4369c8c4a408f99cbc06e58ac30ddc721600"
 failed with error: exit status 125
```

First, stop the `web` and `api` services you're running locally. Then start kind using the command
above, then restart the `web` and `api` services using their start scripts.

## Verify Kind

Verify that `kind` is working by running:
```bash
kubectl get node
NAME                 STATUS   ROLES    AGE   VERSION
kind-control-plane   Ready    master   33m   v1.19.1
```

## Pod
A pod is a single replica of the application. Its specification looks like:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: api
spec:
  containers:
    - name: api
      image: docker.io/lkysow/api:v0.1.0
      ports:
        - containerPort: 80
```

Create a file `pod.yaml` with the above contents. Change the `image` to
whatever image name you tagged yours as.

Then apply the yaml file to your Kubernetes cluster with `kubectl`:

```bash
kubectl apply -f pod.yaml
pod/api created
```

You can see if it's working by running:
```bash
kubectl get pod
NAME   READY   STATUS    RESTARTS   AGE
api    1/1     Running   0          25s
```

You can get its logs by running:
```bash
kubectl logs api
2020-10-20T22:41:59.587Z [INFO]  Starting service: name=api-k8s upstreamURIs= upstreamWorkers=1 listenAddress=0.0.0.0:80 service type=http
2020-10-20T22:41:59.587Z [INFO]  Adding handler for UI static files
2020-10-20T22:41:59.587Z [INFO]  Settings CORS options: allow_creds=false allow_headers=Accept,Accept-Language,Content-Language,Origin,Content-Type allow_origins=*
```

A pod isn't enough though. If it gets deleted, or the node it's
running on crashes, it will never be restarted:

```bash
kubectl delete pod api
pod "api" deleted
```

```kubectl get pod
No resources found in default namespace.
```

## Deployment
What you need is a deployment. A deployment starts pods but also manages them to ensure
the right number is running.

Create a `deployment.yaml` file:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
  labels:
    app: api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
        - name: api
          image: docker.io/lkysow/api:v0.1.0
          ports:
            - containerPort: 80
```

Change the `image` to your image name and then apply the deployment:
```bash
kubectl apply -f deployment.yaml
deployment.apps/api create
```

Ensure it's been applied:

```bash
kubectl get deployment
NAME   READY   UP-TO-DATE   AVAILABLE   AGE
api    1/1     1            1           24s
```

You can see the pod it's created:

```bash
kubectl get pod
NAME                  READY   STATUS    RESTARTS   AGE
api-56dbdd4fc-jbr22   1/1     Running   0          61s
```

If you delete the pod, you'll see another one get created:

```bash
kubectl delete pod api-56dbdd4fc-jbr22
pod "api-56dbdd4fc-jbr22" deleted

kubectl get pod
NAME                  READY   STATUS    RESTARTS   AGE
api-56dbdd4fc-7n6md   1/1     Running   0          6s
```

## Verify
Verify that the deployment is working as expected by using the `kubectl port-forward`
command:

```bash
kubectl port-forward api-56dbdd4fc-7n6md 8888:80
Forwarding from 127.0.0.1:8888 -> 80
Forwarding from [::1]:8888 -> 80
```

If you navigate to [http://localhost:8888/](http://localhost:8888/) you should
see:

```json
{
  "name": "api-k8s",
  "uri": "/",
  "type": "HTTP",
  "ip_addresses": [
    "10.244.0.7"
  ],
  "start_time": "2020-10-20T22:53:17.988606",
  "end_time": "2020-10-20T22:53:17.990155",
  "duration": "1.548424ms",
  "body": "Hello World",
  "code": 200
}
```

## Conclusion
`api` is now running on Kubernetes!
