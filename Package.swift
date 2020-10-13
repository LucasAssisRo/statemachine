// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "StateMachine",
    products: [
        .library(
            name: "StateMachine",
            targets: ["StateMachine"]
        ),
    ],
    targets: [
        .target(
            name: "StateMachine",
            dependencies: []
        ),
    ]
)
