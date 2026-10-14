import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SyncBudgetsStatus keeps of each CountBudgets response.
struct SyncBudgetsStatusRecord {
    var status: String
    var message: String
    var correlationID: String
}

/// Where SyncBudgetsStatus hands each record.
protocol SyncBudgetsStatusTarget {
    func send(_ rec: SyncBudgetsStatusRecord) async throws
}

/// Writes records to acme.shows.v1.ShowQueryService.
struct SyncBudgetsStatusShowQuery: SyncBudgetsStatusTarget {
    let client: Acme_Shows_V1_ShowQueryService.Client<MeshTransport>

    func send(_ rec: SyncBudgetsStatusRecord) async throws {
        _ = try await client.summarizeShows(.with {
            $0.details.cron = rec.correlationID
            $0.reason = rec.message
            $0.showID = rec.status
        })
    }
}

/// Sends records to acme.careplans.v1.CareGoalQueryService.
struct SyncBudgetsStatusCareGoalQuery: SyncBudgetsStatusTarget {
    let client: Acme_Careplans_V1_CareGoalQueryService.Client<MeshTransport>

    func send(_ rec: SyncBudgetsStatusRecord) async throws {
        let request = Acme_Careplans_V1_SuggestCareGoalsRequest.with {
            $0.page.pageToken = rec.correlationID
            $0.filter.region = rec.message
            $0.orderBy = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.suggestCareGoals(request)
        }
    }
}

/// Sends records to acme.featureflags.v1.FeatureFlagValidationService.
struct SyncBudgetsStatusFeatureFlagValidation: SyncBudgetsStatusTarget {
    let client: Acme_Featureflags_V1_FeatureFlagValidationService.Client<MeshTransport>

    func send(_ rec: SyncBudgetsStatusRecord) async throws {
        _ = try await client.validateFeatureFlag(.with {
            $0.featureFlag.featureFlagID = rec.correlationID
            $0.details.locale = rec.message
            $0.reason = rec.status
        })
    }
}

/// Sends records to acme.prescriptions.v1.MedicationReportingService.
struct SyncBudgetsStatusMedicationReporting: SyncBudgetsStatusTarget {
    let client: Acme_Prescriptions_V1_MedicationReportingService.Client<MeshTransport>

    func send(_ rec: SyncBudgetsStatusRecord) async throws {
        _ = try await client.listMedicationReports(.with {
            $0.orderBy = rec.status
            $0.filter.query = rec.message
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct SyncBudgetsStatusLogOnly: SyncBudgetsStatusTarget {
    let logger = Logger(label: "acme.sync-budgets-status")

    func send(_ rec: SyncBudgetsStatusRecord) async throws {
        logger.info("No sink for record", metadata: ["status": .string(rec.status)])
    }
}

/// Reads acme.budgeting.v1.BudgetQueryService/CountBudgets and hands what it keeps to the sink of its kind.
enum SyncBudgetsStatus {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Budgeting_V1_BudgetQueryService.Client(wrapping: mesh)
        let reply = try await reader.countBudgets(.with { $0.orderBy = "current-sync-budgets-status" })
        let record = SyncBudgetsStatusRecord(
            status: reply.result.status,
            message: reply.result.message,
            correlationID: reply.result.correlationID
        )
        try await deliver("feature-flag-validation", record, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: SyncBudgetsStatusRecord, _ mesh: MeshClient) async throws {
        var sink: any SyncBudgetsStatusTarget = SyncBudgetsStatusLogOnly()
        switch kind {
        case "show-query":
            sink = SyncBudgetsStatusShowQuery(client: Acme_Shows_V1_ShowQueryService.Client(wrapping: mesh))
        case "care-goal-query":
            sink = SyncBudgetsStatusCareGoalQuery(client: Acme_Careplans_V1_CareGoalQueryService.Client(wrapping: mesh))
        case "feature-flag-validation":
            sink = SyncBudgetsStatusFeatureFlagValidation(client: Acme_Featureflags_V1_FeatureFlagValidationService.Client(wrapping: mesh))
        case "medication-reporting":
            sink = SyncBudgetsStatusMedicationReporting(client: Acme_Prescriptions_V1_MedicationReportingService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.send(rec)
    }
}
