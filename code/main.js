

var width = window.innerWidth,
    height = window.innerHeight;

var scale = .6,//scale, zoomWidth, zoomHeight are explicitly defined from the beginning to set an intiial zoom
    zoomWidth = (width-scale*width)/2,
    zoomHeight = (height-scale*height)/2,
    displaylower = .8,
    displayhigher = 1.5;

var svg = d3.select("body").append("svg")
    .attr("width", width)
    .attr("height", height),
    bgd = svg.append("rect")
    .attr("class", "bgd")
    .attr("width", "100%")
    .attr("height", "100%")
    .attr("fill", "#F7F7F7"),
    zoom_handler = d3.zoom()
        .on("zoom", zoom_actions);

var opacityScale = d3.scaleLinear()
    .domain([displaylower, displayhigher])
    .range([0, 1]),
    fsizeScale = d3.scaleLinear()
        .domain([0, 25])
        .range([3, 10]),
    color = d3.scaleOrdinal(d3.schemeCategory10);

var node2neighbors = {},
    tip,
    updatedData,
    ontickData,
    mouseoverText,
    namesSwitch = false;



var g = svg.append("g")
    .attr("class", "everything"),
   link = g.append("g")
        .attr("class", "links")
        .selectAll(".link")
        .append("g"),
    node = g.append("g")
      .attr("class","nodes")
      .selectAll(".node")
      .append("g");

zoom_handler.scaleTo(svg, scale);

//using html for the title/subtitle alignment

function showInfo() {
  d3.selectAll(".titles").remove();
  var titles = d3.select("body").append("div")
    .attr("class", "titles")
    .style("left", 0)
    .style("bottom", 0);

  titles.append("div")
    .html("Exploring Korean music: a map")
    .attr("class", "title");

  titles.append("div")
    .html(`Each circle represents one musician. Circles attract each other based on how many collaborations they have together.
    <br> Color represents genre (blue being K-r&b, orange K-hiphop, green K-pop, and red K-indie). Size represents popularity relative to the genre.
    <br> Scroll to zoom. Click on circles to reveal collaborations between artists and basic artist info.`);
  titles.append("div")
    .attr("display", "inline-block")
    .html(`<a  href = 'https://nathankim.name/portfolio/general/9_nongeographic/'>Click me to read more.</a>
          <button onclick='hideInfo()'>Click me to hide info.</button>`);
}
showInfo();

function hideInfo() {
  d3.selectAll(".titles").remove();
  d3.select("body").append("div")
    .attr("class", "titles")
    .style("left", 0)
    .style("bottom", 0)
    .append("div")
    .html("<button onclick='showInfo()'>Click me to show info.</button>")
}

var simulation = d3.forceSimulation()
  .force("link", d3.forceLink().id(function(d){ return d.value;})
                               .strength(.8))

/*
        .force("link",
          d3.forceLink()
            .id(function(d) { return d.value; })
            .strength(function(link) {
              if (link.source.group == link.target.group) {
                return 0.6;
                }	else {
                return 0.2;
                }
            })
          )
  */
        .force("charge", d3.forceManyBody().strength(-300))
        .force("forceX", d3.forceX(width/2).strength(.1))
        .force("forceY", d3.forceY(height/2).strength(.1))
        //.force("forceX", d3.forceX(width/2).strength(function(d){ return hasLinks(d, data.links) ? .7 : .3; }))
	      //.force("forceY", d3.forceY(height/2).strength(function(d){ return hasLinks(d, data.links) ? .7 : .3; }))
        .force("center", d3.forceCenter(width / 2, height / 2))
        .velocityDecay(.8)
        .alphaDecay(.001);



d3.json("../data/assembled.json", function(data) {

  d3.select('.loader').remove()

// the nodes really need no adjustment for the most part, so I'm putting them in the d3.json(...) section so that the code to set them up only runs connected
// links need constant adjustment, i.e. they're not generated at all to begin with and are made only through clicking, so they go int the update(); section
  node = node
    .data(data.nodes)
    .enter().append("g")
    .attr("class", "node");

  node.append("circle")
      .attr("r", function(d) { return Math.max(d.popularity, 2);})
      .attr("fill", function(d) { return color(d.group); })
      .attr("stroke", function(d) { return color(d.group); })
      .call(d3.drag()
          .on("start", dragstarted)
          .on("drag", dragged)
          .on("end", dragended));

node.on("mouseover", function(d,i){
    d3.select(this).select("circle").transition()
      .duration(200)
      .attr("r", function(d){
        return(3 + Math.max(d.popularity, 2)); })
      .style("fill-opacity", 1);

  mouseoverText = d3.select(this).select("text")
  if(mouseoverText.size() == 0){
    d3.select(this).append("text")
        .text(function(d) { return d.artist_name; })
        .attr("x", function(d) { return d.x + d.popularity + 2; })
        .attr("y", function(d) { return d.y; })
        .attr("font-size", function(d){ return fsizeScale(d.popularity); }) //make labels larger for more popular artists
        .attr("opacity", 0);
    mouseoverText = d3.select(this).select("text")
  }
  mouseoverText
      .transition()
      .attr("font-size", function(d){return 10 + fsizeScale(d.popularity) })
      .attr("opacity", 1);
});

node.on("mouseout", function(d,i){
    d3.select(this).select("circle").transition()
      .duration(200)
      .attr("r", function(d){ return(Math.max(d.popularity, 2)); })
      .style("opacity", )
      .style("fill-opacity", .7);
      //on mouseout put them back to what the current zoom level demands
    if(scale > displaylower){
      mouseoverText.transition()
      .duration(200)
      .attr("font-size", function(d){ return fsizeScale(d.popularity); }) //make labels larger for more popular artists
      .attr("opacity", function(d){return opacityScale(scale)});
    } else {
      mouseoverText.transition()
        .duration(200)
        .attr("opacity", 0)
        .remove();
    }

});

  // index of nodes and labels -- used to show neighbors upon click later on
  /*
  for (var i =0; i < data.nodes.length; i++){
    var id = data.nodes[i].value;
    node2neighbors[id] = data.links.filter(function(d){
        return d.source == id || d.target == id;
      }).map(function(d){
        return d.source == id ? d.target : d.source;
      });
  }
*/
  updatedData = data;

  node.on("click", nodeClick);

  bgd.on("click", function(){
    d3.selectAll(".tip").remove();
    d3.selectAll("line")
      .transition()
      .duration(200)
      .style("opacity", 0)
      .remove();

  node.each(function(d){
    d.active = false;
  })
})

// alphaDecay = .001
  simulation
      .nodes(data.nodes)
      .on("tick", ticked);

  simulation.force("link")
      .links(data.links);

  zoom_handler(svg);

});








// FUNCTIONS:
// ticked -- updating positions of lines, nodes, text
// nodeClick -- when a node is clicked, generate the popup and associated links
// dragstarted, dragged, dragended -- functions for enabling dragging of nodes; starting a drag turns off any tips
// zoom_actions -- just zooming in and out
function ticked(){

// update nodes:
    node.selectAll("circle")
        .attr("cx", function(d) { return d.x; })
        .attr("cy", function(d) { return d.y; });

    node.selectAll("text")
        .attr("x", function(d) { return d.x + d.popularity + 2; })
        .attr("y", function(d) { return d.y; });


    ontickData = link.data();
    for(var i=0; i< ontickData.length; i++){
        ontickData[i].newcoords = calc_coords(ontickData[i]);
      }

    link = link.data(ontickData)
    link.selectAll("line")
      .attr("x1", function(d) { return d.newcoords[0]; })
      .attr("y1", function(d) { return d.newcoords[1]; })
      .attr("x2", function(d) { return d.newcoords[2]; })
      .attr("y2", function(d) { return d.newcoords[3]; });
/*

      d3.selectAll("line")
        .attr("x1", function(d) { return d.source.x; })
        .attr("y1", function(d) { return d.source.y; })
        .attr("x2", function(d) { return d.target.x; })
        .attr("y2", function(d) { return d.target.y; });
*/
}

function nodeClick(n){
       // Determine if current node's neighbors and their links are visible
     var active   = n.active ? false : true // toggle whether node is active
     , newOpacity = active ? 1 : 0;
    // Extract node's name and the names of its neighbors
    var id     = n.value;

// make connected links visible -- if a link is connected to the clicked node, it'll have
// the node's name somewhere in its id attribute. Select that and make it visible
// make a popup showing artist info and hide it if the node was active before the click
      if(active){

        d3.selectAll(".tip").remove();
        d3.selectAll("line").remove();
        //apparently you can't append divs to svgs because divs aren't svg elements
        tip =  d3.select('body').append("div")
            .attr("class", "tip")
            .attr("transform", "translate(" + n.x  + "," + n.y + ")")
            .style("opacity", 0)
            .style("left", (d3.event.pageX) + "px")
            .style("top", (d3.event.pageY - 28) + "px")	;

        tip.append("div")
          .append("img")
          .attr('width', 100)
          .attr('height', 100)
          .attr("src", n.image_url)
        //append a subcontainer inside which text can be aligned as spans, next to the image div.
        // There must be a better way to align text but I don't know it lmao
        var tipInfo = tip.append("div").attr("class", "artistInfo");

        tipInfo.append("span")
          .html("<b>" + n.artist_name + "</b></a>").style("font-size", "24px");
          //.html("<a href=" + n.external_urls_spotify + "><b>" + n.artist_name + "</b></a>").style("font-size", "24px");
        tipInfo.append("span").text(n.followers_total + " followers");
        tipInfo.append("span").html("Most recent release: <i>" + n.album_name + "</i> (" + n.album_date + ")");
        tipInfo.append("span").text("Partnered with " + n.collab_artists + " artists so far");

        tip
          .transition()
          .duration(200)
          .style("opacity", 1)

//This section generates links connected to the clicked node
        var neighbors = id;
        filteredData = updatedData.links.filter(function(d){
          return neighbors.includes(d.source.value) || neighbors.includes(d.target.value);
        })
        for(var i=0; i< filteredData.length; i++){
          filteredData[i].newcoords = calc_coords(filteredData[i]);
        }

        link = link.exit().data(filteredData).enter()
        link.append("line")
            .attr("x1", function(d) { return d.newcoords[0]; })
            .attr("y1", function(d) { return d.newcoords[1]; })
            .attr("x2", function(d) { return d.newcoords[2]; })
            .attr("y2", function(d) { return d.newcoords[3]; })
            .attr("stroke-width", 1)
            .style("opacity", 0)
            .transition()
            .duration(200)
            .style("opacity", 1);
            //jsut for debugging
          } else {
        link.selectAll("line")
          .transition()
          .duration(200)
          .attr("opacity", 0)
          .remove();
        d3.selectAll(".tip").remove();
      }

    // Update whether or not the node is active
    n.active = active;
}

function dragstarted(d) {
  if (!d3.event.active) simulation.alphaTarget(0.3).restart();
  d3.event.sourceEvent.stopPropagation();
  d3.selectAll(".tip").remove();
  d.fx = d.x;
  d.fy = d.y;
}

function dragged(d) {
  d.fx = d3.event.x;
  d.fy = d3.event.y;
}

function dragended(d) {
  if (!d3.event.active) simulation.alphaTarget(0);
  d.fx = null;
  d.fy = null;
}

function zoom_actions(){
    g.attr("transform", d3.event.transform)

    // only render text labels when zoom passes a certain level. Otherwise delete them entirely (don't just change opacity to 0).
    // If the zoom is past a certain level
    scale = d3.event.transform.k; //so we can refer to the zoom level on the mouseover event
    if (d3.event.transform.k > displaylower & !namesSwitch) {
      namesSwitch = true;
      node.append("text")
          .text(function(d) { return d.artist_name; })
          .attr("x", function(d) { return d.x + d.popularity + 2; })
          .attr("y", function(d) { return d.y; })
          .attr("font-size", function(d){ return fsizeScale(d.popularity); }) //make labels larger for more popular artists
          .attr("opacity", function(d){return opacityScale(d3.event.transform.k)});
    } else if(d3.event.transform.k > displaylower){
      node.selectAll("text")
      .attr("opacity", function(d){return opacityScale(d3.event.transform.k)});
    } else if(d3.event.transform.k < displaylower){
      namesSwitch = false;
      d3.selectAll(".tip").remove();
      d3.selectAll("text").remove();
    }


}

function calc_coords(d){
      x1 = d.source.x;
      y1 = d.source.y;
      x2 = d.target.x;
      y2 = d.target.y;
      r1 = Math.max(d.source.popularity, 2);
      r2 = Math.max(d.target.popularity, 2);

      dX = x2 - x1;
      dY = y2 - y1;
      hyp = Math.sqrt((dX * dX) + (dY * dY));

      x1 = x1 + (dX * (r1 / hyp));
      x2 = x2 - (dX * (r2 / hyp));
      y1 = y1 + (dY * (r1 / hyp));
      y2 = y2 - (dY * (r2 / hyp));
      return [x1, y1, x2,y2];
}

function hasLinks(d, links) {
    var isLinked = false;

	links.forEach(function(l) {
		if (l.source.id == d.id) {
			isLinked = true;
		}
	})
	return isLinked;
}
