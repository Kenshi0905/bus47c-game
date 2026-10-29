extends RefCounted
## Editable typesetting with actual in-game press photographs.
static func text(g, parent: Control, copy: String, at: Vector2, area: Vector2, size: int, centered: bool=false) -> Label:
	var item: Label=g.paper_label(copy,size)
	parent.add_child(item)
	item.position=at
	item.size=area
	if centered:item.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	return item

static func rule(parent: Control, at: Vector2, area: Vector2) -> void:
	var line := ColorRect.new()
	parent.add_child(line)
	line.position=at
	line.size=area
	line.color=Color("555447")
	line.mouse_filter=Control.MOUSE_FILTER_IGNORE

static func photo(parent: Control, path: String, at: Vector2, area: Vector2) -> void:
	var picture := TextureRect.new()
	parent.add_child(picture)
	picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	picture.texture=load(path)
	picture.position=at
	picture.size=area
	var material := ShaderMaterial.new()
	material.shader=preload("res://assets/ui/newsprint.gdshader")
	picture.material=material

static func page(g) -> Control:
	var page := Control.new()
	page.custom_minimum_size=Vector2(800,528)
	page.clip_contents=true
	text(g,page,"THE LOOMESVILLE GAZETTE",Vector2(0,0),Vector2(800,42),39,true)
	rule(page,Vector2(0,48),Vector2(800,2))
	text(g,page,"MORNING EDITION     EST. 1947     LOCAL NEWS     SIX PENCE",Vector2(0,55),Vector2(800,20),14,true)
	rule(page,Vector2(0,80),Vector2(800,1))
	text(g,page,"NIGHT BUS DESTROYED BY FIRE",Vector2(0,90),Vector2(800,42),34,true)
	text(g,page,"No survivors recovered from the last service to Loomesville",Vector2(0,132),Vector2(800,24),17,true)
	rule(page,Vector2(0,165),Vector2(800,1))
	photo(page,"res://assets/ui/press-bus.png",Vector2(0,180),Vector2(520,184))
	text(g,page,"The remains of service 47C. The road remains closed.",Vector2(0,370),Vector2(520,30),13)
	rule(page,Vector2(541,180),Vector2(1,314))
	photo(page,"res://assets/ui/press-portrait.png",Vector2(565,180),Vector2(235,165))
	text(g,page,"POLICE APPEAL",Vector2(565,353),Vector2(235,25),20)
	text(g,page,"Police seek the state firewatcher assigned to Loomesville Forest. Anyone who saw the last service is asked to come forward.",Vector2(565,385),Vector2(235,118),16)
	text(g,page,"By our local correspondent\n\nInvestigators suspect arson after a night bus was found burnt out on the forest road. No survivors were recovered.",Vector2(0,405),Vector2(245,112),15)
	text(g,page,"The service was travelling toward Loomesville. Police have yet to confirm how many passengers were aboard. The driver remains unaccounted for.",Vector2(268,405),Vector2(252,112),15)
	return page

static func world_paper(g, parent: Node3D, at: Vector3) -> void:
	var viewport := SubViewport.new()
	parent.add_child(viewport)
	viewport.size=Vector2i(850,585)
	viewport.disable_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
	var background := ColorRect.new()
	viewport.add_child(background)
	background.size=Vector2(850,585)
	background.color=Color("c6bfa1")
	var content := page(g)
	viewport.add_child(content)
	content.position=Vector2(25,20)
	var paper: MeshInstance3D=g.block(parent,at,Vector3(.68,.014,.51),"b8b093")
	var top := MeshInstance3D.new()
	paper.add_child(top)
	var quad := QuadMesh.new()
	quad.size=Vector2(.68,.51)
	top.mesh=quad
	top.position.y=.0085
	top.rotation.x=-PI/2
	var material := StandardMaterial3D.new()
	material.albedo_texture=viewport.get_texture()
	material.roughness=1.0
	top.material_override=material
