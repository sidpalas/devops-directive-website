---
title: "Kubernetes the Hard Way Deep Dive -- Intro"
date: 2020-03-03T12:39:41-08:00
bookToc: false
tags: [
  "Kubernetes"
]
categories: [
  "Deep Dive"
]
draft: true
---

**TL;DR:** This is the introduction to a series of posts in which I will work through Kelsey Hightower's [Kubernetes The Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way), explaining key concepts in detail along the way.

*INSERT IMAGE*

<!--more--> 

---

- [My Kubernetes Onboarding](#my-kubernetes-onboarding)
- [The Plan](#the-plan)
- [Housekeeping](#housekeeping)

### My Kubernetes Onboarding 

My first experience with Kubernetes (k8s) was working with an existing cluster deployed using [Google Kubernetes Engine (GKE)](https://cloud.google.com/kubernetes-engine). The `yaml` files all looked like gibberish, but I pattern-matched my way to getting a new service up and running. 

Later, I needed to set up a new cluster to support a variety of data analysis workloads and going through the process of setting up and configuring the cluster helped solidify my understanding of the k8s concepts. That being said, I would still come across situations (such as a pod reaching the dreaded [`Unknown`](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-phase) phase) that left me yearning for a deeper understanding of what was going on under the hood.

### The Plan

To help illuminate the inner workings of k8s, I am going to take off the GKE training wheels and work my way through the process of setting up a Kubernetes cluster from scratch. [Kelsey Hightower](https://twitter.com/kelseyhightower)* published a fantastic guide to do exactly this, but it assumes a certain level of understanding of many of the foundational tools/technologies.

My plan is to follow along Kelsey's guide, and document the process as I try to dig one layer deeper to grok exactly what each step is doing and why it is necessary for setting up k8s.

This series will be most useful for individuals who have worked with k8s primarily in a managed configuration.

### Housekeeping

To organize the series I will use the following naming convention:

`"Kubernetes the Hard Way Deep Dive -- <KTHW_POST_#>.<DD_POST_#>"`

Where:
- `KTHW_POST_#` is the post number within the Kubernetes The Hard Way repository.
- `DD_POST_#` is the number of the DevOps Directive post corresponding to that post.

**For Example:**

`"Kubernetes the Hard Way Deep Dive -- 07.2"`

Would correspond to the second DevOps Directive post referencing the [07-bootstrapping-etcd.md](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/07-bootstrapping-etcd.md) step of the guide.

**Lets dive in!**
 
--- 

\* If you don't know who Kelsey Hightower is, do yourself a favor and go watch a few of his presentations [on YouTube](https://www.youtube.com/results?search_query=kelsey+hightower). You won't regret it!