// Closure to create a private scope for the charting function.
var barcodeChart = function() {

    // Definition of the chart variables.
    var width = 600,
        height = 30;

    // Charting function.
    function chart(selection) {
        selection.each(function(data) {
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

    return chart;
};