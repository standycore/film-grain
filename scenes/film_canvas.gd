@tool
extends ColorRect

func _on_resized():
	# updates the texture_size parameter of the film grain shader to the control's size
	# this is because there is no built-in way to get the control size inside of a canvas_item shader
	self.material.set_shader_parameter("texture_size", self.size)
