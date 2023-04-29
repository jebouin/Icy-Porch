package ;

import h2d.Graphics;
import SceneManager.Scene;
import entities.*;

class Game extends Scene {
    static var _layer = 0;
    public static var LAYER_CLEAR = _layer++;
    public static var LAYER_FX_BACK = _layer++;
    public static var LAYER_BACK = _layer++;
    public static var LAYER_BOX = _layer++;
    public static var LAYER_TRUCK = _layer++;
    public static var LAYER_FX_MID = _layer++;
    public static var LAYER_WALLS = _layer++;
    public static var LAYER_FX_FRONT = _layer++;
    public static var LAYER_DEBUG = _layer++;
    public static var inst : Game;
    public var level : Level;
    public var entities : Array<Entity> = [];
    public var boxes : Array<Box> = [];
    public var spawnX : Int;
    public var spawnY : Int;

    public function new() {
        super();
        if(inst != null) {
            throw "Game scene already exists";
        }
        inst = this;
        level = new Level();
        boxes.push(new Box());
    }

    override public function delete() {
        super.delete();
        inst = null;
        for(b in boxes) {
            b.delete();
        }
        for(e in entities) {
            e.delete();
        }
    }

    override public function update(dt:Float) {
        super.update(dt);
        var i = 0;
        while(i < boxes.length) {
            boxes[i].update(dt);
            if(boxes[i].deleted) {
                boxes.splice(i, 1);
            } else {
                i++;
            }
        }
        i = 0;
        while(i < entities.length) {
            entities[i].update(dt);
            if(entities[i].deleted) {
                entities.splice(i, 1);
            } else {
                i++;
            }
        }
    }

    public function removeEntities() {
        for(e in entities) {
            e.delete();
        }
        entities = [];
        for(b in boxes) {
            b.delete();
        }
        boxes = [];
    }
}