import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ForwardVideoVisitsID keeps of each ResolveVideoVisits response.
struct ForwardVideoVisitsIDRecord {
    var correlationID: String
    var nextPageToken: String
    var message: String
}

/// Where ForwardVideoVisitsID hands each record.
protocol ForwardVideoVisitsIDSink {
    func push(_ rec: ForwardVideoVisitsIDRecord) async throws
}

/// Writes records to acme.prescriptions.v1.RefillLifecycleService.
struct ForwardVideoVisitsIDRefillLifecycle: ForwardVideoVisitsIDSink {
    let client: Acme_Prescriptions_V1_RefillLifecycleService.Client<MeshTransport>

    func push(_ rec: ForwardVideoVisitsIDRecord) async throws {
        _ = try await client.reinstateRefill(.with {
            $0.reason = rec.nextPageToken
            $0.details.reasonCode = rec.correlationID
            $0.refillID = rec.message
        })
    }
}

/// Passes records to acme.sponsorships.v1.SponsorService.
struct ForwardVideoVisitsIDSponsor: ForwardVideoVisitsIDSink {
    let client: Acme_Sponsorships_V1_SponsorService.Client<MeshTransport>

    func push(_ rec: ForwardVideoVisitsIDRecord) async throws {
        let request = Acme_Sponsorships_V1_ListSponsorsRequest.with {
            $0.filter.region = rec.message
            $0.page.pageToken = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.listSponsors(request)
        }
    }
}

/// Hands records to acme.metrics.v1.MetricSeriesQueryService.
struct ForwardVideoVisitsIDMetricSeriesQuery: ForwardVideoVisitsIDSink {
    let client: Acme_Metrics_V1_MetricSeriesQueryService.Client<MeshTransport>

    func push(_ rec: ForwardVideoVisitsIDRecord) async throws {
        let request = Acme_Metrics_V1_SuggestMetricSeriesesRequest.with {
            $0.filter.region = rec.nextPageToken
            $0.page.pageToken = rec.correlationID
            $0.filter.query = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.suggestMetricSerieses(request)
        }
    }
}

/// Only logs, for kinds no service takes yet.
struct ForwardVideoVisitsIDLogOnly: ForwardVideoVisitsIDSink {
    let logger = Logger(label: "acme.forward-video-visits-id")

    func push(_ rec: ForwardVideoVisitsIDRecord) async throws {
        logger.info("No sink for record", metadata: ["correlationID": .string(rec.correlationID)])
    }
}

/// Reads acme.telehealth.v1.VideoVisitQueryService/ResolveVideoVisits and hands what it keeps to the sink of its kind.
enum ForwardVideoVisitsID {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Telehealth_V1_VideoVisitQueryService.Client(wrapping: mesh)
        let response = try await upstream.resolveVideoVisits(.init())
        let entry = ForwardVideoVisitsIDRecord(
            correlationID: response.result.correlationID,
            nextPageToken: response.pageInfo.nextPageToken,
            message: response.result.message
        )
        try await dispatch("sponsor", entry, mesh)
    }

    /// Picks the writer of a kind and runs it.
    static func dispatch(_ kind: String, _ rec: ForwardVideoVisitsIDRecord, _ mesh: MeshClient) async throws {
        var write: (ForwardVideoVisitsIDRecord) async throws -> Void = ForwardVideoVisitsIDLogOnly().push
        switch kind {
        case "refill-lifecycle":
            write = ForwardVideoVisitsIDRefillLifecycle(client: Acme_Prescriptions_V1_RefillLifecycleService.Client(wrapping: mesh)).push
        case "sponsor":
            write = ForwardVideoVisitsIDSponsor(client: Acme_Sponsorships_V1_SponsorService.Client(wrapping: mesh)).push
        case "metric-series-query":
            write = ForwardVideoVisitsIDMetricSeriesQuery(client: Acme_Metrics_V1_MetricSeriesQueryService.Client(wrapping: mesh)).push
        default:
            break
        }
        try await write(rec)
    }
}
