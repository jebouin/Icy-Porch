package entities;

import h2d.Graphics;
import h2d.col.IPolygon;
import h2d.col.IPoint;

class Truck extends Entity {
    var animBack : Anim;
    public var boxCount : Int = 0;
    public var boxTotal : Int = 5;
    public var spawnTime : Float = 2.;
    public var spawnTimer : Float = 2.;
    var bar : Graphics;
    var tuto : Anim;

    public function new(x:Int, y:Int, boxCount:Int, spawnTimeTiles:Float) {
        this.boxTotal = boxCount;
        this.spawnTime = this.spawnTimer = (spawnTimeTiles * Level.TS - 13) / Box.MOVE_VEL;
        super(Assets.animData.get("truck"), Game.LAYER_TRUCK, x, y);
        animBack = new Anim();
        animBack.playFromName("truckBack");
        animBack.x = anim.x;
        animBack.y = anim.y;
        setColliderRect(64 - 4, 32);
        Game.inst.world.add(animBack, Game.LAYER_TRUCK_BACK);
        bar = new Graphics(anim);
        tuto = new Anim();
        tuto.playFromName("tutorialX");
        tuto.x = 20;
        tuto.y = 2;
        anim.addChild(tuto);
    }

    override public function delete() {
        animBack.remove();
        anim.remove();
        bar.remove();
        tuto.remove();
    }

    public function hit() {
        if(deleted) return;
        Game.inst.level.colliders.remove(collider);
        deleted = true;
    }

    override public function update(dt:Float) {
        super.update(dt);
        if(Game.inst.started) {
            if(boxCount < boxTotal) {
                spawnTimer += dt;
                if(spawnTimer > spawnTime) {
                    spawnTimer = 0.;
                    boxCount++;
                    Game.inst.boxes.push(new Box());
                }
            } else {
                spawnTimer = 0.;
            }
        }
        animBack.update(dt);
        bar.visible = boxCount > 0 && boxCount < boxTotal;
        tuto.visible = boxCount == 0;
        if(tuto.visible) {
            tuto.update(dt);
            tuto.currentFrame = anim.currentFrame;
        }
        if(bar.visible) {
            bar.clear();
            bar.lineStyle(2, 0x262b44);
            var lw = 15;
            var lx = 64 - 26 - lw, ly = 11 + (Std.int(anim.currentFrame) == 0 ? 0 : 1);
            bar.moveTo(lx, ly);
            bar.lineTo(lx + lw, ly);
            var t = spawnTimer / spawnTime;
            bar.lineStyle(2, 0x8b9bb4);
            bar.moveTo(lx, ly);
            bar.lineTo(lx + lw * t, ly);
        }
    }
}