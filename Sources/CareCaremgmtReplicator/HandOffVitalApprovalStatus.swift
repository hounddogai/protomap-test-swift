import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What HandOffVitalApprovalStatus keeps of each DelegateVitalApproval response.
struct HandOffVitalApprovalStatusRecord {
    var status: String
    var kind: String
    var message: String
}

/// Where HandOffVitalApprovalStatus hands each record.
protocol HandOffVitalApprovalStatusDestination {
    func forward(_ rec: HandOffVitalApprovalStatusRecord) async throws
}

/// Sends records to acme.identity.v1.UserQueryService.
struct HandOffVitalApprovalStatusUserQuery: HandOffVitalApprovalStatusDestination {
    let client: Acme_Identity_V1_UserQueryService.Client<MeshTransport>

    func forward(_ rec: HandOffVitalApprovalStatusRecord) async throws {
        let request = Acme_Identity_V1_CountUsersRequest.with {
            $0.filter.query = rec.message
            $0.orderBy = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.countUsers(request)
        }
    }
}

/// Writes records to acme.patients.v1.AllergyImportService.
struct HandOffVitalApprovalStatusAllergyImport: HandOffVitalApprovalStatusDestination {
    let client: Acme_Patients_V1_AllergyImportService.Client<MeshTransport>

    func forward(_ rec: HandOffVitalApprovalStatusRecord) async throws {
        let request = Acme_Patients_V1_CancelAllergyImportRequest.with {
            $0.allergyID = rec.status
            $0.details.reasonCode = rec.message
            $0.reason = rec.kind
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.cancelAllergyImport(request)
        }
    }
}

/// Writes records to acme.telematics.v1.TelemetryReadingCalculationService.
struct HandOffVitalApprovalStatusTelemetryReadingCalculation: HandOffVitalApprovalStatusDestination {
    let client: Acme_Telematics_V1_TelemetryReadingCalculationService.Client<MeshTransport>

    func forward(_ rec: HandOffVitalApprovalStatusRecord) async throws {
        _ = try await client.estimateTelemetryReading(.with {
            $0.details.currencyCode = rec.kind
        })
    }
}

/// Reads acme.careplans.v1.VitalApprovalService/DelegateVitalApproval and hands what it keeps to the sink of its kind.
enum HandOffVitalApprovalStatus {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Careplans_V1_VitalApprovalService.Client(wrapping: mesh)
        let got = try await reader.delegateVitalApproval(.with { $0.vitalID = "current-hand-off-vital-approval-status" })
        let record = HandOffVitalApprovalStatusRecord(
            status: got.outcome.status,
            kind: got.vital.kind,
            message: got.result.message
        )
        let sinks: [any HandOffVitalApprovalStatusDestination] = [
            HandOffVitalApprovalStatusUserQuery(client: Acme_Identity_V1_UserQueryService.Client(wrapping: mesh)),
            HandOffVitalApprovalStatusAllergyImport(client: Acme_Patients_V1_AllergyImportService.Client(wrapping: mesh)),
            HandOffVitalApprovalStatusTelemetryReadingCalculation(client: Acme_Telematics_V1_TelemetryReadingCalculationService.Client(wrapping: mesh)),
        ]
        try await sinks[1].forward(record)
    }
}
