---
title: "Doing Stupid Stuff with GitHub Actions"
date: 2020-07-25T09:25:12-07:00
bookToc: false
tags: [
  "GitHub",
  "GitHub Actions",
  "CI",
  "CD"
]
categories: [
  "Impractical"
]
---
 
**TL;DR:** DevOps doesn't have to be all work and no play. I built 5 stupid (but fun!) GitHub actions... because *why not*?

The full code for these actions can all be found in this **[GitHub repo](https://github.com/sidpalas/stupid-actions)**. I encourage you to fork and/or add issues/PRs with impractical actions of your own!

I also recorded a video about this project on **[YouTube](https://www.youtube.com/watch?v=w7-ugGAYVCo)**. ← Check out the video and subscribe if you are into this sort of thing 🙏

![Whiteboard Screenshot](/static/images/stupid-actions.png)

<!--more--> 

---

**Table of Contents:**
- [What is GitHub Actions?](#what-is-github-actions)
- [The Actions](#the-actions)
  - [1 -- Holiday Reminder](#1----holiday-reminder)
  - [2 -- Recursive Action](#2----recursive-action)
  - [3 -- Exponential Action](#3----exponential-action)
  - [4 -- Smart Lights](#4----smart-lights)
  - [5 -- Tic-Tac-Toe](#5----tic-tac-toe)
- [Closing Thoughts](#closing-thoughts)

## What is GitHub Actions?

GitHub Actions is a CI/CD platform built into GitHub. It can be used to automate things such as building, testing, and deploying code and can be triggered by any GitHub event.

There is also a [marketplace](https://github.com/marketplace?type=actions) where developers can publish their actions for others to use.

While I have used many CI/CD systems including Jenkins, Google Cloud Build, and CircleCI, prior to this project I hadn't explored GitHub Actions, so I thought I would try it out and have some fun along the way.

Enough preamble, let's get to the stupid stuff!

## The Actions

### 1 -- Holiday Reminder

Starting simple with this first action, I take advantage of the fact that actions can be triggered on a cron schedule to create the following 10 line action:

```yaml
name: holiday-reminder-happy-new-year
on:
  schedule:
    - cron: '0 0 1 1 *'
jobs:
  happy-new-year:
    runs-on: ubuntu-latest
    steps:
    - name: throw error
      run: exit 1
```

The action will run at midnight on New Year's day and fail every time due to the non-zero exit code. This will cause GitHub to send me an email wishing me a Happy New Year 🎉🎉🎉.

### 2 -- Recursive Action

The next idea was proposed by a friend and former colleague (https://scotchka.github.io/). He suggested that I make an action which triggers itself, thus creating an infinite chain of actions.

Given that the GitHub documentation explicitly states ["To minimize your GitHub Actions usage costs, ensure that you don't create recursive or unintended workflow runs,"](https://docs.github.com/en/actions/reference/events-that-trigger-workflows#triggering-new-workflows-using-a-personal-access-token) this seemed like a sufficiently stupid idea. To achieve this, I created an action triggered by commits that makes and commits a code change of its own.

There are two interesting parts to this action:
1) GitHub helps prevent users from accidentally doing this by not triggering actions based on events associated with the default `GITHUB_TOKEN`. In order to get around this, I created a [personal access token](https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token). See the [action yaml file](https://github.com/sidpalas/stupid-actions/blob/master/.github/workflows/recursive.yml) for how this gets used.
2) In order to prevent the infinite action chain, I persist a count of the action executions within a file in the repo and increment it with each execution. This allows me to terminate the action chain when I reach a specified limit.

```bash
COUNTER_FILE=./recursive/counter.txt
MAX_COUNT=5

count=$(cat "$COUNTER_FILE") 
if (( $count > $MAX_COUNT ));
then 
    echo "Count too high... exiting";
else
    echo "Count okay... continuing";
    echo $(( $count + 1 )) > $COUNTER_FILE
    git config --global user.email "sid@devopsdirective.com"
    git config --global user.name "sid"
    git add $COUNTER_FILE
    git commit -m "Incremented counter file"
    git push 
fi; 
```

### 3 -- Exponential Action

The previous action has the potential to run indefinitely, but only one instance executes at a time, so it could be stopped manually if necessary. What if instead, the action triggered itself multiple times? This way, if it got out of hand there would be no stopping the exponential growth 😰. That sounds dumb... lets do it!

The file counter trick from before no longer works because multiple actions would be executing in parallel, all trying to modify and commit simultaneously causing conflicts. Instead, I stored the state in Git tags!

A random UUID is used as the base for the tag and the current iteration is appended to prevent collisions. The current implementation only support single digits, but if I make it past 9 iterations of exponential growth that means I messed up 💀.

```bash
function increment_tag_push {
    uuid=$(uuidgen)
    suffix=$(( $count + 1 ))
    tag=$1.$uuid.$suffix
    git tag -a $tag -m "New UUID tag"
    git push origin $tag
}

count="$(echo -n $GITHUB_REF| tail -c 1)"

echo $GITHUB_REF
echo $count

sleep 10 # In case something goes wrong (this saved me during development 😳)
MAX_COUNT=2

if (( $count > $MAX_COUNT ));
then 
    echo "Count too high... exiting";
else
    echo "Count okay... continuing";
    git config --global user.email "sid@devopsdirective.com"
    git config --global user.name "sid"
    for ((i = 1; i <= $1; i++ ));
    do
    increment_tag_push $i
    done
fi; 
```

If you are looking for a quick way to burn through your 2000 free tier minutes... this is definitely the way to go!

### 4 -- Smart Lights

Thus far, these actions have been implemented in small bash scripts. In order to actually explore the capabilities of GitHub actions I decided the next action should utilize [Docker](https://docs.github.com/en/actions/creating-actions/creating-a-docker-container-action). 

I had a couple of WiFi smart plugs from VeSync that I received as a gift a few years ago and found a [python client for their API](https://pypi.org/project/pyvesync/). This made it simple to create an action which turns the lights on for a short period of time after each commit (what better way to incentivize code velocity?!💡)

{{< img "images/lights-off.gif" "Lights on... Lights off!" >}}

The code for this one isn't particularly interesting, but because the action is using more than just bash, it requires an `action.yml` file in which we can see how inputs get passed into the action:

```yaml
name: 'Turn on Lights'
description: 'Turn on smart home lights for a few seconds'
inputs:
  VESYNC_PASS:  
    description: password for VESYNC_PASS
    required: true
runs:
  using: 'docker'
  image: 'Dockerfile'
  env:
    VESYNC_PASS: ${{ inputs.VESYNC_PASS }}
```

### 5 -- Tic-Tac-Toe

With the team starting to get a bit burnt out having to commit code constantly just to keep the lights on, I decided to implement a game of Tic-tac-toe to let them burn off some steam. The trick is that the computer player for this game executes within an action!

{{< img "images/tic-tac-toe.png" "Command line interface + board state file" >}}

I wanted to try out the [Javascript runtime](https://docs.github.com/en/actions/creating-actions/creating-a-javascript-action), so I built the game with Node, persisting the board state in a text file. Since the point of this game was to learn about actions the computer's strategy is random, but this has the added benefit of letting the human win, boosting morale 🤔.

## Closing Thoughts

Overall, GitHub Actions turned out to be fairly easy to work with and the option Dockerize the action steps ensures that it should be able to support pretty much any CI/CD need. Also, GitHub has made sharing and reuse of actions a core part of the experience through the Marketplace. 

While I'm won't be rushing off to port existing CI/CD workloads onto GitHub actions, I will certainly consider it for future greenfield projects!