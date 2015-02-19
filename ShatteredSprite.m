/*
 * ShatteredSprite
 *
 * Copyright (c) 2011 Michael Burford  (http://www.headlightinc.com)
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "ShatteredSprite.h"

// We need to define updateColor for Sprite
// so we can call it when we aren't shattered.
@interface CCSprite ()
- (void)updateColor;
@end

// Datastructure for triangle specific data
typedef struct _TriangleData {
    // Angular rotation
    float adelta;
    
    // Velocity
    CGPoint vdelta;
    
    // Center of triangle
    CGPoint center;
} TriangleData;

@implementation ShatteredSprite {
    // All vertices
    CCVertex* _vertices;
    
    // All triangles
    TriangleData* _triangles;
    
    // Number of triangles
    NSUInteger _numOfTriangles;
    
    // Number of vertices
    NSUInteger _numOfVertices;
    
    // Center of sprite
    GLKVector2 _center;
    
    // Extents of sprite
    GLKVector2 _extents;
}

- (instancetype)init {
    self = [super init];
    
    if (self) {
        _center = GLKVector2Make(0.0f, 0.0f);
        _extents = GLKVector2Make(0.0f, 0.0f);
    }
    
    return self;
}

- (void)dealloc {
    if (_vertices != NULL) {
        free(_vertices);
    }
    if (_triangles != NULL) {
        free(_triangles);
    }
}

#pragma mark ShatteredSprite - CCNode overrides

- (void)update:(CCTime)delta {
    delta *= 60.0;
    
    float xMin = FLT_MAX;
    float xMax = FLT_MIN;
    float yMin = FLT_MAX;
    float yMax = FLT_MIN;
    
    for (int i = 0; i < _numOfTriangles; ++i) {
        float ad = _triangles[i].adelta * delta;
        CGPoint vd = ccp(_triangles[i].vdelta.x * delta, _triangles[i].vdelta.y * delta);
        
        _triangles[i].center = ccpAdd(_triangles[i].center, vd);
        
        // TODO: replace the CGPoint operations by creating
        // matrix and applying it to each position vector.
        CGPoint position;
        int vertexIndex = i * 3;
        
        for (int j = vertexIndex; j < vertexIndex + 3; ++j) {
            position = CGPointMake(_vertices[j].position.x, _vertices[j].position.y);
            position = ccpAdd(position, vd);
            position = ccpRotateByAngle(position, _triangles[i].center, ad);
            
            if( position.x < xMin ) {
                xMin = position.x;
            }
            else if( position.x > xMax ) {
                xMax = position.x;
            }
            
            if( position.y < yMin ) {
                yMin = position.y;
            }
            else if( position.y > yMax ) {
                yMax = position.y;
            }
            
            _vertices[j].position.x = position.x;
            _vertices[j].position.y = position.y;
        }
    }
    
    // Set the center/extents for culling purposes.
    _center = GLKVector2Make((xMin + xMax) * 0.5f, (yMin + yMax) * 0.5f);
    _extents = GLKVector2Make((xMax - xMin) * 0.5f, (yMax - yMin) * 0.5f);
}

#pragma mark ShatteredSprite - CCSprite overrides

-(void)draw:(CCRenderer*)renderer transform:(const GLKMatrix4*)transform {
    if (_numOfTriangles > 0) {
        if (self.effect) {
            NSLog(@"Shader effects aren't supported with shattered effect");
        }

        if (CCRenderCheckVisbility(transform, _center, _extents)) {
            CCRenderBuffer buffer = [renderer enqueueTriangles:_numOfTriangles
                                                   andVertexes:_numOfVertices
                                                     withState:self.renderState
                                               globalSortOrder:0];

            for (int i = 0; i < _numOfVertices; ++i) {
                CCRenderBufferSetVertex(buffer, i, CCVertexApplyTransform(_vertices[i], transform));
            }
            
            for (int i = 0; i < _numOfTriangles; ++i) {
                int vertexCount = i * 3;
                CCRenderBufferSetTriangle(buffer, i, vertexCount, vertexCount + 1, vertexCount + 2);
            }
        }
    } else {
        [super draw:renderer transform:transform];
    }
}

- (void)updateColor {
    if (_numOfVertices > 0) {
        GLKVector4 color = GLKVector4Make(_displayColor.r, _displayColor.g, _displayColor.b, _displayColor.a);
        
        // Premultiply alpha.
        color.r *= _displayColor.a;
        color.g *= _displayColor.a;
        color.b *= _displayColor.a;
        
        for (int i = 0; i < _numOfVertices; ++i) {
            _vertices[i].color = color;
        }
    } else {
        [super updateColor];
    }
}

// A helper to do float random numbers in a range around a base value.
float randf(float base, float range) {
    if (range==0) {
        return base;
    }
    long lRange = rand() % (int)((range * 2) * 10000);
    float fRange = ((float)lRange / 10000.0) - range;
    return base + fRange;
}

- (GLKVector2)calculateTextureCoordinatesFromPoint:(CGPoint)point
                                   withTextureRect:(CGRect)rect
                                  withTextureWidth:(CGFloat)width
                                 withTextureHeight:(CGFloat)height {
    CGPoint texCoord = rect.origin;
    
    if (self.textureRectRotated) {
        texCoord.x += point.y;
        texCoord.y += point.x;
    } else {
        texCoord.x += point.x;
        texCoord.y += rect.size.height - point.y;
    }
    return GLKVector2Make(texCoord.x / width, 1.0f - (texCoord.y / height));
}

- (void)shatterWithPiecesX:(NSInteger)piecesX
               withPiecesY:(NSInteger)piecesY
                 withSpeed:(float)speed
              withRotation:(float)rotation {

    if (piecesX <= 0 || piecesY <= 0) {
        return;
    }
    
    float pieceXsize = self.contentSize.width / piecesX;
    float pieceYsize = self.contentSize.height / piecesY;
    
    float xMin = FLT_MAX;
    float xMax = FLT_MIN;
    float yMin = FLT_MAX;
    float yMax = FLT_MIN;
    
    // Build the points first, so they can be wobbled a bit to look more random...
    CGPoint ptArray[piecesX + 1][piecesY + 1];
    for (int x = 0; x <= piecesX; ++x) {
        for (int y = 0; y <= piecesY; ++y) {
            CGPoint pt = CGPointMake(x * pieceXsize, y * pieceYsize);
            
            // Edge pieces aren't wobbled, just interior.
            if (x > 0 && x < piecesX && y > 0 && y < piecesY) {
                pt = ccpAdd(pt, ccp(roundf(randf(0.0, pieceXsize * 0.45)), roundf(randf(0.0, pieceYsize * 0.45))));
            }
            ptArray[x][y] = pt;
            
            if (pt.x < xMin) {
                xMin = pt.x;
            } else if( pt.x > xMax ) {
                xMax = pt.x;
            }
            
            if (pt.y < yMin) {
                yMin = pt.y;
            } else if( pt.y > yMax ) {
                yMax = pt.y;
            }
        }
    }
    
    // Set the center/extents for culling purposes
    _center = GLKVector2Make((xMin + xMax) * 0.5f, (yMin + yMax) * 0.5f);
    _extents = GLKVector2Make((xMax - xMin) * 0.5f, (yMax - yMin) * 0.5f);
    
    _numOfTriangles = piecesX * (piecesY * 2);
    _numOfVertices = _numOfTriangles * 3;
    
    _vertices = realloc(_vertices, _numOfVertices * sizeof(CCVertex));
    _triangles = realloc(_triangles, _numOfTriangles * sizeof(TriangleData));
    
    GLKVector4 color = GLKVector4Make(_displayColor.r, _displayColor.g, _displayColor.b, _displayColor.a);
    
    // Premultiply alpha.
    color.r *= _displayColor.a;
    color.g *= _displayColor.a;
    color.b *= _displayColor.a;
    
    int vertexIndex = 0;
    int triangleIndex = 0;
    
    CGRect textRect = self.textureRect;
    CGFloat textureWidth = self.texture.pixelWidth / self.texture.contentScale;
    CGFloat textureHeight = self.texture.pixelHeight / self.texture.contentScale;
    
    for (int x = 0; x < piecesX; ++x) {
        for (int y = 0; y < piecesY; ++y) {
            // Direction (v) and rotation (a) are done by triangle too.
            // CenterPoint is for rotating each triangle
            // vdelta is random, but could be done based on distance/direction from the center of the image to explode out...
            
            // Triangle 1.
            _triangles[triangleIndex].vdelta = ccp(randf(0.0, speed), randf(0.0, speed));
            _triangles[triangleIndex].adelta = randf(0.0, rotation);
            _triangles[triangleIndex].center = ccp((x * pieceXsize) + (pieceXsize * 0.3), (y * pieceYsize) + (pieceYsize * 0.3));
            
            // Vertex 1 of triangle 1.
            _vertices[vertexIndex].color = color;
            _vertices[vertexIndex].position = GLKVector4Make(ptArray[x][y].x, ptArray[x][y].y, 0.0f, 1.0f);
            _vertices[vertexIndex].texCoord1 = [self calculateTextureCoordinatesFromPoint:ptArray[x][y]
                                                                        withTextureRect:textRect
                                                                        withTextureWidth:textureWidth
                                                                        withTextureHeight:textureHeight];
            
            ++vertexIndex;
            
            // Vertex 2 of triangle 1.
            _vertices[vertexIndex].color = color;
            _vertices[vertexIndex].position = GLKVector4Make(ptArray[x + 1][y].x, ptArray[x + 1][y].y, 0.0f, 1.0f);
            _vertices[vertexIndex].texCoord1 = [self calculateTextureCoordinatesFromPoint:ptArray[x + 1][y]
                                                                        withTextureRect:textRect
                                                                         withTextureWidth:textureWidth
                                                                        withTextureHeight:textureHeight];
            
            ++vertexIndex;
            
            // Vertex 3 of triangle 1.
            _vertices[vertexIndex].color = color;
            _vertices[vertexIndex].position = GLKVector4Make(ptArray[x][y + 1].x, ptArray[x][y + 1].y, 0.0f, 1.0f);
            _vertices[vertexIndex].texCoord1 = [self calculateTextureCoordinatesFromPoint:ptArray[x][y + 1]
                                                                        withTextureRect:textRect
                                                                         withTextureWidth:textureWidth
                                                                        withTextureHeight:textureHeight];
            
            ++triangleIndex;
            
            // Triangle 2.
            _triangles[triangleIndex].vdelta = ccp(randf(0.0, speed), randf(0.0, speed));
            _triangles[triangleIndex].adelta = randf(0.0, rotation);
            _triangles[triangleIndex].center = ccp((x * pieceXsize) + (pieceXsize * 0.7), (y * pieceYsize) + (pieceYsize * 0.7));
            
            ++vertexIndex;
            
            // Vertex 1 of triangle 2, same as Vertex 2 of triangle 1.
            _vertices[vertexIndex] = _vertices[vertexIndex - 2];
            
            ++vertexIndex;
            
            // Vertex 2 of triangle 2.
            _vertices[vertexIndex].color = color;
            _vertices[vertexIndex].position = GLKVector4Make(ptArray[x + 1][y + 1].x, ptArray[x + 1][y + 1].y, 0.0f, 1.0f);
            _vertices[vertexIndex].texCoord1 = [self calculateTextureCoordinatesFromPoint:ptArray[x + 1][y + 1]
                                                                        withTextureRect:textRect
                                                                         withTextureWidth:textureWidth
                                                                        withTextureHeight:textureHeight];
            
            ++vertexIndex;
            
            // Vertex 3 of triangle 2, same as Vertex 3 of triangle 1.
            _vertices[vertexIndex] = _vertices[vertexIndex - 3];
            
            ++vertexIndex;
            ++triangleIndex;
        }
    }
}

- (void)reset {
    _numOfTriangles = 0;
    _numOfVertices = 0;
    _center = GLKVector2Make(0.0f, 0.0f);
    _extents = GLKVector2Make(0.0f, 0.0f);
    
    if (_vertices != NULL) {
        free(_vertices);
        _vertices = NULL;
    }
    if (_triangles != NULL) {
        free(_triangles);
        _triangles = NULL;
    }
}

@end
