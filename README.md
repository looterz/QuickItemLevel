# Quick Item Level

Quick Item Level is a lightweight World of Warcraft addon that displays player item levels and class specializations in tooltips. Hover over any player — in the world, in your party or raid frames, your target, focus, or target-of-target — to instantly see their gear level and spec.

## Features

- **Item Level & Spec Display**: Hover over any player to see their average item level and current specialization directly in the tooltip.

- **Works on All Unit Frames**: Not just mouseover — also works on target, focus, party, raid, and target-of-target frames.

- **Customizable Tooltip Style**: Choose between three display layouts:
  - **Inline Colors** (default) — Spec and item level on one line with class-colored spec and gold item level.
  - **Side by Side** — Spec on the left, item level on the right.
  - **Stacked Lines** — Spec and item level on separate lines.

- **Display Options**: Toggle spec name, item level, and the "Quick Item Level" header independently.

- **Efficient LRU Caching**: Inspection data is cached with configurable size and expiration to minimize API calls and improve performance.

- **Lightweight and Non-Intrusive**: Seamlessly integrates with the default World of Warcraft UI with no extra frames or windows.

## Installation

1. Download the latest version of Quick Item Level from [CurseForge](https://www.curseforge.com/wow/addons/quick-item-level) or [GitHub](https://github.com/looterz/QuickItemLevel). If using CurseForge, no further action is required as the addon will be automatically installed using the CurseForge app.

2. Extract the downloaded ZIP file and place the "QuickItemLevel" folder into your World of Warcraft addons directory (located at `World of Warcraft\_retail_\Interface\AddOns`).

3. Launch World of Warcraft and hover over players to see their specialization and average item level.

## Configuration

Access settings through the World of Warcraft AddOns options panel or by using the slash commands below.

### Slash Commands

- `/qil` — Opens the Quick Item Level configuration panel.
- `/quickitemlevel` — Alternative command to open the configuration panel.

### Settings

| Setting | Description | Default |
|---------|-------------|---------|
| **Cache Size** | Maximum number of player inspections to keep in cache. | 2500 |
| **Inspection Delay** | Delay in seconds before performing an inspection. | 0.025s |
| **Cache Expiration** | Time in seconds before cached data expires and is re-fetched. | 600s |
| **Require Shift Key** | Only inspect players when Shift is held down. | Off |
| **Show Specialization** | Display the player's specialization in the tooltip. | On |
| **Show Item Level** | Display the player's item level in the tooltip. | On |
| **Show Header** | Display the "Quick Item Level" header line above the data. | Off |
| **Tooltip Style** | Choose between Inline Colors, Side by Side, or Stacked Lines. | Inline Colors |

## Feedback and Support

If you encounter any issues, have suggestions for improvements, or want to provide feedback, please visit the [Quick Item Level issue tracker](https://github.com/looterz/QuickItemLevel/issues) on GitHub.

## Contribution

If you would like to contribute to the development of Quick Item Level, please feel free to submit pull requests on the [GitHub repository](https://github.com/looterz/QuickItemLevel). We welcome any contributions, whether it's bug fixes, new features, or documentation improvements.

## License

Quick Item Level is released under the [MIT License](https://github.com/looterz/QuickItemLevel/blob/main/LICENSE). You are free to use, modify, and distribute the addon in accordance with the terms of the license.
