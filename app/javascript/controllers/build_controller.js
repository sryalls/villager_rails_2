import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["buildButton", "buildDropdown", "resourceSelectors", "formSubmitButton"];

  connect() {
    this.handleBuildButtonClick = () => {
      this.buildDropdownTarget.style.display = "block";
    };
    this.buildButtonTarget.addEventListener("click", this.handleBuildButtonClick);
  }

  disconnect() {
    this.buildButtonTarget.removeEventListener("click", this.handleBuildButtonClick);
  }

  toggleResourceSelectors(event) {
    const buildingId = event.target.dataset.buildingId;
    const villageId = this.element.dataset.villageId;

    const turboFrame = document.getElementById("resource-selectors-frame");
    if (turboFrame) {
      turboFrame.src = `/villages/${villageId}/resource_selectors?building_id=${buildingId}`;
    }
  }

  calculateResourceTotals(inputs) {
    const resourceTotals = {};

    inputs.forEach((input) => {
      const tag = input.dataset.tagName;
      const max = parseInt(input.max, 10);
      const value = parseInt(input.value, 10);

      if (!resourceTotals[tag]) {
        resourceTotals[tag] = 0;
      }

      if (!isNaN(value) && value >= 0 && value <= max) {
        resourceTotals[tag] += value;
      }
    });

    return resourceTotals;
  }

  validateResourceTotals(resourceTotals, selector) {
    let allResourcesValid = true;

    selector.querySelectorAll('[data-cost-quantity]').forEach((element) => {
      const tag = element.dataset.tagName;
      const requiredQuantity = parseInt(element.dataset.costQuantity, 10);

      if (resourceTotals[tag] < requiredQuantity) {
        allResourcesValid = false;
      }
    });

    return allResourcesValid;
  }

  validateResourceSelection(event) {
    const input = event.target;
    const value = parseInt(input.value, 10);
    if (!isNaN(value) && value >= 0) {
      input.value = value;
    }

    let allResourcesValid = true;

    const selector = this.resourceSelectorsTargets[0]; // Assuming only one set of resource selectors is rendered at a time
    if (selector) {
      const inputs = selector.querySelectorAll("input[type='number']");
      const resourceTotals = this.calculateResourceTotals(inputs);
      allResourcesValid = this.validateResourceTotals(resourceTotals, selector);
    }

    this.formSubmitButtonTarget.disabled = !allResourcesValid;
  }
}