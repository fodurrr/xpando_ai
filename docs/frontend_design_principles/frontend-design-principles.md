# Frontend Design Principles

## AI Persona and Directives

You are an expert frontend software engineer specializing in building maintainable, responsive web applications using Phoenix LiveView, Ash Framework forms, Tailwind CSS, and the Daisy UI component library. Your primary directive is to generate code that strictly adheres to the principles outlined below. All generated code must be idiomatic, clear, and production-ready.

## Core Frontend Principles (Phoenix LiveView + Ash + Daisy UI)

### 1. The "Component-Aware, Utility-Driven" Workflow

This is the non-negotiable workflow for all LiveView UI development.

1. **ALWAYS** start by using a Daisy UI component class if one exists for the UI element you are building (e.g., `class="btn"`, `class="card"`, `class="alert"`).

2. **THEN**, apply Tailwind CSS utility classes to customize the component's layout, spacing, typography, or appearance (e.g., `class="btn btn-primary rounded-full"`).

3. **ONLY** build components from scratch using pure Tailwind utilities if no suitable Daisy UI component exists.

4. **NEVER** write custom CSS files for one-off component styling. All styling must be achieved through utility and component classes in the template files.

#### Bad Example (Pure utility-first for a standard button)

```elixir
# Bad: Recreating what Daisy UI already provides
def button(assigns) do
  ~H"""
  <button class="font-bold py-2 px-4 rounded text-white bg-blue-500 hover:bg-blue-700">
    <%= @label %>
  </button>
  """
end
```

#### Good Example (Correct Workflow)

```elixir
# Good: Using Daisy UI components with Tailwind utilities
def button(assigns) do
  ~H"""
  <button class="btn btn-primary">
    <%= @label %>
  </button>
  """
end

def card(assigns) do
  ~H"""
  <div class="card w-96 bg-base-100 shadow-xl mt-4">
    <div class="card-body p-6">
      <h2 class="card-title text-2xl"><%= @title %></h2>
      <p><%= @content %></p>
    </div>
  </div>
  """
end
```

### 2. Theming and Responsiveness

1. **PREFER** using Daisy UI's semantic theme colors (`primary`, `secondary`, `accent`, `neutral`, `base-100`, etc.) over raw Tailwind colors (`blue-500`, `gray-800`). This ensures components work correctly across all themes (including dark mode).

2. **ALWAYS** build for mobile-first. Apply base styles for the smallest breakpoint and use responsive prefixes (`sm:`, `md:`, `lg:`, `xl:`) to add or override styles for larger screens.

#### Good Example (Responsive and Themed LiveView Component)

```elixir
def album_card(assigns) do
  ~H"""
  <div class="card lg:card-side bg-base-100 shadow-xl">
    <div class="card-body">
      <h2 class="card-title text-primary"><%= @album.title %></h2>
      <p><%= @album.description %></p>
      <div class="card-actions justify-end">
        <button class="btn btn-primary" phx-click="play" phx-value-id={@album.id}>
          Listen
        </button>
      </div>
    </div>
  </div>
  """
end
```

### 3. Common Daisy UI Components Reference

Always check for these Daisy UI components before creating custom ones:

- **Buttons**: `btn`, `btn-primary`, `btn-secondary`, `btn-accent`, `btn-ghost`, `btn-link`
- **Cards**: `card`, `card-body`, `card-title`, `card-actions`
- **Forms**: `input`, `textarea`, `select`, `checkbox`, `radio`, `toggle`, `range`
- **Layout**: `drawer`, `footer`, `hero`, `navbar`, `stack`, `divider`
- **Data Display**: `table`, `badge`, `progress`, `stat`, `avatar`, `countdown`
- **Feedback**: `alert`, `toast`, `modal`, `loading`, `skeleton`
- **Navigation**: `tabs`, `breadcrumbs`, `pagination`, `steps`, `menu`

### 4. Ash Form Handling Best Practices

**ALWAYS** use Ash forms with AshPhoenix helpers, never raw Phoenix forms.

```elixir
# Good: Using Ash forms with Daisy UI components
def user_form(assigns) do
  ~H"""
  <.simple_form
    for={@form}
    id="user-form"
    phx-target={@myself}
    phx-change="validate"
    phx-submit="save"
  >
    <div class="form-control w-full">
      <label class="label">
        <span class="label-text">Email</span>
      </label>
      <.input 
        field={@form[:email]} 
        type="email" 
        class="input input-bordered"
        placeholder="user@example.com"
      />
      <.error field={@form[:email]} class="label-text-alt text-error mt-1" />
    </div>
    
    <div class="form-control w-full">
      <label class="label">
        <span class="label-text">Role</span>
      </label>
      <.input
        field={@form[:role]}
        type="select"
        options={[:user, :node_operator, :admin]}
        class="select select-bordered"
      />
      <.error field={@form[:role]} class="label-text-alt text-error mt-1" />
    </div>
    
    <:actions>
      <button type="submit" class="btn btn-primary" disabled={!@form.source.valid?}>
        Save User
      </button>
    </:actions>
  </.simple_form>
  """
end

# In the LiveView module
def mount(_params, _session, socket) do
  form = 
    XPando.Core.User
    |> AshPhoenix.Form.for_create(:create)
    
  {:ok, assign(socket, form: form)}
end

def handle_event("validate", %{"form" => params}, socket) do
  form = AshPhoenix.Form.validate(socket.assigns.form, params)
  {:noreply, assign(socket, form: form)}
end

def handle_event("save", %{"form" => params}, socket) do
  case AshPhoenix.Form.submit(socket.assigns.form, params: params) do
    {:ok, _user} ->
      {:noreply, 
       socket
       |> put_flash(:info, "User created successfully")
       |> push_navigate(to: ~p"/users")}
       
    {:error, form} ->
      {:noreply, assign(socket, form: form)}
  end
end
```

## Frontend Testing with Playwright MCP Server

### 5. Automated Testing Workflow

Use the Playwright MCP server for comprehensive frontend testing. This provides powerful browser automation capabilities directly within your development environment.

#### Available Playwright MCP Tools

```bash
# Browser Control
mcp__playwright__browser_navigate          # Navigate to URLs
mcp__playwright__browser_snapshot          # Capture accessibility tree
mcp__playwright__browser_take_screenshot   # Visual regression testing
mcp__playwright__browser_click            # Interact with elements
mcp__playwright__browser_type             # Type into inputs
mcp__playwright__browser_fill_form        # Fill multiple form fields

# Testing & Validation
mcp__playwright__browser_evaluate         # Execute JavaScript for assertions
mcp__playwright__browser_wait_for        # Wait for elements/conditions
mcp__playwright__browser_console_messages # Check console errors
mcp__playwright__browser_network_requests # Monitor API calls

# Advanced Features
mcp__playwright__browser_tabs            # Multi-tab testing
mcp__playwright__browser_handle_dialog   # Handle alerts/confirmations
mcp__playwright__browser_file_upload     # Test file uploads
```

#### Testing LiveView Forms Example

```javascript
// 1. Navigate to the LiveView page
mcp__playwright__browser_navigate({ url: "http://localhost:4000/users/new" })

// 2. Take accessibility snapshot for testing
mcp__playwright__browser_snapshot()

// 3. Fill Ash form fields
mcp__playwright__browser_fill_form({
  fields: [
    { name: "Email field", ref: "input[name='form[email]']", type: "textbox", value: "test@example.com" },
    { name: "Role select", ref: "select[name='form[role]']", type: "combobox", value: "node_operator" }
  ]
})

// 4. Submit the form
mcp__playwright__browser_click({
  element: "Save button",
  ref: "button[type='submit']"
})

// 5. Wait for success message
mcp__playwright__browser_wait_for({ text: "User created successfully" })

// 6. Verify no console errors
mcp__playwright__browser_console_messages()
```

### 6. Accessibility Testing

**ALWAYS** ensure your LiveView components are accessible:

1. Use `mcp__playwright__browser_snapshot()` to capture the accessibility tree
2. Verify proper ARIA labels and roles are present
3. Test keyboard navigation with `mcp__playwright__browser_press_key()`
4. Ensure proper focus management in LiveView interactions

#### Accessibility Checklist

- [ ] All interactive elements are keyboard accessible
- [ ] Form inputs have associated labels
- [ ] Images have alt text
- [ ] Color contrast meets WCAG standards
- [ ] ARIA attributes are used correctly
- [ ] Focus indicators are visible
- [ ] LiveView updates announce to screen readers

### 7. Visual Regression Testing

Use screenshots to catch unintended visual changes in LiveView components:

```javascript
// Take baseline screenshot of LiveView component
mcp__playwright__browser_take_screenshot({
  filename: "user-form-baseline.png",
  fullPage: false,
  element: "User form",
  ref: "#user-form"
})

// After LiveView updates
mcp__playwright__browser_wait_for({ text: "Validation error" })

// Take screenshot of error state
mcp__playwright__browser_take_screenshot({
  filename: "user-form-error-state.png",
  element: "User form with errors",
  ref: "#user-form"
})
```

## Phoenix LiveView Component Patterns

### 8. LiveView Component Best Practices

Build reusable LiveView components with Daisy UI:

```elixir
defmodule XpandoWeb.Components.DataTable do
  use Phoenix.Component
  
  attr :rows, :list, required: true
  attr :columns, :list, required: true
  slot :action, doc: "Action buttons for each row"
  
  def data_table(assigns) do
    ~H"""
    <div class="overflow-x-auto">
      <table class="table table-zebra">
        <thead>
          <tr>
            <%= for col <- @columns do %>
              <th><%= col.label %></th>
            <% end %>
            <th :if={@action != []}>Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr :for={row <- @rows}>
            <%= for col <- @columns do %>
              <td><%= Map.get(row, col.field) %></td>
            <% end %>
            <td :if={@action != []}>
              <%= render_slot(@action, row) %>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end
end
```

### 9. Real-time UI Updates with Streams

For real-time features using Phoenix streams:

```elixir
def notification_list(assigns) do
  ~H"""
  <div id="notifications" phx-update="stream" class="space-y-2">
    <div 
      :for={{dom_id, notification} <- @streams.notifications} 
      id={dom_id}
      class="alert alert-info animate-slide-in"
    >
      <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="stroke-current shrink-0 w-6 h-6">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
      </svg>
      <span><%= notification.message %></span>
      <button 
        class="btn btn-sm btn-ghost"
        phx-click="dismiss"
        phx-value-id={notification.id}
      >
        Dismiss
      </button>
    </div>
  </div>
  """
end
```

### 10. Loading States and Skeletons

Implement smooth loading states for async operations:

```elixir
def resource_list(assigns) do
  ~H"""
  <div>
    <!-- Loading state -->
    <div :if={@loading} class="space-y-4">
      <div class="skeleton h-16 w-full"></div>
      <div class="skeleton h-16 w-full"></div>
      <div class="skeleton h-16 w-full"></div>
    </div>
    
    <!-- Loaded content -->
    <div :if={!@loading} class="space-y-4">
      <div :for={resource <- @resources} class="card bg-base-100 shadow">
        <div class="card-body">
          <h3 class="card-title"><%= resource.name %></h3>
          <p><%= resource.description %></p>
        </div>
      </div>
    </div>
  </div>
  """
end
```

## Common LiveView Patterns

### Navigation Component

```elixir
defmodule XpandoWeb.Components.Navigation do
  use Phoenix.Component
  
  def navbar(assigns) do
    ~H"""
    <div class="navbar bg-base-100">
      <div class="navbar-start">
        <div class="dropdown">
          <label tabindex="0" class="btn btn-ghost lg:hidden">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h8m-8 6h16" />
            </svg>
          </label>
          <ul tabindex="0" class="menu menu-sm dropdown-content mt-3 z-[1] p-2 shadow bg-base-100 rounded-box w-52">
            <li><.link navigate={~p"/dashboard"}>Dashboard</.link></li>
            <li><.link navigate={~p"/nodes"}>Nodes</.link></li>
            <li><.link navigate={~p"/users"}>Users</.link></li>
          </ul>
        </div>
        <.link navigate={~p"/"} class="btn btn-ghost text-xl">XPando AI</.link>
      </div>
      <div class="navbar-center hidden lg:flex">
        <ul class="menu menu-horizontal px-1">
          <li><.link navigate={~p"/dashboard"}>Dashboard</.link></li>
          <li><.link navigate={~p"/nodes"}>Nodes</.link></li>
          <li><.link navigate={~p"/users"}>Users</.link></li>
        </ul>
      </div>
      <div class="navbar-end">
        <button class="btn btn-primary" phx-click="show_login">
          Get started
        </button>
      </div>
    </div>
    """
  end
end
```

### Modal Component

```elixir
defmodule XpandoWeb.Components.Modal do
  use Phoenix.Component
  
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  slot :inner_block, required: true
  
  def modal(assigns) do
    ~H"""
    <dialog id={@id} class={["modal", @show && "modal-open"]}>
      <div class="modal-box">
        <%= render_slot(@inner_block) %>
        <div class="modal-action">
          <form method="dialog">
            <button class="btn" phx-click="close_modal" phx-value-id={@id}>
              Close
            </button>
          </form>
        </div>
      </div>
      <form method="dialog" class="modal-backdrop">
        <button phx-click="close_modal" phx-value-id={@id}>close</button>
      </form>
    </dialog>
    """
  end
end
```

### Ash Resource Table with Actions

```elixir
def resource_table(assigns) do
  ~H"""
  <div class="overflow-x-auto">
    <table class="table table-zebra">
      <thead>
        <tr>
          <th>Name</th>
          <th>Status</th>
          <th>Created</th>
          <th>Actions</th>
        </tr>
      </thead>
      <tbody>
        <tr :for={resource <- @resources}>
          <td><%= resource.name %></td>
          <td>
            <span class={["badge", resource.active && "badge-success" || "badge-ghost"]}>
              <%= if resource.active, do: "Active", else: "Inactive" %>
            </span>
          </td>
          <td><%= Calendar.strftime(resource.inserted_at, "%B %d, %Y") %></td>
          <td class="flex gap-2">
            <.link 
              navigate={~p"/resources/#{resource.id}"} 
              class="btn btn-sm btn-ghost"
            >
              View
            </.link>
            <button 
              class="btn btn-sm btn-error"
              phx-click="delete"
              phx-value-id={resource.id}
              data-confirm="Are you sure?"
            >
              Delete
            </button>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
  """
end
```

## Testing Checklist

Before marking any frontend task complete:

- [ ] Component renders correctly on mobile, tablet, and desktop
- [ ] Dark mode works properly (test with Daisy UI theme switcher)
- [ ] Ash forms validate and submit correctly
- [ ] Error states display appropriately
- [ ] Loading states and skeletons show during async operations
- [ ] LiveView interactions work smoothly
- [ ] Accessibility snapshot shows proper structure
- [ ] No console errors in browser
- [ ] WebSocket connections remain stable
- [ ] Keyboard navigation works throughout
- [ ] Visual regression tests pass

---

**Remember**: Always use Phoenix LiveView components with Ash forms, Daisy UI components first, semantic theme colors, and ensure accessibility. Test everything with Playwright MCP tools. The goal is maintainable, responsive, and user-friendly interfaces that leverage the full power of LiveView and Ash Framework.