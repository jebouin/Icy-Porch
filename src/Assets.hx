package ;

import h2d.Font;

class Assets {
    public static var font : Font;

    public static function init() {
        font = hxd.Res.fonts.cc13.toFont();
    }
}