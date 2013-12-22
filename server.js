"use strict";

var express = require("express"),
          _ = require("underscore"),
    request = require("request"),
      jsdom = require("jsdom");

var app = express();

app.use("/solve", function(req, res, next){
  if(_.isUndefined(req.query.start)){
    return res.send(400, "Please specify a start address");
  }
  if(_.isUndefined(req.query.end)){
    return res.send(400, "Please specify an end");
  }
  next();
});

function dijkstra (start, end) {
  // body...
}

// en.wikipedia.org/wiki/XXXXX
// start = XXXXXXX1
// end   = XXXXXXX2
var wikibase = "http://en.wikipedia.org/wiki/";

app.get("/solve", function(req, res){
  // request(wikibase + req.query.start, function(err, response, body){
  //   if (!err && response.statusCode == 200) {
  //     console.log(body)
  //   }
  // });

  jsdom.env(
    wikibase + req.query.start,
    ["http://code.jquery.com/jquery.js"],
    function(err,window){
      window.$("#mw-content-text a").each(function(i){
        console.log((window.$("#mw-content-text a")[i]).href);
      });
    });

  res.send(200);
});

app.listen(8080);