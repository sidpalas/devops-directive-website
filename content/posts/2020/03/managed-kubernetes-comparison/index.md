---
title: "Managed Kubernetes Price Comparison (2020)"
date: 2020-03-05T07:45:43-08:00
bookToc: false
tags: [
  "Kubernetes",
  "Amazon Web Services",
  "Google Cloud Platform",
  "Azure",
  "Elastic Kubernetes Service",
  "Google Kubernetes Engine",
  "Azure Kubernetes Service",
  "Digital Ocean"
]
categories: [
  "Comparison",
]
---

**TL;DR:** Azure and Digital Ocean don't charge for the compute resources used for the control plane, making AKS and DO the cheapest for running many, smaller clusters. For running fewer, larger clusters GKE is the most affordable option. Also, running on spot/preemptible/low-priority nodes or long-term committed nodes makes a massive impact across all of the platforms.

{{< img "images/k8s-price-graph.png" >}}


<!--more--> 

--- 

**Table of Contents:**

- [Overview](#overview)
- [Cost Breakdown](#cost-breakdown)
- [Jupyter Notebook](#jupyter-notebook)
- [Takeaways](#takeaways)

---

### Overview

With Google Cloud's recent announcement to [start charging $0.10/hour for each cluster](https://news.ycombinator.com/item?id=22485625) on GKE, it seemed like a good time to revisit pricing across the major managed Kubernetes offerings.

{{< img-link "images/gke-price-increase.png" "https://news.ycombinator.com/item?id=22485625" "This upset some people on the internet..." >}}

This article will focus on: 
- Google Kubernetes Engine (GCP) -- [pricing calculator](https://cloud.google.com/products/calculator)
- Elastic Kubernetes Service (AWS) -- [pricing calculator](https://calculator.s3.amazonaws.com/index.html)
- Azure Kubernetes Service (Azure) -- [pricing calculator](https://azure.microsoft.com/en-us/pricing/calculator/)
- Kubernetes on Digital Ocean -- [pricing page](https://www.digitalocean.com/pricing/)

### Cost Breakdown

The cost of running Kubernetes on each of these platforms is based on the following components:

- Cluster Management Fee
- Load Balancer (for Ingress)
- Worker Node Compute Resources (vCPU & Memory)
- Data Egress
- Persistent Storage
- Load Balancer Data Processing
  
Additionally, the cloud providers offer large discounts if you are willing/able to use preemptible/spot/low-priority nodes OR commit to using the same nodes for 1-3 years.

It is important to point out that while cost is a useful dimension to examine when evaluating providers, there are other factors that should also be considered including:
- Uptime (Service Level Agreement)
- Surrounding Cloud Ecosystem
- k8s Version Availability
- Documentation/Tooling Quality

Those factors are beyond the scope of this article/exploratory analysis. This [blog post from StackRox (Feb. 2020)](https://www.stackrox.com/post/2020/02/eks-vs-gke-vs-aks/) provides a detailed look at the non-price factors for EKS, AKS, and GKE.

---

### Jupyter Notebook

To make it easier to explore the cost tradeoffs I created a Jupyter notebook using plotly + ipywidgets to facilitate rapid exploration of cluster sizes/tradeoffs across the different cloud providers.

You can interact with a live version of that notebook yourself using Binder: 

{{< img-link "images/binder.png" "https://mybinder.org/v2/gh/sidpalas/managed-kubernetes-pricing/master?filepath=%2Fmanaged-kubernetes-price-exploration.ipynb" >}}
{{< link "https://mybinder.org/v2/gh/sidpalas/managed-kubernetes-pricing/master?filepath=%2Fmanaged-kubernetes-price-exploration.ipynb" >}}

If any of my calculations or pricing constants look incorrect, please let me know (via a Github Issue or Pull Request! -- [Github repository](https://github.com/sidpalas/managed-kubernetes-pricing/))

### Takeaways

There are too many variables to give much of a recommendation beyond my TL;DR up top, but here are some takeaways:

- AKS and Digital Ocean do not charge for the control plane resources while GKE and EKS do. If your architecture incorporates many small clusters (e.g. 1 cluster *per developer* or *per customer*) AKS and DO can have an cost advantage.
- Google's slightly cheaper compute resources result in lower costs as cluster sizes scale*.
- Taking advantage of preemptible and/or committed use discounts can reduce costs by >50% (*NOTE:* Digital Ocean does not offer these types of discounts).
- While Google's data egress fees are higher, the compute resources dominated the cost calculation (unless you are sending a significant amount of data out of the cluster).
- Choosing machine types that match your workloads' CPU and Memory needs will avoid paying for wasted capacity.
- Digital Ocean charges relatively less for vCPUs and more for memory which could be an important consideration depending on the nature of the compute workloads.

**NOTE:* I used general-purpose compute node types for all 4 clouds (n1 GCP Compute Engine instances, m5 AWS ec2 instances, D2v3 Azure virtual machines, and dedicated CPU DO droplets). Further exploration could be done across the burstable and entry-level VM types. Also, it appeared that pricing for VMs scaled linearly with # of vCPU and GB of memory, but I am not sure that assumption holds as you move towards some of the less standard memory/cpu ratios.

The article ["The Ultimate Kubernetes Cost Guide: AWS vs GCP vs Azure vs Digital Ocean"](https://www.replex.io/blog/the-ultimate-kubernetes-cost-guide-aws-vs-gce-vs-azure-vs-digital-ocean) published in 2018 used a single reference cluster with 100 vCPU cores and 400 GB of memory. As a point of comparison, here is how much my calculation shows that cluster would cost (using on-demand prices) on each of these platforms. 

- AKS: $51,465/year
- EKS: $43,138/year
- GKE: $30,870/year
- DO: $36,131/year

---

Hopefully, this article + notebook will help you in your journey to evaluate the major managed Kubernetes offerings and/or save $$$ on your cloud infrastructure by taking advantage of the available cost-saving opportunities.
