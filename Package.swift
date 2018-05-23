// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "SwiftFlowGraph",
    products: [
        .library(name: "SwiftFlowGraph", targets: ["SwiftFlowGraph"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(name: "SwiftFlowGraph", dependencies: [], path: "SwiftFlowGraph"),
        .testTarget(name: "SwiftFlowGraphTests", dependencies: ["SwiftFlowGraph"]),
    ]
)
