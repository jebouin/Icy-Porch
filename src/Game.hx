package ;

import h2d.Text;
import h2d.Graphics;
import SceneManager.Scene;
import entities.*;
import Controller;
import fx.*;

enum GameState {
    In;
    Playing;
    Out;
}

class Game extends Scene {
    public static inline var TRANSITION_TIME_IN = .8;
    public static inline var TRANSITION_TIME_OUT = 1.8;
    static var _layer = 0;
    public static var LAYER_CLEAR = _layer++;
    public static var LAYER_BACK = _layer++;
    public static var LAYER_FX_BACK = _layer++;
    public static var LAYER_BACK_WALLS = _layer++;
    public static var LAYER_FX_MID = _layer++;
    public static var LAYER_BOX = _layer++;
    public static var LAYER_TRUCK = _layer++;
    public static var LAYER_WALLS = _layer++;
    public static var LAYER_FX_FRONT = _layer++;
    public static var LAYER_DEBUG = _layer++;
    public static var inst : Game;
    public var level : Level;
    public var entities : Array<Entity> = [];
    public var boxes : Array<Box> = [];
    var background : Background;
    public var spawnX : Int;
    public var spawnY : Int;
    var levelText : Text;
    var levelId : Int = 0;
    var transitionIn : TransitionIn;
    var transitionOut : TransitionOut;
    public var state(default, set) : GameState = Playing;
    public var stateTimer(default, null) = 0.;

    public function new() {
        super();
        if(inst != null) {
            throw "Game scene already exists";
        }
        inst = this;
        levelText = new Text(Assets.fontLarge, hud);
        level = new Level();
        loadLevel(levelId);
        background = new Background();
        transitionOut = new TransitionOut();
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
        stateTimer += dt;
        if(state == Playing) {
            levelComplete();
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
            #if debug
            if(Main.inst.controller.isPressed(Action.debugNextLevel)) {
                levelComplete();
            }
            #end
            background.update(dt);
        } if(state == In) {
            transitionIn.update(dt);
            if(stateTimer >= TRANSITION_TIME_IN) {
                state = Playing;
            }
            background.update(dt);
        } else if(state == Out) {
            transitionOut.update(dt);
            if(stateTimer >= TRANSITION_TIME_OUT) {
                loadNextLevel();
                state = In;
            }
        }
    }

    public function set_state(st:GameState) {
        switch(state) {
            case In:
                world.filter = null;
                transitionIn = null;
            case Out:
                transitionOut.remove();
            case Playing:
        }
        state = st;
        switch(state) {
            case In:
                transitionIn = new TransitionIn();
                world.filter = transitionIn;
            case Out:
                world.add(transitionOut, Game.LAYER_FX_FRONT);
                transitionOut.start();
            case Playing:
                world.filter = null;
        }
        stateTimer = 0.;
        return st;
    }

    public function loadLevel(i:Int) {
        if(!level.loadLevelById(i)) {
            return false;
        }
        levelText.text = level.title;
        levelText.x = Main.WIDTH * .5 - levelText.textWidth * .5;
        levelText.y = 1;
        return true;
    }

    public function loadNextLevel() {
        if(!loadLevel(++levelId)) {
            levelId = 0;
            loadLevel(levelId);
        }
    }

    public function levelComplete() {
        state = Out;
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