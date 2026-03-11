import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["username", "submitBtn", "error", "result"]

  connect() {
    this._abortController = null
  }

  disconnect() {
    this._abortController?.abort()
  }

  async fetch(event) {
    event.preventDefault()
    let username = this.usernameTarget.value.trim().replace(/^@/, "")
    if (!username) return

    if (username.includes("instagram.com")) {
      try {
        const url = new URL(username.startsWith("http") ? username : `https://${username}`)
        username = url.pathname.replace(/^\//, "").replace(/\/$/, "")
      } catch { /* use as-is */ }
    }

    this.hideError()
    this.resultTarget.style.display = "none"
    this.submitBtnTarget.disabled = true

    this._abortController?.abort()
    this._abortController = new AbortController()

    try {
      const response = await fetch("/api/profile_picture", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ username }),
        signal: this._abortController.signal
      })

      const data = await response.json()
      if (!response.ok) throw new Error(data.message || "Profile not found")

      this.resultTarget.style.display = "block"
      this.resultTarget.innerHTML = ""
      this.resultTarget.appendChild(this._buildResult(data))
    } catch (err) {
      if (err.name === "AbortError") return
      this.showError(err.message || "Could not find that profile.")
    } finally {
      this.submitBtnTarget.disabled = false
    }
  }

  _buildResult(data) {
    const wrapper = document.createElement("div")
    wrapper.className = "pfp-result animate-slide-up"

    const previewWrap = document.createElement("div")
    previewWrap.className = "pfp-preview"
    const img = document.createElement("img")
    img.src = data.hdUrl
    img.alt = `${data.username || "User"}'s profile picture`
    previewWrap.appendChild(img)

    const info = document.createElement("div")
    info.className = "pfp-info"
    const h3 = document.createElement("h3")
    h3.textContent = `@${data.username || ""}`
    info.appendChild(h3)

    if (data.fullName) {
      const name = document.createElement("p")
      name.className = "pfp-fullname"
      name.textContent = data.fullName
      info.appendChild(name)
    }

    const res = document.createElement("p")
    res.className = "resolution"
    res.textContent = "Full HD resolution"
    info.appendChild(res)

    const link = document.createElement("a")
    link.href = data.hdUrl
    link.download = `${data.username || "profile"}_profile_picture.jpg`
    link.target = "_blank"
    link.className = "btn btn-primary btn-lg pfp-download-btn"
    link.textContent = "Download HD"

    wrapper.append(previewWrap, info, link)
    return wrapper
  }

  showError(msg) { this.errorTarget.textContent = msg; this.errorTarget.style.display = "flex" }
  hideError() { this.errorTarget.style.display = "none" }
}
