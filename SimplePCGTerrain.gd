# Procedural 3d terrain with tilemaps
extends Node3D
class_name SimplePCGTerrain

# Signals
signal chunk_spawned(chunkIndex, chunkNode)
signal chunk_removed(chunkIndex)

# Generator
@export var generatorNode: NodePath
@export var dynamicGeneration: bool = true
@export var playerNode: NodePath
# Chunk System
@export var chunkLoadRadius: int = 0
#export var chunkSize: Vector2 = Vector2(50,50)
@export var mapUpdateTime: float = 0.1
# Grid size (for 1 chunk)
@export var gridSize: Vector2 = Vector2(51,51)
# Enabling/Disabling marching squares
@export var marchingSquares: bool = true
# Physics
@export var addCollision: bool = true
# Material
@export var materials: Array[Material]
enum {ALL, WHITELIST, BLACKLIST}
@export var materialFilters: Array[int]
@export var materialValues: Array[String]
# Tilesheet
@export var tilesheetSize: Vector2 = Vector2(2,2)
@export var tileMargin: Vector2 = Vector2(0.01,0.01)
# Additional
@export var offset: Vector3 = Vector3(-0.5,0,-0.5)

# Generator
var generator
var generatorHasValueFunc:bool = false
var generatorHasHeightFunc:bool = false
var player

# Chunk loading
var chunkLoadQueue = []
var chunkRemoveQueue = []
var loadedChunks = []
var loadedChunkPositions = PackedVector2Array([])

# Second thread
var thread
var threadTime = 0.0
var threadActive = true
var mutex: Mutex
var playerPosition: Vector3 = Vector3.ZERO

# Quad corners
var cornerVectors = PackedVector2Array([
	Vector2.ZERO, Vector2(1,0),
	Vector2(0,1), Vector2(1,1)
])
	
# Trigs for each cell
# |0  1|
# |2  3|
var cell = PackedFloat64Array([
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
	# Find generator
	if generatorNode:
		generator = get_node(generatorNode)
		# Check if generator has value and height functions
		if generator.has_method("get_value"):
			generatorHasValueFunc = true
		if generator.has_method("get_height"):
			generatorHasHeightFunc = true
	# Find player node
	if playerNode:
		player = get_node(playerNode)
	# Create mutex
	mutex = Mutex.new()
	# Create thread
	thread = Thread.new()
	thread.start(map_update.bind(0))

#
# Utility Functions
#

# Get value for each trig in cell using marhing squares
func get_trigs_marching(corners: PackedInt64Array):
	# Case 1
	# |1 1|
	# |1 1|
	if corners[0] == corners[1]\
	and corners[0] == corners[2]\
	and corners[0] == corners[3]:
		return PackedInt64Array([
			corners[0],corners[0],corners[0],corners[0],
			corners[0],corners[0],corners[0],corners[0]
		])
	# Case 2
	# |1 2|
	# |1 1|
	elif corners[0] == corners[2]\
	and corners[0] == corners[3]\
	and corners[0] != corners[1]:
		return PackedInt64Array([
			corners[0],corners[0],corners[0],corners[1],
			corners[0],corners[0],corners[0],corners[0]
		])
	# Case 3
	# |2 1|
	# |1 1|
	elif corners[1] == corners[2]\
	and corners[1] == corners[3]\
	and corners[1] != corners[0]:
		return PackedInt64Array([
			corners[0],corners[1],corners[1],corners[1],
			corners[1],corners[1],corners[1],corners[1]
		])
	# Case 4
	# |2 2|
	# |1 1|
	elif corners[0] == corners[1]\
	and corners[0] != corners[2]\
	and corners[2] == corners[3]:
		return PackedInt64Array([
			corners[0],corners[0],corners[0],corners[0],
			corners[2],corners[2],corners[2],corners[2]
		])
	# Case 5
	# |2 3|
	# |1 1|
	elif corners[0] != corners[1]\
	and corners[0] != corners[2]\
	and corners[2] == corners[3]:
		return PackedInt64Array([
			corners[0],corners[2],corners[2],corners[1],
			corners[2],corners[2],corners[2],corners[2]
		])
	# Case 6
	# |1 1|
	# |1 2|
	elif corners[0] == corners[1]\
	and corners[0] == corners[2]\
	and corners[0] != corners[3]:
		return PackedInt64Array([
			corners[0],corners[0],corners[0],corners[0],
			corners[0],corners[0],corners[0],corners[3]
		])
	# Case 7
	# |1 2|
	# |1 2|
	elif corners[0] == corners[2]\
	and corners[0] != corners[1]\
	and corners[1] == corners[3]:
		return PackedInt64Array([
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
		return PackedInt64Array([
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
		return PackedInt64Array([
			corners[0],corners[0],corners[0],corners[1],
			corners[1],corners[0],corners[0],corners[0]
		])
	# Case 10
	# |1 1|
	# |2 1|
	elif corners[0] == corners[1]\
	and corners[0] == corners[3]\
	and corners[0] != corners[2]:
		return PackedInt64Array([
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
		return PackedInt64Array([
			corners[0],corners[0],corners[0],corners[1],
			corners[2],corners[0],corners[0],corners[0]
		])
	# Case 12
	# |2 1|
	# |1 3|
	elif corners[1] == corners[2]\
	and corners[0] != corners[3]:
		return PackedInt64Array([
			corners[0],corners[1],corners[1],corners[1],
			corners[1],corners[1],corners[1],corners[3]
		])
	# Case 13
	# |2 1|
	# |3 1|
	elif corners[0] != corners[1]\
	and corners[0] != corners[2]\
	and corners[1] == corners[3]:
		return PackedInt64Array([
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
		return PackedInt64Array([
			corners[0],corners[0],corners[0],corners[0],
			corners[2],corners[0],corners[0],corners[3]
		])
	# Case 15
	# |1 2|
	# |3 4|
	else:
		return PackedInt64Array([
			corners[0],corners[0],corners[1],corners[1],
			corners[2],corners[2],corners[3],corners[3]
		])
		
#
# Terrain Generation
#

# Clean from previously generated content
func clean():
	# Remove all nodes
	for child in get_children():
		for subChild in get_children():
			subChild.queue_free()
		child.queue_free()
	# Empty arrays
	loadedChunkPositions = PackedVector2Array([])
	loadedChunks = []
	mutex.lock()
	chunkLoadQueue = []
	chunkRemoveQueue = []
	mutex.unlock()
	# Restart thread
	threadTime = 0
	if not threadActive:
		threadActive = true
		thread.wait_to_finish()
		thread = Thread.new()
		thread.start(map_update.bind(0))

# Generate new surface


# Generate chunk
func generate_chunk(chunkIndex: Vector2):
	var faces = PackedVector3Array()
	var cornerValues = PackedInt64Array()
	var cornerHeights = PackedInt64Array()
	
	# Calculate 2d origin
	var origin2d = chunkIndex * gridSize
	
	# Calculate cell size
	var cellSize = Vector3.ONE
	var textureSize = Vector2.ONE/tilesheetSize
	var tileSize = Vector2.ONE - tileMargin

	# Generate surfaces
	var surfaces = []
	for surfaceIndex in range(materials.size()):
		# Create new SurfaceTool
		var st = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		# Set material
		st.set_material(materials[surfaceIndex])
		# Set material filter
		var filterMode = ALL
		if surfaceIndex < materialFilters.size():
			filterMode = materialFilters[surfaceIndex]
		var filterValues = []
		if surfaceIndex < materialValues.size():
			for val in materialValues[surfaceIndex].replace(" ","").split(","):
				filterValues.append(int(val))
			
		# Loop through grid
		for y in int(gridSize.y):
			for x in int(gridSize.x):
				var cellPos = Vector3(x,0,y)
				var cellPos2d = Vector2(x,y)
			
				# Define trig values
				var trigValues = PackedInt64Array()
				# Generating values using marching squares
				if marchingSquares and generatorHasValueFunc:
					var cellCornerValues = PackedInt64Array()
					if cellPos2d.x == 0 or cellPos2d.y == 0:
						for v in cornerVectors:
							cellCornerValues.append(generator.get_value(v+cellPos2d+origin2d))
					else:
							cellCornerValues.append(cornerValues[(y-1)*gridSize.x*4+x*4+2])
							cellCornerValues.append(cornerValues[(y-1)*gridSize.x*4+x*4+3])
							cellCornerValues.append(cornerValues[y*gridSize.x*4+(x-1)*4+3])
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
					var cellCornerHeights = PackedInt64Array()
					if cellPos2d.x == 0 or cellPos2d.y == 0:
						for v in cornerVectors:
							cellCornerHeights.append(generator.get_height(v+cellPos2d+origin2d))
					else:
							cellCornerHeights.append(cornerHeights[(y-1)*gridSize.x*4+x*4+2])
							cellCornerHeights.append(cornerHeights[(y-1)*gridSize.x*4+x*4+3])
							cellCornerHeights.append(cornerHeights[y*gridSize.x*4+(x-1)*4+3])
							cellCornerHeights.append(generator.get_height(cornerVectors[3]+cellPos2d+origin2d))
					cornerHeights.append_array(cellCornerHeights)
							
				# Add triangles
				for trig in range(8):
					# Find value
					var trigValue = trigValues[0]
					if marchingSquares:
						var trigIndex = trig
						trigValue = trigValues[trigIndex]

					# Filter by values
					if filterMode == WHITELIST:
						if not trigValue in filterValues:
							continue
					elif filterMode == BLACKLIST:
						if trigValue in filterValues:
							continue
					
					# Add vertices
					for i in range(3):
						var vert = Vector3(cell[trig*6+i*2], 0, cell[trig*6+i*2+1])
						# Add height
						if generatorHasHeightFunc:
							var cellIndex = y*gridSize.x*4+x*4
							if vert.x == 0.5 and vert.z == 0.5:
								vert.y = lerp(cornerHeights[cellIndex],cornerHeights[cellIndex+3],0.5)
								vert.y = lerp(vert.y,lerp(cornerHeights[cellIndex+1],cornerHeights[cellIndex+2],0.5),0.5)
							elif vert.x == 0.5:
								vert.y = lerp(cornerHeights[cellIndex+vert.z*2], cornerHeights[cellIndex+vert.z*2+1], 0.5)
							elif vert.z == 0.5:
								vert.y = lerp(cornerHeights[cellIndex+vert.x], cornerHeights[cellIndex+2+vert.x], 0.5)
							else:
								vert.y = cornerHeights[cellIndex+vert.z*2+vert.x]
						# Calculate UV
						var uvPos = Vector2.ZERO
						uvPos.y = floor(trigValue/tilesheetSize.x)
						uvPos.x = trigValue - uvPos.y*tilesheetSize.x
						uvPos += tileMargin/2
						# Add vertex
						st.set_uv(Vector2(vert.x,vert.z)*tileSize*textureSize+uvPos*textureSize)
						var vertex = (vert+cellPos+offset)*cellSize
						st.add_vertex(vertex)
						faces.append(vertex)
					
		# Generate normals and tangents
		st.generate_normals()
		st.generate_tangents()
		# Commit
		surfaces.append(st.commit())
		
	# Add collision
	var collisionShape
	if addCollision:
		var concaveShape = ConcavePolygonShape3D.new()
		concaveShape.set_faces(faces)
		collisionShape = CollisionShape3D.new()
		collisionShape.shape = concaveShape

	mutex.lock()
	chunkLoadQueue.append([surfaces, collisionShape, origin2d, chunkIndex])
	mutex.unlock()

# Remove chunk
func remove_chunk(chunkIndex: int):
	# Free nodes
	var chunk = loadedChunks[chunkIndex]
	for child in chunk.get_children():
		child.queue_free()
	chunk.call_deferred("queue_free")
	# Emit signal
	emit_signal("chunk_removed",loadedChunkPositions[chunkIndex])
	# Remove from array
	loadedChunks.remove_at(chunkIndex)
	loadedChunkPositions.remove_at(chunkIndex)
	

#
# Chunk System
#

# Update map
func map_update(_i):
	while threadActive:
		if threadTime < mapUpdateTime:
			continue
		threadTime = 0.0
		# Define current chunk
		var currentChunk = Vector2.ZERO
		mutex.lock()
		var _playerPosition = playerPosition
		mutex.unlock()
		currentChunk.x = floor(_playerPosition.x/gridSize.x)
		currentChunk.y = floor(_playerPosition.z/gridSize.y)
		# Define needed chunks
		var neededChunks = PackedVector2Array([])
		neededChunks.append(currentChunk)
		if chunkLoadRadius != 0:
			for ring in range(1, chunkLoadRadius+1):
				for x in range(ring*2+1):
					neededChunks.append(Vector2(x-ring,-ring)+currentChunk)
					neededChunks.append(Vector2(x-ring,ring)+currentChunk)
				for y in range(1,ring*2):
					neededChunks.append(Vector2(ring,y-ring)+currentChunk)
					neededChunks.append(Vector2(-ring,y-ring)+currentChunk)
		# Generate needed chunks
		for chunkIndex in neededChunks:
			if not chunkIndex in loadedChunkPositions:
				generate_chunk(chunkIndex)
				break
		# Remove unneeded chunks
		for i in loadedChunkPositions.size():
			var chunkPos = loadedChunkPositions[i]
			if not chunkPos in neededChunks:
				mutex.lock()
				chunkRemoveQueue.append(i)
				mutex.unlock()
				break
		# Finish thread if dynamicGeneration is disabled and generation is done
		if not dynamicGeneration:
			if loadedChunkPositions.size() == neededChunks.size():
				threadActive = false

# Increase threadTime
func _process(delta):
	threadTime += delta
	mutex.lock()
	playerPosition = position
	if player:
		playerPosition = player.position
	if chunkLoadQueue.size() > 0:
		for chunk in chunkLoadQueue:
			var meshInstance = MeshInstance3D.new()
			meshInstance.position.x = chunk[2].x
			meshInstance.position.z = chunk[2].y
			add_child(meshInstance)
			var surfaceIndex = 0
			for surface in chunk[0]:
				if surfaceIndex == 0:
					meshInstance.mesh = surface
				#else:
					#st.commit(meshInstance.mesh)
				surfaceIndex += 1
			if chunk[1]:
				var staticBody = StaticBody3D.new()
				staticBody.add_child(chunk[1])
				meshInstance.add_child(staticBody)
			# Add to loaded
			loadedChunkPositions.append(chunk[3])
			loadedChunks.append(meshInstance)
			emit_signal("chunk_spawned", chunk[3], meshInstance)
		chunkLoadQueue = []
	if chunkRemoveQueue:
		chunkRemoveQueue.sort()
		for chunkIndex in chunkRemoveQueue:
			remove_chunk(chunkIndex)
		chunkRemoveQueue = []
	mutex.unlock()
	
# Close thread on exit
func _exit_tree():
	threadActive = false
	thread.wait_to_finish()
