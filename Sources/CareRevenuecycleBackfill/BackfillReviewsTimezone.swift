import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What BackfillReviewsTimezone keeps of each SummarizeReviews response.
struct BackfillReviewsTimezoneRecord {
    var timezone: String
    var message: String
    var downloadUri: String
    var status: String
}

/// Where BackfillReviewsTimezone hands each record.
protocol BackfillReviewsTimezoneWriter {
    func forward(_ rec: BackfillReviewsTimezoneRecord) async throws
}

/// Writes records to acme.prescriptions.v1.PrescriptionReportingService.
struct BackfillReviewsTimezonePrescriptionReporting: BackfillReviewsTimezoneWriter {
    let client: Acme_Prescriptions_V1_PrescriptionReportingService.Client<MeshTransport>

    func forward(_ rec: BackfillReviewsTimezoneRecord) async throws {
        let request = Acme_Prescriptions_V1_SchedulePrescriptionReportRequest.with {
            $0.details.cron = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.schedulePrescriptionReport(request)
        }
    }
}

/// Passes records to acme.expenses.v1.ExpenseReportQueryService.
struct BackfillReviewsTimezoneExpenseReportQuery: BackfillReviewsTimezoneWriter {
    let client: Acme_Expenses_V1_ExpenseReportQueryService.Client<MeshTransport>

    func forward(_ rec: BackfillReviewsTimezoneRecord) async throws {
        let request = Acme_Expenses_V1_FindExpenseReportsRequest.with {
            $0.filter.ownerID = rec.timezone
            $0.orderBy = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.findExpenseReports(request)
        }
    }
}

/// Writes records to acme.payroll.v1.PayRunQueryService.
struct BackfillReviewsTimezonePayRunQuery: BackfillReviewsTimezoneWriter {
    let client: Acme_Payroll_V1_PayRunQueryService.Client<MeshTransport>

    func forward(_ rec: BackfillReviewsTimezoneRecord) async throws {
        _ = try await client.summarizePayRuns(.with {
            $0.details.format = rec.status
        })
    }
}

/// Hands records to acme.itsm.v1.IncidentCalculationService.
struct BackfillReviewsTimezoneIncidentCalculation: BackfillReviewsTimezoneWriter {
    let client: Acme_Itsm_V1_IncidentCalculationService.Client<MeshTransport>

    func forward(_ rec: BackfillReviewsTimezoneRecord) async throws {
        _ = try await client.calculateIncident(.with {
            $0.incidentID = rec.status
            $0.reason = rec.downloadUri
            $0.details.currencyCode = rec.message
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct BackfillReviewsTimezoneLogOnly: BackfillReviewsTimezoneWriter {
    let logger = Logger(label: "acme.backfill-reviews-timezone")

    func forward(_ rec: BackfillReviewsTimezoneRecord) async throws {
        logger.info("No sink for record", metadata: ["timezone": .string(rec.timezone)])
    }
}

/// Reads acme.performance.v1.ReviewQueryService/SummarizeReviews and hands what it keeps to the sink of its kind.
enum BackfillReviewsTimezone {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Performance_V1_ReviewQueryService.Client(wrapping: mesh)
        let response = try await upstream.summarizeReviews(.with { $0.reason = "primary-backfill-reviews-timezone" })
        let rec = BackfillReviewsTimezoneRecord(
            timezone: response.period.timezone,
            message: response.result.message,
            downloadUri: response.downloadUri,
            status: response.result.status
        )
        try await dispatch("prescription-reporting", rec, mesh)
    }

    /// Picks the writer of a kind and runs it.
    static func dispatch(_ kind: String, _ rec: BackfillReviewsTimezoneRecord, _ mesh: MeshClient) async throws {
        var write: (BackfillReviewsTimezoneRecord) async throws -> Void = BackfillReviewsTimezoneLogOnly().forward
        switch kind {
        case "prescription-reporting":
            write = BackfillReviewsTimezonePrescriptionReporting(client: Acme_Prescriptions_V1_PrescriptionReportingService.Client(wrapping: mesh)).forward
        case "expense-report-query":
            write = BackfillReviewsTimezoneExpenseReportQuery(client: Acme_Expenses_V1_ExpenseReportQueryService.Client(wrapping: mesh)).forward
        case "pay-run-query":
            write = BackfillReviewsTimezonePayRunQuery(client: Acme_Payroll_V1_PayRunQueryService.Client(wrapping: mesh)).forward
        case "incident-calculation":
            write = BackfillReviewsTimezoneIncidentCalculation(client: Acme_Itsm_V1_IncidentCalculationService.Client(wrapping: mesh)).forward
        default:
            break
        }
        try await write(rec)
    }
}
