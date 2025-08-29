// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require("tailwindcss/plugin")
const fs = require("fs")
const path = require("path")

module.exports = {
  content: [
    "./js/**/*.js",
    "../lib/xpando_web_web.ex",
    "../lib/xpando_web_web/**/*.*ex"
  ],
  theme: {
    extend: {
      colors: {
        brand: "#FD4F00",
      }
    },
  },
  daisyui: {
    themes: [
      {
        "xpando-light-sophisticated": // xpando-light-sophisticated
        {
          "primary": "oklch(65.7% 0.224 353.4)", // Your vibrant pink
          "secondary": "oklch(69.8% 0.158 238.2)", // Your electric blue
          "accent": "oklch(82.1% 0.164 88.7)",   // Your golden yellow

          "neutral": "oklch(58% 0.02 240)",       // A cool-toned mid-grey

          "base-100": "oklch(98% 0.01 240)",      // Very light, cool blue/grey background
          "base-200": "oklch(94% 0.015 240)",     // Slightly darker shade
          "base-300": "oklch(90% 0.02 240)",      // Even darker shade

          "base-content": "oklch(29% 0.03 255)",  // Dark slate blue text, works well with cool tones

          "info": "oklch(69.8% 0.158 238.2)",     // Your brand blue
          "success": "oklch(68% 0.18 160)",        // A clear, accessible green
          "warning": "oklch(82.1% 0.164 88.7)",   // Your brand yellow
          "error": "oklch(66% 0.21 25)"           // A strong, unambiguous red
        },
        "xpando-light-crisp": // xpando-light-crisp
        {
          "primary": "oklch(65.7% 0.224 353.4)", // Your vibrant pink
          "secondary": "oklch(69.8% 0.158 238.2)", // Your electric blue
          "accent": "oklch(82.1% 0.164 88.7)",   // Your golden yellow

          "neutral": "oklch(55% 0.01 262)",       // A neutral mid-grey for borders/secondary text

          "base-100": "oklch(99% 0.003 297)",     // Clean Off-White Background
          "base-200": "oklch(96% 0.006 297)",     // Slightly darker for hover/cards
          "base-300": "oklch(92% 0.009 297)",     // Even darker for active states

          "base-content": "oklch(22.3% 0.011 261.2)", // High-contrast near-black text

          "info": "oklch(69.8% 0.158 238.2)",     // Re-using your brand blue for consistency
          "success": "oklch(68% 0.18 160)",        // A clear, accessible green
          "warning": "oklch(82.1% 0.164 88.7)",   // Re-using your brand yellow
          "error": "oklch(66% 0.21 25)"           // A strong, unambiguous red
        },
        "xpando-light-warm": // xpando-light-warm
        {
          "primary": "oklch(65.7% 0.224 353.4)", // Your vibrant pink
          "secondary": "oklch(69.8% 0.158 238.2)", // Your electric blue
          "accent": "oklch(82.1% 0.164 88.7)",   // Your golden yellow

          "neutral": "oklch(60% 0.02 80)",        // A warm-toned grey for secondary elements

          "base-100": "oklch(99% 0.007 90)",      // Very light, warm cream background
          "base-200": "oklch(95% 0.012 90)",      // Slightly darker warm shade
          "base-300": "oklch(91% 0.018 90)",      // Even darker warm shade

          "base-content": "oklch(30% 0.03 70)",   // Dark, warm sepia/brown text

          "info": "oklch(69.8% 0.158 238.2)",     // Your brand blue (provides nice contrast)
          "success": "oklch(68% 0.18 160)",        // A clear, accessible green
          "warning": "oklch(82.1% 0.164 88.7)",   // Your brand yellow (harmonizes perfectly)
          "error": "oklch(66% 0.21 25)"           // A strong, unambiguous red
        },
        "light": // Light theme - improved readability and visual appeal
        {
          "primary": "oklch(58% 0.18 349.761)",     // More saturated pink for better brand recognition
          "secondary": "oklch(62% 0.12 230.318)",   // Richer blue with better contrast
          "accent": "oklch(65% 0.22 65)",           // Much more vibrant orange-gold with higher saturation
          "neutral": "oklch(45% 0.02 280)",         // Much darker neutral for good contrast when used as background

          "base-100": "oklch(96% 0.007 340)",       // Subtle warm pink tint, sophisticated and modern
          "base-200": "oklch(92% 0.010 340)",       // Gentle pink tint for cards and sections
          "base-300": "oklch(86% 0.014 340)",       // More defined pink-tinted backgrounds

          "base-content": "oklch(15% 0.02 250)",    // Much darker text for excellent readability (WCAG AAA)

          "info": "oklch(52% 0.15 232.661)",        // Stronger info blue
          "success": "oklch(48% 0.15 160)",         // Darker, more accessible green
          "warning": "oklch(62% 0.18 85)",          // More vibrant warning orange
          "error": "oklch(52% 0.18 25)"            // Stronger error red
        },
        "dark": // Dark theme using synthwave colors
        {
          "primary": "oklch(71% 0.202 349.761)",
          "secondary": "oklch(82% 0.111 230.318)",
          "accent": "oklch(75% 0.183 55.934)",
          "neutral": "oklch(45% 0.24 277.023)",
          "base-100": "oklch(15% 0.09 281.288)",
          "base-200": "oklch(20% 0.09 281.288)",
          "base-300": "oklch(25% 0.09 281.288)",
          "base-content": "oklch(78% 0.115 274.713)",
          "info": "oklch(74% 0.16 232.661)",
          "success": "oklch(77% 0.152 181.912)",
          "warning": "oklch(90% 0.182 98.111)",
          "error": "oklch(73.7% 0.121 32.639)"
        }
      }
    ],
    darkTheme: "dark",
    base: true,
    styled: true,
    utils: true,
    prefix: "",
    logs: true,
    themeRoot: ":root",
  },
  plugins: [
    require("@tailwindcss/forms"),
    require("daisyui"),
    // Allows prefixing tailwind classes with LiveView classes to add rules
    // only when LiveView classes are applied, for example:
    //
    //     <div class="phx-click-loading:animate-ping">
    //
    plugin(({ addVariant }) => addVariant("phx-click-loading", [".phx-click-loading&", ".phx-click-loading &"])),
    plugin(({ addVariant }) => addVariant("phx-submit-loading", [".phx-submit-loading&", ".phx-submit-loading &"])),
    plugin(({ addVariant }) => addVariant("phx-change-loading", [".phx-change-loading&", ".phx-change-loading &"])),

    // Embeds Heroicons (https://heroicons.com) into your app.css bundle
    // See your `CoreComponents.icon/1` for more information.
    //
    plugin(function ({ matchComponents, theme }) {
      let iconsDir = path.join(__dirname, "../../../deps/heroicons/optimized")
      let values = {}
      let icons = [
        ["", "/24/outline"],
        ["-solid", "/24/solid"],
        ["-mini", "/20/solid"],
        ["-micro", "/16/solid"]
      ]
      icons.forEach(([suffix, dir]) => {
        fs.readdirSync(path.join(iconsDir, dir)).forEach(file => {
          let name = path.basename(file, ".svg") + suffix
          values[name] = { name, fullPath: path.join(iconsDir, dir, file) }
        })
      })
      matchComponents({
        "hero": ({ name, fullPath }) => {
          let content = fs.readFileSync(fullPath).toString().replace(/\r?\n|\r/g, "")
          let size = theme("spacing.6")
          if (name.endsWith("-mini")) {
            size = theme("spacing.5")
          } else if (name.endsWith("-micro")) {
            size = theme("spacing.4")
          }
          return {
            [`--hero-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
            "-webkit-mask": `var(--hero-${name})`,
            "mask": `var(--hero-${name})`,
            "mask-repeat": "no-repeat",
            "background-color": "currentColor",
            "vertical-align": "middle",
            "display": "inline-block",
            "width": size,
            "height": size
          }
        }
      }, { values })
    })
  ]
}
