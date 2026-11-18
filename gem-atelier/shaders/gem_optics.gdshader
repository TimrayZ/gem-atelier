shader_type canvas_item;
render_mode unshaded;
// Same convex boundary planes as the cut solid, transformed into camera space.
uniform vec4 planes[256];
uniform int plane_count = 0;
uniform vec2 center = vec2(142.0, 99.0);
uniform float gem_scale = 1.5;
uniform float refractive_index = 1.746;
uniform float dispersion = 0.012;
uniform float surface_roughness = 0.01;
uniform float scattering_strength = 0.0001;
uniform int illuminant = 0;

// Sixteen visible-wavelength bands: fixed material absorption under changing SPD.
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
float environment(vec3 point, vec3 d) {
	float base = mix(0.055,0.22,clamp(-d.y,0.0,1.0));
	float box1 = smoothstep(0.82,0.93,dot(d,normalize(vec3(-0.6,-0.7,0.6))));
	float box2 = smoothstep(0.88,0.97,dot(d,normalize(vec3(0.8,-0.25,-0.3))));
	float pin = pow(max(0.0,dot(d,normalize(vec3(-0.25,-0.4,0.88)))),600.0/(1.0+surface_roughness*80.0));
	float strip = pow(max(0.0,dot(d,normalize(vec3(0.4,0.65,0.5)))),240.0/(1.0+surface_roughness*60.0));
	float pin2=pow(max(0.0,dot(d,normalize(vec3(-0.8,0.3,-0.45)))),480.0);
	base += box1*0.8+box2*0.6+pin*10.0+strip*5.0+pin2*8.0;
	// Finite ceiling softboxes vary across a facet with the ray exit position.
	if(d.y < -0.001) {
		float t=(-95.0-point.y)/d.y;
		vec3 hit=point+d*t;
		float panel=1.0-smoothstep(0.80,1.0,max(abs((hit.x+38.0)/45.0),abs((hit.z-25.0)/64.0)));
		base+=max(0.0,panel)*2.5;
	}
	if(d.y > 0.001) {
		float t=(75.0-point.y)/d.y;
		vec3 hit=point+d*t;
		float ring=exp(-pow((length(hit.xz)-38.0)/3.0,2.0));
		float floor_shade=0.04+0.12*ring+0.06*exp(-dot(hit.xz,hit.xz)/4000.0);
		base=mix(base,floor_shade,0.72);
	}
	// A finite neutral studio backdrop: transmitted rays bend its vertical folds.
	if(d.z < -0.01) {
		float t = (-110.0-point.z)/d.z;
		vec3 p = point+d*t;
		float fold = 0.5+0.5*cos(p.x*0.055);
		base += 0.10+0.95*pow(fold,6.0);
	}
	if(d.y > 0.8) base *= 0.30;
	return base;
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

vec4 sample_pixel(vec2 pixel) {
	vec3 o = vec3(0.0,0.0,220.0);
	vec3 d = normalize(vec3((pixel-center)/gem_scale,-220.0));
	float distance;
	vec3 normal;
	if (!entry_hit(o,d,distance,normal) || plane_count == 0) {
		return vec4(0.0);
	} else {
		vec3 point = o+d*distance;
		vec3 xyz=vec3(0.0);
		vec3 white_xyz=vec3(0.0);
		float white_y=0.0;
		for(int band=0;band<20;band++) {
			float l=407.5+float(band)*15.0;
			vec3 cmf=observer(l);
			float spd=source_spd(l);
			float cauchy=dispersion/(1.0/pow(0.4308,2.0)-1.0/pow(0.6867,2.0));
			float ri=refractive_index+cauchy*(1.0/pow(l*0.001,2.0)-1.0/pow(0.589,2.0));
			xyz+=cmf*spd*transport(point,d,normal,ri,absorption_bands[band]);
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
	vec2 pixel=UV*vec2(284.0,207.0);
	// Rotated stratification within the native-resolution pixel, no image blur.
	vec4 integrated=sample_pixel(pixel+vec2(-0.375,-0.125)*pixel_footprint)*0.25;
	integrated+=sample_pixel(pixel+vec2(0.125,-0.375)*pixel_footprint)*0.25;
	integrated+=sample_pixel(pixel+vec2(0.375,0.125)*pixel_footprint)*0.25;
	integrated+=sample_pixel(pixel+vec2(-0.125,0.375)*pixel_footprint)*0.25;
	vec3 linear=integrated.rgb/max(integrated.a,0.0001);
	COLOR=vec4(pow(linear,vec3(1.0/2.2)),integrated.a);
}
