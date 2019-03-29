# PingityBot for Slack

PingityBot integrates [Pingity](https://pingity.com) web resource analysis services with Slack, allowing team members to display analysis results directly in-channel, and to monitor particular resources for changes over a desired time period.

## Usage
`/ping` and `/monitor` details go here

## Installation
This repository will allow you to provision and deploy an instance of the PingityBot Slack App server.  In order to get up and running, you'll need a Pingity developer API key to authorize the Pingity Gem.

First, clone the repository locally:

```bash
# ~/
$ git clone git@github.com:StandardGiraffe/slackbot-pingity-sinatra.git pingitybot
$ cd pingitybot
```

### Populate the `.env` file

This is the most convenient time to populate the `.env` file that both PingityBot and the Pingity Gem rely upon to make API calls.  You can use the `.env.sample` as a template:

```bash
# ~/pingitybot

$ cp .env.sample .env
```

**Note:** In order to get the required information, you'll currently need to install the app to your team.  Some of these values will become permanent/abstracted away when the app is authorized on the Slack marketplace.

#### Pingity Gem Credentials
Information to complete the Pingity Gem portion of the `.env` file can be found on your Pingity account's Developer's section, under APIs.  View one of your existing API keys, or create a new one that will be used exclusively by PingityBot.  (This will be the API key against which **all PingityBot tests for all users** will be run, so it should have an unlimited capacity.)

In your `.env` file:
* `PINGITY_ID=` &lt;ID&gt;
* `PINGITY_SECRET=` &lt;Secret&gt;
* `PINGITY_API_BASE=https://pingity.com`

(`PINGITY_API_BASE` will default to `https://pingity.com`, but can be replaced with another endpoint if you wish (for example, if you're running an instance of Pingity locally).)

#### PingityBot Credentials
Information to complete the PingityBot portion of the `.env` file can be found at the app's Slack page.

* Go to the **Basic Information** page and scroll down until you reach the **App Credentials** section.  You can populate the `.env` file as follows:
  * Client ID -> `SLACK_CLIENT_ID`
  * Client Secret -> `SLACK_API_SECRET`
  * Signing Secret -> `SLACK_SIGNING_SECRET`
  * Verification Token -> `SLACK_VERIFICATION_TOKEN`
  (Note, the more secure Signing Secret will be used automatically if available.)
* Next, in **Incoming Webhooks**, create a new Webhook URL for any channels you're planning to invite PingityBot into.  (This feature is currently unused; you can leave `SLACK_WEBHOOK_URL` blank at the moment.)
  * Webhook URL -> SLACK_WEBHOOK_URL
* Finally, in **OAuth & Permissions**:
  * Bot User OAuth Access Token -> SLACK_API_TOKEN

At this point, you should have a completely populated `.env` file.

### Build the Vagrant Machine and Deploy

To build the machine on which the server will run, ensure you have [Vagrant](https://www.vagrantup.com/) and a compatible virtual machine manager installed, and then run:

```bash
# ~/pingitybot

$ vagrant up
```

This will download a Vagrant Box of [Ubuntu Server 18.04](https://app.vagrantup.com/ubuntu/boxes/bionic64) and provision it with the necessary files, applications, and gems.  If you completed your `.env` file in the previous step, it will be copied over (otherwise, a copy of the template will be sent instead; to make further changes, the file can be found at `/app/pingitybot/shared/.env` on the virtual machine).

Finally, ensure you have Capistrano installed and deploy PingityBot to the virtual machine:
```bash
# ~/pingitybot

$ cap vagrant deploy --trace

# If you wish to deploy from a different branch, instead run:
$ BRANCH=<branch name> cap vagrant deploy --trace
```

