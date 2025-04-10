# Base class simulating an interface for binary-readable objects
class_name BinaryReadable

# Virtual method to be implemented by subclasses
func read(file: ByteBuffer) -> void:
	push_error("Method 'read' must be implemented by subclass!")
	assert(false, "Unimplemented method")
