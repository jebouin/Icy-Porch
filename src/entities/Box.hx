package entities;

import h2d.filter.ColorMatrix;
import h2d.col.Point;
import h2d.col.IBounds;
import h2d.Bitmap;
import Controller;

class Box {
    public static inline var DIE_TIME = 2.;
    public static inline var MOVE_VEL = 60.;
    public static inline var FALL_VEL = 120.;
    public static inline var GRAVITY = .995;
    public static inline var GRAVITY_JUMP = .85;
    public static inline var JUMP_VEL = 200.;
    public static inline var JUMP_COYOTE_TIME = .1;
    public static inline var JUMP_BUFFER_TIME = .15;
    public static inline var FLASH_TIME = .05;
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
    var dieTimer : Float = 0.;
    var id : Int;
    var flashTimer : Float = FLASH_TIME + 1.;
    var flashFilter : ColorMatrix;
    var inTruck : Bool = true;
    public var magnet : Magnet = null;
    var magnetSOD : SecondOrderDynamics;
    public var arrived : Bool = false;
    var prevOnGround : Bool = false;

    public function new() {
        bitmap = new Bitmap(Assets.tiles.get("box"));
        Game.inst.world.add(bitmap, Game.LAYER_BOX);
        x = Game.inst.spawnX;
        y = Game.inst.spawnY;
        bitmap.x = x;
        bitmap.y = y;
        var m = new h3d.Matrix();
        m.colorSet(0xFFFFFF);
        flashFilter = new ColorMatrix(m);
    }

    public function delete() {
        if(deleted) return;
        deleted = true;
        bitmap.remove();
        onLeaveGround();
    }

    public function update(dt:Float) {
        if(dead) {
            dieTimer += dt;
            if(dieTimer > DIE_TIME) {
                delete();
            }
            return;
        }
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
        var diagSign = 0;
        if(inTruck) {
            vy = 0.;
            vx = MOVE_VEL;
            tryMoveNoCol(vx * dt, vy * dt);
            var bounds = getBounds();
            if(!Game.inst.truck.bounds.intersects(bounds)) {
                inTruck = false;
            }
        } else if(magnet != null) {
            var targetX = magnet.x + 8 - hitbox.width * .5 - (bitmap.scaleX == -1 ? 0 : 1) - hitbox.xMin;
            if(Util.fabs(magnetSOD.pos - targetX) < 1 && Util.fabs(magnetSOD.vel) < .01) {
                x = Math.round(targetX);
            } else {
                magnetSOD.update(dt, targetX);
                x = Math.round(magnetSOD.pos);
            }
            y = magnet.y - (hitbox.height + hitbox.yMin + 1);
            rx = ry = 0;
            vx = 0;
            vy = 0;
            if(!magnet.isOn) {
                magnet.isFree = true;
                magnet = null;
            }
        } else {
            vy = Util.sodStep(vy, FALL_VEL, jumping ? GRAVITY_JUMP : GRAVITY, dt);
            var dx = vx * dt;
            var dy = vy * dt;
            tryMoveX(dx, function(_) {
                onHitHorizontal();
            });
            tryMoveY(dy, function(_) {
                vy = 0;
            });
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
        }
        if(onGround && !prevOnGround && !inTruck) {
            onHitGround();
        } else if(!onGround && prevOnGround) {
            onLeaveGround();
        }
        prevOnGround = onGround;
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

    function checkEntityCollision(dx:Float, dy:Float) {
        var x1 = this.x + hitbox.xMin + dx;
        var y1 = this.y + hitbox.yMin + dy;
        var x2 = x1 + hitbox.width;
        var y2 = y1 + hitbox.height;
        var prevMagnet = this.magnet;
        var nextMagnet = null;
        for(e in Game.inst.entities) {
            if((dx != 0 || dy < 0) && Std.isOfType(e, Rock)) {
                var rock = cast(e, Rock);
                var bounds = rock.bounds;
                if(!(x2 < bounds.xMin || x1 > bounds.xMax || y2 <= bounds.yMin || y1 >= bounds.yMax)) {
                    rock.hit(dx, dy);
                }
            } else if(Std.isOfType(e, Magnet)) {
                var magnet = cast(e, Magnet);
                if(magnet.isOn && magnet.isFree && !(x2 < magnet.x || x1 > magnet.x + 16 || y2 < magnet.y || y1 > magnet.y + 16)) {
                    nextMagnet = magnet;
                }
            }
        }
        if(nextMagnet != null) {
            this.magnet = nextMagnet;
            this.magnet.isFree = false;
            if(this.magnet != prevMagnet) {
                magnetSOD = new SecondOrderDynamics(2.5, .7, 0., x, Precise);
            }
            // Use largest box ID so other boxes can collide with this one
            var boxes = Game.inst.boxes;
            boxes.remove(this);
            boxes.push(this);
        }
    }

    function checkDeath(level:Level) {
        if(level.isPosInLava(x + hitbox.xMin, y + hitbox.yMin + hitbox.height) || level.isPosInLava(x + hitbox.xMin + hitbox.width, y + hitbox.yMin + hitbox.height)) {
            dead = true;
            flashTimer = 0.;
            Audio.playSound("boxDeath");
            Game.inst.fx.boxDeath(x + bitmap.tile.width * .5, y + bitmap.tile.height * .5, bitmap.tile.width, bitmap.tile.height, 12, function() {
                bitmap.visible = false;
            });
        }
    }

    public function updateConstantRate(dt:Float) {
        flashTimer += dt;
        if(flashTimer <= FLASH_TIME || (flashTimer > FLASH_TIME * 2 && flashTimer <= FLASH_TIME * 3)) {
            bitmap.filter = flashFilter;
        } else {
            bitmap.filter = null;
        }
    }

    public function jump() {
        if(groundTimer > JUMP_COYOTE_TIME) return false;
        groundTimer = JUMP_COYOTE_TIME + 1.;
        jumpBufferTimer = JUMP_BUFFER_TIME + 1.;
        vy = -JUMP_VEL;
        Audio.playJump();
        return true;
    }

    public function tryMoveNoCol(dx:Float, dy:Float) {
        rx += dx;
        var amount = Math.round(rx);
        rx -= amount;
        x += amount;
        ry += dy;
        amount = Math.round(ry);
        ry -= amount;
        y += amount;
    }

    public function tryMoveX(dx:Float, ?onCollide:Int->Void) {
        rx += dx;
        var amount = Math.round(rx);
        if(amount != 0) {
            checkEntityCollision(amount, 0);
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
            checkEntityCollision(0, amount);
            ry -= amount;
            var res = Game.inst.level.sweptRectCollisionVertical(x + hitbox.xMin, y + hitbox.yMin, hitbox.width, hitbox.height, amount);
            x += res.moveX;
            y += res.moveY;
            if(res.moveY != amount && onCollide != null) {
                onCollide(amount - res.moveY);
            }
        }
    }

    inline function onHitGround() {
        Audio.playSlide(this);
    }

    inline function onLeaveGround() {
        Audio.stopSlide(this);
        //Audio.playSound("jump");
    }

    public inline function getBounds() {
        return IBounds.fromValues(x + hitbox.xMin, y + hitbox.yMin, hitbox.width, hitbox.height);
    }
}