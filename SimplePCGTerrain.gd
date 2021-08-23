# Procedural 3d terrain with tilemaps
extends MeshInstance
class_name SimplePCGTerrain

# Generator
export(NodePath) var generatorNode
# Grid and terrain size
export var gridSize: Vector2 = Vector2(51,51)
export var terrainSize: Vector2 = Vector2(50,50)
export var marchingSquares: bool = true
# Physics
export var addCollision: bool = true
# Material
export var material: Material
# Tilesheet
export var tilesheetSize: Vector2 = Vector2(2,2)
export var tileMargin: Vector2 = Vector2(0.01,0.01)
# Additional
export var offset: Vector3 = Vector3(-0.5,0,-0.5)

var generator

var origin2d: Vector2
var generatorHasValueFunc:bool = false
var generatorHasHeightFunc:bool = false



# Quad corners
const cornerVectors = PoolVector2Array([
	Vector2.ZERO, Vector2(1,0),
	Vector2(0,1), Vector2(1,1)
	])
# Trigs for each cell
# |0  1|
# |2  3|
const cell = PoolRealArray([
	# Quad 0
	# 0
	0,   0,
	0.5, 0,
	0,   0.5,
	# 1
	0,   0.5,
	0.5, 0,
	0.5, 0.5,
	# Quad 1
	# 2
	0.5, 0.5,
	0.5, 0,
	1,   0.5,
	# 3
	1,   0.5,
	0.5, 0,
	1,   0,
	# Quad 2
	# 4
	0,   1,
	0,   0.5,
	0.5, 1,
	# 5
	0.5, 1,
	0,   0.5,
	0.5, 0.5,
	# Quad 3
	# 6
	0.5, 0.5,
	1,   0.5,
	0.5, 1,
	# 7
	0.5, 1,
	1,   0.5,
	1,   1
	])



# Connect to generator and start mesh generation
func _ready():
	if not generator:
		generator = get_node(generatorNode)
	if not mesh:
		generate()

#
# Utility Functions
#

# Get value for each trig in cell using marhing squares
func get_trigs_marching(corners: PoolIntArray):
	# Case 1
	# |1 1|
	# |1 1|
	if corners[0] == corners[1]\
	and corners[0] == corners[2]\
	and corners[0] == corners[3]:
		return PoolIntArray([
			corners[0],corners[0],corners[0],corners[0],
			corners[0],corners[0],corners[0],corners[0]
		])
	# Case 2
	# |1 2|
	# |1 1|
	elif corners[0] == corners[2]\
	and corners[0] == corners[3]\
	and corners[0] != corners[1]:
		return PoolIntArray([
			corners[0],corners[0],corners[0],corners[1],
			corners[0],corners[0],corners[0],corners[0]
		])
	# Case 3
	# |2 1|
	# |1 1|
	elif corners[1] == corners[2]\
	and corners[1] == corners[3]\
	and corners[1] != corners[0]:
		return PoolIntArray([
			corners[0],corners[1],corners[1],corners[1],
			corners[1],corners[1],corners[1],corners[1]
		])
	# Case 4
	# |2 2|
	# |1 1|
	elif corners[0] == corners[1]\
	and corners[0] != corners[2]\
	and corners[2] == corners[3]:
		return PoolIntArray([
			corners[0],corners[0],corners[0],corners[0],
			corners[2],corners[2],corners[2],corners[2]
		])
	# Case 5
	# |2 3|
	# |1 1|
	elif corners[0] != corners[1]\
	and corners[0] != corners[2]\
	and corners[2] == corners[3]:
		return PoolIntArray([
			corners[0],corners[2],corners[2],corners[1],
			corners[2],corners[2],corners[2],corners[2]
		])
	# Case 6
	# |1 1|
	# |1 2|
	elif corners[0] == corners[1]\
	and corners[0] == corners[2]\
	and corners[0] != corners[3]:
		return PoolIntArray([
			corners[0],corners[0],corners[0],corners[0],
			corners[0],corners[0],corners[0],corners[3]
		])
	# Case 7
	# |1 2|
	# |1 2|
	elif corners[0] == corners[2]\
	and corners[0] != corners[1]\
	and corners[1] == corners[3]:
		return PoolIntArray([
			corners[0],corners[0],corners[1],corners[1],
			corners[0],corners[0],corners[1],corners[1]
		])
	# Case 8
	# |1 2|
	# |1 3|
	elif corners[0] == corners[2]\
	and corners[0] != corners[1]\
	and corners[0] != corners[3]\
	and corners[1] != corners[3]:
		return PoolIntArray([
			corners[0],corners[0],corners[0],corners[1],
			corners[0],corners[0],corners[0],corners[3]
		])
	# Case 9
	# |1 2|
	# |2 1|
	elif corners[0] == corners[3]\
	and corners[0] != corners[1]\
	and corners[0] != corners[2]\
	and corners[1] == corners[2]:
		return PoolIntArray([
			corners[0],corners[0],corners[0],corners[1],
			corners[1],corners[0],corners[0],corners[0]
		])
	# Case 10
	# |1 1|
	# |2 1|
	elif corners[0] == corners[1]\
	and corners[0] == corners[3]\
	and corners[0] != corners[2]:
		return PoolIntArray([
			corners[0],corners[0],corners[0],corners[0],
			corners[2],corners[0],corners[0],corners[0]
		])
	# Case 11
	# |1 2|
	# |3 1|
	elif corners[0] == corners[3]\
	and corners[0] != corners[1]\
	and corners[0] != corners[2]\
	and corners[1] != corners[2]:
		return PoolIntArray([
			corners[0],corners[0],corners[0],corners[1],
			corners[2],corners[0],corners[0],corners[0]
		])
	# Case 12
	# |2 1|
	# |1 3|
	elif corners[1] == corners[2]\
	and corners[0] != corners[3]:
		return PoolIntArray([
			corners[0],corners[1],corners[1],corners[1],
			corners[1],corners[1],corners[1],corners[3]
		])
	# Case 13
	# |2 1|
	# |3 1|
	elif corners[0] != corners[1]\
	and corners[0] != corners[2]\
	and corners[1] == corners[3]:
		return PoolIntArray([
			corners[0],corners[1],corners[1],corners[1],
			corners[2],corners[1],corners[1],corners[1]
		])
	# Case 14
	# |1 1|
	# |2 3|
	elif corners[0] == corners[1]\
	and corners[0] != corners[2]\
	and corners[0] != corners[3]\
	and corners[2] != corners[3]:
		return PoolIntArray([
			corners[0],corners[0],corners[0],corners[0],
			corners[2],corners[0],corners[0],corners[3]
		])
	# Case 15
	# |1 2|
	# |3 4|
	else:
		return PoolIntArray([
			corners[0],corners[0],corners[1],corners[1],
			corners[2],corners[2],corners[3],corners[3]
		])
		
#
# Terrain Generation
#

# Clean from previously generated content
func clean():
	for child in get_children():
		child.queue_free()
	mesh = null

# Add collisions
func add_collisions(faces: PoolVector3Array):
	var concaveShape = ConcavePolygonShape.new()
	concaveShape.set_faces(faces)
	var collisionShape = CollisionShape.new()
	collisionShape.shape = concaveShape
	var staticBody = StaticBody.new()
	add_child(staticBody)
	staticBody.add_child(collisionShape)

# Generate terrain
func generate():
	clean()
	origin2d = Vector2(translation.x, translation.z)
	var faces = PoolVector3Array()
	var cornerValues = PoolIntArray()
	var cornerHeights = PoolRealArray()
	
	# Check if generator has value and height functions
	if generator.has_method("get_value"):
		generatorHasValueFunc = true
	if generator.has_method("get_height"):
		generatorHasHeightFunc = true
	
	# Create new SurfaceTool
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Set material
	if material:
		st.set_material(material)
	
	# Change grid size (for marching cubes)
	var newGridSize = gridSize
	if marchingSquares:
		newGridSize -= Vector2.ONE
	
	# Calculate cell size
	var cellSize = Vector3(terrainSize.x/newGridSize.x, 1, terrainSize.y/newGridSize.y)
	var textureSize = Vector2.ONE/tilesheetSize
	var tileSize = Vector2.ONE - tileMargin
	
	# Loop through grid
	for y in int(newGridSize.y):
		for x in int(newGridSize.x):
			var cellPos = Vector3(x,0,y)
			var cellPos2d = Vector2(x,y)
		
			# Define trig values
			var trigValues = PoolIntArray()
			# Generating values using marching squares
			if marchingSquares and generatorHasValueFunc:
				var cellCornerValues = PoolIntArray()
				if cellPos2d.x == 0 or cellPos2d.y == 0:
					for v in cornerVectors:
						cellCornerValues.append(generator.get_value(v+cellPos2d+origin2d))
				else:
						cellCornerValues.append(cornerValues[(y-1)*newGridSize.x*4+x*4+2])
						cellCornerValues.append(cornerValues[(y-1)*newGridSize.x*4+x*4+3])
						cellCornerValues.append(cornerValues[y*newGridSize.x*4+(x-1)*4+3])
						cellCornerValues.append(generator.get_value(cornerVectors[3]+cellPos2d+origin2d))
				cornerValues.append_array(cellCornerValues)
				trigValues = get_trigs_marching(cellCornerValues)
			# Generating values without using marching squares
			else:
				var value = 0
				if generatorHasValueFunc:
					value = generator.get_value(cellPos2d+origin2d)
				trigValues = [value]
		
			# Generating heights
			if generatorHasHeightFunc:
				var cellCornerHeights = PoolRealArray()
				if cellPos2d.x == 0 or cellPos2d.y == 0:
					for v in cornerVectors:
						cellCornerHeights.append(generator.get_height(v+cellPos2d+origin2d))
				else:
						cellCornerHeights.append(cornerHeights[(y-1)*newGridSize.x*4+x*4+2])
						cellCornerHeights.append(cornerHeights[(y-1)*newGridSize.x*4+x*4+3])
						cellCornerHeights.append(cornerHeights[y*newGridSize.x*4+(x-1)*4+3])
						cellCornerHeights.append(generator.get_height(cornerVectors[3]+cellPos2d+origin2d))
				cornerHeights.append_array(cellCornerHeights)
						
			# Add triangles
			for i in int(cell.size()/2.0):
				var vert = Vector3(cell[i*2], 0, cell[i*2+1])
				# Add height
				if generatorHasHeightFunc:
					var cellIndex = y*newGridSize.x*4+x*4
					if vert.x == 0.5 and vert.z == 0.5:
						vert.y = lerp(cornerHeights[cellIndex],cornerHeights[cellIndex+3],0.5)
						vert.y = lerp(vert.y,lerp(cornerHeights[cellIndex+1],cornerHeights[cellIndex+2],0.5),0.5)
					elif vert.x == 0.5:
						vert.y = lerp(cornerHeights[cellIndex+vert.z*2], cornerHeights[cellIndex+vert.z*2+1], 0.5)
					elif vert.z == 0.5:
						vert.y = lerp(cornerHeights[cellIndex+vert.x], cornerHeights[cellIndex+2+vert.x], 0.5)
					else:
						vert.y = cornerHeights[cellIndex+vert.z*2+vert.x]
				# Find value
				var trigValue = trigValues[0]
				if marchingSquares:
					var trigIndex = floor(i/3)
					trigValue = trigValues[trigIndex]
				# Calculate UV
				var uvPos = Vector2.ZERO
				uvPos.y = floor(trigValue/tilesheetSize.x)
				uvPos.x = trigValue - uvPos.y*tilesheetSize.x
				uvPos += tileMargin/2
				# Add vertex
				st.add_uv(Vector2(vert.x,vert.z)*tileSize*textureSize+uvPos*textureSize)
				var vertex = (vert+cellPos+offset)*cellSize
				st.add_vertex(vertex)
				faces.append(vertex)
				
	# Generate normals and tangents
	st.generate_normals()
	st.generate_tangents()
	
	# Commit to a mesh
	mesh = st.commit()
	
	# Add collisions
	if addCollision:
		add_collisions(faces)
		
