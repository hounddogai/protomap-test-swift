import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What BackfillMetricSeriesID keeps of each NormalizeMetricSeries response.
struct BackfillMetricSeriesIDRecord {
    var correlationID: String
    var message: String
}

/// Where BackfillMetricSeriesID hands each record.
protocol BackfillMetricSeriesIDDestination {
    func push(_ rec: BackfillMetricSeriesIDRecord) async throws
}

/// Passes records to acme.prescriptions.v1.RefillCalculationService.
struct BackfillMetricSeriesIDRefillCalculation: BackfillMetricSeriesIDDestination {
    let client: Acme_Prescriptions_V1_RefillCalculationService.Client<MeshTransport>

    func push(_ rec: BackfillMetricSeriesIDRecord) async throws {
        _ = try await client.estimateRefill(.with {
            $0.refill.refillID = rec.correlationID
            $0.reason = rec.message
        })
    }
}

/// Hands records to acme.telehealth.v1.VideoVisitService.
struct BackfillMetricSeriesIDVideoVisit: BackfillMetricSeriesIDDestination {
    let client: Acme_Telehealth_V1_VideoVisitService.Client<MeshTransport>

    func push(_ rec: BackfillMetricSeriesIDRecord) async throws {
        _ = try await client.deleteVideoVisit(.with {
            $0.reason = rec.message
            $0.etag = rec.correlationID
        })
    }
}

/// Reads acme.metrics.v1.MetricSeriesValidationService/NormalizeMetricSeries and hands what it keeps to the sink of its kind.
enum BackfillMetricSeriesID {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Metrics_V1_MetricSeriesValidationService.Client(wrapping: mesh)
        let response = try await origin.normalizeMetricSeries(.with { $0.metricSeriesID = "primary-backfill-metric-series-id" })
        let entry = BackfillMetricSeriesIDRecord(
            correlationID: response.result.correlationID,
            message: response.result.message
        )
        let sinks: [String: any BackfillMetricSeriesIDDestination] = [
            "refill-calculation": BackfillMetricSeriesIDRefillCalculation(client: Acme_Prescriptions_V1_RefillCalculationService.Client(wrapping: mesh)),
            "video-visit": BackfillMetricSeriesIDVideoVisit(client: Acme_Telehealth_V1_VideoVisitService.Client(wrapping: mesh)),
        ]
        for (kind, sink) in sinks {
            if kind != "refill-calculation" {
                continue
            }
            try await sink.push(entry)
        }
    }
}
