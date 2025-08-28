// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken}
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// Theme management: Support manual theme selection with localStorage persistence
function initializeTheme() {
  const html = document.documentElement
  const prefersDarkScheme = window.matchMedia('(prefers-color-scheme: dark)')
  const STORAGE_KEY = 'xpando-theme-preference'
  
  function applyTheme(theme) {
    html.setAttribute('data-theme', theme)
    // Update theme toggle button if it exists
    updateThemeToggleButton(theme)
  }
  
  function getThemeFromPreference(userPreference) {
    switch (userPreference) {
      case 'dark':
        return 'synthwave'
      case 'light':
        return 'synthwave-light'
      case 'auto':
      default:
        return prefersDarkScheme.matches ? 'synthwave' : 'synthwave-light'
    }
  }
  
  function updateThemeToggleButton(currentTheme) {
    const themeButton = document.getElementById('theme-toggle')
    const themeIcon = document.getElementById('theme-icon')
    const themeText = document.getElementById('theme-text')
    
    if (themeButton && themeIcon && themeText) {
      const isDark = currentTheme === 'synthwave'
      themeIcon.innerHTML = isDark ? 
        // Sun icon for light mode option
        `<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z" />` :
        // Moon icon for dark mode option  
        `<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z" />`
      
      themeText.textContent = isDark ? 'Light' : 'Dark'
      themeButton.setAttribute('aria-label', `Switch to ${isDark ? 'light' : 'dark'} theme`)
    }
  }
  
  // Get stored preference or default to 'auto'
  const storedPreference = localStorage.getItem(STORAGE_KEY) || 'auto'
  const initialTheme = getThemeFromPreference(storedPreference)
  
  // Apply initial theme
  applyTheme(initialTheme)
  
  // Listen for system theme changes only if preference is 'auto'
  prefersDarkScheme.addEventListener('change', () => {
    const currentPreference = localStorage.getItem(STORAGE_KEY) || 'auto'
    if (currentPreference === 'auto') {
      applyTheme(getThemeFromPreference('auto'))
    }
  })
  
  // Expose theme switching function globally
  window.toggleTheme = function() {
    const currentTheme = html.getAttribute('data-theme')
    const newPreference = currentTheme === 'synthwave' ? 'light' : 'dark'
    const newTheme = getThemeFromPreference(newPreference)
    
    localStorage.setItem(STORAGE_KEY, newPreference)
    applyTheme(newTheme)
  }
}

// Initialize theme when DOM is loaded
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initializeTheme)
} else {
  initializeTheme()
}

