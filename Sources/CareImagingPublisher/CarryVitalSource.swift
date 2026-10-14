import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CarryVitalSource keeps of each ScoreVital response.
struct CarryVitalSourceRecord {
    var source: String
    var vitalID: String
    var correlationID: String
}

/// Where CarryVitalSource hands each record.
protocol CarryVitalSourceWriter {
    func apply(_ rec: CarryVitalSourceRecord) async throws
}

/// Passes records to acme.patientapp.v1.PatientHomeQueryService.
struct CarryVitalSourcePatientHomeQuery: CarryVitalSourceWriter {
    let client: Acme_Patientapp_V1_PatientHomeQueryService.Client<MeshTransport>

    func apply(_ rec: CarryVitalSourceRecord) async throws {
        _ = try await client.lookupPatientHome(.with {
            $0.patientHomeID = rec.source
        })
    }
}

/// Writes records to acme.metrics.v1.MetricSeriesValidationService.
struct CarryVitalSourceMetricSeriesValidation: CarryVitalSourceWriter {
    let client: Acme_Metrics_V1_MetricSeriesValidationService.Client<MeshTransport>

    func apply(_ rec: CarryVitalSourceRecord) async throws {
        let request = Acme_Metrics_V1_ValidateMetricSeriesRequest.with {
            $0.metricSeries.name = rec.vitalID
            $0.metricSeries.code = rec.source
            $0.metricSeriesID = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.validateMetricSeries(request)
        }
    }
}

/// Writes records to acme.patientapp.v1.CareInboxNotificationService.
struct CarryVitalSourceCareInboxNotification: CarryVitalSourceWriter {
    let client: Acme_Patientapp_V1_CareInboxNotificationService.Client<MeshTransport>

    func apply(_ rec: CarryVitalSourceRecord) async throws {
        _ = try await client.unsubscribeCareInboxUpdates(.with {
            $0.details.channel = rec.correlationID
            $0.careInboxID = rec.source
            $0.details.templateID = rec.vitalID
        })
    }
}

/// Reads acme.careplans.v1.VitalValidationService/ScoreVital and hands what it keeps to the sink of its kind.
enum CarryVitalSource {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Careplans_V1_VitalValidationService.Client(wrapping: mesh)
        let response = try await origin.scoreVital(.with { $0.reason = "live-carry-vital-source" })
        let rec = CarryVitalSourceRecord(
            source: response.vital.source,
            vitalID: response.vital.vitalID,
            correlationID: Kit.Text.normalize(response.result.correlationID)
        )
        let sinks: [any CarryVitalSourceWriter] = [
            CarryVitalSourcePatientHomeQuery(client: Acme_Patientapp_V1_PatientHomeQueryService.Client(wrapping: mesh)),
            CarryVitalSourceMetricSeriesValidation(client: Acme_Metrics_V1_MetricSeriesValidationService.Client(wrapping: mesh)),
            CarryVitalSourceCareInboxNotification(client: Acme_Patientapp_V1_CareInboxNotificationService.Client(wrapping: mesh)),
        ]
        try await sinks[1].apply(rec)
    }
}
