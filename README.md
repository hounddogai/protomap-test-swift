# protomap-test-swift

A synthetic Swift code base for testing [ProtoMap](https://protomap.ai) by [HoundDog.ai](https://hounddog.ai). It is
part of the code of Acme, a fictional company.

The code mixes in, on purpose, what makes static analysis of real code bases hard, and `expected.json` is the answer key
of what a scanner should find in it.

Acme's code is spread over multiple repositories, one per programming language. They were generated together from one
catalog of Acme's APIs. Each owns its own domains and calls the others' services, so it holds copies of the protobuf
files it needs from them, byte for byte as their owners have them. Scan them together to follow calls and data from one
repository to another.

| Repository                                                                         | Language   |
|------------------------------------------------------------------------------------|------------|
| [protomap-test-csharp](https://github.com/hounddogai/protomap-test-csharp)         | C#         |
| [protomap-test-golang](https://github.com/hounddogai/protomap-test-golang)         | Go         |
| [protomap-test-java](https://github.com/hounddogai/protomap-test-java)             | Java       |
| [protomap-test-javascript](https://github.com/hounddogai/protomap-test-javascript) | JavaScript |
| [protomap-test-kotlin](https://github.com/hounddogai/protomap-test-kotlin)         | Kotlin     |
| [protomap-test-python](https://github.com/hounddogai/protomap-test-python)         | Python     |
| [protomap-test-rust](https://github.com/hounddogai/protomap-test-rust)             | Rust       |
| **protomap-test-swift** (this one)                                                 | Swift      |
| [protomap-test-typescript](https://github.com/hounddogai/protomap-test-typescript) | TypeScript |

## Repository Layout

Swift 6.4 and SwiftPM build the domain modules under `Sources/Acme*`, with `AcmePlatform` providing protocol-oriented
dependencies, GRDB persistence, swift-log, configuration, and concurrency helpers. The proto target uses
GRPCProtobufGenerator to generate public SwiftProtobuf messages and grpc-swift 2 bindings in `.build`. Generated
bindings are not committed.

`CareReconciler`, `CareImporter`, and `CareAdmin` are batch and operator entry points. Authentication calls the identity
service before every handler.

## Build and Run

Build and test with SwiftPM. The tests include real SQLite writes.

```sh
swift build
swift test
```

To use an installed protoc, build with `PROTOC_PATH=$(command -v protoc) swift build`. Run `swift run acme-server`
behind the mesh sidecar, with `ACME_MESH_HOST`, `ACME_MESH_PORT`, `ACME_DATABASE`, and `ACME_LISTEN_PORT` as needed, and
`ACME_SERVICE_TOKEN`, the credential of its own calls. The batch clients use `ACME_TOKEN` and `ACME_TENANT`.
