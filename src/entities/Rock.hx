package entities;

class Rock extends Entity {
    var broken : Bool = false;
    public function new(x:Int, y:Int) {
        super(Assets.animData.get("rock"), Game.LAYER_TRUCK, x, y);
        setColliderRect(16, 16);
    }

    override public function update(dt:Float) {
        super.update(dt);
        if(broken) {
            delete();
        }
    }

    public function hit(dx:Float, dy:Float) {
        if(broken) return;
        broken = true;
        Game.inst.fx.brokenBlock(x, y, dx, dy);
    }
}