# avocadi

Menu planner for iOS.

## What it does

Avocadi shows a weekly meal plan: for each day, it lists the assigned lunch (*almuerzo*) and dinner (*cena*), each shown as a dish category (e.g. "Legumbre + verduras") with a numbered list of specific dish suggestions to choose from (e.g. "Lentejas guisadas con verduras").

The app opens straight into the week view, with today's day shown first (Monday through Sunday wrap around from there) so you always see what's relevant right now. If the app is left running in the background across midnight, reopening it re-checks the day and scrolls back to today. A floating button appears once you've scrolled down, to jump straight back to the top.

Tapping any dish opens a detail screen with a short description and an illustration, both generated on device with Apple Intelligence and cached so each dish is only generated once.

Three home-screen widgets show the plan without opening the app: a medium one for today's meals, a large one for the next five days, and — from iOS 27 — an extra-large portrait one with today's full menu. The first two list dish categories only; the extra-large one is the first tile tall enough for the dish names themselves. Tapping any of them opens Avocadi scrolled back to today.

## Structure

The menu content lives in [`Menu.json`](Avocadi/Resources/Menu.json), bundled with the app — a fixed set of meals, dish categories, and dishes, plus which category is assigned to each day of the week.

Code shared between the app and the widget is organized by layer at the top level; each screen then lives in its own feature folder:

- **Models** (`Avocadi/Models`) — `Codable` structs mirroring the JSON as-is: `Menu`, `Meal`, `DishCategory`, `Dish`, `Day`.
- **Services** (`Avocadi/Services`) — `MenuLoader` reads and decodes `Menu.json` from the app bundle.
- **ViewModels** (`Avocadi/ViewModels`) — `DayViewModel`/`WeekViewModel` resolve the JSON's id references (which category is assigned to which meal, on which day) into ready-to-display data, and order the week so today comes first; `WeekViewModel.refreshIfNeeded(...)` re-rotates it if "today" has changed since.
- **Week** (`Avocadi/Week`) — `WeekView` (the app's root) lists every day via `DayView`, which in turn renders each meal's assigned category via `DishCategoryView`; it also refreshes the day order (scrolling back to top if it changed) when the app returns to the foreground.
- **DishDetail** (`Avocadi/DishDetail`) — the screen behind tapping a dish, layered behind protocols so its orchestration is testable without SwiftData or the AI frameworks: `DishAIContentStore` persists generated content, `DishDescriptionGenerator` and `DishImageGenerator` wrap Foundation Models and Image Playground, and `DishDetailViewModel` ties them together (cache lookup, regeneration when the description prompt changes, per-section loading state).
- **Widget** (`AvocadiWidget`) — a WidgetKit extension reusing the same models/services/view-models. `AvocadiWidgetProvider.swift` builds the `DayEntry` timeline from `MenuLoader`/`WeekViewModel`, each entry carrying that day's whole rotated week so every widget can read the prefix it needs from the same entries. The three widgets then share that provider and differ only in their views: `AvocadiWidget.swift`/`AvocadiWidgetViews.swift` render today alone (`CompactDayView`), `AvocadiWeekWidget.swift`/`AvocadiWeekWidgetViews.swift` render several days (`WeekAheadView`), `AvocadiDayMenuWidget.swift`/`AvocadiDayMenuWidgetViews.swift` list today's dishes in full (`DayMenuView`), and all three fall back to `EmptyMenuView` if the menu fails to load. A busy day is 16 dish names averaging 65 characters, which fits at a different size on each device, so `DayMenuView` uses `ViewThatFits` to pick the largest of four typographic scales the tile has room for. Its `systemExtraLargePortrait` family only exists from iOS 27 while the rest of the extension targets 26.5, so `AvocadiWidgetBundle` registers that widget behind an availability check.
