---
layout: page
title: Lazy Monad!
tagline: Programming, distributed systems, functional stuff!
---
{% include JB/setup %}

<ul class="posts">
    {% for post in site.posts %}
        <li><span>{{ post.date | date_to_string }}</span> &#10147; <a href="{{ BASE_PATH }}{{ post.url }}">{{ post.title }}</a></li>
    {% endfor %}
</ul>
