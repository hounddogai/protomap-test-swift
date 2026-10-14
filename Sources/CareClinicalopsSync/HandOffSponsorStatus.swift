import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What HandOffSponsorStatus keeps of each LookupSponsor response.
struct HandOffSponsorStatusRecord {
    var status: String
    var correlationID: String
    var sponsorID: String
}

/// Where HandOffSponsorStatus hands each record.
protocol HandOffSponsorStatusSink {
    func apply(_ rec: HandOffSponsorStatusRecord) async throws
}

/// Passes records to acme.metrics.v1.MetricSeriesQueryService.
struct HandOffSponsorStatusMetricSeriesQuery: HandOffSponsorStatusSink {
    let client: Acme_Metrics_V1_MetricSeriesQueryService.Client<MeshTransport>

    func apply(_ rec: HandOffSponsorStatusRecord) async throws {
        _ = try await client.lookupMetricSeries(.with {
            $0.metricSeriesID = rec.status
        })
    }
}

/// Passes records to acme.patients.v1.AllergyWorkflowService.
struct HandOffSponsorStatusAllergyWorkflow: HandOffSponsorStatusSink {
    let client: Acme_Patients_V1_AllergyWorkflowService.Client<MeshTransport>

    func apply(_ rec: HandOffSponsorStatusRecord) async throws {
        let request = Acme_Patients_V1_PauseAllergyWorkflowRequest.with {
            $0.allergy.kind = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.pauseAllergyWorkflow(request)
        }
    }
}

/// Reads acme.sponsorships.v1.SponsorQueryService/LookupSponsor and hands what it keeps to the sink of its kind.
enum HandOffSponsorStatus {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Sponsorships_V1_SponsorQueryService.Client(wrapping: mesh)
        let reply = try await origin.lookupSponsor(.with { $0.sponsorID = "main-hand-off-sponsor-status" })
        let entry = HandOffSponsorStatusRecord(
            status: reply.result.status,
            correlationID: reply.result.correlationID,
            sponsorID: reply.sponsor.sponsorID
        )
        let sinks: [String: any HandOffSponsorStatusSink] = [
            "metric-series-query": HandOffSponsorStatusMetricSeriesQuery(client: Acme_Metrics_V1_MetricSeriesQueryService.Client(wrapping: mesh)),
            "allergy-workflow": HandOffSponsorStatusAllergyWorkflow(client: Acme_Patients_V1_AllergyWorkflowService.Client(wrapping: mesh)),
        ]
        try await route("metric-series-query", entry, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: HandOffSponsorStatusRecord, _ sinks: [String: any HandOffSponsorStatusSink]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.apply(rec)
    }
}
