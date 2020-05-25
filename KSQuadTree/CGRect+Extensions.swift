
import UIKit

extension CGRect {
    func quadrantRects() -> [F4SQuadtreeQuadrant: CGRect] {
        var rects = [F4SQuadtreeQuadrant: CGRect]()
        rects[.topLeft] = CGRect(x: origin.x, y: origin.y, width: width/2, height: height/2)
        rects[.topRight] = CGRect(x: origin.x + width/2, y: origin.y, width: width/2, height: height/2)
        rects[.bottomLeft] = CGRect(x: origin.x, y: origin.y+height/2, width: width/2, height: height/2)
        rects[.bottomRight] = CGRect(x: origin.x + width/2, y: origin.y + height/2, width: width/2, height: height/2)
        return rects
    }
    
    func isPointInsideBounds(_ point: CGPoint) -> Bool {
        return point.x > minX && point.x < maxX && point.y > minY && point.y < maxY
    }
}
