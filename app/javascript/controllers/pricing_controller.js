import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggleSwitch", "monthlyLabel", "annualLabel", "basicPrice", "proPrice"]

  toggle() {
    const isAnnual = this.toggleSwitchTarget.classList.toggle("active")

    if (isAnnual) {
      this.monthlyLabelTarget.classList.remove("active-label")
      this.annualLabelTarget.classList.add("active-label")
      this.basicPriceTarget.textContent = "$3"
      this.proPriceTarget.textContent = "$8"
    } else {
      this.monthlyLabelTarget.classList.add("active-label")
      this.annualLabelTarget.classList.remove("active-label")
      this.basicPriceTarget.textContent = "$4"
      this.proPriceTarget.textContent = "$9"
    }
  }
}
