// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Fanbar",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "Fanbar", targets: ["Fanbar"])],
    targets: [
        .target(name: "CSMC", linkerSettings: [.linkedFramework("IOKit")]),
        .executableTarget(name: "Fanbar", dependencies: ["CSMC"]),
    ]
)
