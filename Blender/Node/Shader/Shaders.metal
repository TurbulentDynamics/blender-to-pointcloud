
#include <metal_stdlib>
using namespace metal;

// 1
struct VertexIn {
    packed_float3 position;
    packed_float3 normal;
};

struct VertexOut {
    float4 position [[position]];
    float3 fragmentPosition;
    float3 normal;
    float pointsize[[point_size]];
};

struct Light {
    packed_float3 color;      // 0 - 2
    float ambientIntensity;          // 3
    packed_float3 direction;  // 4 - 6
    float diffuseIntensity;   // 7
    float shininess;          // 8
    float specularIntensity;  // 9
    
    /*
     _______________________
     |0 1 2 3|4 5 6 7|8 9    |
     -----------------------
     |       |       |       |
     | chunk0| chunk1| chunk2|
     */
};

struct Uniforms{
    float4x4 modelMatrix;
    float4x4 projectionMatrix;
    Light light;
};

vertex VertexOut basic_vertex(const device VertexIn* vertex_array [[ buffer(0) ]],
                              const device Uniforms&  uniforms    [[ buffer(1) ]],
                              unsigned int vid [[ vertex_id ]]) {
    
    float4x4 mv_Matrix = uniforms.modelMatrix;
    float4x4 proj_Matrix = uniforms.projectionMatrix;
    
    VertexIn VertexIn = vertex_array[vid];
    
    VertexOut VertexOut;
    VertexOut.position = proj_Matrix * mv_Matrix * float4(VertexIn.position,1);
    VertexOut.fragmentPosition = (mv_Matrix * float4(VertexIn.position,1)).xyz;
    VertexOut.normal = (mv_Matrix * float4(VertexIn.normal, 0.0)).xyz;
    VertexOut.pointsize = 5.0;

    return VertexOut;
}

// 3
fragment float4 basic_fragment(VertexOut interpolated [[stage_in]],
                              const device Uniforms&  uniforms    [[ buffer(1) ]],
                              texture2d<float>  tex2D     [[ texture(0) ]],
                              sampler           sampler2D [[ sampler(0) ]],
                              float2 pointCoord [[point_coord]]) {
    
    // Ambient
    Light light = uniforms.light;
    float4 ambientColor = float4(light.color * light.ambientIntensity, 1.0);
    
    //Diffuse
    float diffuseFactor = max(0.0,dot(interpolated.normal, light.direction)); // 1
    float4 diffuseColor = float4(light.color * light.diffuseIntensity * diffuseFactor ,1.0); // 2
  

    //Specular
    float3 eye = normalize(interpolated.fragmentPosition); //1
    float3 reflection = reflect(light.direction, interpolated.normal); // 2
    float specularFactor = pow(max(0.0, dot(reflection, eye)), light.shininess); //3
    float4 specularColor = float4(light.color * light.specularIntensity * specularFactor ,1.0);//4

    
    float4 color = (ambientColor + diffuseColor + specularColor);
    color[3] = 1.0;
    return color;
}
