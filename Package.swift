// swift-tools-version: 6.2.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AutomaUtilities",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "AutomaUtilities",
            targets: ["AutomaUtilities"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.113.2"),
        .package(url: "https://github.com/swift-server/swift-prometheus.git", from: "2.0.0"),
        .package(url: "https://github.com/swhitty/FlyingFox.git", .upToNextMajor(from: "0.25.0")),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.9.0"),
        .package(
            url: "https://github.com/open-telemetry/opentelemetry-swift.git",
            exact: "2.3.0"),
        .package(
            url: "https://github.com/open-telemetry/opentelemetry-swift-core.git",
            exact: "2.3.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "AutomaUtilities",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Prometheus", package: "swift-prometheus"),
                .product(name: "FlyingFox", package: "FlyingFox"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "OpenTelemetrySdk", package: "opentelemetry-swift-core"),
                .product(name: "OpenTelemetryApi", package: "opentelemetry-swift-core"),
                .product(name: "OpenTelemetryProtocolExporterHTTP", package: "opentelemetry-swift"),
            ]
        ),
        .testTarget(
            name: "AutomaUtilitiesTests",
            dependencies: [
                .target(name: "AutomaUtilities"),
                .product(name: "VaporTesting", package: "vapor"),
            ]
        ),
    ]
)
