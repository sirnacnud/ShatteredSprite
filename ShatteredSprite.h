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

#import "cocos2d.h"

// Class that excents CCSprite in order to provide a shatter effect where the
// sprite texture is broken up in to pieces that move with a speed and rotation.
@interface ShatteredSprite : CCSprite

// Call to shatter the sprite.
- (void)shatterWithPiecesX:(NSInteger)piecesX
               withPiecesY:(NSInteger)piecesY
                 withSpeed:(float)speed
              withRotation:(float)rotation;

// Resets the sprite from the shattered state back to default.
- (void)reset;

@end
