package entities;

import h2d.Tile;
import h2d.TileGroup;
import h2d.ScaleGrid;
import h2d.col.IPolygon;
import h2d.col.IPoint;

class Sheet extends Entity {
    var isOn : Bool = false;
    var w : Int;
    var h : Int;
    var group : TileGroup;
    var prevBoxCount : Int = 0;
    var sod : SecondOrderDynamics = null;

    public function new(x:Int, y:Int, w:Int, h:Int) {
        this.w = w;
        this.h = h;
        super(Assets.animData.get("sheetOff"), Game.LAYER_BACK_WALLS, x, y);
        anim.visible = false;
        group = new TileGroup(Assets.tiles.get("sheetOff"));
        group.x = x;
        group.y = y;
        Game.inst.world.add(group, Game.LAYER_BACK_WALLS);
        render();
    }

    override public function delete() {
        group.remove();
        super.delete();
    }

    override public function update(dt:Float) {
        super.update(dt);
        if(!isOn) {
            var boxCount = 0;
            for(b in Game.inst.boxes) {
                var bounds = b.getBounds();
                if(bounds.x >= x + w || bounds.y >= y + h || bounds.x + bounds.width <= x || bounds.y + bounds.height <= y) continue;
                boxCount++;
            }
            if(boxCount == 0 && prevBoxCount > 0) {
                activate();
            }
            prevBoxCount = boxCount;
        } else {
            sod.update(dt, 1.);
            group.scaleX = sod.pos;
            group.scaleY = 1. / sod.pos;
            group.x = x + w * .5 - w * .5 * group.scaleX;
            group.y = y + h * .5 - h * .5 * group.scaleY;
        }
    }

    function render() {
        group.clear();
        var tile = group.tile;
        var cntx = Std.int(w / 8);
        var cnty = Std.int(h / 8);
        for(j in 0...cntx) {
            group.add(j * 8, 0, tile.sub(j == 0 ? 0 : (j == cntx - 1 ? 16 : 8), 0, 8, 8));
            group.add(j * 8, (cnty - 1) * 8, tile.sub(j == 0 ? 0 : (j == cntx - 1 ? 16 : 8), 16, 8, 8));
        }
        for(i in 0...cnty) {
            group.add(0, i * 8, tile.sub(0, i == 0 ? 0 : (i == cnty - 1 ? 16 : 8), 8, 8));
            group.add((cntx - 1) * 8, i * 8, tile.sub(16, i == 0 ? 0 : (i == cnty - 1 ? 16 : 8), 8, 8));
        }
        if(isOn) {
            for(i in 1...cnty - 1) {
                for(j in 1...cntx - 1) {
                    group.add(j * 8, i * 8, tile.sub(8, 8, 8, 8));
                }
            }
        }
    }

    public function activate() {
        if(isOn) return;
        isOn = true;
        setColliderRect(w, h);
        group.remove();
        group = new TileGroup(Assets.tiles.get("sheetOn"));
        group.x = x;
        group.y = y;
        Game.inst.world.add(group, Game.LAYER_BACK_WALLS);
        render();
        sod = new SecondOrderDynamics(3.5, .4, 0., 2., Fast);
        Audio.playSoundSpa("sheet", x + w * .5, y + h * .5);
    }
}