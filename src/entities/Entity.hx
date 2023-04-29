package entities;

import Assets.AnimData;

class Entity {
    public var anim : Anim;
    public var x : Int;
    public var y : Int;
    public var deleted : Bool;

    public function new(animData:AnimData, layer:Int) {
        anim = new Anim(animData.tiles, animData.fps, animData.loops);
        Game.inst.world.add(anim, layer);
        Game.inst.entities.push(this);
    }

    public function delete() {
        if(deleted) return;
        deleted = true;
        anim.remove();
    }

    public function update(dt:Float) {
        anim.update(dt);
        anim.x = x;
        anim.y = y;
    }
}