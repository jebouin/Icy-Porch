package ;

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
    public static function playSoundSpa(name:String, x:Float, y:Float, z:Float) {
        var chan = playSound(name, false);
        var spatial = new hxd.snd.effect.Spatialization();
        spatial.referenceDistance = 16;
        spatial.position = new Vector(y, x, 0);
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
}