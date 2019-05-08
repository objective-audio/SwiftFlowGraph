import XCTest
@testable import FlowGraph

final class FlowGraphTests: XCTestCase {
    func testFlow() {
        struct TestType: FlowGraphType {
            enum WaitingState: CaseIterable {
                case begin
                case zero
            }
            
            enum RunningState: CaseIterable {
                case nonZero
            }
            
            enum Event {
                case none
                case value(Int)
                case bang
            }
        }
        
        let builder = FlowGraphBuilder<TestType>()
        
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
        
        XCTAssertTrue(TestType.WaitingState.allCases.allSatisfy { builder.contains(state: .waiting($0)) })
        XCTAssertTrue(TestType.RunningState.allCases.allSatisfy { builder.contains(state: .running($0)) })
        
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
        struct TestType: FlowGraphType {
            enum WaitingState {
                case first
                case second
            }
            
            enum RunningState {
                case first
                case second
            }
            
            typealias Event = Int
        }
        
        let builder = FlowGraphBuilder<TestType>()
        
        builder.add(waiting: .first) { _ in .stay }
        builder.add(running: .second) { _ in .wait(.first) }
        
        XCTAssertTrue(builder.contains(state: .waiting(.first)))
        XCTAssertFalse(builder.contains(state: .waiting(.second)))
        XCTAssertFalse(builder.contains(state: .running(.first)))
        XCTAssertTrue(builder.contains(state: .running(.second)))
    }
    
    func testSubFlow() {
        struct GraphType: FlowGraphType {
            enum WaitingState: CaseIterable {
                case disabled
                case enabled
            }
            
            enum RunningState: CaseIterable {
                case void
            }
            
            enum Event {
                case enable
                case disable
            }
        }
        
        struct SubFlow: Initializable {
            func canDisable() -> Bool {
                return true
            }
        }
        
        let builder = FlowGraphBuilder<GraphType>()
        
        builder.add(waiting: .disabled) { event in
            switch event {
            case .enable:
                return .wait(.enabled)
            case .disable:
                return .stay
            }
        }
        
        builder.add(waiting: .enabled, subFlowType: SubFlow.self) { (event, subFlow) in
            switch event {
            case .enable:
                return .stay
            case .disable:
                if subFlow.canDisable() {
                    return .wait(.disabled)
                } else {
                    return .stay
                }
            }
        }
        
        let mainGraph = builder.build(initial: .disabled)
        
        XCTAssertEqual(mainGraph.state, .waiting(.disabled))
        
        mainGraph.run(.enable)
        
        XCTAssertEqual(mainGraph.state, .waiting(.enabled))
        
        mainGraph.run(.disable)
        
        XCTAssertEqual(mainGraph.state, .waiting(.disabled))
    }
    
    static var allTests = [
        ("testFlow", testFlow),
        ("testContains", testContains),
    ]
}


