shader_type canvas_item;
render_mode unshaded;
// Same convex boundary planes as the cut solid, transformed into camera space.
uniform vec4 planes[256];
uniform vec3 facet_centers[256];
uniform int plane_count = 0;
uniform vec2 logical_size = vec2(284.0,207.0);
uniform vec2 center = vec2(142.0, 99.0);
uniform float gem_scale = 1.5;
uniform float refractive_index = 1.746;
uniform float dispersion = 0.012;
uniform float surface_roughness = 0.01;
uniform float scattering_strength = 0.0001;
uniform int illuminant = 0;

// Twenty visible-wavelength bands: fixed material absorption under changing SPD.
uniform int material_id = 0;
uniform float absorption_bands[20];
uniform int max_bounces = 12;
uniform vec2 pixel_footprint = vec2(0.5);
uniform vec4 inclusions[3];
uniform int inclusion_count = 0;
float gaussian(float x, float mean, float width) {return exp(-0.5*pow((x-mean)/width,2.0));}
vec3 observer(float l) {
	// Analytic CIE 1931 matching-function approximation (Wyman et al.).
	float x = 1.056*gaussian(l,599.8,l<599.8?37.9:31.0)+0.362*gaussian(l,442.0,l<442.0?16.0:26.7)-0.065*gaussian(l,501.1,l<501.1?20.4:26.2);
	float y = 0.821*gaussian(l,568.8,l<568.8?46.9:40.5)+0.286*gaussian(l,530.9,l<530.9?16.3:31.1);
	float z = 1.217*gaussian(l,437.0,l<437.0?11.8:36.0)+0.681*gaussian(l,459.0,l<459.0?26.0:13.8);
	return max(vec3(x,y,z),vec3(0.0));
}
float source_spd(float l) {
	float temp = illuminant==1 ? 2850.0 : (illuminant==0 ? 6500.0 : 4500.0);
	float nm = l*0.001;
	return pow(0.56/nm,5.0)*(exp(14387.77/(0.56*temp))-1.0)/(exp(14387.77/(nm*temp))-1.0);
}
// Plain studio: no curtain, floor, folds, rings, texture or scenery in the rays.
// Pixel-art light shapes: few flat light regions, no textured environment.
float environment(vec3 point,vec3 d){
 float broad=step(0.78,dot(d,normalize(vec3(-0.6,-0.7,0.6))));
 float rim=step(0.88,dot(d,normalize(vec3(0.8,-0.25,-0.3))));
 float glint=step(0.985,dot(d,normalize(vec3(-0.20,-0.42,0.88))));
 float sparkle=step(0.988,dot(d,normalize(vec3(0.55,0.25,0.80))));
 float sparkle2=step(0.990,dot(d,normalize(vec3(-0.75,0.32,0.58))));
 float base=0.12+broad*1.65+rim*1.35+glint*6.0+sparkle*5.0+sparkle2*4.5+step(0.72,dot(d,normalize(vec3(0.2,0.65,0.7))))*1.0;
 float left=step(0.78,dot(d,normalize(vec3(-0.82,0.25,0.52))));
 float right=step(0.78,dot(d,normalize(vec3(0.78,-0.15,0.60))));
 float overhead=step(0.82,dot(d,normalize(vec3(0.0,-0.92,0.40))));
 float narrow=step(0.965,dot(d,normalize(vec3(0.55,0.72,0.42))));
 return base+left*0.8+right*0.8+overhead*0.8+narrow*4.0;
}

bool entry_hit(vec3 o, vec3 d, out float distance, out vec3 normal) {
	float near_t = 0.0;
	float far_t = 1000.0;
	normal = vec3(0.0);
	for (int i = 0; i < 256; i++) {
		if (i >= plane_count) break;
		float denom = dot(planes[i].xyz,d);
		float numer = planes[i].w - dot(planes[i].xyz,o);
		if (abs(denom) < 0.00001) {
			if (numer < 0.0) return false;
		} else {
			float t = numer / denom;
			if (denom < 0.0 && t > near_t) {near_t = t; normal = planes[i].xyz;}
			if (denom > 0.0) far_t = min(far_t,t);
		}
	}
	distance = near_t;
	return near_t <= far_t && far_t > 0.0;
}

float fresnel(float cosine, float eta_i, float eta_t) {
	float ci = clamp(cosine,0.0,1.0);
	float st2 = pow(eta_i/eta_t,2.0)*(1.0-ci*ci);
	if (st2 >= 1.0) return 1.0;
	float ct = sqrt(1.0-st2);
	float rs = (eta_i*ci-eta_t*ct)/max(0.00001,eta_i*ci+eta_t*ct);
	float rp = (eta_t*ci-eta_i*ct)/max(0.00001,eta_t*ci+eta_i*ct);
	return 0.5*(rs*rs+rp*rp);
}

float inclusion_path(vec3 point,vec3 ray,float segment) {
	float length_inside=0.0;
	for(int i=0;i<3;i++) {
		if(i>=inclusion_count) break;
		vec3 offset=point-inclusions[i].xyz;
		float b=dot(offset,ray);
		float disc=b*b-dot(offset,offset)+inclusions[i].w*inclusions[i].w;
		if(disc>0.0) {
			float root=sqrt(disc);
			length_inside+=max(0.0,min(segment,-b+root)-max(0.0,-b-root));
		}
	}
	return length_inside;
}
float transport(vec3 point, vec3 incident, vec3 normal, float ri, float sigma) {
	float entry_f = fresnel(-dot(incident,normal),1.0,ri);
	float radiance = environment(point,reflect(incident,normal))*entry_f;
	float energy = 1.0-entry_f;
	vec3 ray = refract(incident,normal,1.0/ri);
	point += ray*0.003;
	for(int bounce=0;bounce<20;bounce++) {
		if(bounce>=max_bounces) break;
		float nearest=10000.0;
		vec3 n=vec3(0.0);
		for(int i=0;i<256;i++) {
			if(i>=plane_count) break;
			float denom=dot(planes[i].xyz,ray);
			if(denom>0.00001) {
				float t=(planes[i].w-dot(planes[i].xyz,point))/denom;
				if(t>0.0001 && t<nearest) {nearest=t;n=planes[i].xyz;}
			}
		}
		if(nearest>9999.0) break;
		float inclusion_depth=inclusion_path(point,ray,nearest)*0.35;
		float transmittance=exp(-(sigma+scattering_strength)*nearest-inclusion_depth);
		radiance+=energy*(1.0-exp(-inclusion_depth))*0.12;
		// Single-scattering approximation, with the same extinction budget.
		radiance+=energy*(1.0-transmittance)*scattering_strength/max(0.000001,sigma+scattering_strength)*0.22;
		energy*=transmittance;
		point+=ray*nearest;
		vec3 outgoing=refract(ray,-n,ri);
		float f=1.0;
		if(dot(outgoing,outgoing)>0.00001) {
			f=fresnel(dot(ray,n),ri,1.0);
			radiance+=energy*(1.0-f)*environment(point,normalize(outgoing));
		}
		energy*=f;
		ray=reflect(ray,n);
		point+=ray*0.003;
		if(energy<0.001) break;
	}
	return radiance;
}

uniform float art_pixel=1.0;
uniform vec3 outline_colour=vec3(0.72,0.76,0.77);
vec3 xyz_to_rgb(vec3 xyz){return vec3(dot(vec3(3.2406,-1.5372,-0.4986),xyz),dot(vec3(-0.9689,1.8758,0.0415),xyz),dot(vec3(0.0557,-0.2040,1.0570),xyz));}
vec3 spectral_material(vec3 point,vec3 d,vec3 normal){
 vec3 body_xyz=vec3(0.0);vec3 xyz=vec3(0.0);vec3 white_xyz=vec3(0.0);float white_y=0.0;
 for(int band=0;band<12;band++){
  float l=412.5+float(band)*25.0;
  vec3 cmf=observer(l);float spd=source_spd(l);
  float cauchy=dispersion/(1.0/pow(0.4308,2.0)-1.0/pow(0.6867,2.0));
  float ri=refractive_index+cauchy*(1.0/pow(l*0.001,2.0)-1.0/pow(0.589,2.0));
  float position=clamp((l-407.5)/15.0,0.0,19.0);
  int lower=int(floor(position));int upper=min(lower+1,19);
  float sigma=mix(absorption_bands[lower],absorption_bands[upper],fract(position));
  xyz+=cmf*spd*transport(point,d,normal,ri,sigma);
  body_xyz+=cmf*spd*exp(-sigma*110.0);
  white_xyz+=cmf*spd;white_y+=cmf.y*spd;
 }
 body_xyz/=max(white_y,0.001);xyz/=max(white_y,0.001);white_xyz/=max(white_y,0.001);
 // Partial adaptation preserves the source colour on colourless stones.
 vec3 rgb=max(xyz_to_rgb(xyz),vec3(0.0))/pow(max(xyz_to_rgb(white_xyz),vec3(0.08)),vec3(0.75));
 rgb*=1.65;
 float peak=max(rgb.r,max(rgb.g,rgb.b));
 rgb/=1.0+peak*0.65;
 rgb=pow(clamp(rgb,vec3(0.0),vec3(1.0)),vec3(1.0/2.2));
 peak=max(rgb.r,max(rgb.g,rgb.b));
 // A small brightness/chromaticity vocabulary, instead of a material tint.
 vec3 hue=rgb/max(peak,0.001);
 // Expand subtle spectral differences into readable pixel-art flashes.
 float average=(hue.r+hue.g+hue.b)/3.0;
 float fire_strength=clamp(dispersion/0.044,0.0,2.0);
 hue=clamp(vec3(average)+(hue-vec3(average))*(1.0+1.25*fire_strength),vec3(0.0),vec3(1.0));
 vec3 body=max(xyz_to_rgb(body_xyz),vec3(0.0))/pow(max(xyz_to_rgb(white_xyz),vec3(0.08)),vec3(0.75));
 body/=max(0.001,max(body.r,max(body.g,body.b)));
 float chroma=max(body.r,max(body.g,body.b))-min(body.r,min(body.g,body.b));
 // An illustrative material colour derived from absorption × source SPD,
 // never a per-gem RGB paint. Colourless materials retain the traced fire hue.
 if(chroma>0.25 && max(rgb.r,max(rgb.g,rgb.b))<0.92)hue=mix(hue,pow(body,vec3(1.25)),0.65);
 // Keep faint tints neutral and remove some grey from distinct colours.
 float purity=max(hue.r,max(hue.g,hue.b))-min(hue.r,min(hue.g,hue.b));
 float colour_weight=smoothstep(0.06,0.25,purity);
 const float grey_floor=0.17;
 vec3 clean_hue=max(hue-vec3(grey_floor),vec3(0.0))/(1.0-grey_floor);
 hue=mix(vec3(1.0),clean_hue,colour_weight);
 hue=floor(hue*10.0+0.5)/10.0;
 float value=floor(peak*6.0+0.5)/6.0;
 return hue*value;
}
bool pixel_hit(vec2 pixel,out vec3 p,out vec3 n,out vec3 d){
 vec3 o=vec3(0,0,220);d=normalize(vec3((pixel-center)/gem_scale,-220.0));float t;
 bool hit=entry_hit(o,d,t,n);p=o+d*t;return hit;
}
void fragment(){
 vec2 pixel=(floor(UV*logical_size/art_pixel)+vec2(0.5))*art_pixel;
 vec3 p;vec3 n;vec3 d;
 bool hit=pixel_hit(pixel,p,n,d);
 bool outline=false;
 if(hit){
  for(int i=0;i<4;i++){
   vec2 axis=i<2 ? vec2(1,0) : vec2(0,1);
   float side=i%2==0 ? 1.0 : -1.0;
   vec3 neighbour_point;vec3 neighbour_normal;vec3 neighbour_ray;
   bool neighbour_hit=pixel_hit(pixel+axis*side*art_pixel,neighbour_point,neighbour_normal,neighbour_ray);
   // Mark the inner silhouette and only one side of each shared facet edge.
   if(!neighbour_hit || (side>0.0 && dot(n,neighbour_normal)<0.982)) outline=true;
  }
 }
 if(!hit)COLOR=vec4(0.0);
 else if(outline)COLOR=vec4(outline_colour,1.0);
 else{
  // Group pixels by both their front facet and the first internal facet reached.
  vec3 internal_ray=refract(d,n,1.0/refractive_index);
  float nearest=10000.0;
  int exit_face=-1;
  for(int i=0;i<256;i++){
   if(i>=plane_count)break;
   float denominator=dot(planes[i].xyz,internal_ray);
   if(denominator>0.00001){
    float t=(planes[i].w-dot(planes[i].xyz,p))/denominator;
    if(t>0.01 && t<nearest){nearest=t;exit_face=i;}
   }
  }
  vec3 sample_point=p;
  if(exit_face>=0){
   float denominator=dot(internal_ray,n);
   if(abs(denominator)>0.01){
    vec3 exit_center=facet_centers[exit_face];
    sample_point=exit_center-internal_ray*dot(exit_center-p,n)/denominator;
   }
  }
  vec3 sample_ray=normalize(sample_point-vec3(0.0,0.0,220.0));
  vec3 colour=spectral_material(sample_point,sample_ray,n);
  // Small pixel star on a front facet when it catches the studio highlight.
  float glint=dot(reflect(d,n),normalize(vec3(-0.20,-0.42,0.88)));
  vec2 star_center=center+vec2(-14.0,-18.0)*gem_scale;
  vec2 star=abs((pixel-star_center)/art_pixel);
  float pulse=step(0.82,0.5+0.5*sin(TIME*2.0));
  if(glint>0.985 && pulse>0.0 && ((star.x<0.6 && star.y<2.5)||(star.y<0.6 && star.x<2.5))) colour=vec3(1.0);
  COLOR=vec4(colour,1.0);
 }
}
