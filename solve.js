var w = window.innerWidth, h = window.innerHeight;

var color = d3.scale.category10();

var nodes = [],
    links = [];

var force = d3.layout.force()
    .nodes(nodes)
    .links(links)
    .charge(-400)
    .linkDistance(120)
    .size([w, h])
    .on("tick", tick)
    .start();

var svg = d3.select("#d3container").append("svg:svg").attr("width", w).attr("height", h);

var node = svg.selectAll(".node"),
    link = svg.selectAll(".link");


function start() {
  link = link.data(force.links(), function(d) { return d.source.id + "-" + d.target.id; });
  link.enter().insert("line", ".node").attr("class", "link");
  link.exit().remove();

  node = node.data(force.nodes(), function(d) { return d.id;});
  node.enter().append("circle").attr("class", function(d) { return "node " + d.id; }).attr("r", 8);
  node.exit().remove();

  force.start();
}

function tick() {
  node.attr("cx", function(d) { return d.x; })
      .attr("cy", function(d) { return d.y; })

  link.attr("x1", function(d) { return d.source.x; })
      .attr("y1", function(d) { return d.source.y; })
      .attr("x2", function(d) { return d.target.x; })
      .attr("y2", function(d) { return d.target.y; });
}

// 1. Add three nodes and three links.
// setTimeout(function() {
//   var a = {id: "a"}, b = {id: "b"}, c = {id: "c"};
//   nodes.push(a, b, c);
//   links.push({source: a, target: b}, {source: a, target: c}, {source: b, target: c});
//   start();
// }, 0);

var reprocess = _.debounce(start,100);

function receive (event) {
  console.log(event.data);
  var msg = JSON.parse(event.data);
  switch(msg.type) {
    case "progress":
      if(_.isNull(msg.previous)){ //Weird first case
        nodes.push({id: msg.current});
      } else {
        if(!_.contains(nodes, msg.previous)){
          nodes.push({id: msg.previous});
        }
        nodes.push({id:msg.current});
        links.push({source: {id: msg.previous}, target: {id:msg.current}});
      }
      reprocess();
      break;
    case "solution":
      break;
  }
}

function submit () {
  $('#submit').remove();
  var start = $('#start').val(),
        end = $('#end').val(),
        url = "ws://localhost:4567/solve?start="+start+"&end="+end;

  var ws = new WebSocket(url);
  ws.onmessage = receive;
}
