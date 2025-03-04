import { Controller } from "@hotwired/stimulus"
import * as d3 from "d3"

export default class extends Controller {
  connect() {
    console.log("HexButtonController connected")
    
    // The size of the hexagon (radius of the outer circle)
    const size = 100
    
    // Calculate width and height of a hexagon
    const width = Math.sqrt(3) * size
    const height = 2 * size
    
    // Get row, column, spacer, and hasVillage from data attributes
    const row = parseInt(this.element.dataset.row)
    const col = parseInt(this.element.dataset.col)
    const spacer = parseInt(this.element.dataset.spacer)
    const hasVillage = this.element.dataset.hasVillage === "true"
    
    // Calculate the position of the hexagon
    var xOffset = 0
    if(row % 2 === 0){
      xOffset = ((col-1)  * width)
    }else{
      xOffset = ((col-1) * width) + ( 0.5 * width)
    }
    xOffset = xOffset + (spacer * width)
    
    const yOffset = row * height * (3/4)
    
    // Position the hexagon
    this.element.style.transform = `translate(${xOffset}px, ${yOffset}px)`
    
    // Create the SVG container
    const svg = d3.select(this.element)
      .append("svg")
      .attr("width", width)
      .attr("height", height)
      .attr("viewBox", `0 0 ${width} ${height}`)
      .attr("xmlns", "http://www.w3.org/2000/svg")
    
    // Function to calculate hexagon points
    function hexCorner(center, size, i) {
      const angleDeg = 60 * i - 30
      const angleRad = Math.PI / 180 * angleDeg
      return {
        x: center.x + size * Math.cos(angleRad),
        y: center.y + size * Math.sin(angleRad),
      }
    }
    
    // Define the hexagon points
    const center = { x: width / 2, y: height / 2 }
    const hexagonPoints = []
    for (let i = 0; i < 6; i++) {
      const point = hexCorner(center, size, i)
      hexagonPoints.push(`${point.x},${point.y}`)
    }
    
    // Create the hexagon shape
    const polygon = svg.append("polygon")
      .attr("points", hexagonPoints.join(" "))
      .attr("fill", hasVillage ? "#2ecc71" : "#3498db")  // Change color if village exists
      .attr("stroke", hasVillage ? "#27ae60" : "#2980b9")
      .attr("stroke-width", 2)
    
    if (!hasVillage) {
      polygon.on("click", () => {
        fetch(`/villages?tile_id=${this.element.dataset.tileId}`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
          }
        }).then(response => {
          if (response.ok) {
            return response.json();
          } else {
            throw new Error('Failed to create village');
          }
        }).then(data => {
          window.location.href = data.redirect_url;
        }).catch(error => {
          alert(error.message);
        });
      })
    }
    
    // Add text to the hexagon button
    svg.append("text")
      .attr("x", center.x)
      .attr("y", center.y)
      .attr("text-anchor", "middle")
      .attr("dominant-baseline", "middle")
      .attr("fill", "white")
      .attr("font-size", "16px")
      .text(hasVillage ? "Village" : "Create Village")
  }
}