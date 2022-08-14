---
title: "Cloud Control Spectrum: How Should I Deploy My Web Application?"
date: 2022-04-10T10:49:47-04:00
bookToc: false
tags: [
  "Cloud"
]
categories: [
  "Comparison",
]
---

There are seemingly infinite ways to deploy web applications to the cloud:
- [🏢 On-Premise](#-on-premise)
- [🤝 Colocation](#-colocation)
- [🤘 Bare Metal Cloud](#-bare-metal-cloud)
- [📜 Dedicated Hosts/instances](#-dedicated-hostsinstances)
- [🤖 Virtual Machines](#-virtual-machines)
- [⚙️ Managed Services](#️-managed-services)
- [✨ Platform as a Service](#-platform-as-a-service)

Which option is right for you? Read on to find out!

<!--more--> 

---

## 🏢 On-Premise

If you want full control over everything, you can buy servers (computers), hook them up to power, set up networking, install any dependencies, and then deploy your software onto those systems.

Operating an on-premise deployment with high security and reliability comes with significant overhead and is generally only appropriate for large enterprises.

You are responsible for everything from physical security to climate control.

## 🤝 Colocation

If you want full control, but don't want to own and operate your own data center, colocation offloads that responsibility to a service provider. You still buy the servers but set them up in a building owned/operated by another company.

They will charge you rent for the space as well as a fee to cover utilities and other costs to operate the building.

This option can make sense if you have stable compute needs and are able to fully utilize the capacity you buy but don't want to deal with all of the operations.

## 🤘 Bare Metal Cloud
If you don't want to take on the capital expense of the servers, there are cloud providers that allow you to rent servers directly.

"Bare metal" refers to the fact that you interact with the server directly (instead of through a virtualization layer).
With bare metal servers, you are responsible for installing the OS, any dependencies, and your software.

If you mess something up, you may need to wipe the system and reinstall the OS from scratch (which can take a while). Bare metal servers have some performance benefits over virtual machines but are less dynamic.

This can be a good option if you have performance-critical workloads but your compute needs are variable and you don't want to buy your own servers!

## 📜 Dedicated Hosts/instances
Adding a virtualization layer, but renting a specific server(s) from a cloud provider makes it easier to create/destroy/configure servers while retaining hardware-level isolation from other customers (e.g. nobody else is running on the same servers).

You choose or create an "image" with an operating system (and potentially some dependencies) installed and the cloud provider creates a virtual server for you.
You then install additional dependencies and your software OR you might pre-build them into the image.

Dedicated hosts tend to cost more than standard virtual machines (next in this thread) but make sense in two cases:

  1. Some software licenses charge you based on specific hardware usage so you need them
  2. Some industries require data isolation guarantees

## 🤖 Virtual Machines
Similar to dedicated hosts, you choose or create an "image" with an OS (and potentially some dependencies) installed and the cloud provider creates a virtual server for you.

The main difference here is that standard VMs are cheaper and have no guarantees about which physical server your deployment goes on.

This is a great option to keep full control over the configuration but retain the flexibility to create and destroy servers quickly and easily!

## ⚙️ Managed Services

Many cloud providers offer specific products that further take over some of the management responsibility for portions of your application.

For example, AWS offers Relational Database Service (RDS) which provides a managed SQL database.

This allows you to avoid setting up and configuring your own database (with high availability, backups, etc).

You can leverage expertise from the provider, but you don't control the system so if something goes awry it can be an issue. It also costs more than operating yourself

## ✨ Platform as a Service
If you want to offload all of your deployment/operations, you can use a PaaS offering in which you generally hook up a code repo and let them handle the rest.
PaaS offerings can be a great choice for small teams who are focused on product iteration.

When using a PaaS, you are forced to adhere to the guidelines/requirements provided by the provider.

You give up control and pay a bit extra for the simplicity and streamlined developer experience!

---

Hopefully, this helps you understand the options and make a choice about what the right option is for you! 🎉
