import { Application } from "@hotwired/stimulus"
import BuildController from "./controllers/build_controller"
import HexButtonController from "./controllers/hex_button_controller"

const application = Application.start()
const context = require.context(".", true, /\.js$/)
application.load(definitionsFromContext(context))
window.Stimulus = Application.start()
Stimulus.register("build", BuildController)
Stimulus.register("hex-button", HexButtonController)