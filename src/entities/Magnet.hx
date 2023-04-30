package entities;

import h2d.Bitmap;
import fx.Particle;
import h2d.Tile;

class Magnet extends Entity {
    public static inline var PART_COUNT = 4;
    public static inline var PART_HEIGHT = 16;
    public static inline var PART_TIMER = .25;
    public var isOn : Bool = false;
    var timer : Float = 0;
    var particles : Array<Bitmap> = [];

    public function new(x:Int, y:Int) {
        super(Assets.animData.get(isOn ? "magnetOn" : "magnetOff"), Game.LAYER_MAGNETS, x, y);
        var partTile = Assets.tiles.get("particleMagnet");
        for(i in 0...4) {
            var p = new Bitmap(partTile);
            Game.inst.world.add(p, Game.LAYER_BACK_WALLS);
            p.visible = false;
            particles.push(p);
        }
        toggle();
    }

    override public function delete() {
        super.delete();
    }

    override public function update(dt:Float) {
        super.update(dt);
        if(isOn) {
            timer += dt;
        }
        var fromY = y + 1 - PART_HEIGHT;
        var toY = fromY + PART_HEIGHT;
        for(i in 0...particles.length) {
            var p = particles[i];
            p.y = (timer * 30 + i * PART_HEIGHT / PART_COUNT) % PART_HEIGHT + fromY;
            p.x = x + 8;
            var t = (p.y - fromY) / PART_HEIGHT;
            p.alpha = t < .2 ? t / .2 : t > .9 ? (1 - t) / .1 : 1;
        }
    }

    public function toggle() {
        isOn = !isOn;
        anim.playFromName(isOn ? "magnetOn" : "magnetOff");
        for(p in particles) {
            p.visible = isOn;
        }
    }
}