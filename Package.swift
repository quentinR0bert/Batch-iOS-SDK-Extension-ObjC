// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BatchExtension-ObjC",
    platforms: [
        .iOS(.v10)
    ],
    products: [
        .library(
            name: "BatchExtension",
            targets: ["BatchExtension"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "BatchExtension",
            dependencies: [],
            path: "Sources",
            sources: ["Public/", "Private/"],
            publicHeadersPath: "Public/",
            cSettings: [
                .headerSearchPath("Public/"),
                .headerSearchPath("Private/")
            ]
        ),
    ]
)
