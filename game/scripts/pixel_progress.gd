extends ProgressBar
func _ready() -> void:
	add_theme_stylebox_override("fill",StyleBoxEmpty.new())
	add_theme_stylebox_override("background",StyleBoxEmpty.new())
	value_changed.connect(func(_v):queue_redraw())
func _draw() -> void:
	var cells := 32
	var cell := floorf(size.x/cells)
	for i in range(cells):
		draw_rect(Rect2(Vector2(i*cell,0),Vector2(cell-2,6)),Color("c9bea1") if float(i)/cells<value/max_value else Color(.24,.27,.24,.65))
