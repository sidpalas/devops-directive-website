---
title: "Static Site Hosting Using Google Cloud Storage and Cloudflare (with SSL!)"
date: 2020-10-05T10:15:15-04:00
bookToc: false
tags: [
  "Google Cloud Platform",
  "Google Cloud Storage",
  "Cloudflare",
]
categories: [
  "Tutorial"
]
---

**TL;DR:** I used to host my site on a [virtual machine running Caddy webserver]({{< ref "/posts/2020/02/hugo-and-caddy-on-gcp/index.md" >}}), but recently migrated it to Google Cloud Storage with Cloudflare in front of it as a proxy/cache/SSL termination solution. It's pretty awesome! 😎

I also recorded a video about this setup on **[YouTube](https://www.youtube.com/watch?v=sUr4GBzEqNs)**. ← Check out the video and subscribe if you are into this sort of thing 🙏

{{< img "images/gcs-site.png" "Does this count as serverless?" >}}

<!--more--> 

---

Table of Contents:
- [Overview](#overview)
  - [Cloud Storage](#cloud-storage)
  - [Cloudflare](#cloudflare)
- [Setup](#setup)
  - [1) Purchase a Domain](#1-purchase-a-domain)
  - [2) Verify Ownership](#2-verify-ownership)
  - [3) Create a GCS bucket](#3-create-a-gcs-bucket)
  - [4) Configure Cloudflare](#4-configure-cloudflare)
    - [DNS Nameservers](#dns-nameservers)
    - [CNAME Record](#cname-record)
    - [SSL Setting](#ssl-setting)
    - [Page Rules](#page-rules)
  - [5) Deploy Site](#5-deploy-site)
- [Conclusions](#conclusions)

# Overview

If you want to host a static website in 2020, the number of options can be a bit overwhelming. GitHub pages, Netlify, Vercel, oh my! This post describes my current favorite solution for hosting a static website. Here are the attributes of the setup described here:

- **Simple:** No servers to maintain
- **Scalable:** Can handle practically any load you throw at it
- **Affordable:** Hosting this site costs me a few pennies per month
- **SSL:** The site is served over HTTPS

## Cloud Storage

Cloud object storage (S3, GCS, Azure Storage) is a pretty amazing technology. For a few pennies/GB/month you can store files and the cloud provider will serve them with high reliability to pretty much any level of traffic you can throw at it. Also, for nearly 10 years, AWS S3 has provided features to make [hosting a website directly from a storage bucket simple](https://aws.amazon.com/blogs/aws/host-your-static-website-on-amazon-s3/). 

That being said, those solutions don't support HTTPS by default. Google Cloud Platform does offer a guide for setting up a [site with GCS with an HTTPS load balancer in front of it](https://cloud.google.com/storage/docs/hosting-static-website), but the load balancer [costs $18/month](https://cloud.google.com/vpc/network-pricing#lb) at which point this solution becomes significantly less attractive relative to its competition.

## Cloudflare

Cloudflare is a web-infrastructure company that provides a variety of network-related services, including DNS and content delivery caching. They also have a variety of SSL/TLS encryption options ranging from "Off" to "Full (strict)". The "Flexible" setting is the one we want here. 

With this setting, SSL termination is done on the Cloudflare server, so the users' traffic is encrypted from their browser to Cloudflare and then requests between Cloudflare and the origin server (in our case the GCS server) will be un-encrypted.

If you were hosting a site with sensitive information, this would not be the right option, but for a public website (such as this one), this option gives us [most of the benefits of HTTPS](https://doesmysiteneedhttps.com/) without having to set up an SSL certificate on our server!

{{< img "images/flexible-ssl.png" "Cloudflare flexible SSL" >}}

Cloudflare has the added benefit of automatically caching your content, speeding up delivery and reducing the data egress from GCS.

# Setup

## 1) Purchase a Domain 

The first step is to purchase a domain. Any domain provider will do, but purchasing with [Google Domains](https://domains.google/) makes the next step easier or unnecessary. 

## 2) Verify Ownership

Before creating a GCS bucket associated with a particular domain, Google requires you to verify ownership of the domain.

There are a few methods to verify your ownership of the domain. If purchased through Google Domains, this can be done through the [Webmaster Central [page](https://www.google.com/webmasters/verification/home), otherwise, you can use a [DNS text record](https://cloud.google.com/identity/docs/verify-domain-txt). 

## 3) Create a GCS bucket

After verifying ownership, creating and configuring the bucket can be done using the [gsutil tool](https://cloud.google.com/storage/docs/gsutil).

```bash
	gsutil mb -p $PROJECT_ID -b on gs://$DOMAIN
	gsutil web set -m index.html -e 404.html gs://$DOMAIN
	gsutil iam ch allUsers:legacyObjectReader gs://$DOMAIN
```

The `mb` command creates the bucket, the `web set` command configures the main and error pages, and the `iam ch` command sets the permissions to enable public file access.

## 4) Configure Cloudflare

### DNS Nameservers

When you add the domain to Cloudflare, it will prompt you to configure your domain provider to use a pair of Cloudflare nameservers. In my case this was:

```
elma.ns.cloudflare.com
james.ns.cloudflare.com
```

These will be use in place of the default nameservers provided by the domain provider.

### CNAME Record

Because the website content will be served from a Google-managed server at `c.storage.googleapis.com` a CNAME record set that maps the custom domain to that:

```
Type   |  Name                 |  Content
------------------------------------------------------
CNAME  |  devopsdirective.com  |  c.storage.googleapis.com  
``` 

### SSL Setting

As described above, the site will use the "Flexible" SSL/TLS encryption mode, which can be set under the SSL/TLS tab on Cloudflare.

### Page Rules

This step is optional, but without it, the `www` subdomain (e.g. `www.devopsdirective.com` won't work properly).

I prefer to use the root domain, but if a user adds a `www.` prefix I don't want them to encounter an error. This can be handled by creating the following forwarding rule.

{{< img "images/page-rule.png" "www page redirect" >}}

The asterisk (`*`) will capture anything after the slash and gets substituted into the redirect URL at the `$1`. For example:

```
https://www.devopsdirective.com/about/ -> https://devopsdirective.com/about/
```

This page rule will only work properly if there is a DNS record for the www subdomain. This is accomplished by creating a dummy A record pointing to 192.0.2.1 (all addresses in the `192.0.2.0/24` are assigned to `TEST-NET-1` for documentation and example code and don't actually correspond to a real server)

```
Type   |  Name                 |  Content
------------------------------------------------------
A      |  www                  |  192.0.2.1
``` 

## 5) Deploy Site

With everything configured, the only thing remaining is to upload the website files into the bucket. The easiest way to do this is using the `gsutil rsync` command:

```bash
gsutil -m rsync -d -r $LOCAL_SITE_DIR gs://$DOMAIN
```

- The `-m` flag enables multi-threading which can help speed up the execution dramatically for large sets of files
- The `-d` flag will delete files from the bucket not found in the `$LOCAL_SITE_DIR`. NOTE: If there is a chance the local dir could be empty, this would cause all the bucket contents to be deleted (so use at your own risk!).

# Conclusions

I have been using this approach for a few months now and so far it has been rock solid. I love the simplicity of the setup, especially redeploying via a single `rsync` command.

Let me know how you end up hosting your next static site and why!
