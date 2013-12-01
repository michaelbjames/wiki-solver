var express = require('express');
var app = express();

app.get('/solve', function(req, res){
  res.send(200);
});