import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["status"]

  async register() {
    try {
      this.setStatus("Preparing...")

      const optionsResponse = await fetch("/passkeys/register/options", {
        method: "POST",
        headers: { "X-CSRF-Token": this.csrfToken, "Accept": "application/json" }
      })

      if (!optionsResponse.ok) {
        const error = await optionsResponse.json().catch(() => ({ error: "Server error" }))
        this.setStatus(`Error: ${error.error || "Could not start registration"}`)
        return
      }

      const options = await optionsResponse.json()

      options.challenge = this.base64urlToBuffer(options.challenge)
      options.user.id = this.base64urlToBuffer(options.user.id)
      if (options.excludeCredentials) {
        options.excludeCredentials = options.excludeCredentials.map(cred => ({
          ...cred,
          id: this.base64urlToBuffer(cred.id)
        }))
      }

      this.setStatus("Touch your fingerprint sensor...")

      const credential = await navigator.credentials.create({ publicKey: options })

      const verifyResponse = await fetch("/passkeys/register/verify", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfToken
        },
        body: JSON.stringify({
          id: credential.id,
          rawId: this.bufferToBase64url(credential.rawId),
          type: credential.type,
          response: {
            attestationObject: this.bufferToBase64url(credential.response.attestationObject),
            clientDataJSON: this.bufferToBase64url(credential.response.clientDataJSON)
          }
        })
      })

      if (verifyResponse.ok) {
        window.location.reload()
      } else {
        const error = await verifyResponse.json()
        this.setStatus(`Error: ${error.error}`)
      }
    } catch (e) {
      if (e.name === "NotAllowedError") {
        this.setStatus("Registration cancelled.")
      } else if (e.name === "InvalidStateError") {
        this.setStatus("This passkey is already registered.")
      } else {
        this.setStatus(`Error: ${e.message}`)
      }
    }
  }

  async authenticate() {
    try {
      this.setStatus("Preparing...")

      const optionsResponse = await fetch("/passkeys/authenticate/options", {
        method: "POST",
        headers: { "X-CSRF-Token": this.csrfToken, "Accept": "application/json" }
      })
      const options = await optionsResponse.json()

      options.challenge = this.base64urlToBuffer(options.challenge)
      if (options.allowCredentials) {
        options.allowCredentials = options.allowCredentials.map(cred => ({
          ...cred,
          id: this.base64urlToBuffer(cred.id)
        }))
      }

      this.setStatus("Touch your fingerprint sensor...")

      const credential = await navigator.credentials.get({ publicKey: options })

      const verifyResponse = await fetch("/passkeys/authenticate/verify", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfToken
        },
        body: JSON.stringify({
          id: credential.id,
          rawId: this.bufferToBase64url(credential.rawId),
          type: credential.type,
          response: {
            authenticatorData: this.bufferToBase64url(credential.response.authenticatorData),
            clientDataJSON: this.bufferToBase64url(credential.response.clientDataJSON),
            signature: this.bufferToBase64url(credential.response.signature),
            userHandle: credential.response.userHandle
              ? this.bufferToBase64url(credential.response.userHandle)
              : null
          }
        })
      })

      if (verifyResponse.ok) {
        const data = await verifyResponse.json()
        window.location.href = data.redirect_to
      } else {
        const error = await verifyResponse.json()
        this.setStatus(`Error: ${error.error}`)
      }
    } catch (e) {
      if (e.name === "NotAllowedError") {
        this.setStatus("Authentication cancelled.")
      } else {
        this.setStatus(`Error: ${e.message}`)
      }
    }
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content
  }

  setStatus(message) {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = message
    }
  }

  base64urlToBuffer(base64url) {
    const base64 = base64url.replace(/-/g, "+").replace(/_/g, "/")
    const padding = "=".repeat((4 - (base64.length % 4)) % 4)
    const binary = atob(base64 + padding)
    const buffer = new ArrayBuffer(binary.length)
    const view = new Uint8Array(buffer)
    for (let i = 0; i < binary.length; i++) {
      view[i] = binary.charCodeAt(i)
    }
    return buffer
  }

  bufferToBase64url(buffer) {
    const bytes = new Uint8Array(buffer)
    let binary = ""
    for (let i = 0; i < bytes.byteLength; i++) {
      binary += String.fromCharCode(bytes[i])
    }
    return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=/g, "")
  }
}
