//
//  SwiftFlowGraphExampleTests.swift
//

import XCTest
@testable import SwiftFlowGraphExample

class FlowGraphTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testFlow() {
        enum State: EnumEnumerable {
            case begin
            case zero
            case nonZero
        }
        
        enum Event {
            case none
            case value(Int)
            case bang
        }
        
        let builder = FlowGraphBuilder<State, Event>()
        
        builder.add(state: .begin) { event in
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
        
        builder.add(state: .zero) { event in
            switch event {
            case .bang:
                return .wait(.begin)
            default:
                return .stay
            }
        }
        
        builder.add(state: .nonZero) { event in
            return .wait(.begin)
        }
        
        for state in State.cases {
            XCTAssertTrue(builder.contains(state: state))
        }
        
        let graph = builder.build(initial: .begin)
        
        XCTAssertEqual(graph.state, .begin)
        
        graph.run(.value(0))
        
        XCTAssertEqual(graph.state, .zero)
        
        graph.run(.value(0))
        
        XCTAssertEqual(graph.state, .zero)
        
        graph.run(.bang)
        
        XCTAssertEqual(graph.state, .begin)
        
        graph.run(.value(1))
        
        XCTAssertEqual(graph.state, .begin)
    }
    
    func testContains() {
        enum State {
            case first
            case second
        }
        
        let builder = FlowGraphBuilder<State, Int>()
        
        builder.add(state: .first) { _ in .stay }
        
        XCTAssertTrue(builder.contains(state: .first))
        XCTAssertFalse(builder.contains(state: .second))
    }
}
