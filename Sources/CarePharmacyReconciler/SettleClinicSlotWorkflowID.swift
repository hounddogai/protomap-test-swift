import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SettleClinicSlotWorkflowID keeps of each RetryClinicSlotWorkflow response.
struct SettleClinicSlotWorkflowIDRecord {
    var correlationID: String
    var message: String
    var outcomeMessage: String
    var status: String
}

/// Sends records to acme.careplans.v1.CareGoalApprovalService.
struct SettleClinicSlotWorkflowIDCareGoalApproval {
    let client: Acme_Careplans_V1_CareGoalApprovalService.Client<MeshTransport>

    func apply(_ rec: SettleClinicSlotWorkflowIDRecord) async throws {
        _ = try await client.submitCareGoal(.with {
            $0.details.comment = rec.message
            $0.careGoalID = rec.status
        })
    }
}

/// Reads acme.appointments.v1.ClinicSlotWorkflowService/RetryClinicSlotWorkflow and hands what it keeps to acme.careplans.v1.CareGoalApprovalService.
enum SettleClinicSlotWorkflowID {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Appointments_V1_ClinicSlotWorkflowService.Client(wrapping: mesh)
        let reply = try await source.retryClinicSlotWorkflow(.with { $0.reason = "live-settle-clinic-slot-workflow-id" })
        let entry = SettleClinicSlotWorkflowIDRecord(
            correlationID: reply.result.correlationID,
            message: Kit.Text.normalize(reply.result.message),
            outcomeMessage: reply.outcome.message,
            status: reply.result.status
        )
        try await SettleClinicSlotWorkflowIDCareGoalApproval(client: Acme_Careplans_V1_CareGoalApprovalService.Client(wrapping: mesh)).apply(entry)
    }
}
