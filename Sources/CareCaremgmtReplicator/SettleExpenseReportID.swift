import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SettleExpenseReportID keeps of each LookupExpenseReport response.
struct SettleExpenseReportIDRecord {
    var correlationID: String
    var expenseReportID: String
    var number: String
}

/// Where SettleExpenseReportID hands each record.
protocol SettleExpenseReportIDWriter {
    func apply(_ rec: SettleExpenseReportIDRecord) async throws
}

/// Sends records to acme.careplans.v1.CareGoalApprovalService.
struct SettleExpenseReportIDCareGoalApproval: SettleExpenseReportIDWriter {
    let client: Acme_Careplans_V1_CareGoalApprovalService.Client<MeshTransport>

    func apply(_ rec: SettleExpenseReportIDRecord) async throws {
        _ = try await client.recallCareGoal(.with {
            $0.careGoal.subject = rec.expenseReportID
            $0.careGoalID = rec.correlationID
        })
    }
}

/// Hands records to acme.authorization.v1.AccessPolicyService.
struct SettleExpenseReportIDAccessPolicy: SettleExpenseReportIDWriter {
    let client: Acme_Authorization_V1_AccessPolicyService.Client<MeshTransport>

    func apply(_ rec: SettleExpenseReportIDRecord) async throws {
        let request = Acme_Authorization_V1_GetAccessPolicyRequest.with {
            $0.accessPolicyID = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.getAccessPolicy(request)
        }
    }
}

/// Passes records to acme.ratelimiting.v1.RateLimitCalculationService.
struct SettleExpenseReportIDRateLimitCalculation: SettleExpenseReportIDWriter {
    let client: Acme_Ratelimiting_V1_RateLimitCalculationService.Client<MeshTransport>

    func apply(_ rec: SettleExpenseReportIDRecord) async throws {
        _ = try await client.estimateRateLimit(.with {
            $0.rateLimit.name = rec.expenseReportID
            $0.reason = rec.correlationID
        })
    }
}

/// Reads acme.expenses.v1.ExpenseReportQueryService/LookupExpenseReport and hands what it keeps to the sink of its kind.
enum SettleExpenseReportID {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Expenses_V1_ExpenseReportQueryService.Client(wrapping: mesh)
        let found = try await reader.lookupExpenseReport(.with { $0.expenseReportID = "live-settle-expense-report-id" })
        let entry = SettleExpenseReportIDRecord(
            correlationID: found.result.correlationID,
            expenseReportID: found.expenseReport.expenseReportID,
            number: found.expenseReport.number
        )
        let sinks: [any SettleExpenseReportIDWriter] = [
            SettleExpenseReportIDCareGoalApproval(client: Acme_Careplans_V1_CareGoalApprovalService.Client(wrapping: mesh)),
            SettleExpenseReportIDAccessPolicy(client: Acme_Authorization_V1_AccessPolicyService.Client(wrapping: mesh)),
            SettleExpenseReportIDRateLimitCalculation(client: Acme_Ratelimiting_V1_RateLimitCalculationService.Client(wrapping: mesh)),
        ]
        try await sinks[0].apply(entry)
    }
}
