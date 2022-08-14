---
title: "Converting an Old MacBook Into an Always-On Personal Kubernetes Cluster"
date: 2020-03-10T09:05:24-07:00
bookToc: false
tags: [
  "Kubernetes",
  "Minikube"
]
categories: [
  "Tutorial"
]
---

**TL;DR:** I set up Minikube on an old (2012) MacBook Air and configured it to be able to connect from outside my home network so I would have an always-on Kubernetes cluster at home to experiment with.

{{< img "images/macbook-air.jpg" >}}

*Photo Attribution: [flickr](https://flickr.com/photos/pahudson/5127789519/in/photolist-8P8gb8-afjVVd-sVaUtd-4vxyii-8PbmZQ-4vBEo3-4vxyGR-4vBEx9-4m6Uar-4Ykxb1-4vxysv-4xrcrc-5XtHJY-5Xpuee-5Xpuve-4m9FUL-9dUh84-5XpvMz-5XtHTq-66nicm-4Ygiht-4s33cu-5XtHrb-4YkxAy-8NuFUn-4YkxL9-4Ygi84-7daFrV-4C92kK-4YkM85-7dexwb-5XtJaL-7dexW7-7dexPG-5Xpwax-fA3EnA-5XtKSh-ea6KL6-coVFws-coVJSu-4ud9UZ-5QLfy1-7ViDVD-dfYj9B-68FXdw-68BHUH-68BHzM-68BHEk-68FWYo-68FXCf)*

<!--more--> 

---

Table of Contents:
- [Why?](#why)
- [Power/Cost Considerations](#powercost-considerations)
- [Process](#process)
  - [0) Prevent Server System from Sleeping](#0-prevent-server-system-from-sleeping)
  - [1) Install Minikube on the Server System](#1-install-minikube-on-the-server-system)
  - [2) Install `kubectl` on the Client System](#2-install-kubectl-on-the-client-system)
  - [3) Add port forwarding rule from the Server System to the Minikube VM](#3-add-port-forwarding-rule-from-the-server-system-to-the-minikube-vm)
  - [4) Update the `.kube/config` on the Client to Point to the Server](#4-update-the-kubeconfig-on-the-client-to-point-to-the-server)
  - [5) (Optional) Use DDNS + Router Port Forwarding to Access Outside Local Network](#5-optional-use-ddns--router-port-forwarding-to-access-outside-local-network)
- [Conclusion](#conclusion)

## Why?

Over the past five years, Kubernetes (k8s) has risen to become the de facto standard for managing container orchestration at scale. 

However, with many layers of abstraction and [non-trivial costs]({{< ref "/posts/2020/03/managed-kubernetes-comparison/index.md" >}}) to run even the smallest cloud-based cluster, the barriers to entry for an individual who wants to familiarize themselves with Kubernetes can be quite high. 

There are a variety of options for running Kubernetes locally including [Minikube](https://github.com/kubernetes/minikube), [Docker Desktop](https://www.docker.com/products/kubernetes), and [Microk8s](https://microk8s.io/). These are all good options for aiding in the development process, but all suffer from the fact that they are tied to the power status of the system they are running on (i.e. if I shut down my laptop, the local cluster shuts down too). In order to run workloads that are either time-dependent (cronjobs) or event-driven (asynchronous data processing), it would be much better to have a cluster that is always on.

I happen to have a 2012 MacBook Air sitting around unused now that it is no longer my daily driver. Amazingly, this 8-year-old system has a CPU that supports the necessary [software-based virtualization](https://en.wikipedia.org/wiki/X86_virtualization) to run a Linux virtual machine where we can install Kubernetes.

## Power/Cost Considerations

Because my goal is to achieve a low-cost solution, I wanted to do a quick calculation of how much power this laptop will use if I leave it running 24x7. Based on this [environmental spec sheet from apple](https://www.apple.com/environment/pdf/products/archive/2012/13inch_macbookair_per_june2012.pdf) I estimate the system (with the display off and relatively light workloads) will draw approximately 10W on average.

{{< img "images/mba-power.png" >}}

Pricing Estimate:
```bash
  10 (W) 
x 1/1000 (W/kW) 
x 24 (hrs/day) 
x 30.4 (days/month) 
x 0.2 ($/kWh)
---
1.44 $/month -- 👍
```

## Process

### 0) Prevent Server System from Sleeping

Because the MacBook Air is not designed to be used in this configuration, it is necessary to disable sleep using the power management settings (`pmset`) command line utility. The following commands will make the time to sleep infinite as well as prevent sleeping when there is no display connected:

```bash
sudo pmset -a sleep 0; 
sudo pmset -a disablesleep 1
```

### 1) Install Minikube on the Server System

I followed these instructions ([Minikube Installation Instructions](https://kubernetes.io/docs/tasks/tools/install-minikube/)) using the VitualBox hypervisor + vm-driver to install Minikube on the MacBook air: 

### 2) Install `kubectl` on the Client System

I already had `kubectl` installed on my primary development machine, but you could follow these instructions ([Kubectl Installation Instructions](https://kubernetes.io/docs/tasks/tools/install-kubectl/)) to install it on the system you plan to access the cluster from. 

### 3) Add port forwarding rule from the Server System to the Minikube VM

In order for `kubectl` commands to make their way to the Minikube cluster, it is necessary to set up a port forwarding rule within the VM configuration to forward requests to port 8443. This can be accomplished via the VirtualBox GUI:

{{< img "images/minikube-port-forward.png" >}}

### 4) Update the `.kube/config` on the Client to Point to the Server

When executing the `minikube start` command on the server system, a kubectl context called 'minikube' is added to the kubectl configuration file @ `~/.kube/config`:

```yaml
apiVersion: v1
clusters:
- cluster:
    certificate-authority: <PATH-TO-CONFIG>/.minikube/ca.crt
    server: https://192.168.99.100:8443
  name: minikube
contexts:
- context:
    cluster: minikube
    user: minikube
  name: minikube
current-context: "minikube"
kind: Config
preferences: {}
users:
- name: minikube
  user:
    client-certificate: <PATH-TO-CONFIG>/.minikube/client.crt
    client-key: <PATH-TO-CONFIG>/.minikube/client.key
```

This configuration needs to be copied onto the client machine (along with the `client.crt` and `client.key` files).

I copied those files to `<PATH-TO-CONFIG>/.minikube-macbook-air` on the client system and updated the kubectl configuration as follows:

```yaml
apiVersion: v1
clusters:
- cluster:
    insecure-skip-tls-verify: true
    server: https://<INTERNAL-NETWORK-IP>:51928
  name: minikube-macbook-air
contexts:
- context:
    cluster: minikube-macbook-air
    user: minikube-macbook-air
  name: minikube-macbook-air
current-context: "minikube-macbook-air"
kind: Config
preferences: {}
users:
- name: minikube-macbook-air
  user:
    client-certificate: <PATH-TO-CONFIG>/.minikube-macbook-air/client.crt
    client-key: <PATH-TO-CONFIG>/.minikube-macbook-air/client.key
```

This can either be inserted as a context within the primary `.kube/config` file or stored as a separate configuration and used by setting the `KUBECONFIG` environment variable ([documentation](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/#set-the-kubeconfig-environment-variable))

*Note:* The `insecure-skip-tls-verify: true` is used because the certificate authority set up by Minikube is not configured to accept incoming requests originating from another system in this way.

### 5) (Optional) Use DDNS + Router Port Forwarding to Access Outside Local Network

At this point, I was able to connect to the cluster, but only when the Client and Server systems were connected to the same network. 

Two additional things needed to be configured to connect from outside of my home network:

  1) I set up a free dynamic DNS using https://www.dynu.com/. After doing this I replaced `<INTERNAL-NETWORK-IP>` with `<MY-DDNS-DOMAIN-NAME>` 
  2) I configured my router to port forward incoming requests on port `51928` to the MacBook Air and reserve the IP address for the MAC Address of the machine to ensure it doesn't change.
   
At this point I was able to successfully connect to the cluster from an external network!

{{< img "images/kubectl-get-nodes.png" >}}

## Conclusion

There we have it -- For about the price of a McDonald's coffee each month in electricity, I have an always-on Kubernetes cluster (with a single 2 vCPU + 2 GB Memory node) ready for experimentation!  

If I didn't happen to have the MacBook Air sitting around, building a home cluster using Raspberry Pis is another popular option (and enables having more than just a single worker node).
