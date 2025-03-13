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
    this.resourceSelectorsTargets.forEach((selector) => {
      if (selector.dataset.buildingId === buildingId) {
        selector.style.display = "block";
        selector.classList.add("active");
      } else {
        selector.style.display = "none";
        selector.classList.remove("active");
      }
    });
    this.validateResourceSelection();
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

  validateResourceSelection() {
    let allResourcesValid = true;

    allResourcesValid = this.resourceSelectorsTargets.every((selector) => {
      if (selector.classList.contains("active")) {
        const inputs = selector.querySelectorAll("input[type='number']");
        const resourceTotals = this.calculateResourceTotals(inputs);
        return this.validateResourceTotals(resourceTotals, selector);
      }
      return true;
    });
    this.formSubmitButtonTarget.disabled = !allResourcesValid;
  }
}