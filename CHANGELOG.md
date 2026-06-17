## 0.1.7 - 2026-06-17

### Added
- **Notifications example page** (`Web.NotificationsLive`, new "Notifications" admin subtab) — a hands-on tour of the PhoenixKit notification system: send a notification by logging an activity with a `target_uuid`, customize its display via `notification_text`/`notification_icon`/`notification_link` metadata, and read/manage it (unread count, recent list, mark-seen, dismiss) with live PubSub updates. All core calls are guarded with `Code.ensure_loaded?/1`.
- **`notification_types/0` callback** on `PhoenixKitHelloWorld`, demonstrating how a module declares its notification types so users can mute them in preferences.

### Changed
- Synced the `version/0` callback with `mix.exs` (was stale at 0.1.5).

## 0.1.6 - 2026-05-05

### Changed
- Test schema is now built via `PhoenixKit.Migration.ensure_current/2` in `test_helper.exs` (requires `phoenix_kit ≥ 1.7.105`); removed hand-rolled `test/support/postgres/migrations/` and the `ecto.migrate` step from the `test.setup` alias — schema drift impossible by construction (#15)

## 0.1.5 - 2026-04-29

### Added
- LiveView test infrastructure: in-repo `Test.Endpoint` / `Test.Router` / `Test.Layouts`, `LiveCase` with fake `%Scope{}` plumbing via session, `ActivityLogAssertions` helper, `Hooks.on_mount/4`, and a dedicated test migration creating `phoenix_kit_settings`, `phoenix_kit_activities`, and `uuid_generate_v7()`
- 25 new tests across the three LiveViews (mount, gettext-wrap regressions, `handle_info/2` catch-all smokes, demo-event end-to-end with activity row assertion)
- `mix test.setup` / `mix test.reset` aliases and `lazy_html` test-only dep
- Defensive `handle_info/2` catch-all in all three LiveViews so a stray PubSub broadcast or OTP message can't crash the page with `FunctionClauseError`
- `phx-disable-with` on the "Log demo event" button to prevent double-logging on double-click
- AGENTS.md sections: "What This Module Does NOT Have", "Code Organization: Section-Decomposition Pattern", and full Testing infrastructure walk-through

### Changed
- Decompose `ComponentsLive` 742-line `render/1` into 22 per-section `defp x_section/1` function components for easier navigation; pinned by a section-count test
- Move `enabled?/0` resolution in `HelloLive` from render-time DB call to `handle_params/3` assign — was hitting `Settings.get_boolean_setting/2` four times per page (mount × render × 2 calls), now once per navigation
- Wrap user-facing strings in all three LiveViews with `Gettext.gettext(PhoenixKitWeb.Gettext, …)` (status badges, page headings, filter labels, dt labels in the Module Info / Current User cards, next-steps copy, detail-link `title`, "View details", "All events loaded", `phx-disable-with` text)
- Add `@spec` annotations to all public functions in `PhoenixKitHelloWorld.Paths`

### Fixed
- `enabled?/0` now also `catch :exit, _` — when a sandbox-using test exits and the next test calls `enabled?/0`, the connection-pool checkout `EXIT`s with `"owner #PID<...> exited"`, which `rescue` doesn't catch (was a 1-in-10 flake)
- `test_helper.exs` no longer crashes with `ErlangError :enoent` when `psql` isn't on `$PATH` — falls through to the connect probe so integration tests are gracefully excluded
- Replace tautological "detail-link title is gettext-wrapped" test with a source-grep that actually fails on revert

## 0.1.4 - 2026-04-11

### Fixed
- Correct routing guidance: dynamic path segments ARE supported via tabs
- Add sidebar/socket-crash troubleshooting to README
- Document hidden-tab pattern for CRUD sub-pages
- Clarify route module vs tab-based coexistence

## 0.1.3 - 2026-04-11

### Added
- Add Events subtab with infinite-scroll activity feed filtered to `module: "hello_world"` — universal pattern that works as a drop-in for any module
- Add Components subtab showcasing commonly-used PhoenixKit core components (icons, badges, buttons, alerts, stat cards, form inputs, modals, tables, pagination, empty states, loading states) with copy-paste snippets
- Add "Log demo event" button on Overview page demonstrating the canonical activity logging pattern with `Code.ensure_loaded?/1` guard and rescue handling
- Add `PhoenixKitHelloWorld.Paths` module for centralized path helpers

### Changed
- Restructure `admin_tabs/0` to include parent tab + three subtabs (Overview, Events, Components)
- Bump `phoenix_live_view` dep from `~> 1.0` to `~> 1.1` for consistency with other PhoenixKit modules
- Update `HelloLive` with navigation to the new subtabs and activity logging demo
- Update AGENTS.md with activity logging pattern documentation and expanded file layout

## 0.1.2 - 2026-04-05

### Added
- Add `required_integrations/0` and `integration_providers/0` callbacks to template
- Add tests for new integration callbacks

## 0.1.1 - 2026-04-04

### Fixed
- Fix auto-discovery by adding `phoenix_kit` to `extra_applications`

### Changed
- Update AGENTS.md with standardized sections and auto CSS source compiler docs

## 0.1.0 - 2026-03-24

### Added
- Initial PhoenixKit module template with `PhoenixKit.Module` behaviour
- Admin LiveView page with status dashboard and user info
- Route module template for multi-page modules
- Implement `css_sources/0` for Tailwind CSS scanning support
- Add test infrastructure with dual-level testing (unit + integration)
- Add behaviour compliance test suite
- Comprehensive README documentation covering all PhoenixKit module patterns
