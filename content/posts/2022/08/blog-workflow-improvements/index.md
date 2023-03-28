---
title: "Blog Workflow Improvements"
date: 2022-08-10T13:36:15Z
bookToc: false
tags: [
    Update
]
categories: [
    Development
]
draft: false
---

**TL;DR:** I set up GitPod and improved the tooling for creating new posts. I am hoping that this reduces the activation energy for writing new posts significantly!

{{< img "images/blog-workflow-new-life.jpg" >}}

<!--more--> 

---

#### Table of Contents:
- [Why Don't I Post here Frequently?](#why-dont-i-post-here-frequently)
- [What to do?](#what-to-do)
  - [Content Management Systems](#content-management-systems)
  - [Containerized / Remote Dev Environment](#containerized--remote-dev-environment)
- [Additional Tweaks](#additional-tweaks)
- [Final Thoughts](#final-thoughts)


## Why Don't I Post here Frequently?

If you look at the history of articles on this site, it is clear that I haven't done a great job staying consistent with posting. This is in contrast to my YouTube channel and Twitter.

When I thought about why that was, a big reason was that writing posts felt like a bit of a chore. There were several manual steps in the process and the just wasn't very fun. Here is what my old process looked like:

1. Open up VS Code
2. Navigate to the `devops-directive-website` project
3. Run `hugo new <POST_NAME>`
4. Manually change the posts from a single markdown file to a directory
5. Start up the Hugo development server
6. Write the post
7. Commit associated files to GitHub
8. GitHub Actions takes over from here

This workflow wasn't terrible... but there were some pain points:

- It only works on my laptop with the environment preconfigured. What if I want to write a post from my iPad or a different computer?
- Writing a blog post *feels* different than writing code and requires a different mindset. I would prefer if the workflow could be isolated such that I can go into "writing mode".
- The manual manipulation of new post files.
- I didn't have spelling/grammar checking set up which lead to lower quality writing with more errors.

## What to do?

### Content Management Systems

As I tried to determine how to best address the first two pain points, I considered all sorts of things. The obvious solution would be to use a web-based content management system (CMS). This could be a fully integrated blogging platform like [WordPress](https://wordpress.org/) or [Ghost](https://ghost.org/) or a "headless" CMS that stores the content which is then displayed via a separate frontend.

These CMSs have a web interface for authoring content which would eliminate the need to have my environment properly set up and would provide a standalone editing experience. I even went so far as to set up both a WordPress and Ghost blog and export/import my content (via RSS feed) into them:

{{< img "images/ghost.png" "Looks pretty good!">}}

This experimentation was reasonably successful and I was able to get my blog ported over and looking decent with some minor theme tweaking. 

That being said, I like the fact that this blog uses static site generation (SSG) which is just a fancy way of saying that rather than storing content in a database and loading it when a user requests the page, the pages are all pre-generated ahead of time. This makes [hosting simple]({{< ref "/posts/2020/10/gcs-cloudflare-hosting/index.md" >}}) and makes handling large traffic spikes like 😅 rather than 🥵.

### Containerized / Remote Dev Environment

I gave some more thought to how I could address the pain points without having to abandon my current setup entirely.  How could I achieve that same browser-based, isolated writing environment while still using Hugo as the blogging engine? The answer was a remote development environment.

In the past few years, products like [Gitpod](https://gitpod.io) and [GitHub CodeSpaces](https://github.com/features/codespaces) have come along, offering development environments that can be spun up quickly with all of the necessary dependencies/configurations and torn down when not in use. The Gitpod free tier allows for 50hrs/month.

The only external dependency my dev environment really needs is Hugo, so I wrote a script to download it from GitHub and place it into a directory on the PATH:

```bash
#!/bin/bash
set -e -o pipefail

HUGO_VERSION=0.76.5
HUGO_TAR_FILE=hugo_extended_${HUGO_VERSION}_Linux-64bit.tar.gz

wget https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/${HUGO_TAR_FILE}
tar -xf ${HUGO_TAR_FILE}
sudo mv hugo /usr/local/bin/
rm ${HUGO_TAR_FILE}
```

I then added this script to be run in the `.gitpod.yml` file:
```yaml
tasks: 
  - before: ./gitpodinit.sh
```

One gotcha I ran into is that I initially ran the script from an `init` task rather than the `before` task. There is a limitation with `init` tasks that any changes made within them only persist within the `/workspace` directory (see [here](https://www.gitpod.io/docs/prebuilds#workspace-directory-only)) so moving to `/urs/local/bin` didn't persist.

I also added some extensions to the `.gitpod.yml` file to ensure they are pre-installed in the workspace and that was all the config needed.

```yaml
vscode:
  extensions:
    - znck.grammarly
    - yzhang.markdown-all-in-one
```

In fact, I'm editing this post from a Gitpod environment right now!

{{< img "images/gitpod-screenshot.png" "Whoa, meta...">}}

## Additional Tweaks

As you may have noticed in my `.gitpod.yml` code above, I added an extension that uses Grammarly to check for spelling and grammar issues, so that solves another one of my problems from before.

Finally, I actually read the Hugo documentation to set up a [directory-based archetype](https://gohugo.io/content-management/archetypes/#directory-based-archetypes) and a new/improved `Make` target for creating new posts:

```Make
.PHONY: create-dir-post 
create-dir-post: check-post-name
	git checkout -b $(POST_NAME)
	hugo new -k=dir-post $(POST_PATH) 
	code content/$(POST_PATH)/index.md
```

As you can see, it checks out a new git branch, creates a post using the directory-based archetype I set up, and opens the `index.md` file so I can start editing right away. No more fiddling with moving/renaming files, etc...

## Final Thoughts

I am hopeful that this new workflow will make it easier for me to write articles and therefore I will do so more frequently. Only time will tell! 🤞

