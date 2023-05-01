package ;

import h2d.Graphics;
import h2d.Text;
import h2d.Bitmap;
import SceneManager;
import Controller;

class Ending extends Scene {
    public static inline var IN_TIME = 3.;
    public static var inst : Ending;
    var title : Text;
    var by : Text;
    var timer : Float = 0.;
    var over : Graphics;

    override public function new() {
        if(inst != null) {
            throw "Ending scene already exists";
        }
        super();
        inst = this;
        Audio.playMusic("title");
        title = new Text(Assets.fontLarge, hud);
        title.text = "Congratulations!";
        title.x = Main.WIDTH * .5 - title.textWidth * .5;
        title.y = 15;
        by = new Text(Assets.font, hud);
        by.text = "Game made in 48 hours for Ludum Dare 53 by Jeremy Bouin";
        by.x = Main.WIDTH * .5 - by.textWidth * .5;
        by.y = 80;
        over = new Graphics(hud);
        over.beginFill(Palette.BLACK);
        over.drawRect(0, 0, Main.WIDTH, Main.HEIGHT);
        over.endFill();
    }

    override public function delete() {
        inst = null;
        super.delete();
    }

    override public function update(dt:Float) {
        super.update(dt);
        var controller = Main.inst.controller;
        timer += dt;
        var t = timer / IN_TIME;
        if(t < 1) {
            over.alpha = 1. - t * t;
        } else {
            over.visible = false;
        }
    }
}