defmodule XpandoWebWeb.Components.UI.ThemeSwitcher do
  @moduledoc """
  Theme switcher component using DaisyUI themes.

  Provides theme selection functionality with DaisyUI's built-in theme system.
  Follows Frontend Design Principles with accessible dropdown component.
  """

  use Phoenix.Component

  attr :class, :string, default: "", doc: "Additional CSS classes"
  attr :current_theme, :string, default: "synthwave", doc: "Currently selected theme"

  def theme_switcher(assigns) do
    ~H"""
    <div class={["dropdown dropdown-end", @class]}>
      <div
        tabindex="0"
        role="button"
        class="btn btn-ghost"
        aria-label="Theme selector"
        aria-haspopup="true"
        aria-expanded="false"
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="h-5 w-5"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
          aria-hidden="true"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M7 21a4 4 0 01-4-4V5a2 2 0 012-2h4a2 2 0 012 2v12a4 4 0 01-4 4zM21 5a2 2 0 00-2-2h-4a2 2 0 00-2 2v12a4 4 0 004 4h4a2 2 0 002-2V5z"
          />
        </svg>
        <span class="hidden sm:inline">Theme</span>
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="h-4 w-4 ml-1"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
          aria-hidden="true"
        >
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
        </svg>
      </div>

      <ul
        tabindex="0"
        class="dropdown-content z-[1] menu p-2 shadow-lg bg-base-100 rounded-box w-52"
        role="menu"
        aria-label="Theme options"
      >
        <%= for theme <- available_themes() do %>
          <li role="none">
            <button
              class={[
                "justify-between",
                @current_theme == theme.value && "active"
              ]}
              phx-click="switch_theme"
              phx-value-theme={theme.value}
              role="menuitem"
              data-theme-toggle
              aria-label={"Switch to #{theme.name} theme"}
            >
              <span class="flex items-center gap-2">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-4 w-4"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                  aria-hidden="true"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d={theme.icon_path}
                  />
                </svg>
                {theme.name}
              </span>
              <%= if @current_theme == theme.value do %>
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-4 w-4"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                  aria-hidden="true"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M5 13l4 4L19 7"
                  />
                </svg>
              <% end %>
            </button>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end

  # Available themes with their display names and icons
  defp available_themes do
    [
      %{
        value: "synthwave",
        name: "Dark",
        icon_path:
          "M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z"
      },
      %{
        value: "synthwave-light",
        name: "Light",
        icon_path:
          "M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z"
      }
    ]
  end
end
