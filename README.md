# avocadi

Menu planner for iOS.

## What it does

Avocadi shows a weekly meal plan: for each day, it lists the assigned lunch (*almuerzo*) and dinner (*cena*), each shown as a dish category (e.g. "Legumbre + verduras") with a numbered list of specific dish suggestions to choose from (e.g. "Lentejas guisadas con verduras").

The app opens straight into the week view, with today's day shown first (Monday through Sunday wrap around from there) so you always see what's relevant right now. If the app is left running in the background across midnight, reopening it re-checks the day and scrolls back to today. A floating button appears once you've scrolled down, to jump straight back to the top.

A home-screen widget shows today's meals (medium size) without opening the app; tapping it opens Avocadi scrolled back to today.

## Structure

The menu content lives in [`Menu.json`](Avocadi/Avocadi/Resources/Menu.json), bundled with the app — a fixed set of meals, dish categories, and dishes, plus which category is assigned to each day of the week. The app is organized in layers on top of that:

- **Models** (`Avocadi/Avocadi/Models`) — `Codable` structs mirroring the JSON as-is: `Menu`, `Meal`, `DishCategory`, `Dish`, `Day`.
- **Services** (`Avocadi/Avocadi/Services`) — `MenuLoader` reads and decodes `Menu.json` from the app bundle.
- **ViewModels** (`Avocadi/Avocadi/ViewModels`) — `DayViewModel`/`WeekViewModel` resolve the JSON's id references (which category is assigned to which meal, on which day) into ready-to-display data, and order the week so today comes first; `WeekViewModel.refreshIfNeeded(...)` re-rotates it if "today" has changed since.
- **Views** (`Avocadi/Avocadi/Views`) — `WeekView` (the app's root) lists every day via `DayView`, which in turn renders each meal's assigned category via `DishCategoryView`; it also refreshes the day order (scrolling back to top if it changed) when the app returns to the foreground.
- **Widget** (`Avocadi/AvocadiWidget`) — a WidgetKit extension reusing the same models/services/view-models. `AvocadiWidgetProvider.swift` builds a rolling window of `DayEntry` timeline entries from `MenuLoader`/`WeekViewModel`; `AvocadiWidgetViews.swift` renders today's meals (`CompactDayView`) or a fallback (`EmptyMenuView`); `AvocadiWidget.swift` holds the widget configuration and its preview.
