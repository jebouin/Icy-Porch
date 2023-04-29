package ;

import h2d.Graphics;
import SceneManager.Scene;

class Game extends Scene {
    static var _layer = 0;
    public static var LAYER_CLEAR = _layer++;
    public static var LAYER_FX_BACK = _layer++;
    public static var LAYER_BACK = _layer++;
    public static var LAYER_ENTITY = _layer++;
    public static var LAYER_FX_MID = _layer++;
    public static var LAYER_WALLS = _layer++;
    public static var LAYER_FX_FRONT = _layer++;
    public static var LAYER_DEBUG = _layer++;
    public static var inst : Game;
    public var level : Level;

    public function new() {
        super();
        if(inst != null) {
            throw "Game scene already exists";
        }
        inst = this;
        level = new Level();
        var g = new Graphics();
        world.add(g, LAYER_ENTITY);
        g.beginFill(0xFF0000);
        g.drawCircle(150, 100, 10);
        g.endFill();
    }

    override public function delete() {
        super.delete();
        inst = null;
    }

    override public function update(dt:Float) {
        super.update(dt);
    }
}