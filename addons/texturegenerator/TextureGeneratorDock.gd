@tool
extends Control

const SAVE_PATH = "res://addons/texturegenerator/apikey.bin"
var API_KEY: String = ""
var url: String = "https://api.openai.com/v1/images/generations"
var temperature: float = 0.5
var requestUrl: HTTPRequest
var requestImage: HTTPRequest
var generatedImageScene;
var imageContainer;

var promptInput: TextEdit
var sizeOption: OptionButton
var generateButton: Button
var apiButton: Button
var apiInput: TextEdit
var modelOption: OptionButton

func _enter_tree():
	promptInput = get_node("GenerateInput")
	sizeOption = get_node("SizeOption")
	generateButton = get_node("GenerateButton")
	apiButton = get_node("APIButton")
	apiInput = get_node("APIInput")
	modelOption = get_node("ModelOption")
	generatedImageScene = preload("res://addons/texturegenerator/GeneratedImage.tscn")
	imageContainer = get_node("ScrollContainer/ImageContainer")
	
	loadAPIKey()
	
	requestUrl = HTTPRequest.new()
	add_child(requestUrl)
	requestUrl.connect("request_completed", _on_request_url_completed)
	
	requestImage = HTTPRequest.new()
	add_child(requestImage)
	requestImage.connect("request_completed", _on_request_image_completed)

func generate_image(prompt): 
	generateButton.disabled = true
	promptInput.editable = false
	var body =  JSON.new().stringify({
		"model": modelOption.text,
		"prompt": prompt,
		"n": 1,
		"size": sizeOption.text,
	})
	var headers = ["Authorization: Bearer " + API_KEY, "Content-Type: application/json"]
	var error = requestUrl.request(url, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		print("There is an error")

func _on_generate_button_pressed():
	if API_KEY != '' and promptInput.text != '':
		print('generating...')
		generate_image(promptInput.text)
	else:
		print("Please input text and/or add a API Key")
	
func _on_api_button_pressed():
	saveAPIKey(apiInput.text)

func _on_request_url_completed(result, responseCode, headers, body):
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var response = json.get_data()
	if "error" in response:
		print(response)
		generateButton.disabled = false
		promptInput.editable = true
		
	var imageUrl = response['data'][0]['url']
	var error = requestImage.request(imageUrl)
	if error != OK:
		print('Error downloading image.')
	
func _on_request_image_completed(result, responseCode, headers, body):
	var image = Image.new()
	var error = image.load_png_from_buffer(body)
	
	if error != OK:
		print("Couldn't load image.")

	var texture = ImageTexture.create_from_image(image)
	
	var generatedImage = generatedImageScene.instantiate()
	imageContainer.add_child(generatedImage)
	generatedImage.set(promptInput.text, texture)

	generateButton.disabled = false
	promptInput.editable = true
	promptInput.text = ""

func saveAPIKey(key):
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	var data: Dictionary = {
		"API_KEY": key
	}
	file.store_line(JSON.stringify(data))
	API_KEY = key

func loadAPIKey():
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if FileAccess.file_exists(SAVE_PATH) == true:
		if not file.eof_reached():
			var current_line = JSON.parse_string(file.get_line())
			if current_line: 
				API_KEY = current_line["API_KEY"]
				apiButton.disabled = true
				apiInput.editable = false
				apiInput.text = current_line["API_KEY"]

func _on_change_api_key_button_pressed():
	apiButton.disabled = false
	apiInput.editable = true


func _on_lock_api_key_button_pressed():
	apiButton.disabled = true
	apiInput.editable = false
