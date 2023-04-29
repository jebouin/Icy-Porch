package ;

import h2d.Tile;
import h2d.Font;
import haxe.ds.StringMap;

typedef AnimData = {
    var tiles : Array<Tile>;
    var fps : Int;
    var loops : Bool;
}

class Assets {
    public static var font : Font;
    public static var tiles : StringMap<Tile>;
    public static var animData : StringMap<AnimData>;

    public static function init() {
        Data.load(hxd.Res.data.entry.getText());
        font = hxd.Res.fonts.cc13.toFont();
        loadTiles();
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
    }
}