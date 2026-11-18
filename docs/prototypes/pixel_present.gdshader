shader_type canvas_item;
render_mode unshaded;
uniform int block_size=2;
void fragment(){
 vec2 size=1.0/TEXTURE_PIXEL_SIZE;
 vec2 start=floor(UV*size/float(block_size))*float(block_size);
 vec4 sum=vec4(0.0);
 float count=0.0;
 for(int y=0;y<4;y++){
  for(int x=0;x<4;x++){
   if(x>=block_size || y>=block_size) continue;
   vec2 sample_uv=(start+vec2(float(x)+0.5,float(y)+0.5))/size;
   vec4 c=texture(TEXTURE,clamp(sample_uv,TEXTURE_PIXEL_SIZE*0.5,vec2(1.0)-TEXTURE_PIXEL_SIZE*0.5));
   sum+=vec4(pow(max(c.rgb,vec3(0.0)),vec3(2.2))*c.a,c.a);
   count+=1.0;
  }
 }
 vec3 rgb=pow(sum.rgb/max(sum.a,0.00001),vec3(1.0/2.2));
 rgb=floor(rgb*31.0+0.5)/31.0;
 COLOR=vec4(rgb,sum.a/max(count,1.0));
}
