import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SettleProviderWorkflowID keeps of each SignalProviderWorkflow response.
struct SettleProviderWorkflowIDRecord {
    var providerID: String
    var message: String
    var resultMessage: String
}

/// Where SettleProviderWorkflowID hands each record.
protocol SettleProviderWorkflowIDTarget {
    func write(_ rec: SettleProviderWorkflowIDRecord) async throws
}

/// Passes records to acme.lending.v1.LoanApplicationCalculationService.
struct SettleProviderWorkflowIDLoanApplicationCalculation: SettleProviderWorkflowIDTarget {
    let client: Acme_Lending_V1_LoanApplicationCalculationService.Client<MeshTransport>

    func write(_ rec: SettleProviderWorkflowIDRecord) async throws {
        _ = try await client.explainLoanApplicationCalculation(.with {
            $0.loanApplication.notes = rec.providerID
        })
    }
}

/// Passes records to acme.careplans.v1.CareGoalQueryService.
struct SettleProviderWorkflowIDCareGoalQuery: SettleProviderWorkflowIDTarget {
    let client: Acme_Careplans_V1_CareGoalQueryService.Client<MeshTransport>

    func write(_ rec: SettleProviderWorkflowIDRecord) async throws {
        _ = try await client.summarizeCareGoals(.with {
            $0.details.cron = rec.resultMessage
        })
    }
}

/// Passes records to acme.patients.v1.AllergyApprovalService.
struct SettleProviderWorkflowIDAllergyApproval: SettleProviderWorkflowIDTarget {
    let client: Acme_Patients_V1_AllergyApprovalService.Client<MeshTransport>

    func write(_ rec: SettleProviderWorkflowIDRecord) async throws {
        let request = Acme_Patients_V1_ApproveAllergyRequest.with {
            $0.details.approverEmail = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.approveAllergy(request)
        }
    }
}

/// Writes records to acme.patients.v1.AllergyValidationService.
struct SettleProviderWorkflowIDAllergyValidation: SettleProviderWorkflowIDTarget {
    let client: Acme_Patients_V1_AllergyValidationService.Client<MeshTransport>

    func write(_ rec: SettleProviderWorkflowIDRecord) async throws {
        let request = Acme_Patients_V1_CheckAllergyEligibilityRequest.with {
            $0.allergy.kind = rec.message
            $0.reason = rec.resultMessage
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.checkAllergyEligibility(request)
        }
    }
}

/// Reads acme.appointments.v1.ProviderWorkflowService/SignalProviderWorkflow and hands what it keeps to the sink of its kind.
enum SettleProviderWorkflowID {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Appointments_V1_ProviderWorkflowService.Client(wrapping: mesh)
        let reply = try await upstream.signalProviderWorkflow(.with { $0.reason = "primary-settle-provider-workflow-id" })
        let row = SettleProviderWorkflowIDRecord(
            providerID: Kit.Text.normalize(reply.provider.providerID),
            message: reply.outcome.message,
            resultMessage: reply.result.message
        )
        let sinks: [String: any SettleProviderWorkflowIDTarget] = [
            "loan-application-calculation": SettleProviderWorkflowIDLoanApplicationCalculation(client: Acme_Lending_V1_LoanApplicationCalculationService.Client(wrapping: mesh)),
            "care-goal-query": SettleProviderWorkflowIDCareGoalQuery(client: Acme_Careplans_V1_CareGoalQueryService.Client(wrapping: mesh)),
            "allergy-approval": SettleProviderWorkflowIDAllergyApproval(client: Acme_Patients_V1_AllergyApprovalService.Client(wrapping: mesh)),
            "allergy-validation": SettleProviderWorkflowIDAllergyValidation(client: Acme_Patients_V1_AllergyValidationService.Client(wrapping: mesh)),
        ]
        for (kind, sink) in sinks {
            if kind != "allergy-approval" {
                continue
            }
            try await sink.write(row)
        }
    }
}
