---
title: "Kubernetes the Hard Way Deep Dive -- 0 (Bootstrapping k8s Controllers)"
date: 2020-03-20T12:39:41-08:00
bookToc: false
tags: [
  "Kubernetes"
]
categories: [
  "Deep Dive",
  "Tutorial"
]
draft: true
---

**TL;DR:** Lorem Ipsum

**KTHW Lessons:**
- [09-bootstrapping-kubernetes-workers.md](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/09-bootstrapping-kubernetes-workers.md)

![tmux 4 pane](/static/images/tmux-4pane.png)
*Is this the Matrix?*

<!--more--> 

---
**Table of Contents:**
- [GCP + gcloud](#gcp--gcloud)
- [tmux](#tmux)
- [CFSSL & cfssljson](#cfssl--cfssljson)
- [kubectl](#kubectl)

## GCP + gcloud

I don't have anything to add for this step. The instructions are complete and will get your account/system set up to proceed.

A GCP project needs to be configured with the necessary APIs enabled, and gcloud will allow us to interact with GCP via the command line.

## tmux

Embarrassingly, I had never used tmux prior to this. 😳😳😳

tmux, short for "Terminal Multiplexer" is a program that allows for splitting up your terminal into multiple panes and tabs and manage the associated shell sessions. At first glance, this may sound like the `Split Pane` feature of the macOS terminal or the `Split Horizontally/Vertically` feature of [iterm2](https://iterm2.com/), but the difference is that shell sessions are managed independently from the terminal window. 

There are a variety of benefits this enables, but the feature Kelsey is suggesting for this tutorial is the ability to synchronize inputs across multiple terminal panes. This will allow us to `ssh` into multiple virtual machines, synchronize those sessions, and then execute a series of commands in parallel.

To do this we can use the following workflow:

1) Install tmux (`$ brew install tmux` if using Homebrew on macOS)
2) Start a new tmux session with `$ tmux`
3) Split the current pane twice using `Ctrl + b` -> `%`
4) Navigate between panes using `Ctrl + b` -> `←` OR `→`
5) SSH into the relevant virtual machines (`gcloud ssh ...`) in each of the panes
6) Once connected, synchronize the panes using `Ctrl + b` -> `:setw synchronize-panes` 
7) Execute the tutorial commands
8) After finishing, shut down all running tmux sessions using `$ tmux kill-server`

This is just one very specific workflow using tmux. For more information about getting started with some of the other tmux functionality (and lots of other useful tools/skills adjacent to programming), check out [The MIT Missing Semester Course](https://missing.csail.mit.edu/2020/command-line/#terminal-multiplexers).

## CFSSL & cfssljson

CFSSL (of which cfssljson is a sub-project) is an open source project from [Cloudflare](https://www.cloudflare.com/) that is "both a command line tool and an HTTP API server for signing, verifying, and bundling TLS certificates".

These will be used during [04-certificate-authority.md](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/04-certificate-authority.md) to provision a certificate authority,  and then use it to generate TLS certificates and private keys for many k8s system components.

I will go into more detail about what that actually means in the post corresponding to that step in the tutorial. For now, simply installing the software and verifying the versions are correct is sufficient.

## kubectl

`Kubectl` (It's okay... nobody else knoews [how to pronounce it](https://www.youtube.com/watch?v=2wgAIvXpJqU) either) is a command line tool for interacting with Kubernetes clusters. Once the cluster is up and running, `kubectl` will be the primary mechanism for getting information about the cluster (and things running within it), as well deploying and modifying software running within the cluster.

Kelsey's instructions for installation are sufficient, but if on MacOS, it can also be installed with Homebrew using:

    $ brew install kubectl

At this point your computer should have all the necessary prerequisite software and we can start setting up the cloud resources needed for the cluster.

See you in the next post!
