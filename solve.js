var w = 1024, h = 400;
var duration = 750;
var WIKIBASE = "http://en.wikipedia.org/wiki/";
var tree = d3.layout.tree()
                    .size([w,h]);

var root = {},
   nodes = tree(root);

root.parent = root;
root.px = root.x;
root.py = root.y;

var diagonal = d3.svg.diagonal();

var svg = d3.select("#d3container").append("svg")
    .attr("width", w)
    .attr("height", h)
    .append("g");
    // .attr("transform", "translate(10,10)");

var node = svg.selectAll(".node"),
    link = svg.selectAll(".link");

function indexOf(list, key, value){
  for (var i = 0; i < list.length; i++) {
    if(list[i][key] == value){
      return i;
    }
  }
  return -1;
}

function receive (event) {
  console.log(event.data);
  var msg = JSON.parse(event.data);
  switch(msg.type) {
    case "progress":
      var n = {id: msg.current},
          p = {id: msg.previous},
      index = indexOf(nodes, "id", msg.previous);
      if(index < 0){
        p.children = [n];
        nodes.push(p);
      } else {
        var pn = nodes[index];
        if (pn.children)
          pn.children.push(n);
        else
          pn.children = [n];
      }
      nodes.push(n);

    // Recompute the layout and data join.
    node = node.data(tree.nodes(root), function(d) { return d.id; });
    link = link.data(tree.links(nodes), function(d) { return d.source.id + "-" + d.target.id; });

    // Add entering nodes in the parent’s old position.
    node.enter().append("circle")
        .attr("class", "node")
        .attr("r", 4)
        .text(function(d){return d.id;})
        .attr("cx", function(d) { return d.parent.px; })
        .attr("cy", function(d) { return d.parent.py; });

    node.enter().append("a")
                .attr("xlink:href",function(d){return WIKIBASE + d.id;})
                .attr("target","_blank")
        .append("text")
        .attr("class", "node-text")
        .attr("x", function(d) { return d.parent.px;})
        .attr("y", function(d) { return d.parent.py;})
        .attr("dx", ".45em")
        .attr("dy", ".35em")
        .style("fill-opacity", 1)
        .attr("text-anchor", "start")
        .text(function(d) { return d.id; });

    // Add entering links in the parent’s old position.
    link.enter().insert("path", ".node")
        .attr("class", "link")
        .attr("d", function(d) {
          var o = {x: d.source.px, y: d.source.py};
          return diagonal({source: o, target: o});
        });

    // Transition nodes and links to their new positions.
    var t = svg.transition()
               .duration(duration);

    t.selectAll(".link")
              .attr("d", diagonal);

    t.selectAll(".node")
              .attr("cx", function(d) { return d.px = d.x; })
              .attr("cy", function(d) { return d.py = d.y; });

    t.selectAll(".node-text")
              .attr("x", function(d) { return d.px = d.x; })
              .attr("y", function(d) { return d.py = d.y; })
              .attr("transform", function(d){ return "rotate(-45," + d.x + "," + d.y+ ")";});

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
