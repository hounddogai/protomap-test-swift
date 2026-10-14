import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ReplayExpenseReportsMessage keeps of each ResolveExpenseReports response.
struct ReplayExpenseReportsMessageRecord {
    var message: String
    var status: String
    var nextPageToken: String
    var correlationID: String
}

/// Where ReplayExpenseReportsMessage hands each record.
protocol ReplayExpenseReportsMessageSink {
    func send(_ rec: ReplayExpenseReportsMessageRecord) async throws
}

/// Writes records to acme.telehealth.v1.TriageLifecycleService.
struct ReplayExpenseReportsMessageTriageLifecycle: ReplayExpenseReportsMessageSink {
    let client: Acme_Telehealth_V1_TriageLifecycleService.Client<MeshTransport>

    func send(_ rec: ReplayExpenseReportsMessageRecord) async throws {
        let request = Acme_Telehealth_V1_ActivateTriageRequest.with {
            $0.triageID = rec.message
            $0.reason = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.activateTriage(request)
        }
    }
}

/// Hands records to acme.careplans.v1.VitalValidationService.
struct ReplayExpenseReportsMessageVitalValidation: ReplayExpenseReportsMessageSink {
    let client: Acme_Careplans_V1_VitalValidationService.Client<MeshTransport>

    func send(_ rec: ReplayExpenseReportsMessageRecord) async throws {
        _ = try await client.lintVitals(.with {
            $0.vital.vitalID = rec.nextPageToken
            $0.details.locale = rec.message
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct ReplayExpenseReportsMessageLogOnly: ReplayExpenseReportsMessageSink {
    let logger = Logger(label: "acme.replay-expense-reports-message")

    func send(_ rec: ReplayExpenseReportsMessageRecord) async throws {
        logger.info("No sink for record", metadata: ["message": .string(rec.message)])
    }
}

/// Reads acme.expenses.v1.ExpenseReportQueryService/ResolveExpenseReports and hands what it keeps to the sink of its kind.
enum ReplayExpenseReportsMessage {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Expenses_V1_ExpenseReportQueryService.Client(wrapping: mesh)
        let got = try await reader.resolveExpenseReports(.init())
        let record = ReplayExpenseReportsMessageRecord(
            message: got.result.message,
            status: got.result.status,
            nextPageToken: Kit.Text.normalize(got.pageInfo.nextPageToken),
            correlationID: got.result.correlationID
        )
        try await deliver("vital-validation", record, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: ReplayExpenseReportsMessageRecord, _ mesh: MeshClient) async throws {
        var sink: any ReplayExpenseReportsMessageSink = ReplayExpenseReportsMessageLogOnly()
        switch kind {
        case "triage-lifecycle":
            sink = ReplayExpenseReportsMessageTriageLifecycle(client: Acme_Telehealth_V1_TriageLifecycleService.Client(wrapping: mesh))
        case "vital-validation":
            sink = ReplayExpenseReportsMessageVitalValidation(client: Acme_Careplans_V1_VitalValidationService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.send(rec)
    }
}
