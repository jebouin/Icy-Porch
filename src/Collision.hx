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
}