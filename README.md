# protomap-test-swift

A synthetic code base of the fictional company Acme for testing ProtoMap: 110 gRPC services with 857 methods in 6
domains, and 3115 protobuf messages with 13493 fields, many nested several levels deep.

It was generated, with the eight other `protomap-test-*` repositories, from one catalog of Acme's APIs. The repositories
own disjoint domains and call each other's services, so each holds copies of the protobuf files it needs from the
others, byte for byte as their owners have them.

## Layout

Swift 6.4 and SwiftPM build the six domain modules under Sources/Acme*, with AcmePlatform providing protocol-oriented
dependencies, GRDB persistence, swift-log, configuration, and concurrency helpers. The proto target uses
GRPCProtobufGenerator to generate public SwiftProtobuf messages and grpc-swift 2 bindings in .build; generated bindings
are not committed. Run swift build and swift test, or PROTOC_PATH=$(command -v protoc) swift build to use an installed
protoc. Run swift run acme-server behind the mesh sidecar, with ACME_MESH_HOST, ACME_MESH_PORT, ACME_DATABASE, and
ACME_LISTEN_PORT as needed, and ACME_SERVICE_TOKEN, the credential of its own calls. Batch clients use ACME_TOKEN and
ACME_TENANT. CareReconciler, CareImporter, and CareAdmin are batch and operator entry points. Authentication calls
identity before every handler. Actor-directory transfers between RPCs and AsyncStream background follow-ups are the only
known gaps in expected.json. Package versions are exact; verification performs a full build and executable Swift tests,
including real SQLite writes.

The domains are `patientapp`, `patients`, `appointments`, `prescriptions`, `telehealth`, `careplans`. It calls services
of `accounting`, `admissions`, `anomalies`, `audiences`, `audit`, `authorization`, `benefits`, `boxoffice`,
`broadcasts`, `budgeting`, `catalog`, `certificates`, `collections`, `compliance`, `concessions`, `configuration`,
`content`, `corporateevents`, `customers`, `datasets`, `deliveries`, `dispatch`, `documents`, `drivers`, `employees`,
`expenses`, `fanportal`, `featureflags`, `fleet`, `fraud`, `fulfillment`, `identity`, `insurance`, `inventory`, `itsm`,
`keymanagement`, `ledger`, `lending`, `licensing`, `localization`, `metrics`, `notifications`, `onboarding`, `payments`,
`payroll`, `performance`, `performers`, `pipelines`, `promotions`, `ratelimiting`, `recommendations`, `recruiting`,
`search`, `seating`, `shipping`, `shows`, `sponsorships`, `suppliers`, `surveys`, `telematics`, `ticketing`,
`timekeeping`, `tours`, `treasury`, `venues`, `yards` too.

## Oracle

`expected.json` lists what scanning the repository must find: every handler, every call a handler or a program makes,
and every field-level flow from where a handler has data to where a call or its response takes it, each tagged with the
shape of the code that makes it. `crates/graph/tests/fixture_coverage.rs` in `protomap-source` checks a scan against it.

The code mixes in, on purpose, what makes static analysis of real code bases hard. Flows by pattern:

| Pattern | Flows |
|---|---|
| `any_message` | 382 |
| `async_let` | 395 |
| `async_stream_worker` | 110 |
| `batch_reconciliation` | 4 |
| `bidi_call` | 17 |
| `client_stream_writer` | 91 |
| `closure_dictionary` | 393 |
| `closure_property` | 387 |
| `configured_call` | 386 |
| `echo` | 1239 |
| `existential_port` | 374 |
| `generic_message` | 395 |
| `initializer_client` | 392 |
| `json_bytes` | 32 |
| `json_roundtrip` | 381 |
| `key_path` | 398 |
| `message_builder` | 397 |
| `oneof_switch` | 1193 |
| `opaque_port` | 390 |
| `request_extension` | 389 |
| `retry_read` | 101 |
| `server_stream_call` | 199 |
| `shared_actor_cache` | 146 |
| `stepwise` | 391 |
| `task_group_fanout` | 462 |
| `workflow` | 646 |

Flows whose values pass through something on their way, by what:

| Transform | Flows |
|---|---|
| `any_pack_unpack` | 264 |
| `json_encode` | 16 |
| `json_roundtrip` | 274 |
| `key_path` | 258 |
| `oneof_switch` | 294 |

Calls by pattern:

| Pattern | Calls |
|---|---|
| `admin_client` | 1 |
| `any_message` | 82 |
| `async_let` | 82 |
| `async_stream_worker` | 55 |
| `batch_reconciliation` | 4 |
| `bidi_call` | 16 |
| `client_stream_writer` | 75 |
| `closure_dictionary` | 82 |
| `closure_property` | 82 |
| `configured_call` | 82 |
| `existential_port` | 82 |
| `generic_message` | 82 |
| `initializer_client` | 82 |
| `json_bytes` | 16 |
| `json_roundtrip` | 82 |
| `jsonl_import` | 10 |
| `key_path` | 82 |
| `message_builder` | 82 |
| `oneof_switch` | 226 |
| `opaque_port` | 82 |
| `request_extension` | 82 |
| `retry_read` | 23 |
| `server_stream_call` | 53 |
| `shared_actor_cache` | 73 |
| `stepwise` | 82 |
| `task_group_fanout` | 133 |
| `workflow` | 141 |
