//
//  F4SQuadtreeProtocol.swift
//  F4SDataStructures
//
//  Created by Keith Dev on 26/09/2017.
//  Copyright © 2017 F4S. All rights reserved.
//

import Foundation
import UIKit

// MARK:-
public enum F4SPointQuadtreeError : Error {
    case itemNotWithinBounds
}

// MARK:-
/// Represents the quadrant that an item lies within
public enum F4SQuadtreeQuadrant {
    case topLeft
    case topRight
    case bottomRight
    case bottomLeft
    /// Cannot be assigned to a quadrant (e.g. it is on a boundary) but is contained within the parent
    case useOwnBounds
    /// Not contained at all
    case none
}

// MARK:-
//public protocol F4SQuadtreeElement {
//    var position: CGPoint { get }
//    var object: AnyHashable { get }
//}

public struct F4SQuadTreeItem : Equatable, Hashable {
    
    public var position: CGPoint
    public var object: AnyHashable
    
//    public init(latlon: LatLon, object: AnyHashable) {
//        let point = CGPoint(x: latlon.longitude, y: latlon.latitude)
//        self.init(point: point, object: object)
//    }
    
    public init(point: CGPoint, object: AnyHashable) {
        self.position = point
        self.object = object
    }
    
    public static func ==(lhs: F4SQuadTreeItem, rhs: F4SQuadTreeItem) -> Bool {
        return lhs.position == rhs.position && lhs.object == rhs.object
    }
}

extension CGPoint: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
        _ = hasher.finalize()
    }
}

// MARK:-
public class F4SQuadTree {
    /// The points directly contained within this instance (excludes points assigned to subtrees of this instance)
    public var items: [F4SQuadTreeItem]
    /// The maximum number of items that the current instance can hold without splitting (assuming the maximum depth has not been reached)
    public let maxItems: Int
    /// The nesting depth for the current instance. If the max depth is reached, the subtree will not split
    public let depth: Int
    /// Returns the subtrees within the current instance
    public var subtreeDictionary: [F4SQuadtreeQuadrant:F4SQuadTree]? = nil
    /// The bounding rectangle for the current instance
    public let bounds: CGRect
    /// The quadtree which is parent to this one
    public private (set) weak var parent: F4SQuadTree?
    
    public convenience init(bounds: CGRect, depth: Int = 30, maxItems: Int = 30, parent: F4SQuadTree? = nil) {
        try! self.init(bounds: bounds, items: nil, depth: depth, maxItems: maxItems)
    }
    
    public init(bounds: CGRect, items: [F4SQuadTreeItem]?, depth: Int = 30, maxItems: Int = 30, parent: F4SQuadTree? = nil) throws {
        precondition(bounds.size != CGSize.zero, "Bounds cannot be zero")
        self.bounds = bounds
        self.maxItems = maxItems
        self.depth = depth
        self.parent = parent
        self.items = [F4SQuadTreeItem]()
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
    public func insert(items: [F4SQuadTreeItem]) throws {
        try items.forEach() { (item) in
            try insert(item: item)
        }
    }
    /// Retrieve all items in the tree that lie within the specified rect
    public func retrieveWithinRect(_ rect: CGRect) -> [F4SQuadTreeItem] {
        guard rect.intersects(bounds) else {
            return [F4SQuadTreeItem]()
        }
        let items = retrieveAll()
        let itemsInside = items.filter { (item) -> Bool in
            return rect.contains(item.position)
        }
        return itemsInside
    }
    /// Retrieve all items contained within the subtree
    public func retrieveAll() -> [F4SQuadTreeItem] {
        var items = self.items
        if let subtrees = subtreeDictionary {
            for tree in subtrees {
                items += tree.value.retrieveAll()
            }
        }
        return items
    }
    /// Inserts a new point into the subtree
    public func insert(item: F4SQuadTreeItem) throws {
        let quadrant = self.quadrant(for: item)
        switch quadrant {
        case .none:
            // The item lies
            throw F4SPointQuadtreeError.itemNotWithinBounds
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
        var remainingItems = [F4SQuadTreeItem]()
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
    func createSubtreeDictionary() -> [F4SQuadtreeQuadrant : F4SQuadTree] {
        let rects = bounds.quadrantRects()
        var subtrees = [F4SQuadtreeQuadrant:F4SQuadTree]()
        subtrees[.topLeft] = try! F4SQuadTree(bounds: rects[.topLeft]!, items: nil, depth: depth - 1, maxItems: maxItems)
        subtrees[.topRight] = try! F4SQuadTree(bounds: rects[.topRight]!, items: nil, depth: depth - 1, maxItems: maxItems)
        subtrees[.bottomLeft] = try! F4SQuadTree(bounds: rects[.bottomLeft]!, items: nil, depth: depth - 1, maxItems: maxItems)
        subtrees[.bottomRight] = try! F4SQuadTree(bounds: rects[.bottomRight]!, items: nil, depth: depth - 1, maxItems: maxItems)
        return subtrees
    }
    
    /// Returns the quadrant in which the item lies
    public func quadrant(for item: F4SQuadTreeItem) -> F4SQuadtreeQuadrant {
        let point = item.position
        if !bounds.isPointInsideBounds(point){
            return .none // point is outside our bounds or on our boundary which counts as outside
        }
        if point.x == bounds.midX || point.y == bounds.midY {
            return .useOwnBounds // point is on one of our midlines and therefore cannot be assigned to a quadrant
        }
        if point.x < bounds.midX {
            // point lies within the top-left or bottom-left quadrant
            return point.y < bounds.midY ? .topLeft : .bottomLeft
        } else {
            // point lies within the top-right or bottom-right quadrant
            return point.y < bounds.midY ? .topRight : .bottomRight
        }
    }
    /// Returns the smallest subtree with bounds containing the location of the specified elements
    public func smallestSubtreeToContain(elements: [F4SQuadTreeItem]) -> F4SQuadTree? {
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
    /// Tests whether the current instance or any of its subtrees could contain the location of the specified element (i.e, its position lies within the current instance's bounds
    public func couldContain(elements: [F4SQuadTreeItem]) -> Bool {
        guard !elements.isEmpty else { return false }
        for element in elements {
            if quadrant(for: element) == .none {
                return false
            }
        }
        return true
    }
    /// Returns the smallest subtree with bounds containing the location of the specified element
    public func smallestSubtreeToContain(element: F4SQuadTreeItem) -> F4SQuadTree? {
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
}




















