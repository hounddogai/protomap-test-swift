import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SettlePrescriptionConflictsToken keeps of each ListPrescriptionConflicts response.
struct SettlePrescriptionConflictsTokenRecord {
    var nextPageToken: String
    var status: String
}

/// Where SettlePrescriptionConflictsToken hands each record.
protocol SettlePrescriptionConflictsTokenWriter {
    func write(_ rec: SettlePrescriptionConflictsTokenRecord) async throws
}

/// Passes records to acme.careplans.v1.CarePlanApprovalService.
struct SettlePrescriptionConflictsTokenCarePlanApproval: SettlePrescriptionConflictsTokenWriter {
    let client: Acme_Careplans_V1_CarePlanApprovalService.Client<MeshTransport>

    func write(_ rec: SettlePrescriptionConflictsTokenRecord) async throws {
        _ = try await client.listPendingCarePlans(.with {
            $0.filter.region = rec.status
        })
    }
}

/// Hands records to acme.promotions.v1.PromotionCalculationService.
struct SettlePrescriptionConflictsTokenPromotionCalculation: SettlePrescriptionConflictsTokenWriter {
    let client: Acme_Promotions_V1_PromotionCalculationService.Client<MeshTransport>

    func write(_ rec: SettlePrescriptionConflictsTokenRecord) async throws {
        let request = Acme_Promotions_V1_QuotePromotionRequest.with {
            $0.promotion.name = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.quotePromotion(request)
        }
    }
}

/// Sends records to acme.patientapp.v1.CareInboxWorkflowService.
struct SettlePrescriptionConflictsTokenCareInboxWorkflow: SettlePrescriptionConflictsTokenWriter {
    let client: Acme_Patientapp_V1_CareInboxWorkflowService.Client<MeshTransport>

    func write(_ rec: SettlePrescriptionConflictsTokenRecord) async throws {
        let request = Acme_Patientapp_V1_PauseCareInboxWorkflowRequest.with {
            $0.details.step = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.pauseCareInboxWorkflow(request)
        }
    }
}

/// Reads acme.prescriptions.v1.PrescriptionSyncService/ListPrescriptionConflicts and hands what it keeps to the sink of its kind.
enum SettlePrescriptionConflictsToken {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Prescriptions_V1_PrescriptionSyncService.Client(wrapping: mesh)
        let reply = try await source.listPrescriptionConflicts(.with { $0.orderBy = "nightly-settle-prescription-conflicts-token" })
        let record = SettlePrescriptionConflictsTokenRecord(
            nextPageToken: reply.pageInfo.nextPageToken,
            status: Kit.Text.normalize(reply.result.status)
        )
        let sinks: [any SettlePrescriptionConflictsTokenWriter] = [
            SettlePrescriptionConflictsTokenCarePlanApproval(client: Acme_Careplans_V1_CarePlanApprovalService.Client(wrapping: mesh)),
            SettlePrescriptionConflictsTokenPromotionCalculation(client: Acme_Promotions_V1_PromotionCalculationService.Client(wrapping: mesh)),
            SettlePrescriptionConflictsTokenCareInboxWorkflow(client: Acme_Patientapp_V1_CareInboxWorkflowService.Client(wrapping: mesh)),
        ]
        try await sinks[2].write(record)
    }
}
