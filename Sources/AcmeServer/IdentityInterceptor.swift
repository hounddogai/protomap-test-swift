import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import GRPCNIOTransportHTTP2
import GRPCProtobuf
import Logging
import SwiftProtobuf

/// Resolve the caller through identity before dispatching unary or streaming RPCs.
struct IdentityInterceptor: ServerInterceptor {
    let users: Acme_Identity_V1_UserService.Client<MeshTransport>
    let settings: Settings
    let logger: Logger

    init(mesh: MeshClient, settings: Settings, logger: Logger) {
        users = Acme_Identity_V1_UserService.Client(wrapping: mesh)
        self.settings = settings
        self.logger = logger
    }

    func intercept<Input: Sendable, Output: Sendable>(
        request: StreamingServerRequest<Input>,
        context: ServerContext,
        next: @Sendable (StreamingServerRequest<Input>, ServerContext) async throws -> StreamingServerResponse<Output>
    ) async throws -> StreamingServerResponse<Output> {
        guard let credential = request.metadata.firstString("authorization"),
            credential.hasPrefix("Bearer "), credential.count > 7,
            let tenant = request.metadata.firstString("x-tenant-id"), !tenant.isEmpty
        else {
            throw RPCError(code: .unauthenticated, message: "A bearer credential and tenant are required")
        }
        let token = String(credential.dropFirst(7))
        let identityRequest = Acme_Identity_V1_GetUserRequest.with {
            $0.userID = token
            $0.context.tenantID = tenant
            $0.context.actor.serviceAccount = true
            $0.context.actor.userID = "care"
            $0.context.traceID = request.metadata.firstString("x-trace-id") ?? ""
        }
        // The lookup is the server's own call, which bears its workload credential.
        let owner = try await users.getUser(
            identityRequest,
            metadata: [
                "authorization": .string("Bearer " + settings.serviceToken), "x-tenant-id": .string(tenant),
            ])
        guard owner.result.status == "ok", owner.user.userID == token else {
            throw RPCError(code: .permissionDenied, message: "Identity rejected the caller")
        }
        logger.debug(
            "Authenticated RPC",
            metadata: [
                "method": .string(context.descriptor.fullyQualifiedMethod), "actor": .string(owner.user.userID),
            ])
        return try await next(request, context)
    }
}
