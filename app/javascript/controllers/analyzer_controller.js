import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["username", "submitBtn", "error", "result"]

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

    try {
      const response = await fetch("/api/analyze", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ username })
      })

      const data = await response.json()
      if (!response.ok) throw new Error(data.message)

      const formatNum = (n) => {
        if (!n) return "0"
        if (n >= 1000000) return (n / 1000000).toFixed(1) + "M"
        if (n >= 1000) return (n / 1000).toFixed(1) + "K"
        return n.toString()
      }

      const ratio = data.followers && data.following ? (data.followers / data.following).toFixed(2) : "N/A"
      const accountType = data.isVerified ? "Verified" : data.isBusinessAccount ? "Business" : "Personal"

      this.resultTarget.style.display = "block"
      this.resultTarget.innerHTML = `
        <div class="profile-result animate-slide-up">
          <div class="profile-header">
            <div class="profile-avatar">
              ${data.profilePic
                ? `<img src="${data.profilePic}" alt="${data.username}">`
                : `<div class="avatar-placeholder">${data.username[0].toUpperCase()}</div>`}
            </div>
            <div class="profile-meta">
              <h2>@${data.username}</h2>
              ${data.fullName ? `<p class="full-name">${data.fullName}</p>` : ""}
              ${data.bio ? `<p class="bio">${data.bio}</p>` : ""}
            </div>
          </div>

          <div class="stats-grid">
            <div class="stat-card"><span class="stat-value">${formatNum(data.posts)}</span><span class="stat-label">Posts</span></div>
            <div class="stat-card"><span class="stat-value">${formatNum(data.followers)}</span><span class="stat-label">Followers</span></div>
            <div class="stat-card"><span class="stat-value">${formatNum(data.following)}</span><span class="stat-label">Following</span></div>
            <div class="stat-card"><span class="stat-value">${data.engagementRate || "N/A"}</span><span class="stat-label">Engagement</span></div>
          </div>

          <div class="insights">
            <h3>Insights</h3>
            <div class="insight-item">
              <span>&#8599;</span>
              <div class="insight-detail">
                <span class="insight-label">Follower/Following Ratio</span>
                <span class="insight-value">${ratio}</span>
              </div>
            </div>
            <div class="insight-item">
              <span>&#9776;</span>
              <div class="insight-detail">
                <span class="insight-label">Avg. Posts/Week</span>
                <span class="insight-value">${data.avgPostsPerWeek || "N/A"}</span>
              </div>
            </div>
            <div class="insight-item">
              <span>&#9733;</span>
              <div class="insight-detail">
                <span class="insight-label">Account Type</span>
                <span class="insight-value">${accountType}</span>
              </div>
            </div>
          </div>
        </div>`
    } catch (err) {
      this.showError(err.message || "Failed to analyze profile")
    } finally {
      this.submitBtnTarget.disabled = false
    }
  }

  showError(msg) { this.errorTarget.textContent = msg; this.errorTarget.style.display = "flex" }
  hideError() { this.errorTarget.style.display = "none" }
}
