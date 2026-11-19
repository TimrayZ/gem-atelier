shader_type canvas_item;
render_mode unshaded;

uniform vec4 background_color : source_color = vec4(0.90, 0.90, 0.88, 1.0);
uniform float rotation_angle = 0.0;
uniform int illuminant = 0;
uniform vec3 light_weights = vec3(1.0,0.0,0.0);
uniform bool pixel_style = true;
uniform vec3 material_tint = vec3(1.0);
uniform float floor_y = 0.87;
uniform float floor_width = 0.24;
uniform float receiver_y = 50.0;
uniform vec4 planes[256];
uniform int plane_count = 0;


// Intersect the actual faceted solid from the receiver toward the light.
float silhouette(vec3 origin, vec3 ray){
    float near_t=0.0;
    float far_t=10000.0;
    for(int i=0;i<256;i++){
        if(i>=plane_count)break;
        float denom=dot(planes[i].xyz,ray);
        float numer=planes[i].w-dot(planes[i].xyz,origin);
        if(abs(denom)<0.00001){if(numer<0.0)return 0.0;}
        else{
            float t=numer/denom;
            if(denom<0.0)near_t=max(near_t,t);
            else far_t=min(far_t,t);
        }
    }
    return near_t<=far_t && far_t>0.0 ? 1.0 : 0.0;
}
void fragment(){
    vec2 uv=UV;
    if(pixel_style)uv=(floor(uv*vec2(532.0,259.0))+0.5)/vec2(532.0,259.0);
    float offset=light_weights.y*0.035-(light_weights.x+light_weights.z)*0.025;
    vec2 q=(uv-vec2(0.5+offset,floor_y))/vec2(floor_width,0.11);

    float radius=length(q);
    vec3 base=background_color.rgb;
    vec3 shade=base;
    vec3 origin=vec3(q.x*55.0,receiver_y,q.y*55.0);
    if(pixel_style){
        float mask=silhouette(origin,vec3(0.0,-1.0,0.0));
        if(mask>0.5){
            shade=base*0.73;
            // Equal-size ellipses orbit once for each full turn of the stone.
            vec2 orbit=vec2(cos(rotation_angle),sin(rotation_angle))*0.18;
            vec2 radii=vec2(0.24,0.34);
            float inner=silhouette(origin+vec3(4.0,0.0,0.0),vec3(0.0,-1.0,0.0));
            inner*=silhouette(origin-vec3(4.0,0.0,0.0),vec3(0.0,-1.0,0.0));
            inner*=silhouette(origin+vec3(0.0,0.0,4.0),vec3(0.0,-1.0,0.0));
            inner*=silhouette(origin-vec3(0.0,0.0,4.0),vec3(0.0,-1.0,0.0));
            if(inner>0.5){
                float left=1.0-step(1.0,length((q-orbit)/radii));
                float right=1.0-step(1.0,length((q+orbit)/radii));
                float middle=1.0-step(1.0,length(q/radii));
                // Add overlapping light contributions before tone mapping.
                vec3 warm=mix(vec3(1.0,0.68,0.59),material_tint,0.70);
                vec3 cool=mix(vec3(0.62,0.65,1.0),material_tint,0.70);
                vec3 neutral=mix(vec3(1.0),material_tint,0.55);
                vec3 total=left*warm+right*cool+middle*neutral;
                float count=left+right+middle;
                if(count>0.0){
                    vec3 mixed=total/count;
                    float brightness=min(0.70,0.32+0.15*count);
                    shade=mix(shade,mixed,brightness);
                }
            }
        }
    }else if(radius<2.3){
        vec3 shadow_ray=normalize(vec3(-0.35,-0.90,0.25));
        float shadow=silhouette(origin,shadow_ray);
        shadow+=silhouette(origin+vec3(3.0,0.0,0.0),shadow_ray);
        shadow+=silhouette(origin-vec3(3.0,0.0,0.0),shadow_ray);
        shadow+=silhouette(origin+vec3(0.0,0.0,3.0),shadow_ray);
        shadow+=silhouette(origin-vec3(0.0,0.0,3.0),shadow_ray);
        shade=base*(1.0-(shadow/5.0)*0.20);
        // A restrained, soft pool; its tint follows the chosen light and absorption.
        float pool=1.0-smoothstep(0.08,0.32,length(q-vec2(-0.08,0.0)));
        shade=mix(shade,clamp(base*material_tint*1.04,vec3(0.0),vec3(1.0)),pool*(shadow/5.0)*0.32);
    }
    COLOR=vec4(clamp(shade,vec3(0.0),vec3(1.0)),1.0);
}

