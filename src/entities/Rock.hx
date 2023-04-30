package entities;



class Rock extends Entity {
    public function new(x:Int, y:Int) {
        super(Assets.animData.get("rock"), Game.LAYER_TRUCK, x, y);
        setColliderRect(15, 15);
    }

    override public function update(dt:Float) {
        super.update(dt);
    }
}