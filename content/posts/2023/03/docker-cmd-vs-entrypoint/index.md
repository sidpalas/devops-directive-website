---
title: "Docker CMD vs ENTRYPOINT"
date: 2023-03-28T13:13:32Z
bookToc: false
tags: [
    Docker
]
categories: [
    Tutorial
]
draft: false
---

**TL;DR:** The simplest possible example to demonstrate the difference between Docker's CMD and ENTRYPOINT instructions:

{{< img-large "images/cmd-vs-entrypoint.png" >}}

<!--more--> 
---

## Dockerfile

The Dockerfile CMD and ENTRYPOINT instructions can be confusing. Let's create a mimimal docker image to explore how they behave and interact with eachother:

```Bash
docker build -t entrypoint-cmd-example -<<EOF 
  FROM busybox 
  ENTRYPOINT [ "echo", "[ENTRYPOINT]" ]
  CMD [ "[CMD]" ]
EOF 
```

## No Arguments

If you run the image as is (no options/arguments), the ENTRYPOINT is used as the executable and the CMD is appended as arguments.

```bash
docker run entrypoint-cmd-example 
```

The output will combine the ENTRYPOINT and CMD from the Dockerfile: 
```bash
[ENTRYPOINT] [CMD]
```

## With Arguments (override CMD)

If you specify arguments at runtime (e.g. docker run image-name FOO), those arguments override the CMD from the Dockerfile.

```bash
docker run entrypoint-cmd-example "[OVERRIDDEN CMD]" 
```

The output will combine the ENTRYPOINT from the Dockerfile with the arguments provided at runtime:

```bash
[ENTRYPOINT] [OVERRIDDEN CMD] 
```

## Override Entrypoint

If you specify a new entrypoint at runtime (e.g. docker run --entrypoint=BAR image-name) that will override the ENTRYPOINT and IGNORE the CMD from the Dockerfile.

```bash
docker run --entrypoint echo entrypoint-cmd-example 
```

Output is an empty string since `echo` is run with no arguments.
```bash

```

## With Arguments (override CMD) AND Override Entrypoint

If you specify a new entrypoint AND arguments at runtime (e.g. `docker run --entrypoint=BAZ image-name BING`) those will be used instead of the values from the Dockerfile.

```bash
❯ docker run --entrypoint=echo entrypoint-cmd-example "[OVERRIDDEN CMD]" 
```

The output will use the arguments supplied at runtime with the executable specified in the overriden entrypoint:

```bash
[OVERRIDDEN CMD] 
```

## When to Use Each

You should specify an ENTRYPOINT if you want the container to use the same executable (but potentially with different arguments) every time.

The CMD should contain the default arguments you want the container to run with.

The official docs have a nice summary of the various interactions as well: https://docs.docker.com/engine/reference/builder/#understand-how-cmd-and-entrypoint-interact

It is made slightly more complex by the fact that there is different behavior between:

```bash
ENTRYPOINT foo
```

AND 

```bash
ENTRYPOINT ["foo"]
```

(With the latter being preferred)