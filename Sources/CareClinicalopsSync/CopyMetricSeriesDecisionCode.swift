import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CopyMetricSeriesDecisionCode keeps of each ExplainMetricSeriesDecision response.
struct CopyMetricSeriesDecisionCodeRecord {
    var code: String
    var status: String
    var message: String
    var correlationID: String
}

/// Where CopyMetricSeriesDecisionCode hands each record.
protocol CopyMetricSeriesDecisionCodeDestination {
    func write(_ rec: CopyMetricSeriesDecisionCodeRecord) async throws
}

/// Hands records to acme.patients.v1.MedicalRecordLifecycleService.
struct CopyMetricSeriesDecisionCodeMedicalRecordLifecycle: CopyMetricSeriesDecisionCodeDestination {
    let client: Acme_Patients_V1_MedicalRecordLifecycleService.Client<MeshTransport>

    func write(_ rec: CopyMetricSeriesDecisionCodeRecord) async throws {
        _ = try await client.suspendMedicalRecord(.with {
            $0.medicalRecordID = rec.status
        })
    }
}

/// Hands records to acme.compliance.v1.ComplianceCaseService.
struct CopyMetricSeriesDecisionCodeComplianceCase: CopyMetricSeriesDecisionCodeDestination {
    let client: Acme_Compliance_V1_ComplianceCaseService.Client<MeshTransport>

    func write(_ rec: CopyMetricSeriesDecisionCodeRecord) async throws {
        _ = try await client.listComplianceCases(.with {
            $0.filter.ownerID = rec.correlationID
            $0.filter.region = rec.code
        })
    }
}

/// Sends records to acme.telematics.v1.TelemetryReadingCalculationService.
struct CopyMetricSeriesDecisionCodeTelemetryReadingCalculation: CopyMetricSeriesDecisionCodeDestination {
    let client: Acme_Telematics_V1_TelemetryReadingCalculationService.Client<MeshTransport>

    func write(_ rec: CopyMetricSeriesDecisionCodeRecord) async throws {
        _ = try await client.compareTelemetryReadingOptions(.with {
            $0.telemetryReading.kind = rec.code
            $0.details.currencyCode = rec.message
        })
    }
}

/// Reads acme.metrics.v1.MetricSeriesValidationService/ExplainMetricSeriesDecision and hands what it keeps to the sink of its kind.
enum CopyMetricSeriesDecisionCode {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Metrics_V1_MetricSeriesValidationService.Client(wrapping: mesh)
        let reply = try await source.explainMetricSeriesDecision(.with { $0.metricSeriesID = "nightly-copy-metric-series-decision-code" })
        let entry = CopyMetricSeriesDecisionCodeRecord(
            code: reply.metricSeries.code,
            status: reply.result.status,
            message: reply.result.message,
            correlationID: reply.result.correlationID
        )
        let sinks: [String: any CopyMetricSeriesDecisionCodeDestination] = [
            "medical-record-lifecycle": CopyMetricSeriesDecisionCodeMedicalRecordLifecycle(client: Acme_Patients_V1_MedicalRecordLifecycleService.Client(wrapping: mesh)),
            "compliance-case": CopyMetricSeriesDecisionCodeComplianceCase(client: Acme_Compliance_V1_ComplianceCaseService.Client(wrapping: mesh)),
            "telemetry-reading-calculation": CopyMetricSeriesDecisionCodeTelemetryReadingCalculation(client: Acme_Telematics_V1_TelemetryReadingCalculationService.Client(wrapping: mesh)),
        ]
        guard let sink = sinks[ProcessInfo.processInfo.environment["COPY_METRIC_SERIES_DECISION_CODE_TARGET"] ?? ""] else {
            return
        }
        try await sink.write(entry)
    }
}
