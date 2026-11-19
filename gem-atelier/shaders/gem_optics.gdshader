shader_type canvas_item;
render_mode unshaded;
// Same convex boundary planes as the cut solid, transformed into camera space.
uniform vec4 planes[256];
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
uniform float absorption_bands_alt[20];
uniform bool zoned = false;
uniform vec3 zone_axis = vec3(0.0,1.0,0.0);
uniform float zone_width = 20.0;
uniform vec3 light_weights = vec3(1.0,0.0,0.0);
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
float blackbody_spd(float l,float temp) {
 float nm=l*0.001;
 return pow(0.56/nm,5.0)*(exp(14387.77/(0.56*temp))-1.0)/(exp(14387.77/(nm*temp))-1.0);
}
float source_spd(float l) {
 return light_weights.x*blackbody_spd(l,6500.0)+light_weights.y*blackbody_spd(l,2850.0)+light_weights.z*blackbody_spd(l,4500.0);
}
float zone_mix(vec3 point) {
 return zoned ? smoothstep(-zone_width,zone_width,dot(point,zone_axis)) : 0.0;
}
// Plain studio: no curtain, floor, folds, rings, texture or scenery in the rays.
float environment(vec3 point, vec3 d) {
 float box1=smoothstep(0.80,0.94,dot(d,normalize(vec3(-0.6,-0.7,0.6))));
 float box2=smoothstep(0.86,0.97,dot(d,normalize(vec3(0.8,-0.25,-0.3))));
 // Soft studio illumination: no additional narrow light sources.
 return 0.65+box1*5.0+box2*2.5;
}


// Jadeite is a polycrystalline aggregate: this soft translucent appearance is
// an art-directed single-scattering approximation, not a transparent diamond.
vec3 jade_appearance(vec3 point,vec3 normal,vec3 incident) {
 vec3 inside_ray=refract(incident,normal,1.0/1.66);
 float depth=10000.0;
 for(int i=0;i<256;i++) {
  if(i>=plane_count) break;
  float denom=dot(planes[i].xyz,inside_ray);
  if(denom>0.00001) {
   float t=(planes[i].w-dot(planes[i].xyz,point))/denom;
   if(t>0.01) depth=min(depth,t);
  }
 }
 float deep_zone=zone_mix(point+inside_ray*min(depth,60.0)*0.45);
 float zone=mix(zone_mix(point),deep_zone,0.40);
 vec3 white_zone=vec3(0.88,0.92,0.84);
 vec3 green_zone=vec3(0.32,0.69,0.45);
 vec3 body=mix(white_zone,green_zone,zone);
 vec3 smooth_normal=normalize(mix(normal,normalize(point),0.78));
 float diffuse=0.78+0.22*max(0.0,dot(smooth_normal,normalize(vec3(-0.5,-0.7,0.9))));
 float highlight=pow(max(0.0,dot(reflect(incident,smooth_normal),normalize(vec3(-0.2,-0.4,0.9)))),28.0)*0.30;
 vec3 lamp=light_weights.x*vec3(0.96,1.0,0.98)+light_weights.y*vec3(1.0,0.94,0.84)+light_weights.z*vec3(1.0,0.99,0.95);
 return clamp(body*diffuse*lamp+vec3(highlight),vec3(0.0),vec3(1.0));
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
float transport(vec3 point, vec3 incident, vec3 normal, float ri, float sigma, float sigma_alt) {
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
		float local_sigma=mix(sigma,sigma_alt,zone_mix(point+ray*nearest*0.5));
		float transmittance=exp(-(local_sigma+scattering_strength)*nearest-inclusion_depth);
		radiance+=energy*(1.0-exp(-inclusion_depth))*0.12;
		// Single-scattering approximation, with the same extinction budget.
		radiance+=energy*(1.0-transmittance)*scattering_strength/max(0.000001,local_sigma+scattering_strength)*0.22;
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

vec4 sample_pixel(vec2 pixel) {
	vec3 o = vec3(0.0,0.0,220.0);
	vec3 d = normalize(vec3((pixel-center)/gem_scale,-220.0));
	float distance;
	vec3 normal;
	if (!entry_hit(o,d,distance,normal) || plane_count == 0) {
		return vec4(0.0);
	} else {
		vec3 point = o+d*distance;
		if(material_id==10) return vec4(pow(jade_appearance(point,normal,d),vec3(2.2)),1.0);
		vec3 xyz=vec3(0.0);
		vec3 white_xyz=vec3(0.0);
		float white_y=0.0;
		for(int band=0;band<20;band++) {
			float l=407.5+float(band)*15.0;
			vec3 cmf=observer(l);
			float spd=source_spd(l);
			float cauchy=dispersion/(1.0/pow(0.4308,2.0)-1.0/pow(0.6867,2.0));
			float ri=refractive_index+cauchy*(1.0/pow(l*0.001,2.0)-1.0/pow(0.589,2.0));
			xyz+=cmf*spd*transport(point,d,normal,ri,absorption_bands[band],absorption_bands_alt[band]);
			white_xyz+=cmf*spd;
			white_y+=cmf.y*spd;
		}
		xyz/=max(white_y,0.001);
		white_xyz/=max(white_y,0.001);
		vec3 rgb=vec3(dot(vec3(3.2406,-1.5372,-0.4986),xyz),dot(vec3(-0.9689,1.8758,0.0415),xyz),dot(vec3(0.0557,-0.2040,1.0570),xyz));
		vec3 white_rgb=vec3(dot(vec3(3.2406,-1.5372,-0.4986),white_xyz),dot(vec3(-0.9689,1.8758,0.0415),white_xyz),dot(vec3(0.0557,-0.2040,1.0570),white_xyz));
		// Partial von-Kries-style RGB white adaptation; same rule for all materials.
		rgb/=pow(max(white_rgb,vec3(0.08)),vec3(0.85));
		rgb=max(rgb,vec3(0.0))*1.45;
		// Shared luminance compression preserves saturated spectral color edges.
		float peak=max(rgb.r,max(rgb.g,rgb.b));
		rgb/=1.0+peak*0.65;
		return vec4(clamp(rgb,vec3(0.0),vec3(1.0)),1.0);
	}
}

void fragment() {
	vec2 pixel=UV*logical_size;
	// Rotated stratification within the native-resolution pixel, no image blur.
	vec4 integrated=sample_pixel(pixel+vec2(-0.375,-0.125)*pixel_footprint)*0.25;
	integrated+=sample_pixel(pixel+vec2(0.125,-0.375)*pixel_footprint)*0.25;
	integrated+=sample_pixel(pixel+vec2(0.375,0.125)*pixel_footprint)*0.25;
	integrated+=sample_pixel(pixel+vec2(-0.125,0.375)*pixel_footprint)*0.25;
	vec3 linear=integrated.rgb/max(integrated.a,0.0001);
	COLOR=vec4(pow(linear,vec3(1.0/2.2)),integrated.a);
}
