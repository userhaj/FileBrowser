shader_type canvas_item;

uniform float border_size: hint_range(0.0, 0.5) = 0.05;
uniform vec4 border_color: source_color;

void fragment() {
	vec4 color = COLOR;;
	if (UV.x < border_size || UV.x > 1.0 - border_size || UV.y < border_size || UV.y > 1.0 - border_size) {
		COLOR = border_color;
	}
}

void light() {
	// Called for every pixel for every light affecting the CanvasItem.
}
