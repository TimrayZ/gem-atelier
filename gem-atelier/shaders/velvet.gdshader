shader_type canvas_item;
render_mode unshaded;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
	vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void fragment() {
	vec2 p=UV*vec2(980.0,480.0);
	float nap=noise(p*0.22)*0.025+noise(p*0.65)*0.016;
	float fold=sin(p.x*0.012+noise(p*0.008)*2.0)*0.016;
	float light=0.85+0.15*(1.0-length((UV-vec2(0.42,0.3))*0.75));
	vec3 cloth=(vec3(0.135,0.20,0.185)+nap+fold)*light;
	COLOR=vec4(cloth,1.0);
}
