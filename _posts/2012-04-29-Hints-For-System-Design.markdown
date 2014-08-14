---
layout: post
title:  "Hints for System Design"
date:   2012-04-29 02:45:15
category: "System Design"
tags: ["Recommended Reading", "Distributed Systems", "System Design", "Butler W. Lampson"]
---

In 1983, [Butler Lampson](http://research.microsoft.com/en-us/um/people/blampson/) published a landmark paper about [Hints of Computer System Design](http://research.microsoft.com/en-us/um/people/blampson/33-Hints/Acrobat.pdf). As a practitioner and a student of distributed systems design, I find it immensely insightful and I habitually go back and re-read this paper every few months. In this post I'll try and summarize some of the learnings from this paper that I've gained over the years.

<hr/>

### Prerequisite
_Before jumping into system design, think hard about what is it that you are trying to accomplish? Have a clear idea about what your goals are?_

<hr/>

### Hints / Principles

Butler organizes his suggestions along two axis.
>1. *Why* - Why it helps in making a good system?
>2. *Where* - Where in the system design it helps?

<P ALIGN="CENTER"><CENTER><TABLE CELLSPACING=0 BORDER=0 CELLPADDING=7 WIDTH=648>
<TR><TD WIDTH="19%" VALIGN="TOP">
<P><B>Why?</B></TD>
<TD WIDTH="31%" VALIGN="TOP">
<I><P ALIGN="CENTER">Functionality</P>
</I><P>Does it work?</TD>
<TD WIDTH="25%" VALIGN="TOP">
<I><P ALIGN="CENTER">Speed</I> </P>
<P>Is it fast enough?</TD>
<TD WIDTH="25%" VALIGN="TOP">
<I><P ALIGN="CENTER">Fault-tolerance</P>
</I><P>Does it keep working?</TD>
</TR>
<TR><TD WIDTH="19%" VALIGN="TOP">
<B><P>Where?</B></TD>
<TD WIDTH="31%" VALIGN="TOP">
<P>&nbsp;</TD>
<TD WIDTH="25%" VALIGN="TOP">
<P>&nbsp;</TD>
<TD WIDTH="25%" VALIGN="TOP">
<P>&nbsp;</TD>
</TR>
<TR><TD WIDTH="19%" VALIGN="TOP">
<I><P>Completeness</I></TD>
<TD WIDTH="31%" VALIGN="TOP">
<P>Separate normal and <BR>
worst case</TD>
<TD WIDTH="25%" VALIGN="TOP">
<P>Shed load<BR>
End-to-end<BR>
Safety first</TD>
<TD WIDTH="25%" VALIGN="TOP">
<P><BR>
End-to-end</TD>
</TR>
<TR><TD WIDTH="19%" VALIGN="TOP">
<I><P>Interface</I></TD>
<TD WIDTH="31%" VALIGN="TOP">
<P>Do one thing well:<BR>
Don’t generalize<BR>
Get it right<BR>
Don’t hide power<BR>
Use procedure arguments<BR>
Leave it to the client<BR>
Keep basic interfaces stable<BR>
Keep a place to stand</TD>
<TD WIDTH="25%" VALIGN="TOP">
<P>Make it fast<BR>
Split resources&#9;<BR>
Static analysis<BR>
Dynamic translation</TD>
<TD WIDTH="25%" VALIGN="TOP">
<P>End-to-end<BR>
Log updates<BR>
Make actions atomic</TD>
</TR>
<TR><TD WIDTH="19%" VALIGN="TOP">
<I><P>Implementation</I></TD>
<TD WIDTH="31%" VALIGN="TOP">
<P>Plan to throw one away<BR>
Keep secrets<BR>
Use a good idea again<BR>
Divide and conquer</TD>
<TD WIDTH="25%" VALIGN="TOP">
<P>Cache answers <BR>
Use hints &#9; <BR>
Use brute force<BR>
Compute in background<BR>
Batch processing</TD>
<TD WIDTH="25%" VALIGN="TOP">
<P>Make actions atomic<BR>
Use hints</TD>
</TR>
</TABLE>
</CENTER></P>

<hr/>

### Key Takeaways ###

* Engineering is all about compromises. You may want your service to be _simple, dependable, scalable, efficient, gracefully degradable, fault tolerant and highly responsive_. All these are reasonable and very desirable goals but trying to achieve them all at once may not be possible. Choose your battles sensibly. Absence of clearly prioritized goals could lead to the temptation of trying to achieve all at once which most likely will result in a failure. Having said that, sometimes with a lot of effort you may be able to achieve all these goals but it would most definitely be a high cost enterprise.
* _Features, speed, cost, time to market, dependable, usable, adaptable_ etc. are examples of trade offs. Think which ones matter most for your service?
* Write a spec. Writing a spec is difficult because it forces you to think and _thinking_ is hard. For the very least, try and write down about the _abstract states_ and the _interfaces_ that deal with them. Writing gives clarity of mind as Guindon once said "writing is nature's way to showing you how fuzzy your thinking is ..." [Leslie Lamport](http://dpb.bitbucket.org/leslie-lamport-on-thinking-first-and-on-commenting-code-2007.html).
* Keep interfaces simple. An interface should capture the minimum essentials of an abstraction. Don't generalize; generalizations are generally wrong (no pun intended). When an interface undertakes too much, the result is an implementation which is large, slow, and complicated.
* Get it right. Neither abstraction nor simplicity is a substitute for getting it right.
* Make it fast, rather than general or powerful. It is much better to have basic operations executed quickly than more powerful ones which are slower (of course, a fast, powerful operation is best, if you know how to get it). The trouble with slow, powerful operations is that the client who doesn't want the power pays more for the basic function. Handle normal and worst case separately as a rule, because the requirements for the two are quite different: the normal case must be fast; the worst case must make some progress.
* The purpose of abstraction is to conceal undesirable properties; desirable ones should not be hidden.
* Use a good idea again, instead of generalizing it. A specialized implementation of the idea may be much more effective than a general one.
* Split resources in a fixed way if in doubt, rather than sharing them. It is usually faster to allocate dedicated resources, it is often faster to access them, and the behavior of the allocator is more predictable.
* When in doubt, use brute force. Especially as the cost of hardware declines, a straightforward, easily analyzed solution which requires a lot of special-purpose computing cycles is better than a complex, poorly characterized one which may work well if certain assumptions are satisfied. Doing things incrementally almost always costs more [... and] batch processing permits much simpler error recovery.
* Safety first. In allocating resources, strive to avoid disaster, rather than to attain the optimum.
* Shed load to control demand, rather than allowing the system to become overloaded. Apply back pressure.
* End-to-end error recovery is absolutely necessary for a reliable system, and any other error detection or recovery is not logically necessary, but is strictly for performance. Many uses of hints are applications of this idea. Log updates to record the truth about the state of an object.
* Make actions atomic or restartable. Make APIs idempotent.
* Try and keep your system simple enough so that you can still understand it. Keeping systems simple is hard and its often not rewarded. Overtime as the system evolves only abstractions and interfaces will save you.
* Time to market - keep it real. Learn what customers really want. Make it good enough and then iterate. Ship often and ship early. Good enough is good enough because many errors aren't fetal. For example, at least once guarantee is good enough; trying to provide at-most once guarantee may not be worth the effort.
* Many a time approximations are _good enough_.
* Make it efficient by reducing waste. Aim for efficient enough, not optimal. _Efficient_ has two different definitions; one by implementor and other by the client. Understand what is important for your service. In general, optimizations introduce complexity and search for optimality in distributed systems implementation is a bad idea.
* Predicting future is hard. Plan for success and change. Successful systems last a long time and eventually have to scale. If you want to plan for success; you better plan for scalability. Embrace uncertainty and develop incrementally.
* Failures are inevitable. Embrace them instead of avoiding them. Make failures cheap.
* Your system will evolve much more successfully if you design it to be extensible. Internet and HTML are examples of extensible systems. HTML processors drop unrecognized elements which allows for extensibility.
* Dependability has three aspects:
    - Reliable - Gives the right answer.
    - Available - Gives the answer promptly.
    - Secure - Works in spite of bad guys.
* Understand how much dependability is required by your system? In many cases, a dependable _undo_ option would be good enough and you may not need anything else.
* Use abstractions and interfaces and limit complexity by liberating parts from each other. Compose relations using indirect mappings. An example would be the network stack: Source route -> IP addr -> DNS name -> Service name  -> Query.
