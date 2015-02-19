# ShatteredSprite
Sprite class for Cocos2d that supports a shattered effect.

Cocos2d-swift v3 dropped support for the shatter effect action, so this class was created to support for a shattered
effect on a sprite.  The code originally started from this [example](http://headlightinc.com/shatter-sample-src.zip)
for Cocos2d v2, but has been heavily modified.

## Usuage
ShatteredSprite is a subclass of Sprite, so you can use it just like a regular sprite.

The below code shows allocation of a ShatteredSprite, then shattering the sprite in to 35 pieces.
```
ShatteredSprite* shatteredSprite = [ShatteredSprite spriteWithFile:@"smile.png"];
[shatteredSprite shatterWithPiecesX:5 withPiecesY:7 withSpeed:0.5 withRotation:0.02];
```

To end the shattered effect, you can call the reset method and the sprite will reset to normal.
```
[shatteredSprite reset];
```

## Limitations
Currently there isn't support to use effect shaders while the shattered effect is running.

## Dependencies
You need to be using Cocos2d-swift v3.

## Author

Copyright (C) 2015 [Duncan Cunningham](https://github.com/sirnacnud)

## License

Distributed under the MIT License.
