import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ExportFeatureFlagsToken keeps of each SuggestFeatureFlags response.
struct ExportFeatureFlagsTokenRecord {
    var nextPageToken: String
    var status: String
}

/// Where ExportFeatureFlagsToken hands each record.
protocol ExportFeatureFlagsTokenSink {
    func deliver(_ rec: ExportFeatureFlagsTokenRecord) async throws
}

/// Passes records to acme.telehealth.v1.TriageWorkflowService.
struct ExportFeatureFlagsTokenTriageWorkflow: ExportFeatureFlagsTokenSink {
    let client: Acme_Telehealth_V1_TriageWorkflowService.Client<MeshTransport>

    func deliver(_ rec: ExportFeatureFlagsTokenRecord) async throws {
        _ = try await client.advanceTriageWorkflow(.with {
            $0.triage.subject = rec.nextPageToken
        })
    }
}

/// Sends records to acme.appointments.v1.AppointmentService.
struct ExportFeatureFlagsTokenAppointment: ExportFeatureFlagsTokenSink {
    let client: Acme_Appointments_V1_AppointmentService.Client<MeshTransport>

    func deliver(_ rec: ExportFeatureFlagsTokenRecord) async throws {
        _ = try await client.getAppointment(.with {
            $0.appointmentID = rec.status
        })
    }
}

/// Reads acme.featureflags.v1.FeatureFlagQueryService/SuggestFeatureFlags and hands what it keeps to the sink of its kind.
enum ExportFeatureFlagsToken {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Featureflags_V1_FeatureFlagQueryService.Client(wrapping: mesh)
        let got = try await reader.suggestFeatureFlags(.with { $0.orderBy = "default-export-feature-flags-token" })
        let record = ExportFeatureFlagsTokenRecord(
            nextPageToken: got.pageInfo.nextPageToken,
            status: got.result.status
        )
        let sinks: [any ExportFeatureFlagsTokenSink] = [
            ExportFeatureFlagsTokenTriageWorkflow(client: Acme_Telehealth_V1_TriageWorkflowService.Client(wrapping: mesh)),
            ExportFeatureFlagsTokenAppointment(client: Acme_Appointments_V1_AppointmentService.Client(wrapping: mesh)),
        ]
        try await sinks[1].deliver(record)
    }
}
