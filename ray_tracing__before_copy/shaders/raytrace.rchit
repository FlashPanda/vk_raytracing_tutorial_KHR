#version 460
#extension GL_EXT_ray_tracing : require
#extension GL_EXT_nonuniform_qualifier : enable
#extension GL_EXT_scalar_block_layout : enable
#extension GL_GOOGLE_include_directive : enable
#extension GL_EXT_shader_explicit_arithmetic_types_int64 : require
#extension GL_EXT_buffer_reference2 : require

#inlcude "raycommon.glsl"
#include "wavefront.glsl"

layout(location = 0) rayPayloadInEXT hitPayload prd;

layout(buffer_reference, scalar) buffer Vertices {Vertex v[];};
layout(buffer_reference, scalar) buffer Indices{ivec3 i[];};
layout(buffer_reference, scalar) buffer Materials{WaveFrontMaterial m[];};	// Array of all materials on an object
layout(buffer_reference, scalar) buffer MatIndices{int i[];};	// Material ID fro each triangle
layout(set = 1, binding = eObjDescs, scalar) buffer ObjDesc_ {ObjDesc i[];} objDesc;
layout(push_constant) uniform _PushConstantRay {PushConstantRay pcRay;};
hitAttributeEXT vec3 attribs;

void main()
{
  hitValue = vec3(0.2, 0.5, 0.5);
}
