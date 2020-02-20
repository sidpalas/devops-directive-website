---
title: "The Making of This Site (Hugo, Caddy, + GCP)"
date: 2020-02-20T09:45:37-08:00
---
Alternate title: **Just use [Netlify](https://www.netlify.com/)**.

**TL;DR:** Deploy a Hugo site to GCP for free in less time than it will take you to read this article ([Github Repo](https://github.com/sidpalas/hugo-gcp-deploy) with all referenced commands)


![logos](/static/images/hugo-caddy-gcp.png)

<!--more--> 

--- 

Table of Contents:
- [Choosing a site generator:](#choosing-a-site-generator)
- [Initial Setup](#initial-setup)
- [Choosing a hosting solution:](#choosing-a-hosting-solution)
- [Local configuration (http-only for now)](#local-configuration-http-only-for-now)
- [Deploying to GCP](#deploying-to-gcp)
  - [1) Enable billing for the project](#1-enable-billing-for-the-project)
  - [2) Enable the Compute Engine and Container Registry APIs](#2-enable-the-compute-engine-and-container-registry-apis)
  - [3) Reserve a static IP address](#3-reserve-a-static-ip-address)
  - [4) Add firewall rules](#4-add-firewall-rules)
  - [5) Create the VM (finally!)](#5-create-the-vm-finally)
  - [6) Configure docker(s)](#6-configure-dockers)
  - [7) Deploy](#7-deploy)
  - [7) We're Live!](#7-were-live)
  - [8) Configuring DNS](#8-configuring-dns)
  - [9) Enabling HTTPs](#9-enabling-https)
- [Closing thoughts](#closing-thoughts)


---

### Choosing a site generator:

With GeoCities no longer an viable option for hosting websites in 2020 (apparently Yahoo Japan shut it down the final remnants in [March 2019](https://www.cnet.com/news/geocities-dies-in-march-2019-and-with-it-a-piece-of-internet-history/)) I needed a more modern solution to host this site.

[![geocities.jpg](/static/images/geocities.jpg)](https://flickr.com/photos/edkohler/2248645751/)
*RIP GeoCities*

After a brief look at the leading static site generators Jekyll, Hugo, Next.js, Gatsby, etc... I came to the conclusion that almost any of these would work just fine for my needs. I ended up choosing Hugo for a two main reasons:

**1) Language:** It's written in Go, a language I have wanted to learn. Having this site with Hugo may provide a nudge of motivation to make some contribution to the Hugo project. 

**2) Speed:** Site build times are near instant for this (tiny) site, but that would be true for any generator with so few pages. However, people have performed a number of [benchmarks](https://forestry.io/blog/hugo-vs-jekyll-benchmark/) showing Hugo's performance as a site grows.

### Initial Setup

The Hugo documentation is concise and they have an easy to follow quick start guide found here: https://gohugo.io/getting-started/quick-start/

I'm currently (as of February 2020) still using the suggested [Ananke](https://themes.gohugo.io/gohugo-theme-ananke/) theme with a few minor styling tweaks, but eventually will probably spend some more time customizing the theme.

### Choosing a hosting solution:  

With the site generator working, I then needed to decide how to host the site. In the past, I have used Github Pages to host static sites, but I noticed that they explicitly prohibit **"Get-rich-quick schemes"** (which learning & writing about DevOps and Cloud infrastructure clearly is) so that was out of the running.

I also looked at hosting within a [AWS](https://aws.amazon.com/s3/) / [GCP](https://cloud.google.com/storage) / [Azure](https://azure.microsoft.com/en-us/services/storage/blobs/) bucket. These are all super easy to set up and scale effortlessly, but if you want to use a domain with HTTPS enabled, you end up having to jump through some hoops configuring a Content Delivery Network.

I then came across [Caddy](https://caddyserver.com/), a webserver with automatic HTTPS configuring using [Let's Encrypt](https://letsencrypt.org/) which seemed ideal for this use case!

![caddy](/static/images/caddy.png)
*With a lock for a logo, it must be secure!*

**NOTE:** If you are following along and setting up your own site, for most people, the best option at this point would be to stop here and go to https://www.netlify.com/. They have a generous free tier plan and offer direct integration with github/gitlab/bitbucket to handle automatic build/deploys triggered by Git commits. I achieved a similar end result with GCP Compute Engine + Cloud Build (a topic for another post) that provides me a bit more control/extensibility, but Netlify covers most use cases with a fantastic user experience!

### Local configuration (http-only for now)

Since my computer is running MacOS, but ultimately the site would be deployed on a sever running some variant of linux, my default is to use containers to eliminate any configuration headaches with slight differences between the two environments.

This appears to be the defacto standard Caddy docker image https://hub.docker.com/r/abiosoft/caddy with over 10M pulls so I used that as the base. 

There are two options for accessing the files that Caddy needs to host within the container. (1) Copy them into the container image OR (2) mount a location the host filesystem into the container with `-v` or `--mount` [docker flags](https://docs.docker.com/storage/bind-mounts/) when running the container. 

Either option would be fine, but option 1 is nice for a small site because it ensures the entire site and its dependencies are included within the container image. As the site grows, I may switch to storing the site files outside of the container image.

Bundling the site files into the container can be accomplished with a 2 line dockerfile.

        FROM abiosoft/caddy:1.0.3
        COPY ./public /srv

Here `./public` is the local directory where Hugo builds the site, and `/srv` is the directory within the container Caddy expects to find the files it is serving. The following 4 commands will build the site, build the container, and run the container:

        export IMAGE_NAME=my-hugo-caddy-docker-image
        hugo -D    # -D flag tells Hugo to build drafts 
        docker build ./ --tag $IMAGE_NAME
      	docker run -p 2015:2015 $IMAGE_NAME     

The `-p` forwards the port from host system into container allowing us to connect to http://localhost:2015/ and that request will be forwarded into the container on port 2015 where Caddy is listening. 

### Deploying to GCP

With the container image working, I was then ready to deploy it somewhere. There are a variety of options to do this, but I chose to use a GCP Compute Engine `f1-micro` virtual machine instance running Google's [Container-Optimized OS](https://cloud.google.com/container-optimized-os/docs). Container-Optimized OS provides nice [security features](https://cloud.google.com/container-optimized-os/docs) configured by default making it a good OS options for containerized applications. While the `f1-micro` instance is small (0.2 vCPUs + 600MB Memory), running one is included in the GCP's [always free usage limits](https://cloud.google.com/free/docs/gcp-free-tier#always-free-usage-limits) making this deployment cost me a *grand total of $0!*

Since this site is about DevOps, I clearly needed to automate the entire set up process, which I did here: https://github.com/sidpalas/hugo-gcp-deploy.

I also decided to create a new GCP project for this site. Doing this makes it easy to clean things up should I decide to take the site down by simply deleting the entire project without having to worry about accidentally leaving some resources running.

If you are more comfortable working with the GCP web interface, that is perfectly fine, but the following process should do the trick

**NOTE:** for any of the following commands `$PROJECT_ID` would need to be replaced with your GCP project id. I also like to explicitly pass the project ID into the commands to ensure they are executed in the correct location (Just in case I happened to have changed my default project configuration)

#### 1) Enable billing for the project
Even though the resources used here are included in the free tier, Google requires having a payment method on file. This is the one step I recommend doing via the console as the command line command is [still in alpha](https://cloud.google.com/sdk/gcloud/reference/alpha/billing):

https://console.cloud.google.com/billing/linkedaccount?project=$PROJECT_ID 

#### 2) Enable the Compute Engine and Container Registry APIs

This is necessary to provision the VM and to be able to push container images.

        gcloud services enable compute.googleapis.com --project=$PROJECT_ID
	    gcloud services enable containerregistry.googleapis.com --project=$PROJECT_ID

#### 3) Reserve a static IP address

If the VM needs to restart (or if I wanted to move to a larger machine type), a static IP ensures it won't change unexpectedly and mess up DNS configuration.

	gcloud compute addresses create my-site-external-ip \
		--project=$PROJECT_ID \
		--region=us-central1

#### 4) Add firewall rules

By default Compute Engine VMs do not allow http or https traffic. Adding firewall rules allow those requests to make it to the webserver.

    gcloud compute firewall-rules create default-allow-http \
		--project=$PROJECT_ID \
		--target-tags=http-server \
        --allow tcp:80
	gcloud compute firewall-rules create default-allow-https \
		--project=$PROJECT_ID \
		--target-tags=https-server \
        --allow tcp:443

The target-tags allow the VM configuration to utilize these rules.

#### 5) Create the VM (finally!)

When creating the VM, the static IP and firewall rule tags are used to configure it:

        gcloud compute instances create my-f1-micro-instance \
            --project=$PROJECT_ID \
            --zone=us-central1-a \
            --machine-type=f1-micro \
            --image=projects/cos-cloud/global/images/cos-69-10895-385-0 \
            --address=my-site-external-ip \
            --tags=http-server,https-server

This takes a few minutes to provision.

#### 6) Configure docker(s)

In order to configure my local Docker install to push images to google container registry I had to run:

        gcloud auth configure-docker    

In order for the Docker installed in container optimized OS running on the VM I had to run the following:

        gcloud compute ssh my-f1-micro-instance \
            --project=$PROJECT_ID \
            --zone=us-central1-a -- \
            docker-credential-gcr configure-docker

#### 7) Deploy

To deploy the site, I needed to get the container image into the google container registry by building, tagging, and then pushing it:

        export IMAGE_NAME=my-hugo-caddy-docker-image
        export IMAGE_TAG=incrementing-tag-001 # change this with each deploy to ensure latest image is used
        docker build ./ --tag $IMAGE_NAME
    	docker tag $IMAGE_NAME gcr.io/$PROJECT_ID/$IMAGE_NAME:$IMAGE_TAG
	    docker push gcr.io/$PROJECT_ID/$IMAGE_NAME:$IMAGE_TAG

If the site is already running, it needs to be cleaned up before the new container can be deployed or else it would fail when trying to bind to the same host ports. This can be accomplished using:

        gcloud compute ssh my-f1-micro-instance \
            --project=$PROJECT_ID \
            --zone=us-central1-a -- \
            'docker container stop $(docker container ls -aq) && docker container rm $(docker container ls -aq)'

Having to do this step is one downside to bundling the entire site into the container image, the site has to be down for a second or two while the new version starts up. If the site was mounted into the container, the server could keep running and the files could be copied onto the host filesystem with no downtime.

Finally, we can issue a `docker run` to run the new container image:

        gcloud compute ssh my-f1-micro-instance \
                --project=$PROJECT_ID \
                --zone=us-central1-a -- \
                'docker run -d --restart=unless-stopped -p 80:80 -p 443:443 -v $HOME/.caddy:/root/.caddy gcr.io/$PROJECT_ID/$IMAGE_NAME:$IMAGE_TAG'

**NOTE:** the `-v $HOME/.caddy:/root/.caddy` mount isn't necessary here, but later once we actually request the TLS certificate, it will avoid making unnecessary requests to Let's Encrypt which could lead to being rate limited.

#### 7) We're Live!

At this point I was able to visit the external IP address from step 3 and see the website:

![speed run](/static/images/website-speedrun.png)
*It seems complex, but it takes <5 min... Seriously, I timed it!*

#### 8) Configuring DNS

The final element of the setup is to point a domain to the IP address which I accomplihed with the following settings:

        Name      Type   TTL     Data
        @         A      1h      104.154.89.62
        www       CNAME  1h      devopsdirective.com.

(The CNAME record maps the www subdomain to the primary domain without www)

#### 9) Enabling HTTPs

The final element of the setup is to enable https within Caddy. This can be accomplished by creating a `Caddyfile`:

        my-awesome-domain.com www.my-awesome-domain.com
        tls my-email-address@domain.com
        browse
        log stdout
        errors stdout

and make some small tweaks to the Dockerfile:

        FROM abiosoft/caddy:1.0.3
        COPY ./public /srv

        ENV ACME_AGREE=true # This gets used during the container start up to accept the Let's Encrypt subscriber agreement (without requiring user input)
        COPY ./CADDYFILE /etc/Caddyfile 

After redeploying and waiting for the DNS settings to propagate I was able to access my site and bask in the glory of the https connection symbol!

![https symbol](/static/images/https-success.png)

### Closing thoughts

Overall I'm happy with this configuration and am amazed that all of this can be accomplished for free using mostly open source software! It was also useful to continue gaining experience with the tools and platforms. 

My hope is now that everything is set up and configured, the amount of maintenance effort required should be low. Time will tell...

In a future post I will cover how I used Google Cloud Build to automate the deployment process. I also plan do some benchmarking to see just what kind of load this tiny server can handle!



