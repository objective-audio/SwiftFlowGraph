import XCTest
@testable import FlowGraph

final class FlowGraphTests: XCTestCase {
    func testFlow() {
        enum WaitingState: EnumEnumerable {
            case begin
            case zero
        }
        
        enum RunningState: EnumEnumerable {
            case nonZero
        }
        
        enum Event {
            case none
            case value(Int)
            case bang
        }
        
        let graph = FlowGraph<WaitingState, RunningState, Event>()
        
        graph.add(waiting: .begin) { event in
            switch event {
            case .value(let value):
                if value == 0 {
                    return .wait(.zero)
                } else {
                    return .run(.nonZero, .none)
                }
            default:
                return .stay
            }
        }
        
        graph.add(waiting: .zero) { event in
            switch event {
            case .bang:
                return .wait(.begin)
            default:
                return .stay
            }
        }
        
        graph.add(running: .nonZero) { event in
            return .wait(.begin)
        }
        
        for state in WaitingState.cases {
            XCTAssertTrue(graph.contains(state: .waiting(state)))
        }
        
        for state in RunningState.cases {
            XCTAssertTrue(graph.contains(state: .running(state)))
        }
        
        graph.begin(with: .begin)
        
        XCTAssertEqual(graph.state, .waiting(.begin))
        
        graph.run(.value(0))
        
        XCTAssertEqual(graph.state, .waiting(.zero))
        
        graph.run(.value(0))
        
        XCTAssertEqual(graph.state, .waiting(.zero))
        
        graph.run(.bang)
        
        XCTAssertEqual(graph.state, .waiting(.begin))
        
        graph.run(.value(1))
        
        XCTAssertEqual(graph.state, .waiting(.begin))
    }
    
    func testContains() {
        enum WaitingState {
            case first
            case second
        }
        
        enum RunningState {
            case first
            case second
        }
        
        let graph = FlowGraph<WaitingState, RunningState, Int>()
        
        graph.add(waiting: .first) { _ in .stay }
        graph.add(running: .second) { _ in .wait(.first) }
        
        XCTAssertTrue(graph.contains(state: .waiting(.first)))
        XCTAssertFalse(graph.contains(state: .waiting(.second)))
        XCTAssertFalse(graph.contains(state: .running(.first)))
        XCTAssertTrue(graph.contains(state: .running(.second)))
    }
    
    static var allTests = [
        ("testFlow", testFlow),
        ("testContains", testContains),
    ]
}
