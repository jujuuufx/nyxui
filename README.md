# NYX UI Documentation

Welcome to the **NYX UI** (Valley) documentation! This library is designed to be sleek, modern, and easy to implement in your Roblox scripts.

---

## 🚀 Getting Started

To use the NYX UI library, you first need to load it into your environment. You can do this by using `loadstring` or simply by requiring the file if it's stored locally.

```lua
local Valley = loadstring(game:HttpGet("https://raw.githubusercontent.com/jujuuufx/nyxui/refs/heads/main/ui.lua"))()
```

*(Note: Replace the URL with the actual path to your `NYX.lua` if hosting it elsewhere.)*

---

## 🏗️ Core Architecture

The UI is organized into a simple hierarchy:
1. **Window**: The main container.
2. **Tab**: Sidebar categories for different features.
3. **Section**: Grouped boxes within a tab.
4. **Components**: Interactive elements like Toggles, Sliders, and Buttons.

---

## 🖥️ Window Management

### `Valley:Window(properties)`
Creates the main UI window.

**Parameters:**
- `Title` (string): The main name shown in the header.
- `Subtitle` (string): A smaller suffix shown next to the title.
- `Size` (UDim2): The default size of the window (e.g., `UDim2.fromOffset(720, 500)`).

**Example:**
```lua
local Window = Valley:Window({
    Title = "NYX",
    Subtitle = "UI",
    Size = UDim2.fromOffset(720, 500)
})
```

---

## 📂 Navigation (Tabs & Sections)

### `Window:Tab(properties)`
Creates a new button in the sidebar.

**Parameters:**
- `Name` (string): Tab identifier.
- `Icon` (string/id): Roblox asset ID for the icon (e.g., `"rbxassetid://1234567"`).

### `Tab:Section(properties)`
Creates a grouped container within a tab.

**Parameters:**
- `Name` (string): Title of the section.
- `Side` (string): `"Left"` or `"Right"`.

**Example:**
```lua
local MainTab = Window:Tab({ Name = "Main", Icon = "rbxassetid://10723415903" })
local CombatSection = MainTab:Section({ Name = "Combat", Side = "Left" })
```

---

## ⚙️ Interactive Components

All components are added to a **Section**.

### 🔘 Toggle
A switch for turning features on/off.
- `Flag`: (string) Unique ID for config saving.
- `Default`: (boolean) Initial state.
- `Callback`: (function) Runs when toggled.

### 🖱️ Button
A simple clickable button.
- `Name`: (string) Button text.
- `Callback`: (function) Runs when clicked.

### 📏 Slider
A range selector for numbers.
- `Min` / `Max`: (number) The range limits.
- `Default`: (number) Starting value.
- `Increment`: (number) Step size.
- `Suffix`: (string) Text appended to the value (e.g., `"ms"`).

### 📝 Textbox
Input field for text or numbers.
- `Placeholder`: (string) Ghost text when empty.
- `Numeric`: (boolean) If true, only accepts numbers.

### 🔽 Dropdown
A selection menu.
- `Options`: (table) List of items to choose from.
- `Callback`: (function) Returns the selected item.

### 🎨 Colorpicker
A full HSV color selector. Can be chained to a Label or Button.
- `Color`: (Color3) Default color.

### ⌨️ Keybind
Assigns a key to trigger an action.
- `Default`: (Enum.KeyCode) The initial key.

---

## 🛠️ Utilities

### Notifications
Send floating alerts to the screen.
```lua
Valley.Notifications:Create({
    Name = "Exploit Loaded!",
    Lifetime = 3
})
```

### Config & Theme Management
Automatically adds a settings tab with Save/Load/Delete config features and theme customization.
```lua
Valley:Configs(Window)
```

---

## 🌟 Complete Example

```lua
local Valley = loadstring(game:HttpGet("https://raw.githubusercontent.com/jujuuufx/nyxui/refs/heads/main/ui.lua"))()

local Window = Valley:Window({
    Title = "NYX",
    Subtitle = "PREMIUM",
    Size = UDim2.fromOffset(720, 500)
})

local Tab = Window:Tab({ Name = "Combat", Icon = "rbxassetid://10723343306" })
local Section = Tab:Section({ Name = "Aimbot Settings", Side = "Left" })

Section:Toggle({
    Name = "Enabled",
    Flag = "aim_toggle",
    Callback = function(v) print("Aimbot Status:", v) end
})

Section:Slider({
    Name = "Field of View",
    Min = 0, Max = 180, Default = 90,
    Flag = "aim_fov",
    Callback = function(v) print("FOV Set to:", v) end
})

Section:Dropdown({
    Name = "Target Method",
    Options = {"Closest", "Lowest HP", "Prioritize Friends"},
    Default = "Closest",
    Callback = function(v) print("Method:", v) end
})

Valley:Configs(Window) -- Adds the settings & config tab
```
