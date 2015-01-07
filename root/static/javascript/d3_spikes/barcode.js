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

      // Create the svg element on enter, and append a
      // background rectangle to it.
      svg.enter()
        .append('svg')
        .attr('width', width)
        .attr('height', height)
        .append('rect')
        .attr('width', width)
        .attr('height', height)
        .attr('fill', 'white');
    });
  }

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