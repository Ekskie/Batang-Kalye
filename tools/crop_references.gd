extends SceneTree

func _init():
	var p = "C:/Users/Denn/.gemini/antigravity/brain/508450bb-1fe4-4a4d-83ef-1fa766b84a56/reference_public_private.png"
	var img = Image.load_from_file(p)
	var w = img.get_width()
	var h = img.get_height()
	print("Image size: ", w, "x", h)
	
	# Private is the bottom half
	var half_h = h / 2
	var priv_img = Image.create(w, half_h, false, img.get_format())
	priv_img.blit_rect(img, Rect2i(0, half_h, w, half_h), Vector2i(0, 0))
	priv_img.save_png("C:/Users/Denn/.gemini/antigravity/brain/508450bb-1fe4-4a4d-83ef-1fa766b84a56/reference_private_crop.png")
	
	# Public is the top half
	var pub_img = Image.create(w, half_h, false, img.get_format())
	pub_img.blit_rect(img, Rect2i(0, 0, w, half_h), Vector2i(0, 0))
	pub_img.save_png("C:/Users/Denn/.gemini/antigravity/brain/508450bb-1fe4-4a4d-83ef-1fa766b84a56/reference_public_crop.png")
	
	print("Saved reference_private_crop.png and reference_public_crop.png")
	quit()
