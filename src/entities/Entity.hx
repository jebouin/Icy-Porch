package entities;

import h2d.col.IPolygon;
import h2d.col.IPoint;
import Assets.AnimData;

class Entity {
    public var anim : Anim;
    public var x : Int;
    public var y : Int;
    public var deleted : Bool;
    var collider : IPolygon = null;

    public function new(animData:AnimData, layer:Int, x:Int, y:Int, ?collider:IPolygon) {
        this.collider = collider;
        anim = new Anim(animData.tiles, animData.fps, animData.loops);
        Game.inst.world.add(anim, layer);
        Game.inst.entities.push(this);
        this.x = x;
        this.y = y;
        anim.x = x;
        anim.y = y;
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

    public function setColliderRect(w:Int, h:Int) {
        if(collider != null) {
            Game.inst.level.colliders.remove(collider);
        }
        collider = new IPolygon([
            new IPoint(x, y),
            new IPoint(x, y + h),
            new IPoint(x + w, y + h),
            new IPoint(x + w, y)
        ]);
        Game.inst.level.colliders.push(collider);
    }
}