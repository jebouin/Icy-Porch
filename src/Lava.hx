package ;

import h2d.filter.Glow;
import h2d.Graphics;

class Lava {
    public var lakes : Array<LavaLake> = [];
    var g : Graphics;

    public function new() {
        g = new Graphics();
        Game.inst.world.add(g, Game.LAYER_LAVA);
        g.filter = new Glow(0xFFFFAA, 1., 10., .5, 2., true);
    }

    public function deleteLakes() {
        lakes = [];
    }

    public function update(dt:Float) {
        g.clear();
        for(lake in lakes) {
            lake.update(dt);
            lake.render(g);
        }
    }
}

class LavaLake {
    public static inline var COLOR_SURFACE = 0xfee761;
    public static inline var COLOR = 0xe43b44;
    var y : Int;
    var x1 : Int;
    var x2 : Int;
    var depth : Array<Float>;
    var pos : Array<Float>;
    var timer : Float = 0.;
    var noiseOffsetX : Int;
    var noiseOffsetY : Int;

    public function new(y:Int, x1:Int, x2:Int) {
        this.y = y;
        this.x1 = x1;
        this.x2 = x2;
        var len = x2 - x1 + 1;
        var level = Game.inst.level;
        depth = [for(x in 0...len) 0];
        pos = [for(x in 0...len) 0];
        for(i in 0...len) {
            for(add in 0...Main.HEIGHT) {
                if(!level.isPosInLava(x1 + i, y + add, true)) {
                    depth[i] = add;
                    break;
                }
            }
        }
        Game.inst.level.lava.lakes.push(this);
        noiseOffsetX = Std.random(Main.WIDTH);
        noiseOffsetY = Std.random(Main.HEIGHT);
    }

    public function update(dt:Float) {
        timer += dt;
        var len = x2 - x1 + 1;
        for(i in 0 ... len) {
            var wx = Std.int(60 * timer + i * 2 + noiseOffsetX) % Assets.noiseWidth;
            var wxr = (Math.floor(-10 * timer + i * 2 + noiseOffsetX) % Assets.noiseWidth + Assets.noiseWidth) % Assets.noiseWidth;
            var wy = Std.int(60 * timer + noiseOffsetY) % Assets.noiseHeight;
            pos[i] = 8 * (Assets.noiseX[wy][wx] + .5 * Assets.noiseY[wy][wxr]);
        }
    }

    public function render(g:Graphics) {
        var len = x2 - x1 + 1;
        g.lineStyle(0);
        g.beginFill(COLOR);
        g.moveTo(x1 + .5, y + pos[0] + .5);
        for(i in 1...len - 1) {
            g.lineTo(x1 + i + .5, y + pos[i] + .5);
        }
        g.lineTo(x2 + 1.5, y + pos[len - 1] + .5);
        g.lineTo(x2 + 1.5, y + depth[len - 1] + .5);
        for(i in 1...len - 1) {
            g.lineTo(x2 - i + .5, y + depth[len - i - 1] + .5);
        }
        g.lineTo(x1 + .5, y + depth[0] + .5);
        g.lineTo(x1 + .5, y + pos[0] + .5);
        g.endFill();
        g.lineStyle(1., COLOR_SURFACE);
        g.moveTo(x1 - .5, y + pos[0] + .5);
        for(i in 1...len - 1) {
            g.lineTo(x1 + i + .5, y + pos[i] + .5);
        }
        g.lineTo(x2 + 1.5, y + pos[len - 1] + .5);
    }
}