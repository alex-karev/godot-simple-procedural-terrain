# Godot Simple PCG Terrain

A tool that helps to generate terrains using your own generator script.
It does all the hard job of generating a mesh with normals, UVs and collision shape,
while programmer can focus on writing a good generator script

<img src="https://i.imgur.com/K75yMkr.gif"/>

* Does **not** generate terrain by itself. Instead, it can be connected to a **custom generator node**,
making it easier to focus on logic
* Uses grid system and **tilemaps**
* Height and tile index can be defined separately, which makes it able to support **multiple biomes**
* Supports 2 modes: with and without using **marching squares** algorithm
* 100% **GDscript**

## Why?
Writing a 3d mesh generator for terrain (especially with marching squares/cubes implementation) can be hard and boring.
With this tool a game programmer can skip this part and focus more on map generation

## Usage
A new class called SimplePCGTerrain can be found in "Create New Node" menu, but it also can be added to the scene from another script. There are some parameters to set:

* Generator Node: *String* - A path to your custom generator node.
* Grid Size: *Vector2* - A number of cells which terrain consists of
* Terrain Size: *Vector2* - A scale of terrain
* Marching Squares: *bool* - Whether to use or not to use marching squares algorithm
* Add collision: *bool* - Whether to generate StatisBody with CollisionShape
* Tilemap Size: *Vector2* - A number of horizontal and verical elements of tilemap to be used
* Tile Size: *Vector2* - A size of 1 tile in pixels
* Offest: *Vector3* - An offset to be applied for mesh

**REMEMBER** to create a new material in "Material Override" and attach your tilemap to it as an albedo texture

### Generator Node
Can be any type of node. A script attached to it should have these 2 functions:

| Type | Function | Description |
| --- | --- | --- |
|int | get_value(pos: *Vector2*) | returns an index of a tile on the tilemap in a given position |
|float | get_height(pos: *Vector2*) | returns a height of the terrain in a given position |
 
**A very simple example of usage can be found in "Example" directory**

## License
Distributed under the MIT License. See LICENSE for more information
