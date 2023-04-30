package fx;

import h2d.col.Point;
import h2d.SpriteBatch;

class Particle extends BatchElement {
    public static inline var BOUNCINESS = .5;
    public static var LIMIT = 1000;

    public var vx : Float = 0;
    public var vy : Float = 0;
    public var accx : Float = 0;
    public var accy : Float = 0;
    public var time : Float;
    public var timer : Float;
    public var frx : Float = 1.;
    public var fry : Float = 1.;
    public var tsx : Float = 1.;
    public var tsy : Float = 1.;
    public var rotVel : Float = 0.;
    public var fade : Bool = false;
    public var baseScaleX : Float = 1.;
    public var baseScaleY : Float = 1.;
    public var bounce : Bool = false;
    public var dieOnCollision : Bool = false;
    public var deleted : Bool = false;

    public function new(tile, time) {
        super(tile);
        this.time = timer = time;
    }

    public function delete() {
        deleted = true;
        visible = false;
    }

    inline function updateScale(sx:Float, sy:Float) {
        scaleX = sx;
        scaleY = sy;
    }

    inline function updateAlpha(v:Float) {
        alpha = v;
    }

    override public function tick(dt:Float) {
        timer -= dt;
        if(timer < 0) {
            delete();
            return;
        }
        var t = 1. - timer / time;
        updateScale(baseScaleX * (1. - t) + tsx * t, baseScaleY * (1. - t) + tsy * t);
        if(fade) {
            updateAlpha(1. - t);
        }
        var prevX = x, prevY = y;
        vx += accx * dt;
        vy += accy * dt;
        if(frx != 1.) {
            vx *= Math.pow(frx, dt);
        }
        if(fry != 1.) {
            vy *= Math.pow(fry, dt);
        }
        var dx = vx * dt;
        var dy = vy * dt;
        if(Game.inst != null) {
            var level = Game.inst.level;
            if(bounce) {
                if(level.pointCollision(new Point(x, y + dy))) {
                    vy *= -BOUNCINESS;
                    dy *= -BOUNCINESS;
                    vx *= BOUNCINESS;
                    rotVel *= -BOUNCINESS;
                }
                y += dy;
                if(level.pointCollision(new Point(x + dx, y))) {
                    vx *= -BOUNCINESS;
                    dx *= -BOUNCINESS;
                    vy *= BOUNCINESS;
                    rotVel *= -BOUNCINESS;
                }
                x += dx;
            } else {
                x += dx;
                y += dy;
            }
            var collides = level.pointCollision(new Point(x, y));
            if(dieOnCollision && collides) {
                delete();
                return;
            }
        } else {
            x += dx;
            y += dy;
        }
        rotation += rotVel * dt;
    }
}