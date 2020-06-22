//
//  F4SQuadtreeTests.swift
//  F4SDataStructuresTests
//
//  Created by Keith Dev on 27/09/2017.
//  Copyright © 2017 F4S. All rights reserved.
//

import XCTest
import KSQuadTree

class KSQuadTreeTestCase: XCTestCase {
    
    func test_initalise() {
        let rect = CGRect(x: 10, y: 10, width: 10, height: 10)
        let sut = F4SQuadTree(bounds: rect, depth: 5, maxItems: 2, parent: nil)
        XCTAssertEqual(sut.bounds, rect)
        XCTAssertEqual(sut.depth, 5)
        XCTAssertEqual(sut.maxItems, 2)
        XCTAssertNil(sut.parent)
    }
    
    func test_smallest() {
        let rect = CGRect(x: 10, y: 10, width: 10, height: 10)
        let sut = F4SQuadTree(bounds: rect, depth: 5, maxItems: 2, parent: nil)
        let item1 = F4SQuadTreeItem(point: CGPoint(x:11,y:11), object: "item1")
        let item2 = F4SQuadTreeItem(point: CGPoint(x:11,y:11), object: "item2")
        let item3 = F4SQuadTreeItem(point: CGPoint(x:11,y:11), object: "item3")
        try! sut.insert(item: item1)
        try! sut.insert(item: item2)
        var smallest = sut.smallestSubtreeToContain(elements: [item1,item2])
        XCTAssertEqual(smallest!.bounds, rect)
        try! sut.insert(item: item3)
        smallest = sut.smallestSubtreeToContain(elements: [item1,item2, item3])
        XCTAssertNotEqual(smallest!.bounds, rect)
    }
    
    func test_build_and_clear() {
        let rect = CGRect(x: 10, y: 10, width: 10, height: 10)
        let sut = F4SQuadTree(bounds: rect, depth: 5, maxItems: 2, parent: nil)
        let item1 = F4SQuadTreeItem(point: CGPoint(x:11,y:11), object: "item1")
        let item2 = F4SQuadTreeItem(point: CGPoint(x:11,y:11), object: "item2")
        let item3 = F4SQuadTreeItem(point: CGPoint(x:11,y:11), object: "item3")
        let item4 = F4SQuadTreeItem(point: CGPoint(x:11,y:11), object: "item4")
        try! sut.insert(item: item1)
        try! sut.insert(item: item2)
        // Add items up to the limit before this tree creates subtrees
        XCTAssertEqual(sut.items.count, 2)
        XCTAssertEqual(sut.count(), 2)
        XCTAssertNil(sut.subtreeDictionary)
        // Clear and ensure items and subtrees are empty
        sut.clear()
        XCTAssertEqual(sut.items.count,0)
        XCTAssertNil(sut.subtreeDictionary)
        // Add three items (one more than maxItems) to force subtrees to be created and items copied to them
        try! sut.insert(item: item1)
        try! sut.insert(item: item2)
        try! sut.insert(item: item3)
        XCTAssertEqual(sut.items.count, 0)
        XCTAssertEqual(sut.count(), 3)
        XCTAssertEqual(sut.subtreeDictionary!.count, 4)
        // Add one more item to ensure it goes into the existing subtrees and not the items collection
        try! sut.insert(item: item4)
        XCTAssertEqual(sut.items.count, 0)
        XCTAssertEqual(sut.count(), 4)
        XCTAssertEqual(sut.subtreeDictionary!.count, 4)
        // Clear and check both items and subtrees are empty
        sut.clear()
        XCTAssertEqual(sut.items.count,0)
        XCTAssertNil(sut.subtreeDictionary)
    }
    
    func testQuadrantForItemFarOutside() {
        let qt = KSQuadTreeTestCase.createEmptyTree()
        let exteriorPoint = CGPoint(x: -1, y: 0)
        let item = F4SQuadTreeItem(point: exteriorPoint, object: 1)
        let quadrant = qt.quadrant(for: item)
        XCTAssertEqual(quadrant, F4SQuadtreeQuadrant.none)
    }
    func testQuadrantForItemOnLeftBoundary() {
        let qt = KSQuadTreeTestCase.createEmptyTree()
        let boundaryPoint = CGPoint(x: 0, y: 0.5)
        let item = F4SQuadTreeItem(point: boundaryPoint, object: 1)
        let quadrant = qt.quadrant(for: item)
        XCTAssertEqual(quadrant, F4SQuadtreeQuadrant.none)
    }
    func testQuadrantForItemOnRightBoundary() {
        let qt = KSQuadTreeTestCase.createEmptyTree()
        let boundaryPoint = CGPoint(x: 2, y: 0.5)
        let item = F4SQuadTreeItem(point: boundaryPoint, object: 1)
        let quadrant = qt.quadrant(for: item)
        XCTAssertEqual(quadrant, F4SQuadtreeQuadrant.none)
    }
    func testQuadrantForItemOnTopBoundary() {
        let qt = KSQuadTreeTestCase.createEmptyTree()
        let boundaryPoint = CGPoint(x: 0.5, y: 0)
        let item = F4SQuadTreeItem(point: boundaryPoint, object: 1)
        let quadrant = qt.quadrant(for: item)
        XCTAssertEqual(quadrant, F4SQuadtreeQuadrant.none)
    }
    func testQuadrantForItemOnBottomBoundary() {
        let qt = KSQuadTreeTestCase.createEmptyTree()
        let boundaryPoint = CGPoint(x: 0.5, y: 2)
        let item = F4SQuadTreeItem(point: boundaryPoint, object: 1)
        let quadrant = qt.quadrant(for: item)
        XCTAssertEqual(quadrant, F4SQuadtreeQuadrant.none)
    }
    func testQuadrantForItemOnHorizontalMidline() {
        let qt = KSQuadTreeTestCase.createEmptyTree()
        let point = CGPoint(x: 0.5, y: 1)
        let item = F4SQuadTreeItem(point: point, object: 1)
        let quadrant = qt.quadrant(for: item)
        XCTAssertEqual(quadrant, F4SQuadtreeQuadrant.useOwnBounds)
    }
    func testQuadrantForItemOnVerticalMidline() {
        let qt = KSQuadTreeTestCase.createEmptyTree()
        let point = CGPoint(x: 1, y: 0.5)
        let item = F4SQuadTreeItem(point: point, object: 1)
        let quadrant = qt.quadrant(for: item)
        XCTAssertEqual(quadrant, F4SQuadtreeQuadrant.useOwnBounds)
    }
    func testQuadrantForItemInTopLeftQuadrant() {
        let qt = KSQuadTreeTestCase.createEmptyTree()
        let point = CGPoint(x: 0.5, y: 0.5)
        let item = F4SQuadTreeItem(point: point, object: 1)
        let quadrant = qt.quadrant(for: item)
        XCTAssertEqual(quadrant, F4SQuadtreeQuadrant.topLeft)
    }
    func testQuadrantForItemInTopRightQuadrant() {
        let qt = KSQuadTreeTestCase.createEmptyTree()
        let point = CGPoint(x: 1.5, y: 0.5)
        let item = F4SQuadTreeItem(point: point, object: 1)
        let quadrant = qt.quadrant(for: item)
        XCTAssertEqual(quadrant, F4SQuadtreeQuadrant.topRight)
    }
    func testQuadrantForItemInBottomLeftQuadrant() {
        let qt = KSQuadTreeTestCase.createEmptyTree()
        let point = CGPoint(x: 0.5, y: 1.5)
        let item = F4SQuadTreeItem(point: point, object: 1)
        let quadrant = qt.quadrant(for: item)
        XCTAssertEqual(quadrant, F4SQuadtreeQuadrant.bottomLeft)
    }
    func testQuadrantForItemInBottomRightQuadrant() {
        let qt = KSQuadTreeTestCase.createEmptyTree()
        let point = CGPoint(x: 1.5, y: 1.5)
        let item = F4SQuadTreeItem(point: point, object: 1)
        let quadrant = qt.quadrant(for: item)
        XCTAssertEqual(quadrant, F4SQuadtreeQuadrant.bottomRight)
    }
    func testInitQuadTreeSettingMaxItemsAndDepth() {
        let rect = CGRect(x: 0, y: 0, width: 2, height: 2)
        let qt = try! F4SQuadTree(bounds: rect, items: nil, depth: 27, maxItems: 72)
        XCTAssertEqual(qt.depth, 27)
        XCTAssertEqual(qt.maxItems, 72)
    }
    func testInitQuadTreeWithItemOutsideBoundsThrows() {
        let rect = CGRect(x: 0, y: 0, width: 2, height: 2)
        let exteriorPoint = CGPoint(x: -1, y: 0)
        let item = F4SQuadTreeItem(point: exteriorPoint, object: 1)
        XCTAssertThrowsError(try F4SQuadTree(bounds: rect, items: [item]))
    }
    func testInsertItemOutsideOfBoundsThrows() {
        let qt = KSQuadTreeTestCase.createEmptyTree()
        let exteriorPoint = CGPoint(x: -1, y: 0)
        let item = F4SQuadTreeItem(point: exteriorPoint, object: 1)
        XCTAssertThrowsError(try qt.insert(item: item))
    }
    func testInsertItemOnBoundaryThrows() {
        let qt = KSQuadTreeTestCase.createEmptyTree()
        let boundaryPoint = CGPoint(x: 0, y: 0)
        let item = F4SQuadTreeItem(point: boundaryPoint, object: 1)
        XCTAssertThrowsError(try qt.insert(item: item))
    }
    func testInsertItem() {
        let qt = KSQuadTreeTestCase.createEmptyTree()
        let point = CGPoint(x: 0.5, y: 0.5)
        let item = F4SQuadTreeItem(point: point, object: 1)
        try! qt.insert(item: item)
        XCTAssertNil(qt.subtreeDictionary)
        XCTAssertEqual(qt.items.count, 1)
        XCTAssertEqual(qt.items[0].position, point)
    }
    func testInsertMaximumItemsBeforeSplitting() {
        let qt = KSQuadTreeTestCase.createEmptyTree()
        let point = CGPoint(x: 0.5, y: 0.5)
        let item1 = F4SQuadTreeItem(point: point, object: 1)
        let item2 = F4SQuadTreeItem(point: point, object: 2)
        try! qt.insert(item: item1)
        try! qt.insert(item: item2)
        XCTAssertNil(qt.subtreeDictionary)
        XCTAssertEqual(qt.items.count, 2)
    }
    func testInsertOneMoreThanMaximumItemsDoesntCauseSplitIfAtDepth0() {
        let rect = CGRect(x: 0, y: 0, width: 2, height: 2)
        let qt = try! F4SQuadTree(bounds: rect, items: nil, depth: 0, maxItems: 2)
        KSQuadTreeTestCase.addOneMoreThanMaxItems(qt: qt)
        XCTAssertNil(qt.subtreeDictionary)
        XCTAssertEqual(qt.items.count, 3)
        XCTAssertGreaterThan(qt.items.count, qt.maxItems)
    }
    func testInsertOneMoreThanMaximumItemsCausingSplit() {
        let qt = KSQuadTreeTestCase.createSplitSubtree()
        XCTAssertNotNil(qt.subtreeDictionary)
        XCTAssertEqual(qt.items.count, 0)
        XCTAssertEqual(qt.subtreeDictionary![.topLeft]!.items.count,3)
        XCTAssertEqual(qt.subtreeDictionary![.topRight]!.items.count,0)
        XCTAssertEqual(qt.subtreeDictionary![.bottomLeft]!.items.count,0)
        XCTAssertEqual(qt.subtreeDictionary![.bottomLeft]!.items.count,0)
    }
    func testSubtreeDepth() {
        let qt = KSQuadTreeTestCase.createSplitSubtree()
        let topLevel = qt.depth
        let nextLevel = qt.subtreeDictionary![.topLeft]!.depth
        XCTAssertEqual(topLevel, nextLevel+1)
    }
    func testAddingItemToAlreadySplitTreeOnMidline() {
        let qt = KSQuadTreeTestCase.createSplitSubtree()
        let point = CGPoint(x: qt.bounds.midX, y: 0.5)
        let itemX = F4SQuadTreeItem(point: point, object: "X")
        try! qt.insert(item: itemX)
        XCTAssertTrue(qt.items.contains(where: { (item) -> Bool in
            guard let x = item.object as? String, x == "X" else {
                return false
            }
            return true
        }))
    }
    func testRetrieveFromEmptyTree() {
        let qt = KSQuadTreeTestCase.createEmptyTree()
        let items: [F4SQuadTreeItem] = qt.retrieveAll()
        XCTAssertTrue(items.count == 0)
    }
    func testRetrieveFromNonSplitTree() {
        let qt = KSQuadTreeTestCase.createEmptyTree()
        let point = CGPoint(x: 0.5, y: 0.5)
        let item = F4SQuadTreeItem(point: point, object: 1)
        try! qt.insert(item: item)
        let items: [F4SQuadTreeItem] = qt.retrieveAll()
        XCTAssertTrue(items.count == 1)
    }
    
    func testRetrieveWithExternalRect() {
        let qt = KSQuadTreeTestCase.createSplitSubtree()
        let externalRect = CGRect(x: -10, y: -10, width: 1, height: 1)
        XCTAssertTrue(qt.retrieveWithinRect(externalRect).count == 0)
    }
    func testRetrieveTopeLeftWithTopLeftQuadrantRectContainingAllItems() {
        let qt = KSQuadTreeTestCase.createSplitSubtree()
        let topLeft = CGRect(x: 0, y: 0, width: 1, height: 1)
        XCTAssertEqual(qt.retrieveWithinRect(topLeft).count, qt.retrieveAll().count)
    }
    func testRetrieveTopRightWithTopLeftQuadrantRectContainingAllItems() {
        let qt = KSQuadTreeTestCase.createSplitSubtree()
        let topRight = CGRect(x: 1, y: 0, width: 1, height: 1)
        XCTAssertEqual(qt.retrieveWithinRect(topRight).count, 0)
    }
    func testRetrieveTopLeftEmptyQuadrantWithTopLeftQuadrantRectContainingAllItems() {
        let qt = KSQuadTreeTestCase.createSplitSubtree()
        let topLeftEmpty = CGRect(x: 0, y: 0, width: 0.1, height: 0.1)
        XCTAssertEqual(qt.retrieveWithinRect(topLeftEmpty).count, 0)
    }
    func testRetrieveTopLeftPopulatedSubquadrantQuadrantWithTopLeftQuadrantRectContainingAllItems() {
        let qt = KSQuadTreeTestCase.createSplitSubtree()
        let topLeftPopulated = CGRect(x: 0.4, y: 0.4, width: 0.2, height: 0.2)
        XCTAssertEqual(qt.retrieveWithinRect(topLeftPopulated).count, qt.retrieveAll().count)
    }
    
    func test_equality_when_equal() {
        let point = CGPoint(x: 1, y: 2)
        let object = "hello"
        let item1 = F4SQuadTreeItem(point: point, object: object)
        let item2 = F4SQuadTreeItem(point: point, object: object)
        XCTAssertTrue(item1 == item2)
    }
    
    func test_equality_when_not_equal_points() {
        let point1 = CGPoint(x: 1, y: 2)
        let object = "hello"
        let point2 = CGPoint(x: 2, y: 1)
        let item1 = F4SQuadTreeItem(point: point1, object: object)
        let item2 = F4SQuadTreeItem(point: point2, object: object)
        XCTAssertFalse(item1 == item2)
    }
    
    func test_equality_when_not_equal_objects() {
        let point = CGPoint(x: 1, y: 2)
        let object1 = "hello"
        let object2 = "goodbye"
        let item1 = F4SQuadTreeItem(point: point, object: object1)
        let item2 = F4SQuadTreeItem(point: point, object: object2)
        XCTAssertFalse(item1 == item2)
    }
    
    func test_hashvalue_when_identical() {
        let point = CGPoint(x: 1, y: 2)
        let object = "hello"
        let item1 = F4SQuadTreeItem(point: point, object: object)
        let item2 = F4SQuadTreeItem(point: point, object: object)
        XCTAssertTrue(item1.hashValue == item2.hashValue)
    }
    
    func test_hashvalue_when_different_points() {
        let point1 = CGPoint(x: 1, y: 2)
        let point2 = CGPoint(x: 2, y: 2)
        let object = "hello"
        let item1 = F4SQuadTreeItem(point: point1, object: object)
        let item2 = F4SQuadTreeItem(point: point2, object: object)
        XCTAssertFalse(item1.hashValue == item2.hashValue)
    }
    
    func test_hashvalue_when_different_objects() {
        let point = CGPoint(x: 1, y: 2)
        let object1 = "hello"
        let object2 = "goodbye"
        let item1 = F4SQuadTreeItem(point: point, object: object1)
        let item2 = F4SQuadTreeItem(point: point, object: object2)
        XCTAssertFalse(item1.hashValue == item2.hashValue)
    }
    
}

// MARK: helpers
extension KSQuadTreeTestCase {
    /// Creates an empty tree with depth = 2, maxItems = 2, bounds = CGRect(0,0,2,2)
    static func createEmptyTree() -> F4SQuadTree {
        let rect = CGRect(x: 0, y: 0, width: 2, height: 2)
        let qt = try! F4SQuadTree(bounds: rect, items: nil, depth: 2, maxItems: 2)
        XCTAssertNil(qt.subtreeDictionary)
        return qt
    }
    
    /// Creates a quadtree with depth of 2, maxItems = 2 with sufficient items to create a split
    static func createSplitSubtree() -> F4SQuadTree {
        let qt = createEmptyTree()
        addOneMoreThanMaxItems(qt: qt)
        XCTAssertNotNil(qt.subtreeDictionary)
        return qt
    }
    
    /// Adds sufficient items to cause a split
    static func addOneMoreThanMaxItems(qt:F4SQuadTree) {
        let point = CGPoint(x: qt.bounds.width/4.0, y: qt.bounds.height/4.0)
        for i in 0...qt.maxItems {
            let item = F4SQuadTreeItem(point: point, object: i)
            try! qt.insert(item: item)
        }
    }
}








