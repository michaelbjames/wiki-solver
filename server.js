"use strict";

var express = require('express'),
          _ = require('underscore');

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

app.get('/solve', function(req, res){
  res.send(200);
});

app.listen(8080);