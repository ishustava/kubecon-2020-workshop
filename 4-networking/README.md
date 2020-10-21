# Step 4: Networking

In this step, we will expose our API service so that web can talk to it.

## Goals

* Learn about the Kubernetes networking model
* Expose the API service using NGINX ingress

## Tasks

### Kubernetes Service

Create a ClusterIP service for the API deployment that we will later use for ingress.

   ```yaml
   apiVersion: v1
   kind: Service
   metadata:
     name: api
   spec:
     selector:
       app: api
     ports:
       - port: 9090
         targetPort: 80
   ```
   
   ```bash
   $ kubectl apply -f service.yaml
   service/api created
   ```
   
Check that the service is created:
   
   ```bash
   $ kubectl get service
   NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
   api          ClusterIP   10.96.125.162   <none>        9090/TCP   105s
   kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP    69m
   ```
   
Verify that the `api` service has endpoints:
   
   ```bash
   $ kubectl get endpoints
   NAME         ENDPOINTS         AGE
   api          10.244.0.5:9090   3m6s
   kubernetes   172.18.0.2:6443   71m
   ```
   
ClusterIP services are only reachable from within the cluster.
To verify that we can talk to our API service,
we'll create a temporary pod and try to curl the api service from there.
   
   ```bash
   $ kubectl run -it test-api --image tutum/curl --restart Never -- curl http://api:9090
   {
     "name": "api-k8s",
     "uri": "/",
     "type": "HTTP",
     "ip_addresses": [
       "10.244.0.5"
     ],
     "start_time": "2020-10-21T01:48:28.993496",
     "end_time": "2020-10-21T01:48:28.993634",
     "duration": "138.1µs",
     "body": "Hello World",
     "code": 200
   }
   ```
   
Delete the `test-api` pod:
   
   ```bash
   kubectl delete po/test-api
   ```

### Ingress

First, install NGINX ingress controller into your cluster.
   
```bash
$ kubectl apply -f nginx-ingress.yaml
namespace/ingress-nginx created
serviceaccount/ingress-nginx created
configmap/ingress-nginx-controller created
clusterrole.rbac.authorization.k8s.io/ingress-nginx created
clusterrolebinding.rbac.authorization.k8s.io/ingress-nginx created
role.rbac.authorization.k8s.io/ingress-nginx created
rolebinding.rbac.authorization.k8s.io/ingress-nginx created
service/ingress-nginx-controller-admission created
service/ingress-nginx-controller created
deployment.apps/ingress-nginx-controller created
validatingwebhookconfiguration.admissionregistration.k8s.io/ingress-nginx-admission created
serviceaccount/ingress-nginx-admission created
clusterrole.rbac.authorization.k8s.io/ingress-nginx-admission created
clusterrolebinding.rbac.authorization.k8s.io/ingress-nginx-admission created
role.rbac.authorization.k8s.io/ingress-nginx-admission created
rolebinding.rbac.authorization.k8s.io/ingress-nginx-admission created
job.batch/ingress-nginx-admission-create created
job.batch/ingress-nginx-admission-patch created
```
   
Wait for the ingress controller to become healthy.
   
```bash
$ kubectl get pods -n ingress-nginx
NAME                                       READY   STATUS      RESTARTS   AGE
ingress-nginx-admission-create-5lgm2       0/1     Completed   0          46s
ingress-nginx-admission-patch-htg5m        0/1     Completed   0          46s
ingress-nginx-controller-b9fbd76f4-6dfh8   1/1     Running     0          46s
```

Next, create an ingress configuration file and apply it to the cluster:

```yaml
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
 name: api
spec:
 rules:
   - http:
       paths:
         - path: /
           backend:
             serviceName: api
             servicePort: 9090
```

```bash
$ kubectl apply -f ingress.yaml
ingress.networking.k8s.io/api created
```

Finally, Verify that the we can reach the service from our local machine:

```bash
$ curl localhost
{
 "name": "api-k8s",
 "uri": "/",
 "type": "HTTP",
 "ip_addresses": [
   "10.244.0.5"
 ],
 "start_time": "2020-10-20T18:15:18.558101",
 "end_time": "2020-10-20T18:15:18.558261",
 "duration": "160.3µs",
 "body": "Hello World",
 "code": 200
}
```
   
## Conclusion

We can now reach API from our local machine.

## Next Step

Go to [5-logging](../5-logging/README.md).