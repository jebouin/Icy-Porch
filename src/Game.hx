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
    Won;
    Out;
}

class Game extends Scene {
    public static inline var WIN_TIME = 1.5;
    public static inline var WIN_X = 336 + Level.WORLD_X;
    public static inline var TRANSITION_TIME_IN = .8;
    public static inline var TRANSITION_TIME_OUT = 1.8;
    static var _layer = 0;
    public static var LAYER_CLEAR = _layer++;
    public static var LAYER_BACK = _layer++;
    public static var LAYER_FX_BACK = _layer++;
    public static var LAYER_BACK_WALLS = _layer++;
    public static var LAYER_DECO_BACK = _layer++;
    public static var LAYER_TRUCK_BACK = _layer++;
    public static var LAYER_FX_MID = _layer++;
    public static var LAYER_BOX = _layer++;
    public static var LAYER_LAVA = _layer++;
    public static var LAYER_TRUCK = _layer++;
    public static var LAYER_WALLS = _layer++;
    public static var LAYER_DECO_FRONT = _layer++;
    public static var LAYER_MAGNETS = _layer++;
    public static var LAYER_FX_FRONT = _layer++;
    public static var LAYER_UI = _layer++;
    public static var LAYER_DEBUG = _layer++;
    public static var inst : Game;
    public var level : Level;
    public var entities : Array<Entity> = [];
    public var boxes : Array<Box> = [];
    public var truck : Truck;
    var background : Background;
    public var fx : Fx;
    public var spawnX : Int;
    public var spawnY : Int;
    var levelText : Text;
    var levelId : Int = 2;
    var transitionIn : TransitionIn;
    var transitionOut : TransitionOut;
    public var state(default, set) : GameState = Playing;
    public var stateTimer(default, null) = 0.;
    public var started : Bool = false;
    var progressText : Text;
    var progressTextTargetX : Int;
    var progressSOD : SecondOrderDynamics;
    var progressTimer : Float;
    var arrivedCount : Int = 0;

    public function new(?fromTitle:Bool=false) {
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
        Audio.playMusic("intro", "loop");
        fromTitle = true;
        if(fromTitle) {
            state = In;
        }
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
            boxes.sort(function(b1, b2) {
                return (b1.magnet == null ? 0 : 1) - (b2.magnet == null ? 0 : 1);
            });
            var i = 0, failed = false, dead = false;
            while(i < boxes.length) {
                boxes[i].update(dt);
                if(boxes[i].dead) {
                    dead = true;
                } else if(!boxes[i].deleted && boxes[i].x >= WIN_X) {
                    boxes[i].arrived = true;
                    boxes[i].delete();
                    arrivedCount++;
                    showProgress();
                    if(arrivedCount == truck.boxTotal) {
                        levelComplete();
                    }
                }
                if(boxes[i].deleted && !boxes[i].arrived) {
                    boxes.splice(i, 1);
                    failed = true;
                } else {
                    i++;
                }
            }
            if(failed) {
                levelFailed(false);
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
                levelFailed(false);
            }
            if(dead && !failed && Main.inst.controller.isPressed(Action.jump)) {
                levelFailed(true);
            }
            if(Main.inst.controller.isPressed(Action.magnet)) {
                toggleMagnets();
            }
            if(!started && Main.inst.controller.isPressed(Action.jump)) {
                started = true;
            }
            updateNonInteractive(dt);
        } if(state == In) {
            transitionIn.update(dt);
            if(stateTimer >= TRANSITION_TIME_IN) {
                state = Playing;
            }
            updateNonInteractive(dt);
        } else if(state == Out) {
            transitionOut.update(dt);
            if(stateTimer >= TRANSITION_TIME_OUT) {
                loadNextLevel();
                state = In;
            }
        } else if(state == Won) {
            updateNonInteractive(dt);
            if(stateTimer >= WIN_TIME) {
                state = Out;
            }
        }
    }

    function updateNonInteractive(dt:Float) {
        level.update(dt);
        background.update(dt);
        fx.update(dt);
        if(progressText != null) {
            progressSOD.update(dt, progressTextTargetX);
            progressText.x = progressSOD.pos;
            progressTimer += dt;
            if(progressTimer >= 1.5) {
                progressText.remove();
                progressText = null;
            } else if(progressTimer >= 1.) {
                progressText.alpha = 1. - (progressTimer - 1.) * 2.;
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
            case Playing:
            case Won:
            case Out:
                transitionOut.remove();
        }
        state = st;
        switch(state) {
            case In:
                transitionIn = new TransitionIn();
                world.filter = transitionIn;
            case Playing:
                world.filter = null;
                started = false;
            case Won:

            case Out:
                world.add(transitionOut, Game.LAYER_FX_FRONT);
                transitionOut.start();
        }
        stateTimer = 0.;
        return st;
    }

    public function loadLevel(i:Int) {
        if(!level.loadLevelById(i)) {
            return false;
        }
        for(e in entities) {
            if(Std.isOfType(e, Truck)) {
                truck = cast(e, Truck);
            }
        }
        levelText.text = level.title;
        levelText.x = Main.WIDTH * .5 - levelText.textWidth * .5;
        levelText.y = 1;
        arrivedCount = 0;
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
        state = Won;
    }

    public function levelFailed(fast:Bool) {
        loadLevel(levelId);
        started = fast;
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

    public function toggleMagnets() {
        for(e in entities) {
            if(Std.isOfType(e, Magnet)) {
                var m = cast(e, Magnet);
                m.toggle();
            }
        }
    }

    public function showProgress() {
        if(progressText != null) {
            progressText.remove();
        }
        progressText = new Text(Assets.font);
        world.add(progressText, LAYER_UI);
        if(arrivedCount == truck.boxTotal) {
            progressText.text = "Done!";
        } else {
            progressText.text = Std.string(arrivedCount) + "/" + Std.string(truck.boxTotal);
        }
        progressText.x = level.porchFrontX;
        progressText.y = level.porchFrontY + 3;
        progressSOD = new SecondOrderDynamics(2.5, 1., 0., progressText.x, Fast);
        progressTextTargetX = Std.int(progressText.x - progressText.textWidth - 35);
        progressTimer = 0.;
    }
}