package ;

import h2d.Graphics;
import h2d.Text;
import h2d.Bitmap;
import SceneManager;
import Controller;

enum TitleState {
    Idle;
    Out;
}

class Title extends Scene {
    public static inline var OUT_TIME = 3.;
    public static inline var TUTO_Y = 30;
    public static inline var BACK_FROM_Y = -60;
    public static inline var BACK_TO_Y = 5;
    public static var inst : Title;
    var state : TitleState = Idle;
    var back : Bitmap;
    var title : Text;
    var tuto : Text;
    var timer : Float = 0.;
    var stateTimer : Float = 0.;
    var over : Graphics;

    override public function new() {
        if(inst != null) {
            throw "Title scene already exists";
        }
        super();
        inst = this;
        Audio.playMusic("title");
        back = new Bitmap(hxd.Res.gfx.cover.toTile(), world);
        back.y = -20;
        title = new Text(Assets.fontLarge, hud);
        title.text = "Icy Porch";
        title.x = 190;
        title.y = 5;
        tuto = new Text(Assets.font, hud);
        tuto.text = "Press X to start";
        tuto.x = 198;
        tuto.y = TUTO_Y;
        over = new Graphics(hud);
        over.beginFill(Palette.BLACK);
        over.drawRect(0, 0, Main.WIDTH, Main.HEIGHT);
        over.endFill();
        over.alpha = 0.;
    }

    override public function delete() {
        inst = null;
        super.delete();
    }

    override public function update(dt:Float) {
        super.update(dt);
        var controller = Main.inst.controller;
        timer += dt;
        stateTimer += dt;
        if(state == Idle) {
            if(controller.isPressed(Action.jump)) {
                state = Out;
                stateTimer = 0.;
                Audio.stopMusic(OUT_TIME * .8);
                Audio.playSound("start");
            }
            tuto.y = TUTO_Y + Math.sin(timer * 3.5) * 4.;
        } else if(state == Out) {
            if(stateTimer > OUT_TIME * .25) {
                tuto.visible = false;
            } else {
                tuto.visible = stateTimer % .1 < .05;
            }
            var t = stateTimer / OUT_TIME;
            over.alpha = t * t;
            if(stateTimer > OUT_TIME) {
                delete();
                new Game();
            }
        }
        var dist = BACK_TO_Y - BACK_FROM_Y;
        var mid = (BACK_TO_Y + BACK_FROM_Y) * .5;
        back.y = mid + Math.cos(timer * .5) * dist * .5;
    }
}