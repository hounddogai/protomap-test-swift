import GRPCCore

/// Task-local metadata follows child tasks without leaking credentials across concurrent requests.
public enum CallerScope {
    @TaskLocal public static var metadata: Metadata = [:]
}

extension Metadata {
    public func firstString(_ key: String) -> String? {
        var values = self[stringValues: key].makeIterator()
        return values.next()
    }
}

/// Calls carry their caller's credentials, or else, for calls no caller asked for, the program's own.
public struct MeshCredentials: ClientInterceptor {
    private let settings: Settings
    private let token: String
    public init(settings: Settings, token: String) {
        self.settings = settings
        self.token = token
    }

    public func intercept<Input: Sendable, Output: Sendable>(
        request: StreamingClientRequest<Input>,
        context: ClientContext,
        next: (StreamingClientRequest<Input>, ClientContext) async throws -> StreamingClientResponse<Output>
    ) async throws -> StreamingClientResponse<Output> {
        var authenticated = request
        for key in ["authorization", "x-tenant-id", "x-trace-id"] {
            if let value = CallerScope.metadata.firstString(key) {
                authenticated.metadata.replaceOrAddString(value, forKey: key)
            }
        }
        if authenticated.metadata.firstString("authorization") == nil, !token.isEmpty {
            authenticated.metadata.addString("Bearer " + token, forKey: "authorization")
        }
        if authenticated.metadata.firstString("x-tenant-id") == nil {
            authenticated.metadata.addString(settings.tenant, forKey: "x-tenant-id")
        }
        return try await next(authenticated, context)
    }
}
