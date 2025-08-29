defmodule XpandoWebWeb.Components.UI.ThemeSwitcher do
  @moduledoc """
  Universal theme switcher component for the xPando application.

  Features:
  - Works consistently across static pages and LiveViews
  - Persists theme preference in localStorage
  - Provides smooth theme transitions
  - Accessible with keyboard navigation
  - Supports multiple themes with easy extensibility
  """

  use Phoenix.Component
  alias Phoenix.LiveView.JS

  attr :id, :string, default: "theme-switcher", doc: "Unique ID for the component"
  attr :class, :string, default: "", doc: "Additional CSS classes"

  @doc """
  Renders a theme switcher dropdown component.
  Uses Phoenix.LiveView.JS for client-side interactions and localStorage for persistence.
  """
  def theme_switcher(assigns) do
    ~H"""
    <div
      id={@id}
      class={["dropdown dropdown-end", @class]}
      phx-hook="UniversalTheme"
      data-storage-key="xpando-theme-preference"
      data-default-theme="dark"
    >
      <div
        tabindex="0"
        role="button"
        class="btn btn-ghost"
        aria-label="Change theme"
        aria-haspopup="true"
        aria-expanded="false"
        id={"#{@id}-button"}
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="h-5 w-5 theme-icon-dark"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
          aria-hidden="true"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z"
          />
        </svg>
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="h-5 w-5 theme-icon-light hidden"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
          aria-hidden="true"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z"
          />
        </svg>
        <span class="hidden sm:inline ml-2">Theme</span>
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
        class="dropdown-content z-[999] menu p-2 shadow-lg bg-base-100 rounded-box w-52 mt-1"
        role="menu"
        aria-label="Theme selection"
      >
        <%= for theme <- available_themes() do %>
          <li role="none">
            <button
              type="button"
              class="justify-between theme-option"
              data-theme-value={theme.value}
              phx-click={apply_theme(theme.value, @id)}
              role="menuitem"
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
                <span>{theme.name}</span>
              </span>
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class={"h-4 w-4 theme-check theme-check-#{theme.value} hidden"}
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
            </button>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end

  # Available themes configuration
  defp available_themes do
    [
      %{
        value: "dark",
        name: "Dark",
        icon_path:
          "M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z"
      },
      %{
        value: "light",
        name: "Light",
        icon_path:
          "M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z"
      }
    ]
  end

  # JS command to apply theme and close dropdown
  defp apply_theme(theme_value, component_id) do
    JS.dispatch("xpando:theme-change",
      detail: %{theme: theme_value},
      to: "##{component_id}"
    )
    |> JS.remove_class("dropdown-open", to: "##{component_id}")
    |> JS.set_attribute({"aria-expanded", "false"}, to: "##{component_id}-button")
  end
end
