import AcmeAppointments
import AcmeCareplans
import AcmeContracts
import AcmePatientapp
import AcmePatients
import AcmePlatform
import AcmePrescriptions
import AcmeTelehealth
import Foundation
import GRPCCore
import GRPCNIOTransportHTTP2
import GRPCProtobuf
import Logging
import SwiftProtobuf

@main
enum AcmeServer {
    static func main() async throws {
        let settings = Settings()
        let logger = Logger(label: "acme.acmeserver")
        try await withGRPCClient(
            transport: .http2NIOPosix(
                target: .dns(host: settings.meshHost, port: try settings.port(settings.meshPort)),
                transportSecurity: .plaintext
            ),
            interceptors: [MeshCredentials(settings: settings, token: settings.serviceToken)]
        ) { mesh in
            let repository = try SQLiteRepository(path: settings.databasePath)
            let dependencies = Container(mesh: mesh, repository: repository, settings: settings, logger: logger)
            let modules = [
                AppointmentsModule.make(dependencies: dependencies),
                CareplansModule.make(dependencies: dependencies),
                PatientappModule.make(dependencies: dependencies),
                PatientsModule.make(dependencies: dependencies),
                PrescriptionsModule.make(dependencies: dependencies),
                TelehealthModule.make(dependencies: dependencies),
            ]
            let server = GRPCServer(
                transport: .http2NIOPosix(
                    address: .ipv4(host: "0.0.0.0", port: try settings.port(settings.listenPort)),
                    transportSecurity: .plaintext
                ),
                services: modules.flatMap(\.services),
                interceptors: [IdentityInterceptor(mesh: mesh, settings: settings, logger: logger)]
            )
            logger.info("Starting care services", metadata: ["port": .string(settings.listenPort)])
            try await withThrowingDiscardingTaskGroup { group in
                for module in modules {
                    for worker in module.workers { group.addTask { try await worker() } }
                }
                group.addTask { try await server.serve() }
            }
        }
    }
}
