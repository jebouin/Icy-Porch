package entities;

import h2d.col.IBounds;
import h2d.Bitmap;
import Controller;

enum BoxState {
    MoveLeft;
    MoveRight;
    Frozen;
}

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
    var state : BoxState = MoveRight;

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
        var level = Game.inst.level;
        var onGround = level.rectCollision(x + hitbox.xMin, y + hitbox.yMin + 1, hitbox.width, hitbox.height);
        var controller = Main.inst.controller;
        if(controller.isPressed(Action.debugLeft)) {
            state = MoveLeft;
        }
        if(controller.isPressed(Action.debugRight)) {
            state = MoveRight;
        }
        if(controller.isPressed(Action.freeze)) {
            state = Frozen;
        }
        vx = state == Frozen ? 0 : (state == MoveLeft ? -MOVE_VEL : MOVE_VEL);
        var jumping = vy < 0 && controller.isDown(Action.jump);
        if(vy < 0 && controller.isReleased(Action.jump)) {
            vy *= .5;
        }
        var jumped = false;
        if(controller.isPressed(Action.jump)) {
            if(jump()) {
                jumped = true;
            } else {
                jumpBufferTimer = 0.;
            }
        } else if(onGround && controller.isDown(Action.jump) && jumpBufferTimer <= JUMP_BUFFER_TIME) {
            jumped = jump();
        }
        vy = Util.sodStep(vy, FALL_VEL, jumping ? GRAVITY_JUMP : GRAVITY, dt);
        onGround = false;
        tryMoveX(vx * dt, function(_) {
            if(state == MoveRight) {
                state = MoveLeft;
            } else {
                state = MoveRight;
            }
            vx *= -1;
        });
        tryMoveY(vy * dt, function(_) {
            if(vy > 0) {
                onGround = true;
            }
            vy = 0;
        });
        bitmap.scaleX = state == MoveLeft ? -1 : 1;
        bitmap.x = x + (state == MoveLeft ? bitmap.tile.iwidth : 0);
        bitmap.y = y;
    }

    public function jump() {
        if(groundTimer > JUMP_COYOTE_TIME) return false;
        groundTimer = JUMP_COYOTE_TIME + 1.;
        jumpBufferTimer = JUMP_BUFFER_TIME + 1.;
        vy = -JUMP_VEL;
        return true;
    }

    public function tryMoveX(dx:Float, ?onCollide:Int->Void) {
        rx += dx;
        var amount = Math.round(rx);
        if(amount != 0) {
            rx -= amount;
            var move = Game.inst.level.sweptRectCollisionHorizontal(x + hitbox.xMin, y + hitbox.yMin, hitbox.width, hitbox.height, amount);
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
            var move = Game.inst.level.sweptRectCollisionVertical(x + hitbox.xMin, y + hitbox.yMin, hitbox.width, hitbox.height, amount);
            y += move;
            if(move != amount && onCollide != null) {
                onCollide(amount - move);
            }
        }
    }
}