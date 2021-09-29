
uniform StructuredBuffer<int> boundingBox;
uniform StructuredBuffer<float3> chunksCenter;
uniform StructuredBuffer<int2> pointCloudDataMip3;
uniform StructuredBuffer<int> gridPointersMip2;
uniform StructuredBuffer<int> gridPointersMip3;


float4x4 objectMatrix;
float4x4 objectMatrixInv;
float chunkSize;
sampler2D _MainTex;
float lodNear;
float lodFar;
int solidHighlightId;

static const int3 mip3CellIter[] = {
    int3(0, 0, 0), int3(1, 0, 0), int3(2, 0, 0), int3(3, 0, 0), int3(0, 1, 0), int3(1, 1, 0), int3(2, 1, 0), int3(3, 1, 0), int3(0, 2, 0), int3(1, 2, 0), int3(2, 2, 0), int3(3, 2, 0), int3(0, 3, 0), int3(1, 3, 0), int3(2, 3, 0), int3(3, 3, 0), int3(0, 0, 1), int3(1, 0, 1), int3(2, 0, 1), int3(3, 0, 1), int3(0, 1, 1), int3(1, 1, 1), int3(2, 1, 1), int3(3, 1, 1), int3(0, 2, 1), int3(1, 2, 1), int3(2, 2, 1), int3(3, 2, 1), int3(0, 3, 1), int3(1, 3, 1), int3(2, 3, 1), int3(3, 3, 1), int3(0, 0, 2), int3(1, 0, 2), int3(2, 0, 2), int3(3, 0, 2), int3(0, 1, 2), int3(1, 1, 2), int3(2, 1, 2), int3(3, 1, 2), int3(0, 2, 2), int3(1, 2, 2), int3(2, 2, 2), int3(3, 2, 2), int3(0, 3, 2), int3(1, 3, 2), int3(2, 3, 2), int3(3, 3, 2), int3(0, 0, 3), int3(1, 0, 3), int3(2, 0, 3), int3(3, 0, 3), int3(0, 1, 3), int3(1, 1, 3), int3(2, 1, 3), int3(3, 1, 3), int3(0, 2, 3), int3(1, 2, 3), int3(2, 2, 3), int3(3, 2, 3), int3(0, 3, 3), int3(1, 3, 3), int3(2, 3, 3), int3(3, 3, 3)
};

static const int3 neighboursBigSplat[7] = {
    int3(0, 0, 0),
    int3(0, 1, 0),
    int3(0, -1, 0),
    int3(1, 0, 0),
    int3(-1, 0, 0),
    int3(0, 0, 1),
    int3(0, 0, -1),
};

int3 gridCoordFromLinearId(uint linearGridId, uint gridSize){
    int3 gridCoord;
    gridCoord.x = linearGridId % gridSize;
    gridCoord.z = int(linearGridId / (gridSize*gridSize));
    gridCoord.y = int(linearGridId / gridSize) - (gridSize * gridCoord.z);

    return gridCoord;
}

float3 expandGridPoint(int3 cellCoord, float cellSize, float localChunkSize){
    float cellCornerOffset = cellSize * 0.5;
    float halfBounds = localChunkSize * 0.5;
    float3 gridPoint = float3(
        (cellSize * cellCoord.x) - halfBounds, 
        (cellSize * cellCoord.y) - halfBounds, 
        (cellSize * cellCoord.z) - halfBounds) + cellCornerOffset;

    return gridPoint;
}

void unpack8888(uint inVal, out uint a, out uint b, out uint c, out uint d){
    a = inVal >> 24;
    b = (0x00FF0000 & inVal) >> 16;
    c = (0x0000FF00 & inVal) >> 8;
    d = (0x000000FF & inVal);
}

void unpack66668(int value, out int4 unpackedData1, out int unpackedData2){
    unpackedData2 = value & 0x000000FF;
    value >>= 8;
    unpackedData1.w = value & 0x3f;
    value >>= 6;
    unpackedData1.z = value & 0x3f;
    value >>= 6;
    unpackedData1.y = value & 0x3f;
    value >>= 6;
    unpackedData1.x = value & 0x3f;
}

void unpack6663335(int value, out uint a, out uint b, out uint c, out uint d, out uint e, out uint f, out uint g){
    g = value & 0x1f;
    value >>= 5;
    f = value & 0x7;
    value >>= 3;
    e = value & 0x7;
    value >>= 3;
    d = value & 0x7;
    value >>= 3;
    c = value & 0x3f;
    value >>= 6;
    b = value & 0x3f;
    value >>= 6;
    a = value & 0x3f;
}

uint unpack6_444455(int value){
    value >>= 26;
    return value & 0x3f;
}

void unpack6444455(int value, out uint a, out uint b, out uint c, out uint d, out uint e, out uint f, out uint g){
    g = value & 0x1f;
    value >>= 5;
    f = value & 0x1f;
    value >>= 5;
    e = value & 0xf;
    value >>= 4;
    d = value & 0xf;
    value >>= 4;
    c = value & 0xf;
    value >>= 4;
    b = value & 0xf;
    value >>= 4;
    a = value & 0x3f;
}

void unpack8618(int value, out uint a, out uint b, out uint c){
    c = value & 0x3ffff;
    value >>= 18;
    b = value & 0x3f;
    value >>= 6;
    a = value & 0xff;
}

void unpack55418(int value, out uint a, out uint b, out uint c, out uint d){
    d = value & 0x3ffff;
    value >>= 18;
    c = value & 0xf;
    value >>= 4;
    b = value & 0x1f;
    value >>= 5;
    a = value & 0x1f;
}

int4 unpack66614(int value){
    int4 outval;

    outval.w = value & 0x3fff;
    value >>= 14;
    outval.z = value & 0x3f;
    value >>= 6;
    outval.y = value & 0x3f;
    value >>= 6;
    outval.x = value & 0x3f;
    
    return outval;
}


void unpack66884(int value, out uint a, out uint b, out uint c, out uint d, out uint e){

}

void unpack824(int value, out uint a, out uint b){
    b = value & 0xffffff;
    value >>= 24;
    a = value & 0xff;
}

float3 unpackNormal2Byte(uint value1, uint value2){
    float2 f = float2((float)value1 / 256.0, (float)value2 / 256.0);
    // float2 f = float2(value1 * 0.00390625, value2 * 0.00390625);

    f = f * 2.0 - 1.0;

    float3 n = float3( f.x, f.y, 1.0 - abs( f.x ) - abs( f.y ) );
    float t = saturate( -n.z );
    n.xy += n.xy >= 0.0 ? -t : t;

    return normalize( n );
}

float3 unpackNormal(float value1, float value2){
    value1 = value1 * 2.0 - 1.0;
    value2 = value2 * 2.0 - 1.0;

    float3 n = float3( value1, value2, 1.0 - abs( value1 ) - abs( value2 ) );
    float t = saturate( -n.z );
    n.xy += n.xy >= 0.0 ? -t : t;

    return normalize(n);
}

float3 unpackNormalUnnorm(float value1, float value2){
    value1 = value1 * 2.0 - 1.0;
    value2 = value2 * 2.0 - 1.0;

    float3 n = float3( value1, value2, 1.0 - abs( value1 ) - abs( value2 ) );
    float t = saturate( -n.z );
    n.xy += n.xy >= 0.0 ? -t : t;

    return n;
}

float3 projectPointOnPlane(float3 p, float3 planeOrigin, float3 planeNormal){
    float3 vec = planeOrigin - p;

    return vec - planeNormal * ( dot( vec, planeNormal ) / dot( planeNormal, planeNormal ) );
}

float3 projectRayOnPlane(float3 rayOrigin, float3 rayDirection, float3 planeOrigin, float3 planeNormal){
    float denom = dot(planeNormal, rayDirection);

    // float t = 1.0;
    // if(denom > 0.00001){
        float t = dot(planeOrigin - rayOrigin, planeNormal) / denom;
    // }
    
    return rayOrigin + (rayDirection * t);
}

float projectPointOnLine(float3 pnt, float3 linePnt, float3 lineDir){
    float3 v = pnt - linePnt;
    float t = dot(v, lineDir);
    
    return t;
}

float boundsIntersection(float3 ro, float3 rd, float3 rad, float3 m) {
    float3 n = m * ro;
    float3 k = abs(m) * rad;
    float3 t2 = -n + k;

    float tF = min( min( t2.x, t2.y ), t2.z );

    return tF;
}

float boxIntersection( float3 ro, float3 rd, float3 boxPos, float boxSize){
    ro -= boxPos;
    float3 m = 1.0 / rd; // can precompute if traversing a set of aligned boxes
    float3 n = m * ro;   // can precompute if traversing a set of aligned boxes
    float3 k = abs(m) * boxSize;
    float3 t1 = -n - k;
    float3 t2 = -n + k;
    float tN = max( max( t1.x, t1.y ), t1.z );
    float tF = min( min( t2.x, t2.y ), t2.z );
    if( tN>tF || tF < 0.0) return -1.0; // no intersection

    return tN;
}

float boxIntersectionFast(float3 ro, float3 m, float3 k, float3 boxPos){
    ro -= boxPos;
    // float3 m = 1.0 / rd; // can precompute if traversing a set of aligned boxes
    float3 n = m * ro;   // can precompute if traversing a set of aligned boxes
    // float3 k = abs(m) * boxSize;
    float3 t1 = -n - k;
    float3 t2 = -n + k;
    float tN = max( max( t1.x, t1.y ), t1.z );
    float tF = min( min( t2.x, t2.y ), t2.z );
    if(tN > tF) return -1.0;
    // if(tN > tF || tF < 0.0) return -1.0; // no intersection

    // return tN;
    return 1.0;
}

float boxIntersectionNormalFast(float3 ro, float3 s, float3 m, float3 k, float3 boxPos, out float3 outNormal){
    ro -= boxPos;
    // float3 m = 1.0 / rd; // can precompute if traversing a set of aligned boxes
    float3 n = -m * ro;   // can precompute if traversing a set of aligned boxes
    // float3 k = abs(m) * boxSize;
    float3 t1 = -n - k;
    float3 t2 = -n + k;
    float tN = max( max( t1.x, t1.y ), t1.z );
    float tF = min( min( t2.x, t2.y ), t2.z );
    if(tN > tF ) return -1.0;

    outNormal = -(s*step(t1.yzx,t1.xyz)*step(t1.zxy,t1.xyz));

    return 1.0;
}

float boxIntersectionNormal( float3 ro, float3 rd, float3 boxPos, float boxSize, out float3 outNormal){
    ro -= boxPos;
    float3 m = 1.0 / rd; // can precompute if traversing a set of aligned boxes
    float3 n = m * ro;   // can precompute if traversing a set of aligned boxes
    float3 k = abs(m) * boxSize;
    float3 t1 = -n - k;
    float3 t2 = -n + k;
    float tN = max( max( t1.x, t1.y ), t1.z );
    float tF = min( min( t2.x, t2.y ), t2.z );
    // if( tN > tF || tF < 0.0) return -1.0; // no intersection

    outNormal = -sign(rd)*step(t1.yzx,t1.xyz)*step(t1.zxy,t1.xyz);

    return tN;
}

// Z buffer to linear 0..1 depth (0 at eye, 1 at far plane)
inline float Linear01Depth( float z )
{
    return 1.0 / (_ZBufferParams.x * z + _ZBufferParams.y);
}
// Z buffer to linear depth
inline float LinearEyeDepth( float z )
{
    return 1.0 / (_ZBufferParams.z * z + _ZBufferParams.w);
}

void drawVoxel(float3 positionWS, float3 viewDirectionWS, float3 cellCenter, float halfCellSize, int3 colorData,
    inout float depthSort, inout bool hit, inout float3 outDepthPoint, inout float3 outNormal, inout float3 outColor){

    float3 voxelNormal = 0;
    float boxHit = boxIntersectionNormal(positionWS, -viewDirectionWS, cellCenter, halfCellSize, voxelNormal);

    if(boxHit > -1.0){// && boxHit < depthSort){
        float3 projectedPoint = projectRayOnPlane(positionWS, viewDirectionWS, cellCenter + (voxelNormal * halfCellSize), voxelNormal);

        outColor = colorData / 64;

        outNormal = voxelNormal;

        outDepthPoint = projectedPoint;

        depthSort = boxHit;

        hit = true;
    }
}

/* cube topology
               5---6
             / |     |
            /  4    |
            1---2  7
            |    |  /
            0---3/

            y  z
            |/
            ---x
            */

// this mask is used to lerp a cube mesh between min and max bounds
static const float3 boundingBoxMask[8] = {
    float3(0.0, 0.0, 0.0), // 0
    float3(0.0, 1.0, 0.0), // 1
    float3(1.0, 1.0, 0.0), // 2
    float3(1.0, 0.0, 0.0), // 3
    float3(0.0, 0.0, 1.0), // 4
    float3(0.0, 1.0, 1.0), // 5
    float3(1.0, 1.0, 1.0), // 6
    float3(1.0, 0.0, 1.0), // 7
};

void clayxels_microVoxels_vert(uint chunkId, uint vertexId, float3 positionOS, out float3 vertexPos, out float3 boundsCenter, out float3 boundsSize){
    vertexPos = 0;
    boundsCenter = 0;
    boundsSize = 0;

    int chunkIdOffset = chunkId * 6;
    int minX = boundingBox[chunkIdOffset];
    int minY = boundingBox[chunkIdOffset + 1];
    int minZ = boundingBox[chunkIdOffset + 2];

    int maxX = boundingBox[chunkIdOffset + 3];
    int maxY = boundingBox[chunkIdOffset + 4];
    int maxZ = boundingBox[chunkIdOffset + 5];

    float3 chunkCenter = chunksCenter[chunkId];

    int maxExt = (minX + minY + minZ) - (maxX + maxY + maxZ);
    if(maxExt == 192){
        // if bounding box covers the whole chunk, it's an empty chunk
        vertexPos = chunkCenter;

        return;
    }

    float halfChunk = chunkSize * 0.5;
    float cellSizeMip2 = chunkSize * 0.015625; // div by 64
    float cellSizeMip3 = chunkSize * 0.00390625; // div by 256

    float3 minVec = halfChunk - (float3(minX, minY, minZ) * cellSizeMip2) + (cellSizeMip2*0.5);
    float3 maxVec = -halfChunk + (float3(maxX, maxY, maxZ) * cellSizeMip2) + (cellSizeMip2 * 2);

    vertexPos = ((positionOS * -2.0) * lerp(maxVec, minVec, boundingBoxMask[vertexId % 8])) + chunkCenter;
    boundsCenter = (maxVec - minVec) * 0.5;
    boundsSize = float3(
        max(minVec.x + boundsCenter.x, maxVec.x - boundsCenter.x),
        max(minVec.y + boundsCenter.y, maxVec.y - boundsCenter.y),
        max(minVec.z + boundsCenter.z, maxVec.z - boundsCenter.z));
}

int idFromGridCoord(int x, int y, int z, int gridSize){
   return x + gridSize * (y + (gridSize * z));
}

float3 advanceRay(float3 ro, float3 s, float3 m, float3 k, float3 boxPos){
    ro -= boxPos;
    // float3 m = 1.0 / rd; // can precompute if traversing a set of aligned boxes
    float3 n = m * ro;   // can precompute if traversing a set of aligned boxes
    // float3 k = abs(m) * boxSize;
    float3 t1 = -n - k;
    float3 t2 = -n + k;
    float tN = max( max( t1.x, t1.y ), t1.z );
    
    float3 advanceDir = s*step(t1.yzx,t1.xyz)*step(t1.zxy,t1.xyz);

    return advanceDir;
}
uint pack66884(uint a, uint b, uint c, uint d, uint e){
    uint packedValue = ((((a << 6 | b) << 8 | c) << 8 | d) << 4) | e;

    return packedValue;
}

float3 findFragmentStartPos(float3 positionWS, float3 viewDirectionWS, float3 boundsCenter, float3 boundsSize, float3 chunkCenter, float3 containerOffset, float3 boxRayCastM, float cellSizeMip2){
    // flip the bounds inside-out
    float invertT = boundsIntersection(((positionWS - chunkCenter) - boundsCenter), viewDirectionWS, boundsSize, boxRayCastM);
    float3 flippedFragPos = positionWS + (viewDirectionWS * invertT);
    float3 voxelFragPos = flippedFragPos - chunkCenter + containerOffset;

    return voxelFragPos;
}

bool clayxels_microVoxelsMip3Fast_frag(uint chunkId, float3 positionWS, float3 viewDirectionWS, float3 boundsCenter, float3 boundsSize, out float3 hitNormal, out float3 hitColor, out float3 hitDepthPoint){
    hitNormal = float3(0, 1, 0);
    hitColor = float3(1, 1, 1);
    hitDepthPoint = float3(0, 0, 0);

    float cellSizeMip2 = chunkSize * 0.015625;// div by 64
    float halfCellSizeMip2 = cellSizeMip2 * 0.5;
    float cellSizeMip3 = chunkSize * 0.00390625;// div by 256
    float halfCellSizeMip3 = cellSizeMip3 * 0.5;
    float splatSizeMip3 = cellSizeMip3;// * 0.78;

    int chunkOffsetIdMip2 = chunkId * 262144;
    int chunkOffsetMip3 = chunkId * 16777216;

    float3 boxRayCastM = 1.0 / viewDirectionWS;
    float3 boxRayCastK = abs(boxRayCastM) * halfCellSizeMip2;
    float3 boxRayCastKMip3 = abs(boxRayCastM) * halfCellSizeMip3;
    float3 s = -sign(viewDirectionWS);

    float containerOffset = (chunkSize * 0.5) - halfCellSizeMip3;
    float3 chunkCenter = chunksCenter[chunkId];

    float3 voxelFragPos = findFragmentStartPos(
        positionWS, viewDirectionWS, boundsCenter, boundsSize, chunkCenter, containerOffset, boxRayCastM, cellSizeMip2);

    // start placing the ray adjacent to the mesh boundary
    int3 currCellCoordMip2 = voxelFragPos / cellSizeMip2;
    float3 cellCenterMip2 = float3(cellSizeMip2 * currCellCoordMip2.x, cellSizeMip2 * currCellCoordMip2.y, cellSizeMip2 * currCellCoordMip2.z) + halfCellSizeMip2;
    

    // traverse mip2 grid 64^3
    int traverseStepsMip2 = 160;
    for(int traverseMip2It = 0; traverseMip2It < traverseStepsMip2; ++traverseMip2It){
        float3 advanceVec = advanceRay(voxelFragPos, s, boxRayCastM, boxRayCastK, cellCenterMip2);
        currCellCoordMip2 = currCellCoordMip2 + advanceVec;
        
        if(currCellCoordMip2.x < 0 || currCellCoordMip2.y < 0 || currCellCoordMip2.z < 0 ||
            currCellCoordMip2.x > 63 || currCellCoordMip2.y > 63 || currCellCoordMip2.z > 63){

            return false;
        }

        uint cellCoordIdMip2 = idFromGridCoord(currCellCoordMip2.x, currCellCoordMip2.y, currCellCoordMip2.z, 64);

        cellCenterMip2 = float3(cellSizeMip2 * currCellCoordMip2.x, cellSizeMip2 * currCellCoordMip2.y, cellSizeMip2 * currCellCoordMip2.z) + halfCellSizeMip2;
        
        int mip2Pointer = gridPointersMip2[chunkOffsetIdMip2 + cellCoordIdMip2];

        // if this mip2 voxel is filled
        if(mip2Pointer != -1){
            uint gridPointerMip2 = pointCloudDataMip3[chunkOffsetMip3 + mip2Pointer].x;

            float3 rayPos = projectRayOnPlane(voxelFragPos, viewDirectionWS, cellCenterMip2 - (advanceVec * halfCellSizeMip2), -advanceVec);

            float3 cellCornerMip2 = (cellCenterMip2 - halfCellSizeMip2);

            int3 currCellCoordMip3 = ((rayPos - cellCornerMip2) / cellSizeMip3);
            
            int cellCoordIdMip3 = idFromGridCoord(currCellCoordMip3.x, currCellCoordMip3.y, currCellCoordMip3.z, 4);
            
            float3 cellCenterMip3 = cellCornerMip2 + (float3(cellSizeMip3 * currCellCoordMip3.x, cellSizeMip3 * currCellCoordMip3.y, cellSizeMip3 * currCellCoordMip3.z) + halfCellSizeMip3);

            // traverse at mip3 level
            for(int traverseMip3It = 0; traverseMip3It < 16; ++traverseMip3It){
                // check we're inside a 4^3 grid
                if(currCellCoordMip3.x > -1 && currCellCoordMip3.y > -1 && currCellCoordMip3.z > -1 &&
                    currCellCoordMip3.x < 4 && currCellCoordMip3.y < 4 && currCellCoordMip3.z < 4){ 

                    int gridPointerMip3 = gridPointersMip3[chunkOffsetMip3 + gridPointerMip2 + cellCoordIdMip3];

                    // check if this cell contains a voxel
                    if(gridPointerMip3 != -1){
                        uint mip3Iter;
                        uint mip3Pointer;
                        unpack824(gridPointerMip3, mip3Iter, mip3Pointer);

                        int2 mip3Data = pointCloudDataMip3[chunkOffsetMip3 + mip3Pointer + mip3Iter + 1];
                        
                        uint normalX = (0x0000FF00 & mip3Data.x) >> 8;
                        uint normalY = (0x000000FF & mip3Data.x);

                        float3 normalMip3 = unpackNormal(normalX * 0.00390625, normalY * 0.00390625); // div by 256

                        float d = dot(normalMip3, viewDirectionWS);

                        if(d > 0.0){
                            uint normalOffsetInt = (0x00FF0000 & mip3Data.x) >> 16;

                            float normalOffsetMip3 = (((normalOffsetInt * 0.00390625) * 2.0) - 1.0) * cellSizeMip3;

                            float3 cellPlanePosMip3 = cellCenterMip3 + (normalMip3 * normalOffsetMip3);

                            // project ray onto plane at cell center
                            float t = dot(cellPlanePosMip3 - voxelFragPos, normalMip3) / d;
                            float3 projectedPointMip3 = voxelFragPos + (viewDirectionWS * t);

                            float3 splatMip3 = projectedPointMip3 - cellPlanePosMip3;
                            float splatCircle = length(splatMip3);
                            if(splatCircle < splatSizeMip3){
                                int4 data2Mip3 = unpack66614(mip3Data.y);
                                hitColor = data2Mip3.xyz * 0.015625; // div 64

                                hitNormal = normalMip3;
                                hitDepthPoint = cellPlanePosMip3 - containerOffset + chunkCenter;

                                return true;
                            }

                            traverseStepsMip2 *= 1.0 - (d * 0.5);
                        }
                    }
                }
                
                float3 advanceVecMip3 = advanceRay(voxelFragPos, s, boxRayCastM, boxRayCastKMip3, cellCenterMip3);
                currCellCoordMip3 = currCellCoordMip3 + advanceVecMip3;

                if(currCellCoordMip3.x < 0 || currCellCoordMip3.y < 0 || currCellCoordMip3.z < 0 ||
                    currCellCoordMip3.x > 3 || currCellCoordMip3.y > 3 || currCellCoordMip3.z > 3){
                    break;
                }

                cellCoordIdMip3 = idFromGridCoord(currCellCoordMip3.x, currCellCoordMip3.y, currCellCoordMip3.z, 4);

                cellCenterMip3 = cellCornerMip2 + (float3(cellSizeMip3 * currCellCoordMip3.x, cellSizeMip3 * currCellCoordMip3.y, cellSizeMip3 * currCellCoordMip3.z) + halfCellSizeMip3);
            }
        }
    }

    return false;
}

bool clayxels_microVoxelsMip3Shadow_frag(uint chunkId, float3 positionWS, float3 viewDirectionWS, float3 boundsCenter, float3 boundsSize, out float3 hitNormal, out float3 hitDepthPoint){
    hitNormal = 0;
    hitDepthPoint = 0;

    float cellSizeMip2 = chunkSize * 0.015625;// div by 64
    float halfCellSizeMip2 = cellSizeMip2 * 0.5;
    float cellSizeMip3 = chunkSize * 0.00390625;// div by 256
    float halfCellSizeMip3 = cellSizeMip3 * 0.5;
    float splatSizeMip3 = cellSizeMip3;// * 0.78;

    int chunkOffsetIdMip2 = chunkId * 262144;
    int chunkOffsetMip3 = chunkId * 16777216;
    
    float3 boxRayCastM = 1.0 / viewDirectionWS;
    float3 boxRayCastK = abs(boxRayCastM) * halfCellSizeMip2;
    float3 boxRayCastKMip3 = abs(boxRayCastM) * halfCellSizeMip3;
    float3 s = -sign(viewDirectionWS);

    float containerOffset = (chunkSize * 0.5) - halfCellSizeMip3;
    float3 chunkCenter = chunksCenter[chunkId];

    float3 voxelFragPos = findFragmentStartPos(
        positionWS, viewDirectionWS, boundsCenter, boundsSize, chunkCenter, containerOffset, boxRayCastM, cellSizeMip2);
    
    // start placing the ray adjacent to the mesh boundary
    int3 currCellCoordMip2 = voxelFragPos / cellSizeMip2;
    float3 cellCenterMip2 = float3(cellSizeMip2 * currCellCoordMip2.x, cellSizeMip2 * currCellCoordMip2.y, cellSizeMip2 * currCellCoordMip2.z) + halfCellSizeMip2;

    // traverse mip2 grid 64^3
    int traverseStepsMip2 = 64;
    for(int traverseMip2It = 0; traverseMip2It < traverseStepsMip2; ++traverseMip2It){
        float3 advanceVec = advanceRay(voxelFragPos, s, boxRayCastM, boxRayCastK, cellCenterMip2);
        currCellCoordMip2 = currCellCoordMip2 + advanceVec;
        
        if(currCellCoordMip2.x < 0 || currCellCoordMip2.y < 0 || currCellCoordMip2.z < 0 ||
            currCellCoordMip2.x > 63 || currCellCoordMip2.y > 63 || currCellCoordMip2.z > 63){

            return false;
        }

        uint cellCoordIdMip2 = idFromGridCoord(currCellCoordMip2.x, currCellCoordMip2.y, currCellCoordMip2.z, 64);

        cellCenterMip2 = float3(cellSizeMip2 * currCellCoordMip2.x, cellSizeMip2 * currCellCoordMip2.y, cellSizeMip2 * currCellCoordMip2.z) + halfCellSizeMip2;
        
        int mip2Pointer = gridPointersMip2[chunkOffsetIdMip2 + cellCoordIdMip2];

        // if this mip2 voxel is filled
        if(mip2Pointer != -1){
            uint gridPointerMip2 = pointCloudDataMip3[chunkOffsetMip3 + mip2Pointer].x;

            float3 rayPos = projectRayOnPlane(voxelFragPos, viewDirectionWS, cellCenterMip2 - (advanceVec * halfCellSizeMip2), -advanceVec);

            float3 cellCornerMip2 = (cellCenterMip2 - halfCellSizeMip2);

            int3 currCellCoordMip3 = ((rayPos - cellCornerMip2) / cellSizeMip3);
            
            int cellCoordIdMip3 = idFromGridCoord(currCellCoordMip3.x, currCellCoordMip3.y, currCellCoordMip3.z, 4);
            
            float3 cellCenterMip3 = cellCornerMip2 + (float3(cellSizeMip3 * currCellCoordMip3.x, cellSizeMip3 * currCellCoordMip3.y, cellSizeMip3 * currCellCoordMip3.z) + halfCellSizeMip3);

            // traverse at mip3 level
            for(int traverseMip3It = 0; traverseMip3It < 16; ++traverseMip3It){
                // check we're inside a 4^3 grid
                if(currCellCoordMip3.x > -1 && currCellCoordMip3.y > -1 && currCellCoordMip3.z > -1 &&
                    currCellCoordMip3.x < 4 && currCellCoordMip3.y < 4 && currCellCoordMip3.z < 4){ 

                    int gridPointerMip3 = gridPointersMip3[chunkOffsetMip3 + gridPointerMip2 + cellCoordIdMip3];

                    // check if this cell contains a voxel
                    if(gridPointerMip3 != -1){
                        uint mip3Iter;
                        uint mip3Pointer;
                        unpack824(gridPointerMip3, mip3Iter, mip3Pointer);

                        int2 mip3Data = pointCloudDataMip3[chunkOffsetMip3 + mip3Pointer + mip3Iter + 1];
                        
                        uint normalX = (0x0000FF00 & mip3Data.x) >> 8;
                        uint normalY = (0x000000FF & mip3Data.x);

                        float3 normalMip3 = unpackNormal(normalX * 0.00390625, normalY * 0.00390625); // div by 256

                        float d = dot(normalMip3, viewDirectionWS);

                        if(d > 0.0){
                            uint normalOffsetInt = (0x00FF0000 & mip3Data.x) >> 16;

                            float normalOffsetMip3 = (((normalOffsetInt * 0.00390625) * 2.0) - 1.0) * cellSizeMip3;

                            float3 cellPlanePosMip3 = cellCenterMip3 + (normalMip3 * normalOffsetMip3);

                            hitNormal = normalMip3;
                            hitDepthPoint = cellPlanePosMip3 - containerOffset + chunkCenter;

                            return true;
                        }
                    }
                }
                
                float3 advanceVecMip3 = advanceRay(voxelFragPos, s, boxRayCastM, boxRayCastKMip3, cellCenterMip3);
                currCellCoordMip3 = currCellCoordMip3 + advanceVecMip3;

                if(currCellCoordMip3.x < 0 || currCellCoordMip3.y < 0 || currCellCoordMip3.z < 0 ||
                    currCellCoordMip3.x > 3 || currCellCoordMip3.y > 3 || currCellCoordMip3.z > 3){
                    break;
                }

                cellCoordIdMip3 = idFromGridCoord(currCellCoordMip3.x, currCellCoordMip3.y, currCellCoordMip3.z, 4);

                cellCenterMip3 = cellCornerMip2 + (float3(cellSizeMip3 * currCellCoordMip3.x, cellSizeMip3 * currCellCoordMip3.y, cellSizeMip3 * currCellCoordMip3.z) + halfCellSizeMip3);
            }
        }
    }

    return false;
}

bool clayxels_microVoxelsMip3Splat_frag(float roughColor, uint chunkId, float3 positionWS, float3 viewDirectionWS, float3 boundsCenter, float3 boundsSize, out float3 hitNormal, out float3 hitColor, out float3 hitDepthPoint){
    hitNormal = float3(0, 1, 0);
    hitColor = float3(1, 1, 1);
    hitDepthPoint = float3(0, 0, 0);

    float cellSizeMip2 = chunkSize * 0.015625;// div by 64
    float halfCellSizeMip2 = cellSizeMip2 * 0.5;
    float cellSizeMip3 = chunkSize * 0.00390625;// div by 256
    float halfCellSizeMip3 = cellSizeMip3 * 0.5;
    float splatSizeMip3 = cellSizeMip3 * 0.78;

    int chunkOffsetIdMip2 = chunkId * 262144;
    int chunkOffsetMip3 = chunkId * 16777216;    
    
    float3 boxRayCastM = 1.0 / viewDirectionWS;
    float3 boxRayCastK = abs(boxRayCastM) * halfCellSizeMip2;
    float3 boxRayCastKMip3 = abs(boxRayCastM) * splatSizeMip3;
    float3 s = -sign(viewDirectionWS);

    float containerOffset = (chunkSize * 0.5) - halfCellSizeMip3;
    float3 chunkCenter = chunksCenter[chunkId];

    float3 voxelFragPos = findFragmentStartPos(
        positionWS, viewDirectionWS, boundsCenter, boundsSize, chunkCenter, containerOffset, boxRayCastM, cellSizeMip2);

    // start placing the ray adjacent to the mesh boundary
    int3 currCellCoordMip2 = voxelFragPos / cellSizeMip2;
    float3 cellCenterMip2 = float3(cellSizeMip2 * currCellCoordMip2.x, cellSizeMip2 * currCellCoordMip2.y, cellSizeMip2 * currCellCoordMip2.z) + halfCellSizeMip2;

    // traverse mip2 grid 64^3
    int traverseStepsMip2 = 160;
    for(int traverseMip2It = 0; traverseMip2It < traverseStepsMip2; ++traverseMip2It){
        float3 advanceVec = advanceRay(voxelFragPos, s, boxRayCastM, boxRayCastK, cellCenterMip2);
        currCellCoordMip2 = currCellCoordMip2 + advanceVec;
        
        if(currCellCoordMip2.x < 0 || currCellCoordMip2.y < 0 || currCellCoordMip2.z < 0 ||
            currCellCoordMip2.x > 63 || currCellCoordMip2.y > 63 || currCellCoordMip2.z > 63){

            return false;
        }

        uint cellCoordIdMip2 = idFromGridCoord(currCellCoordMip2.x, currCellCoordMip2.y, currCellCoordMip2.z, 64);

        cellCenterMip2 = float3(cellSizeMip2 * currCellCoordMip2.x, cellSizeMip2 * currCellCoordMip2.y, cellSizeMip2 * currCellCoordMip2.z) + halfCellSizeMip2;
        
        int mip2Pointer = gridPointersMip2[chunkOffsetIdMip2 + cellCoordIdMip2];

        // if this mip2 voxel is filled
        if(mip2Pointer != -1){
            int2 mip2Data = pointCloudDataMip3[chunkOffsetMip3 + mip2Pointer];
            int numMip3Cells = mip2Data.y >> 24;

            float3 cellCornerMip2 = (cellCenterMip2 - halfCellSizeMip2);

            // traverse at mip3 level
            for(int mip3Iter = 0; mip3Iter < numMip3Cells; ++mip3Iter){
                int2 mip3Data = pointCloudDataMip3[chunkOffsetMip3 + mip2Pointer + mip3Iter + 1];
                uint localCellCoordMip3 = mip3Data.x >> 24;
                
                int3 currCellCoordMip3 = mip3CellIter[localCellCoordMip3];
                
                float3 cellCenterMip3 = cellCornerMip2 + (float3(cellSizeMip3 * currCellCoordMip3.x, cellSizeMip3 * currCellCoordMip3.y, cellSizeMip3 * currCellCoordMip3.z) + halfCellSizeMip3);
                
                float mip3Intersect = boxIntersectionFast(voxelFragPos, boxRayCastM, boxRayCastKMip3, cellCenterMip3);
                if(mip3Intersect != -1.0){
                    uint normalX = (0x0000FF00 & mip3Data.x) >> 8;
                    uint normalY = (0x000000FF & mip3Data.x);

                    float3 normalMip3 = unpackNormal(normalX * 0.00390625, normalY * 0.00390625); // div by 256

                    float d = dot(normalMip3, viewDirectionWS);

                    if(d > 0.0){
                        uint normalOffsetInt = (0x00FF0000 & mip3Data.x) >> 16;

                        float normalOffsetMip3 = (((normalOffsetInt * 0.00390625) * 2.0) - 1.0) * cellSizeMip3;

                        float3 cellPlanePosMip3 = cellCenterMip3 + (normalMip3 * normalOffsetMip3);

                        // project ray onto plane at cell center
                        float t = dot(cellPlanePosMip3 - voxelFragPos, normalMip3) / d;
                        float3 projectedPointMip3 = voxelFragPos + (viewDirectionWS * t);

                        float3 splatMip3 = projectedPointMip3 - cellPlanePosMip3;
                        float splatCircle = length(splatMip3);
                        if(splatCircle < splatSizeMip3){
                            int4 data2Mip3 = unpack66614(mip3Data.y);

                            hitColor = data2Mip3.xyz * 0.015625; // div 64

                            float mip3Random = frac(sin(dot(float2(cellCenterMip3.x, cellCenterMip3.y),float2(12.9898,78.233+cellCenterMip3.z)))*43758.5453123);
                            hitColor *= 1.0 - (mip3Random * roughColor);

                            int solidId = data2Mip3.w;
                            if(solidHighlightId == -2){
                                hitColor = hitColor * 2.0;  
                            }
                            else if(solidHighlightId > -1){
                                if(solidId == solidHighlightId + 1){
                                    hitColor = hitColor * 2.0;
                                }
                            }

                            hitNormal = normalMip3;
                            hitDepthPoint = projectedPointMip3 - containerOffset + chunkCenter;

                            return true;
                        }

                        // decimate traversal steps based on the angle of impact on this splat
                        traverseStepsMip2 *= 1.0 - (d * 0.1);
                    }
                }
            }
        }
    }

    return false;
}

bool clayxels_microVoxelsMip3Vox_frag(float roughColor, uint chunkId, float3 positionWS, float3 viewDirectionWS, float3 boundsCenter, float3 boundsSize, out float3 hitNormal, out float3 hitColor, out float3 hitDepthPoint){
    hitNormal = float3(0, 1, 0);
    hitColor = float3(1, 1, 1);
    hitDepthPoint = float3(0, 0, 0);

    float cellSizeMip2 = chunkSize * 0.015625;// div by 64
    float halfCellSizeMip2 = cellSizeMip2 * 0.5;
    float cellSizeMip3 = chunkSize * 0.00390625;// div by 256
    float halfCellSizeMip3 = cellSizeMip3 * 0.5;
    float splatSizeMip3 = cellSizeMip3;// * 0.78;

    int chunkOffsetIdMip2 = chunkId * 262144;
    int chunkOffsetMip3 = chunkId * 16777216;

    float3 boxRayCastM = 1.0 / viewDirectionWS;
    float3 boxRayCastK = abs(boxRayCastM) * halfCellSizeMip2;
    float3 boxRayCastKMip3 = abs(boxRayCastM) * halfCellSizeMip3;
    float3 s = -sign(viewDirectionWS);

    float containerOffset = (chunkSize * 0.5) - halfCellSizeMip3;
    float3 chunkCenter = chunksCenter[chunkId];

    float3 voxelFragPos = findFragmentStartPos(
        positionWS, viewDirectionWS, boundsCenter, boundsSize, chunkCenter, containerOffset, boxRayCastM, cellSizeMip2);

    // start placing the ray adjacent to the mesh boundary
    int3 currCellCoordMip2 = voxelFragPos / cellSizeMip2;
    float3 cellCenterMip2 = float3(cellSizeMip2 * currCellCoordMip2.x, cellSizeMip2 * currCellCoordMip2.y, cellSizeMip2 * currCellCoordMip2.z) + halfCellSizeMip2;

    // traverse mip2 grid 64^3
    int traverseStepsMip2 = 160;
    for(int traverseMip2It = 0; traverseMip2It < traverseStepsMip2; ++traverseMip2It){
        float3 advanceVec = advanceRay(voxelFragPos, s, boxRayCastM, boxRayCastK, cellCenterMip2);
        currCellCoordMip2 = currCellCoordMip2 + advanceVec;
        
        if(currCellCoordMip2.x < 0 || currCellCoordMip2.y < 0 || currCellCoordMip2.z < 0 ||
            currCellCoordMip2.x > 63 || currCellCoordMip2.y > 63 || currCellCoordMip2.z > 63){

            return false;
        }

        uint cellCoordIdMip2 = idFromGridCoord(currCellCoordMip2.x, currCellCoordMip2.y, currCellCoordMip2.z, 64);

        cellCenterMip2 = float3(cellSizeMip2 * currCellCoordMip2.x, cellSizeMip2 * currCellCoordMip2.y, cellSizeMip2 * currCellCoordMip2.z) + halfCellSizeMip2;
        
        int mip2Pointer = gridPointersMip2[chunkOffsetIdMip2 + cellCoordIdMip2];

        // if this mip2 voxel is filled
        if(mip2Pointer != -1){
            uint gridPointerMip2 = pointCloudDataMip3[chunkOffsetMip3 + mip2Pointer].x;

            float3 rayPos = projectRayOnPlane(voxelFragPos, viewDirectionWS, cellCenterMip2 - (advanceVec * halfCellSizeMip2), -advanceVec);

            float3 cellCornerMip2 = (cellCenterMip2 - halfCellSizeMip2);

            int3 currCellCoordMip3 = ((rayPos - cellCornerMip2) / cellSizeMip3);
            
            int cellCoordIdMip3 = idFromGridCoord(currCellCoordMip3.x, currCellCoordMip3.y, currCellCoordMip3.z, 4);
            
            float3 cellCenterMip3 = cellCornerMip2 + (float3(cellSizeMip3 * currCellCoordMip3.x, cellSizeMip3 * currCellCoordMip3.y, cellSizeMip3 * currCellCoordMip3.z) + halfCellSizeMip3);

            // traverse at mip3 level
            for(int traverseMip3It = 0; traverseMip3It < 16; ++traverseMip3It){
                // check we're inside a 4^3 grid
                if(currCellCoordMip3.x > -1 && currCellCoordMip3.y > -1 && currCellCoordMip3.z > -1 &&
                    currCellCoordMip3.x < 4 && currCellCoordMip3.y < 4 && currCellCoordMip3.z < 4){ 

                    int gridPointerMip3 = gridPointersMip3[chunkOffsetMip3 + gridPointerMip2 + cellCoordIdMip3];

                    // check if this cell contains a voxel
                    if(gridPointerMip3 != -1){
                        float3 voxelNormal = 0;
                        float boxHit = boxIntersectionNormalFast(voxelFragPos, s, boxRayCastM, boxRayCastKMip3, cellCenterMip3, voxelNormal);

                        if(boxHit > -1.0){
                            float mip3Random = frac(sin(dot(float2(cellCenterMip3.x, cellCenterMip3.y),float2(12.9898,78.233+cellCenterMip3.z)))*43758.5453123);

                            float3 voxelHitPlane = cellCenterMip3 + (voxelNormal * halfCellSizeMip3);
                            float3 projectedPoint = projectRayOnPlane(voxelFragPos, viewDirectionWS, voxelHitPlane, voxelNormal);

                            uint mip3Iter;
                            uint mip3Pointer;
                            unpack824(gridPointerMip3, mip3Iter, mip3Pointer);
                            int2 mip3Data = pointCloudDataMip3[chunkOffsetMip3 + mip3Pointer + mip3Iter + 1];

                            int4 data2Mip3 = unpack66614(mip3Data.y);
                            hitColor = data2Mip3.xyz * 0.015625; // div 64
                            hitColor *= 1.0 - (mip3Random * roughColor);

                            hitNormal = voxelNormal;
                            hitDepthPoint = voxelHitPlane - containerOffset + chunkCenter;

                            int solidId = data2Mip3.w;
                            if(solidHighlightId == -2){
                                hitColor = hitColor * 2.0;  
                            }
                            else if(solidHighlightId > -1){
                                if(solidId == solidHighlightId + 1){
                                    hitColor = hitColor * 2.0;
                                }
                            }

                            return true;
                        }
                    }
                }
                
                float3 advanceVecMip3 = advanceRay(voxelFragPos, s, boxRayCastM, boxRayCastKMip3, cellCenterMip3);
                currCellCoordMip3 = currCellCoordMip3 + advanceVecMip3;

                if(currCellCoordMip3.x < 0 || currCellCoordMip3.y < 0 || currCellCoordMip3.z < 0 ||
                    currCellCoordMip3.x > 3 || currCellCoordMip3.y > 3 || currCellCoordMip3.z > 3){
                    break;
                }

                cellCoordIdMip3 = idFromGridCoord(currCellCoordMip3.x, currCellCoordMip3.y, currCellCoordMip3.z, 4);

                cellCenterMip3 = cellCornerMip2 + (float3(cellSizeMip3 * currCellCoordMip3.x, cellSizeMip3 * currCellCoordMip3.y, cellSizeMip3 * currCellCoordMip3.z) + halfCellSizeMip3);
            }
        }
    }

    return false;
}

bool clayxels_microVoxelsMip3Pick_frag(uint chunkId, float3 positionWS, float3 viewDirectionWS, float3 boundsCenter, float3 boundsSize, out uint hitClayObjId, out float3 hitDepthPoint){
    hitClayObjId = 0;
    hitDepthPoint = 0;

    float cellSizeMip2 = chunkSize * 0.015625;// div by 64
    float halfCellSizeMip2 = cellSizeMip2 * 0.5;
    float cellSizeMip3 = chunkSize * 0.00390625;// div by 256
    float halfCellSizeMip3 = cellSizeMip3 * 0.5;
    float splatSizeMip3 = cellSizeMip3;// * 0.78;

    int chunkOffsetIdMip2 = chunkId * 262144;
    int chunkOffsetMip3 = chunkId * 16777216;

    float3 boxRayCastM = 1.0 / viewDirectionWS;
    float3 boxRayCastK = abs(boxRayCastM) * halfCellSizeMip2;
    float3 boxRayCastKMip3 = abs(boxRayCastM) * halfCellSizeMip3;
    float3 s = -sign(viewDirectionWS);

    float containerOffset = (chunkSize * 0.5) - halfCellSizeMip3;
    float3 chunkCenter = chunksCenter[chunkId];

    float3 voxelFragPos = findFragmentStartPos(
        positionWS, viewDirectionWS, boundsCenter, boundsSize, chunkCenter, containerOffset, boxRayCastM, cellSizeMip2);
    
    // start placing the ray adjacent to the mesh boundary
    int3 currCellCoordMip2 = voxelFragPos / cellSizeMip2; 
    float3 cellCenterMip2 = float3(cellSizeMip2 * currCellCoordMip2.x, cellSizeMip2 * currCellCoordMip2.y, cellSizeMip2 * currCellCoordMip2.z) + halfCellSizeMip2;

    // traverse mip2 grid 64^3
    int traverseStepsMip2 = 160;
    for(int traverseMip2It = 0; traverseMip2It < traverseStepsMip2; ++traverseMip2It){
        float3 advanceVec = advanceRay(voxelFragPos, s, boxRayCastM, boxRayCastK, cellCenterMip2);
        currCellCoordMip2 = currCellCoordMip2 + advanceVec;
        
        if(currCellCoordMip2.x < 0 || currCellCoordMip2.y < 0 || currCellCoordMip2.z < 0 ||
            currCellCoordMip2.x > 63 || currCellCoordMip2.y > 63 || currCellCoordMip2.z > 63){

            return false;
        }

        uint cellCoordIdMip2 = idFromGridCoord(currCellCoordMip2.x, currCellCoordMip2.y, currCellCoordMip2.z, 64);

        cellCenterMip2 = float3(cellSizeMip2 * currCellCoordMip2.x, cellSizeMip2 * currCellCoordMip2.y, cellSizeMip2 * currCellCoordMip2.z) + halfCellSizeMip2;
        
        int mip2Pointer = gridPointersMip2[chunkOffsetIdMip2 + cellCoordIdMip2];

        // if this mip2 voxel is filled
        if(mip2Pointer != -1){
            uint gridPointerMip2 = pointCloudDataMip3[chunkOffsetMip3 + mip2Pointer].x;

            float3 rayPos = projectRayOnPlane(voxelFragPos, viewDirectionWS, cellCenterMip2 - (advanceVec * halfCellSizeMip2), -advanceVec);

            float3 cellCornerMip2 = (cellCenterMip2 - halfCellSizeMip2);

            int3 currCellCoordMip3 = ((rayPos - cellCornerMip2) / cellSizeMip3);
            
            int cellCoordIdMip3 = idFromGridCoord(currCellCoordMip3.x, currCellCoordMip3.y, currCellCoordMip3.z, 4);
            
            float3 cellCenterMip3 = cellCornerMip2 + (float3(cellSizeMip3 * currCellCoordMip3.x, cellSizeMip3 * currCellCoordMip3.y, cellSizeMip3 * currCellCoordMip3.z) + halfCellSizeMip3);

            // traverse at mip3 level
            for(int traverseMip3It = 0; traverseMip3It < 16; ++traverseMip3It){
                // check we're inside a 4^3 grid
                if(currCellCoordMip3.x > -1 && currCellCoordMip3.y > -1 && currCellCoordMip3.z > -1 &&
                    currCellCoordMip3.x < 4 && currCellCoordMip3.y < 4 && currCellCoordMip3.z < 4){ 

                    int gridPointerMip3 = gridPointersMip3[chunkOffsetMip3 + gridPointerMip2 + cellCoordIdMip3];

                    // check if this cell contains a voxel
                    if(gridPointerMip3 != -1){
                        uint mip3Iter;
                        uint mip3Pointer;
                        unpack824(gridPointerMip3, mip3Iter, mip3Pointer);

                        int2 mip3Data = pointCloudDataMip3[chunkOffsetMip3 + mip3Pointer + mip3Iter + 1];
                        int4 data2Mip3 = unpack66614(mip3Data.y);

                        hitClayObjId = data2Mip3.w;

                        hitDepthPoint = cellCenterMip3 - containerOffset + chunkCenter;
                                
                        return true;
                    }
                }
                
                float3 advanceVecMip3 = advanceRay(voxelFragPos, s, boxRayCastM, boxRayCastKMip3, cellCenterMip3);
                currCellCoordMip3 = currCellCoordMip3 + advanceVecMip3;

                if(currCellCoordMip3.x < 0 || currCellCoordMip3.y < 0 || currCellCoordMip3.z < 0 ||
                    currCellCoordMip3.x > 3 || currCellCoordMip3.y > 3 || currCellCoordMip3.z > 3){
                    break;
                }

                cellCoordIdMip3 = idFromGridCoord(currCellCoordMip3.x, currCellCoordMip3.y, currCellCoordMip3.z, 4);

                cellCenterMip3 = cellCornerMip2 + (float3(cellSizeMip3 * currCellCoordMip3.x, cellSizeMip3 * currCellCoordMip3.y, cellSizeMip3 * currCellCoordMip3.z) + halfCellSizeMip3);
            }
        }
    }

    return false;
}

bool clayxels_microVoxelsMip2Tex_frag(float roughColor, float splatSize, float roughOrientX, float roughOrientY, float roughOffset, float alphaCutout, uint chunkId, float3 positionWS, float3 viewDirectionWS, float3 boundsCenter, float3 boundsSize, out float3 hitNormal, out float3 hitColor, out float3 hitDepthPoint){
    hitNormal = float3(0, 1, 0);
    hitColor = float3(1, 1, 1);
    hitDepthPoint = float3(0, 0, 0);

    float cellSizeMip2 = chunkSize * 0.015625;// div by 64
    float halfCellSizeMip2 = cellSizeMip2 * 0.5;
    float cellSizeMip3 = chunkSize * 0.00390625;// div by 256
    float halfCellSizeMip3 = cellSizeMip3 * 0.5;
    float splatSizeMip2 = cellSizeMip2 * splatSize;

    int chunkOffsetIdMip2 = chunkId * 262144;
    int chunkOffsetMip3 = chunkId * 16777216;

    float3 boxRayCastM = 1.0 / viewDirectionWS;
    float3 boxRayCastK = abs(boxRayCastM) * halfCellSizeMip2;
    float3 boxRayCastKMip3 = abs(boxRayCastM) * halfCellSizeMip3;
    float3 s = -sign(viewDirectionWS);

    float containerOffset = (chunkSize * 0.5) - halfCellSizeMip2 + cellSizeMip3;
    float3 chunkCenter = chunksCenter[chunkId];

    float3 voxelFragPos = findFragmentStartPos(
        positionWS, viewDirectionWS, boundsCenter, boundsSize, chunkCenter, containerOffset, boxRayCastM, cellSizeMip2);

    // start placing the ray adjacent to the mesh boundary
    int3 currCellCoordMip2 = voxelFragPos / cellSizeMip2;
    float3 cellCenterMip2 = float3(cellSizeMip2 * currCellCoordMip2.x, cellSizeMip2 * currCellCoordMip2.y, cellSizeMip2 * currCellCoordMip2.z) + halfCellSizeMip2;
    
    float3 camUpVec = UNITY_MATRIX_V._m10_m11_m12;

    // traverse mip2 grid 64^3
    int traverseSteps = 160;
    for(int traverseMip2It = 0; traverseMip2It < traverseSteps; ++traverseMip2It){
        float3 advanceVec = advanceRay(voxelFragPos, s, boxRayCastM, boxRayCastK, cellCenterMip2);
        currCellCoordMip2 = currCellCoordMip2 + advanceVec;

        if(currCellCoordMip2.x < 0 || currCellCoordMip2.y < 0 || currCellCoordMip2.z < 0 ||
            currCellCoordMip2.x > 63 || currCellCoordMip2.y > 63 || currCellCoordMip2.z > 63){

            return false;
        }

        uint cellCoordIdMip2Main = idFromGridCoord(currCellCoordMip2.x, currCellCoordMip2.y, currCellCoordMip2.z, 64);
        int mip2PointerMain = gridPointersMip2[chunkOffsetIdMip2 + cellCoordIdMip2Main];
        cellCenterMip2 = float3(cellSizeMip2 * currCellCoordMip2.x, cellSizeMip2 * currCellCoordMip2.y, cellSizeMip2 * currCellCoordMip2.z) + halfCellSizeMip2;

        // if this mip2 voxel is filled
        if(mip2PointerMain != -1){
            float depth = 1.0;

            for(int neighbourIter = 0; neighbourIter < 7; ++neighbourIter){
                int3 neighbourCoord = currCellCoordMip2 + neighboursBigSplat[neighbourIter];

                if(neighbourCoord.x < 0 || neighbourCoord.y < 0 || neighbourCoord.z < 0 ||
                    neighbourCoord.x > 63 || neighbourCoord.y > 63 || neighbourCoord.z > 63){

                    continue;
                }

                uint cellCoordIdMip2 = idFromGridCoord(neighbourCoord.x, neighbourCoord.y, neighbourCoord.z, 64);
                float3 cellCenterMip2N = float3(cellSizeMip2 * neighbourCoord.x, cellSizeMip2 * neighbourCoord.y, cellSizeMip2 * neighbourCoord.z) + halfCellSizeMip2;
                int mip2Pointer = gridPointersMip2[chunkOffsetIdMip2 + cellCoordIdMip2];

                // if this mip2 voxel is filled
                if(mip2Pointer != -1){
                    uint mip2Data2 = pointCloudDataMip3[chunkOffsetMip3 + mip2Pointer].y;

                    uint mip3Pointer, mip2NormalX, mip2NormalY, mip2NormalOffsetInt;
                    unpack8888(mip2Data2, mip3Pointer, mip2NormalX, mip2NormalY, mip2NormalOffsetInt);

                    float3 normalMip2 = unpackNormal(mip2NormalX * 0.00390625, mip2NormalY * 0.00390625); // div by 256

                    float mip2Random = (frac(sin(dot(float2(cellCenterMip2N.x, cellCenterMip2N.y),float2(12.9898,78.233+cellCenterMip2N.z)))*43758.5453123) - 1.0) * 0.5;
                    float3 splatRoughNormal = normalMip2;
                    splatRoughNormal.x += (mip2Random * roughOrientX);
                    splatRoughNormal.y += (mip2Random * roughOrientY);
                    splatRoughNormal = normalize(splatRoughNormal);

                    float d = dot(normalMip2, viewDirectionWS);
                    float dRough = dot(splatRoughNormal, viewDirectionWS);

                    if(d > -0.1){
                        float normalOffsetMip2 = ((((mip2NormalOffsetInt * 0.00390625) * 2.0) - 1.0) * cellSizeMip2) + (mip2Random * roughOffset);

                        float3 cellPlanePosMip2 = cellCenterMip2N + (splatRoughNormal * normalOffsetMip2);

                        // project ray onto plane at cell center
                        float t = dot(cellPlanePosMip2 - voxelFragPos, splatRoughNormal) / dRough;

                        float3 projectedPointMip2 = voxelFragPos + (viewDirectionWS * t);

                        if(t < depth){
                            float3 splatMip2 = projectedPointMip2 - cellPlanePosMip2;

                            float3 splatSideVec = normalize(cross(camUpVec, splatRoughNormal));
                            float3 splatUpVec = normalize(cross(splatSideVec, splatRoughNormal));
                            float3 splatTexVec = splatMip2 / (cellSizeMip2 * splatSize);

                            float4 uv = float4(
                                (dot(splatTexVec, splatUpVec) + 1.0) * 0.5,
                                (dot(splatTexVec, splatSideVec) + 1.0) * 0.5,
                                0, 0);

                            float a = tex2Dlod(_MainTex, uv).a;

                            if(a > alphaCutout){
                                depth = t;

                                int4 data2Mip3 = unpack66614(pointCloudDataMip3[chunkOffsetMip3 + mip2Pointer + 1].y);
                                hitColor = data2Mip3.xyz * 0.015625; // div 64

                                hitColor *= 1.0 - (mip2Random * roughColor);

                                hitNormal = normalMip2;
                                hitDepthPoint = projectedPointMip2 - containerOffset + chunkCenter;

                                int solidId = data2Mip3.w;
                                if(solidHighlightId == -2){
                                    hitColor = hitColor * 2.0;  
                                }
                                else if(solidHighlightId > -1){
                                    if(solidId == solidHighlightId + 1){
                                        hitColor = hitColor * 2.0;
                                    }
                                }
                            }
                        }

                        // filter out those rays that impact a splat frontally but miss
                        // traverseSteps *= 1.0 - (d * 0.9);
                    }
                }
            }

             if(depth < 1.0){
                return true;
            }
        }
    }

    return false;
}

bool clayxels_microVoxelsMip2Fast_frag(float splatSize, uint chunkId, float3 positionWS, float3 viewDirectionWS, float3 boundsCenter, float3 boundsSize, out float3 hitNormal, out float3 hitColor, out float3 hitDepthPoint){
    hitNormal = float3(0, 1, 0);
    hitColor = float3(1, 1, 1);
    hitDepthPoint = float3(0, 0, 0);

    float cellSizeMip2 = chunkSize * 0.015625;// div by 64
    float halfCellSizeMip2 = cellSizeMip2 * 0.5;
    float cellSizeMip3 = chunkSize * 0.00390625;// div by 256
    float halfCellSizeMip3 = cellSizeMip3 * 0.5;
    float splatSizeMip2 = cellSizeMip2 * splatSize;

    int chunkOffsetIdMip2 = chunkId * 262144;
    int chunkOffsetMip3 = chunkId * 16777216;

    float3 boxRayCastM = 1.0 / viewDirectionWS;
    float3 boxRayCastK = abs(boxRayCastM) * halfCellSizeMip2;
    float3 boxRayCastKMip3 = abs(boxRayCastM) * halfCellSizeMip3;
    float3 s = -sign(viewDirectionWS);

    float containerOffset = (chunkSize * 0.5) - halfCellSizeMip2 + cellSizeMip3;
    float3 chunkCenter = chunksCenter[chunkId];

    float3 voxelFragPos = findFragmentStartPos(
        positionWS, viewDirectionWS, boundsCenter, boundsSize, chunkCenter, containerOffset, boxRayCastM, cellSizeMip2);

    // start placing the ray adjacent to the mesh boundary
    int3 currCellCoordMip2 = voxelFragPos / cellSizeMip2;
    float3 cellCenterMip2 = float3(cellSizeMip2 * currCellCoordMip2.x, cellSizeMip2 * currCellCoordMip2.y, cellSizeMip2 * currCellCoordMip2.z) + halfCellSizeMip2;

    // traverse mip2 grid 64^3
    int traverseSteps = 160;
    for(int traverseMip2It = 0; traverseMip2It < traverseSteps; ++traverseMip2It){
        float3 advanceVec = advanceRay(voxelFragPos, s, boxRayCastM, boxRayCastK, cellCenterMip2);
        currCellCoordMip2 = currCellCoordMip2 + advanceVec;
        
        if(currCellCoordMip2.x < 0 || currCellCoordMip2.y < 0 || currCellCoordMip2.z < 0 ||
            currCellCoordMip2.x > 63 || currCellCoordMip2.y > 63 || currCellCoordMip2.z > 63){

            return false;
        }

        uint cellCoordIdMip2 = idFromGridCoord(currCellCoordMip2.x, currCellCoordMip2.y, currCellCoordMip2.z, 64);

        cellCenterMip2 = float3(cellSizeMip2 * currCellCoordMip2.x, cellSizeMip2 * currCellCoordMip2.y, cellSizeMip2 * currCellCoordMip2.z) + halfCellSizeMip2;
        
        int mip2Pointer = gridPointersMip2[chunkOffsetIdMip2 + cellCoordIdMip2];

        // if this mip2 voxel is filled
        if(mip2Pointer != -1){
            uint mip2Data2 = pointCloudDataMip3[chunkOffsetMip3 + mip2Pointer].y;

            uint mip3Pointer, mip2NormalX, mip2NormalY, mip2NormalOffsetInt;
            unpack8888(mip2Data2, mip3Pointer, mip2NormalX, mip2NormalY, mip2NormalOffsetInt);

            float3 normalMip2 = unpackNormal(mip2NormalX * 0.00390625, mip2NormalY * 0.00390625); // div by 256

            float d = dot(normalMip2, viewDirectionWS);
            if(d > 0.0){
                float normalOffsetMip2 = (((mip2NormalOffsetInt * 0.00390625) * 2.0) - 1.0) * cellSizeMip2;

                float3 cellPlanePosMip2 = cellCenterMip2 + (normalMip2 * normalOffsetMip2);

                // project ray onto plane at cell center
                float t = dot(cellPlanePosMip2 - voxelFragPos, normalMip2) / d;
                float3 projectedPointMip2 = voxelFragPos + (viewDirectionWS * t);
                float3 splatMip2 = projectedPointMip2 - cellPlanePosMip2;

                float splatCircle = length(splatMip2);
                if(splatCircle < splatSizeMip2){
                    int4 data2Mip3 = unpack66614(pointCloudDataMip3[chunkOffsetMip3 + mip2Pointer + 1].y);
                    hitColor = data2Mip3.xyz * 0.015625; // div 64

                    hitNormal = normalMip2;
                    hitDepthPoint = projectedPointMip2 - containerOffset + chunkCenter;

                    return true;
                }

                // filter out those rays that impact a splat frontally but miss
                traverseSteps *= 1.0 - (d * 0.8);
            }
        }
    }

    return false;
}

half3 LightingSubsurface(float3 lightDirection, float3 lightColor, half3 normalWS, half3 subsurfaceColor, half subsurfaceRadius){
    half NdotL = dot(normalWS, lightDirection);
    half alpha = subsurfaceRadius;
    half theta_m = acos(-alpha);

    half theta = max(0, NdotL + alpha) - alpha;
    half normalization_jgt = (2 + alpha) / (2 * (1 + alpha));
    half wrapped_jgt = (pow(abs((theta + alpha) / (1 + alpha)), abs(1 + alpha))) * normalization_jgt;

    half wrapped_valve = 0.25 * (NdotL + 1) * (NdotL + 1);
    half wrapped_simple = (NdotL + alpha) / (1 + alpha);

    half3 subsurface_radiance = lerp(lightColor * subsurfaceColor * wrapped_jgt, float3(0,0,0), NdotL);

    return subsurface_radiance;
}
