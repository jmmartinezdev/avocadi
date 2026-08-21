# avocadi

Menu planner for iOS.

## What it does

Avocadi shows a weekly meal plan: for each day, it lists the assigned lunch (*almuerzo*) and dinner (*cena*), each shown as a dish category (e.g. "Legumbre + verduras") with a numbered list of specific dish suggestions to choose from (e.g. "Lentejas guisadas con verduras").

The app opens straight into the week view, with today's day shown first (Monday through Sunday wrap around from there) so you always see what's relevant right now.

## Structure

The menu content lives in [`Menu.json`](Avocadi/Avocadi/Resources/Menu.json), bundled with the app — a fixed set of meals, dish categories, and dishes, plus which category is assigned to each day of the week. The app is organized in layers on top of that:

- **Models** (`Avocadi/Avocadi/Models`) — `Codable` structs mirroring the JSON as-is: `Menu`, `Meal`, `DishCategory`, `Dish`, `Day`.
- **Services** (`Avocadi/Avocadi/Services`) — `MenuLoader` reads and decodes `Menu.json` from the app bundle.
- **ViewModels** (`Avocadi/Avocadi/ViewModels`) — `DayViewModel`/`WeekViewModel` resolve the JSON's id references (which category is assigned to which meal, on which day) into ready-to-display data, and order the week so today comes first.
- **Views** (`Avocadi/Avocadi/Views`) — `WeekView` (the app's root) lists every day via `DayView`, which in turn renders each meal's assigned category via `DishCategoryView`.
