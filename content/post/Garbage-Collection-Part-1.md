---
title: "Garbage Collection - Part 1"
date: 2015-10-30 11:58:00
category: "Language Runtimes"
tags: ["System Design", "Garbage Collection", "Memory Management", "Language Runtimes"]
---

## TL;DR
Stop reading if you've a computer with infinite memory.

In this series of blog posts, I'll go over some well known _garbage collection_ techniques and analyze the tradeoffs involved from the system design perspective. All the ideas are taken from existing literature and I am not making any claims of original work. Garbage collection is a subject that is very close to my heart, and by writing about it I hope to improve my own understanding of modern language runtimes.

In this post we'll go over a brief overview of the _explicit_ vs _automatic_ memory management approaches. Then we'll establish the terminology that'll serve as the basis of deeper dive into _garbage collection_ algorithms and techniques as discuseed in future blog posts. I know it sounds boring, but just hang in there and I promise we'll get to the fun stuff in the next post.

* [Memory Management](#memory-management)
  * [Explicit Memory Management](#explicit-memory-management)
  * [Automatic Memory Management](#automatic-memory-management)
    * [Basics Of Automatic Memory Management](#basics-of-automatic-memory-management)
      * [Dynamic Memory Allocation](#dynamic-memory-allocation)
      * [Garbage Collector](#garbage-collector)
          * [Mutator](#mutator)
          * [Collector](#collector)
  * [Desirable Properties Of Garbage Collection Algorithms] (#desirable-properties-of-garbage-collection-algorithms)

# Memory Management

Computer memory is a finite resource. Historically, for any reasonably large software system, memory management was typically one of the leading concerns of its designers. They had the momentous task of picking one of the following options:

1. [Explicit memory management] (#explicit-memory-management)
2. [Automatic memory management] (#automatic-memory-management)

Let's briefly look at the pros and cons of both approaches.

## Explicit Memory Management

_Explicit memory management_ requires programmers to manually _free/delete_ the dynamically allocated memory. Languages, like C/C++, offer almost complete control (even address alignment at times) over the object's lifecycle. For large systems, it requires _strict_ programming discipline to ensure the long term correctness and reliability of the programs. Some common coding pitfalls include:

* Dangling pointers due to releasing a live object
* Memory corruption due to double _free_
* Memory leaks due to forgetting to release memory
* Higher coupling between components due to modeling of ownership semantics in API signatures

There are many established patterns to avoid these pitfalls, but pretty much everything boils down to maintaining strict coding discipline that requires consistently using the correct memory management strategy. This becomes tricky for large programs where third party dependencies/libraries might force a mix of multiple approaches. Memory issues are arguably among the hardest class of bugs to investigate. For example, in case of _dangling pointers_ or _double free_, the best outcome is the immediate crash of the program but typically it doesn't happen and the program continues to run exhibiting unpredictable behavior. Hence the saying, _to err is human - to blame it on a computer is even more so._

In this day and age, the biggest problem with the option of _explicit memory management_ is that it _**exists**_.

# Automatic Memory Management

_Automatic memory management_ is an essential feature of all modern programming languages. It relieves the programmer from the burden of memory management by presenting an illusion of infinite memory. For example, the following java program will never run out of memory even when run with no optimizations (*-Djava.compiler=NONE*)

```java
import java.util.UUID;

public class A {
    public static void main(String []args) {
        while (true) {
            System.out.println(new String(UUID.randomUUID().toString()));
        }
    }
}
```

Other pros include:

* No dangling pointers.
* No double frees
* Simpler code
* Faster development cycle

_Simpler code_ is the key win with _automatic memory management_. In _garbage collected_ languages, the code is more readable and easier to reason about.


Having said that, _automatic memory management_ isn't the silver-bullet. It doesn't guarantee absence of memory leaks (more on that later). It introduces space/time tradeoffs with subtle impacts on a program's runtime. Let's start with basics before getting into subtleties.

## Basics Of Automatic Memory Management

An _automatic memory management_ system typically comprises of two _almost_ independent parts:

1. Dynamic memory allocation
2. Garbage collection

### Dynamic Memory Allocation
Dynamic memory allocation involves a _heap_ that serves as a pool of memory that backs all the allocated objects. Heap allocation allows the programmers to allocate objects of variable sizes and then freely pass them around beyond current execution context. All heap allocated objects are accessed through _references_. A _reference_ typically points to one of the following:

* Address of the allocated object's memory on the heap.
* A _handle_ that in-turn contains the object's memory address on the heap

_Handles_ offer the advantage of allowing an object to be re-allocated easily by updating the handle's value as opposed to updating all the object's references.

Heap offers APIs to _allocate_ and _deallocate_ the objects. We'll refer to this heap interface as _allocator_.

## Garbage Collector

_Garbage collector_ is the magic component that makes the illusion of _infinite memory_ possible. It typically consists of two semi-independent components known as _mutator_ and _collector_.

### Mutator

Typically, all components of a language runtime that are responsible for executing application code, allocating/de-allocating new objects, and managing execution contexts get categorized as the _mutators_. Most reasonably large programs have more than one _mutator_ threads. Exact number of _mutator_ threads is generally irrelevant to the garbage collection approaches.

### Collector

The _collector_ actually executes the garbage collection code. It discovers the _garbage_ (read: unreachable) objects and reclaims their storage. In concurrent GCs, there may be more than one _collector_ threads. Exact number of _collectors_ is mostly irrelevant to the approaches that we are going to discuss. Most GCs, offer control over the behavior of _collectors_ through configuration settings (more on that later).

The _collector_ is correct _**only**_ if it never reclaims _live_ objects. Theoretically, determining _liveness_ of an object might not even be possible (e.g. in systems supporting hot patching) even if we've the time to _scan the world_. So, most _garbage collectors_ cheat a bit and treat _reachability_ as _liveness_. An object is considered _reachable_ if a _mutator_ can reach it by following direct or indirect references of the objects in its execution contexts (local/global variables, stack frames, virtual/physical CPU registers, thread local storage, heap references etc.).

## Desirable Properties of Garbage Collection Algorithms

Just like distributed systems, designing a _garbage collection_ mechanism is an exercise in balancing tradeoffs. Some of the desirable properties of _garbage collectors_ are:

* **Correctness** - A GC must be _correct_ and _safe_. It must never reclaim _live_ objects. The safety typically comes at the cost of performance or efficiency. There are cases where a GCs performance can be improved by feeding it hints from compiler and other runtime systems. More on that later.
* **Performance** - Overall time spent by a GC should be as short as possible. Typically a GC's performance is measured in two dimensions - latency and throughput. Both significantly depend on the implementation, workload and runtime environment. GCs are by nature intrusive. They introduce pauses by stopping all _mutators_ while performing garbage accounting. It is clearly desirable for these pauses to be as short and as infrequent as possible. In some systems (i.e. distributed lease/transaction coordinators etc.), long pauses could trigger failures resulting in system downtime. Having said that, measuring _pause time_ alone isn't particularly useful in itself. A GC that has no pauses and not _garbage reclaiming throughput_ wouldn't be very useful. Ideally, a GC should reclaim _all_ the garbage in the heap. However, this isn't always possible or even desirable (say for large heaps). For performance reasons, it may be desirable not to collect the whole heap at every _collector cycle_. Generational garbage collectors (used in Java/.NET etc.) segregate objects by their age into two or more regions called _generations_. By concentrating effort on the youngest generation, generational collectors can both improve total collection time and reduce the average _pause time_ for individual collections. More on that later.
* **Space Overhead** - The goal of _automatic memory management_ is the safe and efficient use of space. Memory managers, both _explicit_ and _automatic_, impose space overheads on the system. Some GCs may impose per-object space overhead (e.g. reference counts); others may be able to piggy back on an object's existing layout (e.g, a dirty bit). _Collectors_ also have space overhead as they are actually doing the garbage accounting. The standard space-vs-time tradeoff applies to all algorithms and GCs are no exception.

GC algorithms are complex and juggle way too many tradeoffs. There are cases where programming language semantics can aid a GC's performance. For example, functional languages like ML/Scala, distinguish mutable data from immutable - and GC implementations can leverage this information to improve performance. In the next post, we'll go over the four broad categories of GC algorithms and do a deep dive into one of them. Stay tuned.