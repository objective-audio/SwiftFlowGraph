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
        
        let builder = FlowGraphBuilder<WaitingState, RunningState, Event>()
        
        builder.add(waiting: .begin) { event in
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
        
        builder.add(waiting: .zero) { event in
            switch event {
            case .bang:
                return .wait(.begin)
            default:
                return .stay
            }
        }
        
        builder.add(running: .nonZero) { event in
            return .wait(.begin)
        }
        
        for state in WaitingState.cases {
            XCTAssertTrue(builder.contains(state: .waiting(state)))
        }
        
        for state in RunningState.cases {
            XCTAssertTrue(builder.contains(state: .running(state)))
        }
        
        let graph = builder.build(initial: .begin)
        
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
        
        let builder = FlowGraphBuilder<WaitingState, RunningState, Int>()
        
        builder.add(waiting: .first) { _ in .stay }
        builder.add(running: .second) { _ in .wait(.first) }
        
        XCTAssertTrue(builder.contains(state: .waiting(.first)))
        XCTAssertFalse(builder.contains(state: .waiting(.second)))
        XCTAssertFalse(builder.contains(state: .running(.first)))
        XCTAssertTrue(builder.contains(state: .running(.second)))
    }
    
    func testRunner() {
        enum WaitingState {
            case some
        }
        
        enum RunningState {
            case some
        }
        
        let builder = FlowGraphBuilder<WaitingState, RunningState, Int>()
        
        var received: Int?
        
        builder.add(waiting: .some) { event in
            received = event
            return .stay
        }
        
        let graph: FlowGraphRunner<Int> = builder.build(initial: .some)
        
        graph.run(1)
        
        XCTAssertEqual(received, 1)
    }
    
    static var allTests = [
        ("testFlow", testFlow),
        ("testContains", testContains),
    ]
}
