shader_type canvas_item;
render_mode unshaded;

uniform sampler2D tex;
uniform vec4 color : source_color = vec4(0.0, 1.0, 0.0, 1.0);
uniform float fill : hint_range(0.0, 1.0, 0.01) = 0.5;

void fragment() {
	COLOR = vec4(0.0, 0.0, 1.0, 0.0);//COLOR * color;
}
