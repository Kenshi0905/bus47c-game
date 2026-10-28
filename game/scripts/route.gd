extends RefCounted
## One shared route keeps the road, scenery and moving cabin aligned.
const TERMINUS_Z := -900.0
const FINAL_RIDE_SECONDS := 36.0
# World-space landmarks shared by props, triggers and vegetation clearings.
const FOREST_FORK := Vector3(28,0,-694)
const WALK_PATH := [FOREST_FORK,Vector3(48,0,-714),Vector3(78,0,-733),Vector3(103,0,-723),Vector3(120,0,-717),Vector3(120,0,-739)]
const FRUIT_SITES := [Vector3(20,0,-674),Vector3(28,0,-683),Vector3(18,0,-701)]
const ANCHORS := [Vector2(100,0),Vector2(0,0),Vector2(-30,0),Vector2(-65,8),Vector2(-100,14),Vector2(-133,14),Vector2(-165,7),Vector2(-200,-9),Vector2(-235,-16),Vector2(-273,-16),Vector2(-305,-5),Vector2(-345,12),Vector2(-380,19),Vector2(-410,19),Vector2(-440,9),Vector2(-480,-9),Vector2(-520,-15),Vector2(-550,-15),Vector2(-590,-6),Vector2(-630,8),Vector2(-660,8),Vector2(-680,8),Vector2(-710,8),Vector2(-750,-14),Vector2(-790,-22),Vector2(-830,-4),Vector2(-870,12),Vector2(-900,12),Vector2(-930,12),Vector2(-1050,0)]

static func center_x(z: float) -> float:
	for i in range(ANCHORS.size()-1):
		var a: Vector2=ANCHORS[i]
		var b: Vector2=ANCHORS[i+1]
		if z<=a.x and z>=b.x:
			var t := clampf((z-a.x)/(b.x-a.x),0,1)
			return lerpf(a.y,b.y,t*t*(3-2*t))
	return 0

static func heading(z: float) -> float:
	return atan((center_x(z+.3)-center_x(z-.3))/.6)

static func frame(z: float) -> Transform3D:
	return Transform3D(Basis(Vector3.UP,heading(z)),Vector3(center_x(z),0,z))

static func point(x: float, y: float, z: float) -> Vector3:
	return frame(z)*Vector3(x,y,0)
