---
layout: page
title: Lazy Monad!
tagline: Programming, distributed systems, functional stuff!
---
{% include JB/setup %}

<ul class="listing">
    {% for post in site.posts %}
        <li><span>{{ post.date | date_to_string }}</span> <a href="{{ BASE_PATH }}{{ post.url }}">{{ post.title }}</a></li>
    {% endfor %}
</ul>
