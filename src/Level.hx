package ;

import h2d.col.IPolygon;
import h2d.col.IPoint;
import h2d.col.Point;
import haxe.ds.IntMap;
import haxe.ds.Vector;
import h2d.col.IBounds;
import assets.LevelProject;
import h2d.TileGroup;
import entities.*;

enum CollisionShape {
    Empty;
    Full;
    DiagDR;
    DiagDL;
    DiagUR;
    DiagUL;
}

class LevelRender {
    var walls : TileGroup;
    var back : TileGroup;
    
    public function new(level:LevelProject_Level) {
        walls = level.l_Walls.render();
        Game.inst.world.add(walls, Game.LAYER_WALLS);
        back = level.l_Back.render();
        Game.inst.world.add(back, Game.LAYER_BACK_WALLS);
    }

    public function delete() {
        walls.remove();
        back.remove();
    }
}

class Level {
    static var DX = [0, 1, 0, -1];
    static var DY = [-1, 0, 1, 0];
    public static inline var TS = 16;
    public static inline var HTS = 8;
    public static inline var TILE_ICE = 1;
    public static inline var TILE_ICE_DR = 2;
    public static inline var TILE_ICE_DL = 3;
    public static inline var TILE_ICE_UR = 4;
    public static inline var TILE_ICE_UL = 5;
    public var width : Int;
    public var height : Int;
    public var worldWidth : Int;
    public var worldHeight : Int;
    public var tileCollisions : Vector<CollisionShape>;
    var visited : Array<Array<Bool> >;
    var project : LevelProject;
    var level : LevelProject_Level = null;
    public var render : LevelRender = null;
    public var title(default, null) : String = "";
    var colliders : Array<IPolygon> = [];

    public function new() {
        project = new LevelProject();
        loadTileCollisions();
    }

    public function delete() {

    }

    public function loadLevelById(id:Int) {
        var level = project.all_worlds.Default.getLevel(null, "Level_" + id);
        if(level == null) {
            return false;
        }
        loadLevel(level);
        return true;
    }

    function loadLevel(newLevel:LevelProject_Level) {
        Game.inst.removeEntities();
        level = newLevel;
        width = Std.int(level.pxWid / TS);
        height = Std.int(level.pxHei / TS);
        if(render != null) {
            render.delete();
        }
        render = new LevelRender(level);
        for(t in level.l_Entities.all_Truck) {
            new Truck(t.pixelX, t.pixelY);
            Game.inst.spawnX = t.pixelX + t.width - 16;
            Game.inst.spawnY = t.pixelY + t.height - 10;
        }
        loadColliders();
        title = level.f_Title;
    }

    function loadColliders() {
        colliders = [];
        visited = [for(i in 0...height) [for(j in 0...width) false]];
        for(i in 0...height) {
            for(j in 0...width) {
                if(visited[i][j]) continue;
                var col = getCollisionShape(i, j);
                if(col == Empty) continue;
                var comp = getCollisionComponent(i, j);
                var pts = getComponentCorners(comp);
                colliders.push(new IPolygon(pts));
            }
        }
    }

    inline function isInLevel(i:Int, j:Int) {
        return i >= 0 && j >= 0 && i < height && j < width;
    }
    inline function getTile(i:Int, j:Int) {
        return level.l_Walls.getInt(j, i);
    }
    inline function getCollisionShape(i:Int, j:Int) {
        var val = level.l_Walls.getInt(j, i);
        return val == -1 ? Empty : tileCollisions[val];
    }

    function getCollisionComponent(i:Int, j:Int) {
        var comp : Array<{i:Int, j:Int}> = [];
        if(visited[i][j]) return comp;
        visited[i][j] = true;
        comp.push({i: i, j: j});
        for(d in 0...4) {
            var ii = i + DY[d];
            var jj = j + DX[d];
            if(!isInLevel(ii, jj)) continue;
            var col = getCollisionShape(ii, jj);
            if(col == Empty) continue;
            var add = getCollisionComponent(ii, jj);
            comp = comp.concat(add);
        }
        return comp;
    }
    function getComponentCorners(comp:Array<{i:Int, j:Int}>) : Array<IPoint> {
        var xMax = width * TS + 1;
        inline function ptu(x:Int, y:Int) {
            return y * xMax + x;
        }
        inline function utp(u:Int) {
            return {x: u % xMax, y: Std.int(u / xMax)};
        }
        var graph = new IntMap<Int>();
        inline function addEdge(u:Int, v:Int) {
            graph.set(u, v);
        }
        inline function addSeg(x1:Int, y1:Int, x2:Int, y2:Int) {
            addEdge(ptu(x1, y1), ptu(x2, y2));
        }
        inline function addSegs(cx:Int, cy:Int, mask:Int, check:Int) {
            if((check & 1) > 0 && (mask & 1) == 0) addSeg(cx, cy, cx + TS, cy);
            if((check & 2) > 0 && (mask & 2) == 0) addSeg(cx + TS, cy, cx + TS, cy + TS);
            if((check & 4) > 0 && (mask & 4) == 0) addSeg(cx + TS, cy + TS, cx, cy + TS);
            if((check & 8) > 0 && (mask & 8) == 0) addSeg(cx, cy + TS, cx, cy);
        }
        for(p in comp) {
            var cx = p.j * TS, cy = p.i * TS;
            var col = getCollisionShape(p.i, p.j);
            var mask = 0;
            for(d in 0...4) {
                var i = p.i + DY[d];
                var j = p.j + DX[d];
                if(!isInLevel(i, j) || !visited[i][j]) continue;
                mask += 1 << d;
            }
            if(col == Full) {
                addSegs(cx, cy, mask, 1 + 2 + 4 + 8);
            } else if(col == DiagDR) {
                addSeg(cx, cy + TS, cx + TS, cy);
                addSegs(cx, cy, mask, 2 + 4);
            } else if(col == DiagDL) {
                addSeg(cx, cy, cx + TS, cy + TS);
                addSegs(cx, cy, mask, 4 + 8);
            } else if(col == DiagUR) {
                addSeg(cx + TS, cy + TS, cx, cy);
                addSegs(cx, cy, mask, 1 + 2);
            } else if(col == DiagUL) {
                addSeg(cx + TS, cy, cx, cy + TS);
                addSegs(cx, cy, mask, 8 + 1);
            }
        }
        var start = graph.keys().next();
        var u = start;
        var ans = [];
        for(i in 0...1000) {
            if(!graph.exists(u)) {
                var sp = utp(start);
                trace("Error parsing tile component starting at " + sp.x + ", " + sp.y);
                trace(start);
                return [];
            }
            u = graph.get(u);
            var pos = utp(u);
            ans.push(new IPoint(pos.x, pos.y));
            if(u == start) {
                break;
            }
        }
        return ans;
    }

    public function pointCollision(pt:Point) {
        for(collider in colliders) {
            if(collider.contains(pt)) {
                return true;
            }
        }
        return false;
    }
    public function getSlope(x:Float, y:Float) {
        var minDist = Collision.INF_DIST_SQ, closestCollider = null, closestId = -1;
        for(collider in colliders) {
            for(i in 0...collider.points.length) {
                var p = collider.points[i];
                var curDist = Collision.pointPointDistSq(x, y, p.x, p.y);
                if(curDist < minDist) {
                    minDist = curDist;
                    closestCollider = collider;
                    closestId = i;
                }
            }
        }
        if(minDist == Collision.INF_DIST_SQ) {
            return new Point(0, 0);
        }
        var pi = closestId == 0 ? closestCollider.points.length - 1 : closestId - 1;
        var ni = closestId == closestCollider.points.length - 1 ? 0 : closestId + 1;
        var pt = closestCollider.points[closestId];
        var pDist = Util.fmax(Util.fabs(x - closestCollider.points[pi].x), Util.fabs(y - closestCollider.points[pi].y));
        var nDist = Util.fmax(Util.fabs(x - closestCollider.points[ni].x), Util.fabs(y - closestCollider.points[ni].y));
        var seg = null;
        if(pDist < nDist) {
            seg = new Point(pt.x - closestCollider.points[pi].x, pt.y - closestCollider.points[pi].y);
        } else {
            seg = new Point(closestCollider.points[ni].x - pt.x, closestCollider.points[ni].y - pt.y);
        }
        return seg;
    }
    public function rectCollision(x:Int, y:Int, w:Int, h:Int) {
        return pointCollision(new Point(x, y)) || pointCollision(new Point(x + w, y)) || pointCollision(new Point(x, y + h)) || pointCollision(new Point(x + w, y + h));
    }
    public function sweptRectCollisionHorizontal(x:Int, y:Int, w:Int, h:Int, dx:Int) {
        var res = {moveX: 0, moveY: 0};
        if(dx > 0) {
            for(i in 0...dx) {
                if(pointCollision(new Point(x + w + 1, y))) {
                    var slope = getSlope(x + w + 1, y);
                    if(slope.x == slope.y || slope.y == 0) {
                        res.moveX++;
                        x++;
                        res.moveY++;
                        y++;
                    } else {
                        return res;
                    }
                } else if(pointCollision(new Point(x + w + 1, y + h))) {
                    var slope = getSlope(x + w + 1, y + h);
                    if(slope.x == -slope.y || slope.y == 0) {
                        res.moveX++;
                        x++;
                        res.moveY--;
                        y--;
                    } else {
                        return res;
                    }
                } else {
                    x++;
                    res.moveX++;
                }
            }
        } else if(dx < 0) {
            for(i in 0...-dx) {
                if(pointCollision(new Point(x - 1, y))) {
                    var slope = getSlope(x - 1, y);
                    if(slope.x == -slope.y || slope.y == 0) {
                        res.moveX--;
                        x--;
                        res.moveY++;
                        y++;
                    } else {
                        return res;
                    }
                } else if(pointCollision(new Point(x - 1, y + h))) {
                    var slope = getSlope(x - 1, y + h);
                    if(slope.x == slope.y || slope.y == 0) {
                        res.moveX--;
                        x--;
                        res.moveY--;
                        y--;
                    } else {
                        return res;
                    }
                } else {
                    x--;
                    res.moveX--;
                }
            }
        }
        return res;
    }
    public function sweptRectCollisionVertical(x:Int, y:Int, w:Int, h:Int, dy:Int) {
        var res = {moveX: 0, moveY: 0};
        if(dy > 0) {
            for(i in 0...dy) {
                if(pointCollision(new Point(x, y + h + 1)) || pointCollision(new Point(x + w, y + h + 1))) {
                    return res;
                } else {
                    y++;
                    res.moveY++;
                }
            }
        } else if(dy < 0) {
            for(i in 0...-dy) {
                if(pointCollision(new Point(x, y - 1))) {
                    var slope = getSlope(x, y - 1);
                    if(slope.x == -slope.y) {
                        res.moveX++;
                        x++;
                        res.moveY--;
                        y--;
                    } else {
                        return res;
                    }
                } else if(pointCollision(new Point(x + w, y - 1))) {
                    var slope = getSlope(x + w, y - 1);
                    if(slope.x == slope.y) {
                        res.moveX--;
                        x--;
                        res.moveY--;
                        y--;
                    } else {
                        return res;
                    }
                } else {
                    y--;
                    res.moveY--;
                }
                /*if(pointCollision(new Point(x, y - 1)) || pointCollision(new Point(x + w, y - 1))) {
                    return res;
                } else {
                    y--;
                    res.moveY--;
                }*/
            }
        }
        return res;
    }

    function loadTileCollisions() {
        tileCollisions = new Vector<CollisionShape>(1024);
        for(i in 0...tileCollisions.length) {
            tileCollisions[i] = Empty;
        }
        tileCollisions[1] = Full;
        tileCollisions[2] = DiagDR;
        tileCollisions[3] = DiagDL;
        tileCollisions[4] = DiagUR;
        tileCollisions[5] = DiagUL;
    }
}