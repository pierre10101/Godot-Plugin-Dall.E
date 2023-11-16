@tool
extends Panel

var outputImage: TextureRect
var promptLabel: Label

func set(prompt, texture):
	outputImage = get_node("OutputImage")
	promptLabel = get_node("PromptLabel")
	
	promptLabel.text = prompt
	outputImage.texture = texture

func _on_save_image_button_pressed():
	var data = outputImage.texture.get_image()
	data.convert(Image.FORMAT_RGBA8)
	data.save_png("res://" + promptLabel.text + ".png")

func _on_delete_image_button_pressed():
	queue_free()
