package ;

import h2d.Bitmap;
import hxd.BitmapData;
import haxe.ds.Vector;
import h2d.Tile;
import h2d.Drawable;
import h2d.RenderContext;
import h2d.impl.BatchDrawState;

@:allow(PixelBatch)
class BatchElement {
	public var x : Float = 0;
	public var y : Float = 0;
	public var ix : Int = 0;
	public var iy : Int = 0;
	public var col : Int = 0xFFFFFF;
	public var batch(default, null) : PixelBatch;
	public function new(x:Float, y:Float, col:Int) {
		init(x, y, col);
	}
	public function init(x:Float, y:Float, col:Int) {
		this.x = x;
		this.y = y;
		ix = Std.int(x);
		iy = Std.int(y);
		this.col = col;
	}
	function update(et:Float) {
		return true;
	}
    public dynamic function tick(dt:Float) {}
}

class PixelBatch extends Bitmap {
    public var elements : Vector<BatchElement>;
    public var count : Int = 0;
	var data : BitmapData;

	public function new(cnt:Int, parent) {
		super(null, parent);
        elements = new Vector<BatchElement>(cnt);
		data = new BitmapData(Main.WIDTH, Main.HEIGHT);
	}

	public function add(e:BatchElement) {
        if(count == elements.length) return e;
        elements[count++] = e;
		e.batch = this;
		return e;
	}

	public function clear() {
        count = 0;
		render();
	}

	override function sync(ctx) {
        for(i in 0...count) {
            elements[i].update(ctx.elapsedTime);
        }
		render();
		super.sync(ctx);
	}

	function render() {
		data.lock();
		for(i in 0...Main.HEIGHT) {
			for(j in 0...Main.WIDTH) {
				data.setPixel(j, i, 0x0);
			}
		}
		for(i in 0...count) {
			var e = elements[i];
			if(e.ix < 0 || e.iy < -1 || e.ix >= Main.WIDTH || e.iy >= Main.HEIGHT) continue;
			data.setPixel(e.ix, e.iy, 0xFF000000 | e.col);
		}
		data.unlock();
		tile = Tile.fromBitmap(data);
	}

	public function update(dt:Float) {
		for(i in 0...count) {
			elements[i].tick(dt);
		}
	}
}