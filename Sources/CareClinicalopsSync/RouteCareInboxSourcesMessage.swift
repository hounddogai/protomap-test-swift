import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RouteCareInboxSourcesMessage keeps of each ListCareInboxSources response.
struct RouteCareInboxSourcesMessageRecord {
    var message: String
    var status: String
    var correlationID: String
}

/// Where RouteCareInboxSourcesMessage hands each record.
protocol RouteCareInboxSourcesMessageTarget {
    func apply(_ rec: RouteCareInboxSourcesMessageRecord) async throws
}

/// Passes records to acme.broadcasts.v1.BroadcastService.
struct RouteCareInboxSourcesMessageBroadcast: RouteCareInboxSourcesMessageTarget {
    let client: Acme_Broadcasts_V1_BroadcastService.Client<MeshTransport>

    func apply(_ rec: RouteCareInboxSourcesMessageRecord) async throws {
        _ = try await client.updateBroadcast(.with {
            $0.broadcast.broadcastID = rec.correlationID
        })
    }
}

/// Sends records to acme.metrics.v1.MetricSeriesQueryService.
struct RouteCareInboxSourcesMessageMetricSeriesQuery: RouteCareInboxSourcesMessageTarget {
    let client: Acme_Metrics_V1_MetricSeriesQueryService.Client<MeshTransport>

    func apply(_ rec: RouteCareInboxSourcesMessageRecord) async throws {
        _ = try await client.summarizeMetricSerieses(.with {
            $0.details.cron = rec.message
            $0.reason = rec.status
            $0.metricSeriesID = rec.correlationID
        })
    }
}

/// Reads acme.patientapp.v1.CareInboxIntegrationService/ListCareInboxSources and hands what it keeps to the sink of its kind.
enum RouteCareInboxSourcesMessage {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Patientapp_V1_CareInboxIntegrationService.Client(wrapping: mesh)
        let response = try await reader.listCareInboxSources(.with { $0.orderBy = "live-route-care-inbox-sources-message" })
        let entry = RouteCareInboxSourcesMessageRecord(
            message: response.result.message,
            status: Kit.Text.normalize(response.result.status),
            correlationID: response.result.correlationID
        )
        try await act("metric-series-query", entry, mesh)
    }

    /// Runs the action registered for a kind.
    static func act(_ kind: String, _ rec: RouteCareInboxSourcesMessageRecord, _ mesh: MeshClient) async throws {
        let actions: [String: () async throws -> Void] = [
            "broadcast": { try await RouteCareInboxSourcesMessageBroadcast(client: Acme_Broadcasts_V1_BroadcastService.Client(wrapping: mesh)).apply(rec) },
            "metric-series-query": { try await RouteCareInboxSourcesMessageMetricSeriesQuery(client: Acme_Metrics_V1_MetricSeriesQueryService.Client(wrapping: mesh)).apply(rec) },
        ]
        guard let action = actions[kind] else {
            throw Kit.Failure("no action for \(kind)")
        }
        try await action()
    }
}
