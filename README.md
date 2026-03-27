# Quick Item Level

A lightweight World of Warcraft addon that displays player item levels and specializations in tooltips. Hover over any player in the world, on your party or raid frames, your target, focus, or target-of-target to instantly see their gear level and spec.

## Features

- **Item Level & Spec Display**: Hover over any player to see their average item level and current specialization.
- **PvP Item Level Display**: While in PvP content, QuickItemLevel will estimate the players active PvP Item Level.
- **Works on All Unit Frames**: Target, focus, party, raid, and target-of-target frames are all supported.
- **Customizable Tooltip Style**: Choose between Inline Colors, Side by Side, or Stacked Lines.
- **Display Options**: Toggle spec name, item level, and header visibility independently.
- **Efficient LRU Caching**: Configurable cache size and expiration to minimize API calls.
- **Lightweight and Non-Intrusive**: Integrates seamlessly with the default WoW UI.

## Installation

1. Download from [CurseForge](https://www.curseforge.com/wow/addons/quick-item-level) or [GitHub](https://github.com/looterz/QuickItemLevel).
2. Place the `QuickItemLevel` folder in your `Interface\AddOns` directory.
3. Launch WoW and hover over players to see their spec and item level.

## Configuration

Open settings with `/qil` or `/quickitemlevel`, or find it in the AddOns options panel.

### Settings

- **Cache Size**: Max cached inspections. Default: `2500`
- **Inspection Delay**: Seconds before inspecting. Default: `0.025`
- **Cache Expiration**: Seconds before data expires. Default: `600`
- **Require Shift Key**: Only inspect while holding Shift. Default: `Off`
- **Show Specialization**: Show spec in tooltip. Default: `On`
- **Show Item Level**: Show item level in tooltip. Default: `On`
- **Show Header**: Show "Quick Item Level" header. Default: `Off`
- **Tooltip Style**: Inline Colors, Side by Side, or Stacked Lines. Default: `Inline Colors`

## Feedback and Support

Found a bug or have a suggestion? Visit the [issue tracker](https://github.com/looterz/QuickItemLevel/issues) on GitHub.

## Contribution

Pull requests are welcome on the [GitHub repository](https://github.com/looterz/QuickItemLevel).

## License

Released under the [MIT License](https://github.com/looterz/QuickItemLevel/blob/main/LICENSE).
