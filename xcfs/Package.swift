// swift-tools-version:5.3
import PackageDescription

_ = Package(
    name: "xcfs",
    platforms: [.macOS("11")],
    dependencies: [
        .package(url: "https://github.com/yury/FMake", from: "0.0.16")
    ],
    
    targets: [
        // libssh2
        .binaryTarget(
            name: "libssh2",
            url: "https://github.com/blinksh/libssh2-apple/releases/download/v1.9.0/libssh2-dynamic.xcframework.zip",
            checksum: "a4b5d09cd799b32a019148168983499e8501d93c2a458a9cc547b03028d96040"
        ),
        .binaryTarget(
            name: "openssl",
            url: "https://github.com/blinksh/openssl-apple/releases/download/v1.1.1k/openssl-dynamic.xcframework.zip",
            checksum: "9a7cc2686122e62445b85a8ce04f49379d99c952b8ea3534127c004b8a00af59"
        ),
        // ios_system:
        .binaryTarget(
            name: "ios_system",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.9.0/ios_system.xcframework.zip",
            checksum: "6022e36472dabebf6be96d2ce4de9da2609dc3f00d26e64359f68241b85bf1e3"
        ),
        .binaryTarget(
            name: "awk",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.9.0/awk.xcframework.zip",
            checksum: "8f8268507c55d4e1caa75726c117b43a99691656da5f832cc72bfe3dce274e1d"
        ),
        .binaryTarget(
            name: "curl_ios",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.9.0/curl_ios.xcframework.zip",
            checksum: "8ccda25c81f13ec6a1324dfbf9f09fe8d4da5f8296a8d3dec417a61e30483480"
        ),
        .binaryTarget(
            name: "files",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.9.0/files.xcframework.zip",
            checksum: "598ae49b3a3a322e0d2a87e7c3cb3fa1c29ddeea84c39c0f30c9dfb468d50c7a"
        ),
        .binaryTarget(
            name: "shell",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.9.0/shell.xcframework.zip",
            checksum: "2e77d2cf9692f6460ba760b72cde6f7106e7ff5e48ebc76feafb3300cff52db8"
        ),
        .binaryTarget(
            name: "ssh_cmd",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.9.0/ssh_cmd.xcframework.zip",
            checksum: "079c3e702d3530a3edbd828b3fd57a843082b507598bbe3be963aeef34450371"
        ),
        .binaryTarget(
            name: "tar",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.9.0/tar.xcframework.zip",
            checksum: "75ce32b7e4673924a010f9602390d28dbcc038f43f6cbed8b89e793f8135a201"
        ),
        .binaryTarget(
            name: "text",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.9.0/text.xcframework.zip",
            checksum: "1b17b7d81b86770136d67570e62701663df4f6bebd5b18b5dea78f791d03c7fa"
        ),
        .binaryTarget(
            name: "mandoc",
            url: "https://github.com/holzschu/ios_system/releases/download/2.7/mandoc.xcframework.zip",
            checksum: "02b952191ec311fe04df0001e85e8812f68473b6616eaed4a03c045aed111a43"
        ),
        // network_ios
        .binaryTarget(
            name: "network_ios",
            url: "https://github.com/holzschu/network_ios/releases/download/v0.2/network_ios.xcframework.zip",
            checksum: "18e96112ae86ec39390487d850e7732d88e446f9f233b2792d633933d4606d46"
        ),
        //
        .target(
            name: "build",
            dependencies: ["FMake"]
        ), 
    ]
)
