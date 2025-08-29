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
// Import hooks
import { UniversalTheme, NetworkStatusHook, NetworkGraphHook, MetricsHook, ToastHook } from "./hooks"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: {
    UniversalTheme: UniversalTheme,
    NetworkStatus: NetworkStatusHook,
    NetworkGraph: NetworkGraphHook,
    Metrics: MetricsHook,
    Toast: ToastHook
  }
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

// Universal theme initialization for both static and LiveView pages
function initializeTheme() {
  const STORAGE_KEY = 'xpando-theme-preference'
  const DEFAULT_THEME = 'dark'
  
  // Get stored theme or default
  const storedTheme = localStorage.getItem(STORAGE_KEY) || DEFAULT_THEME
  
  // Apply theme immediately to prevent flash
  document.documentElement.setAttribute('data-theme', storedTheme)
  
  // Add CSS for smooth theme transitions
  if (!document.getElementById('theme-transition-styles')) {
    const style = document.createElement('style')
    style.id = 'theme-transition-styles'
    style.textContent = `
      .theme-transition,
      .theme-transition *,
      .theme-transition *::before,
      .theme-transition *::after {
        transition: background-color 0.3s ease, color 0.3s ease, border-color 0.3s ease !important;
      }
    `
    document.head.appendChild(style)
  }
}

// Initialize theme as early as possible
initializeTheme()

// Re-initialize on DOM content loaded to ensure it's applied
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initializeTheme)
}

// Listen for the custom theme change event (for static pages)
window.addEventListener('xpando:theme-change', function(e) {
  const theme = e.detail.theme
  document.documentElement.setAttribute('data-theme', theme)
  localStorage.setItem('xpando-theme-preference', theme)
  
  // Add transition class temporarily
  document.documentElement.classList.add('theme-transition')
  setTimeout(() => {
    document.documentElement.classList.remove('theme-transition')
  }, 300)
})

// Smooth scrolling for anchor links with animation
function initializeSmoothScrolling() {
  // Smooth scroll function with custom easing
  function smoothScrollTo(targetPosition, duration = 800) {
    const startPosition = window.pageYOffset
    const distance = targetPosition - startPosition
    let startTime = null

    function animation(currentTime) {
      if (startTime === null) startTime = currentTime
      const timeElapsed = currentTime - startTime
      const run = ease(timeElapsed, startPosition, distance, duration)
      window.scrollTo(0, run)
      if (timeElapsed < duration) requestAnimationFrame(animation)
    }

    // Easing function for smooth animation
    function ease(t, b, c, d) {
      t /= d / 2
      if (t < 1) return c / 2 * t * t + b
      t--
      return -c / 2 * (t * (t - 2) - 1) + b
    }

    requestAnimationFrame(animation)
  }

  // Add click event listener for anchor links
  document.addEventListener('click', function(e) {
    const link = e.target.closest('a[href^="#"]')
    if (!link) return
    
    const href = link.getAttribute('href')
    if (!href || href === '#') return
    
    const targetId = href.substring(1)
    const targetElement = document.getElementById(targetId)
    
    if (targetElement) {
      e.preventDefault()
      
      // Calculate offset for sticky navbar (80px)
      const navbarHeight = 80
      const targetPosition = targetElement.offsetTop - navbarHeight
      
      // Perform smooth scroll with custom animation
      smoothScrollTo(Math.max(0, targetPosition), 1200) // 1.2 second duration
      
      // Update URL after scroll
      setTimeout(() => {
        if (history.pushState) {
          history.pushState(null, null, href)
        }
      }, 100)
    }
  })
}

// Initialize smooth scrolling when DOM is loaded
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initializeSmoothScrolling)
} else {
  initializeSmoothScrolling()
}

// Back to Top Buttons functionality
function initializeBackToTop() {
  const backToTopLeftBtn = document.getElementById('back-to-top-left')
  const backToTopRightBtn = document.getElementById('back-to-top-right')
  const backToTopBtns = [backToTopLeftBtn, backToTopRightBtn].filter(btn => btn)

  // Smooth scroll to top function (reusing the same smooth scroll logic)
  function scrollToTop() {
    const startPosition = window.pageYOffset
    const distance = -startPosition
    let startTime = null

    function animation(currentTime) {
      if (startTime === null) startTime = currentTime
      const timeElapsed = currentTime - startTime
      const run = ease(timeElapsed, startPosition, distance, 1000) // 1 second duration
      window.scrollTo(0, run)
      if (timeElapsed < 1000) requestAnimationFrame(animation)
    }

    // Same easing function as smooth scrolling
    function ease(t, b, c, d) {
      t /= d / 2
      if (t < 1) return c / 2 * t * t + b
      t--
      return -c / 2 * (t * (t - 2) - 1) + b
    }

    requestAnimationFrame(animation)
  }

  // Show/hide buttons based on scroll position
  function toggleBackToTopButtons() {
    const scrollPosition = window.pageYOffset
    const windowHeight = window.innerHeight
    
    // Show buttons when user has scrolled down at least one screen height
    backToTopBtns.forEach(btn => {
      if (scrollPosition > windowHeight * 0.5) {
        btn.classList.remove('hidden', 'hide')
        btn.classList.add('show')
      } else {
        btn.classList.remove('show')
        btn.classList.add('hide')
        // Hide completely after animation
        setTimeout(() => {
          if (btn.classList.contains('hide')) {
            btn.classList.add('hidden')
          }
        }, 300)
      }
    })
  }

  // Add click event listeners to both buttons
  backToTopBtns.forEach(btn => {
    btn.addEventListener('click', function(e) {
      e.preventDefault()
      scrollToTop()
    })
  })

  // Add scroll event listener with throttling for performance
  let scrollTimeout
  window.addEventListener('scroll', function() {
    if (scrollTimeout) {
      clearTimeout(scrollTimeout)
    }
    scrollTimeout = setTimeout(toggleBackToTopButtons, 10)
  })

  // Initial check
  toggleBackToTopButtons()
}

// Initialize back to top when DOM is loaded
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initializeBackToTop)
} else {
  initializeBackToTop()
}