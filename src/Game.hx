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
    public static var LAYER_LAVA = _layer++;
    public static var LAYER_TRUCK = _layer++;
    public static var LAYER_WALLS = _layer++;
    public static var LAYER_FX_FRONT = _layer++;
    public static var LAYER_DEBUG = _layer++;
    public static var inst : Game;
    public var level : Level;
    public var entities : Array<Entity> = [];
    public var boxes : Array<Box> = [];
    var background : Background;
    public var fx : Fx;
    public var spawnX : Int;
    public var spawnY : Int;
    var levelText : Text;
    var levelId : Int = 1;
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
        fx = new Fx(LAYER_FX_FRONT, LAYER_FX_MID);
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
        fx.delete();
    }

    override public function update(dt:Float) {
        super.update(dt);
        stateTimer += dt;
        if(state == Playing) {
            var i = 0, failed = false, dead = false;
            while(i < boxes.length) {
                boxes[i].update(dt);
                if(boxes[i].dead) {
                    dead = true;
                }
                if(boxes[i].deleted) {
                    boxes.splice(i, 1);
                    failed = true;
                } else {
                    i++;
                }
            }
            if(failed) {
                levelFailed();
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
            if(Main.inst.controller.isPressed(Action.retry)) {
                levelFailed();
            }
            if(dead && !failed && Main.inst.controller.isPressed(Action.jump)) {
                levelFailed();
            }
            level.update(dt);
            background.update(dt);
            fx.update(dt);
        } if(state == In) {
            transitionIn.update(dt);
            if(stateTimer >= TRANSITION_TIME_IN) {
                state = Playing;
            }
            level.update(dt);
            background.update(dt);
            fx.update(dt);
        } else if(state == Out) {
            transitionOut.update(dt);
            if(stateTimer >= TRANSITION_TIME_OUT) {
                loadNextLevel();
                state = In;
            }
        }
    }

    override public function updateConstantRate(dt:Float) {
        for(box in boxes) {
            box.updateConstantRate(dt);
        }
        fx.updateConstantRate(dt);
        world.x = fx.shakeX;
        world.y = fx.shakeY;
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
        fx.clear();
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

    public function levelFailed() {
        loadLevel(levelId);
    }

    public function onBoxCollision(i:Int, j:Int) {
        // Swap box i and j, hacky way to mitigate non-symmetrical collisions
        var tmp = boxes[i];
        boxes[i] = boxes[j];
        boxes[j] = tmp;
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