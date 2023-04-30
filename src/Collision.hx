package ;

class Collision {
    public static inline var EPS = 1e-3;
    public static inline var INF_DIST = 1e9;
    public static inline var INF_DIST_SQ = 1e18;

    public static inline function pointPointDistSq(x1:Float, y1:Float, x2:Float, y2:Float) : Float {
        return (x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1);
    }

    public static inline function pointPointDist(x1:Float, y1:Float, x2:Float, y2:Float) : Float {
        return Math.sqrt(pointPointDistSq(x1, y1, x2, y2));
    }

    public static inline function iDet(x1:Int, y1:Int, x2:Int, y2:Int) : Int {
        return x1 * y2 - x2 * y1;
    }

    public static inline function isColinear(x1:Int, y1:Int, x2:Int, y2:Int, x3:Int, y3:Int) : Bool {
        return iDet(x2 - x1, y2 - y1, x3 - x1, y3 - y1) == 0;
    }

    public static inline function segmentPointDistSq(x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float) : Float {
        var px = x2 - x1;
        var py = y2 - y1;
        var d = px * px + py * py;
        var u = ((x3 - x1) * px + (y3 - y1) * py) / d;
        if (u > 1) u = 1;
        else if (u < 0) u = 0;
        var x = x1 + u * px;
        var y = y1 + u * py;
        var dx = x - x3;
        var dy = y - y3;
        return dx * dx + dy * dy;
    }
}