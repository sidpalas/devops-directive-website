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

**TL;DR:** When deploying applications in containers, understanding the role and implications of the init process is critical. In this article, we'll delve into how your application runs as Process ID #1 in a container, and what this means for your application's signal handling and zombie process management.

{{< img-large "images/init-process-diagram.jpg" "To init or not?..." >}}

<!--more--> 

## Understanding the Init Process

Within a container, by default, your application will run as Process ID #1. In a standard Linux system, PID 1, also known as "init," is treated differently from other processes. It carries certain responsibilities that may impact your container's operation. Two aspects of init processes are particularly relevant for containers:

1. Signal Handling: What happens when you send a SIGINT or SIGTERM signal to the container?
2. Zombie Process Handling: What happens when you spawn child processes, and the parent exits?

Let's examine these aspects in detail.

## Signal Handling in Containers

Signal handling determines how your containerized application responds to system signals, such as `SIGINT` (interrupt from keyboard) or `SIGTERM` (termination signal).

For instance, consider a Node.js program that loops indefinitely and doesn't handle system signals. When you press `CTRL + C`, which sends a `SIGINT`, or when you execute `docker stop`, which sends a `SIGTERM`, the application continues running. This behavior is due to the lack of appropriate signal handling in the application code.

```js
// javascript program that doesn't handle signals
while (true) {
  console.log("Looping indefinitely...");
}
```

To manage system signals effectively, you need to add handlers in your application code that respond appropriately to `SIGINT` and `SIGTERM` signals. 

Moreover, it's best practice to include code that gracefully terminates any ongoing operations, such as closing open client connections before calling `process.exit()`.

```js

Understanding the Init Process in Containers
When deploying applications in containers, understanding the role and implications of the init process is critical. In this article, we'll delve into how your application runs as Process ID #1 in a container, and what this means for your application's signal handling and zombie process management.

[Placeholder for the flow chart image: This diagram summarizes the options for handling the init process in a container.]

Understanding the Init Process
Within a container, by default, your application will run as Process ID #1. In a standard Linux system, PID 1, also known as "init," is treated differently from other processes. It carries certain responsibilities that may impact your container's operation. Two aspects of init processes are particularly relevant for containers:

Signal Handling: What happens when you send a SIGINT or SIGTERM signal to the container?
Zombie Process Handling: What happens when you spawn child processes, and the parent exits?
Let's examine these aspects in detail.

Signal Handling in Containers
Signal handling determines how your containerized application responds to system signals, such as SIGINT (interrupt from keyboard) or SIGTERM (termination signal).

For instance, consider a Node.js program that loops indefinitely and doesn't handle system signals. When you press CTRL + C, which sends a SIGINT, or when you execute docker stop, which sends a SIGTERM, the application continues running. This behavior is due to the lack of appropriate signal handling in the application code.

javascript
Copy code
// Node.js program that doesn't handle signals
while (true) {
  console.log("Looping indefinitely...");
}

### If this is your application (you control the source)

To manage system signals effectively, you need to add handlers in your application code that respond appropriately to SIGINT and SIGTERM signals. Moreover, it's best practice to include code that gracefully terminates any ongoing operations, such as closing open client connections before calling process.exit().

javascript
Copy code
// Node.js program that handles SIGINT and SIGTERM signals
process.on('SIGINT', function() {
  console.log('Received SIGINT. Gracefully shutting down...');
  process.exit();
});

process.on('SIGTERM', function() {
  console.log('Received SIGTERM. Gracefully shutting down...');
  process.exit();
});

while (true) {
  console.log("Looping indefinitely...");
}
```

### If this is not your application (you don't control the source)

If you do not control the application source code, we can run a separate program as the init process which will in turn spawn the primary application. Tini is a "tiny buy valid init for containers" designed specifically for this purpose (https://github.com/krallin/tini).

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

It is important to note that this will not magically make your app terminate gracefully, but at least `SIGINT` and `SIGTERM` signals will stop the application.

## Zombie Process Handling in Containers

A "Zombie" process is a process that has finished its execution but still exists in the process table. Although these processes no longer consume CPU or memory, they should ideally be cleaned up. The init process typically handles this clean-up.

For example, consider a Node.js program that uses `child_process.spawn` in detached mode to run a shell script that initiates a sleep operation in the background before exiting. This sequence can create zombie processes.

```js
const { exec } = require('child_process');

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function main() {
  let seconds = 0;
  while (true) {
    console.log(`${seconds}...`);
    console.log('Spawning child process!');
    exec('./child-background.sh');
    await sleep(1000);
    seconds += 1;
  }
}

process.on('SIGINT', () => {
  console.log('SIGINT signal received!');
  // Logic to gracefully terminate children goes here!

  process.exit();
});

main();
```

```sh
#!usr/bin/env sh
sleep 3 &
exit 0
```

In this scenario, each invocation of child.sh is a child process, and each sleep invocation within the child is a grandchild. When the child.sh processes exit, the grandchildren run to completion and never get cleaned up, turning into zombie processes.

To resolve this issue, you can update your code so that parent processes wait for their children to exit. In a shell script, you can achieve this by waiting for the PID of the grandchild. If you're spawning native Node.js processes, much of this will be handled automatically.

```sh
#!usr/bin/env sh
sleep 3 &
pid=$!

wait $pid
```

As with signal handling, if you don't control the source code, you can use a separate init process to handle zombie processes. The separate init process will reap zombie processes when they exit.

## Summary
Running your application as PID 1 inside a container has implications for signal handling and zombie process reaping. The best practices are:

1. Properly handle system signals in your application code.
2. Manage child processes to prevent the creation of zombie processes.

If you cannot modify the application code, consider using a separate init process.

Hopefully, this article has helped you understand these considerations. To learn more about containers, check out my comprehensive course {{< link "https://courses.devopsdirective.com/docker-beginner-to-pro/lessons/00-introduction/01-main" "Docker: Beginner to Pro" >}}

