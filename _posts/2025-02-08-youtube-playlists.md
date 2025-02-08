---
layout: post
title: Split your YouTube playlists
tags:
- Python
- YouTube
comments: true
---

Split your YouTube playlist into many, using your predefined rules


## Reasoning

Until now, I have been lazy, and I was saving all my favorite music videos under single playlist, no matter the genre.
Now is the time to fix it.
Because YouTube does not have any mechanism to distinct music genres, we have to do it ourselves by creating rules.
So I created a little project written in Python to export the playlist items, split them into multiple lists, and import back up one by one.


## Setup credentials

First, we create a new project at [Google Cloud Console](https://console.cloud.google.com)

![CreateProject](/img/post/split-playlist/CreateProject.png){: class="post-img"}

Search for **api and services** to find **APIs & Services**

![SearchAPIs](/img/post/split-playlist/SearchAPIs.png){: class="post-img"}

Now we need to enable **YouTube Data API v3**

![EnableAPIs](/img/post/split-playlist/EnableAPIs.png){: class="post-img"}

Search for it, and click enable

![EnableYTAPI](/img/post/split-playlist/EnableYTAPI.png){: class="post-img"}

Now navigate to **APIs & Services**, click on **Create Credentials** and **OAuth Client ID**

![APICredentials](/img/post/split-playlist/APICredentials.png){: class="post-img"}

It should ask you to **Configure Consent Screen**, so click on that and select **External** for **User Type**, and click on **Create**

![OAuthConsent1](/img/post/split-playlist/OAuthConsent1.png){: class="post-img"}

On next page fill out:

- App name: Split Playlist
- User support email: your account email

and

- Developer contact information email address: your account email

Press on **Save And Continue**

Now we need to add the following scope:

- **https://www.googleapis.com/auth/youtube.force-ssl**

Let's go further so press on **Save And Continue**

Under **Test users** add your account email

Again press on **Save And Continue**

Now we need to create **OAuth client ID** credential

- Application type: Web application
- Name: just leave default
- Authorized redirect URIs: add **https://localhost**

Click **Create**

In the popup window, download JSON, it will save it as **~/Downloads/client_secret_...-....apps.googleusercontent.com.json**

This is now Done.

## The Project Usage

Project is located on [GitHub](https://github.com/matejc/split_playlist).
Let's look at it on how to use it.

### Install

You can install this Python project the way you like it, but I prefer using virtual environment.

```shell
mkdir ./split_playlist
cd ./split_playlist
python3 -m venv ./venv
./venv/bin/pip install git+https://github.com/matejc/split_playlist
```

This will install three commands:

- pl-token: to login using OAuth client credentials
- pl-split: will fetch playlist items and split them into many using our rules
- pl-insert: incremental upload of playlist items, one playlist at a time

But before we start, we need to create playlist splitting rules


### Split rules

Let's make our own split rules and save them into **./split_playlist/rules.json**:

```json
{
  "rules": [
    {"name": "removed", "fields": [ "channel" ], "patterns": [ null ]},
    {"name": "music_metal", "fields": [ "title", "channel" ], "patterns": [ "Minniva", "Sabaton" ] },
    {"name": "music_metal", "fields": [ "description" ], "patterns": [ "napalm records" ]},
    {"name": "music_dance", "fields": [ "title" ], "patterns": [ ".*" ]}
  ]
}
```

Rules will be executed in following order:

1. Create JSON List file named **data/removed.jsonl** for where **channel** name is **null**, to filter out removed or privated playlist items
2. Create JSON List file named **data/music_metal.jsonl** for where **title**, **channel** include "Minniva" or "Sabaton" keywords
3. Append items to JSON List file named **data/music_metal.jsonl** for where **description** include "napalm records" keyword
4. Create JSON List file named **data/music_dance.jsonl** for everything else (for this example, I have only Metal and Dance)


### Login

Supply the client secret file, downloaded from Google Cloud Console from one of previous steps.

```shell
./venv/bin/pl-token -f ~/Downloads/client_secret_...-....apps.googleusercontent.com.json
```

It will ask you to open the offered URL in the browser and follow the procedure there, until it redirects you to the (non existant) localhost page, at that point copy whole URL back to the upper command.

On successful execution, token will be saved into $HOME/.pl-token file. Later commands will use it automatically.


### Export and Split

To export and split the playlist run the command:

```shell
./venv/bin/pl-split -p "https://www.youtube.com/playlist?list=..." -r ./rules.json -o ./data
```

Make sure you inspect the results before importing your new playlists. You can do that by opening the files (either CSV, or jsonl) named **music_metal** and **music_dance**, inside the **./data** directory.

Note: since the daily quota of requests that you can make is limited, you can re-run the command offline like so (for example if you are not satisfied with rules, and you want to change them):

```shell
./venv/bin/pl-split -p ./data/all.jsonl -r ./rules.json -o ./data
```

### Import

To import one of your new playlists:

```shell
./venv/bin/pl-insert -p "music_metal" -i ./data
```

This will take some time and you might run out of daily quota, if that happens, just re-run the same command each day until everything is uploaded.

Note:

- Command is incremental, so no need to worry if you run it multiple times


## Conclusion

This was fun little project, I always enjoy making things like this, and sharing with you all, since if I had some trouble with something, I am probably not alone.
So wish you good day and keep making new stuff!
