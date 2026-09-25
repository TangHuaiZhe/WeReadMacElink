// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "WeReadMacElink",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "WeReadMacElink", targets: ["WeReadMacElink"])
    ],
    targets: [
        .executableTarget(name: "WeReadMacElink"),
        .testTarget(
            name: "WeReadMacElinkTests",
            dependencies: ["WeReadMacElink"]
        )
    ],
    swiftLanguageModes: [.v5]
)
