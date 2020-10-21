## Step 2: Dockerize
In this step, you will build a Docker image for the `api` service.

## Goals
* Docker image is built for the `api` service.
* Docker image has been tested.

## Tasks

### Dockerfile
A `Dockerfile` is like a build script for the Docker image. 

#### Base Image
First, you need to decide what base image your image will build on. The base
image must contain all the libraries and tooling that your application requires.
For example, if you want to run `node` then your base image must contain
`node` or you'll need to add it in your own `Dockerfile`.

In your case, you're going to use `alpine`, specifically the latest image `alpine:3.12.0`.
`alpine` is a small base image that contains a number of utilities like `ls`,
`cd` and `curl` that can be useful if you need to run commands inside of our container.

You specify the base image with:
```dockerfile
FROM alpine:3.12.0
```

After deciding on a base image, you need to ensure your image has everything
needed to run `api`.  If you look at the start script for `api`,
`vms/start-api-darwin.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

export NAME="api-vm"
export LISTEN_ADDR="127.0.0.1:80"

./$(dirname "$0")/../bin/api/api-darwin
```

You'll see `export` instructions and finally the execution of `api-darwin`.

#### Environment Variables

The `export` commands can be replicated in your Docker image with the `ENV`
instruction.

You'll need to make the following changes:
1. `NAME` should be `api-k8s` (not `api-vm`) so you know when you're talking to the `api`
   service running on Kubernetes
1. `LISTEN_ADDR` should be `0.0.0.0:80` (not `127.0.0.1:80`) so that `api` binds
   to all interfaces in the container. If you only bound to `127.0.0.1` then you
   could only make calls to `api` from inside the container. Since we need to
   be able to make calls to `api` from outside it's container, i.e. from `web`,
   this must be `0.0.0.0`.

```dockerfile
ENV NAME="api-k8s"
ENV LISTEN_ADDR="0.0.0.0:80"
```

### Binary

Next, you'll want to add your binary to the image. You can use the `COPY` instruction
to copy the binary from your `bin` directory into the Docker image.

**NOTE:** You want to use the linux binary `bin/api/api-linux` because your Kubernetes
cluster is running on linux.

```dockerfile
COPY ./bin/api/api-linux /app/api
```

In order to ensure the directory `/app` exists, you need to run `mkdir /app`.
You can run commands using the `RUN` instruction:

```dockerfile
RUN mkdir /app
COPY ./bin/api/api-linux /app/api
```

#### Entrypoint
Finally, you'll need to specify the default command that gets run when the
container is started. In your case, you'll want to start `api`:

```dockerfile
ENTRYPOINT ["/app/api"]
```

#### Final Dockerfile
Putting it all together, your Dockerfile should look like:

```dockerfile
FROM alpine:3.12.0
ENV NAME="api-k8s"
ENV LISTEN_ADDR="0.0.0.0:80"
RUN mkdir /app
COPY ./bin/api/api-linux /app/api
ENTRYPOINT ["/app/api"]
```

Create this file in the root of the repo with the name `Dockerfile`.

### Docker build
To build your Docker image, run:
```bash
docker build .

Sending build context to Docker daemon  197.8MB
Step 1/6 : FROM alpine:3.12.0
 ---> a24bb4013296
Step 2/6 : ENV NAME="api-k8s"
 ---> Running in 2bb827646e38
Removing intermediate container 2bb827646e38
 ---> 94ee0441e50a
Step 3/6 : ENV LISTEN_ADDR="0.0.0.0:80"
 ---> Running in ab4eb850054f
Removing intermediate container ab4eb850054f
 ---> 7a69d6e3bfd4
Step 4/6 : RUN mkdir /app
 ---> Running in cdc5c8bf761d
Removing intermediate container cdc5c8bf761d
 ---> 71a025b7a0ef
Step 5/6 : COPY ./bin/api/api-linux /app/api
 ---> b53b52c72b2c
Step 6/6 : ENTRYPOINT ["/app/api"]
 ---> Running in 009cd448cbd9
Removing intermediate container 009cd448cbd9
 ---> b4227513fc2c
Successfully built b4227513fc2c
```

In the root of the repo.

The last line should give you the image id:
```bash
Successfully built b4227513fc2c
```

### Docker run
You should test your image before deploying it to Kubernetes. To do so,
start it using `docker run`. You'll need to also pass `--publish` so that
a port on your machine is forwarded to the Docker container:
```bash
docker run --publish 8888:80 b4227513fc2c

2020-10-20T21:54:24.603Z [INFO]  Starting service: name=api-k8s upstreamURIs= upstreamWorkers=1 listenAddress=0.0.0.0:80 service type=http
2020-10-20T21:54:24.603Z [INFO]  Adding handler for UI static files
2020-10-20T21:54:24.603Z [INFO]  Settings CORS options: allow_creds=false allow_headers=Accept,Accept-Language,Content-Language,Origin,Content-Type allow_origins=*
```

**NOTE: Use your image ID from above**

If the logs show up, then your image works!

You should then be able to go to [http://localhost:8888](http://localhost:8888):
```json
{
  "name": "api-k8s",
  "uri": "/",
  "type": "HTTP",
  "ip_addresses": [
    "172.17.0.2"
  ],
  "start_time": "2020-10-20T21:56:55.853603",
  "end_time": "2020-10-20T21:56:55.854622",
  "duration": "1.018953ms",
  "body": "Hello World",
  "code": 200
}
```

`"name"` should be `api-k8s`. This proves your Docker image can serve traffic
as expected.

`Ctrl-C` the `docker run` command to stop the container.

### Docker publish
Your Docker image only exists on your machine right now. In order for Kubernetes
to run it, it must be published to a registry.

If you already have a Docker hub account, you can tag the image and then `push` it:
```bash
docker tag b4227513fc2c docker.io/lkysow/api:v0.1.0
docker push docker.io/lkysow/api:v0.1.0
```

If you don't have a Docker hub account, you can load the Docker image directly
into the Kubernetes cluster because for the tutorial the cluster is running
locally.

#### Start the Kubernetes cluster
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

First, stop the `web` and `api` services. Then start kind using the command
above, then restart the `web` and `api` services using their start scripts.

#### Load your docker image into kind
To load your Docker image into your local `kind` Kubernetes cluster, tag it and
then use the
`kind load` command:
```bash
docker tag b4227513fc2c docker.io/lkysow/api:v0.1.0
kind load docker-image docker.io/lkysow/api:v0.1.0

Image: "docker.io/lkysow/api:v0.1.0" with ID "sha256:b4227513fc2c3323d389c3eecf4c248e4bd7a3bcd70483f6b33ada37e936c5a5" not yet present on node "kind-control-plane", loading...
```

## Conclusion
In this section, you created a `Dockerfile`, built a Docker image, and pushed
it to a registry or directly to `kind`.

## Next Step

Go to [3-kubernetize](../3-kubernetize/README.md).
