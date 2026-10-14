import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ReplayUsersToken keeps of each SuggestUsers response.
struct ReplayUsersTokenRecord {
    var nextPageToken: String
    var status: String
    var correlationID: String
    var message: String
}

/// Where ReplayUsersToken hands each record.
protocol ReplayUsersTokenSink {
    func forward(_ rec: ReplayUsersTokenRecord) async throws
}

/// Writes records to acme.patientapp.v1.PatientHomeWorkflowService.
struct ReplayUsersTokenPatientHomeWorkflow: ReplayUsersTokenSink {
    let client: Acme_Patientapp_V1_PatientHomeWorkflowService.Client<MeshTransport>

    func forward(_ rec: ReplayUsersTokenRecord) async throws {
        _ = try await client.cancelPatientHomeWorkflow(.with {
            $0.details.step = rec.correlationID
        })
    }
}

/// Sends records to acme.telematics.v1.TelemetryReadingQueryService.
struct ReplayUsersTokenTelemetryReadingQuery: ReplayUsersTokenSink {
    let client: Acme_Telematics_V1_TelemetryReadingQueryService.Client<MeshTransport>

    func forward(_ rec: ReplayUsersTokenRecord) async throws {
        _ = try await client.summarizeTelemetryReadings(.with {
            $0.details.format = rec.status
        })
    }
}

/// Reads acme.identity.v1.UserQueryService/SuggestUsers and hands what it keeps to the sink of its kind.
enum ReplayUsersToken {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Identity_V1_UserQueryService.Client(wrapping: mesh)
        let response = try await reader.suggestUsers(.with { $0.orderBy = "nightly-replay-users-token" })
        let rec = ReplayUsersTokenRecord(
            nextPageToken: response.pageInfo.nextPageToken,
            status: response.result.status,
            correlationID: response.result.correlationID,
            message: response.result.message
        )
        let sinks: [any ReplayUsersTokenSink] = [
            ReplayUsersTokenPatientHomeWorkflow(client: Acme_Patientapp_V1_PatientHomeWorkflowService.Client(wrapping: mesh)),
            ReplayUsersTokenTelemetryReadingQuery(client: Acme_Telematics_V1_TelemetryReadingQueryService.Client(wrapping: mesh)),
        ]
        try await sinks[1].forward(rec)
    }
}
