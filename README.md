# Godot Simple PCG Terrain

A tool that helps to generate 3d terrains using your own generator script.
It does all the hard job of generating a mesh with normals, UVs and collision shape,
while you can focus on writing a good generator script

<img src="https://i.imgur.com/K75yMkr.gif"/>

* Does **not** generate terrain by itself. Instead, it uses your own **custom generator node**, which makes it easier to focus on logic
* Uses a **tilesheet**
* Height and tile index can be defined separately, which enables **multiple biomes** support
* Has 2 generation modes: with and without using **marching squares**
* 100% **GDscript**

## Why?
Writing a 3d mesh generator for terrain (especially with marching squares/cubes implementation) can be hard and boring.
With this tool a game programmer can skip this part and focus more on map generation

## Usage
A new class called SimplePCGTerrain can be found in "Create New Node" menu under "MeshInstance". It also can be added to the scene from another script. There are some parameters to set:

| Name | Type | Description |
| --- | --- | --- |
| generatorNode | String | A path to custom generator node **(required)**|
| gridSize | Vector2 | A number of cells which terrain consists of |
| terrainSize | Vector2 | A scale of the terrain |
| marchingSquares | bool | Enable/Disable marching squares |
| addCollision | bool | Enable/Disable StaticBody generation |
| tilesheetSize | Vector2 | A number of horizontal and verical elements on tilesheet |
| tileMargin | Vector2 | Margin around each tile (for fixing floating point errors) |
| material | Material | A material to be used for terrain mesh. **Tilesheet can be attached to it as albedo texture** |
| offset | Vector3 | An offset to be applied for mesh |
| generator | Node | Generator node. *Is not displayed in Inspector*. Being set automatically if generatorNode specified. Might be set manually beforer adding terrain to the scene |

### Generator Node
Can be any type of node. A script attached to it should have these 2 functions:

| Type | Function | Description |
| --- | --- | --- |
|int | get_value(pos: *Vector2*) | returns an index of a tile on the tilesheet in a given position |
|float | get_height(pos: *Vector2*) | returns a height of the terrain in a given position |

### Tilesheet
Tile indexes are given from 0 to n in a following order:


|     | Col 1 | Col 2 | Col 3 |
| --- | --- | --- | --- |
| **Row 1** | 0 | 1 | 2 |
| **Row 2** | 3 | 4 | 5 |

A number of rows and columns can be specified using tilesheetSize variable


### Example
**A very simple example of usage can be found in "Example" directory**

## License
Distributed under the MIT License. See LICENSE for more information
