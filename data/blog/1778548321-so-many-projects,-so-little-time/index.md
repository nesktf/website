+++
[BLOG_ENTRY]
title = "So many projects, so little time"
subtitle = ""
timestamp = 1778548321
slug = "1778548321-so-many-projects,-so-little-time"
tags = ["update", "me"]
+++

This last month I've been quite busy doing lots of random things, some of them i'm still busy with.
So I thought I could share them now to take them off my mind for a bit.

## 3D graphics
I started properly learning how to use Vulkan, I've been following the guide at
[vkguide.dev](https://vkguide.dev/) and it has been quite a fun experience so far. I had some
leftover initialization code from like a year ago when I was instead following the older
[vulkan guide](https://vulkan-tutorial.com/), so the start went pretty smoothly I would say.

So far I've been able to create a Vulkan context that shows a spinning Quad with a background that
uses some shader effects from a compute pipeline using some user input from Dear ImGui. It's more
or less exactly what the guide makes you do but with some changes on the code to follow my needs
and tastes, things like making a C wrapper over the code to define a clear API boundary and using
a more functional style in the code.

![vulkan_demo](https://files.catbox.moe/gsetcc.mp4 "Basic Vulkan demo"){width=600 height=auto}

My first idea was to add Vulkan support to my crappy 3D graphics framework, but after putting some
thought into it I decided to just use Vulkan directly on the project that I have currently as a
sort of playground for 3D things, I think it will be both faster and more fun that way.

I also realized that I've wasted a lot of time on making a library that I cannot really use to make 
something useful in practice, so thats another reason to go fresh and move to Vulkan. For now I
will let that project aside, maybe I will return to it some day when I'm a more experienced
developer.

After I get some basic abstractions for rendering things again I will start to port all the older
code for animations and such to the new rendering pipeline, then I want to do some fun stuff like
physics simulations and things like that. I've watched a
[very interesting video](https://youtu.be/MrIAw980iYg) about vehicle simulations like almost a year
ago and ever since that day I wanted to do something fun like that for a game, so I might start
to work on that too.

## Funny gifs
On the last post I mentioned that I wanted to make a local [picmix](https://www.picmix.com/) clone
form making funny gifs to share with other people. Well, I finally started doing something with
that, it took quite some time to get over my lazyness and start with it.

Since I'm a sucker for lower level languages my first idea was to make it using C++ with OpenGL
and using my graphics framework and yada yada yada. But the thing with that is that it would take
a lot of time for making what it's really a simpleish program, it doesn't make any practical sense
to do something like that. Some would say that is like trying to use a fucking nuclear bomb to
dig a hole instead of using a shovel like normal people would do.

So I just went with a simple Python application using Qt, it has been a while since I used
something like that to make software so I thought it would be fun. And sure enough it was, in just
two days I made a silly little window with some basic controls to add gifs to a canvas.

![keikimix_demo](https://files.catbox.moe/v2tkof.mp4 "Keikimix demo"){width=600 height=auto}

I don't even remember when was the last time I wasn't worrying about random bullshit like
ownership, memory allocations and other low level quirks just to make a fun application. It was
like a breath of fresh air.

At first I was kind of worried about speed and about being efficient, but I realized is just a
stupid program for making silly gifs, who cares if it takes an extra 10ms to add an image. Even if
eventually I hit a cap on what Python can do with this I can just port the program to C++ since its
just using Qt, but even that it's very unlikely I think. In the worst case scenario at least it
will be more performant than a shitty web app lmao.

## University
I started working on my thesis, at least the more introductory boring parts that I need to deliver
at the very start, like paperwork and such.

I got some new ideas that I think would make it more fun. The main idea was to make a system for
remotely controlling an electric vehicle with some sensors to check the state of the vehicle every
so often (I think that with just that main objective in mind I can deliver something good, but I
still thought that I was missing something).

I had the vague idea of including some kind of autopilot mode to the vehicle, one would put a
series of checkpoints in a map and the vehicle would try to navigate around to get to those
checkpoints. I didn't know exactly how to do that, the vehicle would move inside a road most of the
time and I can't just use some kind of sensor that follows a line like those small cars from
Arduino projects.

But then I got the idea to use some kind of image recognition system that can help the car find its
way on the road, I've never user this kind of system before so I thought it could be exciting. I
recently dusted off my Nintendo Switch and installed Fedora on it; I investigated a bit and I
think that I can use CUDA to meet my needs with this project, I just need to get a webcam from
somewhere and do some tests with that.

![chiruno_switch](%%DIR%%/chiruno_switch.jpg "Cirno helped me install Fedora"){width=600 height=auto}

I still don't know if this will be a viable thing to add to my project, but if it can be done I
will absolutely do it. In the worst case scenario I will just present my original idea and that
will be enough I'm sure.

## Other things
I kind of started looking for a job, I sent some CVs to some job offerings that I found just to
see if anybody would call me (so far nobody did lmao). I still feel kind of lazy about finding
a job but I think it's something that I will have to do in the near future since i'm broke at the
moment. I feel like if I actually put effort on searching I will eventually find something good,
but I'm still feeling lazy.

I have so many things that I want to do but I don't feel like i have the time. I want to
do my programming projects, I want to finish my studies as soon as possible, I want to get a Job,
I want to start new hobbies like drawing or 3D modelling. There are so many fun and fascinating
things that I want to get into but don't have the time or the will to start just yet.

Still, there is a whole lifetime ahead to try all of these things so I am sure that, eventually, I
will acomplish my desires in some way of another. It's just that for the time being I feel a little
frustrated for not being able to do that, but that is life I guess.

Anyways, I also want to do an update on this website eventually, but like I just said I have lots
of things in my agenda so it might take a while. If there is anybody that actually reads the things
that I write and endures my crappy english writting skills, I thank you a lot for that! I will keep
on doing it.

