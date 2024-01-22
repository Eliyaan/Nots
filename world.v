module main 

@[heap]
struct Chunk {
mut:
	x     i64
	y     i64
	tiles [][]i64 = [][]i64{len: 16, init: []i64{len: 16, init: -1}}
}

fn (mut app App) get_chunk_id_at_coords(x int, y int) int {
	chunk_y := int(math.floor(f64(y) / 16.0))
	chunk_x := int(math.floor(f64(x) / 16.0))
	for i, chunk in app.chunks {
		if chunk.x == chunk_x && chunk.y == chunk_y {
			return i
		}
	}
	app.chunks << Chunk{chunk_x, chunk_y, [][]i64{len: 16, init: []i64{len: 16, init: -1}}}
	return app.chunks.len - 1
}

fn (mut app App) get_tile_id_at(x int, y int) i64 {
	chunk := app.chunks[app.get_chunk_id_at_coords(x, y)]
	return chunk.tiles[math.abs(y - chunk.y * 16)][math.abs(x - chunk.x * 16)]
}

fn (app App) mouse_to_coords(x f32, y f32) (int, int) {
	return int(x) / ceil(tile_size * app.scale), int(y) / ceil(tile_size * app.scale)
}
