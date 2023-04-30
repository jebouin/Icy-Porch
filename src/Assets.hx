package ;

import hxd.res.Sound;
import haxe.ds.Vector;
import h2d.Tile;
import h2d.Font;
import haxe.ds.StringMap;

typedef AnimData = {
    var tiles : Array<Tile>;
    var fps : Int;
    var loops : Bool;
}

class Assets {
    public static var noiseX : Vector<Vector<Float> >;
    public static var noiseY : Vector<Vector<Float> >;
    public static var noiseWidth : Int;
    public static var noiseHeight : Int;
    public static var font : Font;
    public static var fontLarge : Font;
    public static var tiles : StringMap<Tile>;
    public static var animData : StringMap<AnimData>;
    public static var explosionAnim : AnimData;
    // Audio
    public static var soundDefs : StringMap<Data.SoundDef>;
    public static var nameToSound : StringMap<Sound>;
    public static var nameToMusic : StringMap<Sound>;

    public static function init() {
        Data.load(hxd.Res.data.entry.getText());
        font = hxd.Res.fonts.cc13.toFont();
        fontLarge = hxd.Res.fonts.large.toFont();
        loadTiles();
        loadNoise();
        loadAudio();
    }

    static function loadTiles() {
        tiles = new StringMap<Tile>();
        animData = new StringMap<AnimData>();
        var atlasTile = hxd.Res.gfx.entities.toTile();
        for(anim in Data.atlas.all) {
            var name = anim.name;
            var tile = atlasTile.sub(anim.x, anim.y, anim.width, anim.height);
            if(anim.frameCount == null && anim.frameWidth == null) {
                if(anim.centerX == null) {
                    tile.dx = -tile.iwidth >> 1;
                    tile.dy = -tile.iheight >> 1;
                } else {
                    tile.dx = -anim.centerX;
                    tile.dy = -anim.centerY;
                }
                tiles.set(name, tile);
                animData.set(name, {tiles: [tile], fps: 1, loops: false});
            } else {
                var uniqueTiles = [];
                var frameWidth = anim.frameWidth, frameHeight = anim.frameHeight;
                if(frameWidth == null) {
                    frameWidth = Std.int(tile.width / anim.frameCount);
                    frameHeight = tile.iheight;
                }
                var cntx = Std.int(tile.width / frameWidth);
                var cnty = Std.int(tile.height / frameHeight);
                var frameCount = anim.frameCount;
                var centerX = anim.centerX, centerY = anim.centerY;
                if(centerX == null) {
                    centerX = frameWidth >> 1;
                }
                if(centerY == null) {
                    centerY = frameHeight >> 1;
                }
                if(frameCount == null) {
                    frameCount = cntx * cnty;
                }
                for(f in 0...frameCount) {
                    var i = Std.int(f / cntx), j = f % cntx;
                    var sub = tile.sub(j * frameWidth, i * frameHeight, frameWidth, frameHeight, -centerX, -centerY);
                    uniqueTiles.push(sub);
                }
                var tiles = [];
                if(anim.frames != null) {
                    for(f in anim.frames) {
                        tiles.push(uniqueTiles[f.id]);
                    }
                } else {
                    tiles = uniqueTiles;
                }
                var fps = anim.fps;
                if(fps == null) {
                    fps = 1;
                }
                animData.set(name, {tiles: tiles, fps: fps, loops: anim.loops != null ? anim.loops : true});
            }
        }
        explosionAnim = {tiles: hxd.Res.gfx.explosionLarge.toTile().gridFlatten(64, -32, -32), fps: 60, loops: false};
    }

    static function loadNoise() {
        var bd = hxd.Res.gfx.noiseTexture.toBitmap();
        bd.lock();
        noiseWidth = bd.width;
        noiseHeight = bd.height;
        noiseX = new Vector<Vector<Float> >(noiseHeight);
        noiseY = new Vector<Vector<Float> >(noiseHeight);
        for(i in 0...noiseHeight) {
            noiseX[i] = new Vector<Float>(noiseWidth);
            noiseY[i] = new Vector<Float>(noiseWidth);
        }
        for(i in 0...noiseHeight) {
            for(j in 0...noiseWidth) {
                var col = bd.getPixel(j, i);
                noiseX[i][j] = (col & 255) / 255.0 * 2 - 1;
                noiseY[i][j] = ((col >> 8) & 255) / 255.0 * 2 - 1;
            }
        }
    }

    static function loadAudio() {
        soundDefs = new StringMap<Data.SoundDef>();
        for(s in Data.soundDef.all) {
            soundDefs.set(s.name, s);
        }
        nameToMusic = new StringMap<Sound>();
        function addMusic(dir:String) {
            for(res in hxd.Res.load(dir)) {
                var music = res.toSound();
                music.getData();
                nameToMusic.set(res.name.substr(0, res.name.indexOf(".")), music);
            }
        }
        #if js
        addMusic("music/exportMP3");
        #else
        addMusic("music/exportWAV");
        #end
        nameToSound = new StringMap<Sound>();
        for(res in hxd.Res.load("sfx")) {
            var sound = res.toSound();
            sound.getData();
            nameToSound.set(sound.name.substr(0, sound.name.indexOf(".")), sound);
        }
    }
}