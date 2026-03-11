import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["username", "submitBtn", "error", "result"]

  connect() {
    this._abortController = null
  }

  disconnect() {
    this._abortController?.abort()
  }

  async analyze(event) {
    event.preventDefault()
    let username = this.usernameTarget.value.trim().replace(/^@/, "")
    if (!username) return

    if (username.includes("instagram.com")) {
      try {
        const url = new URL(username.startsWith("http") ? username : `https://${username}`)
        username = url.pathname.split("/").filter(Boolean)[0]
      } catch { /* use as-is */ }
    }

    this.hideError()
    this.resultTarget.style.display = "none"
    this.submitBtnTarget.disabled = true

    this._abortController?.abort()
    this._abortController = new AbortController()

    try {
      const response = await fetch("/api/analyze", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ username }),
        signal: this._abortController.signal
      })

      const data = await response.json()
      if (!response.ok) throw new Error(data.message)

      this.resultTarget.style.display = "block"
      this.resultTarget.innerHTML = ""
      this.resultTarget.appendChild(this._buildProfileResult(data))
    } catch (err) {
      if (err.name === "AbortError") return
      this.showError(err.message || "Failed to analyze profile")
    } finally {
      this.submitBtnTarget.disabled = false
    }
  }

  _buildProfileResult(data) {
    const formatNum = (n) => {
      if (!n) return "0"
      if (n >= 1000000) return (n / 1000000).toFixed(1) + "M"
      if (n >= 1000) return (n / 1000).toFixed(1) + "K"
      return n.toString()
    }

    const ratio = data.followers && data.following ? (data.followers / data.following).toFixed(2) : "N/A"
    const accountType = data.isVerified ? "Verified" : data.isBusinessAccount ? "Business" : "Personal"

    const wrapper = document.createElement("div")
    wrapper.className = "profile-result animate-slide-up"

    // Profile header
    const header = document.createElement("div")
    header.className = "profile-header"

    const avatarWrap = document.createElement("div")
    avatarWrap.className = "profile-avatar"

    if (data.profilePic) {
      const img = document.createElement("img")
      img.src = data.profilePic
      img.alt = data.username || ""
      avatarWrap.appendChild(img)
    } else {
      const placeholder = document.createElement("div")
      placeholder.className = "avatar-placeholder"
      placeholder.textContent = (data.username || "?")[0].toUpperCase()
      avatarWrap.appendChild(placeholder)
    }

    const meta = document.createElement("div")
    meta.className = "profile-meta"

    const h2 = document.createElement("h2")
    h2.textContent = `@${data.username || ""}`
    meta.appendChild(h2)

    if (data.fullName) {
      const fullName = document.createElement("p")
      fullName.className = "full-name"
      fullName.textContent = data.fullName
      meta.appendChild(fullName)
    }
    if (data.bio) {
      const bio = document.createElement("p")
      bio.className = "bio"
      bio.textContent = data.bio
      meta.appendChild(bio)
    }

    header.append(avatarWrap, meta)

    // Stats grid
    const statsGrid = document.createElement("div")
    statsGrid.className = "stats-grid"

    const stats = [
      { value: formatNum(data.posts), label: "Posts" },
      { value: formatNum(data.followers), label: "Followers" },
      { value: formatNum(data.following), label: "Following" },
      { value: data.engagementRate || "N/A", label: "Engagement" }
    ]
    stats.forEach(({ value, label }) => {
      const card = document.createElement("div")
      card.className = "stat-card"
      const valSpan = document.createElement("span")
      valSpan.className = "stat-value"
      valSpan.textContent = value
      const labelSpan = document.createElement("span")
      labelSpan.className = "stat-label"
      labelSpan.textContent = label
      card.append(valSpan, labelSpan)
      statsGrid.appendChild(card)
    })

    // Insights
    const insights = document.createElement("div")
    insights.className = "insights"

    const insightsTitle = document.createElement("h3")
    insightsTitle.textContent = "Insights"
    insights.appendChild(insightsTitle)

    const insightData = [
      { icon: "\u2197", label: "Follower/Following Ratio", value: ratio },
      { icon: "\u2630", label: "Avg. Posts/Week", value: data.avgPostsPerWeek || "N/A" },
      { icon: "\u2605", label: "Account Type", value: accountType }
    ]
    insightData.forEach(({ icon, label, value }) => {
      const item = document.createElement("div")
      item.className = "insight-item"

      const iconSpan = document.createElement("span")
      iconSpan.textContent = icon

      const detail = document.createElement("div")
      detail.className = "insight-detail"

      const labelSpan = document.createElement("span")
      labelSpan.className = "insight-label"
      labelSpan.textContent = label

      const valueSpan = document.createElement("span")
      valueSpan.className = "insight-value"
      valueSpan.textContent = value

      detail.append(labelSpan, valueSpan)
      item.append(iconSpan, detail)
      insights.appendChild(item)
    })

    wrapper.append(header, statsGrid, insights)
    return wrapper
  }

  showError(msg) { this.errorTarget.textContent = msg; this.errorTarget.style.display = "flex" }
  hideError() { this.errorTarget.style.display = "none" }
}
