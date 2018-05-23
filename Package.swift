// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "FlowGraph",
    products: [
        .library(name: "FlowGraph", targets: ["FlowGraph"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(name: "FlowGraph", dependencies: [], path: "FlowGraph"),
        .testTarget(name: "FlowGraphTests", dependencies: ["FlowGraph"]),
    ]
)
