# Godot Simple PCG Terrain

A tool that helps to generate 3d terrains using your own generator script.
It does all the hard job of generating 3d mesh with normals, UVs, collision shapes, multiple materials and chunk system 
while you can focus on writing a good generator script

<img src="https://i.imgur.com/zpNxsYH.gif"/>

<img src="https://i.imgur.com/K75yMkr.gif"/>

* Does **not** generate terrain by itself. Instead, it uses your own **custom generator node**, which makes it easier to focus on logic
* Implements **chunk system**
* Uses **tilesheet**
* Supports **multiple materials**
* Height and tile index can be defined separately, which enables **multiple biomes** support
* Has 2 generation modes: with and without using **marching squares**
* 100% **GDscript**

## Why?
Writing a 3d terrain generator (especially with marching squares/cubes implementation) can be hard.
This tool provides a 3d terrain mesh generator with chunk system and lets you focus more on map generation itself

## Usage
A new class called SimplePCGTerrain can be found in "Create New Node" menu under "Spatial".


You also need to write your own *generation node* and specify its path in Inspector.


If you set playerNode in Inspector and dynamicGeneration is active chunks will be dynamically spawned and removed as player moves.

### Parameters

| Name | Type | Description |
| --- | --- | --- |
| generatorNode | String | A path to custom generator node **(required)**|
| dynamicGeneration | bool | Enable/Disable dynamic terrain generation (to follow player controller) |
| chunkLoadRadius | int | A radius within chunks are generated around player controller node |
| mapUpdateTime | float | Time to wait between spawning/removing chunk |
| gridSize | Vector2 | A number of cells which terrain consists of |
| marchingSquares | bool | Enable/Disable marching squares |
| addCollision | bool | Enable/Disable StaticBody generation |
| materials | Array(Material) | Materials to be used for terrain mesh. **Tilesheet can be attached to it as albedo texture** |
| materialFilters | Array(int) | Filter type to be applied for each material (all, whitelist or blacklist) |
| materialValues | Array(String) | List of values for filtering each material **(separated bt comma)** |
| tilesheetSize | Vector2 | A number of horizontal and verical elements on tilesheet |
| tileMargin | Vector2 | Margin around each tile (for fixing floating point errors) |
| offset | Vector3 | An offset to be applied for mesh |

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

### Signals
Chunk system can be further extended to place building/props. For this purpose SimplePCGTerrain node emits 2 signals:

| Signal | Arguments | Description |
| --- | --- | --- |
| chunk_spawned | chunkIndex: Vector2 | Emited when new chunk is added to the scene |
| chunk_removed | chunkIndex: Vector2 | Emited when chunk is removed |


### Example
**Examples can be found in "Example" directory**

**Example.tscn shows the basics of usage**

**Example(MultipleMaterials).tscn is a slightly modified Example.tscn to demonstrate how to use multiple materials**

Also, it is recommended to look at SimpleGenerator.gd. This is a simple map generator made for demonstration purpose. 
It gives a nice example of how "get_height()" and "get_value()" functions in your own generator script could look like.

## TODO

- [ ] Add "How it works" section
- [ ] Fix typos in README
- [ ] Spawn water
- [X] Add support for multiple materials
- [ ] Optimize marching squares algorithm
- [ ] ? Add particles
- [ ] ? Add props scattering
- [ ] ? Add splatmaps as 3rd generation mode

## License
Distributed under the MIT License. See LICENSE for more information
