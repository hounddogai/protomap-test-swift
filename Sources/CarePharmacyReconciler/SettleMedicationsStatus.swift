import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SettleMedicationsStatus keeps of each PullMedications response.
struct SettleMedicationsStatusRecord {
    var status: String
    var code: String
}

/// Where SettleMedicationsStatus hands each record.
protocol SettleMedicationsStatusWriter {
    func push(_ rec: SettleMedicationsStatusRecord) async throws
}

/// Passes records to acme.shows.v1.ShowService.
struct SettleMedicationsStatusShow: SettleMedicationsStatusWriter {
    let client: Acme_Shows_V1_ShowService.Client<MeshTransport>

    func push(_ rec: SettleMedicationsStatusRecord) async throws {
        let request = Acme_Shows_V1_DeleteShowRequest.with {
            $0.reason = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.deleteShow(request)
        }
    }
}

/// Hands records to acme.careplans.v1.CareGoalLifecycleService.
struct SettleMedicationsStatusCareGoalLifecycle: SettleMedicationsStatusWriter {
    let client: Acme_Careplans_V1_CareGoalLifecycleService.Client<MeshTransport>

    func push(_ rec: SettleMedicationsStatusRecord) async throws {
        _ = try await client.terminateCareGoal(.with {
            $0.careGoalID = rec.status
            $0.details.reasonCode = rec.code
        })
    }
}

/// Hands records to acme.careplans.v1.CarePlanApprovalService.
struct SettleMedicationsStatusCarePlanApproval: SettleMedicationsStatusWriter {
    let client: Acme_Careplans_V1_CarePlanApprovalService.Client<MeshTransport>

    func push(_ rec: SettleMedicationsStatusRecord) async throws {
        _ = try await client.approveCarePlan(.with {
            $0.details.approverEmail = rec.status
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct SettleMedicationsStatusLogOnly: SettleMedicationsStatusWriter {
    let logger = Logger(label: "acme.settle-medications-status")

    func push(_ rec: SettleMedicationsStatusRecord) async throws {
        logger.info("No sink for record", metadata: ["status": .string(rec.status)])
    }
}

/// Reads acme.prescriptions.v1.MedicationSyncService/PullMedications and hands what it keeps to the sink of its kind.
enum SettleMedicationsStatus {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Prescriptions_V1_MedicationSyncService.Client(wrapping: mesh)
        let response = try await upstream.pullMedications(.with { $0.reason = "live-settle-medications-status" })
        let rec = SettleMedicationsStatusRecord(
            status: response.result.status,
            code: Kit.Text.normalize(response.medication.code)
        )
        try await deliver("care-plan-approval", rec, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: SettleMedicationsStatusRecord, _ mesh: MeshClient) async throws {
        var sink: any SettleMedicationsStatusWriter = SettleMedicationsStatusLogOnly()
        switch kind {
        case "show":
            sink = SettleMedicationsStatusShow(client: Acme_Shows_V1_ShowService.Client(wrapping: mesh))
        case "care-goal-lifecycle":
            sink = SettleMedicationsStatusCareGoalLifecycle(client: Acme_Careplans_V1_CareGoalLifecycleService.Client(wrapping: mesh))
        case "care-plan-approval":
            sink = SettleMedicationsStatusCarePlanApproval(client: Acme_Careplans_V1_CarePlanApprovalService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.push(rec)
    }
}
