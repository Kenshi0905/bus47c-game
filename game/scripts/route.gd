extends RefCounted
## One shared route keeps the road, scenery and moving cabin aligned.
const ANCHORS := [Vector2(100,0),Vector2(0,0),Vector2(-30,0),Vector2(-65,8),Vector2(-100,14),Vector2(-133,14),Vector2(-165,7),Vector2(-200,-9),Vector2(-235,-16),Vector2(-273,-16),Vector2(-305,-5),Vector2(-345,12),Vector2(-380,19),Vector2(-410,19),Vector2(-440,9),Vector2(-480,-9),Vector2(-520,-15),Vector2(-550,-15),Vector2(-590,-6),Vector2(-630,8),Vector2(-660,8),Vector2(-680,8),Vector2(-710,8),Vector2(-820,0)]

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
