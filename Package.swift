// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "WalkFlowMac",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "WalkFlowCore", targets: ["WalkFlowCore"]),
        .executable(name: "WalkFlowMac", targets: ["WalkFlowMacApp"])
    ],
    dependencies: [
        .package(url: "https://github.com/airbnb/lottie-spm.git", from: "4.6.1")
    ],
    targets: [
        .target(
            name: "WalkFlowCore"
        ),
        .executableTarget(
            name: "WalkFlowMacApp",
            dependencies: [
                "WalkFlowCore",
                .product(name: "Lottie", package: "lottie-spm")
            ],
            exclude: ["Resources/Info.plist"]
        ),
        .testTarget(
            name: "WalkFlowCoreTests",
            dependencies: ["WalkFlowCore"]
        ),
        .testTarget(
            name: "WalkFlowMacAppTests",
            dependencies: ["WalkFlowMacApp", "WalkFlowCore"]
        )
    ]
)
