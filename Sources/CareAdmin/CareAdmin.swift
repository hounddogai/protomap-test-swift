import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import GRPCNIOTransportHTTP2
import GRPCProtobuf
import Logging
import SwiftProtobuf

@main
enum CareAdmin {
    static func main() async throws {
        let settings = Settings()
        let logger = Logger(label: "acme.careadmin")
        try await withGRPCClient(
            transport: .http2NIOPosix(
                target: .dns(host: settings.meshHost, port: try settings.port(settings.meshPort)),
                transportSecurity: .plaintext
            ),
            interceptors: [MeshCredentials(settings: settings, token: settings.token)]
        ) { mesh in
            let context = Acme_Common_V1_RequestContext.with {
                $0.tenantID = settings.tenant
                $0.actor.serviceAccount = true
                $0.actor.userID = "care-operations"
                $0.locale = "en"
            }
            let metadata: Metadata = [
                "authorization": .string("Bearer " + settings.token), "x-tenant-id": .string(settings.tenant),
            ]
            let arguments = Array(CommandLine.arguments.dropFirst())
            guard arguments.count >= 2 else {
                throw RPCError(code: .invalidArgument, message: "Usage: care-admin user ID | invoke SERVICE METHOD ID")
            }
            let request = Acme_Identity_V1_GetUserRequest.with {
                $0.context = context
                $0.userID = arguments.last ?? ""
            }
            if arguments[0] == "user" {
                let client = Acme_Identity_V1_UserService.Client(wrapping: mesh)
                let reply = try await client.getUser(request, metadata: metadata)
                print(try reply.jsonString())
            } else {
                guard arguments.count == 4, arguments[0] == "invoke" else {
                    throw RPCError(code: .invalidArgument, message: "invoke needs SERVICE METHOD ID")
                }
                let descriptor = MethodDescriptor(
                    service: ServiceDescriptor(fullyQualifiedService: arguments[1]), method: arguments[2]
                )
                let reply = try await mesh.unary(
                    request: ClientRequest(message: request, metadata: metadata),
                    descriptor: descriptor,
                    serializer: ProtobufSerializer<Acme_Identity_V1_GetUserRequest>(),
                    deserializer: ProtobufDeserializer<Acme_Identity_V1_GetUserResponse>(),
                    options: .defaults
                ) { response in try response.message }
                print(try reply.jsonString())
            }
            logger.info("Admin operation complete")
        }
    }
}
