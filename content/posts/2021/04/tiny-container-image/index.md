---
title: "Tiny Container Challenge: Building a 6kB Containerized HTTP Server!"
date: 2021-04-14T15:16:04-07:00
bookToc: false
tags: [
  "Docker"
]
categories: [
  "Deep Dive"
]
---

**TL;DR** I set out to build the smallest container image that I could that was still able to do something useful. By taking advantage of multistage builds, the `scratch` base image, and a tiny assembly based http server, I was able to get it down to 6.32kB!

{{< img "images/container-for-ants.png" >}}


<!--more-->

---

Table of Contents:
- [Bloated Containers](#bloated-containers)
- [Challenge](#challenge)
- [Naive Solution](#naive-solution)
- [Smaller Base Image](#smaller-base-image)
- [Compiled Languages](#compiled-languages)
- [Multi-stage Builds](#multi-stage-builds)
- [Static Compilation + Scratch image](#static-compilation--scratch-image)
- [ASM for the Win!](#asm-for-the-win)

--- 

{{< img-link "images/tiny-container-thumbnail.png" "https://www.youtube.com/watch?v=VG8rZIE8ET8" "If you prefer video format, check out the corresponding YouTube video here!" >}}

## Bloated Containers
Containers are often touted as a silver bullet to solve every challenge associated with operating software. While I love containers, I often encounter container images in the wild that have a variety of issues. One common issue is size, with images sometimes clocking in at multiple GB!

Because of this, I decided to challenge myself and others to build the smallest possible image.

## Challenge

The rules are pretty simple:
- The container should serve the contents of a file over http on the port of your choosing
- No volume mounts are allowed (Also known as "The Marek Rule" 😜)

## Naive Solution

To get a baseline image size, we can use node.js to create a simple server `index.js`:

```js
const fs = require("fs");
const http = require('http');

const server = http.createServer((req, res) => {
  res.writeHead(200, { 'content-type': 'text/html' })
  fs.createReadStream('index.html').pipe(res)
})

server.listen(port, hostname, () => {
  console.log(`Server: http://0.0.0.0:8080/`);
});
```
and built it into an image starting the official node base image:

```bash
FROM node:14
COPY . .
CMD ["node", "index.js"]
```

This clocked in at `943MB`! 😳

## Smaller Base Image

One of the simplest and most obvious tactics for reducing image size is to use a smaller base image. The official node image has a `slim` variant (still debian based, but with fewer dependencies preinstalled) and an `alpine` variant based on [Alpine Linux](https://alpinelinux.org/).

Using `node:14-slim` and `node:14-alpine` as the base image brought the image size down to `167MB` and `116MB` respectively.

Because docker images are additive, which each layer building on the next there isn't much else we can do to make the node.js solution smaller.

## Compiled Languages

To take things to the next level we can move to a compiled language with many fewer runtime dependencies. There are a variety of options, but for building web services, [golang](https://golang.org/) is a popular choice.

I created a basic fileserver `server.go`:

```go
package main

import (
	"fmt"
	"log"
	"net/http"
)

func main() {
	fileServer := http.FileServer(http.Dir("./"))
	http.Handle("/", fileServer)
	fmt.Printf("Starting server at port 8080\n")
	if err := http.ListenAndServe(":8080", nil); err != nil {
			log.Fatal(err)
	}
}
```
and built it into a container image using the official golang base image:
```bash
FROM golang:1.14
COPY . .
RUN go build -o server .
CMD ["./server"]
```
Which clocked in at... `818MB`. 😡

The issue here is that the golang base image has a lot of dependencies installed that are useful when building go software but aren't needed to run the software.

## Multi-stage Builds

Docker has a feature called [multi-stage builds](https://docs.docker.com/develop/develop-images/multistage-build/) which make it easy to build the code in an environment with all of the necessary dependencies, and then copy the resulting executable into a different image.

This is useful for a variety of reasons, but one of the most obvious is image size! By refactoring the dockerfile as follows:

```bash
### build stage ###
FROM golang:1.14-alpine AS builder
COPY . .
RUN go build -o server .

### run stage ###
FROM alpine:3.12
COPY --from=builder /go/server ./server
COPY index.html index.html
CMD ["./server"]
```

The resulting image is just `13.2MB`! 🙂

## Static Compilation + Scratch image

13 MB isn't too bad, but there are still a couple of tricks we can play to make it even smaller.

There is a base image called [scratch](https://hub.docker.com/_/scratch) which is explicitly empty and has zero size. Because the `scratch` has nothing inside, any image built from it must bring all of its necessary dependencies. 

To make this possible with our go based server, we need to add a few flags to the compilation step in order to ensure the necessary libraries are statically linked into the executable:

```bash
### build stage ###
FROM golang:1.14 as builder
COPY . .
RUN go build \
  -ldflags "-linkmode external -extldflags -static" \
  -a server.go

### run stage ###
FROM scratch
COPY --from=builder /go/server ./server
COPY index.html index.html
CMD ["./server"]
```

Specifically, we set the link mode to `external` and pass the `-static` flag to the external linker.

These two changes bring the image size to `8.65MB` 😀

## ASM for the Win!

An image less than 10MB, written in a language like Go is plenty small for almost any circumstance... but we can go smaller! Github user [nemasu](https://github.com/nemasu) fully functional http server written in assembly on github named [assmttpd](https://github.com/nemasu/asmttpd).

All that was required to containerize it was to install a few build dependencies into the ubuntu base image before running the provided `make release` recipe:

```bash
### build stage ###
FROM ubuntu:18.04 as builder
RUN apt update
RUN apt install -y make yasm as31 nasm binutils 
COPY . .
RUN make release

### run stage ###
FROM scratch
COPY --from=builder /asmttpd /asmttpd
COPY /web_root/index.html /web_root/index.html
CMD ["/asmttpd", "/web_root", "8080"] 
```

The resulting `asmttpd` executable is then copied into the scratch image and invoked with the `CMD`. This resulted in an image size of just 6.34kB! 🥳

{{< img "images/image-sizes.png" "The progression of container image sizes!" >}}

Hopefully you enjoyed this journey from our initial 943MB Node.js image all the way to this tiny 6.34kB Assembly image and learned some techniques you can apply to make your container images smaller in the future.


