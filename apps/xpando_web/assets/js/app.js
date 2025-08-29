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
// Import dashboard hooks
import { ThemeHook, NetworkStatusHook, NetworkGraphHook, MetricsHook, ToastHook } from "./dashboard_hooks"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: {
    Theme: ThemeHook,
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

// Theme management: Support manual theme selection with localStorage persistence
function initializeTheme() {
  const html = document.documentElement
  const STORAGE_KEY = 'xpando-theme-preference'
  
  function applyTheme(theme) {
    html.setAttribute('data-theme', theme)
    // Add smooth transition effect
    document.body.style.transition = 'background-color 0.3s ease, color 0.3s ease'
    setTimeout(() => {
      document.body.style.transition = ''
    }, 300)
  }
  
  // Get stored theme or default to dark theme
  const storedTheme = localStorage.getItem(STORAGE_KEY) || 'dark'
  
  // Apply initial theme
  applyTheme(storedTheme)
  
  // Handle theme switching clicks for static pages (non-LiveView)
  document.addEventListener('click', function(e) {
    if (e.target.closest('[phx-click="switch_theme"]')) {
      const themeValue = e.target.getAttribute('phx-value-theme')
      if (themeValue) {
        localStorage.setItem(STORAGE_KEY, themeValue)
        applyTheme(themeValue)
        
        // Update dropdown state
        updateDropdownSelection(themeValue)
        
        // Close the dropdown after selection
        const dropdownButton = e.target.closest('.dropdown').querySelector('[tabindex="0"]')
        if (dropdownButton) {
          dropdownButton.blur()
          // Remove focus from any dropdown elements
          document.activeElement?.blur()
        }
      }
    }
  })
  
  function updateDropdownSelection(selectedTheme) {
    // Update active state in dropdowns
    const buttons = document.querySelectorAll('[data-theme-toggle]')
    buttons.forEach(button => {
      const theme = button.getAttribute('phx-value-theme')
      if (theme === selectedTheme) {
        button.classList.add('active')
      } else {
        button.classList.remove('active')
      }
    })
  }
  
  // Initialize dropdown state
  updateDropdownSelection(storedTheme)
}

// Initialize theme when DOM is loaded
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initializeTheme)
} else {
  initializeTheme()
}

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

