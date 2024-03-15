# Quick Item Level

Quick Item Level is a lightweight and efficient World of Warcraft addon that enhances your gameplay experience by providing quick and easy access to item level and class spec information in tooltips. With Quick Item Level, you can instantly view the average item level and specialization of other players by simply hovering over them and viewing the "Quick Item Level" area in the tooltip after the data is fetched by the game.

## Features

- **Instant Item Level Display**: When you mouseover a player, their item level will be immediately displayed in the tooltip, allowing you to quickly assess their gear quality.

- **Specialization Information**: In addition to the item level, Quick Item Level also shows the player's current specialization, giving you a better understanding of their role and playstyle.

- **Efficient Caching**: The addon utilizes an intelligent caching system to store and manage player data efficiently. This ensures that information is readily available and minimizes unnecessary API calls, resulting in improved performance.

- **Automatic Updating**: Quick Item Level automatically updates the item level and specialization information whenever you mouseover a player, ensuring that you always have the most up-to-date data.

- **Lightweight and Non-Intrusive**: Quick Item Level is designed to be lightweight and non-intrusive, seamlessly integrating with the default World of Warcraft UI. It does not clutter your screen with unnecessary information or require complex configuration.

## Installation

1. Download the latest version of Quick Item Level from [CurseForge](https://www.curseforge.com/wow/addons/quick-item-level) or Github. If using CurseForge, no further action is required as the addon will be automatically installed using the CurseForge app.

2. Extract the downloaded ZIP file and place the "QuickItemLevel" folder into your World of Warcraft addons directory (located at `World of Warcraft\_retail_\Interface\AddOns`).

3. Launch World of Warcraft and mouse over players to see their chosen specialization and average item level.

## Usage

Once installed, Quick Item Level will automatically start working whenever you mouseover a player. Simply hover your cursor over a player, and their item level and specialization will be displayed in the tooltip.

## Configuration

Quick Item Level provides configuration options to customize the addon's behavior. You can access the configuration settings through the World of Warcraft UI or by using slash commands.

### Addon Settings

To access the configuration options through the World of Warcraft UI:

1. Open the Main Menu by clicking on the Game Menu button (default: Escape key).
2. Click on "Options" or "System" (depending on your game version).
3. Go to the "AddOns" tab.
4. Find "Quick Item Level" in the addon list and click on it to expand the settings.

The available configuration options are:

- **Cache Size**: Adjusts the maximum number of player inspections to keep in the cache. A higher value will store more data but consume more memory. Default value is 1000.
- **Inspection Delay**: Sets the delay (in seconds) before performing an inspection when mousing over a player. Default value is 0.025 seconds (25ms).
- **Require Shift Key**: When enabled, inspections will only be performed when the Shift key is held down while mousing over a player. Default value is false.

### Slash Commands

Quick Item Level also provides slash commands for quick access to the configuration panel:

- `/qil`: Opens the Quick Item Level configuration panel.
- `/quickitemlevel`: An alternative command to open the configuration panel.

You can use these slash commands to quickly access the configuration options without navigating through the World of Warcraft UI.

## Feedback and Support

If you encounter any issues, have suggestions for improvements, or want to provide feedback, please visit the [Quick Item Level issue tracker](https://github.com/looterz/QuickItemLevel/issues) on GitHub.

## Contribution

If you would like to contribute to the development of Quick Item Level, please feel free to submit pull requests on the [GitHub repository](https://github.com/looterz/QuickItemLevel). We welcome any contributions, whether it's bug fixes, new features, or documentation improvements.

## License

Quick Item Level is released under the [MIT License](https://github.com/looterz/QuickItemLevel/blob/main/LICENSE). You are free to use, modify, and distribute the addon in accordance with the terms of the license.
