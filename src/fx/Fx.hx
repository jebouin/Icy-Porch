package fx;

import h3d.Matrix;
import h3d.Vector;
import h2d.Graphics;
import h3d.col.Point;
import h2d.Tile;
import h2d.Bitmap;
import h2d.Layers;
import h2d.SpriteBatch;

enum ScreenShakeType {
    Bounce;
    Noise;
}

class CardboardParticle {
    public static inline var GRAVITY = 200.;
    public static inline var FR_MIN = .0;
    public static inline var FR_MAX = 1.;
    public static inline var ACC = 100;
    var points : Array<Vector> = [];
    var timer : Float = 0.;
    public var rotVelX : Float = 0.;
    public var rotVelY : Float = 0.;
    public var rotVelZ : Float = 0.;
    public var rotX : Float = 0.;
    public var rotY : Float = 0.;
    public var rotZ : Float = 0.;
    public var x : Float = 0.;
    public var y : Float = 0.;
    public var vx : Float = 0.;
    public var vy : Float = 0.;
    public var vz : Float = 0.;
    var mat : Matrix;

    public function new(w:Float, h:Float) {
        points.push(new Vector(-w * .5, -h * .5, 0));
        points.push(new Vector(w * .5, -h * .5, 0));
        points.push(new Vector(w * .5, h * .5, 0));
        points.push(new Vector(-w * .5, h * .5, 0));
        mat = new Matrix();
    }

    public function update(dt:Float) {
        var frr = Math.pow(.1, dt);
        if(Util.fmax(Util.fabs(rotVelX), Util.fmax(Util.fabs(rotVelY), Util.fabs(rotVelZ))) > .1) {
            rotVelX *= frr;
            rotVelY *= frr;
            rotVelZ *= frr;
        }
        rotX += rotVelX * dt;
        rotY += rotVelY * dt;
        rotZ += rotVelZ * dt;
        mat.identity();
        mat.initRotation(rotX, rotY, rotZ);
        vy += GRAVITY * dt;
        var normal = new Vector(0, 0, 1).transformed(mat);
        var side = new Vector(1, 0, 0).transformed(mat);
        var vel = new Vector(vx, vy, vz);
        var velLength = vel.length();
        var drag = Util.fabs(normal.dot(vel)) / velLength;
        var acc = side.dot(vel) / velLength;
        vx += acc * dt * ACC * side.x;
        vy += acc * dt * ACC * side.y;
        vz += acc * dt * ACC * side.z;
        var fr = Math.pow(Util.lerp(FR_MIN, FR_MAX, 1. - drag) * .5, dt);
        vx *= fr;
        vy *= fr;
        vz *= fr;
        x += vx * dt;
        y += vy * dt;
    }

    public function render(g:Graphics) {
        var rotatedPoints = [];
        for(i in 0...4) {
            var p = points[i].transformed(mat);
            rotatedPoints.push(new h2d.col.Point(p.x + x, p.y + y));
        }
        var turn = Collision.det(rotatedPoints[1].x - rotatedPoints[0].x, rotatedPoints[1].y - rotatedPoints[0].y, rotatedPoints[2].x - rotatedPoints[1].x, rotatedPoints[2].y - rotatedPoints[1].y);
        if(turn < 0) {
            g.beginFill(0x743f39);
            g.lineStyle(1., 0x743f39);
        } else {
            g.beginFill(0xe4a672);
            g.lineStyle(1., 0xb86f50);
        }
        var p = rotatedPoints[3];
        g.moveTo(p.x, p.y);
        for(i in 0...points.length) {
            var p = rotatedPoints[i];
            g.lineTo(p.x, p.y);
        }
        g.endFill();
    }
}

class Fx {
    var sbFront : SpriteBatch;
    var sbBack : SpriteBatch;
    public var shakeX : Float = 0.;
    public var shakeY : Float = 0.;
    var shakeDX : Float = 0.;
    var shakeDY : Float = 0.;
    var shakeSOD : SecondOrderDynamics;
    var shakeTimer : Float = 0.;
    var shakeType : ScreenShakeType = Bounce;
    var flashTimer : Float = 0.;
    var flashSOD : SecondOrderDynamics;
    var flashBitmap : Bitmap;
    var flashLayers : Layers = null;
    var explosions : Array<Anim> = [];
    var cardboardParticles : Array<CardboardParticle> = [];
    var cardboardGraphics : Graphics;

    public function new(frontLayer:Int, backLayer:Int) {
        sbFront = new SpriteBatch(hxd.Res.gfx.entities.toTile());
        sbBack = new SpriteBatch(hxd.Res.gfx.entities.toTile());
        Game.inst.world.add(sbFront, frontLayer);
        Game.inst.world.add(sbBack, backLayer);
        cardboardGraphics = new Graphics();
        Game.inst.world.add(cardboardGraphics, frontLayer);
    }

    public function delete() {
        clear();
    }

    public function clear() {
        sbFront.clear();
        sbBack.clear();
        for(e in explosions) {
            e.remove();
        }
        explosions = [];
        cardboardParticles = [];
        cardboardGraphics.clear();
    }

    public function update(dt:Float) {
        for(p in sbFront.getElements()) {
            p.tick(dt);
        }
        for(p in sbBack.getElements()) {
            p.tick(dt);
        }
        for(e in explosions) {
            e.update(dt);
        }
        cardboardGraphics.clear();
        for(p in cardboardParticles) {
            p.update(dt);
            p.render(cardboardGraphics);
        }
    }

    public function updateConstantRate(dt:Float) {
        if(shakeTimer > 0) {
            shakeTimer -= dt;
            if(shakeTimer < 0) {
                shakeX = shakeY = 0;
            } else {
                shakeSOD.update(dt, 0);
                if(shakeType == Noise) {
                    var ra = Math.random() * Util.TAU;
                    var dist = shakeSOD.pos;
                    shakeX = Math.cos(ra) * dist * shakeDX;
                    shakeY = Math.sin(ra) * dist * shakeDY;
                } else {
                    shakeX = shakeDX * shakeSOD.pos;
                    shakeY = shakeDY * shakeSOD.pos;
                }
            }
        }
        if(flashTimer > 0) {
            flashBitmap.x = -flashLayers.x;
            flashBitmap.y = -flashLayers.y;
            flashTimer -= dt;
            if(flashTimer < 0) {
                flashBitmap.remove();
                flashBitmap = null;
            } else {
                flashSOD.update(dt, 0);
                flashBitmap.alpha = flashSOD.pos;
            }
        }
    }

    public function screenBounce(dx:Float, dy:Float, f:Float, z:Float, r:Float) {
        shakeSOD = new SecondOrderDynamics(f, z, r, 1., Fast);
        shakeTimer = 4. / f;
        shakeDX = dx;
        shakeDY = dy;
        shakeType = ScreenShakeType.Bounce;
    }
    public function screenShake(dx:Float, dy:Float, f:Float, z:Float, r:Float, ?maxTime:Float=null) {
        shakeSOD = new SecondOrderDynamics(f, z, r, 1., Fast);
        shakeTimer = maxTime == null ? 4. / f : maxTime;
        shakeDX = dx;
        shakeDY = dy;
        shakeType = ScreenShakeType.Noise;
    }
    public function stopShake() {
        if(shakeSOD != null) {
            shakeSOD.reset(0);
        }
        shakeDX = shakeDY = shakeX = shakeY = shakeTimer = 0.;
    }
    public function screenFlash(layers:Layers, color:Int, alpha:Float, f:Float) {
        if(flashBitmap != null) {
            flashBitmap.remove();
        }
        flashBitmap = new Bitmap(Tile.fromColor(0xFF000000 | color, Main.WIDTH, Main.HEIGHT), layers);
        flashBitmap.blendMode = Add;
        flashSOD = new SecondOrderDynamics(f, 1, 0, alpha, Fast);
        flashTimer = 4. / f;
        flashLayers = layers;
    }

    public function rumble(strength:Float, seconds:Float) {
        Main.inst.controller.rumble(strength, seconds);
    }

    public function boxDeath(x:Float, y:Float, w:Float, h:Float, d:Float, onHitStopDone:Void->Void) {
        screenShake(5, 5, 2., 1., 0);
        screenFlash(Game.inst.hud, 0xFF0000, .4, 2.);
        rumble(.5, .2);
        Main.inst.hitStop(.3);
        Main.inst.onHitStopDone = function() {
            var anim = Assets.explosionAnim;
            var explosion = new Anim(anim.tiles, anim.fps, false);
            explosion.x = x;
            explosion.y = y;
            explosions.push(explosion);
            Game.inst.world.add(explosion, Game.LAYER_FX_FRONT);
            var remArea = 2 * (2 * w * h + 2 * w * d + 2 * h * d);
            var minArea = 16, maxArea = 60;
            var minLength = 3, maxLength = 10;
            var count = 0;
            while(count < 100 && remArea > 0) {
                var area = Util.randf(minArea, maxArea);
                var length = Util.randf(minLength, Util.fmin(maxLength, area / minLength));
                var p = new CardboardParticle(length, area / length);
                var pos = Util.randCircle(0, 12 - length * .5);
                p.x = x + pos.x;
                p.y = y + pos.y;
                var vel = Util.randCircle(0, 150);
                p.vx = vel.x;
                p.vy = -250 + vel.y;
                p.vx *= 1.;
                p.vy *= 1.;
                var rotType = Std.random(3);
                if(rotType == 0) {
                    p.rotX = Math.PI * .5;
                } else if(rotType == 1) {
                    p.rotY = Math.PI * .5;
                }
                inline function randRotVel() {
                    return Util.randSign() * Util.randf(.7, 1.) * 25.;
                }
                p.rotVelX = randRotVel();
                p.rotVelY = randRotVel();
                p.rotVelZ = randRotVel();
                cardboardParticles.push(p);
                remArea -= area;
                count++;
            }
            onHitStopDone();
        };
    }
}