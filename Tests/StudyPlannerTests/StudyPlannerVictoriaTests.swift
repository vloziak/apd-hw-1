import XCTest
@testable import StudyPlanner

final class StudyPlannerVictoriaTests: XCTestCase {
    private func makeItem(
        _ id: String,
        title: String = "Task",
        minutes: Int = 10,
        category: StudyCategory = .reading
    ) throws -> StudyItem {
        try StudyItem(id: id, title: title, estimatedMinutes: minutes, category: category)
    }
    
    // testing task 1 Validation and errors
    func testZeroMinutesIsRejected() {
        XCTAssertThrowsError(try makeItem("z", minutes: 0)) { error in
            XCTAssertEqual(error as? StudyPlanError, .nonPositiveEstimatedMinutes)
        }
    }
    
    func testTitleErrorTakesPrecedenceOverMinutes() {
        XCTAssertThrowsError(try makeItem("x", title: " \t\n ", minutes: -5)) { error in
            XCTAssertEqual(error as? StudyPlanError, .blankTitle)
        }
    }
    
    func testTitleWithSurroundingSpacesIsKeptAsIs() throws {
        let item = try makeItem("s", title: "  Swift  ", minutes: 1)
        
        XCTAssertEqual(item.title, "  Swift  ")
        XCTAssertEqual(item.estimatedMinutes, 1)
    }
    
    // testing task 2 Codable boundaries
    func testDecodingItemWithBlankTitleFails() {
        let json = #"{"id": "a", "title": "   ", "estimatedMinutes": 5, "category": "reading"}"#
        
        XCTAssertThrowsError(try JSONDecoder().decode(StudyItem.self, from: Data(json.utf8))) { error in
            XCTAssertEqual(error as? StudyPlanError, .blankTitle)
        }
    }
    
    func testDecodingKeyedPlanUsesItemsKey() throws {
        let json = #"{"items": [{"id": "a", "title": "Read", "estimatedMinutes": 5, "category": "reading"}]}"#
        
        let plan = try JSONDecoder().decode(StudyPlan.self, from: Data(json.utf8))
        
        XCTAssertEqual(plan.items.count, 1)
        XCTAssertEqual(plan.items[0].id, "a")
        XCTAssertFalse(plan.items[0].isCompleted)
    }
    
    func testDecodingFixtureArray() throws {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: "study-items", withExtension: "json", subdirectory: "Fixtures")
        )
        let data = try Data(contentsOf: url)
        
        let plan = try StudyPlan.decode(from: data)
        
        XCTAssertEqual(plan.items.map(\.id), ["planner-milestone", "collections-drill", "swift-chapter-1"])
        XCTAssertEqual(plan.incompleteMinutes(), 135)
    }
    
    // testing task 3 Duplicates and ordering
    func testFirstDuplicateIDIsReported() throws {
        let items = [try makeItem("a"), try makeItem("b"), try makeItem("b"), try makeItem("a")]
        
        XCTAssertThrowsError(try StudyPlan(items: items)) { error in
            XCTAssertEqual(error as? StudyPlanError, .duplicateID("b"))
        }
    }
    
    func testItemsAreSortedByTitleThenID() throws {
        let plan = try StudyPlan(items: [
            try makeItem("c", title: "Beta"),
            try makeItem("b", title: "Alpha"),
            try makeItem("a", title: "Beta")
        ])
        
        XCTAssertEqual(plan.items.map(\.id), ["b", "a", "c"])
    }
    
    // testing task 4 Queries and completion
    func testItemsInCategoryReturnsOnlyThatCategory() throws {
        let plan = try StudyPlan(items: [
            try makeItem("r", category: .reading),
            try makeItem("p", category: .practice),
            try makeItem("j", category: .project)
        ])
        
        XCTAssertEqual(plan.items(in: .practice).map(\.id), ["p"])
    }
    
    func testIncompleteMinutesIsZeroForEmptyPlan() throws {
        let plan = try StudyPlan(items: [])
        
        XCTAssertEqual(plan.incompleteMinutes(), 0)
    }
    
    func testMarkCompletedWithUnknownIDThrowsAndKeepsPlan() throws {
        var plan = try StudyPlan(items: [try makeItem("a")])
        let before = plan
        
        XCTAssertThrowsError(try plan.markCompleted(id: "missing")) { error in
            XCTAssertEqual(error as? StudyPlanError, .unknownID("missing"))
        }
        XCTAssertEqual(plan, before)
    }
    
    func testMarkCompletedIsIdempotent() throws {
        var plan = try StudyPlan(items: [try makeItem("a", minutes: 10), try makeItem("b", minutes: 20)])
        
        try plan.markCompleted(id: "a")
        let afterFirst = plan
        try plan.markCompleted(id: "a")
        
        XCTAssertEqual(plan, afterFirst)
        XCTAssertEqual(plan.incompleteMinutes(), 20)
    }
    
    // testing bonus task
    func testImportReplacesExistingInPlaceAndAppendsNewSortedByID() throws {
        var plan = try StudyPlan(items: [
            try makeItem("b", title: "Alpha"),
            try makeItem("a", title: "Beta")
        ])
        
        try plan.importMerging([
            try makeItem("z", title: "New Z"),
            try makeItem("a", title: "Beta v2", minutes: 99),
            try makeItem("c", title: "New C")
        ])
        
        XCTAssertEqual(plan.items.map(\.id), ["b", "a", "c", "z"])
        XCTAssertEqual(plan.items[1].title, "Beta v2")
        XCTAssertEqual(plan.items[1].estimatedMinutes, 99)
    }
    
    func testImportWithDuplicateIncomingIDsThrowsAndKeepsPlan() throws {
        var plan = try StudyPlan(items: [try makeItem("a", title: "Original")])
        let before = plan
        
        XCTAssertThrowsError(try plan.importMerging([
            try makeItem("n", title: "New"),
            try makeItem("a", title: "Changed"),
            try makeItem("n", title: "New again")
        ])) { error in
            XCTAssertEqual(error as? StudyPlanError, .duplicateID("n"))
        }
        XCTAssertEqual(plan, before)
    }
    
    func testImportOfEmptyListChangesNothing() throws {
        var plan = try StudyPlan(items: [try makeItem("a"), try makeItem("b")])
        let before = plan
        
        try plan.importMerging([])
        
        XCTAssertEqual(plan, before)
    }
}

