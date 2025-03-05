import { Controller } from "@hotwired/stimulus";
import * as d3 from "d3";

export default class extends Controller {
  connect() {
    const row = parseInt(this.element.dataset.row);
    const col = parseInt(this.element.dataset.col);
    const spacer = parseFloat(this.element.dataset.spacer);
    const hasVillage = this.element.dataset.hasVillage === "true";
    const villageLink = this.element.dataset.villageLink;
    const tileId = this.element.dataset.tileId;

    // Determine hexagon dimensions
    const { width, height, xOffset, yOffset } = this.calculateHexagonDimensions(row, col, spacer);

    // Position the hexagon
    this.element.style.transform = `translate(${xOffset}px, ${yOffset}px)`;

    // Create the SVG container
    const svg = this.createSvgContainer(width, height);

    // Add hexagon shape
    const polygon = this.addHexagonShape(svg, width, height, hasVillage);

    // Add text to the hexagon button
    this.addHexagonText(svg, { x: width / 2, y: height / 2 }, hasVillage);

    // Attach click event to the polygon
    this.attachClickEvent(polygon, hasVillage, villageLink, tileId);
  }

  addHexagonShape(svg, width, height, hasVillage) {
    const center = { x: width / 2, y: height / 2 };
    const points = d3.range(6).map(i => this.hexCorner(center, 100, i)).join(" ");
    return svg.append("polygon")
      .attr("points", points)
      .attr("class", `hexagon ${hasVillage ? 'village' : 'no-village'}`);
  }

  createSvgContainer(width, height) {
    return d3.select(this.element)
      .append("svg")
      .attr("width", width)
      .attr("height", height)
      .attr("viewBox", `0 0 ${width} ${height}`)
      .attr("xmlns", "http://www.w3.org/2000/svg");
  }

  calculateHexagonDimensions(row, col, spacer) {
    // Calculate width and height of a hexagon
    const width = Math.sqrt(3) * 100;
    const height = 2 * 100;

    // Calculate the position of the hexagon
    const { xOffset, yOffset } = this.calculateOffsets(row, col, width, height, spacer);

    return { width, height, xOffset, yOffset };
  }

  calculateOffsets(row, col, width, height, spacer) {
    let xOffset = 0;
    if (row % 2 === 0) {
      xOffset = col * width;
    } else {
      xOffset = col * width + 0.5 * width;
    }
    xOffset = xOffset + spacer * width;

    const yOffset = row * height * (3 / 4);

    return { xOffset, yOffset };
  }

  hexCorner(center, size, i) {
    const angleDeg = 60 * i - 30;
    const angleRad = Math.PI / 180 * angleDeg;
    return [
      center.x + size * Math.cos(angleRad),
      center.y + size * Math.sin(angleRad)
    ];
  }

  addHexagonText(svg, center, hasVillage) {
    svg.append("text")
      .attr("x", center.x)
      .attr("y", center.y)
      .attr("class", "hexagon-text")
      .text(hasVillage ? "Village" : "Create Village");
  }

  attachClickEvent(polygon, hasVillage, villageLink, tileId) {
    if (hasVillage && villageLink) {
      polygon.on("click", () => {
        this.navigateToVillage(villageLink);
      });
    } else if (!hasVillage) {
      polygon.on("click", () => {
        this.createVillage(tileId);
      });
    }
  }

  navigateToVillage(villageLink) {
    window.location.href = villageLink;
  }

  createVillage(tileId) {
    fetch(`/villages?tile_id=${tileId}`, {
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
  }
}