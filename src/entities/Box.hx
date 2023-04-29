package entities;

import h2d.col.IBounds;
import h2d.Bitmap;

class Box {
    public static inline var MOVE_VEL = 70.;
    public static inline var FALL_VEL = 100.;
    public static inline var GRAVITY = .996;
    public static inline var GRAVITY_JUMP = .93;
    public static inline var JUMP_VEL = 250.;
    public static inline var JUMP_COYOTE_TIME = .1;
    public static inline var JUMP_BUFFER_TIME = .15;
    var bitmap : Bitmap;
    public var hitbox : IBounds = IBounds.fromValues(1, 1, 13, 10);
    public var x : Int = 150;
    public var y : Int = 100;
    public var rx : Float = 0.;
    public var ry : Float = 0.;
    public var vx : Float = 0.;
    public var vy : Float = 0.;
    var groundTimer : Float = 0.;
    var jumpBufferTimer : Float = JUMP_BUFFER_TIME;
    public var deleted : Bool = false;

    public function new() {
        bitmap = new Bitmap(Assets.tiles.get("box"));
        Game.inst.world.add(bitmap, Game.LAYER_BOX);
    }

    public function delete() {
        if(deleted) return;
        deleted = true;
        bitmap.remove();
    }

    public function update(dt:Float) {
        vx = MOVE_VEL;
        vy = .3 * MOVE_VEL;
        tryMoveX(vx * dt);
        tryMoveY(vy * dt);
        bitmap.x = x;
        bitmap.y = y;
    }

    public function tryMoveX(dx:Float, ?onCollide:Int->Void) {
        rx += dx;
        var amount = Math.round(rx);
        if(amount != 0) {
            rx -= amount;
            var move = amount;
            x += move;
            if(move != amount && onCollide != null) {
                onCollide(amount - move);
            }
        }
    }

    public function tryMoveY(dy:Float, ?onCollide:Int->Void) {
        ry += dy;
        var amount = Math.round(ry);
        if(amount != 0) {
            ry -= amount;
            var move = amount;
            y += move;
            if(move != amount && onCollide != null) {
                onCollide(amount - move);
            }
        }
    }
}