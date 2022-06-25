// swift-tools-version:5.6

import PackageDescription

let package = Package(
    name: "SwiftUIMapView",
    platforms: [
        .iOS(.v13),
        .macOS(.v12)
    ],
    products: [
        .library(name: "SwiftUIMapView", targets: ["SwiftUIMapView"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "SwiftUIMapView", dependencies: []),
        .testTarget(name: "SwiftUIMapViewTests", dependencies: ["SwiftUIMapView"]),
    ]
)
