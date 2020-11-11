---
title: "How to Manage Application Secrets (7 Levels of Credential Management)"
date: 2020-11-11T08:29:55-05:00
bookToc: false
tags: [
  "Vault",
  "Security"
]
categories: [
  "Tutorial"
]
---

**TL;DR:** If you develop web applications, inevitably you will have secrets (database credentials, 3rd party API keys, etc...) that you need to manage. I have seen a variety of approaches used here and wanted to walk through them, from least secure to most. 

There are always trade-offs when writing software, and in this case the tradeoff is between convenience and security. The ideal solution will establish convenient developer workflows while also protecting user data.

![cosmic-brain-progression](/static/images/credential-management-meme.png)

<!--more--> 

---

Table of Contents:
- [Level -2: No Authentication](#level--2-no-authentication)
- [Level -1: All Passwords = "password"](#level--1-all-passwords--password)
- [Level 0: Hardcode Everywhere](#level-0-hardcode-everywhere)
- [Level +1: Move Secrets into a Config File](#level-1-move-secrets-into-a-config-file)
- [Level +2: Encrypt the Config File](#level-2-encrypt-the-config-file)
- [Level +3: Use a Secret Manager](#level-3-use-a-secret-manager)
- [Level +4: Dynamic Ephemeral Credentials](#level-4-dynamic-ephemeral-credentials)
- [Final Thoughts](#final-thoughts)

**DISCLAIMER:** _Hopefully this is obvious from the tone of my writing, but PLEASE do not use levels -2, -1, or 0 in the real world._ 🙏

{{< img-link "images/credential-managment-thumbnail.png" "https://www.youtube.com/watch?v=7NTFZoDpzbQ" "If you prefer video format, check out the corresponding YouTube video here!" >}}

## Level -2: No Authentication

For lazy people who like to live dangerously, you can simply turn off authentication for all services and cross your fingers 🤞.

This is the ultimate in convenience as you never have to deal with any secrets. It will be somewhat less convenient when inevitably your data is leaked on the dark web and you have to clean up the ensuing mess.

## Level -1: All Passwords = "password"

If it is too hard to remember more than one password... how about setting them all to the same value? As long as you choose something easy to remember, you can then just share it with your teammates verbally and they will be good to go!

## Level 0: Hardcode Everywhere

When I was learning to program, I received the advice to "define things close to where they are used". Well... you can't get any closer than hard coding it EXACTLY where it gets used!

```js
const mongoose = require('mongoose');

const connectionString = 
  'mongodb://myUser:superSecretPassword@localhost:27017/databaseName';

mongoose.connect(connectionString, { useNewUrlParser: true }).catch((e) => {
  console.error('Connection error', e.message);
});
const db = mongoose.connection;

module.exports = db;
```

Okay, jokes aside -- there are **many** issues here. First, there is no way to avoid checking in the secret to your version control system. Second, it will be a nightmare to maintain because credentials will be sprinkled across many files. Third, there is no way to support multiple environments (separate dev/staging/production).


## Level +1: Move Secrets into a Config File

Rather than hard code at the point of use, it is better to extract secrets into a separate configuration file and then load them in as environment variables. By doing this, you can treat the credential file as sensitive (including adding to `.gitignore` to avoid accidentally checking it into the codebase).

```bash
# secrets.env
DB_PASS=superSecretPassword
```
```js
const dotenv = require('dotenv')
const mongoose = require('mongoose');

dotenv.config({ path: './secrets.env' })

const connectionString = 
  `mongodb://myUser:${process.env.DB_PASS}@localhost:27017/myDatabaseName`;

mongoose.connect(connectionString, { useNewUrlParser: true }).catch((e) => {
  console.error('Connection error', e.message);
});

const db = mongoose.connection;

module.exports = db;
```

For a side project where you are the only person working on it, this method might be sufficient, but it does have the downside of storing the credentials in plain text on your system. Also if you need to share credentials with teammates it is difficult to do so safely.

## Level +2: Encrypt the Config File

One way to share the sensitive configuration file is to encrypt it. This can be done using a two-way encryption algorithm with a tool such as `openssl`:

```bash
export ENCRYPTION_KEY=Where-am-I-supposed-to-store-this?!

# encrypt
openssl aes-256-cbc -a -salt -in secrets.env -out secrets.env.enc -pass pass:$ENCRYPTION_KEY

# decrypt
openssl aes-256-cbc -d -a -salt -in secrets.env.enc -out secrets.env -pass pass:$ENCRYPTION_KEY
```

While certainly better than before, this does kick the can down the road a bit because now you have to figure out how to manage/share the encryption key.

One possible approach is to store it in a shared password manager such as 1Password or use a key management system such as Google Cloud KMS.

This approach doesn't provide any ability to monitor when individual developers are accessing the secrets. In certain industries where this type of audit log is required, this could be an issue.

## Level +3: Use a Secret Manager 

At this point we have taken the concept of a local configuration file about as far as we can. The next level is to move secrets into a dedicated secret manager. All of the major cloud providers offer a service like this, for example AWS has the [Secrets Manager](https://aws.amazon.com/secrets-manager/).

The credentials can then be passed into your application as an environment variable at runtime. I often use the following Makefile snippet to retrieve credentials from GCP as needed:

```bash
PROJECT_ID:=<MY_GCP_PROJECT>
SECRET_NAME:=DB_PASS

define get-secret
$(shell gcloud secrets versions access latest --secret=$(1) --project=$(PROJECT_ID))
endef

run-app:
	@DB_PASS=$(call get-secret,$(DB_PASS))" npm start
```

Moving secrets into a system like this offers a number of benefits. First, these companies have entire teams of security experts building their products making them highly likely to be more secure than whatever system you roll yourself (analogous to "Don't roll your own crypto").

If you are already using the cloud provider to host your application, the tight integration with Identity and Access Management (IAM) functionality, and audit logging can be big wins from a security perspective.

The biggest shortfall with this approach is that rotating can still be a hassle, and often leads to a static set of long lived credentials.

## Level +4: Dynamic Ephemeral Credentials

To acheive fully enlightened credential management, we can move to a model of auto-generating credentials for each use case and only allow them to be active for a short period of time. This way if there is a leak, it greatly minimizes the potential blast radius.

The best implementation of this concept I have seen is [HashiCorp's Vault] (https://www.vaultproject.io/). You can configure Vault so that whenever an application (or individual) needs access to a resource such as a database. It will create a new username/password and handle deleting those credentials after a pre-specified period of time.

There is a great talk on YouTube by Bench Accounting showcasing this approach in action (https://www.youtube.com/watch?v=Y0SdwZDy20Q), along with the corresponding Github Repo (https://github.com/BenchLabs/talk-vault-ephemeral-credentials).

To generate new credentials you can make a call to vault such as:

```bash
$ vault read database/creds/service-write
```
Which returns the new username/password along with some metadata:

```bash
Key                Value
---                -----
lease_id           database/creds/service-write/lVpzrysA5akqSvjZVtCgx1i9
lease_duration     240h
lease_renewable    true
password           A1a-9yW06ZdVk54I5KnX
username           v-token-service--1luYzAYl7SdMxvdpibYv-1555972312
```

Moving to this approach does require that you truly trust Vault (or whatever tool you use) because you have to grant it `root` level permissions across many of your resources. You should protect those credentials as described in level +3.

## Final Thoughts

Hopefully this overview has helped you understand many of the available options for managing credentials for your web application. The right solution for your project will depend on its scale and the sensitivity of the resources being protected.

Before you start building your next application, think about where along this scale makes sense for you and your team so that you can keep your application secure.