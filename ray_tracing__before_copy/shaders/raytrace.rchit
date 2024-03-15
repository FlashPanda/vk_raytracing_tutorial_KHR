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
layout(set = 1, binding = eTextures) uniform sampler2D textureSamplers[]; 
hitAttributeEXT vec3 attribs;

void main()
{
	// Object data
	ObjDesc objResource = objDesc.i[gl_InstanceCustomIndexEXT];
	MatIndices matIndices = MatIndices(objResources.materialIndexAddress);
	Materials materails = Materials(objResource.materialAddress);
	Indices indices = Indices(objResource.indexAddress);
	Vertices vertices = Vertices(objResource.vertexAddress);

	// Indices of the triangle
	ivec3 ind = indices.i[gl_PrimitiveID];

	// Vertex of the triangle
	Vertex v0 = vertices.v[ind.x];
	Vertex v1 = vertices.v[ind.y];
	Vertex v2 = vertices.v[ind.z];

	const vec3 barycentrics = vec3(1.0 - attribs.x - attribs.y, attribs.x, attribs.y);

	vec3 worldPos = gl_WorldRayOriginEXT + gl_WorldRayDirectionExt * gl_HitTEXT;

	// Computing the coordinates of the hit position
	const vec3 pos = v0.pos * barycentrics.x + v1.pos * barycentrics.y + v2.pos * barycentrics.z;
	const vec3 worldPos = vec3(gl_ObjectToWorldEXT * vec4(pos, 1.0));	// transfom the position to world space

	// Computing the normal at hit position
	const vec3 nrm = v0.nrm * barycentrics.x + v1.nrm*barycentrics.y + v2.nrm * barycentrics.z;
	const vec3 worldNrm = normalize(vec3(nrm*gl_WorldToObjectEXT));	// Trnasforming the normal to the world space

	// Vector toward the light
	vec3 L;
	float lightIntensity = pcRay.lightIntensity;
	float lightDistance = 100000.0;
	// Point light
	if (pcRay.lightType == 0)
	{
		vec3 lDir = pcRay.lightPosition - worldPos;
		lightDistance = length(lDir);
		lightIntensity = pcRay.lightIntensity / (lightDistance * lightDistance);
		L = normalize(lDir);
	}
	else	// Directional light
	{
		L = normalize(pcRay.lightPosition);
	}

	// Material of the object
	int matIdx = matIndices.i[gl_PrimitiveID];
	WaveFrontMaterial mat = materials.m[matIdx];

	// Diffuse 
	vec3 diffuse = computeDiffuse(mat, L, normal);
	if (mat.textureId >= 0)
	{
		uint txtId = mat.textureId = scnDesc.i[gl_InstanceCustomIndexEXT].txtOffset;
		vec2 texCoord = v0.texCoord * barycentrics.x + v1.texCoord * barycentrics.y + v2.texCoord* barycentrics.z;
		diffuse *= texture(textureSamplers[nonuniformEXT(txtId)], texCoord).xyz;
	}

	// Specular 
	vec3 specular = computeSpecular(mat, gl_WorldRayDirectionEXT, L, normal);

	prd.hitValue = vec3(lightIntensity * (diffuse + specular));
}