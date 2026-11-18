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

uniform vec3 art_dark=vec3(0.08,0.16,0.29);
uniform vec3 art_mid=vec3(0.32,0.49,0.68);
uniform vec3 art_light=vec3(0.70,0.86,0.91);
uniform vec3 art_edge=vec3(0.54,0.72,0.81);
uniform vec3 art_white=vec3(1.0,0.98,0.83);
uniform vec2 logical_size=vec2(425.1892,207.0);
uniform float art_pixel=1.2;

bool entry_hit(vec3 o,vec3 d,out float distance,out vec3 normal){
 float near_t=0.0;float far_t=1000.0;normal=vec3(0.0);
 for(int i=0;i<256;i++){
  if(i>=plane_count)break;
  float denom=dot(planes[i].xyz,d);
  float numer=planes[i].w-dot(planes[i].xyz,o);
  if(abs(denom)<0.00001){if(numer<0.0)return false;}
  else{
   float t=numer/denom;
   if(denom<0.0 && t>near_t){near_t=t;normal=planes[i].xyz;}
   if(denom>0.0)far_t=min(far_t,t);
  }
 }
 distance=near_t;
 return near_t<=far_t && far_t>0.0;
}

bool exit_path(vec3 point,vec3 incident,vec3 normal,float ri,out vec3 exit_n,out vec3 exit_d,out float length){
 vec3 ray=refract(incident,normal,1.0/ri);
 point+=ray*0.003;length=0.0;exit_n=normal;exit_d=ray;
 for(int bounce=0;bounce<8;bounce++){
  float nearest=10000.0;vec3 n=vec3(0.0);
  for(int i=0;i<256;i++){
   if(i>=plane_count)break;
   float denom=dot(planes[i].xyz,ray);
   if(denom>0.00001){
    float t=(planes[i].w-dot(planes[i].xyz,point))/denom;
    if(t>0.0001 && t<nearest){nearest=t;n=planes[i].xyz;}
   }
  }
  if(nearest>9999.0)break;
  length+=nearest;point+=ray*nearest;
  vec3 outgoing=refract(ray,-n,ri);
  if(dot(outgoing,outgoing)>0.00001){exit_n=n;exit_d=normalize(outgoing);return true;}
  ray=reflect(ray,n);point+=ray*0.003;
 }
 return false;
}

vec3 absorption_colour(float path_length){
 vec3 xyz=vec3(0.0);float white_y=0.0;
 for(int band=0;band<20;band++){
  float l=407.5+float(band)*15.0;
  vec3 cmf=observer(l);float spd=source_spd(l);
  xyz+=cmf*spd*exp(-absorption_bands[band]*path_length);
  white_y+=cmf.y*spd;
 }
 xyz/=max(white_y,0.001);
 vec3 rgb=vec3(dot(vec3(3.2406,-1.5372,-0.4986),xyz),dot(vec3(-0.9689,1.8758,0.0415),xyz),dot(vec3(0.0557,-0.2040,1.0570),xyz));
 rgb=max(rgb,vec3(0.0));
 return rgb/max(0.01,max(rgb.r,max(rgb.g,rgb.b)));
}

bool hit_pixel(vec2 pixel,out vec3 point,out vec3 normal,out vec3 direction){
 vec3 o=vec3(0.0,0.0,220.0);
 direction=normalize(vec3((pixel-center)/gem_scale,-220.0));
 float distance;
 bool hit=entry_hit(o,direction,distance,normal);
 point=o+direction*distance;
 return hit;
}

void fragment(){
 vec2 pixel=(floor(UV*logical_size/art_pixel)+vec2(0.5))*art_pixel;
 vec3 point;vec3 n;vec3 d;
 vec3 ink=vec3(0.035,0.065,0.12);
 bool hit=hit_pixel(pixel,point,n,d);
 vec2 directions[4];
 directions[0]=vec2(1,0);directions[1]=vec2(-1,0);directions[2]=vec2(0,1);directions[3]=vec2(0,-1);
 bool silhouette=false;bool edge=false;
 for(int i=0;i<4;i++){
  vec3 p2;vec3 n2;vec3 d2;
  bool other=hit_pixel(pixel+directions[i]*art_pixel,p2,n2,d2);
  if(other!=hit)silhouette=true;
  if(hit && other && dot(n,n2)<0.997)edge=true;
 }
 if(!hit){COLOR=vec4(ink,silhouette?1.0:0.0);}
 else{
  vec3 exit_n;vec3 exit_d;float path_length;
  bool exits=exit_path(point,d,n,refractive_index,exit_n,exit_d,path_length);
  vec3 key=normalize(vec3(-0.6,-0.7,0.6));
  float face_light=clamp(0.5+0.5*dot(n,key),0.0,1.0);
  // A few face-scale values: no smooth PBR shading and no noisy environment.
  float value=face_light*0.82+(exits?0.08:0.0);
  vec3 colour=art_dark;
  if(value>0.34)colour=mix(art_dark,art_mid,0.55);
  if(value>0.52)colour=art_mid;
  if(value>0.71)colour=art_light;
  vec3 tint=absorption_colour(path_length);
  // Select a compact colour family for alexandrite using its fixed absorption.
  if(material_id==0){
   float red=clamp((tint.r-tint.g+0.10)*2.5,0.0,1.0);
   colour=mix(colour,colour*vec3(1.7,0.42,1.3),step(0.5,red));
  }
  // A single broad studio source makes clean, connected light shapes.
  float surface_box=dot(reflect(d,n),key);
  float transmitted_box=exits?dot(exit_d,key):-1.0;
  if(surface_box>0.88 || transmitted_box>0.86)colour=art_white;
  // Red and blue rays exit the actual cut solid at different angles.
  // Restrict fire to the softbox boundary instead of painting random speckles.
  if(exits && dispersion>0.02 && transmitted_box>0.76 && transmitted_box<0.90){
   vec3 red_n;vec3 red_d;float red_length;
   vec3 blue_n;vec3 blue_d;float blue_length;
   bool red_exit=exit_path(point,d,n,refractive_index-dispersion*0.35,red_n,red_d,red_length);
   bool blue_exit=exit_path(point,d,n,refractive_index+dispersion*0.65,blue_n,blue_d,blue_length);
   float r=red_exit?dot(red_d,key):-1.0;
   float b=blue_exit?dot(blue_d,key):-1.0;
   if(r>0.84 && b<=0.84)colour=vec3(1.0,0.74,0.25);
   if(b>0.84 && r<=0.84)colour=vec3(0.45,0.93,1.0);
  }
  // Facet line colour is part of the material, before final output.
  if(edge)colour=mix(colour,art_edge,0.80);
  if(silhouette)colour=ink;
  COLOR=vec4(colour,1.0);
 }
}
