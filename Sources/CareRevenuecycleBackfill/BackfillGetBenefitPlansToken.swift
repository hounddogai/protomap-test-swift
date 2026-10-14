import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What BackfillGetBenefitPlansToken keeps of each BatchGetBenefitPlans response.
struct BackfillGetBenefitPlansTokenRecord {
    var nextPageToken: String
    var correlationID: String
    var message: String
    var status: String
}

/// Where BackfillGetBenefitPlansToken hands each record.
protocol BackfillGetBenefitPlansTokenSink {
    func write(_ rec: BackfillGetBenefitPlansTokenRecord) async throws
}

/// Passes records to acme.telehealth.v1.TriageApprovalService.
struct BackfillGetBenefitPlansTokenTriageApproval: BackfillGetBenefitPlansTokenSink {
    let client: Acme_Telehealth_V1_TriageApprovalService.Client<MeshTransport>

    func write(_ rec: BackfillGetBenefitPlansTokenRecord) async throws {
        _ = try await client.listPendingTriages(.with {
            $0.filter.ownerID = rec.status
            $0.page.pageToken = rec.message
            $0.filter.query = rec.correlationID
        })
    }
}

/// Passes records to acme.patients.v1.MedicalRecordApprovalService.
struct BackfillGetBenefitPlansTokenMedicalRecordApproval: BackfillGetBenefitPlansTokenSink {
    let client: Acme_Patients_V1_MedicalRecordApprovalService.Client<MeshTransport>

    func write(_ rec: BackfillGetBenefitPlansTokenRecord) async throws {
        _ = try await client.getMedicalRecordApprovalStatus(.with {
            $0.medicalRecordID = rec.status
        })
    }
}

/// Reads acme.benefits.v1.BenefitPlanService/BatchGetBenefitPlans and hands what it keeps to the sink of its kind.
enum BackfillGetBenefitPlansToken {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Benefits_V1_BenefitPlanService.Client(wrapping: mesh)
        let reply = try await reader.batchGetBenefitPlans(.init())
        let row = BackfillGetBenefitPlansTokenRecord(
            nextPageToken: Kit.Text.normalize(reply.pageInfo.nextPageToken),
            correlationID: reply.result.correlationID,
            message: reply.result.message,
            status: reply.result.status
        )
        try await act("medical-record-approval", row, mesh)
    }

    /// Runs the action registered for a kind.
    static func act(_ kind: String, _ rec: BackfillGetBenefitPlansTokenRecord, _ mesh: MeshClient) async throws {
        let actions: [String: () async throws -> Void] = [
            "triage-approval": { try await BackfillGetBenefitPlansTokenTriageApproval(client: Acme_Telehealth_V1_TriageApprovalService.Client(wrapping: mesh)).write(rec) },
            "medical-record-approval": { try await BackfillGetBenefitPlansTokenMedicalRecordApproval(client: Acme_Patients_V1_MedicalRecordApprovalService.Client(wrapping: mesh)).write(rec) },
        ]
        guard let action = actions[kind] else {
            throw Kit.Failure("no action for \(kind)")
        }
        try await action()
    }
}
