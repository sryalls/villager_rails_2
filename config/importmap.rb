# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"
pin "d3", to: "https://cdn.jsdelivr.net/npm/d3@7/+esm"
pin "@rails/ujs", to: "https://ga.jspm.io/npm:@rails/ujs@6.1.4/lib/assets/compiled/rails-ujs.js"
pin "popper", to: "https://ga.jspm.io/npm:@popperjs/core@2.11.8/lib/index.js", preload: true
pin "bootstrap", to:  "https://ga.jspm.io/npm:bootstrap@5.1.3/dist/js/bootstrap.esm.js", preload: true
