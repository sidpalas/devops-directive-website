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

While it is usually best to attempt to avoid downtime for your production services, sometimes downtime is unavoidable (or at least not worth the effort to avoid). I recently had a project that called for a maintenance period, and this is the solution I came up with. The two key attributes I wanted to achieve were:

- **Easy + fast to toggle on/off** (I wanted to avoid needing and DNS updates because caching can cause them to be slow and unpredictable)
- **No additional container image required** (Every time you build a custom container image, it is one more thing to maintain, host in a registry, etc...)

### How?

To achieve these goals I used the default [nginx image](https://hub.docker.com/_/nginx) and took advantage of the fact that `ConfigMaps` can be mounted as volumes to inject my HTML, CSS, and nginx.conf into the pod at runtime!

I StackOverflow copy/pasted my way to the following `default.conf` nginx configuration which will take all requests (except for `png|jpg|jpeg|css` filetypes) and route them to the maintenance page located at `/usr/share/nginx/html/maintenance/maintenance.html`, returning the proper [503 Service Unavailable](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/503) HTML code:
```
server { 
  listen 80 default_server;
  server_name  _ ;

  location / {
    if (-f /usr/share/nginx/html/maintenance/maintenance.html) {
      return 503;
    }
  }
  
  # for all routes, return maintenance page
  error_page 503 @maintenance;
  location @maintenance {
    root    /usr/share/nginx/html/maintenance/;
    rewrite ^(.*)$ /maintenance.html break;
  }
  
  # allow images and css to be retrieved
  location ~* \.(png|jpg|jpeg|css) {
    root /usr/share/nginx/html/maintenance/;
  }
}
```

#### Kubernetes resources

I created a `ConfigMap` containing the site files (HTML + CSS) and nginx `default.conf` file:
```YAML
apiVersion: v1
kind: ConfigMap
metadata:
  name: maintenance-page
data:
  maintenance.html: |-
    <!--HTML GOES HERE-->
  maintenance.css: |-
    /* CSS GOES HERE */
  default.conf: |-
    # NGINX CONFIGURATIOPN GOES HERE
```

This ConfigMap then gets mounted into a Deployment to achieve the desired effect:
```YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: maintenance-page
  labels:
    app: maintenance-page
spec:
  replicas: 1
  selector:
    matchLabels:
      app: maintenance-page
  template:
    metadata:
      labels:
        app: maintenance-page
    spec:
      containers:
      - name: nginx
        image: nginx:1.23
        ports:
        - containerPort: 80
        volumeMounts:
        # Because no subPath is specified, all keys in configmap willb
        # be mounted as files at the specified mountPath
        - name: config-volume
          mountPath: /usr/share/nginx/html/maintenance/
        - name: config-volume
          mountPath: /etc/nginx/conf.d/default.conf
          subPath: default.conf
      volumes:
        - name: config-volume
          configMap:
            name: maintenance-page
```

All that remains is the Service and Ingress objects to route traffic to this deployment's pod (the cluster is using the [nginx ingress controller](https://docs.nginx.com/nginx-ingress-controller/):
```YAML
apiVersion: v1
kind: Service
metadata:
  name: maintenance-page
spec:
  selector:
    app: maintenance-page
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.org/rewrites: serviceName=maintenance-page rewrite=/;
  name: my-ingress
spec:
  rules:
  - host: maintenance.devopsdirective.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: maintenance-page
            port:
              number: 8080
      # Can still have other paths defined
```

