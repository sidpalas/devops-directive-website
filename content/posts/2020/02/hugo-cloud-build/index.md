---
title: "CI/CD for this site (Hugo + Cloud Build)"
date: 2020-02-21T11:09:35-08:00
bookToC: false
tags: [
  "Hugo",
  "Cloud Build",
  "GCP",
  "Containers",
  "CI",
  "CD"
]
categories: [
  "Tutorial"
]
---

**TL;DR:** Configuring Cloud Build to automatically handle Continuous Integration and Continuous Deployment for this site based on Git triggers ended up being a bit trickier than I would have expected.

{{< img "images/hugo-cloud-build.png" >}}

<!--more--> 

--- 

Table of Contents:
- [Picking a CI/CD Tool](#picking-a-cicd-tool)
- [Attempting to Use the Cloud Build GitHub App](#attempting-to-use-the-cloud-build-github-app)
- [GCP Set Up](#gcp-set-up)
  - [Video Walkthrough](#video-walkthrough)
  - [1) Mirroring GitHub Repo to Cloud Source](#1-mirroring-github-repo-to-cloud-source)
  - [2) Enable the Cloud Build API](#2-enable-the-cloud-build-api)
  - [3) Add IAM Roles for Cloud Build Service Account](#3-add-iam-roles-for-cloud-build-service-account)
  - [4) Creating Cloud Build Trigger](#4-creating-cloud-build-trigger)
- [Creating the Cloud Build Pipeline (cloudbuild.yaml)](#creating-the-cloud-build-pipeline-cloudbuildyaml)
  - [1) Initialize and Update the Submodules](#1-initialize-and-update-the-submodules)
  - [2) Build the Hugo Site](#2-build-the-hugo-site)
  - [3) Build + Push the Caddy Container Image](#3-build--push-the-caddy-container-image)
  - [4) Stop Running Containers \& Start New Container](#4-stop-running-containers--start-new-container)
  - [NOTE: Pushing Images](#note-pushing-images)
- [Closing Thoughts](#closing-thoughts)

---

This is a continuation of the previous post ([The Making of This Site (Hugo, Caddy, + GCP)]({{< ref "/posts/2020/02/hugo-and-caddy-on-gcp/index.md" >}})) in which I walked through the set up of this site. In this post, I add automated builds/deploys to the site.

All of the commands for creating the site, as well as setting up this automation can be found in this [GitHub Repo](https://github.com/sidpalas/hugo-gcp-deploy).

### Picking a CI/CD Tool

Initially, I was going to use [Circle CI](https://circleci.com/) to automate the process of building and deploying the site. Circle CI has direct integration with Github and posted to their blog in 2018 explaining how to [Automate Your Static Site Deployment with CircleCI](https://circleci.com/blog/automate-your-static-site-deployment-with-circleci/) using Hugo as the example site generator. 

That being said since everything in the site setup was GCP based, I decided to try out [Cloud Build](https://cloud.google.com/cloud-build). Cloud Build also has a [GitHub app](https://github.com/marketplace/google-cloud-build) and being within the same GCP project meant I wouldn't have to deal with shuffling additional service account credentials between platforms.

Also, just like with the server setup, Cloud Build is also included in the GCP free tier (up to 120 build minutes/day) so this shouldn't cost me anything. 

### Attempting to Use the Cloud Build GitHub App

Thinking this would be a 30-minute task, I eagerly installed the Cloud Build Github app and added a build trigger based on pushes to the master branch. When the build succeeded I was not greeted with the website, but instead with the Default Caddy home page. After manually navigating to the `/articles` endpoint I saw the following:

{{< img "images/*missing-hugo-theme*" >}}


The content files were there, but I realized that It wasn't being rendered properly because the build failed to get the theme files. After doing more research I concluded that it has to do with the fact that the theme is not stored within the website Git repo, but is a Git submodule. 

In an attempt to solve this, I added a step to the build pipeline to grab the submodule files using:

```bash
git submodule init
git submodule update
```

but Cloud Builds triggered from GitHub don't have access to the `.git` directory within the repo and these commands will fail. The best workaround I could find was to mirror the GitHub repo into a Cloud Source Repository. This is already getting more complicated than I had hoped, but the show must go on!

### GCP Set Up

At this point, I had arrived what I thought was a viable plan that I just needed to execute.

**NOTE:** The commands that follow use $PROJECT_ID and other template variables that should reflect the relevant project and values.

```bash
export PROJECT_ID=my-awesome-project-1234
```

#### Video Walkthrough

To accompany this article, I also created a full video walkthrough of setting up the pipeline. Feel free to follow along or skip it depending on if you prefer the video or written format!

{{< youtube MF2gMZ5aDBQ >}}

#### 1) Mirroring GitHub Repo to Cloud Source

As noted above, I needed to mirror the GitHub repo for my website into a Cloud Source repo. I couldn't find a good way to script this, so I just followed the guidance in this Google post: [Mirroring a GitHub repository](https://cloud.google.com/source-repositories/docs/mirroring-a-github-repository)

#### 2) Enable the Cloud Build API

To use Cloud Build I had to enable the cloud build API using:

```bash
gcloud services enable cloudbuild.googleapis.com --project=$PROJECT_ID
```

#### 3) Add IAM Roles for Cloud Build Service Account

When the Cloud Build API is enabled, a service account of the format `projectNumber@cloudbuild.gserviceaccount.com` is granted some IAM roles, but for this build pipeline the service account also needs the following two roles:

```bash
Compute Instance Admin (v1)
Service Account User
```

which I accomplished with the following commands:

```bash
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member serviceAccount:$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")@cloudbuild.gserviceaccount.com \
  --role roles/compute.instanceAdmin.v1
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member serviceAccount:$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")@cloudbuild.gserviceaccount.com \
  --role roles/iam.serviceAccountUser
```

#### 4) Creating Cloud Build Trigger

With all of the prerequisite configurations in place, it was then time to create the Cloud Build trigger:

```bash
export IMAGE_NAME=my-hugo-caddy-docker-image
export INSTANCE_NAME=my-f1-micro-instance
export ZONE=us-central1-a
gcloud beta builds triggers create cloud-source-repositories \
  --project=$PROJECT_ID \
  --repo=my-cloud-source-repo-mirroring-a-github-repo \
  --branch-pattern=master \
  --build-config=cloudbuild.yaml \
  --substitutions=_IMAGE_NAME=$IMAGE_NAME,_SSH_STRING=$USER@$INSTANCE_NAME,_ZONE=$ZONE,_HOME=/home/$USER
```

The `--substitutions` represent template variables that get used in the pipeline definition as will become apparent below.

### Creating the Cloud Build Pipeline (cloudbuild.yaml)

At this point, Cloud Build was primed and ready to go... but I hadn't told it what to do yet. The actual build pipeline is defined within a `cloudbuild.yaml` file at the root of the repository.

[Build Configuration Documentation](https://cloud.google.com/cloud-build/docs/build-config)

Each step in this pipeline takes in a container image as its "name" and can also take optional arguments which are executed inside that container.

Below I have broken down this pipeline into its 6 steps:

#### 1) Initialize and Update the Submodules

As mentioned above, one of the initial challenges using Cloud Build was it failing to get the files associated with the Hugo theme because they are located in a git submodule. The following uses the git cloud-builders image to initialize and update the git submodules, resulting in the theme files being available for future steps:

```bash
steps:
- name: 'gcr.io/cloud-builders/git'
  entrypoint: 'bash'
  args:
  - -c
  - |
    git submodule init
    git submodule update
```

#### 2) Build the Hugo Site

The whole reason for needing a build step is that only the content source files are version controlled (not the generated site files). This step runs the Hugo generator. I couldn't find a publicly available container image that was compatible with Cloud Build, so I created my own (based on [this example](https://github.com/GoogleCloudPlatform/cloud-builders-community/tree/master/hugo)) and posted it to DockerHub: https://hub.docker.com/r/sidpalas/cloud-builder-hugo.

```bash
# build hugo site
- name: 'sidpalas/cloud-builder-hugo:0.64.1'
```

#### 3) Build + Push the Caddy Container Image

This step builds the website container image and pushes it to Google Container Registry. It uses the COMMIT_SHA (which is populated automatically by Cloud Build based on the triggering commit) to tag the image.

```bash
- name: 'gcr.io/cloud-builders/docker'
  # Overriding entrypoint to allow for running two docker commands
  entrypoint: 'bash'
  args: 
    - -c
    - |
      docker build -t gcr.io/$PROJECT_ID/$_IMAGE_NAME:$COMMIT_SHA . &&
      docker push gcr.io/$PROJECT_ID/$_IMAGE_NAME:$COMMIT_SHA
```

#### 4) Stop Running Containers & Start New Container

With the new container available in GCR, the pipeline stops any running containers and then starts the new container using a gcloud container image to execute a `gcloud ssh` command on the VM.

```bash
- name: 'gcr.io/cloud-builders/gcloud'
  args:
  - compute
  - ssh
  - $_SSH_STRING
  - --project=$PROJECT_ID
  - --zone=$_ZONE
  - --
  - docker container stop $$(docker container ls -aq) && 
  - docker container rm $$(docker container ls -aq) &&
  - docker run -d --restart=unless-stopped -p 80:80 -p 443:443 -v $_HOME/.caddy:/root/.caddy gcr.io/$PROJECT_ID/$_IMAGE_NAME:$COMMIT_SHA
```

#### NOTE: Pushing Images 

Normally, the build configuration would have an `images:` section specifying which container images should be pushed to GCR. Because step #3 already tagged and pushed the container image, it is **not** necessary to include an images section:

```bash
images:
- 'gcr.io/$PROJECT_ID/$_IMAGE_NAME:$COMMIT_SHA'
```

### Closing Thoughts

This process ended up being much more complex than I had initially hoped. The issues with Git submodules, and having to create my own Hugo builder image made it take much longer than I expected. That being said, it was quite satisfying when I got the configuration dialed in and the long stretch of red builds finally turned green.

{{< img "images/*cloud-build-dashboard*" "Success!">}}

While I am happy with the end result, I can't help but think using Circle CI might have been a smoother process. Perhaps sometime down the the road I'll attempt setting up an equivalent pipeline there and see how that goes!
