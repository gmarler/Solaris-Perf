// Closure to create a private scope for the charting function.
var barcodeChart = function() {

  // Definition of the chart variables.
  var width = 600,
    height = 30,
    margin = {top: 5, right: 5, bottom: 5, left: 5 };

  // Charting function.
  function chart(selection) {
    selection.each(function (data) {
      // Bind the dataset to the svg selection.
      var div = d3.select(this),
          svg = div.selectAll('svg').data([data]);

      // SVG Initialization
      svg.enter().append('svg').call(svgInit);

      // Compute the horizontal scale.
      var xScale = d3.time.scale()
        .domain(d3.extent(data, function(d) { return d.date; }))
        .range([0, width - margin.left - margin.right]);

      // Select the chart group
      var g = svg.select('g.chart-content');

      // Bind the data to the bars selection.
      var bars = g.selectAll('line')
        .data(data, function(d) { return d.date; });

      // Append the bars on enter and set its attributes.
      bars.enter().append('line')
        .attr('x1', function(d) { return xScale(d.date); })
        .attr('x2', function(d) { return xScale(d.date); })
        .attr('y1', 0)
        .attr('y2', height - margin.top - margin.bottom)
        .attr('stroke', '#000')
        .attr('stroke-opacity', 0.5);
    });
  }

  // Initialize the SVG Element
  function svgInit(svg) {
    // Set the SVG size
    svg
      .attr('width', width)
      .attr('height', height);

    // Create and translate the container group
    var g = svg.append('g')
      .attr('class', 'chart-content')
      .attr('transform', 'translate(' + [margin.top, margin.left] + ')');

    // Add a background rectangle
    g.append('rect')
      .attr('width', width - margin.left - margin.right)
      .attr('height', height - margin.top - margin.bottom)
      .attr('fill', 'white');
  };

  // Accessor Methods
  // Width
  chart.width = function (value) {
    if (!arguments.length) {
      return width;
    }
    width = value;
    // Returns the chart to allow method chaining
    return chart;
  };

  // Height
  chart.height = function (value) {
    if (!arguments.length) {
      return height;
    }
    height = value;
    // Returns the chart to allow method chaining
    return chart;
  };

  // Margin
  chart.margin = function (value) {
    if (!arguments.length) {
      return margin;
    }
    margin = value;
    // Returns the chart to allow method chaining
    return chart;
  };

  return chart;
};

// The Dataset
var data = ['a', 'b', 'c'];

// Get the charting function.
var barcode = barcodeChart();

// Bind the data array with the data-item div selection, and call
// the barcode function on each div.
d3.select('#chart').selectAll('div.data-item')
    .data(data)
    .enter()
    .append('div')
    .attr('class', 'data-item')
    .call(barcode);