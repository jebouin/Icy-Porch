package ;

import h3d.Engine;

class Scene {
	public var onFocusGain : Void->Void;
	public var onFocusLoss : Void->Void;
	public var onDelete : Void->Void;
    public var world : h2d.Scene;
	public var hud : h2d.Scene;
	public var masking(default, null) : Bool;

	public function new(masking:Bool=false) {
		this.masking = masking;
		SceneManager.add(this);
        world = new h2d.Scene();
        world.scaleMode = ScaleMode.Stretch(Main.WIDTH, Main.HEIGHT);
        hud = new h2d.Scene();
        hud.scaleMode = ScaleMode.Stretch(Main.WIDTH, Main.HEIGHT);
		Main.inst.sevents.addScene(world);
		Main.inst.sevents.addScene(hud);
	}
	public function delete() {
		Main.inst.sevents.removeScene(hud);
		Main.inst.sevents.removeScene(world);
		hud.remove();
        world.remove();
		SceneManager.remove(this);
		if(onDelete != null) {
			onDelete();
		}
	}
	public function update(dt:Float) {
	}
	public function updateBack(dt:Float) {
	}
	public function updateConstantRate(dt:Float) {
	}
    public function renderWorld(e:Engine) {
        world.render(e);
    }
	public function renderHUD(e:Engine) {
		hud.render(e);
	}
}

class SceneManager {
	public static var scenes : Array<Scene>;
	static var lastMaskingId : Int;

	public static function init() {
		scenes = new Array();
		updateLastMaskingId();
	}
	public static function deleteAll() {
		while(scenes.length > 0) {
			scenes[scenes.length - 1].delete();
		}
		updateLastMaskingId();
	}
	public static function update(dt:Float) {
		if(scenes.length == 0) return;
		scenes[scenes.length - 1].update(dt);
	}
	public static function updateBack(dt:Float) {
		for(scene in scenes) {
			scene.updateBack(dt);
		}
	}
	public static function updateConstantRate(dt:Float) {
		if(scenes.length == 0) return;
		scenes[scenes.length - 1].updateConstantRate(dt);
	}
	static function updateLastMaskingId() {
		if(scenes.length == 0) {
			lastMaskingId = -1;
			return;
		}
		lastMaskingId = 0;
		for(i in 0...scenes.length) {
			if(scenes[i].masking) {
				lastMaskingId = i;
			}
		}
	}
    public static function renderWorld(e:Engine) {
		if(lastMaskingId == -1) return;
		for(i in lastMaskingId...scenes.length) {
			scenes[i].renderWorld(e);
		}
    }
    public static function renderHUD(e:Engine) {
		if(lastMaskingId == -1) return;
		for(i in lastMaskingId...scenes.length) {
			scenes[i].renderHUD(e);
		}
    }
	@:allow(Scene)
	static private function add(scene:Scene) {
		if(scenes.length > 0) {
			if(scenes[scenes.length-1].onFocusLoss != null) {
				scenes[scenes.length-1].onFocusLoss();
			}
		}
		scenes.push(scene);
		updateLastMaskingId();
	}
	@:allow(Scene)
	static private function remove(scene:Scene) {
		scenes.remove(scene);
		if(scenes.length > 0) {
			if(scenes[scenes.length-1].onFocusGain != null) {
				scenes[scenes.length-1].onFocusGain();
			}
		}
		updateLastMaskingId();
	}
}