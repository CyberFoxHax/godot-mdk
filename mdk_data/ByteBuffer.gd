class_name ByteBuffer

var _data: PackedByteArray
var _position: int = 0
var _positions: Array[int]

func shallow_clone() -> ByteBuffer:
	var buffer = ByteBuffer.new()
	buffer._data = _data
	buffer._position = _position
	return buffer

func _init(data: PackedByteArray = PackedByteArray()):
	_data = data

func get_data() -> PackedByteArray:
	return _data

func get_position() -> int:
	return _position

func set_position(pos: int) -> void:
	_position = pos

func push_position(pos: int) -> void:
	_positions.append(_position)
	_position = pos

func pop_position() -> void:
	_position = _positions.pop_back()

func seek(offset: int) -> void:
	_position = offset

func resize(new_size: int) -> void:
	_data.resize(new_size)

func get_byte() -> int:
	var value = _data[_position]
	_position += 1
	return value

func get_u8() -> int:
	var value = _data[_position]
	_position += 1
	return value

func get_s8() -> int:
	var value = _data.decode_s8(_position)
	_position += 1
	return value

func get_u16() -> int:
	var value = _data.decode_u16(_position)
	_position += 2
	return value

func get_s16() -> int:
	var value = _data.decode_s16(_position)
	_position += 2
	return value

func get_u32() -> int:
	var value = _data.decode_u32(_position)
	_position += 4
	return value

func get_s32() -> int:
	var value = _data.decode_s32(_position)
	_position += 4
	return value

func get_float() -> float:
	var value = _data.decode_float(_position)
	_position += 4
	return value

func get_string() -> String:
	var length = _data.decode_u32(_position)
	_position += 4
	var bytes = _data.slice(_position, _position + length)
	_position += length
	return bytes.get_string_from_utf8()

func get_bytes(length: int) -> PackedByteArray:
	var bytes = _data.slice(_position, _position + length)
	_position += length
	return bytes

func get_chars(length: int) -> String:
	var bytes = _data.slice(_position, _position + length)
	_position += length
	return bytes.get_string_from_ascii().strip_edges(true, false)
