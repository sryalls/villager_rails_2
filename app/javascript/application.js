import { Application } from "@hotwired/stimulus"
import Rails from "@rails/ujs"
import "@hotwired/turbo-rails"
import BuildController from "./controllers/build_controller"
import HexButtonController from "./controllers/hex_button_controller"

Rails.start()

const application = Application.start()
application.register("build", BuildController)
application.register("hex-button", HexButtonController)