package entities;

class Truck extends Entity {
    public var spawnCount : Int = 0;
    public var spawnTotal : Int = 5;
    public var spawnTime : Float = 2.;
    public var spawnTimer : Float = 2.;

    public function new(x:Int, y:Int) {
        super(Assets.animData.get("truck"), Game.LAYER_TRUCK, x, y);
    }

    override public function update(dt:Float) {
        super.update(dt);
        if(spawnCount < spawnTotal) {
            spawnTimer += dt;
            if(spawnTimer > spawnTime) {
                spawnTimer = 0.;
                spawnCount++;
                Game.inst.boxes.push(new Box());
            }
        } else {
            spawnTimer = 0.;
        }
    }
}