// swift-tools-version:5.3
import PackageDescription

_ = Package(
    name: "xcfs",
    platforms: [.macOS("11")],
    dependencies: [
        .package(url: "https://github.com/yury/FMake", from: "0.0.16")
    ],
    
    targets: [
        .binaryTarget(
            name: "libssh2",
            url: "https://github.com/blinksh/libssh2-apple/releases/download/v1.9.0/libssh2-dynamic.xcframework.zip",
            checksum: "79b18673040a51e7c62259965c2310b5df2a686de83b9cc94c54db944621c32c"
        ),
        .binaryTarget(
            name: "openssl",
            url: "https://github.com/blinksh/openssl-apple/releases/download/v1.1.1i/openssl-dynamic.xcframework.zip",
            checksum: "7f7e7cf7a1717dde6fdc71ef62c24e782f3c0ca1a2621e9376699362da990993"
        ),
        // ios_system:
        .binaryTarget(
            name: "ios_system",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.8.0/ios_system.xcframework.zip",
            checksum: "4f8ff7fba7a053d8cbd79abb505c2c71c0c9756d5eea64e845dee6f0946ea032"
        ),
        .binaryTarget(
            name: "awk",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.8.0/awk.xcframework.zip",
            checksum: "cea938659311902471d64e5345294780d364f20f983ae701ddd52870afb0bceb"
        ),
        .binaryTarget(
            name: "curl_ios",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.8.0/curl_ios.xcframework.zip",
            checksum: "d21c43012a1966109f05a1f0c45bbcd74102204d9025ee243f4c0b31ae3651a7"
        ),
        .binaryTarget(
            name: "files",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.8.0/files.xcframework.zip",
            checksum: "2c6a028702519e823481310676407c6525f652db7e9bfdb84680bfc89263e0c8"
        ),
        .binaryTarget(
            name: "shell",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.8.0/shell.xcframework.zip",
            checksum: "9af7f9d87e1bc1e26ff7c076959ee08a2d6b6584b56bbf772bcdbe43563bdb10"
        ),
        .binaryTarget(
            name: "ssh_cmd",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.8.0/ssh_cmd.xcframework.zip",
            checksum: "a3f19cd39b4ecb8e4f0983c4cbd78febc52a05e547ea4bdc85ddf74c2789b3ee"
        ),
        .binaryTarget(
            name: "tar",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.8.0/tar.xcframework.zip",
            checksum: "13a188649adcb25ca483dcc35b4fd91538ba9629dd15e845cf7bac28f84d7526"
        ),
        .binaryTarget(
            name: "text",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.8.0/text.xcframework.zip",
            checksum: "c56d164d7c0fd37d88f265fbd2aca47cd21dc42db536af33a1a469660794ad98"
        ),

        .binaryTarget(
            name: "mandoc",
            url: "https://github.com/holzschu/ios_system/releases/download/2.7/mandoc.xcframework.zip",
            checksum: "428eadde2515ad58ede9943a54e0bd56f8cd2980cf89a7b1762c7f36594737f5"
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

/* 
ios_system.xcframework.zip	7680ddfbc9ee41eecec13a86cb5a5189b95c8ec9dab861695c692b85435bbdf2
awk.xcframework.zip	dad5fe7a16a3f32343c53cb22d9a28a092e9ca6e8beb0faea4aae2c15359e8db
curl_ios.xcframework.zip	168bf3b37d8c14d0915049ea97a3d46518d855df488da986b876fc09df50af9f
files.xcframework.zip	7494be7319ef73271e2210e8ecf2ea2b134a35edb5ed921b9ca64c3586d158f3
shell.xcframework.zip	898d61af490747ccc1f581504c071db7508c816297985f9022cc6f2f21d19673
ssh_cmd.xcframework.zip	78d1b7c14c9447465cb49f1defd195e62dd77a4e4e2bc6762d8363754e2eee40
tar.xcframework.zip	1b8eb72a7e38714aa265441dc28ff1963b13990f67c660b9b058fffad11a4264
text.xcframework.zip	fcde883ff2d8f7d1cc43e9d4a80f01df8ab8d6e42515c4492f2fcc7a05b79afa
*/
