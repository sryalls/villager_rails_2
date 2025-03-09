import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["buildButton", "buildDropdown"];

  connect() {
    this.buildButtonTarget.addEventListener("click", () => {
      this.buildDropdownTarget.style.display = "block";
    });
  }
}