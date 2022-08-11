---
title: "Kubernetes the Hard Way Deep Dive -- 03 (Provisioning Compute Resources)"
date: 2020-04-13T14:39:41-08:00
bookToc: false
tags: [
  "Kubernetes",
  "KTHW"
]
categories: [
  "Deep Dive",
  "Tutorial"
]
---
 
**TL;DR:** Setting up a Virtual Private Cloud (network), configuring firewall rules, and provisioning the Compute Engine virtual machine instances!

**KTHW Lesson:** [03-compute-resources.md](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/03-compute-resources.md)

{{< img "images/gcp-k8s-resources.png" >}}

<!--more--> 

---
**Table of Contents:**
- [Networking](#networking)
  - [Default VPC](#default-vpc)
  - [Custom VPC + Subnets](#custom-vpc--subnets)
  - [Firewall Rules](#firewall-rules)
  - [Internal](#internal)
  - [External](#external)
- [Compute Instances (Virtual Machines)](#compute-instances-virtual-machines)
  - [Pricing](#pricing)
  - [VM configurations](#vm-configurations)
- [Connecting to VMs](#connecting-to-vms)

## Networking

### Default VPC

When the [Compute Engine API](https://console.cloud.google.com/apis/api/compute.googleapis.com/overview) is enabled within a GCP project, a default Virtual Private Cloud (named "default") is created. 

{{< img "images/default-vpc.png" "Default VPC: 22 subnets (1 per GCP region) + 4 firewall rules are created by default!" >}}

Using the default network makes the getting started with setting things up easy, but also enables any Compute Engine instances using that VPC to make network requests to one another using tcp, udp, or icmp protocols (based on the `default-allow-internal` firewall rule). 

### Custom VPC + Subnets

To isolate the Kubernetes cluster in this tutorial and minimize the attack surface area, we create a separate VPC with a single subnet and more restrictive firewall rules. Specifying the `--subnet-mode custom` when creating the VPC is what prevents GCP from auto-provisioning a subnet for each region. What about IP address range `--range` specified (`10.240.0.0/24`)?

The `/24` is what is known as classless inter-domain routing (CIDR) notation and is a shorthand way of specifying the subnet mask. 24 corresponds to the number of active bits in the subnet mask, so in this case the subnet mask is: `11111111.11111111.11111111.00000000` in binary (or `255.255.255.0` in decimal).

This subnet mask denotes that the first 3 octets `10.240.0.` will be the same across the entire subnet and the final octet can vary throughout its full range from `0` to `255`. The highest address (`10.240.0.255`) is the "[broadcast address](https://en.wikipedia.org/wiki/Broadcast_address)", leaving 254 open for IP addresses (as Kelsey states).

For a more in depth look at Network ID's and Subnet Masks, this YouTube video is a great resource:

{{< youtube XQ3T14SIlV4 >}}

### Firewall Rules 

We are also creating two firewall rules, one which will allow internal traffic and another for external traffic.

### Internal

The internal firewall rule allows tcp, udp, and icmp traffic originating from the IP range specified for the above subnet (`10.240.0.0/24`) as well as `10.200.0.0/16` which is the CIDR range that will be passed into the `kube-controller-manager` to be used for pod IP address assignment.

### External

The external firewall rule (it is external because the filter is `0.0.0.0/0` indicating that **any** originating IP address is acceptable) allows for tcp traffic on port 22 (used for SSH), tcp traffic on port 6443 (used to communicate with the [Kubernetes API server](https://kubernetes.io/docs/reference/access-authn-authz/controlling-access/#transport-security)), and icmp on any port (used by network devices to diagnose communication issues)

## Compute Instances (Virtual Machines)

With the networking configuration set up, we can now provision the Compute Engine Instances (VMs) for the Kubernetes control plane as well as those that will serve as the Kubernetes workers.

### Pricing

This tutorial sets up 3 control plane nodes and 3 worker nodes of type `n1-standard-1` each with a 200 GB boot disk. looking at GCP's pricing calculator we can see within the us-central1 region this will cost [$193.63/month](https://cloud.google.com/products/calculator#id=b7572205-01ef-4498-8e16-c11059136362)

While the Compute Engine instances comprise the bulk of the costs, a load balancer will cost an additional $18.26/month bringing the total to [$211.89/month](https://cloud.google.com/products/calculator/#id=b854a15b-2c79-494a-b38c-ba28b3b084bf). 

*NOTE:* This is higher than the number cited in the tutorial because it accounts for the persistent storage charges.

### VM configurations

Within the `gcloud compute instances create` command, there are a number of command line flags used to configure the virtual machines. Below I have detailed the noteworthy options:

  - `--can-ip-forward`: allows the instances to send and receive packets with non-matching destination or source IP addresses.
  - `--private-network-ip 10.240.0.1${i}` substituting in the iterator `i` we can see that our controller VMs will have all fall within the range of our subnet from earlier:
```
Controllers:
  10.240.0.10, 10.240.0.11, 10.240.0.12
```
```
Workers:
  10.240.0.20, 10.240.0.21, 10.240.0.22
```
  - `--subnet kubernetes`: references the subnet by name.
  - `--metadata pod-cidr=10.200.${i}.0/24` (worker VMs only): This metadata is available to the guest operating system. It will be used in [09-bootstrapping-kubernetes-workers.md](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/09-bootstrapping-kubernetes-workers.md) to generate a network configuration file that tells k8s which internal IP addresses to assign to pods.

## Connecting to VMs

The use of the `gcloud compute ssh` command is straight-forward and no additional commentary is needed.

At this point, we now have networking + compute resources provisioned and configured. Next, we will generate certificates and keys to enable secure communications amongst the machines.

See you in the next post!
