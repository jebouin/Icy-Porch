package entities;

import h2d.col.Point;
import h2d.col.IBounds;
import h2d.Bitmap;
import Controller;

class Box {
    public static inline var MOVE_VEL = 80.;
    public static inline var FALL_VEL = 120.;
    public static inline var GRAVITY = .998;
    public static inline var GRAVITY_JUMP = .94;
    public static inline var JUMP_VEL = 275.;
    public static inline var JUMP_COYOTE_TIME = .1;
    public static inline var JUMP_BUFFER_TIME = .15;
    var bitmap : Bitmap;
    public var hitbox : IBounds = IBounds.fromValues(1, 1, 13, 9);
    public var x : Int = 0;
    public var y : Int = 0;
    public var rx : Float = 0.;
    public var ry : Float = 0.;
    public var vx : Float = 0.;
    public var vy : Float = 0.;
    var groundTimer : Float = 0.;
    var jumpBufferTimer : Float = JUMP_BUFFER_TIME;
    public var deleted : Bool = false;
    var moveSign : Int = 1;
    var frozen : Bool = false;
    public var dead : Bool = false;
    var id : Int;

    public function new() {
        bitmap = new Bitmap(Assets.tiles.get("box"));
        Game.inst.world.add(bitmap, Game.LAYER_BOX);
        x = Game.inst.spawnX + 36;
        y = Game.inst.spawnY - 10;
        bitmap.x = x;
        bitmap.y = y;
    }

    public function delete() {
        if(deleted) return;
        deleted = true;
        bitmap.remove();
    }

    public function update(dt:Float) {
        var level = Game.inst.level;
        var onGround = level.rectCollision(x + hitbox.xMin, y + hitbox.yMin + 1, hitbox.width, hitbox.height);
        id = Game.inst.boxes.indexOf(this);
        if(onGround) {
            groundTimer = 0.;
        } else {
            groundTimer += dt;
        }
        var controller = Main.inst.controller;
        if(controller.isPressed(Action.debugLeft)) {
            moveSign = -1;
        }
        if(controller.isPressed(Action.debugRight)) {
            moveSign = 1;
        }
        if(controller.isPressed(Action.freeze)) {
            frozen = !frozen;
        }
        vx = frozen ? 0 : moveSign * MOVE_VEL;
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
        tryMoveX(vx * dt, function(_) {
            onHitHorizontal();
        });
        tryMoveY(vy * dt, function(_) {
            vy = 0;
        });
        var diagSign = 0;
        if(onGround && !jumped) {
            stickToGround(level);
            var slopeLeft = level.getSlope(x + hitbox.xMin, y + hitbox.yMin + hitbox.height + 1);
            var slopeRight = level.getSlope(x + hitbox.xMin + hitbox.width, y + hitbox.yMin + hitbox.height + 1);
            if(slopeLeft.x == slopeLeft.y) {
                diagSign = -1;
            } else if(slopeRight.x == -slopeRight.y) {
                diagSign = 1;
            }
        }
        checkDeath(level);
        bitmap.scaleX = moveSign < 0 ? -1 : 1;
        bitmap.tile = Assets.tiles.get(diagSign == 0 ? "box" : ((diagSign == 1) == (bitmap.scaleX == 1) ? "boxDiagUp" : "boxDiagDown"));
        bitmap.x = x + (moveSign < 0 ? bitmap.tile.iwidth : 0);
        bitmap.y = y;
    }


    inline function onHitHorizontal() {
        vx *= -1;
        moveSign *= -1;
    }

    function stickToGround(level) {
        var x1 = x + hitbox.xMin;
        var x2 = x1 + hitbox.width;
        var y2 = y + hitbox.yMin + hitbox.height;
        for(i in 1...8) {
            if(level.pointCollision(new Point(x1, y2 + i)) || level.pointCollision(new Point(x2, y2 + i))) {
                y += i - 1;
                break;
            }
        }
    }

    function checkDeath(level:Level) {
        if(level.isPosInLava(x + hitbox.xMin, y + hitbox.yMin + hitbox.height) || level.isPosInLava(x + hitbox.xMin + hitbox.width, y + hitbox.yMin + hitbox.height)) {
            dead = true;
        }
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
            var res = Game.inst.level.sweptRectCollisionHorizontal(x + hitbox.xMin, y + hitbox.yMin, hitbox.width, hitbox.height, amount, id);
            if(res.collidedBox != null) {
                Game.inst.onBoxCollision(id, Game.inst.boxes.indexOf(res.collidedBox));
                res.collidedBox.onHitHorizontal();
            }
            x += res.moveX;
            y += res.moveY;
            if(res.moveX != amount && onCollide != null) {
                onCollide(amount - res.moveX);
            }
        }
    }

    public function tryMoveY(dy:Float, ?onCollide:Int->Void) {
        ry += dy;
        var amount = Math.round(ry);
        if(amount != 0) {
            ry -= amount;
            var res = Game.inst.level.sweptRectCollisionVertical(x + hitbox.xMin, y + hitbox.yMin, hitbox.width, hitbox.height, amount);
            x += res.moveX;
            y += res.moveY;
            if(res.moveY != amount && onCollide != null) {
                onCollide(amount - res.moveY);
            }
        }
    }
}