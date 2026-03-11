import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["field", "editBtn", "saveBtn", "cancelBtn", "avatarBtn"]

  edit() {
    this.fieldTargets.forEach(f => f.disabled = false)
    if (this.hasAvatarBtnTarget) this.avatarBtnTarget.disabled = false
    this.editBtnTarget.classList.add("hidden")
    this.saveBtnTarget.classList.remove("hidden")
    this.cancelBtnTarget.classList.remove("hidden")
    this.fieldTargets[0]?.focus()
  }

  cancel() {
    this.fieldTargets.forEach(f => {
      f.disabled = true
      f.value = f.dataset.original ?? f.value
    })
    if (this.hasAvatarBtnTarget) this.avatarBtnTarget.disabled = true
    this.editBtnTarget.classList.remove("hidden")
    this.saveBtnTarget.classList.add("hidden")
    this.cancelBtnTarget.classList.add("hidden")
  }
}
