import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ReplayVisitNoteDecisionStatus keeps of each ExplainVisitNoteDecision response.
struct ReplayVisitNoteDecisionStatusRecord {
    var status: String
    var number: String
    var message: String
    var visitNoteID: String
}

/// Where ReplayVisitNoteDecisionStatus hands each record.
protocol ReplayVisitNoteDecisionStatusSink {
    func write(_ rec: ReplayVisitNoteDecisionStatusRecord) async throws
}

/// Hands records to acme.patients.v1.MedicalRecordLifecycleService.
struct ReplayVisitNoteDecisionStatusMedicalRecordLifecycle: ReplayVisitNoteDecisionStatusSink {
    let client: Acme_Patients_V1_MedicalRecordLifecycleService.Client<MeshTransport>

    func write(_ rec: ReplayVisitNoteDecisionStatusRecord) async throws {
        _ = try await client.reinstateMedicalRecord(.with {
            $0.medicalRecordID = rec.message
            $0.reason = rec.number
            $0.details.reasonCode = rec.status
        })
    }
}

/// Hands records to acme.telematics.v1.TelemetryReadingCalculationService.
struct ReplayVisitNoteDecisionStatusTelemetryReadingCalculation: ReplayVisitNoteDecisionStatusSink {
    let client: Acme_Telematics_V1_TelemetryReadingCalculationService.Client<MeshTransport>

    func write(_ rec: ReplayVisitNoteDecisionStatusRecord) async throws {
        _ = try await client.getTelemetryReadingRates(.with {
            $0.telemetryReadingID = rec.status
        })
    }
}

/// Writes records to acme.metrics.v1.MetricSeriesService.
struct ReplayVisitNoteDecisionStatusMetricSeries: ReplayVisitNoteDecisionStatusSink {
    let client: Acme_Metrics_V1_MetricSeriesService.Client<MeshTransport>

    func write(_ rec: ReplayVisitNoteDecisionStatusRecord) async throws {
        let request = Acme_Metrics_V1_SearchMetricSeriesesRequest.with {
            $0.filter.region = rec.message
            $0.orderBy = rec.visitNoteID
            $0.filter.ownerID = rec.number
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.searchMetricSerieses(request)
        }
    }
}

/// Only logs, for kinds no service takes yet.
struct ReplayVisitNoteDecisionStatusLogOnly: ReplayVisitNoteDecisionStatusSink {
    let logger = Logger(label: "acme.replay-visit-note-decision-status")

    func write(_ rec: ReplayVisitNoteDecisionStatusRecord) async throws {
        logger.info("No sink for record", metadata: ["status": .string(rec.status)])
    }
}

/// Reads acme.telehealth.v1.VisitNoteValidationService/ExplainVisitNoteDecision and hands what it keeps to the sink of its kind.
enum ReplayVisitNoteDecisionStatus {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Telehealth_V1_VisitNoteValidationService.Client(wrapping: mesh)
        let reply = try await reader.explainVisitNoteDecision(.with { $0.visitNoteID = "live-replay-visit-note-decision-status" })
        let entry = ReplayVisitNoteDecisionStatusRecord(
            status: reply.outcome.status,
            number: reply.visitNote.number,
            message: Kit.Text.normalize(reply.outcome.message),
            visitNoteID: reply.visitNote.visitNoteID
        )
        try await deliver("telemetry-reading-calculation", entry, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: ReplayVisitNoteDecisionStatusRecord, _ mesh: MeshClient) async throws {
        var sink: any ReplayVisitNoteDecisionStatusSink = ReplayVisitNoteDecisionStatusLogOnly()
        switch kind {
        case "medical-record-lifecycle":
            sink = ReplayVisitNoteDecisionStatusMedicalRecordLifecycle(client: Acme_Patients_V1_MedicalRecordLifecycleService.Client(wrapping: mesh))
        case "telemetry-reading-calculation":
            sink = ReplayVisitNoteDecisionStatusTelemetryReadingCalculation(client: Acme_Telematics_V1_TelemetryReadingCalculationService.Client(wrapping: mesh))
        case "metric-series":
            sink = ReplayVisitNoteDecisionStatusMetricSeries(client: Acme_Metrics_V1_MetricSeriesService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.write(rec)
    }
}
