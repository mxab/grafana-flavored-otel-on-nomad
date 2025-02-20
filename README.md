# Grafana flavored OpenTelemetry on Nomad

This repository contains the demo code from my talk @ HashiTalks 2025


## Setup

### Requirements

- [Nomad](https://developer.hashicorp.com/nomad/install)
- [Docker](https://docs.docker.com/get-docker/)

### Run Dev Cluster

```bash
sudo nomad agent -dev -network-interface="en0" -bind="0.0.0.0"
```

### Grafana LGTM

```bash

cd nomad/lgmt

nomad run lgtm.nomad.hcl
```

Open Grafana at `http://<en0 ip address>:3000`

### Grafana Alloy Gateway

```bash
cd nomad/gateway

nomad run gateway.nomad.hcl
```

You can inspect the gateway ui by going to the nomad allocation and take the address from the `ui` port.

### Grafana Alloy Agent

```bash
cd nomad/agent

nomad run agent.nomad.hcl
```
You can inspect the agent ui at `http://<en0 ip address>:12345`

## Run the demo

### Build the apps

```bash
cd apps

./gradlew bootImage
```

#### Run the apps


```bash
cd cd apps/salutation-provider

nomad run salutation-provider.nomad.hcl
# or the instrumented version
nomad run salutation-provider-instrumented.nomad.hcl
```

```bash
cd apps/hello-world

nomad run hello-world.nomad.hcl
# or the instrumented version
nomad run hello-world-instrumented.nomad.hcl
```

The hello-world app will be available at `http://<en0 ip address>:8080`.

When you run the instrumented version of the apps, you can start exploring the signals in Grafana.

## NACP

For the demo we run the [Nomad Admission Control Proxy](https://github.com/mxab/nacp) locally.

```bash
cd nomad/nacp
nacp -config=nacp.conf.hcl
```

You can now deploy the uninstrumented version of the apps by pointing the nomad cli to the proxy.


```bash
cd apps/hello-world
NOMAD_ADDR=http://localhost:6464 nomad run hello-world.nomad.hcl
```

Check the nomad ui to inspect the job