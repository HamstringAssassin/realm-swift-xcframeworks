# realm-swift-xcframeworks

Pre-built static XCFrameworks for [realm-swift](https://github.com/realm/realm-swift), updated automatically on every upstream commit.

## Why

Building RealmSwift from source via SPM takes 5+ minutes on a clean build. These pre-built XCFrameworks reduce that to seconds.

## Usage

Add binary targets to your `Package.swift`:

```swift
.binaryTarget(
    name: "Realm",
    url: "https://github.com/HamstringAssassin/realm-swift-xcframeworks/releases/download/community-20.0.4-build.1/Realm.spm.zip",
    checksum: "344a4fb34f7e67be29761973029ff6cf83211a4ff2049d0626dce8c9f8cae012"
),
.binaryTarget(
    name: "RealmSwift",
    url: "https://github.com/HamstringAssassin/realm-swift-xcframeworks/releases/download/community-20.0.4-build.1/RealmSwift@26.5.spm.zip",
    checksum: "2af5f373a74975ee30e3d2ad8f2c90b6ced8bebbe5e993cb5ed28f44d0740f9a"
),
```

Check [Releases](https://github.com/HamstringAssassin/realm-swift-xcframeworks/releases) for the latest version. Each release includes checksums and ready-to-copy `Package.swift` snippets.

## Tracked branches

| Branch | Description |
|--------|-------------|
| `community` | Main development branch of realm-swift |
| `master` | Maintained by Realm/MongoDB, closest to official releases |

## How it works

1. A daily cron job checks realm-swift for new commits on each tracked branch
2. When a new commit is detected, a PR is created with the updated SHA
3. After merge, GitHub Actions builds static XCFrameworks using the upstream `build.sh`
4. Artifacts are packaged and published as a GitHub Release with checksums

## Artifacts per release

- `Realm.spm.zip` -- Objective-C core framework (Xcode-version agnostic)
- `RealmSwift@{version}.spm.zip` -- Swift framework (built for a specific Xcode/Swift version)

## Versioning

Releases are tagged as `{branch}-{version}-build.{n}`, e.g. `community-20.0.4-build.1`.

## Swift version compatibility

RealmSwift does not use Library Evolution, so the Swift module is tied to the Xcode/Swift version it was compiled with. Make sure the `RealmSwift@{version}` artifact matches your Xcode version. `Realm.spm.zip` (Objective-C) works with any Xcode version.
