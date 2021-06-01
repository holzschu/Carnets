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
            checksum: "6a41de307993536beca9b9c1b126085f80921ab8722ad890a8d54f1e8f6079ae"
        ),
        .binaryTarget(
            name: "awk",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.9.0/awk.xcframework.zip",
            checksum: "d4063a5c4a1eeac56f9ff9167e0a9e754f35fc8217476970700b9cf200e5c715"
        ),
        .binaryTarget(
            name: "curl_ios",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.9.0/curl_ios.xcframework.zip",
            checksum: "40f4d113484d3d935320044940ab9791369fa839f4605056c309087fa99ff89f"
        ),
        .binaryTarget(
            name: "files",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.9.0/files.xcframework.zip",
            checksum: "0447973bcb65f88cc84f66bb9f540fb8462b50a94c80fd634d4da19ff793e119"
        ),
        .binaryTarget(
            name: "shell",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.9.0/shell.xcframework.zip",
            checksum: "aa22db5bb759ecfca021edfebad7442dea0c2bc09abfdb311c059985e4ea3391"
        ),
        .binaryTarget(
            name: "ssh_cmd",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.9.0/ssh_cmd.xcframework.zip",
            checksum: "8483ce068ed6751343583ed29daed90d70d17dd595d3f46967ef8226dd784dfb"
        ),
        .binaryTarget(
            name: "tar",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.9.0/tar.xcframework.zip",
            checksum: "dd60d2d4f63f666f7a3391410714f2a6f61457ace2cbf8de7ee070f20854eddc"
        ),
        .binaryTarget(
            name: "text",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.9.0/text.xcframework.zip",
            checksum: "2053a9d30c07968b0b10c51c5235feac006c1799828876e7a04436bfe5b40625"
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
