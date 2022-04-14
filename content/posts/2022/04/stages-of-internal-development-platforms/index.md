---
title: "The Six Stages of Internal Development Platforms"
date: 2022-04-13T15:33:53-07:00
draft: false
bookToc: false
tags: [
  "Cloud",
  "DevOps",
  "Kubernetes"
]
categories: [
  "Trends",
]
---

> ### You either die supporting raw Kubernetes manifests, or live long enough to see yourself build an internal developer platform. ~Anonymous

![internal-development-platform](/static/images/internal-development-platform.jpeg)

<!--more-->

---

#### Table of Contents:
- [What the Heck is an Internal Development Platform?](#what-the-heck-is-an-internal-development-platform)
- [Why am I hearing about this now?](#why-am-i-hearing-about-this-now)
- [Designing the Right IDP](#designing-the-right-idp)
- [Evolution of an IDP](#evolution-of-an-idp)
  - [Stage 0: External Platform as a Service](#stage-0-external-platform-as-a-service)
  - [Stage 1: Vanilla Kubernetes](#stage-1-vanilla-kubernetes)
  - [Stage 2: Templating Tools](#stage-2-templating-tools)
  - [Stage 3: Initial Internal Developer Platform](#stage-3-initial-internal-developer-platform)
  - [Stage 4: Extending Existing Platform Building Blocks](#stage-4-extending-existing-platform-building-blocks)
  - [Stage 5 (Optional): Inventing New Platform Building Blocks](#stage-5-optional-inventing-new-platform-building-blocks)
  - [Stage 6: Full Internal Platform as a Service](#stage-6-full-internal-platform-as-a-service)
- [Go Forth and Conquer!](#go-forth-and-conquer)

## What the Heck is an Internal Development Platform?

An Internal Development Platform (IDP) is the system that your organization uses to facilitate developing, deploying, and operating applications. The IDP defines how application developers create, modify, and test their applications, ideally in a self-service manner.

Instead of just handing application teams an AWS root account and saying **"have fun"**, IDPs seek to provide abstractions that enable those teams focus on building products, without needing to become DevOps/cloud experts!

As outlined by {{< link "https://internaldeveloperplatform.org/core-components/" "internaldeveloperplatform.org" >}}, the 5 core components of an Internal development platform are:

1. **Application Configuration Management:** Manage application configuration in a scalable and reliable way
2. **Infrastructure Orchestration:** Integrate with your existing and future infrastructure
3. **Environment Management:** Enable developers to create new environments whenever needed
4. **Deployment Management:** Implement a Continuous Delivery or even Continuous Deployment (CD) approach
5. **Role-Based Access Control:** Manage who can do what in a scalable way

Everywhere I turn these days I see another article/talk about companies building internal development platforms on top of Kubernetes:
  - **2022-03:** {{< link "https://slack.engineering/applying-product-thinking-to-slacks-internal-compute-platform/" "Applying Product Thinking to Slack’s Internal Compute Platform" >}}
  - **2022-02:** {{< link "https://www.youtube.com/watch?v=j5i00z3QXyU" "DevOps MUST Build Internal Developer Platform (IDP)" >}}
  - **2022-01:** {{< link "https://www.youtube.com/watch?v=euDC19oknw4" "Your Internal Developer Platform s**ks!" >}} 
  - **2020-05:** {{< link "https://www.youtube.com/watch?v=z3nFTi5-b3A" "More Power, Less Pain: Building an Internal Platform with CNCF Tools" >}}

This concept is not actually new! {{< link "https://twitter.com/kelseyhightower" "Kelsey Hightower" >}}, {{< link "https://twitter.com/jbeda" "Joe Beda" >}} (and others) have been telling us that Kubernetes is a platform for building platforms since 2017!

{{< img "images/kelsey-tweet.png" "It's pretty dope... but it's not still not the endgame">}}

{{< img-link "images/beda-video.png" "https://youtu.be/QQsq2Ny5a4A?t=1151" "\"How can we turn Kubernetes into a platform for building platforms?\"" >}}

## Why am I hearing about this now?

At this point you might ask, what is fueling this renaissance of companies building (and publicly talking about) Internal Developer Platforms? In my opinion it is driven by the rapid maturation of the cloud native tools that represent the building blocks for these types of platforms. This makes it feasible for smaller teams to build and support platforms that actually work and add business value.

That being said, the {{< link "https://landscape.cncf.io/" "Cambrian explosion" >}} of cloud native tools is both a blessing and a curse. While it is more likely than ever that a tool exists which [somewhat] addresses your particular need, choosing between them and ensuring interoperability is becoming increasingly difficult! (more on this in a future post... {{< link "https://roamresearch.com/#/app/devopsdirective/page/xi2CaPv5i" "but you can find some raw thoughts here" >}}) 

## Designing the Right IDP

The size and complexity of the appropriate platform to suit your organization depends on a three main of factors:
  1. The number and nature of the applications it needs to support
  2. The size and skill set of the application development team(s)
  3. The size and skill set of the platform development team 

Building an internal development process is generally an iterative process and ideally you will have some early adopter application developers willing to use it as soon as possible and provide feedback to ensure it is meeting their needs effectively.

Below is a rough spectrum (scale intentionally vague) of the different stages an internal developer platform often exhibits within an organization. This is based on my experience working with teams as they build out these types of application platforms and from discussions with others doing the same.

{{< img "images/idp-spectrum.png" >}}

## Evolution of an IDP

### Stage 0: External Platform as a Service

For very small teams, you likely should avoid building your own platform entirely, and use a 3rd party Platform as a Service (PaaS) while focusing on product iteration and achieving product market fit. There are many options to choose from here including:
  - [Heroku](https://www.heroku.com/)
  - [Cloud Foundry](https://www.cloudfoundry.org/)
  - [Render](https://render.com/)
  - [App Engine](https://cloud.google.com/appengine)

Eventually though, it is likely that either:
  1. Your workloads no longer fit the constraints imposed by the PaaS 📦
  2. The PaaS pricing begins to hurt your wallet a bit too much 💸

at which point you may consider migrating off the PaaS, and in the past few years Kubernetes has become the [de facto leader](https://www.cockroachlabs.com/guides/kubernetes-trends/) for doing so!

### Stage 1: Vanilla Kubernetes

When you first move to Kubernetes and are still figuring out how migrate things, you probably won't have built out additional abstractions. You will use the raw Kubernetes resource types directly and interact with the cluster via `kubectl`. This stage generally won't last long before moving on to the next stage.

### Stage 2: Templating Tools

Very early on you will come across scenarios where you want to have variants of applications running in different environments. There are a variety of ways to accomplish this, ranging from custom bash scripts using `envsubst` to more robust tools such as `helm`. Your application developers will still need some familiarity with Kubernetes to be successful at this stage.

### Stage 3: Initial Internal Developer Platform

Eventually as the team and applications grow, creating bespoke definitions for each workload becomes unwieldy. To wrangle this complexity you will likely begin stitching together some collection of tools from the [CNCF ecosystem](https://landscape.cncf.io/) to help. 

Much of the work at this stage is selecting the tools that best suit your team's needs and configuring them to play nicely together. This is also the stage where you start to bake more control/opinions into the platform itself and you shape the application developer experience (for better for for worse).

### Stage 4: Extending Existing Platform Building Blocks

As you iterate on your platform, you will almost certainly start to push the boundaries of what existing tools can support or encounter use cases that aren't quite supported. In this case you may start to extend those tools (either via a wrapper or a fork) to meet your own needs.

### Stage 5 (Optional): Inventing New Platform Building Blocks

At a certain scale/complexity there might not be an existing tool/project and your custom scripts and glue code are no longer enough. At that point you might choose to building a new tool to fill the gap.

### Stage 6: Full Internal Platform as a Service

At this point you have come full circle! While the platform will never be __complete__, a mature internal developer platform starts to look and feel a lot like the 3rd party PaaS you started with, except it has all the specific features your organization needs.

## Go Forth and Conquer!

Building an Internal Developer Platform is a significant undertaking, but if done properly can be a force multiplier for application developers and reduce the operational toil of building and operating applications on Kubernetes. 

The sooner you start to think about what your ideal IDP might eventually look like, the easier it will be to make decisions that will help you set a course to reach that desired state.

Good luck! 🍀
