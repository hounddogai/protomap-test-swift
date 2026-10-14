import Foundation
import GRPCCore
import GRPCNIOTransportHTTP2
import Logging

public typealias MeshTransport = HTTP2ClientTransport.Posix
public typealias MeshClient = GRPCClient<MeshTransport>

/// Capture configuration at startup; request handlers never read mutable process environment.
@propertyWrapper
public struct EnvironmentValue: Sendable {
    public let wrappedValue: String

    public init(_ key: String, default fallback: String) {
        wrappedValue = ProcessInfo.processInfo.environment[key] ?? fallback
    }
}

public struct Settings: Sendable {
    @EnvironmentValue("ACME_REGION", default: "west") public var region: String
    @EnvironmentValue("ACME_MESH_HOST", default: "localhost") public var meshHost: String
    @EnvironmentValue("ACME_MESH_PORT", default: "15001") public var meshPort: String
    @EnvironmentValue("ACME_LISTEN_PORT", default: "8443") public var listenPort: String
    @EnvironmentValue("ACME_DATABASE", default: "acme.sqlite") public var databasePath: String
    @EnvironmentValue("ACME_TENANT", default: "training") public var tenant: String
    @EnvironmentValue("ACME_TOKEN", default: "") public var token: String
    /// The workload credential the server makes its own calls with, such as its identity lookups.
    @EnvironmentValue("ACME_SERVICE_TOKEN", default: "") public var serviceToken: String

    public init() {}

    public func port(_ text: String) throws -> Int {
        guard let value = Int(text), (1...65535).contains(value) else {
            throw RPCError(code: .invalidArgument, message: "Port must be between 1 and 65535")
        }
        return value
    }
}

/// The composition root provides capabilities, while domains depend on this protocol.
public protocol Dependencies: Sendable {
    var mesh: MeshClient { get }
    var repository: any RecordRepository { get }
    var settings: Settings { get }
    var logger: Logger { get }
}

public struct Container: Dependencies {
    public let mesh: MeshClient
    public let repository: any RecordRepository
    public let settings: Settings
    public let logger: Logger

    public init(mesh: MeshClient, repository: any RecordRepository, settings: Settings, logger: Logger) {
        self.mesh = mesh
        self.repository = repository
        self.settings = settings
        self.logger = logger
    }
}
