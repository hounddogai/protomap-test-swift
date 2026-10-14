import AcmeContracts
import GRPCCore

public enum FanOut {
    /// Bound concurrency and restore input order before selecting or projecting replies.
    public static func map<Input: Sendable, Output: Sendable>(
        _ inputs: [Input], limit: Int = 8,
        operation: @escaping @Sendable (Input) async throws -> Output
    ) async throws -> [Output] {
        try await withThrowingTaskGroup(of: (Int, Output).self) { group in
            var pending = inputs.enumerated().makeIterator()
            for _ in 0..<max(1, limit) {
                if let (index, value) = pending.next() {
                    group.addTask { (index, try await operation(value)) }
                }
            }
            var replies: [(Int, Output)] = []
            while let reply = try await group.next() {
                replies.append(reply)
                if let (index, value) = pending.next() {
                    group.addTask { (index, try await operation(value)) }
                }
            }
            return replies.sorted { $0.0 < $1.0 }.map(\.1)
        }
    }
}

/// A process-local directory used by later RPCs; tenant keys prevent cross-tenant reuse.
public actor ActorDirectory {
    private var users: [String: String] = [:]
    public init() {}

    public func remember(tenant: String, userID: String) {
        if users.count >= 1024, users[tenant] == nil, let evicted = users.keys.sorted().first {
            users.removeValue(forKey: evicted)
        }
        users[tenant] = userID
    }

    public func user(tenant: String) -> String? { users[tenant] }
}

/// One consumer owns each queue. A full buffer reports backpressure instead of losing an event silently.
public final class WorkQueue<Element: Sendable>: Sendable {
    public let events: AsyncStream<Element>
    private let continuation: AsyncStream<Element>.Continuation

    public init(capacity: Int = 128) {
        let pair = AsyncStream<Element>.makeStream(bufferingPolicy: .bufferingOldest(capacity))
        events = pair.stream
        continuation = pair.continuation
    }

    public func submit(_ value: Element) throws {
        switch continuation.yield(value) {
        case .enqueued: break
        case .dropped:
            throw RPCError(code: .resourceExhausted, message: "Follow-up queue is full")
        case .terminated:
            throw RPCError(code: .unavailable, message: "Follow-up worker is stopped")
        @unknown default:
            throw RPCError(code: .internalError, message: "Unknown queue state")
        }
    }

    public func finish() { continuation.finish() }
}

public struct ServiceModule: Sendable {
    public let services: [any RegistrableRPCService]
    public let workers: [@Sendable () async throws -> Void]

    public init(services: [any RegistrableRPCService], workers: [@Sendable () async throws -> Void]) {
        self.services = services
        self.workers = workers
    }
}
