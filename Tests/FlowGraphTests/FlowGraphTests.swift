import XCTest
@testable import FlowGraph

final class FlowGraphTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(FlowGraph().text, "Hello, World!")
    }


    static var allTests = [
        ("testExample", testExample),
    ]
}
