extends Polygon2D
class_name CustomStar

func set_star(star_points, radius, inner_radius, set_color: Color=Color.YELLOW, outline_width:float = 0.0, outline_color: Color=Color.BLACK):
	if outline_width > 0:
		self.color = outline_color
		polygon = create_star_points(star_points, radius, inner_radius)
		
		var inner_star = Polygon2D.new()
		inner_star.polygon = create_star_points(star_points, radius - outline_width, inner_radius - outline_width/2)
		inner_star.color = set_color
		add_child(inner_star)
	else:
		self.color = set_color
		polygon = create_star_points(star_points, radius, inner_radius)

func create_star_points(star_points, radius, inner_radius):
	var polygon_points = PackedVector2Array()
	var step = PI / star_points
	for i in range(2 * star_points):
		# Alternate radius between inner and outer points
		var _radius = radius if !i%2 else inner_radius
		# Set angle based on star points on circle radius
		var angle = i * step - PI / 2
		# Create point of star base on current radius
		var polygon_point = Vector2(cos(angle), sin(angle)) * _radius
		polygon_points.append(polygon_point)
	return polygon_points
