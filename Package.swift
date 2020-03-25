// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "Skylark",
    platforms: [
        .iOS("9.3")
    ],
    products: [
        .library(
            name: "Skylark",
            targets: ["Skylark"]
        )
    ],
    targets: [
        .target(
            name: "Skylark",
            path: "Skylark/Classes"
        )
    ]
)
