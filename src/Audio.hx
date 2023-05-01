package ;

import hxd.snd.effect.Spatialization;
import entities.Box;
import h3d.Vector;
import hxd.snd.Channel;
import hxd.snd.Manager;
import hxd.snd.ChannelGroup;

class Audio {
    static var manager : Manager;
    static var soundGroup : ChannelGroup;
    static var musicGroup : ChannelGroup;
    static var music : Channel;
    static var currentMusicName = "";
    static var slideSounds : Array<Channel> = [];
    static var slideBoxes : Array<Box> = [];
    static var slideSpatials : Array<Spatialization> = [];
    static var jumpChan : Channel = null;

    public static function init() {
        manager = Manager.get();
        soundGroup = new ChannelGroup("sound");
        musicGroup = new ChannelGroup("music");
    }
    public static function setMasterVolume(v:Float) {
        manager.masterVolume = v;
    }
    public static function setMusicVolume(v:Float) {
        musicGroup.volume = v;
    }
    public static function setSoundEffectVolume(v:Float) {
        soundGroup.volume = v;
    }
    public static function mute() {
        manager.masterVolume = 0;
    }
    public static function unmute() {
        manager.masterVolume = 1;
    }
    public static function playMusic(name:String, ?next:String=null) {
        if(name == currentMusicName) return;
        stopMusic();
        currentMusicName = name;
        var s = Assets.nameToMusic.get(name);
        if(s == null) {
            trace("Invalid music name", name);
            return;
        }
        music = s.play(true, 1., musicGroup);
        if(next != null) {
            music.loop = false;
            music.onEnd = function() {
                playMusic(next);
            }
        }
    }
    public static function stopMusic(?fadeTime:Float=0.) {
        if(music == null) return;
        if(fadeTime > 0) {
            music.fadeTo(0., fadeTime, function() {
                music.stop();
                currentMusicName = "";
            });
        } else {
            music.stop();
            currentMusicName = "";
        }
    }
    public static function pauseMusic() {
        if(music == null) return;
        music.pause = true;
    }
    public static function resumeMusic() {
        if(music == null) return;
        music.pause = false;
    }
    public static function playJump() {
        if(jumpChan != null) return;
        var pos = music.position / music.duration;
        jumpChan = playSound(pos < .5 || currentMusicName != "loop" ? "jumpG" : "jumpF");
        jumpChan.onEnd = function() {
            jumpChan = null;
        }
    }
    public static function playDeliver() {
        var pos = music.position / music.duration;
        playSoundSpa(pos < .5 || currentMusicName != "loop" ? "deliverG" : "deliverF", Game.WIN_X * .5 + Main.WIDTH2 * .5, 0);
    }
    public static function playKick() {
        var pos = music.position / music.duration;
        playSoundSpa(pos < .5 || currentMusicName != "loop" ? "kickG" : "kickF", Game.inst.spawnX * .35 + Main.WIDTH2 * .65, 0);
    }
    public static function playSoundSpa(name:String, x:Float, y:Float) {
        var chan = playSound(name, false);
        var spatial = new hxd.snd.effect.Spatialization();
        spatial.referenceDistance = 16;
        spatial.position = new Vector(0, x, 0);
        chan.addEffect(spatial);
        return chan;
    }
    public static function playSound(name:String, ?loop:Bool=false, ?vol:Float=1.) {
        var sound = Assets.nameToSound.get(name);
        if(sound == null) return null;
        var def = Assets.soundDefs.get(name);
        if(def != null) {
            vol *= def.volume;
        }
        return sound.play(loop, vol, soundGroup);
    }
    public static function playSlide(box:Box) {
        stopSlide(box);
        var chan = playSound("slide", true);
        slideSounds.push(chan);
        slideBoxes.push(box);
        var spatial = new hxd.snd.effect.Spatialization();
        spatial.referenceDistance = 80;
        //spatial.fadeDistance = 40;
        spatial.position = new Vector(0, box.x + 8, 0);
        chan.addEffect(spatial);
        slideSpatials.push(spatial);
    }
    public static function stopSlide(box:Box) {
        var i = slideBoxes.indexOf(box);
        if(i == -1) return;
        slideSounds[i].stop();
        slideSounds.splice(i, 1);
        slideBoxes.splice(i, 1);
        slideSpatials.splice(i, 1);
    }
    public static function stopAllSlide() {
        for(i in 0...slideBoxes.length) {
            slideSounds[i].stop();
        }
        slideSounds = [];
        slideBoxes = [];
        slideSpatials = [];
    }
    public static function update(dt:Float) {
        for(i in 0...slideBoxes.length) {
            var box = slideBoxes[i];
            var spatial = slideSpatials[i];
            spatial.position = new Vector(0, box.x + 8, 0);
        }
        var listener = manager.listener;
        listener.position = new Vector(-30, Main.WIDTH2, 0);
    }
}