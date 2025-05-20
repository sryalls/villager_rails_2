import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { url: String, interval: Number }

  connect() {
    this.intervalValue = this.intervalValue || 1000; // Default to 1 second
    this.startPolling();
  }

  disconnect() {
    this.stopPolling();
  }

  startPolling() {
    this.stopPolling(); // Ensure no duplicate intervals
    this.timer = setInterval(() => {
      this.pollResources();
    }, this.intervalValue);
  }

  stopPolling() {
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
    }
  }

  pollResources() {
    fetch(this.urlValue)
      .then(response => response.text())
      .then(html => {
        Turbo.renderStreamMessage(html);
      })
      .catch(error => console.error("Auto-refresh error:", error));
  }
}
