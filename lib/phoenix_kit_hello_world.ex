defmodule PhoenixKitHelloWorld do
  @moduledoc """
  A minimal PhoenixKit plugin module — use this as a starting point for your own.

  This module demonstrates every required and commonly-used optional callback from
  the `PhoenixKit.Module` behaviour. Copy this project, rename it, and replace the
  callbacks with your own logic.

  ## How it works

  1. `use PhoenixKit.Module` marks this module as a plugin (persists a
     `@phoenix_kit_module` attribute in the `.beam` file).
  2. PhoenixKit scans `.beam` files at startup and discovers this module
     automatically — no config line needed.
  3. The callbacks below tell PhoenixKit how to integrate the module:
     admin tabs, permissions, enable/disable toggling, etc.

  ## Installation

  Add to your parent app's `mix.exs`:

      {:phoenix_kit_hello_world, "~> 0.1.0"}

  Or for local development:

      {:phoenix_kit_hello_world, path: "../phoenix_kit_hello_world"}

  Then run `mix deps.get`. That's it — the module appears in the admin
  Modules page and sidebar automatically.

  ## What you get for free

  - Admin sidebar tab (appears/disappears when module is toggled)
  - Entry in the admin Modules page with enable/disable toggle
  - Permission key in the roles/permissions matrix
  - Live sidebar updates (no page reload needed when toggling)
  - Route auto-generated at compile time from the `live_view` field

  ## Navigation paths

  All `href` attributes and `redirect/2` calls must go through
  `PhoenixKit.Utils.Routes.path/1` — never use relative paths.
  Create a `Paths` module (e.g., `MyModule.Paths`) that wraps
  `Routes.path/1` to centralize your module's paths in one place.
  See the README for the full pattern.

  ## JavaScript

  External modules cannot inject into the parent app's JS build pipeline.
  All JavaScript must be **inline `<script>` tags** in your templates.
  Register hooks on `window.PhoenixKitHooks` — PhoenixKit spreads this
  into the LiveSocket automatically. See the README for full details.

  ## Callbacks overview

  | Callback                  | Required? | What it does                                      |
  |---------------------------|-----------|---------------------------------------------------|
  | `module_key/0`            | Yes       | Unique string key (used in settings, permissions)  |
  | `module_name/0`           | Yes       | Human-readable name (shown in admin UI)            |
  | `enabled?/0`              | Yes       | Whether the module is currently on                 |
  | `enable_system/0`         | Yes       | Turn the module on (persists to DB)                |
  | `disable_system/0`        | Yes       | Turn the module off (persists to DB)               |
  | `permission_metadata/0`   | No        | Icon, label, description for permissions UI        |
  | `admin_tabs/0`            | No        | Tabs to add to the admin sidebar                   |
  | `settings_tabs/0`         | No        | Tabs to add to the admin settings page             |
  | `children/0`              | No        | Supervisor child specs (GenServers, workers, etc.) |
  | `version/0`               | No        | Version string (default: "0.0.0")                  |
  | `get_config/0`            | No        | Stats/config map shown on the Modules page         |
  | `route_module/0`          | No        | Module providing custom route macros               |
  | `user_dashboard_tabs/0`   | No        | Tabs for the user-facing dashboard                 |
  | `migration_module/0`      | No        | Versioned migration coordinator module             |
  | `required_integrations/0` | No        | Integration provider keys this module needs        |
  | `integration_providers/0` | No        | Custom provider definitions to contribute          |
  """

  use PhoenixKit.Module

  alias PhoenixKit.Dashboard.Tab
  alias PhoenixKit.Settings

  # ===========================================================================
  # Required callbacks
  # ===========================================================================

  @impl PhoenixKit.Module
  @doc "Unique key for this module. Used in settings, permissions, and PubSub events."
  def module_key, do: "hello_world"

  @impl PhoenixKit.Module
  @doc "Display name shown in the admin UI."
  def module_name, do: "Hello World"

  @impl PhoenixKit.Module
  @doc """
  Whether the module is currently enabled.

  Reads from the DB-backed settings table. Defensive against three
  failure modes that can hit before/around DB availability:

  - `rescue _`: DB not running, table missing, schema mismatch, etc.
  - `catch :exit, _`: connection pool checkout `EXIT` (e.g. when a
    test sandbox owner has just stopped — test-environment artifact,
    but harmless to handle in production code too).

  All branches return `false` so callers don't need to special-case
  startup ordering.
  """
  def enabled? do
    Settings.get_boolean_setting("hello_world_enabled", false)
  rescue
    _ -> false
  catch
    :exit, _ -> false
  end

  @impl PhoenixKit.Module
  @doc """
  Enables the module by persisting a boolean setting.

  `update_boolean_setting_with_module/3` stores the value and tracks which
  module owns the setting. The third argument must match `module_key/0`.
  """
  def enable_system do
    Settings.update_boolean_setting_with_module("hello_world_enabled", true, module_key())
  end

  @impl PhoenixKit.Module
  @doc "Disables the module. Same pattern as `enable_system/0`."
  def disable_system do
    Settings.update_boolean_setting_with_module("hello_world_enabled", false, module_key())
  end

  # ===========================================================================
  # Optional callbacks (remove any you don't need — defaults are provided)
  # ===========================================================================

  @impl PhoenixKit.Module
  @doc "Version string. Shown on the admin Modules page."
  def version, do: "0.1.7"

  @impl PhoenixKit.Module
  @doc """
  Permission metadata for the roles/permissions matrix.

  The `:key` MUST match `module_key/0` — PhoenixKit validates this at startup.
  Icons use the `hero-` prefix (Heroicons via `phoenix_heroicons`).

  Return `nil` to opt out of the permissions system entirely (default).
  """
  def permission_metadata do
    %{
      key: module_key(),
      label: "Hello World",
      icon: "hero-hand-raised",
      description: "Demo module showing Hello World in the admin panel"
    }
  end

  @impl PhoenixKit.Module
  @doc """
  Admin sidebar tabs for this module.

  Each tab needs at minimum: `:id`, `:label`, `:path`, `:level`, `:permission`.

  Key fields:
  - `:id` — unique atom across ALL modules (prefix with `:admin_yourmodule`)
  - `:path` — must start with `/admin` and use hyphens, not underscores
  - `:permission` — must match `module_key/0` so custom roles get proper access
  - `:group` — use `:admin_modules` to appear in the Modules section of the sidebar
  - `:priority` — controls sort order (higher = further down). Built-in modules
    use 500-620; use 640+ for external modules
  - `:live_view` — `{Module, :action}` tuple; PhoenixKit auto-generates the route
  - `:icon` — Heroicon name (optional, shown in sidebar)
  - `:match` — `:exact` or `:prefix` for active-state highlighting

  Return `[]` to have no admin tabs (default).
  """
  def admin_tabs do
    [
      # Parent tab — match: :prefix keeps subtabs highlighted on any /hello-world/* page.
      # subtab_display: :when_active shows subtabs only when this module is active.
      %Tab{
        id: :admin_hello_world,
        label: "Hello World",
        icon: "hero-hand-raised",
        path: "hello-world",
        priority: 640,
        level: :admin,
        permission: module_key(),
        match: :prefix,
        group: :admin_modules,
        subtab_display: :when_active,
        highlight_with_subtabs: false,
        live_view: {PhoenixKitHelloWorld.Web.HelloLive, :index}
      },
      # Subtabs — Overview (same path as parent), Events, Components
      %Tab{
        id: :admin_hello_world_overview,
        label: "Overview",
        icon: "hero-hand-raised",
        path: "hello-world",
        priority: 641,
        level: :admin,
        permission: module_key(),
        match: :exact,
        parent: :admin_hello_world,
        live_view: {PhoenixKitHelloWorld.Web.HelloLive, :index}
      },
      %Tab{
        id: :admin_hello_world_events,
        label: "Events",
        icon: "hero-clock",
        path: "hello-world/events",
        priority: 642,
        level: :admin,
        permission: module_key(),
        parent: :admin_hello_world,
        live_view: {PhoenixKitHelloWorld.Web.EventsLive, :index}
      },
      %Tab{
        id: :admin_hello_world_components,
        label: "Components",
        icon: "hero-squares-2x2",
        path: "hello-world/components",
        priority: 643,
        level: :admin,
        permission: module_key(),
        parent: :admin_hello_world,
        live_view: {PhoenixKitHelloWorld.Web.ComponentsLive, :index}
      },
      %Tab{
        id: :admin_hello_world_notifications,
        label: "Notifications",
        icon: "hero-bell-alert",
        path: "hello-world/notifications",
        priority: 644,
        level: :admin,
        permission: module_key(),
        parent: :admin_hello_world,
        live_view: {PhoenixKitHelloWorld.Web.NotificationsLive, :index}
      }
    ]
  end

  @impl PhoenixKit.Module
  @doc "OTP apps whose templates Tailwind should scan for CSS classes."
  def css_sources, do: [:phoenix_kit_hello_world]

  @impl PhoenixKit.Module
  @doc """
  Notification types this module contributes.

  Each type becomes a per-user toggle in notification preferences. `actions`
  maps the activity `action` strings this module emits to the type, so a user
  who mutes "Hello World" stops receiving those notifications. See the
  Notifications admin page (`Web.NotificationsLive`) for the matching senders.
  """
  def notification_types do
    [
      %{
        key: "hello_world",
        label: "Hello World",
        description: "Greetings and demos from the Hello World module",
        actions: ["hello.greeting", "hello.custom"],
        default: true
      }
    ]
  end

  # ===========================================================================
  # Route module (for multi-page modules)
  # ===========================================================================
  #
  # This module has a single admin page, so the `live_view` field on admin_tabs
  # handles routing automatically. If you add more pages (e.g., a form, settings,
  # sub-pages), uncomment this and define your routes in the Routes module:
  #
  #   @impl PhoenixKit.Module
  #   def route_module, do: PhoenixKitHelloWorld.Routes
  #
  # When using route_module, you can REMOVE the `live_view` field from
  # admin_tabs — the Routes module takes over all route registration.
  # See lib/phoenix_kit_hello_world/routes.ex for the full pattern.

  # ===========================================================================
  # Other optional callbacks you can override (shown with their defaults):
  #
  #   def get_config, do: %{enabled: enabled?()}
  #   def settings_tabs, do: []
  #   def user_dashboard_tabs, do: []
  #   def children, do: []
  #   def route_module, do: nil          # see Route module section above
  #   def migration_module, do: nil
  #   def required_integrations, do: []  # e.g., ["google"] or ["openrouter"]
  #   def integration_providers, do: []  # e.g., [%{key: "my_provider", name: "My Provider"}]
  #
  # See the PhoenixKit.Module docs for details on each.
  # ===========================================================================
end
