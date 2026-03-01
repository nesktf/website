+++
[BLOG_ENTRY]
title = "Smallish update"
subtitle = "Things I did recently"
timestamp = 1772389571
slug = "1772389571-smallish-update"
tags = ["update", "me", "meta"]
+++

## Studies 
It has been a while since I've written something here, so wanted to share a little bit of an update.

I've been in a small vacation on the last few months, nothing special I just relaxed a little bit from
university and worked on my projects at home. That was until the first days of February when I had
to start studying for finals, and I just finished with them last week. It appears everything went ok, I
just have to wait a little bit for the results.

Now I have to start going to classes again next Wednesday, so I'm planning and preparing everything
since this will be hopefully the last year where I have to keep attending classes. If everything goes
smoothly I will only have some finals left for the next year and that's it for my university degree.

## Projects
I spent most of the time rewritting a lot of things for
[my graphics library](https://github.com/nesktf/shogle), hopefully this will be the last time (or maybe
not?). I removed a lot of unnecessary complexity that I wrote to abstract the system graphics API and
started adding a little bit of Vulkan code, nothing special. I also made a silly little logo (?) since
I found it funny:

![shogle](%%DIR%%/shogle.gif "As shrimple as that"){width=auto height=auto}

Another project that I started thinking about is making a local [picmix](https://www.picmix.com/) clone.
I like doing silly images using that website so I thought it could be a fun project. This was one of the
reasons to rewrite lots of things from ShOGLE since I was tired of writting so much boilerplate to
show things on screen, so hopefully now I can use it to make actually useful programs.

I also worked a little bit on my 3D game engine, trying to add simple rigidbody physics from the book
[Game Physics Engine Development](https://www.sciencedirect.com/book/monograph/9780123694713/game-physics-engine-development).
I stumbled upon it on a SethBling video some months ago and it caught my attention.

Here, take a look at a simple spring simulation:

![kappa](https://files.catbox.moe/373jua.mp4 "Cirno on the resonance frequency"){width=auto height=auto}

This also made me remember that I have to migrate from catbox for videos, it takes a lot of time to load
them sometimes for me. Hopefully I can stop depending on external sites for videos when I eventually
setup a VPS and move from neocities.

## The website
I did a full refactor of the static generator part of the website. I started doing it on January but
I was just too lazy to fix some bugs that I ended up introducing until now lmao.

This was mostly to fix some things in the markdown compilation step that were making it difficult to
manipulate the HTML output, so now that I've fixed it I can make things like an RSS feed (yay!!).

I started working on a silly little 88x31 website button; I made two versions but still none of them
convinced me so I might work on it a little bit more.

![button1](%%DIR%%/button_thingy_ver1.png "First version"){width=auto height=auto}

![button2](%%DIR%%/button_thingy_ver2.png "Second version"){width=auto height=auto}

The next thing after implementing the RSS generator is to fill the `pages/` section with things. I'm
still wondering what I want to add there, so it might take a little while too.

Also, I initially intended for the blog section to be something like a general devblog where I would
only post things when I finish a project or reached some kind of milestone, but I realized that I like
sharing random things more so I will start doing that too along the programming things.

## Other things
One thing that I want to do eventually is to move my computers to NixOS, or at least my main desktop
PC since I got tired of working with old packages from Debian. It was a good choice for the time, since
I moved to Debian when Plasma 6 came out and I didn't want to update, but now I've migrated to AwesomeWM
and no longer have any uses for old packages.

I experimented a little bit with Nix on a VM and it looks interesting, it appears like I can make it be
a good middle point between Debian and Arch. I just neeed to keep testing things a little bit more and
then try to migrate my dotfiles to the Nix system, and that last task alone will take some time.

Going back to my personal life again, I might try to find a job or at least an internship after I
start my classes (I actually need to do an internship to get my title, it's a university requirement
it looks like).

I think finding a job now can be very benefitial since I'm almost at the end of my degree and some
experience would be nice. As a plus I can get some extra cash since I'm always out of money and I would
like to buy some tools (for electronics) and maybe some anime figures or a Touhou fumo, I've actually
been planning on getting a Marisa for quite some time now and I think I can get one on the following
months, we'll see.
