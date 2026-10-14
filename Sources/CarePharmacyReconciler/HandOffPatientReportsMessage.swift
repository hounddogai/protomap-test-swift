import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What HandOffPatientReportsMessage keeps of each ListPatientReports response.
struct HandOffPatientReportsMessageRecord {
    var message: String
    var correlationID: String
}

/// Where HandOffPatientReportsMessage hands each record.
protocol HandOffPatientReportsMessageDestination {
    func apply(_ rec: HandOffPatientReportsMessageRecord) async throws
}

/// Hands records to acme.prescriptions.v1.RefillSyncService.
struct HandOffPatientReportsMessageRefillSync: HandOffPatientReportsMessageDestination {
    let client: Acme_Prescriptions_V1_RefillSyncService.Client<MeshTransport>

    func apply(_ rec: HandOffPatientReportsMessageRecord) async throws {
        _ = try await client.reconcileRefills(.with {
            $0.refillID = rec.message
        })
    }
}

/// Passes records to acme.patientapp.v1.CareInboxWorkflowService.
struct HandOffPatientReportsMessageCareInboxWorkflow: HandOffPatientReportsMessageDestination {
    let client: Acme_Patientapp_V1_CareInboxWorkflowService.Client<MeshTransport>

    func apply(_ rec: HandOffPatientReportsMessageRecord) async throws {
        _ = try await client.advanceCareInboxWorkflow(.with {
            $0.careInboxID = rec.message
        })
    }
}

/// Reads acme.patients.v1.PatientReportingService/ListPatientReports and hands what it keeps to the sink of its kind.
enum HandOffPatientReportsMessage {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Patients_V1_PatientReportingService.Client(wrapping: mesh)
        let found = try await origin.listPatientReports(.with { $0.orderBy = "default-hand-off-patient-reports-message" })
        let entry = HandOffPatientReportsMessageRecord(
            message: Kit.Text.normalize(found.result.message),
            correlationID: found.result.correlationID
        )
        try await act("care-inbox-workflow", entry, mesh)
    }

    /// Runs the action registered for a kind.
    static func act(_ kind: String, _ rec: HandOffPatientReportsMessageRecord, _ mesh: MeshClient) async throws {
        let actions: [String: () async throws -> Void] = [
            "refill-sync": { try await HandOffPatientReportsMessageRefillSync(client: Acme_Prescriptions_V1_RefillSyncService.Client(wrapping: mesh)).apply(rec) },
            "care-inbox-workflow": { try await HandOffPatientReportsMessageCareInboxWorkflow(client: Acme_Patientapp_V1_CareInboxWorkflowService.Client(wrapping: mesh)).apply(rec) },
        ]
        guard let action = actions[kind] else {
            throw Kit.Failure("no action for \(kind)")
        }
        try await action()
    }
}
