package entities;

import h2d.TileGroup;

class Rock extends Entity {
    var broken : Bool = false;
    var w : Int;
    var h : Int;
    var group : TileGroup;

    public function new(x:Int, y:Int, w:Int, h:Int) {
        this.w = w;
        this.h = h;
        super(Assets.animData.get("rock"), Game.LAYER_WALLS, x, y);
        setColliderRect(w, h);
        anim.visible = false;
        group = new TileGroup(Assets.tiles.get("rock"));
        group.x = x;
        group.y = y;
        Game.inst.world.add(group, Game.LAYER_WALLS);
        render();
    }

    override public function delete() {
        group.remove();
        super.delete();
    }

    override public function update(dt:Float) {
        super.update(dt);
        if(broken) {
            delete();
        }
    }

    function render() {
        group.clear();
        var tile = group.tile;
        var cntx = Std.int(w / 16);
        var cnty = Std.int(h / 16);
        if(cntx > 1 && cnty > 1) {
            for(j in 0...cntx) {
                group.add(j * 16, 0, tile.sub(j == 0 ? 0 : (j == cntx - 1 ? 32 : 16), 0, 16, 16));
                group.add(j * 16, (cnty - 1) * 16, tile.sub(j == 0 ? 0 : (j == cntx - 1 ? 32 : 16), 32, 16, 16));
            }
            for(i in 0...cnty) {
                group.add(0, i * 16, tile.sub(0, i == 0 ? 0 : (i == cnty - 1 ? 32 : 16), 16, 16));
                group.add((cntx - 1) * 16, i * 16, tile.sub(32, i == 0 ? 0 : (i == cnty - 1 ? 32 : 16), 16, 16));
            }
            for(i in 1...cnty - 1) {
                for(j in 1...cntx - 1) {
                    group.add(j * 16, i * 16, tile.sub(16, 16, 16, 16));
                }
            }
        } else if(cnty > 1) {
            for(i in 0...cnty) {
                group.add(0, i * 16, tile.sub(48, i == 0 ? 0 : 16, 16, 16));
            }
        } else {
            for(j in 0...cntx) {
                group.add(j * 16, 0, tile.sub(48, 0, 16, 16));
            }
        }
    }

    public function hit(dx:Float, dy:Float) {
        if(broken) return;
        broken = true;
        Game.inst.fx.brokenBlock(x, y, w, h, dx, dy);
    }
}