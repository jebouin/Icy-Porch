package ;

import h2d.col.Polygon;
import h2d.col.IPolygon;
import h2d.col.IPoint;
import h2d.col.Point;
import haxe.ds.IntMap;
import haxe.ds.Vector;
import h2d.col.IBounds;
import assets.LevelProject;
import h2d.TileGroup;
import entities.*;
import Lava;

enum CollisionShape {
    Empty;
    Full;
    DiagDR;
    DiagDL;
    DiagUR;
    DiagUL;
}

class LevelRender {
    var decoFront : TileGroup;
    var walls : TileGroup;
    var decoBack : TileGroup;
    var back : TileGroup;
    
    public function new(level:LevelProject_Level) {
        decoFront = level.l_DecoFront.render();
        Game.inst.world.add(decoFront, Game.LAYER_DECO_FRONT);
        walls = level.l_Walls.render();
        Game.inst.world.add(walls, Game.LAYER_WALLS);
        decoBack = level.l_DecoBack.render();
        Game.inst.world.add(decoBack, Game.LAYER_DECO_BACK);
        back = level.l_Back.render();
        Game.inst.world.add(back, Game.LAYER_BACK_WALLS);
        walls.x = back.x = decoFront.x = decoBack.x = Level.WORLD_X;
        walls.y = back.y = decoFront.y = decoBack.y = Level.WORLD_Y;
    }

    public function delete() {
        walls.remove();
        back.remove();
        decoBack.remove();
        decoFront.remove();
    }
}

class Level {
    static var DX = [0, 1, 0, -1];
    static var DY = [-1, 0, 1, 0];
    public static inline var TS = 16;
    public static inline var HTS = 8;
    public static inline var WORLD_X = -TS;
    public static inline var WORLD_Y = -TS;
    public static inline var TILE_ICE = 1;
    public static inline var TILE_ICE_DR = 2;
    public static inline var TILE_ICE_DL = 3;
    public static inline var TILE_ICE_UR = 4;
    public static inline var TILE_ICE_UL = 5;
    public static inline var TILE_PORCH_STAIRS = 6;
    public static inline var TILE_PORCH_FLAT = 7;
    public static inline var TILE_TRAP_LAVA = 1;
    public static inline var TILE_PORCH_DECO_FRONT = 355;
    public static inline var LAVA_OFF_Y = 8;
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
    public var colliders : Array<IPolygon> = [];
    public var lava : Lava;
    public var porchFrontX : Float;
    public var porchFrontY : Float;

    public function new() {
        project = new LevelProject();
        loadTileCollisions();
        lava = new Lava();
    }

    public function delete() {
        lava.deleteLakes();
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
        lava.deleteLakes();
        level = newLevel;
        width = Std.int(level.pxWid / TS);
        height = Std.int(level.pxHei / TS);
        if(render != null) {
            render.delete();
        }
        render = new LevelRender(level);
        loadColliders();
        loadEntities();
        #if debug
        for(col in colliders) {
            trace(col);
        }
        #end
        loadLava();
        title = level.f_Title;
        for(i in 0...height) {
            for(j in 0...width) {
                if(!level.l_DecoFront.hasAnyTileAt(j, i)) continue;
                var tile = level.l_DecoFront.getTileStackAt(j, i)[0].tileId;
                if(tile == TILE_PORCH_DECO_FRONT) {
                    porchFrontX = j * TS + WORLD_X;
                    porchFrontY = i * TS + WORLD_Y;
                }
            }
        }
    }

    public function loadEntities() {
        for(t in level.l_Entities.all_Truck) {
            var x = t.pixelX + WORLD_X;
            var y = t.pixelY + WORLD_Y;
            new Truck(x, y, t.f_BoxCount, t.f_SpawnTimeTiles);
            Game.inst.spawnX = x + t.width - 32;
            Game.inst.spawnY = y + t.height - 10 - 9;
        }
        for(r in level.l_Entities.all_Rock) {
            new Rock(r.pixelX + WORLD_X, r.pixelY + WORLD_Y, r.width, r.height);
        }
        for(s in level.l_Entities.all_Sheet) {
            new Sheet(s.pixelX + WORLD_X, s.pixelY + WORLD_Y, s.width, s.height);
        }
        for(m in level.l_Entities.all_Magnet) {
            new Magnet(m.pixelX + WORLD_X, m.pixelY + WORLD_Y, m.f_isOn);
        }
    }

    public function loadLava() {
        for(i in 0...height) {
            var expand = false;
            var x1 = -1, x2 = -1;
            for(j in 0...width) {
                var x = j * TS + WORLD_X;
                var y = i * TS + LAVA_OFF_Y + WORLD_Y;
                var t = getTrapTile(i, j);
                var tu = getTrapTile(i - 1, j);
                if(t != TILE_TRAP_LAVA || tu == TILE_TRAP_LAVA) {
                    if(expand) {
                        new LavaLake(y, x1, x2);
                        expand = false;
                    }
                    continue;
                }
                if(!expand) {
                    expand = true;
                    x1 = x;
                    x2 = x1 + TS - 1;
                } else {
                    x2 = x + TS - 1;
                }
            }
        }
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

    public function update(dt:Float) {
        lava.update(dt);
    }

    inline function isInLevel(i:Int, j:Int) {
        return i >= 0 && j >= 0 && i < height && j < width;
    }
    inline function getTrapTile(i:Int, j:Int) {
        return level.l_Traps.getInt(j, i);
    }
    inline function getTile(i:Int, j:Int) {
        return level.l_Walls.getInt(j, i);
    }
    public function isPosInLava(x:Float, y:Float, ?ignoreSurface:Bool=false) {
        var i = Std.int((y - WORLD_Y) / TS);
        var j = Std.int((x - WORLD_X) / TS);
        if(!isInLevel(i, j)) return false;
        var tile = getTrapTile(i, j);
        if(tile != TILE_TRAP_LAVA) return false;
        var tileUp = i == 0 ? 0 : getTrapTile(i - 1, j);
        return ignoreSurface || tileUp == TILE_TRAP_LAVA || y - WORLD_Y - i * TS > LAVA_OFF_Y;
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
            ans.push(new IPoint(WORLD_X + pos.x, WORLD_Y + pos.y));
            if(u == start) {
                break;
            }
        }
        return simplifyPolygon(ans);
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
        var minDistSq = Collision.INF_DIST_SQ, closestCollider = null;
        var seg = new Point(0, 0);
        for(collider in colliders) {
            for(i in 0...collider.points.length) {
				var pt = collider.points[i];
				var ni = i == collider.points.length - 1 ? 0 : i + 1;
                var npt = collider.points[ni];
                var curDistSq = Collision.segmentPointDistSq(pt.x, pt.y, npt.x, npt.y, x, y);
                if(curDistSq < minDistSq) {
                    minDistSq = curDistSq;
                    closestCollider = collider;
                    seg = new Point(npt.x - pt.x, npt.y - pt.y);
                }
            }
        }
        return seg;
    }
    public function rectCollision(x:Int, y:Int, w:Int, h:Int) {
        return pointCollision(new Point(x, y)) || pointCollision(new Point(x + w, y)) || pointCollision(new Point(x, y + h)) || pointCollision(new Point(x + w, y + h));
    }
    function boxCollision(x:Float, y:Float, boxId:Int) {
        var all = Game.inst.boxes;
        if(boxId == all.length - 1) return null;
        for(i in boxId + 1...all.length) {
            var other = all[i];
            if(other.deleted || other.dead) continue;
            var ox1 = other.x + other.hitbox.xMin;
            var oy1 = other.y + other.hitbox.yMin;
            var ox2 = ox1 + other.hitbox.width;
            var oy2 = oy1 + other.hitbox.height;
            if(x < ox1 || x > ox2 || y < oy1 || y > oy2) continue;
            return other;
        }
        return null;
    }
    public function sweptRectCollisionHorizontal(x:Int, y:Int, w:Int, h:Int, dx:Int, boxId:Int) {
        var res = {moveX: 0, moveY: 0, collidedBox: null};
        if(dx > 0) {
            for(i in 0...dx) {
                var box = boxCollision(x + w + 1 - Collision.EPS, y + Collision.EPS, boxId);
                if(box == null) {
                    box = boxCollision(x + w + 1 - Collision.EPS, y + h - Collision.EPS, boxId);
                }
                if(box != null) {
                    res.collidedBox = box;
                    return res;
                }
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
                var box = boxCollision(x - 1 + Collision.EPS, y + Collision.EPS, boxId);
                if(box == null) {
                    box = boxCollision(x - 1 + Collision.EPS, y + h - Collision.EPS, boxId);
                }
                if(box != null) {
                    res.collidedBox = box;
                    return res;
                }
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

    function simplifyPolygon(points:Array<IPoint>) {
        if(points.length < 3) return points;
        var newPoints = [];
        for(i in 0...points.length) {
            var p = points[i];
            if(i >= 2) {
                var prev2 = newPoints[newPoints.length - 2], prev = newPoints[newPoints.length - 1];
                if(newPoints.length >= 2 && Collision.isColinear(prev2.x, prev2.y, prev.x, prev.y, p.x, p.y)) {
                    newPoints.pop();
                }
            }
            newPoints.push(p);
        }
        if(newPoints.length >= 3) {
            var last = newPoints[newPoints.length - 1], first = newPoints[0], second = newPoints[1];
            if(Collision.isColinear(last.x, last.y, first.x, first.y, second.x, second.y)) {
                newPoints.remove(first);
            }
        }
        if(newPoints.length >= 3) {
            var last2 = newPoints[newPoints.length - 2], last = newPoints[newPoints.length - 1], first = newPoints[0];
            if(Collision.isColinear(last2.x, last2.y, last.x, last.y, first.x, first.y)) {
                newPoints.remove(last);
            }
        }
        return newPoints;
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
        tileCollisions[6] = DiagDR;
        tileCollisions[7] = Full;
    }
}