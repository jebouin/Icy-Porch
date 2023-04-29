package ;

import assets.LevelProject;
import h2d.TileGroup;

class LevelRender {
    var walls : TileGroup;
    var back : TileGroup;
    
    public function new(level:LevelProject_Level) {
        walls = level.l_Walls.render();
        Game.inst.world.add(walls, Game.LAYER_WALLS);
        back = level.l_Back.render();
        Game.inst.world.add(back, Game.LAYER_BACK);
    }

    public function delete() {
        walls.remove();
        back.remove();
    }
}

class Level {
    public static inline var TS = 16;
    public static inline var HTS = 8;
    public static inline var TILE_ICE = 1;
    public static inline var TILE_ICE_DR = 2;
    public static inline var TILE_ICE_DL = 3;
    public static inline var TILE_ICE_UR = 4;
    public static inline var TILE_ICE_UL = 5;
    public var width : Int;
    public var height : Int;
    public var worldWidth : Int;
    public var worldHeight : Int;
    var project : LevelProject;
    var level : LevelProject_Level = null;
    public var render : LevelRender = null;

    public function new() {
        project = new LevelProject();
        loadLevel(project.all_worlds.Default.all_levels.Level_0);
    }

    public function delete() {

    }

    function loadLevel(newLevel:LevelProject_Level) {
        level = newLevel;
        if(render != null) {
            render.delete();
        }
        render = new LevelRender(level);
    }
}