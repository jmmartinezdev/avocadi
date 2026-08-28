# avocadi

Menu planner for iOS.

## What it does

Avocadi shows a weekly meal plan: for each day, it lists the assigned lunch (*almuerzo*) and dinner (*cena*), each shown as a dish category (e.g. "Legumbre + verduras") with a numbered list of specific dish suggestions to choose from (e.g. "Lentejas guisadas con verduras").

The app opens straight into the week view, with today's day shown first (Monday through Sunday wrap around from there) so you always see what's relevant right now. If the app is left running in the background across midnight, reopening it re-checks the day and scrolls back to today. A floating button appears once you've scrolled down, to jump straight back to the top.

Tapping any dish opens a detail screen with a short description and an illustration, both generated on device with Apple Intelligence and cached so each dish is only generated once. The description is written in whatever language the app is being read in, even though the dish names themselves are always Spanish.

Three home-screen widgets show the plan without opening the app: a medium one for today's meals, a large one for the next five days, and — from iOS 27 — an extra-large portrait one with today's full menu. The first two list dish categories only; the extra-large one is the first tile tall enough for the dish names themselves. Tapping any of them opens Avocadi scrolled back to today.

## Structure

The menu content lives in [`Menu.json`](Avocadi/Resources/Menu.json), bundled with the app — a fixed set of meals, dish categories, and dishes, plus which category is assigned to each day of the week.

Code shared between the app and the widget is organized by layer at the top level; each screen then lives in its own feature folder:

- **Models** (`Avocadi/Models`) — `Codable` structs mirroring the JSON as-is: `Menu`, `Meal`, `DishCategory`, `Dish`, `Day`.
- **Services** (`Avocadi/Services`) — `MenuLoader` reads and decodes `Menu.json` from the app bundle.
- **ViewModels** (`Avocadi/ViewModels`) — `DayViewModel`/`WeekViewModel` resolve the JSON's id references (which category is assigned to which meal, on which day) into ready-to-display data, and order the week so today comes first; `WeekViewModel.refreshIfNeeded(...)` re-rotates it if "today" has changed since.
- **Week** (`Avocadi/Week`) — `WeekView` (the app's root) lists every day via `DayView`, which in turn renders each meal's assigned category via `DishCategoryView`; it also refreshes the day order (scrolling back to top if it changed) when the app returns to the foreground.
- **DishDetail** (`Avocadi/DishDetail`) — the screen behind tapping a dish, layered behind protocols so its orchestration is testable without SwiftData or the AI frameworks: `DishAIContentStore` persists generated content, `DishDescriptionGenerator` and `DishImageGenerator` wrap Foundation Models and Image Playground, and `DishDetailViewModel` ties them together (cache lookup, regeneration when the description prompt changes or the app's language does, per-section loading state).
- **Widget** (`AvocadiWidget`) — a WidgetKit extension reusing the same models/services/view-models. `AvocadiWidgetProvider.swift` builds the `DayEntry` timeline from `MenuLoader`/`WeekViewModel`, each entry carrying that day's whole rotated week so every widget can read the prefix it needs from the same entries. The three widgets then share that provider (and `EmptyMenuView`, the fallback when the menu fails to load) and differ only in their views, so each one lives in its own folder holding its definition and its views: `DaySummaryWidget/` renders today alone (`DaySummaryView`), `WeekWidget/` renders several days (`WeekAheadView`), and `DayFullMenuWidget/` lists today's dishes in full (`DayFullMenuView`). A busy day is 16 dish names averaging 65 characters, which fits at a different size on each device, so `DayFullMenuView` uses `ViewThatFits` to pick the largest of four typographic scales the tile has room for. Its `systemExtraLargePortrait` family only exists from iOS 27 while the rest of the extension targets 26.5, so `AvocadiWidgetBundle` registers that widget behind an availability check.

## Localization

The app is written in English and ships in English, Spanish, Italian, Catalan and Galician, with the strings
in String Catalogs rather than in the code. The app and the widget are separate
bundles, so each has its own `Localizable.xcstrings`; nothing under `Models`,
`ViewModels` or `Services` contains a user-facing string, so there is nothing
shared between them to keep in sync.

The **menu content stays Spanish in both languages**. Dish, category, meal and day
names all come from `Menu.json` and reach the screen as plain `String`s, which
SwiftUI does not localize — only the app's own chrome switches. Text that isn't
copy is kept out of the catalogs with `Text(verbatim:)`: the numbering on dish
lists, and the redacted placeholder lines behind the description shimmer, whose
only job is to have the right widths.

The prompts driving the on-device description live in their own
`DishDetail/Prompts.xcstrings` rather than alongside the UI strings, because they
are not UI copy and are not free to reword: translations must be written natively
in their own language rather than translated sentence-by-sentence, since the model
follows the language of its surrounding context far more reliably than a
"respond in X" directive — and the dish name interpolated into every prompt is
Spanish whatever the app's language, pulling the other way.

That table also holds a `prompt.language.code` entry giving its own language code.
`DishDescriptionGenerator` reads the app's language from there, so the language
stamped onto a cached description is by construction the one its prompt resolved in;
`DishDetailViewModel` compares that stamp alongside `promptVersion` and regenerates
the description — but never the illustration, which isn't language-specific — when
either has changed. Adding a language therefore means adding its
`prompt.language.code`, which `PromptLocalizationTests` enforces.

Apple Intelligence doesn't necessarily write every language the app ships, and which
ones it writes changes between releases — Catalan is the case that prompted this.
Nothing in `SystemLanguageModel.Availability` reports it either: an unsupported
language leaves the model reporting itself available and then throwing on the actual
request. So rather than hardcoding a list, the generator asks `supportsLocale` up
front and, when the app's language isn't supported, generates in Spanish instead —
the language the dish names are already in — stamping the cache `es` so it stays a
plain cache hit afterwards. `DishDetailView` puts a short note
above such a description saying which language it's in and why, because a Catalan
screen holding a Spanish paragraph is otherwise indistinguishable from a bug. If the
model supports nothing the app can use, the description section is simply absent,
exactly as on a device without Apple Intelligence.

The fallback ordering lives in a pure
`FoundationModelsDishDescriptionGenerator.resolveLanguage(appLanguage:contentLanguage:isSupported:)`
because `supportsLocale` needs capable hardware that no simulator has —
`DescriptionLanguageResolutionTests` is the only coverage it can have.
