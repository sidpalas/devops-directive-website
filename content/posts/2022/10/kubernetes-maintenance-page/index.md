---
title: "Kubernetes Maintenance Page"
date: 2022-10-30T20:48:21Z
bookToc: false
tags: [
  Kubernetes
  Docker    
]
categories: [
  Tutorial
]
draft: true
---

**TL;DR: Need to set up a quick maintenance page for a service hosted in Kubernetes? You can create a custom page and host it with nginx without even needing a custom container image!** 

{{< img-large "images/maintenance-page-screenshot.png" >}}

<!--more--> 

#### Table of Contents:


### Why?

While it is usually best to attempt to avoid downtime for your production services, but sometimes downtime is unavoidable (or at least not worth the effort to avoid). I had a project that called for a maintenance period, and this is the solution I came up with. The two key attributes I wanted to achieve were:

- Easy + fast to toggle on/off (I wanted to avoid needing and DNS updates because caching can cause them to be slow and unpredictable)
- No additional container required (Every time you build a custom container image, it is one more thing to maintain, host in a registry, etc...)

### How?

To achieve these goals I used the default [nginx image](https://hub.docker.com/_/nginx) and took advantage of the fact that `ConfigMaps` can be mounted as volumes to inject my HTML, CSS, and nginx.conf into the pod at runtime!