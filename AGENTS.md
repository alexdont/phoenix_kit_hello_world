# AGENTS.md

This file provides guidance to AI agents when working with code in this repository.

## Project Overview

PhoenixKit plugin module template and showcase — a production-ready example for building PhoenixKit plugin modules. Implements the `PhoenixKit.Module` behaviour for auto-discovery by a parent Phoenix application. Ships with three admin pages that demonstrate the most common patterns:

- **Overview** — Landing page with module info + a "Log demo event" button showing the canonical activity logging pattern
- **Events** — Infinite-scroll activity feed filtered to `module: "hello_world"` (universal pattern, drop-in for any module)
- **Components** — Live showcase of commonly-used PhoenixKit core components with copy-paste snippets

## What This Module Does NOT Have (by design)

This is the canonical template — its job is to demonstrate the minimum viable shape of a PhoenixKit module. It deliberately omits things larger modules need so future copies start lean:

- **No context module** — there is no `PhoenixKitHelloWorld.HelloWorld` business-logic context. Pure presentation; the only "operation" is logging a demo activity event from `HelloLive`. Larger modules (locations, catalogue) add a context module.
- **No Errors dispatcher** — there are no error-returning context functions, so no `PhoenixKitHelloWorld.Errors` atom-to-gettext module. When you build a real module that returns `{:error, :something}` shapes, copy `phoenix_kit_locations/lib/phoenix_kit_locations/errors.ex` as the reference.
- **No Ecto schemas** — no DB-backed data of its own. Larger modules add `lib/<module>/schemas/`.
- **No production migrations** — modules with DB tables get them via core `phoenix_kit`'s versioned migrations (V90+ scheme), not in their own repo.
- **No `actor_opts/1` keyword-list helper** — `HelloLive` uses a simpler `actor_uuid/1` (returns the UUID directly) because the `Activity.log/1` map embeds the value directly. The `actor_opts/1` form returning `[actor_uuid: uuid]` shows up in modules that thread it through context functions accepting `opts \\ []`.

When extending this template into a real module, the order of additions is usually: context module → schemas → Errors dispatcher → `actor_opts/1` helper, in that order. See `phoenix_kit_locations` for the smallest end-to-end reference of all four.

## Common Commands

### Setup & Dependencies

```bash
mix deps.get                # Install dependencies
```

### Testing

```bash
mix test                        # Run all tests
mix test test/phoenix_kit_hello_world_test.exs  # Run specific test file
mix test test/file_test.exs:42  # Run specific test by line
```

### Code Quality

```bash
mix format                  # Format code (imports Phoenix LiveView rules)
mix credo --strict          # Lint / code quality (strict mode)
mix dialyzer                # Static type checking
mix precommit               # compile + format + credo --strict + dialyzer
mix quality                 # format + credo --strict + dialyzer
mix quality.ci              # format --check-formatted + credo --strict + dialyzer
mix docs                    # Generate documentation
```

## Dependencies

This is a **library** (not a standalone Phoenix app) — there is no `config/` directory, no endpoint, no router. The full dependency chain:

- `phoenix_kit` (path: `"../phoenix_kit"`) — provides Module behaviour, Settings, RepoHelper, Dashboard tabs
- `phoenix_live_view` — web framework (LiveView UI)

## Local cross-repo development

`phoenix_kit` (and any sibling `phoenix_kit_*` dep) resolves from Hex by
default. To build or test this module against a **local checkout** of a
dependency — e.g. an unpublished core change — export `<APP>_PATH` and Mix
swaps the Hex pin for a `path:` + `override: true` dep at resolve time:

```bash
PHOENIX_KIT_PATH=../phoenix_kit mix test     # this module against local core
```

The variable name is the dep's app name upper-cased with `_PATH` appended
(`:phoenix_kit` -> `PHOENIX_KIT_PATH`, `:phoenix_kit_ai` ->
`PHOENIX_KIT_AI_PATH`). Set several at once to override multiple deps. **Unset = the
published pin**, so `mix hex.publish` and CI resolve exactly as before.
Implemented via `pk_dep/3` in `mix.exs` — never hand-edit a `phoenix_kit*`
dep into a `path:` tuple (a committed path dep ships a broken package); set
the env var instead.

## Architecture

This is a **PhoenixKit module** that implements the `PhoenixKit.Module` behaviour. It depends on the host PhoenixKit app for Repo, Endpoint, and Settings.

### How It Works

1. Parent app adds this as a dependency in `mix.exs`
2. PhoenixKit scans `.beam` files at startup and auto-discovers modules (zero config)
3. `admin_tabs/0` callback registers admin pages; PhoenixKit generates routes at compile time
4. Settings are persisted via `PhoenixKit.Settings` API (DB-backed in parent app)
5. Permissions are declared via `permission_metadata/0` and checked via `Scope.has_module_access?/2`

### Key Modules

- **`PhoenixKitHelloWorld`** (`lib/phoenix_kit_hello_world.ex`) — Main module implementing `PhoenixKit.Module` behaviour. Declares required callbacks (`module_key`, `module_name`, `enabled?`, `enable_system`, `disable_system`) and optional ones (`admin_tabs`, `permission_metadata`, `get_config`, etc.). Registers 4 admin tabs: parent `:admin_hello_world` + three subtabs (`:admin_hello_world_overview`, `:admin_hello_world_events`, `:admin_hello_world_components`).

- **`PhoenixKitHelloWorld.Paths`** (`lib/phoenix_kit_hello_world/paths.ex`) — Centralized path helpers (`index/0`, `events/0`, `components/0`). All navigation goes through `PhoenixKit.Utils.Routes.path/1` for prefix/locale handling.

- **`PhoenixKitHelloWorld.Web.HelloLive`** (`lib/phoenix_kit_hello_world/web/hello_live.ex`) — Landing page with module info, Scope API demonstration, and the "Log demo event" button showing the canonical activity logging pattern.

- **`PhoenixKitHelloWorld.Web.EventsLive`** (`lib/phoenix_kit_hello_world/web/events_live.ex`) — Activity events feed with infinite scroll, action filtering, and graceful degradation when `PhoenixKit.Activity` isn't loaded. Near-identical to `phoenix_kit_catalogue`'s events tab — this is a universal pattern.

- **`PhoenixKitHelloWorld.Web.ComponentsLive`** (`lib/phoenix_kit_hello_world/web/components_live.ex`) — Live showcase of commonly-used PhoenixKit core components (icons, badges, buttons, alerts, stat cards, form inputs, modals, tables, pagination, empty states, loading states) with copy-paste snippets. **Render is decomposed into per-section function components** — see "Code Organization: Section-Decomposition Pattern" below. The render function is a flat dispatch over 22 `<.x_section />` calls; each section is a private function returning a `<.showcase_section>` block.

### Activity Logging Pattern

The canonical pattern for external modules (see `HelloLive.log_demo_event/1`):

```elixir
defp log_demo_event(socket) do
  if Code.ensure_loaded?(PhoenixKit.Activity) do
    PhoenixKit.Activity.log(%{
      action: "hello_world.demo_event",
      module: "hello_world",
      mode: "manual",
      actor_uuid: actor_uuid(socket),
      resource_type: "hello_world",
      metadata: %{"source" => "showcase_button"}
    })
  else
    :activity_unavailable
  end
rescue
  e ->
    Logger.warning("[HelloWorld] Activity logging error: \#{Exception.message(e)}")
    {:error, e}
end

defp actor_uuid(socket) do
  case socket.assigns[:phoenix_kit_current_user] do
    %{uuid: uuid} -> uuid
    _ -> nil
  end
end
```

Key rules:
- **Guard with `Code.ensure_loaded?/1`** so the module works on hosts without activity logging.
- **Rescue all exceptions** — logging failures must never crash the primary operation.
- **Extract `actor_uuid`** from `socket.assigns[:phoenix_kit_current_user]`.
- **Action format**: `"resource.verb"` (e.g., `"hello_world.demo_event"`).
- **Mode**: `"manual"` for user-triggered, `"auto"` for system/background.

### Code Organization: Section-Decomposition Pattern

`ComponentsLive` demonstrates a pattern worth copying for any LiveView whose render function would otherwise grow past ~150 lines: **flat dispatch from `render/1` to per-section private function components**.

```elixir
def render(assigns) do
  ~H"""
  <div class="...">
    <.icons_section />
    <.badges_section />
    <.modals_section show_modal={@show_modal} show_confirm={@show_confirm} counter={@counter} />
    <.section_divider label="..." />
    <.draggable_list_section items={@draggable_items} />
  </div>
  """
end

defp icons_section(assigns), do: ~H"""<.showcase_section title="Icons" ...>...</.showcase_section>"""
defp badges_section(assigns), do: ~H"""<.showcase_section title="Badges" ...>...</.showcase_section>"""

attr(:show_modal, :boolean, required: true)
attr(:show_confirm, :boolean, required: true)
attr(:counter, :integer, required: true)
defp modals_section(assigns), do: ~H"""..."""
```

Rules:

- **One function per section, in render order.** Lets you jump to a section by name and modify it without scrolling 700 lines of HEEX.
- **Sections that need LV state declare `attr` for each value.** Don't pass the whole `assigns` — be explicit about what the section reads.
- **Stateless sections take no attrs** — they're called as `<.icons_section />`.
- **Stay in one file.** The "single-file showcase" value of a template page (everything visible at once when copy-pasting from the source) is preserved by keeping all sections in the same module. The only thing the decomposition changes is per-function navigability.
- **Small inline helpers like `<.section_divider label="...">` and `<.page_header>` belong with the sections** — they're part of the same dispatch shape.

`ComponentsLive` ended up at 1060 lines after decomposition (was 905 before, with one 742-line render function). Total grew because each section now has function-component plumbing; per-function size dropped from 742 → ~30 (render) and ~25–50 (each section). The win is in maintainability, not in source-line count.

### Settings Keys

`hello_world_enabled`

### File Layout

```
lib/phoenix_kit_hello_world.ex                    # Main module (PhoenixKit.Module behaviour)
lib/phoenix_kit_hello_world/
├── paths.ex                                     # Centralized URL path helpers
├── routes.ex                                    # Route module scaffold (for multi-page modules)
└── web/
    ├── hello_live.ex                            # Overview: module info + activity logging demo
    ├── events_live.ex                           # Activity events feed (infinite scroll)
    └── components_live.ex                       # PhoenixKit core components showcase
```

## Critical Conventions

- **Module key** must be consistent across all callbacks: lowercase with underscores (`"hello_world"`)
- **Tab IDs**: prefixed with `:admin_` (e.g., `:admin_hello_world`)
- **URL paths**: use hyphens, not underscores (`"hello-world"`)
- **Navigation paths**: always use `PhoenixKit.Utils.Routes.path/1`, never relative paths
- **`enabled?/0`**: must rescue errors and return `false` as fallback (DB may not be available)
- **LiveViews**: use `use PhoenixKitWeb, :live_view` which imports PhoenixKit's core components (`<.icon>`, `<.button>`, etc.), Gettext, layout config, and HTML helpers. External modules that use `use Phoenix.LiveView` directly must import helpers explicitly instead.
- **JavaScript hooks**: must be inline `<script>` tags; register on `window.PhoenixKitHooks`
- **LiveView assigns** available in admin pages: `@phoenix_kit_current_scope`, `@current_locale`, `@url_path`

### Commit Message Rules

Start with action verbs: `Add`, `Update`, `Fix`, `Remove`, `Merge`. **Do not include AI attribution or `Co-Authored-By` footers** — Max handles attribution on his own.

### Core Form Primitives

Hello World uses `use PhoenixKitWeb, :live_view` (not `use Phoenix.LiveView` directly), which auto-imports the core form primitives `<.input>`, `<.select>`, `<.textarea>`, `<.checkbox>`, `<.simple_form>` from `PhoenixKitWeb.Components.Core.{Input, Select, Textarea, Checkbox, SimpleForm}`. Use these in every form rather than raw HTML — they handle label wiring, error rendering via `phx-feedback-for`, and daisyUI styling. The `ComponentsLive` "Form helpers" section (the `<.form_helpers_section />` private function) demonstrates this pattern end-to-end.

Modules that use `use Phoenix.LiveView` directly (locations, sync, catalogue, newsletters) need to `import` these explicitly. This template's choice of `PhoenixKitWeb` macros is the simpler default and the recommended starting point.

## Routing: Single Page vs Multi-Page

> ⚠️ **Never hand-register plugin LiveView routes in the parent app's `router.ex`.** PhoenixKit injects module routes into its own `live_session :phoenix_kit_admin` automatically. A hand-written route sits outside that session, which (a) loses the admin layout — `:phoenix_kit_ensure_admin` only applies it inside the session — and (b) crashes the socket on navigation between admin pages (`navigate event failed because you are redirecting across live_sessions`). You cannot work around it by redeclaring `live_session :phoenix_kit_admin` in your router: Phoenix raises on duplicate names. Use `live_view:` on a tab, or a plugin route module. Also note that `:phoenix_kit_ensure_admin` is an **on_mount hook, not a Plug** — it does nothing in `pipe_through`.

**Multi-tab via `live_view:` on each tab** (this template): Each tab in `admin_tabs/0` sets its own `live_view:` field, and PhoenixKit auto-generates a route per tab via `tab_to_route/1` in `phoenix_kit`'s `integration.ex`. **Dynamic path segments are fully supported** — the `path` string is spliced verbatim into the generated `live` route, so `path: "hello-world/:id/edit"` works exactly as you'd expect. The showcase uses this pattern with an Overview, Events, and Components subtab.

For CRUD sub-pages that shouldn't appear in the sidebar (like a new/edit form), add extra tabs with `visible: false` and `parent: :your_parent_tab_id`:

```elixir
%Tab{
  id: :admin_hello_world_edit,
  label: "Edit Hello",
  path: "hello-world/:id/edit",
  parent: :admin_hello_world,
  visible: false,
  live_view: {PhoenixKitHelloWorld.Web.HelloFormLive, :edit}
}
```

See `phoenix_kit_posts/lib/phoenix_kit_posts.ex:213` and `phoenix_kit_catalogue/lib/phoenix_kit_catalogue.ex:198` for real-world examples of this hidden-tab pattern with dynamic segments.

**Route module pattern**: Use a route module (instead of or alongside `admin_tabs/0`) when the tab-based approach isn't expressive enough for your admin LiveView routes — specifically when you want to declare many `live` routes without enumerating each as a Tab, when you need separate localized/non-localized variants with distinct `:as` aliases, or when you want to mix the two patterns (see `phoenix_kit_ai` for a hybrid reference). Steps:

1. Uncomment the routes in `lib/phoenix_kit_hello_world/routes.ex`
2. Uncomment `route_module/0` in the main module
3. Keep or remove the `live_view:` field on `admin_tabs/0` entries as needed — the route module and tab-based routes coexist and both get compiled into `:phoenix_kit_admin`
4. Define admin LiveView routes in both `admin_locale_routes/0` AND `admin_routes/0`

Both functions define the same routes — one for localized paths (`:locale` prefix) and one for non-localized. Every route needs a unique `:as` name (use `_localized` suffix on the localized side).

> **`admin_routes/0` and `admin_locale_routes/0` can only contain `live` declarations.** Their quoted blocks get spliced directly inside Phoenix's `live_session :phoenix_kit_admin do … end` block by `compile_external_admin_routes/1` in `phoenix_kit/lib/phoenix_kit_web/integration.ex:481`, and Phoenix's `live_session` macro rejects controllers (`get`, `post`, …), `forward`, nested `scope`, and `pipe_through` at compile time. For non-LiveView module routes (controllers, API endpoints, WebSocket forwards, catch-all public pages) use `generate/1` or `public_routes/1` on the same route module instead — they splice into different router locations outside any `live_session`. See `phoenix_kit_sync/lib/phoenix_kit_sync/routes.ex` for the controller/`forward` pattern in `generate/1`.

**Catch-all public routes** (`/:slug`, `/:group/*path`): MUST go in `public_routes/1`, NOT `generate/1`. Routes in `generate/1` are placed early and will intercept `/admin/*` paths.

### How route discovery works

Module routes are auto-discovered at compile time — no manual registration needed:

1. `use PhoenixKit.Module` persists a `@phoenix_kit_module` marker in the `.beam` file
2. PhoenixKit's `ModuleDiscovery` scans beam files of deps that depend on `:phoenix_kit`
3. For each discovered module, it calls `route_module/0` to get the route module
4. Admin routes (`admin_routes/0`, `admin_locale_routes/0`) and public routes (`generate/1`, `public_routes/1`) are compiled into the host router via the `phoenix_kit_routes()` macro
5. The host router auto-recompiles when module deps are added or removed (via `__mix_recompile__?/0` hash comparison)

## Tailwind CSS Scanning

Modules with templates using Tailwind classes must implement `css_sources/0` returning their OTP app name as an atom list (e.g., `[:phoenix_kit_hello_world]`). CSS source discovery is **automatic at compile time** — the `:phoenix_kit_css_sources` compiler scans all discovered modules and writes `assets/css/_phoenix_kit_sources.css`. The parent app's `app.css` imports this generated file.

## Database & Migrations

This template module has no database tables. Modules that need DB tables should have their migrations created in the parent `phoenix_kit` project as a new versioned migration (e.g., `V90`).

## Testing

### Setup

This module owns its own test database (`phoenix_kit_hello_world_test`). Schema setup runs core's versioned migrations directly via `PhoenixKit.Migration.ensure_current/2` in `test/test_helper.exs` — no module-owned DDL anywhere. Create the DB once:

```bash
mix test.setup    # ecto.create; test_helper handles the rest on every boot
```

If the DB is absent, integration tests auto-exclude via the `:integration` tag (see `test/test_helper.exs`) — unit tests still run.

The critical config wiring is in `config/test.exs`:

```elixir
config :phoenix_kit, repo: PhoenixKitHelloWorld.Test.Repo
```

Without this, all DB calls through `PhoenixKit.RepoHelper` crash with "No repository configured".

### Test infrastructure

- `test/support/test_repo.ex` — `PhoenixKitHelloWorld.Test.Repo` (Ecto repo for tests)
- `test/support/data_case.ex` — `PhoenixKitHelloWorld.DataCase` (sandbox setup, auto-tags `:integration`)
- `test/support/live_case.ex` — `PhoenixKitHelloWorld.LiveCase` (thin wrapper around `Phoenix.LiveViewTest` with router + endpoint wiring)
- `test/support/test_endpoint.ex` + `test_router.ex` + `test_layouts.ex` — minimal Phoenix plumbing so LiveViews can render under `Phoenix.LiveViewTest.live/2`. **`Test.Layouts.app/1` renders flashes** — required for asserting flash content via `live/2` after click events
- `test/support/activity_log_assertions.ex` — `PhoenixKitHelloWorld.ActivityLogAssertions` (helpers `assert_activity_logged/2` and `refute_activity_logged/2` that query `phoenix_kit_activities` directly with action / actor_uuid / metadata-subset matching)
- `test/test_helper.exs` — calls `PhoenixKit.Migration.ensure_current/2` to apply all core versioned migrations on every boot. **Do not** swap in `Ecto.Migrator.run([{0, PhoenixKit.Migration}], :up, all: true)` — that pattern silently goes stale once `0` is in `schema_migrations` (the inner runner is never re-invoked, so newly-shipped Vxxx migrations don't apply). See `PhoenixKit.Migration.ensure_current/2` moduledoc for the full bug story

### Running tests

```bash
mix test                                          # All tests (excludes :integration if no DB)
mix test test/phoenix_kit_hello_world_test.exs    # Module behaviour tests only
mix test test/phoenix_kit_hello_world/web         # LiveView smoke tests only
for i in $(seq 1 10); do mix test; done           # stability check — catches sandbox/activity-log flakes
```

### Version compliance test

The test file verifies `module_key/0`, `module_name/0`, `version/0`, `permission_metadata/0`, `admin_tabs/0`, and `css_sources/0`.

## Versioning & Releases

This project follows [Semantic Versioning](https://semver.org/).

### Version locations

The version must be updated in **three places** when bumping:

1. `mix.exs` — `@version` module attribute
2. `lib/phoenix_kit_hello_world.ex` — `def version, do: "x.y.z"`
3. `test/phoenix_kit_hello_world_test.exs` — version compliance test

### Tagging & GitHub releases

Tags use **bare version numbers** (no `v` prefix):

```bash
git tag 0.1.0
git push origin 0.1.0
```

GitHub releases are created with `gh release create`:

```bash
gh release create 0.1.0 \
  --title "0.1.0 - 2026-03-24" \
  --notes "$(changelog body for this version)"
```

### Full release checklist

1. Update version in `mix.exs`, `lib/phoenix_kit_hello_world.ex` (`version/0`), and the version test
2. Add changelog entry in `CHANGELOG.md`
3. Run `mix precommit` — ensure zero warnings/errors before proceeding
4. Commit all changes: `"Bump version to x.y.z"`
5. Push to main and **verify the push succeeded** before tagging
6. Create and push git tag: `git tag x.y.z && git push origin x.y.z`
7. Create GitHub release: `gh release create x.y.z --title "x.y.z - YYYY-MM-DD" --notes "..."`

**IMPORTANT:** Never tag or create a release before all changes are committed and pushed. Tags are immutable pointers — tagging before pushing means the release points to the wrong commit.

## Pull Requests

### PR Reviews

PR review files go in `dev_docs/pull_requests/{year}/{pr_number}-{slug}/` directory. Use `{AGENT}_REVIEW.md` naming (e.g., `CLAUDE_REVIEW.md`, `GEMINI_REVIEW.md`).

Severity levels for review findings:

- `BUG - CRITICAL` — Will cause crashes, data loss, or security issues
- `BUG - HIGH` — Incorrect behavior that affects users
- `BUG - MEDIUM` — Edge cases, minor incorrect behavior
- `IMPROVEMENT - HIGH` — Significant code quality or performance issue
- `IMPROVEMENT - MEDIUM` — Better patterns or maintainability
- `NITPICK` — Style, naming, minor suggestions

## Pre-commit Commands

Always run before git commit:

```bash
mix precommit               # compile + format + credo --strict + dialyzer
```

## External Dependencies

- **PhoenixKit** (`~> 1.7`) — Module behaviour, Settings API, shared components, RepoHelper, Activity logging
- **Phoenix LiveView** (`~> 1.1`) — Admin LiveViews
- **lazy_html** (test only) — HTML parser used by `Phoenix.LiveViewTest` for smoke tests

## Two Module Types

- **Full-featured**: Admin tabs, routes, UI, settings (this template)
- **Headless**: Functions/API only, no UI — still gets auto-discovery, toggles, and permissions
