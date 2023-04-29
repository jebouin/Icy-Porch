package entities;

class Truck extends Entity {
    public function new(x:Int, y:Int) {
        super(Assets.animData.get("truck"), Game.LAYER_TRUCK);
        this.x = x;
        this.y = y;
    }
}