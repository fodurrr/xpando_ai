/**
 * LiveView Hooks
 * 
 * Provides client-side enhancements for xPando including:
 * - Universal theme management
 * - Real-time status indicators
 * - Network activity animations
 * - Connection health monitoring
 */

// Universal theme hook - handles all theme management consistently
const UniversalTheme = {
  mounted() {
    this.storageKey = this.el.dataset.storageKey || 'xpando-theme-preference'
    this.defaultTheme = this.el.dataset.defaultTheme || 'dark'
    
    // Initialize theme on mount
    this.initializeTheme()
    
    // Listen for theme change events
    this.el.addEventListener('xpando:theme-change', (e) => {
      this.changeTheme(e.detail.theme)
    })
    
    // Listen for storage changes (cross-tab sync)
    window.addEventListener('storage', (e) => {
      if (e.key === this.storageKey && e.newValue) {
        this.applyTheme(e.newValue)
      }
    })
    
    // Update UI on mount
    this.updateThemeUI()
  },
  
  initializeTheme() {
    // Get saved theme or use default
    const savedTheme = localStorage.getItem(this.storageKey) || this.defaultTheme
    
    // Apply theme immediately
    this.applyTheme(savedTheme)
    
    // Sync with LiveView if connected
    if (this.pushEvent) {
      this.pushEvent("sync_theme", { theme: savedTheme })
    }
  },
  
  changeTheme(theme) {
    // Save to localStorage
    localStorage.setItem(this.storageKey, theme)
    
    // Apply theme
    this.applyTheme(theme)
    
    // Notify LiveView if connected
    if (this.pushEvent) {
      this.pushEvent("theme_changed", { theme })
    }
    
    // Dispatch custom event for other components
    window.dispatchEvent(new CustomEvent('theme-applied', { 
      detail: { theme } 
    }))
  },
  
  applyTheme(theme) {
    // Apply to document root
    document.documentElement.setAttribute('data-theme', theme)
    
    // Add smooth transition
    if (!document.documentElement.classList.contains('theme-transition')) {
      document.documentElement.classList.add('theme-transition')
      setTimeout(() => {
        document.documentElement.classList.remove('theme-transition')
      }, 300)
    }
    
    // Update UI elements
    this.updateThemeUI()
  },
  
  updateThemeUI() {
    const currentTheme = localStorage.getItem(this.storageKey) || 
                        document.documentElement.getAttribute('data-theme') || 
                        this.defaultTheme
    
    // Update theme icons visibility
    const darkIcon = this.el.querySelector('.theme-icon-dark')
    const lightIcon = this.el.querySelector('.theme-icon-light')
    
    if (darkIcon && lightIcon) {
      if (currentTheme === 'light' || currentTheme === 'cupcake' || currentTheme === 'bumblebee') {
        darkIcon.classList.add('hidden')
        lightIcon.classList.remove('hidden')
      } else {
        darkIcon.classList.remove('hidden')
        lightIcon.classList.add('hidden')
      }
    }
    
    // Update checkmarks for all theme options
    this.el.querySelectorAll('.theme-check').forEach(check => {
      check.classList.add('hidden')
    })
    
    const activeCheck = this.el.querySelector(`.theme-check-${currentTheme}`)
    if (activeCheck) {
      activeCheck.classList.remove('hidden')
    }
    
    // Update active state on buttons
    this.el.querySelectorAll('.theme-option').forEach(option => {
      const themeValue = option.dataset.themeValue
      if (themeValue === currentTheme) {
        option.classList.add('active')
      } else {
        option.classList.remove('active')
      }
    })
  }
}

// Network status animation hook
const NetworkStatusHook = {
  mounted() {
    this.animateNetworkActivity()
    
    // Listen for network updates
    this.handleEvent("network_activity", ({ type, node_id }) => {
      this.showNetworkActivity(type, node_id)
    })
  },
  
  animateNetworkActivity() {
    // Add subtle animations to active network elements
    const activeNodes = this.el.querySelectorAll('[data-status="online"]')
    activeNodes.forEach(node => {
      node.classList.add('animate-pulse')
    })
  },
  
  showNetworkActivity(type, _nodeId) {
    // Create temporary activity indicator
    const indicator = document.createElement('div')
    indicator.className = 'fixed top-4 right-4 alert alert-info alert-sm z-[60] animate-slide-in-right'
    indicator.innerHTML = `
      <svg class="h-4 w-4" fill="currentColor" viewBox="0 0 24 24">
        <path d="M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m0 2.684l6.632 3.316m-6.632-6l6.632-3.316m0 0a3 3 0 105.367-2.684 3 3 0 00-5.367 2.684zm0 9.316a3 3 0 105.367 2.684 3 3 0 00-5.367-2.684z"/>
      </svg>
      <span>Network activity: ${type}</span>
    `
    
    document.body.appendChild(indicator)
    
    // Auto-remove after 3 seconds
    setTimeout(() => {
      indicator.classList.add('animate-fade-out')
      setTimeout(() => indicator.remove(), 300)
    }, 3000)
  }
}

// Network graph interaction hook
const NetworkGraphHook = {
  mounted() {
    this.initializeGraph()
    this.setupInteractions()
    
    // Listen for graph updates
    this.handleEvent("graph_update", (data) => {
      this.updateGraph(data)
    })
  },
  
  initializeGraph() {
    const svg = this.el.querySelector('svg')
    if (svg) {
      // Add zoom and pan capabilities
      this.addZoomBehavior(svg)
      
      // Initialize node pulse animations
      this.startNodeAnimations()
    }
  },
  
  setupInteractions() {
    // Add keyboard navigation
    this.el.addEventListener('keydown', (e) => {
      if (e.key === 'Escape') {
        this.clearSelection()
      }
    })
    
    // Add double-click to zoom to node
    this.el.addEventListener('dblclick', (e) => {
      const nodeElement = e.target.closest('[data-node-id]')
      if (nodeElement) {
        this.zoomToNode(nodeElement.dataset.nodeId)
      }
    })
  },
  
  addZoomBehavior(svg) {
    // Simple zoom implementation
    let scale = 1
    const maxScale = 3
    const minScale = 0.5
    
    svg.addEventListener('wheel', (e) => {
      e.preventDefault()
      
      const delta = e.deltaY > 0 ? 0.9 : 1.1
      const newScale = Math.max(minScale, Math.min(maxScale, scale * delta))
      
      if (newScale !== scale) {
        scale = newScale
        svg.style.transform = `scale(${scale})`
        svg.style.transformOrigin = 'center'
      }
    })
  },
  
  startNodeAnimations() {
    // Animate connection pulses for active connections
    const connections = this.el.querySelectorAll('line[data-status="active"]')
    connections.forEach((line, index) => {
      line.style.animationDelay = `${index * 0.2}s`
      line.classList.add('animate-pulse')
    })
  },
  
  updateGraph(data) {
    // Update graph with new data while maintaining animations
    this.pushEvent("graph_data_updated", data)
  },
  
  zoomToNode(nodeId) {
    this.pushEvent("focus_node", { node_id: nodeId })
  },
  
  clearSelection() {
    this.pushEvent("clear_selection", {})
  }
}

// Real-time metrics hook
const MetricsHook = {
  mounted() {
    this.startMetricsUpdate()
  },
  
  destroyed() {
    if (this.metricsInterval) {
      clearInterval(this.metricsInterval)
    }
  },
  
  startMetricsUpdate() {
    // Update metrics every 5 seconds
    this.metricsInterval = setInterval(() => {
      this.updateMetricsDisplay()
    }, 5000)
  },
  
  updateMetricsDisplay() {
    // Add subtle loading indicators during updates
    const statElements = this.el.querySelectorAll('.stat-value')
    statElements.forEach(el => {
      el.classList.add('animate-pulse')
      setTimeout(() => {
        el.classList.remove('animate-pulse')
      }, 500)
    })
  }
}

// Toast hook for Daisy UI toast notifications
const ToastHook = {
  mounted() {
    this.handleEvent("show_toast", ({ type, message }) => {
      this.showToast(type, message)
    })
  },
  
  showToast(type, message) {
    // Create DaisyUI toast with icon on the left
    const toastItem = document.createElement('div')
    toastItem.className = `alert alert-${type}`
    toastItem.innerHTML = `
      <svg class="stroke-current flex-shrink-0 h-6 w-6" fill="none" viewBox="0 0 24 24">
        ${this.getIcon(type)}
      </svg>
      <span>${message}</span>
    `
    
    this.el.appendChild(toastItem)
    
    // Auto-remove after 4 seconds
    setTimeout(() => {
      if (toastItem.parentNode) {
        toastItem.parentNode.removeChild(toastItem)
      }
    }, 4000)
  },

  getIcon(type) {
    switch (type) {
      case 'success':
        return '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />'
      case 'warning':
        return '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.996-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z" />'
      case 'error':
        return '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" />'
      case 'info':
      default:
        return '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />'
    }
  }
}

export { UniversalTheme, NetworkStatusHook, NetworkGraphHook, MetricsHook, ToastHook }