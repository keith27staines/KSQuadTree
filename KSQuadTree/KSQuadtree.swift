
import KSGeometry

// MARK:-
public enum KSQuadtreeError : Error {
    case itemNotWithinBounds
}

// MARK:-
/// Represents the quadrant that an item lies within
public enum KSQuadrantAssignment {
    case topLeft
    case topRight
    case bottomRight
    case bottomLeft
    /// Cannot be assigned to a quadrant (e.g. it is on a boundary) but is contained within the parent
    case useOwnBounds
    /// Not contained at all
    case none
}

public struct KSQuadTreeItem : Equatable, Hashable {
    
    public var position: Point
    public var object: AnyHashable?
    
    public init(point: Point, object: AnyHashable?) {
        self.position = point
        self.object = object
    }
    
    public static func ==(lhs: KSQuadTreeItem, rhs: KSQuadTreeItem) -> Bool {
        return lhs.position == rhs.position && lhs.object == rhs.object
    }
}

// MARK:-
public class KSQuadTree {
    /// The points directly contained within this instance (excludes points assigned to subtrees of this instance)
    public var items: [KSQuadTreeItem]
    /// The maximum number of items that the current instance can hold without splitting (assuming the maximum depth has not been reached)
    public let maxItems: Int
    /// The nesting depth for the current instance. If the max depth is reached, the subtree will not split
    public let depth: Int
    /// Returns the subtrees within the current instance
    public var subtreeDictionary: [KSQuadrantAssignment:KSQuadTree]? = nil
    /// The bounding rectangle for the current instance
    public let bounds: Rect
    /// The quadtree which is parent to this one
    public private (set) weak var parent: KSQuadTree?
    
    public convenience init(bounds: Rect, depth: Int = 30, maxItems: Int = 30, parent: KSQuadTree? = nil) {
        try! self.init(bounds: bounds, items: nil, depth: depth, maxItems: maxItems)
    }
    
    public init(bounds: Rect, items: [KSQuadTreeItem]?, depth: Int = 30, maxItems: Int = 30, parent: KSQuadTree? = nil) throws {
        self.bounds = bounds
        self.maxItems = maxItems
        self.depth = depth
        self.parent = parent
        self.items = [KSQuadTreeItem]()
        guard let items = items else {
            return
        }
        try insert(items: items)
    }
    /// Clears the current instance and all substrees
    public func clear() {
        items.removeAll()
        subtreeDictionary = nil
    }
    /// Returns the total number of elements contained within the current instance and its subtrees
    public func count() -> Int {
        let startCount = items.count
        guard let trees = subtreeDictionary?.values else {
            return startCount
        }
        return trees.reduce(startCount) { (n, tree) -> Int in
            return n + tree.count()
        }
    }
    /// Inserts points into the subtree
    public func insert(items: [KSQuadTreeItem]) throws {
        try items.forEach() { (item) in
            try insert(item: item)
        }
    }
    /// Retrieve all items in the tree that lie within the specified rect
    public func retrieveWithinRect(_ rect: Rect) -> [KSQuadTreeItem] {
        guard rect.intersects(bounds) else {
            return [KSQuadTreeItem]()
        }
        let items = retrieveAll()
        let itemsInside = items.filter { (item) -> Bool in
            return rect.contains(item.position)
        }
        return itemsInside
    }
    /// Retrieve all items contained within the subtree
    public func retrieveAll() -> [KSQuadTreeItem] {
        var items = self.items
        if let subtrees = subtreeDictionary {
            for tree in subtrees {
                items += tree.value.retrieveAll()
            }
        }
        return items
    }
    /// Inserts a new point into the subtree
    public func insert(item: KSQuadTreeItem) throws {
        let quadrant = self.quadrant(for: item)
        switch quadrant {
        case .none:
            // The item lies
            throw KSQuadtreeError.itemNotWithinBounds
        case .useOwnBounds:
            // The item is lying on the mid-lines of the the current instance so must be assigned to the current instance's own array of items because it cannot be uniquely assigned to a quadrant
            items.append(item)
        default:
            // The item does lie in a well defined quadrant
            guard depth > 0 else {
                // The current instance is at the maximum depth allowed, so no more splitting is allowed. Therefore inserts must be added to the current instance's own array of items
                items.append(item)
                return
            }
            guard let subtrees = subtreeDictionary else {
                // Split this subtree into 4 subtrees and reassign items to the subtrees where possible
                items.append(item)
                if items.count > maxItems {
                    split()
                }
                return
            }
            // assign the new item to the appropriate quadrant
            let subtree = subtrees[quadrant]!
            try subtree.insert(item: item)
        }
    }
    
    /// Splits the current instance by creating 4 subtrees and moving as many of its items to the subtrees as possible
    private func split() {
        // `remainingItems` will hold all the items that cannot be assigned to subtrees
        var remainingItems = [KSQuadTreeItem]()
        let subtreeDictionary = createSubtreeDictionary()
        for item in items {
            let quadrant = self.quadrant(for: item)
            if let subtree = subtreeDictionary[quadrant] {
                // There is an appropriate subtree to home this item
                try! subtree.insert(item: item)
            } else {
                // We can't put this item in a subtree so we keep it ourselves
                remainingItems.append(item)
            }
        }
        // The items that couldn't be assigned to subtrees must be retained by us
        items = remainingItems
        self.subtreeDictionary = subtreeDictionary
    }
    
    /// Returns a dictionary containing new sub-quadtrees for the current instance
    func createSubtreeDictionary() -> [KSQuadrantAssignment : KSQuadTree] {
        let rects = bounds.quadrantRects()
        var subtrees = [KSQuadrantAssignment:KSQuadTree]()
        subtrees[.topLeft] = try! KSQuadTree(bounds: rects[.topLeft]!, items: nil, depth: depth - 1, maxItems: maxItems)
        subtrees[.topRight] = try! KSQuadTree(bounds: rects[.topRight]!, items: nil, depth: depth - 1, maxItems: maxItems)
        subtrees[.bottomLeft] = try! KSQuadTree(bounds: rects[.bottomLeft]!, items: nil, depth: depth - 1, maxItems: maxItems)
        subtrees[.bottomRight] = try! KSQuadTree(bounds: rects[.bottomRight]!, items: nil, depth: depth - 1, maxItems: maxItems)
        subtrees.values.forEach { (subtree) in subtree.parent = self }
        return subtrees
    }
    
    /// Returns the quadrant in which the item lies
    public func quadrant(for item: KSQuadTreeItem) -> KSQuadrantAssignment {
        let point = item.position
        if !bounds.contains(point){
            return .none // point is outside our bounds or on our boundary which counts as outside
        }
        if point.x == bounds.midX || point.y == bounds.midY {
            return .useOwnBounds // point is on one of our midlines and therefore cannot be assigned to a quadrant
        }
        if point.x < bounds.midX {
            // point lies within the top-left or bottom-left quadrant
            return point.y < bounds.midY ? .bottomLeft : .topLeft
        }
        // point lies within the top-right or bottom-right quadrant
        return point.y < bounds.midY ? .bottomRight : .topRight
    }
    
    /// Returns the smallest subtree with bounds containing the location of the specified elements
    public func smallestSubtreeToContain(elements: [KSQuadTreeItem]) -> KSQuadTree? {
        guard let first = elements.first else {
            return nil
        }
        guard var smallest = smallestSubtreeToContain(element: first) else {
            return nil
        }

        while !smallest.couldContain(elements: elements) {
            guard let parent = smallest.parent else {
                return nil
            }
            smallest = parent
        }
        return smallest
    }
    
    /// Returns the smallest subtree with bounds containing the location of the specified element
    public func smallestSubtreeToContain(element: KSQuadTreeItem) -> KSQuadTree? {
        let quadrant = self.quadrant(for: element)
        switch quadrant {
        case .useOwnBounds:
            return self
        case .none:
            return nil
        default:
            if let subtreeDictionary = self.subtreeDictionary {
                let subtree = subtreeDictionary[quadrant]
                return subtree?.smallestSubtreeToContain(element: element) ?? self
            } else {
                return self
            }
        }
    }
    
    /// Tests whether the current instance or any of its subtrees could contain the location of the specified element (i.e, its position lies within the current instance's bounds
    public func couldContain(elements: [KSQuadTreeItem]) -> Bool {
        guard !elements.isEmpty else { return false }
        for element in elements {
            if quadrant(for: element) == .none {
                return false
            }
        }
        return true
    }
}




















