package fx;

import hxd.Pixels;
import h2d.Object;
import h2d.Graphics;
import PixelBatch.BatchElement;

class Dust extends BatchElement {
    public static inline var ACC_MIN = .07;
    public static inline var ACC_MAX = .5;
    public static inline var DAMP = .98;
    public var vx : Float = 0.;
    public var vy : Float = 0.;
    var tr : TransitionOut;

    public function new(x:Float, y:Float, col:Int, tr:TransitionOut) {
        super(x, y, col);
        this.tr = tr;
    }

    override public function init(x:Float, y:Float, col:Int) {
        super.init(x, y, col);
        vx = vy = 0.;
    }

    override public function update(dt:Float) {
        return false;
    }

    override public function tick(dt:Float) {
        ix = Std.int(x);
        iy = Std.int(y);
        var wx = (ix + tr.anx) & 511;
        var wy = (iy + tr.any) & 255;
        vx += Assets.noiseX[wy][wx] * tr.acc;
        vy += Assets.noiseY[wy][wx] * tr.acc;
        vx *= DAMP;
        vy *= DAMP;
        x += vx;
        y += vy;
    }
}

class TransitionOut extends Object {
    public static inline var DUST_DENSITY = 4;
    var back : Graphics;
    var batch : PixelBatch;
    public var acc : Float = Dust.ACC_MIN;
    public var anx : Int;
    public var any : Int;

    public function new() {
        super();
        batch = new PixelBatch(Main.WIDTH * Main.HEIGHT * DUST_DENSITY, this);
    }

    public function start() {
        var screenshot = Main.inst.screenTexture.capturePixels();
        var cnt = 0;
        for(i in 0...Main.HEIGHT) {
            for(j in 0...Main.WIDTH) {
                var col = screenshot.getPixel(j, i);
                if(col & 0x00FFFFFF == Palette.BACKGROUND) {
                    continue;
                }
                for(k in 0...DUST_DENSITY) {
                    if(cnt < batch.count) {
                        batch.elements[cnt].init(j + Math.random(), i + Math.random(), col);
                        cnt++;
                    } else {
                        batch.add(new Dust(j + Math.random(), i + Math.random(), col, this));
                    }
                }
            }
        }
        batch.count = cnt;
        anx = Std.random(Main.WIDTH);
        any = Std.random(Main.HEIGHT);
        batch.alpha = 1.;
        if(back != null) {
            back.remove();
        }
        back = new Graphics();
        addChildAt(back, 0);
        back.beginFill(Palette.BLACK);
        back.drawRect(0, 0, Main.WIDTH, Main.HEIGHT);
        back.endFill();
    }

    public function update(dt:Float) {
        var t = Game.inst.stateTimer / Game.TRANSITION_TIME_OUT;
        acc = Util.lerp(Dust.ACC_MIN, Dust.ACC_MAX, Util.fmin(1., t * 2));
        batch.update(dt);
        if(t >= .5) {
            var tt = (t - .5) * 2;
            batch.alpha = (1 - tt) * (1 - tt);
        }
    }
}