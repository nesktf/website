+++
[BLOG_ENTRY]
title = "Self hosting things"
subtitle = ""
timestamp = 1780770642
slug = "1780770642-self-hosting-things"
tags = ["self-host", "linux"]
+++

## "Owning" software
I like to own the software that I use, not in the traditional sense of "owning" where you just
acquire a license for using it within some constraints but more in the free software kind of way
where you can manipulate it in any way you want, be it modifying the source, sharing it with
others or just being able to copy it and use it how and whenever you want.

One of the trends of current times that I hate the most is that almost everything is a subscription
web service where you don't have freedom of use for your own software and/or data however you'd
like. You cannot copy it, run it locally, and you have to pay every once in a while to keep the
"privilege" of being a user.

To mitigate this problem I prefer to use FOSS on my personal computers whenever I can, I only use
propietary software if I'm obligated to do so or if it's a videogame (though, I prefer games 
without DRM). This is fine for the most important pieces of software that I use (like my operating
system, code editor, compiler, web browser, etc.), but sometimes you want to have access to
some kind of service when you want to share data or some kind of functionality between machines,
and usually the most convenient way to do this is just to use a web service of some kind.

## Self hosting things
Since I prefer not to use random web services from the internet just for convenience, I started to
search for software services that I can run on my local network and can give me the functionality
I need.

I don't have any servers, but I decided to just use my main desktop PC for hosting. The software
that I'm going to mention really doesn't use a lot of computing power. My computer specs are
the following:

- CPU: Ryzen 3 3200G (I use integrated graphics)
- RAM: 16GB
- Storage: 1TB HDD + 500GB Nvme
- OS: Debian 12 Bookworm

## Jellyfin
I grew tired of having to load my anime video files via SFTP, it's very clunky and I can't access
my library this way if I use the TV or my switch.

For local video you have two main alternatives, Plex and Jellyfin. I went with Jellyfin since I
don't like the idea of having to pay for having access to my own data in my own computer (lmao).

![jellyfin](%%DIR%%/jellyfin.png "I have to finish my backlog, eventually"){width=750 height=auto}

At first I found it kind of annoying to use, sometimes it doesn't recognize your series correctly.
Usually it either thinks is some random show that has nothing to do or just doesn't download
any metadata.

To fix this, I found out that you need to have some kind of naming scheme in your files. You
separate your shows in folders with the exact name that is displayed in your metadata provider
(usually TheTVDB) and you separate the video files in seasons subfolders. For example, for K-ON
Season 1 you store all the video files on a subfolder named "Season 1" and then rename each file
depending on the episode number in the format "S01XX" where XX is the episode number.

Once you get the hang of it it's actually very comfy to use. You can use it just like any other
streaming service, and you can even load music files. You can use it from the browser of use a
client, it has clients for all the important platforms (even a
[switch homebrew](https://github.com/dragonflylee/switchfin))

- [Link to the jellyfin website](https://jellyfin.org/)

## Suwayomi
I don't have the habit of reading manga, I read some things from time to time. But when I do read
something I like to have it organized just like my anime.

My preferred software for this has always been Tachiyomi (or any of the new forks that have
been popping up since it died), but it had two mayor downsides: It's a phone app and it
doesn't have a good way to synchronize my reading progress.

Then I found Suwayomi (previously Tachidesk), which is basically just a port of Tachiyomi for
desktops but with the added bonus that it can be used as a local server.

![suwayomi](%%DIR%%/suwayomi.png "I like reading JoJo's"){width=750 height=auto}

Not much more to say about this one. I just think it's neat.

- [Link to the suwayomi repo](https://github.com/Suwayomi/Suwayomi-Server)

## cgit
The latest addition to my self hosted things has been a local git http client. I like having a
list of all my projects in one place where I can easily steal some snippets of source code, but I
don't like to have every single project that I have made hosted on an internet web service.

I had a lot of options for this one, but I just settled with cgit. It's just very easy to setup,
and I even found out that it can be themed using some basic css.

![kappagit](%%DIR%%/kappagit.png "Don't let the Yamawaro find the source code"){width=750 height=auto}

I just stole a css theme from [here](https://git.vidhukant.com/cgit-catppuccin/) and slapped some
syntax highlighting. I must say it ended up looking pretty cool.

For uploading I still prefer to use the standard git way using SSH, but when keeping an eye
on the progress via commits and diffs its so much more convenient this way. It was also very fun
to make a silly logo just for this, I love doing stupid things like that.

- [Link to the cgit main repo](https://git.zx2c4.com/cgit/about/)

## Things to improve in the future

![patchy](%%DIR%%/patchy.jpg "Patchy self hosts"){width=640 height=auto}

I'm debating if it's a good idea to expose these services to the internet using a reverse
proxy or something. For things like my git repos it can be a nice way to share source code, and
it can be convenient to have access when I'm not at home. But I'm still unsure about the security
aspect of it and the fact that I don't have my computer on 24/7.

It would mess things up a little bit if I ever want to host something that is always
available (like this website!). So for now I just expose OpenVPN and access things from there if
I ever have the need to.

I'm currently not backing up the server configs anywhere, so if I ever try to migrate to
another computer I think I'm kind of screwed and I might have to do everything from scratch. I will
try to fix this when/if I ever switch to NixOS for hosting things.

Also, I'd like to someday have dedicated servers for hosting, but that will have to wait for a
bit since I'm still poor at the moment :p
