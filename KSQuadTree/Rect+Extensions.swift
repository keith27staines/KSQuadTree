
import KSGeometry

extension Rect {
    func quadrantRects() -> [KSQuadrantAssignment: Rect] {
        let halfWidth = size.width/2.0
        let halfHeight = size.height/2.0
        let halfSize = Size(width: halfWidth, height: halfHeight)
        var rects = [KSQuadrantAssignment: Rect]()
        rects[.bottomLeft] = Rect(origin: origin, size: halfSize)
        rects[.topRight] = Rect(origin: center, size: halfSize)
        rects[.topLeft] = Rect(origin: midYPoint, size: halfSize)
        rects[.bottomRight] = Rect(origin: midXPoint, size: halfSize)        
        return rects
    }
}
