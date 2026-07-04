+++
[BLOG_ENTRY]
title = "I can finally rest a little bit"
subtitle = ""
timestamp = 1783095026
slug = "1783095026-i-can-finally-rest-a-little-bit"
tags = ["update", "me", "meta", "programming"]
+++

I just got finished with doing my final exams for this semester, so now I can work on my projects
a little bit more.

## Decompiling Minecraft Beta
I had the idea to decompile and port a Minecraft version to a native language for quite some time
now. Some weeks ago I started playing around with
[RetroMCP](https://github.com/Memory-Fabricators/RetroMCP), a Minecraft Coder Pack fork with
support for older versions of the game, and decided to port the old Beta 1.7.3.

I always dreamt of being able to play the game on one of my shitty old computers, more
specifically on one of the first computers that I ever used which has an old Pentium 4 with 256MiB
of RAM. I don't know if I will be able to actually run the game at a decent framerate on that old
machine, but either way it is a fun project to do.

The decompiled Java sources are around ~55k lines of code (and a little bit more if you take into
account the multiplayer server JAR). So far I've ported around 11k lines of code to C++, but it
will probably not be a 1:1 ratio between both codebases, I expect to have to write a lot more C++
code before the game even starts. However, that chunk of code cost me just around two weeks of
work, and I've been translating it on a steady pace, so I think it will not take a lot of time
before I'm done with the initial porting.

```sh
~/d/nativebeta λ cloc . --vcs=git
     103 text files.
     101 unique files.
       2 files ignored.

github.com/AlDanial/cloc v 1.96  T=0.12 s (837.3 files/s, 118351.2 lines/s)
-------------------------------------------------------------------------------
Language                     files          blank        comment           code
-------------------------------------------------------------------------------
C++                             27           1093             45           5651
C/C++ Header                    71            885            256           5207
C                                1             49             24            981
YAML                             1              9              0             29
CMake                            1             11             10             26
-------------------------------------------------------------------------------
SUM:                           101           2047            335          11894
-------------------------------------------------------------------------------
```

The plan is to first port the game as is to a native executable (both the client and the server),
and then once I make sure everything works as it should I want to port it to other platforms (I'm
working on x86_64 linux at the moment). I plan to port to (at least) 32bit old windows (XP era) and
HOS (the Nintendo Switch OS).

Then after doing that I want to integrate some kind of modding API, I thought of using Lua
as the main scripting language like Luanti/Minetest. It might be fun to port some older mods to the
new API, I would love to have at least old IC2 running.

Btw, it's still a bit too early, but a huge thanks to the
[BetaSharp project](https://git.gay/betasharp-official/betasharp). Without them I don't think I
would be able to read most of the shitty old Minecraft code, since most variable names are not
actually deobfuscated when you use RetroMCP lmao.

## I got a fumo
I wanted to get a Touhou fumo for quite some time now, I think I mentioned it on one of my previous
posts. Well I finally got enough money last month to buy a Marisa, and she just arrived some days
ago. She's a bootleg but I like her a lot, I got her from the Fumo x Fumo store from AliExpress.
She has some minor imperfections on her, but she's still very very similar the official one.

I've also started trying to get into photography just for taking silly fumo photos. I now know
little bit about RAW image processing, and that helps me to squeeze more juice out of my
shitty phone camera. Here, take a look at some of the photos that I've taken:

![marisa1](%%DIR%%/mari1.jpg "She's being properly educated on the arts"){width=600, height=auto}

![marisa2](%%DIR%%/mari2.jpg "I'm also teaching her how to drive"){width=600, height=auto}

Expect more silly fumo photos in the future!

## The website
I'm planning on doing an update on the site soon. I've been experimenting with adding some kind of
microblog page (a la Twitter) for making smaller posts. I think I prefer that format for posting
updates like this more frequently, or for just posting photos or other media.

While I'm at it I also want to update other existing pages. I think the welcome page, the
about me section and the projects page need a small redesign. Also I have to add that RSS feed that
I've been procrastinating doing for quite some time now lel.
