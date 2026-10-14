import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What MirrorVenueID keeps of each DeleteVenue response.
struct MirrorVenueIDRecord {
    var correlationID: String
    var message: String
    var status: String
}

/// Where MirrorVenueID hands each record.
protocol MirrorVenueIDSink {
    func apply(_ rec: MirrorVenueIDRecord) async throws
}

/// Sends records to acme.careplans.v1.VitalLifecycleService.
struct MirrorVenueIDVitalLifecycle: MirrorVenueIDSink {
    let client: Acme_Careplans_V1_VitalLifecycleService.Client<MeshTransport>

    func apply(_ rec: MirrorVenueIDRecord) async throws {
        _ = try await client.suspendVital(.with {
            $0.vitalID = rec.correlationID
        })
    }
}

/// Passes records to acme.telehealth.v1.VisitNoteWorkflowService.
struct MirrorVenueIDVisitNoteWorkflow: MirrorVenueIDSink {
    let client: Acme_Telehealth_V1_VisitNoteWorkflowService.Client<MeshTransport>

    func apply(_ rec: MirrorVenueIDRecord) async throws {
        let request = Acme_Telehealth_V1_ResumeVisitNoteWorkflowRequest.with {
            $0.details.step = rec.message
            $0.details.initiatedBy = rec.status
            $0.reason = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.resumeVisitNoteWorkflow(request)
        }
    }
}

/// Passes records to acme.metrics.v1.MetricSeriesQueryService.
struct MirrorVenueIDMetricSeriesQuery: MirrorVenueIDSink {
    let client: Acme_Metrics_V1_MetricSeriesQueryService.Client<MeshTransport>

    func apply(_ rec: MirrorVenueIDRecord) async throws {
        _ = try await client.suggestMetricSerieses(.with {
            $0.orderBy = rec.message
            $0.filter.ownerID = rec.status
            $0.page.pageToken = rec.correlationID
        })
    }
}

/// Reads acme.venues.v1.VenueService/DeleteVenue and hands what it keeps to the sink of its kind.
enum MirrorVenueID {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Venues_V1_VenueService.Client(wrapping: mesh)
        let response = try await upstream.deleteVenue(.with { $0.reason = "main-mirror-venue-id" })
        let entry = MirrorVenueIDRecord(
            correlationID: response.result.correlationID,
            message: Kit.Text.normalize(response.result.message),
            status: Kit.Text.normalize(response.result.status)
        )
        let sinks: [String: any MirrorVenueIDSink] = [
            "vital-lifecycle": MirrorVenueIDVitalLifecycle(client: Acme_Careplans_V1_VitalLifecycleService.Client(wrapping: mesh)),
            "visit-note-workflow": MirrorVenueIDVisitNoteWorkflow(client: Acme_Telehealth_V1_VisitNoteWorkflowService.Client(wrapping: mesh)),
            "metric-series-query": MirrorVenueIDMetricSeriesQuery(client: Acme_Metrics_V1_MetricSeriesQueryService.Client(wrapping: mesh)),
        ]
        for (kind, sink) in sinks {
            if kind != "visit-note-workflow" {
                continue
            }
            try await sink.apply(entry)
        }
    }
}
