import AcmeContracts
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Primary associated types keep ports injectable without erasing their request and response types.
public protocol RPCPort<Request, Response>: Sendable {
    associatedtype Request: Message
    associatedtype Response: Message
    func execute(_ request: Request) async throws -> Response
}

public struct ClosurePort<Request: Message, Response: Message>: RPCPort {
    private let operation: @Sendable (Request) async throws -> Response

    public init(_ operation: @escaping @Sendable (Request) async throws -> Response) {
        self.operation = operation
    }

    public func execute(_ request: Request) async throws -> Response {
        try await operation(request)
    }
}

public enum RPCOperations {
    public static func call<Request: Message, Response: Message>(
        _ request: Request,
        using operation: @Sendable (Request) async throws -> Response
    ) async throws -> Response {
        try Task.checkCancellation()
        return try await operation(request)
    }

    public static func port<Request: Message, Response: Message>(
        _ operation: @escaping @Sendable (Request) async throws -> Response
    ) -> some RPCPort<Request, Response> {
        ClosurePort(operation)
    }

    /// Retry only reads: callers select this helper for idempotent queries.
    public static func read<Response: Sendable>(
        _ operation: @Sendable () async throws -> Response
    ) async throws -> Response {
        do { return try await operation() } catch let error as RPCError where error.code == .unavailable {
            try await Task.sleep(for: .milliseconds(20))
            return try await operation()
        }
    }
}

public enum Projection {
    public static func updating<MessageType: Message>(
        _ message: MessageType, with update: (inout MessageType) -> Void
    ) -> MessageType {
        var result = message
        update(&result)
        return result
    }

    public static func read<Root, Value>(_ root: Root, at path: KeyPath<Root, Value>) -> Value {
        root[keyPath: path]
    }

    public static func json<MessageType: Message>(_ message: MessageType) throws -> MessageType {
        let bytes = Data(try message.jsonString().utf8)
        return try MessageType(jsonString: String(decoding: bytes, as: UTF8.self))
    }

    public static func unpack<MessageType: Message>(_ message: MessageType) throws -> MessageType {
        let envelope = try Google_Protobuf_Any(message: message)
        return try MessageType(unpackingAny: envelope)
    }

    /// Preserve all candidates when several upstreams contribute the same optional response field.
    public static func firstValue<Value: Equatable>(_ values: [Value], default fallback: Value) -> Value {
        values.first(where: { $0 != fallback }) ?? fallback
    }
}

public enum Validation {
    public static func context(_ context: Acme_Common_V1_RequestContext) throws {
        guard !context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "context.tenant_id is required")
        }
        guard context.actor.serviceAccount || !context.actor.userID.isEmpty else {
            throw RPCError(code: .unauthenticated, message: "An actor is required")
        }
    }
}
