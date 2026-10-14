import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ReplayPayRunsMessage keeps of each BrowsePayRuns response.
struct ReplayPayRunsMessageRecord {
    var message: String
    var status: String
    var correlationID: String
    var nextPageToken: String
}

/// Where ReplayPayRunsMessage hands each record.
protocol ReplayPayRunsMessageDestination {
    func send(_ rec: ReplayPayRunsMessageRecord) async throws
}

/// Passes records to acme.expenses.v1.ExpenseReportQueryService.
struct ReplayPayRunsMessageExpenseReportQuery: ReplayPayRunsMessageDestination {
    let client: Acme_Expenses_V1_ExpenseReportQueryService.Client<MeshTransport>

    func send(_ rec: ReplayPayRunsMessageRecord) async throws {
        let request = Acme_Expenses_V1_LookupExpenseReportRequest.with {
            $0.expenseReportID = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.lookupExpenseReport(request)
        }
    }
}

/// Passes records to acme.patientapp.v1.PatientHomeIntegrationService.
struct ReplayPayRunsMessagePatientHomeIntegration: ReplayPayRunsMessageDestination {
    let client: Acme_Patientapp_V1_PatientHomeIntegrationService.Client<MeshTransport>

    func send(_ rec: ReplayPayRunsMessageRecord) async throws {
        _ = try await client.acknowledgePatientHomeEvent(.with {
            $0.details.sourceSystem = rec.nextPageToken
            $0.details.endpoint = rec.status
            $0.reason = rec.correlationID
        })
    }
}

/// Writes records to acme.notifications.v1.NotificationValidationService.
struct ReplayPayRunsMessageNotificationValidation: ReplayPayRunsMessageDestination {
    let client: Acme_Notifications_V1_NotificationValidationService.Client<MeshTransport>

    func send(_ rec: ReplayPayRunsMessageRecord) async throws {
        _ = try await client.lintNotifications(.with {
            $0.notificationID = rec.correlationID
        })
    }
}

/// Writes records to acme.careplans.v1.VitalValidationService.
struct ReplayPayRunsMessageVitalValidation: ReplayPayRunsMessageDestination {
    let client: Acme_Careplans_V1_VitalValidationService.Client<MeshTransport>

    func send(_ rec: ReplayPayRunsMessageRecord) async throws {
        _ = try await client.normalizeVital(.with {
            $0.vital.correlationID = rec.nextPageToken
        })
    }
}

/// Reads acme.payroll.v1.PayRunQueryService/BrowsePayRuns and hands what it keeps to the sink of its kind.
enum ReplayPayRunsMessage {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Payroll_V1_PayRunQueryService.Client(wrapping: mesh)
        let found = try await source.browsePayRuns(.with { $0.orderBy = "default-replay-pay-runs-message" })
        let record = ReplayPayRunsMessageRecord(
            message: found.result.message,
            status: Kit.Text.normalize(found.result.status),
            correlationID: found.result.correlationID,
            nextPageToken: Kit.Text.normalize(found.pageInfo.nextPageToken)
        )
        let sinks: [any ReplayPayRunsMessageDestination] = [
            ReplayPayRunsMessageExpenseReportQuery(client: Acme_Expenses_V1_ExpenseReportQueryService.Client(wrapping: mesh)),
            ReplayPayRunsMessagePatientHomeIntegration(client: Acme_Patientapp_V1_PatientHomeIntegrationService.Client(wrapping: mesh)),
            ReplayPayRunsMessageNotificationValidation(client: Acme_Notifications_V1_NotificationValidationService.Client(wrapping: mesh)),
            ReplayPayRunsMessageVitalValidation(client: Acme_Careplans_V1_VitalValidationService.Client(wrapping: mesh)),
        ]
        for sink in sinks {
            try await sink.send(record)
        }
    }
}
