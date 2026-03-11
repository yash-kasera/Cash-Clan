# Cash Clan

Welcome to **Cash Clan**, a comprehensive Roblox game project built with Rojo. This project features a robust procedural world generation system, an integrated economy, dynamic user interfaces, and custom Python tooling for external data visualization.

## 🚀 Features

### Procedural World Generation
- **Terrain Generation**: Complex deterministic terrain generation using Luau.
- **Dynamic Towns**: Towns are procedurally placed on a grid-based system, complete with unique names, bounding boxes, and internal structure plotting (`TownManager`).
- **Structure Spawning**: Buildings and objects to populate the world organically.

### Core Gameplay & Economy
- **Economy System**: Server-sided economy managers for handling currency and shops.
- **Shop & Purchasing Interfaces**: Native UI for buying tools and items.
- **Movement**: Custom player movement including a fly controller for specific modes.

### User Interface & Environment
- **Interactive Maps**: Real-time minimap and a full-screen world map UI for navigation.
- **Lighting Dynamics**: Custom biome-based and stylized lighting tailored to the player's environment.
- **Component Library**: Reusable UI components built natively for Roblox.

### Python Tooling
The `tools/` directory includes specialized Python scripts for visualizing and debugging your 3D world offline.
- **Live Data Bridge** (`bridge.py`): A local HTTP server (port 8081) that listens for telemetry and world dump data from Roblox Studio.
- **World Visualizer** (`visualize_world.py`): Parses JSON data of the Roblox workspace to generate human-readable hierarchies of towns and assets.
- **Telemetry Parsers**: Tools to debug and track the state of the simulation outside of the engine.

## 🛠️ Getting Started

### Prerequisites
- [Rojo](https://rojo.space/docs/) (7.6.1 or later)
- Python 3.x (Optional, for tooling)

### Building the Project
To compile the project into a Roblox place file (`.rbxlx`), use:

```bash
rojo build -o "iitm.rbxlx"
```

Next, open `iitm.rbxlx` in Roblox Studio and start the Rojo live sync server:

```bash
rojo serve
```

### Running the Python Bridge
To debug or visualize the world externally, run the bridge server before sending test dumps from Studio:

```bash
cd tools/
python bridge.py
```
This will start a local server on port 8081 specifically waiting for Roblox Studio telemetry.