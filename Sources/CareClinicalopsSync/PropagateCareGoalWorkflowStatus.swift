import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What PropagateCareGoalWorkflowStatus keeps of each AdvanceCareGoalWorkflow response.
struct PropagateCareGoalWorkflowStatusRecord {
    var status: String
    var correlationID: String
    var subject: String
}

/// Where PropagateCareGoalWorkflowStatus hands each record.
protocol PropagateCareGoalWorkflowStatusDestination {
    func deliver(_ rec: PropagateCareGoalWorkflowStatusRecord) async throws
}

/// Passes records to acme.prescriptions.v1.PrescriptionQueryService.
struct PropagateCareGoalWorkflowStatusPrescriptionQuery: PropagateCareGoalWorkflowStatusDestination {
    let client: Acme_Prescriptions_V1_PrescriptionQueryService.Client<MeshTransport>

    func deliver(_ rec: PropagateCareGoalWorkflowStatusRecord) async throws {
        _ = try await client.suggestPrescriptions(.with {
            $0.filter.region = rec.subject
        })
    }
}

/// Passes records to acme.payroll.v1.PayRunQueryService.
struct PropagateCareGoalWorkflowStatusPayRunQuery: PropagateCareGoalWorkflowStatusDestination {
    let client: Acme_Payroll_V1_PayRunQueryService.Client<MeshTransport>

    func deliver(_ rec: PropagateCareGoalWorkflowStatusRecord) async throws {
        let request = Acme_Payroll_V1_PeekPayRunRequest.with {
            $0.payRunID = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.peekPayRun(request)
        }
    }
}

/// Reads acme.careplans.v1.CareGoalWorkflowService/AdvanceCareGoalWorkflow and hands what it keeps to the sink of its kind.
enum PropagateCareGoalWorkflowStatus {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Careplans_V1_CareGoalWorkflowService.Client(wrapping: mesh)
        let response = try await reader.advanceCareGoalWorkflow(.with { $0.careGoalID = "main-propagate-care-goal-workflow-status" })
        let row = PropagateCareGoalWorkflowStatusRecord(
            status: response.outcome.status,
            correlationID: response.result.correlationID,
            subject: response.careGoal.subject
        )
        let sinks: [String: any PropagateCareGoalWorkflowStatusDestination] = [
            "prescription-query": PropagateCareGoalWorkflowStatusPrescriptionQuery(client: Acme_Prescriptions_V1_PrescriptionQueryService.Client(wrapping: mesh)),
            "pay-run-query": PropagateCareGoalWorkflowStatusPayRunQuery(client: Acme_Payroll_V1_PayRunQueryService.Client(wrapping: mesh)),
        ]
        for (kind, sink) in sinks {
            if kind != "prescription-query" {
                continue
            }
            try await sink.deliver(row)
        }
    }
}
