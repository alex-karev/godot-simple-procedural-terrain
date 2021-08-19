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
# Tilemap
export var tilemapSize: Vector2 = Vector2(2,2)
export var tileSize: Vector2 = Vector2(16,16)
# Additional
export var offset: Vector3 = Vector3(-0.5,0,-0.5)

var origin2d: Vector2
var generator


# Trigs for each cell
# |0  1|
# |2  3|
var cell = PoolRealArray([
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
	origin2d = Vector2(global_transform.origin.x, global_transform.origin.z)
	generator = get_node(generatorNode)
	generate()

#
# Utility Functions
#

# Get value for each trig in cell using marhing squares
func get_trigs_marching(corners: PoolIntArray):
	var trigValues = PoolIntArray()
	# Case 1
	# |1 1|
	# |1 1|
	if corners[0] == corners[1]\
	and corners[0] == corners[2]\
	and corners[0] == corners[3]:
		for _i in range(8):
			trigValues.append(corners[0])
	# Case 2
	# |1 2|
	# |1 1|
	elif corners[0] == corners[2]\
	and corners[0] == corners[3]\
	and corners[0] != corners[1]:
		trigValues.append_array([
			corners[0],corners[0],corners[0],corners[1],
			corners[0],corners[0],corners[0],corners[0]
		])
	# Case 3
	# |2 1|
	# |1 1|
	elif corners[1] == corners[2]\
	and corners[1] == corners[3]\
	and corners[1] != corners[0]:
		trigValues.append_array([
			corners[0],corners[1],corners[1],corners[1],
			corners[1],corners[1],corners[1],corners[1]
		])
	# Case 4
	# |2 2|
	# |1 1|
	elif corners[0] == corners[1]\
	and corners[0] != corners[2]\
	and corners[2] == corners[3]:
		trigValues.append_array([
			corners[0],corners[0],corners[0],corners[0],
			corners[2],corners[2],corners[2],corners[2]
		])
	# Case 5
	# |2 3|
	# |1 1|
	elif corners[0] != corners[1]\
	and corners[0] != corners[2]\
	and corners[2] == corners[3]:
		trigValues.append_array([
			corners[0],corners[2],corners[2],corners[1],
			corners[2],corners[2],corners[2],corners[2]
		])
	# Case 6
	# |1 1|
	# |1 2|
	elif corners[0] == corners[1]\
	and corners[0] == corners[2]\
	and corners[0] != corners[3]:
		trigValues.append_array([
			corners[0],corners[0],corners[0],corners[0],
			corners[0],corners[0],corners[0],corners[3]
		])
	# Case 7
	# |1 2|
	# |1 2|
	elif corners[0] == corners[2]\
	and corners[0] != corners[1]\
	and corners[1] == corners[3]:
		trigValues.append_array([
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
		trigValues.append_array([
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
		trigValues.append_array([
			corners[0],corners[0],corners[0],corners[1],
			corners[1],corners[0],corners[0],corners[0]
		])
	# Case 10
	# |1 1|
	# |2 1|
	elif corners[0] == corners[1]\
	and corners[0] == corners[3]\
	and corners[0] != corners[2]:
		trigValues.append_array([
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
		trigValues.append_array([
			corners[0],corners[0],corners[0],corners[1],
			corners[2],corners[0],corners[0],corners[0]
		])
	# Case 12
	# |2 1|
	# |1 3|
	elif corners[1] == corners[2]\
	and corners[0] != corners[3]:
		trigValues.append_array([
			corners[0],corners[1],corners[1],corners[1],
			corners[1],corners[1],corners[1],corners[3]
		])
	# Case 13
	# |2 1|
	# |3 1|
	elif corners[0] != corners[1]\
	and corners[0] != corners[2]\
	and corners[1] == corners[3]:
		trigValues.append_array([
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
		trigValues.append_array([
			corners[0],corners[0],corners[0],corners[0],
			corners[2],corners[0],corners[0],corners[3]
		])
	# Case 15
	# |1 2|
	# |3 4|
	else:
		trigValues.append_array([
			corners[0],corners[0],corners[1],corners[1],
			corners[2],corners[2],corners[3],corners[3]
		])
	# Return values
	return trigValues
		
# Get value for each trig in cell (no marching squares)
func get_trigs(value:int):
	var trigValues = PoolIntArray()
	for i in range(8):
		trigValues.append(value)
	return trigValues

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
	var faces = PoolVector3Array()
	
	# Create new SurfaceTool
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Change grid size (for marching cubes)
	var newGridSize = gridSize
	if marchingSquares:
		newGridSize -= Vector2.ONE
	
	# Calculate cell size
	var cellSize = Vector3(terrainSize.x/newGridSize.x, 1, terrainSize.y/newGridSize.y)
	var textureSize = Vector2.ONE/tilemapSize
	
	# Loop through grid
	for y in int(newGridSize.y):
		for x in int(newGridSize.x):
			var cellPos = Vector3(x,0,y)
			var cellPos2d = Vector2(x,y)
		
			# Define trig values
			var trigValues = PoolIntArray()
			# Generate values using marching cubes
			if marchingSquares and generator.has_method("get_value"):
				var corners = PoolIntArray()
				var cornerVectors = PoolVector2Array([
					cellPos2d, cellPos2d+Vector2(1,0),
					cellPos2d+Vector2(0,1), cellPos2d+Vector2(1,1)
				])
				for v in cornerVectors:
					corners.append(generator.get_value(v+origin2d))
				trigValues = get_trigs_marching(corners)
			# Generate values using grid
			else:
				var value = 0
				if generator.has_method("get_value"):
					value = generator.get_value(cellPos2d+origin2d)
				trigValues = get_trigs(value)
		
			# Add triangles
			for i in int(cell.size()/2):
				var vert = Vector3(cell[i*2], 0, cell[i*2+1])
				# Add height
				if generator.has_method("get_height"):
					var vert2d = Vector2(vert.x,vert.z)
					var vertPos2d = vert2d + cellPos2d
					vert.y = generator.get_height(vertPos2d+origin2d)
				# Find value
				var trigIndex = floor(i/3)
				var trigValue = trigValues[trigIndex]
				# Calculate UV
				var uvPos = Vector2.ZERO
				uvPos.y = floor(trigValue/tilemapSize.y)
				uvPos.x = uvPos.y + trigValue - uvPos.y
				# Add vertex
				st.add_uv(Vector2(vert.x,vert.z)*textureSize+uvPos*textureSize)
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
		
