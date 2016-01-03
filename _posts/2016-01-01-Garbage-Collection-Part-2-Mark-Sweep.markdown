---
layout: post
title: "Garbage Collection - Part 2 - Mark Sweep Collection"
date: 2016-01-01 20:14:00
category: "Language Runtimes"
tags: ["System Design", "Garbage Collection", "Memory Management", "Language Runtimes"]
---

## Disclaimer
This post provides an intentionally watered-down overview of *mark sweep* garbage collection algorithm and the tradeoffs involved around it. A lot of the gory implementation details aren't mentioned.

## Recap
At a high level, an _automatic memory management_ system has two key responsibilities:

1. Allocate space for new objects
2. Reclaim space from dead objects

The sole responsibility of a garbage collector is to reclaim the space used by every object that will no longer be used by any of the execution paths in the program. In order to achieve that, it needs to categorize all objects as either _dead_ or _alive_. As we mentioned in [part 1](http://lazymonad.com/language%20runtimes/2015/10/30/Garbage-Collection-Part-1/), most garbage collectors treat _reachability_ as _liveness_. An object is considered _dead_ if none of the program's execution paths can reach it. This post assumes that you've read [part 1](http://lazymonad.com/language%20runtimes/2015/10/30/Garbage-Collection-Part-1/) and are familiar with _mutator_ and _collector_ concepts.

# Categories Of Garbage Collection Algorithms


Most garbage collection schemes can be categorized as one of the four fundamental approaches :

* Mark Sweep Collection

* Mark Compact Collection

* Copying Collection

* Reference Counting

It is common for GC implementations to combine multiple approaches (e.g. reference counting supplemented by mark-sweep) to meet performance goals. In this post, we'll look into the details of *mark sweep* approach and its trade-offs.

## How and when is _GC_ invoked?
Before we jump into the details of *mark sweep*, let's quickly understand how/when a _GC_ is triggered.  Typically, language runtimes trigger _GC_ when they find that the heap is exhausted and there's no more memory
available to satisfy a memory allocation request by a mutator thread. Its something like:

{% highlight python linenos=table %}

def memory_allocator(n):
    # Allocate and return 'n' bytes on the heap.
    ref = allocate(n)
    if not ref:
        # Oops. We are out of memory. Invoke GC.
        gc()
        # Retry allocation
        ref = allocate(n)
        if not ref:
            # Let's give caller a chance to do something about it.
            # i.e. delete references, purge caches etc.
            raise OutOfMemory
    return ref
{% endhighlight %}


# Mark Sweep

_Mark Sweep_ algorithm is as simple as its name. It consists of a _mark_ phase that is followed up by a _sweep_
phase. During _mark_ phase, the collector walks over all the _roots_ (global variables, local variables, stack frames,
virtual and hardware registers etc.) and marks every object that it encounters by setting a bit somewhere in/around that object. And during the _sweep_ phase, it walks over the heap and reclaims memory from all the unmarked
objects.

The outline of the basic algorithm is given below in python pseudo-code. Here we assume that the _collector_ is single threaded but there could be multiple _mutators_. All _mutator_ threads
are stopped while the _collector_ runs. This stop-the-world approach seems suboptimal but it greatly simplifies the
implementation of _collector_ because _mutators_ can't change the state under it.


{% highlight python linenos=table %}

def gc():
    stop_all_mutators()
    mark_roots()
    sweep()
    resume_all_mutators()

def mark_roots():
    candidates = Stack()
    for field in Roots:
        if field != nil && not is_marked(field):
            set_marked(field)
            candidates.push(field)
            mark(candidates)

def mark(candidates):
    while not candidates.empty():
        ref = candidates.pop()
        for field in pointers(ref):
            if field != nil && not is_marked(field):
                set_marked(field)
                candidates.push(field)

def sweep():
    scan = start_of_heap()
    end = end_of_heap()
    while scan < end:
        if is_marked(scan):
            unset_marked(scan)
        else:
            free(scan)
        scan = next_object(scan)

def next_object(address):
    # Parse the heap and return the next object.
    ...

{% endhighlight %}

## Mark Phase
From the pseudo-code, it is clear that *mark sweep* doesn't directly identify _garbage_. Instead it identifies all the objects that are _not garbage_ i.e. _alive_ and then concludes that anything else must be _garbage_. Marking is a recursive process. Upon finding a live reference, we recurse into its child fields and so on and so forth. Recursive procedure call isn't a practical method for _marking_ because of time overhead and stack overflow potential. That's why we are using an explicit stack. This algorithm makes the space cost as well as the time overhead of the marking phase explicit. The maximum depth of the _candidates_ stack depends on the size of the longest path that has to be traced through the object graph. A theoratical worst case might be equal to the number of nodes on the heap, but most real world workloads tend to produce stacks that are comparatively shallow. Nonetheless a safe _GC_ implementation must handle such abnormal situations. In our implementation, we call _mark( )_ immediately after adding a new object to the _candidates_ mainly to keep the size of the stack under control. The predicament of marking is that _GC_ is needed precisely because of lack of available memory but auxiliary stacks require additional space. Large programs may cause _garbage collector_ itself to run out of space. One benefit of explicit stack is that an overflow can be detected easily and a recovery action can be triggered. Overflow can be detected in many ways. A simple solution is to use an inline check in each _push( )_. A slightly more efficient method would be to use a _guard page_ and trigger recovery after trapping the _guard violation_ exception. The tradeoffs of both approaches must be understood in the context of the underlying operating system and the hardware. In first approach, the _is-full_ test is likely to cost a couple of instructions (_test_ followed by a _branch_) but will be repeated every time we examine an object. Second approach requires trapping access violation exception that is generally expensive but will be infrequent.

## Sweep Phase
The implementation of _sweep( )_ is fairly straight-forward. It scans the heap in a linear fashion and frees any unmarked object. It does pose _parsability_ constraints on our heap layout. The implementation of *next_object(address)* must be able to return the next _object_ on the heap. Generally, it is sufficient for the heap to be parseable only in one direction. Most _GC_ enabled language runtimes tag an object's data with an object header. The header contains information like object's _metadata_ i.e. _type_, _size_, _hashcode_, _mark bits_, _sync block_ etc. Typically an object's header is placed immediately before an object's data. Thus object's _reference_ doesn't point to the first byte of the allocated heap cell, but into the middle of the cell, right after the object header. This facilitates upward parsing of the heap. A common implementation of _free(address)_ will fill the freed cell with a pre-determined _filler pattern_ that is recognized by the heap parsing logic.

# Issues And Tradeoffs

* **Cache Performance**: It is typical for most application's performance to be dominated by the utilization efficiency of hardware cache. These days the L1-L3 caches can be accessed in 2 to 10 CPU cycles and it takes upwards of 100 cycles to hit the RAM. Caches boost performance for applications that exhibit good _temporal_ and _spatial_ locality. A program exhibits  _temporal locality_ if it accesses a memory location that was recently accessed before. And a program shows high _spatial locality_ if it accesses adjacent memory locations in a scan-like fashion. Unfortunately, in _mark sweep_ algorithm, the _mark_ phase kind of sucks when it comes to _temporal_ and _spatial_ locality. In _mark( )_ we typically read and write an object's header only _once_ (assuming that most objects are popular and are referenced by only a single pointer). We read the _mark_ bit and if the object hasn't already been marked, its unlikely to be accessed again. Hardware prefetching (speculative or thorugh explicit prefetch instructions) isn't suitable for such wild pointer chasing. One common technique to improve cache performance is to put the _mark bits_ in a separate bitmap instead of making them part of object headers. The format, location and space needed for the bitmap depends on many factors like heap size, object alignment requirements, hardware cache sizes etc. These _marking bitmaps_ offer concrete performance advantage to the *mark sweep* algorithm. For example, _marking_ doesn't need to modify objects, multiple objects may be marked using a single instruction (bit whacking against a bitmap word). Since it modifies fewer words which means fewer dirty cache lines which implies less cache flushes. _Sweeping_ doesn't need to read any live objects and instead can fully rely on the bitmap for heap scan.
* **Speed**: The complexity of _mark phase_ is _O(L)_ where _L_ is the size of live objects reachable from all the roots. And the time complexity of _sweep phase_ is _O(H)_ where _H_ is the number of heap cells. It might be tempting to assume that _O(H)_ dominates _O(L)_ given that _H > L_, but in reality the sweep phase show great cache performance due to high spatial locality and the actual speed of the overall collection is dominated by the _O(L)_ due to all the cache unfriendly pointer chasing.

* **Space Overhead**: The *mark sweep* algorithm offers better space utilization compared to *reference counting* algorithms plus it can handle _cyclical structures_ cleanly without imposing any pointer manipulation overhead. *Marking* is an expensive operation and that's why its performed infrequently (only when absolutely required). Just like other _tracing_ algorithms, it requires some headroom on the heap for its operation. Furthermore, since *mark sweep* doesn't compact the heap, the system could suffer from higher internal fragmentation resulting in decreased heap utilization (especially for larger allocations).

* **Mutator Overhead**: *Mark sweep* puts almost no coordination overhead with _mutator_'s _read_ or _write_ operations.
  It's only interfacing with the _mutators_ is through the _object allocation_ routine and even there the overhead is
  minimal.

* **Allocator Overhead**: Generally, *mark sweep* systems do require complex _allocators_ that understand and support
  heap parsing and bitmap manipulation. Also, heap managers might have to introduce non-trivial implementation
  strategies to deal with internal fragmentation. On the other hand, not moving objects makes *mark sweep* a suitable
  candidate for use in non-cooperative environments where *language runtime* doesn't coordinate with _garbage
  collector_ (it can happen if the _GC_ was introduced as an after thought in the language design). Another advantage of
  *not moving* is that the object addresses don't change and there is no need to *patch* them after the *sweep* phase.

* **Invasiveness**: Like all *tracing* algorithms, *mark sweep* is invasive. The _collector_ interrupts the client
  program while all active objects are identified. These pauses could be substantial for some memory bound workloads.
  Typically the _GC_ frequency increases as the heap becomes fuller.

## Conclusion
This concludes a high level overview of mark sweep garbage collection approach. Mark sweep is a class of garbage
collection algorithms and each of them involves subtle tradeoffs. Some notable algorithms include:

* **Dijkstra's Tri-color Marking**: It is one of the most widely used algorithm in mark sweep category. It is particularly useful
for implementing increment and concurrent collectors. [Go Language (1.5)](https://blog.golang.org/go15gc) uses it.
* **Lazy Sweep and Prefetching**: There's a whole class of algorithms dedicated to improving GC performance using lazy
sweeping and prefetching. See [this](https://www.cs.purdue.edu/homes/hosking/ismm2000/papers/boehm.pdf), [this](http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.122.5048&rep=rep1&type=pdf),  and [this](http://users.cecs.anu.edu.au/~steveb/downloads/pdf/pf-ismm-2007.pdf) for details.
