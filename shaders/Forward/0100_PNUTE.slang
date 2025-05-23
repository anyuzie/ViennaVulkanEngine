import Common;

struct CoarseVertex {
    float3 positionW : POSITION;
    float3 normalW : NORMAL;
    float2 uv : TEXCOORD;
    float3 tangentW : TANGENT;
};

struct VertexStageOutput {
    CoarseVertex coarseVertex : CoarseVertex;
    float4       sv_position  : SV_Position;
};

// binding B,S means that the resource is bound to binding B, set S

// set 0 ... per frame

[[vk::binding(0, 0)]]
ConstantBuffer<UniformBufferFrame> gParamsFrame;

[[vk::binding(1, 0)]]
StructuredBuffer<Light> gLights;

[[vk::binding(2, 0)]]
Sampler2DArray<uint, 1> shadowMapImage; // shadow maps for the lights

//----------------------------------------------------------------------------

// set 1 ... per object

[[vk::binding(0, 1)]]
ConstantBuffer<UniformBufferObjectTexture> gParamsObject;

[[vk::binding(1, 1)]]
Sampler2D texSampler;

//----------------------------------------------------------------------------

[[vk::push_constant]]
LightOffset offset;

//----------------------------------------------------------------------------

[shader("vertex")]
VertexStageOutput vertexMain(
    float3 positionL: POSITION,
    float3 normalL: NORMAL,
    float2 uv: TEXCOORD,
    float3 tangentL : TANGENT)
{
    float3 positionW = mul(gParamsObject.model, float4(positionL, 1.0)).xyz;
    float3 positionV = mul(gParamsFrame.camera.view, float4(positionW, 1.0)).xyz;  

    VertexStageOutput output;
    output.coarseVertex.positionW   = positionW;
    output.coarseVertex.normalW     = mul(gParamsObject.modelInvTranspose, float4(normalL, 0.0)).xyz;
    output.coarseVertex.uv          = gParamsObject.uvscale * uv;
    output.coarseVertex.tangentW    = mul(gParamsObject.model, float4(tangentL, 1.0)).xyz;
    output.sv_position              = mul(gParamsFrame.camera.proj, float4(positionV, 1.0));

    return output;
}

[shader("fragment")]
float4 fragmentMain(CoarseVertex cv: CoarseVertex) : SV_Target
{
    Camera camera = gParamsFrame.camera;
    uint3 numberLights = gParamsFrame.numberLights;

    float4 tex = texSampler.Sample(cv.uv);
    float3 l = calculateLighting(gLights, numberLights, offset, cv.normalW, camera.positionW, cv.positionW);
    return float4(tex.rgb * l, 1);
}
