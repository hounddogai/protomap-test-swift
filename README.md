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

## Added Code and Benchmark Labels

`tools/grow` (seed 20261116) added ordinary application code to this repository, and 8 programs whose jobs carry rpc
responses to other rpcs through constructs a static analysis cannot resolve. All of it is under
`Sources/AcmePlatform/Kit/`, `Sources/AcmeCareplans/ClinicalOps/`, `Sources/AcmePatients/RevenueCycle/`,
`Sources/AcmePrescriptions/Pharmacy/`, `Sources/AcmePatients/Labs/`, `Sources/AcmeAppointments/BedManagement/`,
`Sources/AcmeCareplans/CareManagement/`, `Sources/AcmeAppointments/Staffing/`, `Sources/AcmeTelehealth/Imaging/`,
`Sources/AcmePatientapp/Consent/`, `Sources/AcmeTelehealth/Referrals/`, `Sources/CareClinicalopsSync/`,
`Sources/CareRevenuecycleBackfill/`, `Sources/CarePharmacyReconciler/`, `Sources/CareLabsRelay/`,
`Sources/CareBedmgmtSweeper/`, `Sources/CareCaremgmtReplicator/`, `Sources/CareStaffingExporter/`,
`Sources/CareImagingPublisher/`, `Tests/AcmePlatformTests/Kit/`, `Tests/AcmeDomainTests/`.

- The ordinary code (domain models, validation rules, stores and caches, adjustment engines, reports, workflows, feature
  flags, retries, command-line tools, and unit tests) makes no gRPC calls, so it adds no flows.
- Each planted job reads one rpc's response and hands some of its fields to one or more implementations, each calling
  another rpc. Which implementations run is decidable from the code of the functions on the flow's path. A flow through
  one that runs is in `flows`, with a `pattern` ending in `_real`, or the plain pattern name when every implementation
  runs; one through an implementation that cannot run is in `forbidden_flows`, with the full source and target and a
  pattern ending in `_decoy`.
- `benchmark` in `expected.json` names the generator, its seed, the new patterns, the new code's path and function
  prefixes, and the planted programs' islands. The labels are complete for the new code: every real flow it creates is
  in `flows`, so a flow the scanner reports in the new code that is not there is false.
- New `flows` entries are `known_gap` unless the scanner already finds them. Unlike the other `forbidden_flows`, which
  only name a source, the `_decoy` entries name an endpoint pair; `fixture_coverage.rs`, which reads only their source
  and target kind, lists the ones the scanner reports.

| Pattern | What decides which implementation runs | True | False |
|---|---|---:|---:|
| `direct_call` | nothing: one concrete call, which the scanner finds certain | 61 | 0 |
| `dispatch_closure_map` | a map of closures, one called by a constant key | 85 | 133 |
| `dispatch_filter_loop` | a loop over keyed implementations that skips all but one key | 97 | 158 |
| `dispatch_func_value` | a function value a switch on a constant kind reassigns | 77 | 161 |
| `dispatch_index` | a list of implementations, one taken by a constant index | 73 | 150 |
| `dispatch_registry` | a registry of implementations looked up by a constant key | 90 | 186 |
| `dispatch_runtime` | run-time data, so each implementation may run | 78 | 0 |
| `dispatch_switch` | a selector's switch on a kind its caller passes as a constant | 112 | 216 |
| `fanout_all` | nothing: a loop runs every implementation | 78 | 0 |
