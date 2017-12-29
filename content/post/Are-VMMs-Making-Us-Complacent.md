---
title:  "Are VMMs making us complacent?"
date:   2015-04-04 11:34:00
category: "Operating Systems"
tags: ["Rant", "Recommended Reading", "Operating Systems", "System Design", "Virtual Machines", "Microkernels", "VMMs"]
---

I recently came across an interesting [opinion paper](https://www.usenix.org/legacy/event/hotos05/final_papers/full_papers/hand/hand.pdf) that posits -- *modern VMMs are microkernels done right*. Its a bit dated but a good read nonetheless. I couldn't help but disagree with some parts of their claims. In all honesty, comparing VMMs to microkernels doesn't feel like an apples to apples comparison. I am summing up my thoughts for your instructive criticism.

## Avoid Liability Inversion

Their claim about microkernels having performance problems because of page evictions by user-space pagers is correct for the most part. But this problem will exists for VMMs as well if they start oversubscribing RAM. Modern day VMMs (read Xen) completely side step the problem by not oversubscribing RAM in the first place. In this regard, I believe, Xen is close to exokernels than microkernels. You could achieve simiilar isolation with an exokernel that also doesn't allow oversubscription of RAM across processes.

As a counter example -- for failure isolation -- consider that in a Xen system, all VMs are clients of Dom0. And if
a device driver misbehaves in Dom0, it can bring down all the VMs. While in case of microkernels only those processes
that are using that particular device will fail.

## IPC Performance

This claim is correct but it is another case of a cleverly chosen example. They mention several techniques that they use to speed up Xen's inter-VM communication performance. But there is no reason that the same techniques can't be applied for microkernels as well.

As for the other assertion that VMs reduce the need for IPC; it may be true to a certain extent, but in practice one of the two things happen: Either the IPC is replaced by more expensive things like full-blown TCP (e.g. file server and application server running on different VMs on the same box) or you end up implementing special hardware support just to address the sucky IPC perf in VMMs. SR-IOV hardware is realized to solve this exact problem.

One other aspect is the overall resource efficiency. For the most part, VMMs are pretty inefficient in terms of resource usage. For example, let's just consider the memory requirements. In a VMM, each VM is running a full-blown OS with several hundred megabytes (if not GBs) of memory overhead each, and even though a lot of it is really just different copies of the same thing, there is no sharing i.e. through copy-on-write. Isn't it a grossly missed opportunity?

One of the major benefits of VMMs is that you can run existing operating systems and on top you can run all your existing application. But unless you really want bad perf, you can't actually run existing OS unmodified. You've to enlighten them to get even remotely decent perf. Having said that, the changes required to enlighten a guest for a VMM are a lot less than to emulate it on top of an exokernel and even more so on top of a microkernel.

After guest enlightenment and hardware support, I agree that the overall perf overhead of Xen is small but only in case of CPU. IO perf is still relatively bad with VMs.

## Conclusion

Back in Azure, when I was working on implementing the web/worker roles, we decided to run each individual role instance inside a [separate VM](https://patents.justia.com/patent/8621553). A role instance was essentially a single process -- we were running IIS in-process in hostable webcore mode --  and the real reason to allocate a separate VM was to address the limitations of the underlying OS especially towards IO quota management and isolation. And I feel this has been the story of VMMs for past 30 years or so. We use them to hide away the limitations of underlying operating systems because it appears hard to provide true isolation at kernel level. For example, back in 90s when huge SMP systems started appearing for the first time, OSes weren't good with scaling and VMMs were used to run multiple OS instances to take advantage of all those CPUs. Today, OSes have become good enough that they can manage themselves and now we are using VMMs to cover up their limitations towards multi-tenancy. I would love to see current OSes improve in terms of providing better resource isolation at kernel level and also providing better QoS guarantees for IO to its processes. Given that ring 1-2 are completely underutilized on most intel based systems, I feel our ever increasing reliance on VMMs is sub-optimal. Something that industry could change.

I am not saying that achieving true kernel level isolation is easy. All that I am saying is that, hey there's quite a bit of room for improvement in current OSes and VMMs are making us complacent!
