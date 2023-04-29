package fx;

import hxsl.Types.Sampler2D;
import h2d.filter.Shader;

class TransitionIn extends Shader<InternalShader> {
    var timer : Float = 0.;

    public function new() {
        var s = new InternalShader();
        super(s);
    }

    public function update(dt:Float) {
        timer += dt;
    }

    override function draw(ctx:h2d.RenderContext, t:h2d.Tile) : h2d.Tile {
        shader.time = timer;
        shader.transitionTime = Game.TRANSITION_TIME_IN;
        return super.draw(ctx, t);
    }
}

private class InternalShader extends h3d.shader.ScreenShader {
    static var SRC = {
        @param var texture : Sampler2D;
        @param var time : Float = 0.;
        @param var transitionTime = .8;
        @param var TILE_WIDTH = .4;
        @param var TILE_HEIGHT = .4;

        function fragment() {
            var t = mod(time, transitionTime) / transitionTime;
            var uv = (calculatedUV * 2. - 1.) * vec2(1.777777, -1);
            var tileDim = vec2(TILE_WIDTH, TILE_HEIGHT);
            var center = uv - mod(uv - tileDim * .5, tileDim) + tileDim * .5;
            var tileCoords = center / tileDim;
            var fromTime = pow(dot(tileCoords, tileCoords), .5) * .1;
            var pos = vec2(uv.x - center.x, uv.y - center.y);
            var tt = min(1., (1. - pow(1. - max(0., t - fromTime), 4.)) * 1.1);
            var angle = -tileCoords.x * .4 * (1. - tt);
            var scale = pow(tt, abs(tileCoords.y) * .2 + 1.);
            var posTr = 1. / scale * vec2(pos.x * cos(angle) - pos.y * sin(angle), pos.x * sin(angle) + pos.y * cos(angle));
            if(abs(posTr.x) > TILE_WIDTH * .5 || abs(posTr.y) > TILE_HEIGHT * .5) {
                pixelColor = vec4(0.);
            } else {
                var texUV = (center + posTr) / vec2(1.777777, -1);
                texUV = (texUV + 1) * .5;
                pixelColor = texture.get(texUV);
            }
        }
    }
}