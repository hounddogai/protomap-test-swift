import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import GRPCNIOTransportHTTP2
import GRPCProtobuf
import Logging
import SwiftProtobuf

@main
enum CareReconciler {
    static func main() async throws {
        let settings = Settings()
        let logger = Logger(label: "acme.carereconciler")
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
            let appointmentsReader = Acme_Appointments_V1_AppointmentApprovalService.Client(wrapping: mesh)
            let appointmentsWriter = Acme_Appointments_V1_AppointmentService.Client(wrapping: mesh)
            var appointmentsToken = ""
            repeat {
                let page = try await appointmentsReader.listPendingAppointments(
                    .with {
                        $0.context = context
                        $0.page.pageSize = 100
                        $0.page.pageToken = appointmentsToken
                    }, metadata: metadata)
                for record in page.appointments {
                    _ = try await appointmentsWriter.updateAppointment(
                        .with {
                            $0.context = context
                            $0.appointment = record
                            $0.updateMask.paths = ["audit"]
                        }, metadata: metadata)
                }
                appointmentsToken = page.pageInfo.nextPageToken
            } while !appointmentsToken.isEmpty
            let patientappReader = Acme_Patientapp_V1_CareInboxIntegrationService.Client(wrapping: mesh)
            let patientappWriter = Acme_Patientapp_V1_CareInboxService.Client(wrapping: mesh)
            var patientappToken = ""
            repeat {
                let page = try await patientappReader.listCareInboxSources(
                    .with {
                        $0.context = context
                        $0.page.pageSize = 100
                        $0.page.pageToken = patientappToken
                    }, metadata: metadata)
                for record in page.careInboxes {
                    _ = try await patientappWriter.updateCareInbox(
                        .with {
                            $0.context = context
                            $0.careInbox = record
                            $0.updateMask.paths = ["audit"]
                        }, metadata: metadata)
                }
                patientappToken = page.pageInfo.nextPageToken
            } while !patientappToken.isEmpty
            logger.info("Reconciliation complete")
        }
    }
}
