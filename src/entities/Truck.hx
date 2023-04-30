package entities;

import h2d.col.IPolygon;
import h2d.col.IPoint;

class Truck extends Entity {
    public var boxCount : Int = 0;
    public var boxTotal : Int = 5;
    public var spawnTime : Float = 2.;
    public var spawnTimer : Float = 2.;

    public function new(x:Int, y:Int, boxCount:Int, spawnTimeTiles:Float) {
        this.boxTotal = boxCount;
        this.spawnTime = this.spawnTimer = (spawnTimeTiles * Level.TS - 13) / Box.MOVE_VEL;
        super(Assets.animData.get("truck"), Game.LAYER_TRUCK, x, y);
        setColliderRect(64, 32);
    }

    public function hit() {
        if(deleted) return;
        Game.inst.level.colliders.remove(collider);
        deleted = true;
    }

    override public function update(dt:Float) {
        super.update(dt);
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
}