import { Controller } from "@hotwired/stimulus"
import * as d3 from "d3"

export default class extends Controller {
  connect() {
    console.log("HexButtonController connected")

    // Set up the SVG canvas dimensions
    const width = 200
    const height = 200

    // Create the SVG container
    const svg = d3.select(this.element)
      .append("svg")
      .attr("width", width)
      .attr("height", height)
      .attr("viewBox", `0 0 ${width} ${height}`)
      .attr("xmlns", "http://www.w3.org/2000/svg")

    // Define the hexagon points
    const hexagonPoints = [
      { x: 100, y: 20 },
      { x: 170, y: 60 },
      { x: 170, y: 140 },
      { x: 100, y: 180 },
      { x: 30, y: 140 },
      { x: 30, y: 60 }
    ]

    // Create the hexagon shape
    svg.append("polygon")
      .attr("points", hexagonPoints.map(d => `${d.x},${d.y}`).join(" "))
      .attr("fill", "#3498db")
      .attr("stroke", "#2980b9")
      .attr("stroke-width", 2)
      .on("click", () => {
        alert("Hexagon button clicked!")
      })

    // Add text to the hexagon button
    svg.append("text")
      .attr("x", 100)
      .attr("y", 100)
      .attr("text-anchor", "middle")
      .attr("dominant-baseline", "middle")
      .attr("fill", "white")
      .attr("font-size", "16px")
      .text("Click Me")
  }
}