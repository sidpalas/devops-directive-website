---
title: "Turning off Google Analytics for Local Hugo Server"
date: 2020-04-03T16:52:56-07:00
bookToc: false
tags: [
  "Quick",
  "Hugo"
]
categories: [
  "Tutorial"
]
---

**TL;DR:** If using Google Analytics, most Hugo themes load the tracking script even when running locally. This causes a bunch of bogus page views when writing a new article. Using an environment variable is an easy way to fix this.

![DevOps Symbols](/static/images/bogus-google-analytics.png)
*Whoops... that's me visiting my site on localhost*

<!--more--> 

---

To solve this, find where in the theme the following template is being used:

```
{{- template "_internal/google_analytics_async.html" . -}}
```

and wrap it in a conditional that checks whether the `HUGO_ENV` environment variable is set to `"Production"`:

```
{{ if eq (getenv "HUGO_ENV") "production"}}
  {{- template "_internal/google_analytics_async.html" . -}}
{{ end }}
```

This way if you run your server locally with `$ hugo server` it will not get triggered. Wherever you build your site for production make sure to set that environment variable like so:

```
HUGO_ENV=production hugo 
```

For the DevOps Directive site, the hugo build step actually happens within a GCP cloud build pipeline, so I set the environment variable inside the DockerFile for that build step which can [be seen here](https://github.com/sidpalas/cloud-builder-hugo/blob/0dc33337e4432414c0ea35ed445e87851e1cdd3c/Dockerfile#L11).

I hope that helps anyone who encounters the same situation!
