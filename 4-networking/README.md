# Step 4: Networking

In this step, we will expose our API service so that web can talk to it.

## Goals

* Learn about the Kubernetes networking model
* Expose the API service using NGINX ingress

## Tasks

### Kubernetes Service

1. Create a service for the API deployment that we will later use for ingress

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
   ```
   
   ```bash
   kubectl apply -f service.yaml
   ```

### Ingress

1. Install NGINX ingress controller into your cluster
   
   ```bash
    kubectl apply -f nginx-ingress.yaml
   ```
   
   Wait for the ingress controller to become healthy
   
   ```bash
   kubectl get pods -n ingress-nginx
   ```

1. Create an ingress configuration file

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

1. Apply the file:

  ```bash
  kubectl apply -f ingress.yaml
  ```

1. Verify that the we can reach the service from our local machine:

   ```bash
   $ curl localhost
   {
     "name": "api",
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