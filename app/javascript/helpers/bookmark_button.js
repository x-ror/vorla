// Matches app/assets/icons/lucide/bookmark.svg
const bookmarkIcon = `<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 3a2 2 0 0 1 2 2v15a1 1 0 0 1-1.496.868l-4.512-2.578a2 2 0 0 0-1.984 0l-4.512 2.578A1 1 0 0 1 5 20V5a2 2 0 0 1 2-2z"/></svg>`

const bookmarkIconFilled = `<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="currentColor" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 3a2 2 0 0 1 2 2v15a1 1 0 0 1-1.496.868l-4.512-2.578a2 2 0 0 0-1.984 0l-4.512 2.578A1 1 0 0 1 5 20V5a2 2 0 0 1 2-2z"/></svg>`

async function handleBookmark(btn, url, title) {
  if (btn.disabled) return
  btn.disabled = true

  try {
    const response = await fetch("/bookmarks", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content
      },
      body: JSON.stringify({ url, title })
    })

    const data = await response.json()

    if (response.ok) {
      btn.classList.add("bookmarked")
      btn.innerHTML = bookmarkIconFilled
      btn.title = "Bookmarked"
    } else {
      const original = btn.innerHTML
      btn.innerHTML = data.message || "Failed"
      btn.classList.add("bookmark-error")
      setTimeout(() => {
        btn.innerHTML = original
        btn.classList.remove("bookmark-error")
      }, 2000)
    }
  } catch {
    const original = btn.innerHTML
    btn.innerHTML = "Failed"
    btn.classList.add("bookmark-error")
    setTimeout(() => {
      btn.innerHTML = original
      btn.classList.remove("bookmark-error")
    }, 2000)
  } finally {
    btn.disabled = false
  }
}

export function buildBookmarkBtn(url, title = "") {
  const btn = document.createElement("button")
  btn.type = "button"
  btn.className = "bookmark-btn"
  btn.title = "Bookmark"
  btn.innerHTML = bookmarkIcon
  btn.addEventListener("click", () => handleBookmark(btn, url, title))
  return btn
}
