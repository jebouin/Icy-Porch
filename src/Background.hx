package ;

import h2d.Tile;
import hxd.Res;
import h2d.Bitmap;
import h2d.SpriteBatch;

class Flake extends BatchElement {
    public static inline var ACC = .015;
    public static inline var DAMP = .3;
    public static inline var GRAVITY = .02;
    public var vx : Float;
    public var vy : Float;
    public var xx : Float;
    public var yy : Float;
    public var background : Background;
    var isFront : Bool;

    public function new(t:Tile, background:Background, isFront:Bool) {
        this.background = background;
        this.isFront = isFront;
        super(t);
        spawn(false);
    }

    function spawn(border:Bool) {
        if(border) {
            var pos = Math.random() * 2 * (Main.WIDTH + Main.HEIGHT);
            if(pos < Main.WIDTH) {
                xx = pos;
                yy = 0;
            } else if(pos < Main.WIDTH + Main.HEIGHT) {
                xx = Main.WIDTH - 1;
                yy = pos - Main.WIDTH;
            } else if(pos < 2 * Main.WIDTH + Main.HEIGHT) {
                xx = 2 * Main.WIDTH + Main.HEIGHT - pos;
                yy = Main.HEIGHT - 1;
            } else {
                xx = 0;
                yy = 2 * Main.WIDTH + 2 * Main.HEIGHT - pos;
            }
        } else {
            xx = Math.random() * Main.WIDTH;
            yy = Math.random() * Main.HEIGHT;
        }
        vx = 0.;
        vy = 0.;
        for(i in 0...60) {
            applyAcceleration(1. / 60.);
        }
    }

    override public function update(dt:Float) {
        return false;
    }

    function applyAcceleration(dt:Float) {
        var ix = Std.int(x);
        var iy = Std.int(y);
        var wx = Math.round(isFront ? ix : 2 * ix + background.windTextureX);
        var wy = Math.round(isFront ? iy : 2 * iy + background.windTextureY);
        var accx = Assets.noiseX[wy % Assets.noiseHeight][wx % Assets.noiseWidth];
        var accy = Assets.noiseY[wy % Assets.noiseHeight][wx % Assets.noiseWidth];
        var dist = Math.sqrt(accx * accx + accy * accy);
        if(dist > 0) {
            accx /= dist;
            accy /= dist;
        }
        vx += accx * ACC;
        vy += accy * ACC + GRAVITY;
        vx *= Math.pow(DAMP, dt);
        vy *= Math.pow(DAMP, dt);
    }

    override public function tick(dt:Float) {
        if(x < 0 || y < 0 || x >= Main.WIDTH || y >= Main.HEIGHT) {
            spawn(true);
        }
        applyAcceleration(dt);
        xx += vx;
        yy += vy;
        x = Std.int(xx);
        y = Std.int(yy);
    }
}

class Background {
    public static inline var FLAKE_COUNT = 100;
    var bitmap : Bitmap;
    var snowTile : Tile;
    var snowFront : SpriteBatch;
    var snowBack : SpriteBatch;
    public var windTextureX : Float = 0.;
    public var windTextureY : Float = 0.;

    public function new() {
        bitmap = new Bitmap(Res.gfx.background.toTile());
        Game.inst.world.add(bitmap, Game.LAYER_BACK);
        snowTile = Tile.fromColor(0xc0cbdc);
        snowFront = new SpriteBatch(snowTile);
        Game.inst.world.add(snowFront, Game.LAYER_FX_MID);
        snowBack = new SpriteBatch(snowTile);
        Game.inst.world.add(snowBack, Game.LAYER_FX_BACK);
        for(i in 0...FLAKE_COUNT) {
            if(Std.random(3) == 0) {
                var flake = new Flake(snowTile, this, true);
                snowFront.add(flake);
            } else {
                var flake = new Flake(snowTile, this, false);
                flake.r = flake.g = flake.b = Std.random(2) == 0 ? .5 : .3;
                snowBack.add(flake);
            }
        }
    }

    public function update(dt:Float) {
        windTextureX += dt * 50;
        windTextureY += dt * 30;
        for(flake in snowFront.getElements()) {
            flake.tick(dt);
        }
        for(flake in snowBack.getElements()) {
            flake.tick(dt);
        }
    }
}