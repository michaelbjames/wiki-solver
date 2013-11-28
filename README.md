wiki-game
=========

Find the shortest path between two wikipedia pages

Strategy
--------

Due to the [Same origin policy](http://en.wikipedia.org/wiki/Same-origin_policy)
I cannot even use an iframe to traverse wikipedia to find a path connecting two nodes.
This policy further rules out using JS to make queries to wikipedia.

Instead, I'll have to have a server do much of the work for me.
So the plan is to have a node backend that makes lots of requests to wikipedia
to find the shortest path between two nodes. And I'll need to have a basic
frontend to show the work done.
