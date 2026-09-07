// swift-tools-version:5.6
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
  dependencies: [
    .package(url: "https://github.com/apple/swift-docc-plugin.git", .upToNextMajor(from: "1.4.3")),
  ],
  targets: [
    .target(
      name: "StateMachine",
      dependencies: []
    ),
  ]
)
