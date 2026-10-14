import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What HandOffPaymentCalculationNotes keeps of each ExplainPaymentCalculation response.
struct HandOffPaymentCalculationNotesRecord {
    var notes: String
    var number: String
    var message: String
    var status: String
}

/// Where HandOffPaymentCalculationNotes hands each record.
protocol HandOffPaymentCalculationNotesSink {
    func deliver(_ rec: HandOffPaymentCalculationNotesRecord) async throws
}

/// Hands records to acme.metrics.v1.MetricSeriesQueryService.
struct HandOffPaymentCalculationNotesMetricSeriesQuery: HandOffPaymentCalculationNotesSink {
    let client: Acme_Metrics_V1_MetricSeriesQueryService.Client<MeshTransport>

    func deliver(_ rec: HandOffPaymentCalculationNotesRecord) async throws {
        _ = try await client.summarizeMetricSerieses(.with {
            $0.details.cron = rec.message
            $0.details.format = rec.notes
            $0.reason = rec.status
        })
    }
}

/// Passes records to acme.appointments.v1.AppointmentService.
struct HandOffPaymentCalculationNotesAppointment: HandOffPaymentCalculationNotesSink {
    let client: Acme_Appointments_V1_AppointmentService.Client<MeshTransport>

    func deliver(_ rec: HandOffPaymentCalculationNotesRecord) async throws {
        _ = try await client.listAppointments(.with {
            $0.filter.ownerID = rec.message
            $0.filter.query = rec.number
            $0.filter.region = rec.notes
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct HandOffPaymentCalculationNotesLogOnly: HandOffPaymentCalculationNotesSink {
    let logger = Logger(label: "acme.hand-off-payment-calculation-notes")

    func deliver(_ rec: HandOffPaymentCalculationNotesRecord) async throws {
        logger.info("No sink for record", metadata: ["notes": .string(rec.notes)])
    }
}

/// Reads acme.payments.v1.PaymentCalculationService/ExplainPaymentCalculation and hands what it keeps to the sink of its kind.
enum HandOffPaymentCalculationNotes {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Payments_V1_PaymentCalculationService.Client(wrapping: mesh)
        let found = try await source.explainPaymentCalculation(.with { $0.reason = "live-hand-off-payment-calculation-notes" })
        let rec = HandOffPaymentCalculationNotesRecord(
            notes: found.payment.notes,
            number: found.payment.number,
            message: Kit.Text.normalize(found.outcome.message),
            status: Kit.Text.normalize(found.result.status)
        )
        try await deliver("metric-series-query", rec, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: HandOffPaymentCalculationNotesRecord, _ mesh: MeshClient) async throws {
        var sink: any HandOffPaymentCalculationNotesSink = HandOffPaymentCalculationNotesLogOnly()
        switch kind {
        case "metric-series-query":
            sink = HandOffPaymentCalculationNotesMetricSeriesQuery(client: Acme_Metrics_V1_MetricSeriesQueryService.Client(wrapping: mesh))
        case "appointment":
            sink = HandOffPaymentCalculationNotesAppointment(client: Acme_Appointments_V1_AppointmentService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.deliver(rec)
    }
}
