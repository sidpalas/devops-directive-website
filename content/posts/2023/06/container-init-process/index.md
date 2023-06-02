---
title: "Container Init Process"
date: 2023-06-02T11:37:18Z
bookToc: false
tags: [
  Containers
]
categories: [
  Deep Dive
]
draft: true
---

**TL;DR:** When deploying applications in containers, understanding the role and implications of the init process is critical. In this article, we'll delve into how our application runs as Process ID #1 in a container, and what this means for our application's signal handling and zombie process management.

{{< img-large "images/init-process-diagram.jpg" "To init or not to init, that is the question..." >}}

<!--more--> 

## Understanding the Init Process

When we boot up a Linux computer or virtual machine, the first process to start is known as the "init process". This process is assigned Process ID #1, given that PIDs are assigned sequentially. The init process carries several responsibilities including initializing the kernel, mounting filesystems, managing services and daemons, and supervising other processes.

This article is not meant to be an exhaustive discussion on init systems. We are only examining aspects of init systems that are relevant to running containers. If we want to learn more about Linux init systems, I recommend watching ["Whats the Point of A Linux Init System"](https://www.youtube.com/watch?v=lDdVUlXLjx8) by Brodie Robertson.

{{< youtube lDdVUlXLjx8 >}}

## The Implications of PID 1 in Containers

Now, what about Linux containers? Containers typically have their own isolated PID namespace. This implies that the process executed upon startup (the `ENTRYPOINT` or `CMD` within our Dockerfile) gets run as PID 1 inside the container.

In a standard Linux system, PID 1, also known as "init," is treated differently from other processes. As mentioned above it has a number of specific responsibilities, some of which may impact our container's operation. Two aspects of init processes are particularly relevant for containers:

1. **Signal Handling:** What happens when we send a `SIGINT` or `SIGTERM` signal to the container?
2. **Zombie Process Handling:** What happens when we spawn child processes, and the parent exits?

Let's examine these aspects in detail.

## Signal Handling in Containers

Signal handling determines how our application responds to system signals, such as `SIGINT` (interrupt from keyboard) or `SIGTERM` (termination signal).

For instance, consider a Node.js program that loops indefinitely and doesn't handle system signals:

```js
// javascript program that doesn't handle signals
while (true) {
  console.log("Looping forever...");
}
```

If this is running inside a container, when we press `CTRL + C`, which sends a `SIGINT`, or when we execute `docker stop`, which sends a `SIGTERM`, the application continues running. This behavior is due to the lack of appropriate signal handling in the application code.

So what can we do about this?

### Option 1: Handle Signals in the Application Code

If we control the application source code, it is best to add handlers in our application code that respond appropriately to system signals such as `SIGINT` and `SIGTERM`. Moreover, it's best practice to include code that gracefully terminates any ongoing operations, such as closing open client connections before calling `process.exit()`.

```js
// Node.js program that handles SIGINT and SIGTERM signals
process.on('SIGINT', function() {
  console.log('Received SIGINT. Gracefully shutting down...');
  // Insert necessary commands to shut down gracefully here
process.exit();
});

process.on('SIGTERM', function() {
  console.log('Received SIGTERM. Gracefully shutting down...');
  // Insert necessary commands to shut down gracefully here
  process.exit();
});

while (true) {
  console.log("Looping forever...");
}
```

### Option 2: Run a Separate Init Process

If we do not control the application source code, we can run a separate program as the init process which will in turn spawn the primary application. Tini is a "tiny buy valid init for containers" designed specifically for this purpose (https://github.com/krallin/tini).

Docker has the abiliy to do this at runtime by using the init flag (`docker run --init <CONTAINER_IMAGE>`). This approach works, but is specific to Docker. If we want a solution that will always run Tini without relying on a specific container runtime implementation, we can build it into the container image!

```Dockerfile
FROM node:18.16-bullseye

ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]

COPY . .
CMD ["node", "index.js"]
```

It is important to note that this will NOT magically make our app terminate gracefully, but at least `SIGINT` and `SIGTERM` signals will stop the containerized application.

## Zombie Process Handling in Containers

A "Zombie" process is a process that has finished its execution but still exists in the process table. Although these processes no longer consume CPU or memory, they should ideally be cleaned up. The init process typically handles this clean-up.

For example, consider a Node.js program that uses `child_process.spawn` in detached mode to run a shell script that initiates a sleep operation in the background before exiting. This sequence can create zombie processes.

```js
// index.js
const { exec } = require('child_process');

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function main() {
  while (true) {
    console.log('Spawning child process!');
    exec('./child.sh');
    await sleep(1000);
  }
}

main();
```

Shell script `child.sh`:
```sh
#!usr/bin/env sh
# child.sh (called from Node.js program)
sleep 3 &
exit 0
```

In this scenario, each invocation of `child.sh` is a child process, and each `sleep` invocation within the child is a grandchild. When the `child.sh` processes exit, the grandchildren run to completion and never get cleaned up, turning into zombie processes.

To resolve this issue, we can update our code so that parent processes wait for their children to exit. In a shell script, we can achieve this by waiting for the PID of the grandchild. If we're spawning native Node.js processes, much of this will be handled automatically.

```sh
#!usr/bin/env sh
sleep 3 &

# By capturing the PID of the sleep command and waiting 
# for it to exit we no longer create zombies!
pid=$!
wait $pid
```

As with signal handling, if we don't control the source code, we can use a separate init process to handle zombie processes. The separate init process will reap zombie processes when they exit.

## Summary

Running our application as PID 1 inside a container has implications for signal handling and zombie process reaping. The best practices are:

1. Properly handle system signals in our application code.
2. Manage child processes to prevent the creation of zombie processes.

If we cannot modify the application code, consider using a separate init process.

Hopefully, this article has helped we understand these considerations. To learn more about containers, check out my comprehensive course {{< link "https://courses.devopsdirective.com/docker-beginner-to-pro/lessons/00-introduction/01-main" "Docker: Beginner to Pro" >}}:

{{< img-link "images/course-screenshot.png" "https://courses.devopsdirective.com/docker-beginner-to-pro/lessons/00-introduction/01-main" >}}

## Additional Resources:

Here is a list of additional resources on the internet I found helpful when trying to understand this topic:

- [Why do you need an init process inside your Docker container (PID 1) -- Dávid Szabó](https://daveiscoding.com/why-do-you-need-an-init-process-inside-your-docker-container-pid-1)
- [PID 1 Orphan Child Processes in Docker -- Peter Malmgren](https://petermalmgren.com/pid-1-child-processes-docker/)
- [You Don't Need an Init System for Node.js in Docker -- Christian Emmer](https://emmer.dev/blog/you-don-t-need-an-init-system-for-node.js-in-docker/)
- [The Almighty Pause Container -- Ian Lewis](https://www.ianlewis.org/en/almighty-pause-container)
- [Choosing an init process for multi-process containers -- Ahmet Alp Balkan](https://ahmet.im/blog/minimal-init-process-for-containers/)
- [Docker and Node.js Best Practices from Bret Fisher at DockerCon 2019 [YouTube] -- Bret Fisher](https://youtu.be/Zgx0o8QjJk4?t=1065)