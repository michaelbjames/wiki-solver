"use strict";

var express = require('express'),
          _ = require('underscore'),
       request = require('request');

var app = express();

app.use('/solve', function(req, res, next){
  console.log(req.query);
  if(_.isUndefined(req.query.start)){
    return res.send(400, "Please specify a start address");
  }
  if(_.isUndefined(req.query.end)){
    return res.send(400, "Please specify an end");
  }
  next();
});

// en.wikipedia.org/wiki/XXXXX
// start = XXXXXXX1
// end   = XXXXXXX2
var wikibase = 'http://en.wikipedia.org/wiki/'

app.get('/solve', function(req, res){
  console.log(wikibase + req.query.start);
  request(wikibase + req.query.start, function(err, response, body){
    if (!err && response.statusCode == 200) {
      console.log(body)
    }
  });
  res.send(200);
});

app.listen(8080);