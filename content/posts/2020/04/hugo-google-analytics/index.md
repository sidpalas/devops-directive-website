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

**TL;DR:** If using Google Analytics, most Hugo themes load the tracking script even when running locally. This causes a bunch of bogus page views when writing a new article. Creating separate config files for development and production is an easy way to fix this.

![DevOps Symbols](/static/images/bogus-google-analytics.png)
*Whoops... that's me visiting my site on localhost*

<!--more--> 

---

To solve this, take advantage of the fact that Hugo allows for specifying multiple configuration files. In this case create a separate "production" `config.toml` file without the `googleAnalytics` code specified and rearrange the directory structure as follows:

```
├── config
|   ├── _default
|   │   └── config.toml
|   └── production
|       └── config.toml
```

When serving locally with `hugo serve` the config in _default will be used, but when generating the site with `hugo`, Hugo will default to the production configuration.

If you do want to test the production configuration locally, you can specify the environment via a command flag:

`hugo serve --environment production`

The full documentation for this feature can be found on the [gohugo.io website](https://gohugo.io/getting-started/configuration/#configuration-directory).

I hope that helps anyone who encounters the same situation!
