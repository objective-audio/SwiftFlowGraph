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
                case reset
            }
            
            enum Event {
                case enable
                case disable
                case reset
            }
        }
        
        // 2回以上incrementが呼ばれるとtrueを返す
        class SubFlow: Initializable {
            private var count: Int = 0
            
            required init() {
            }
            
            func increment() -> Bool {
                self.count += 1
                return self.count >= 2
            }
        }
        
        let builder = FlowGraphBuilder<GraphType>()
        
        builder.add(waiting: .disabled) { event in
            switch event {
            case .enable:
                return .wait(.enabled)
            case .disable, .reset:
                return .stay
            }
        }
        
        builder.add(waiting: .enabled, subFlowType: SubFlow.self) { (event, subFlow) in
            switch event {
            case .enable:
                return .stay
            case .disable:
                // SubFlowのcountが2以上だったら遷移する
                if subFlow.increment() {
                    return .wait(.disabled)
                } else {
                    return .stay
                }
            case .reset:
                return .run(.reset, event)
            }
        }
        
        builder.add(running: .reset) { event in
            return .wait(.enabled)
        }
        
        let mainGraph = builder.build(initial: .disabled)
        
        XCTAssertEqual(mainGraph.state, .waiting(.disabled))
        
        mainGraph.run(.enable)
        
        XCTAssertEqual(mainGraph.state, .waiting(.enabled))
        
        mainGraph.run(.disable)
        
        XCTAssertEqual(mainGraph.state, .waiting(.enabled))
        
        mainGraph.run(.reset)
        
        // runningステートを通ってSubFlowがリセットされた
        
        XCTAssertEqual(mainGraph.state, .waiting(.enabled))
        
        mainGraph.run(.disable)

        XCTAssertEqual(mainGraph.state, .waiting(.enabled))

        mainGraph.run(.disable)

        XCTAssertEqual(mainGraph.state, .waiting(.disabled))
        
        mainGraph.run(.enable)
        
        // 別のwaitingステートから遷移したのでSubFlowがリセットされた
        
        XCTAssertEqual(mainGraph.state, .waiting(.enabled))
        
        mainGraph.run(.disable)
        
        XCTAssertEqual(mainGraph.state, .waiting(.enabled))
        
        mainGraph.run(.disable)
        
        XCTAssertEqual(mainGraph.state, .waiting(.disabled))
    }
    
    func testManySubFlow() {
        struct GraphType: FlowGraphType {
            enum WaitingState: CaseIterable {
                case first
                case second
            }
            
            enum RunningState: CaseIterable {
                case none
            }
            
            enum Event {
                case bang
            }
        }
        
        class FirstSubFlow: Initializable {
            private var count: Int = 0
            
            required init() {}
            
            func increment() -> Bool {
                self.count += 1
                return self.count >= 2
            }
        }
        
        class SecondSubFlow: Initializable {
            private var count: Int = 0
            
            required init() {}
            
            func increment() -> Bool {
                self.count += 1
                return self.count >= 3
            }
        }
        
        let builder = FlowGraphBuilder<GraphType>();
        
        builder.add(waiting: .first, subFlowType: FirstSubFlow.self) { event, subFlow in
            return subFlow.increment() ? .wait(.second) : .stay
        }
        
        builder.add(waiting: .second, subFlowType: SecondSubFlow.self) { event, subFlow in
            return subFlow.increment() ? .wait(.first) : .stay
        }
        
        let graph = builder.build(initial: .first)
        
        graph.run(.bang)
        
        XCTAssertEqual(graph.state, .waiting(.first))
        
        graph.run(.bang)
        
        XCTAssertEqual(graph.state, .waiting(.second))
        
        graph.run(.bang)
        
        XCTAssertEqual(graph.state, .waiting(.second))
        
        graph.run(.bang)
        
        XCTAssertEqual(graph.state, .waiting(.second))
        
        graph.run(.bang)
        
        XCTAssertEqual(graph.state, .waiting(.first))
        
        graph.run(.bang)
        
        XCTAssertEqual(graph.state, .waiting(.first))
        
        graph.run(.bang)
        
        XCTAssertEqual(graph.state, .waiting(.second))
    }
    
    func testDebugHandler() {
        struct DebugTestType: FlowGraphType {
            enum WaitingState: CaseIterable {
                case first
                case second
            }
            
            enum RunningState: CaseIterable {
                case firstToSecond
            }
            
            enum Event {
                case bang
            }
        }
        
        let builder = FlowGraphBuilder<DebugTestType>()
        
        builder.add(waiting: .first) { event in
            return .run(.firstToSecond, event)
        }
        
        builder.add(running: .firstToSecond) { event in
            return .wait(.second)
        }
        
        builder.add(waiting: .second) { event in
            return .wait(.first)
        }
        
        let graph = builder.build(initial: .first)
        
        var received: [(DebugTestType.State, DebugTestType.State)] = []
        
        graph.activateDebugging { (next, prev) in
            received.append((next, prev))
        }
        
        graph.run(.bang)
        
        XCTAssertEqual(received.count, 2)
        
        XCTAssertEqual(received[0].0, .running(.firstToSecond))
        XCTAssertEqual(received[0].1, .waiting(.first))
        XCTAssertEqual(received[1].0, .waiting(.second))
        XCTAssertEqual(received[1].1, .running(.firstToSecond))
        
        graph.run(.bang)
        
        XCTAssertEqual(received.count, 3)
        
        XCTAssertEqual(received[2].0, .waiting(.first))
        XCTAssertEqual(received[2].1, .waiting(.second))
        
        graph.deactivateDebugging()
        
        graph.run(.bang)
        
        XCTAssertEqual(received.count, 3)
    }
    
    static var allTests = [
        ("testFlow", testFlow),
        ("testContains", testContains),
        ("testDebugHandler", testDebugHandler),
    ]
}


