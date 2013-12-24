"use strict";

var express = require("express"),
          _ = require("underscore"),
    request = require("request"),
      jsdom = require("jsdom"),
       when = require("when");

var app = express();

// en.wikipedia.org/wiki/XXXXX
// start = XXXXXXX1
// end   = XXXXXXX2
var wikibase = "http://en.wikipedia.org/wiki/";
var wikiregex = new RegExp(wikibase);

app.use("/solve", function(req, res, next){
  if(_.isUndefined(req.query.start)){
    return res.send(400, "Please specify a start address");
  }
  if(_.isUndefined(req.query.end)){
    return res.send(400, "Please specify an end");
  }
  next();
});

function neighbors(article){
  var deferred = when.defer();
  // console.log(article);
  jsdom.env(
    wikibase + article,
    ["http://code.jquery.com/jquery.js"],
    function(err,window){
      deferred.resolve(
      _.map(
      _.filter(window.$("#mw-content-text a").map(function(i){
        return (window.$("#mw-content-text a")[i]).href;
      }),function(i){
        return wikiregex.test(i) &&
               !(/#.*$/).test(i);
      }),function(i){
        return i.split("wikipedia.org/wiki/")[1];
      }));
    });
  return deferred.promise;
}

function dijkstra (start, end) {
  var dist     = {},
      visited  = {},
      previous = {},
      q        = [],
      u        = "";

  dist[start] = 0;

  var neighborDist = function(vs){
    _.each(vs,function(v){
      if(_.isUndefined(dist[u])){dist[u] = 0;}
      if(_.isUndefined(dist[v])){dist[v] = 0;}
      var alt = dist[u] + 1;
      if(alt < dist[v]){
        dist[v] = alt;
        previous[v] = u;
        if(!visited[v]){
          q.push(v);
        }
      }
    });
  };

  q.push(start);

  while(q.length > 0){
    u = q.pop();
    console.log("q.pop()= " + u);
    if(u === end){
      var seq = [];
      while(!_.isUndefined(previous[u])){
        seq.push(u);
        u = previous[u];
        return seq;
      }
    }
    visited[u] = true;
    neighbors(u).then(neighborDist);
  }
}

app.get("/solve", function(req, res){
  // request(wikibase + req.query.start, function(err, response, body){
  //   if (!err && response.statusCode == 200) {
  //     console.log(body)
  //   }
  // });

  console.log(dijkstra(req.query.start, req.query.end));
  res.send(200);
  // neighbors(req.query.start).then(function(thing){
    // console.log(thing);
    // res.send(200);
  // });
});

app.listen(8080);