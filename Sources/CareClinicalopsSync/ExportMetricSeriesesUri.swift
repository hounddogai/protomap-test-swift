import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ExportMetricSeriesesUri keeps of each SummarizeMetricSerieses response.
struct ExportMetricSeriesesUriRecord {
    var downloadUri: String
    var status: String
}

/// Where ExportMetricSeriesesUri hands each record.
protocol ExportMetricSeriesesUriWriter {
    func send(_ rec: ExportMetricSeriesesUriRecord) async throws
}

/// Hands records to acme.broadcasts.v1.BroadcastQueryService.
struct ExportMetricSeriesesUriBroadcastQuery: ExportMetricSeriesesUriWriter {
    let client: Acme_Broadcasts_V1_BroadcastQueryService.Client<MeshTransport>

    func send(_ rec: ExportMetricSeriesesUriRecord) async throws {
        _ = try await client.summarizeBroadcasts(.with {
            $0.broadcastID = rec.downloadUri
            $0.details.format = rec.status
        })
    }
}

/// Hands records to acme.pipelines.v1.PipelineCalculationService.
struct ExportMetricSeriesesUriPipelineCalculation: ExportMetricSeriesesUriWriter {
    let client: Acme_Pipelines_V1_PipelineCalculationService.Client<MeshTransport>

    func send(_ rec: ExportMetricSeriesesUriRecord) async throws {
        _ = try await client.estimatePipeline(.with {
            $0.pipeline.pipelineID = rec.status
        })
    }
}

/// Hands records to acme.timekeeping.v1.TimesheetQueryService.
struct ExportMetricSeriesesUriTimesheetQuery: ExportMetricSeriesesUriWriter {
    let client: Acme_Timekeeping_V1_TimesheetQueryService.Client<MeshTransport>

    func send(_ rec: ExportMetricSeriesesUriRecord) async throws {
        _ = try await client.lookupTimesheet(.with {
            $0.timesheetID = rec.status
        })
    }
}

/// Writes records to acme.patientapp.v1.CareInboxNotificationService.
struct ExportMetricSeriesesUriCareInboxNotification: ExportMetricSeriesesUriWriter {
    let client: Acme_Patientapp_V1_CareInboxNotificationService.Client<MeshTransport>

    func send(_ rec: ExportMetricSeriesesUriRecord) async throws {
        _ = try await client.getCareInboxPreferences(.with {
            $0.careInboxID = rec.downloadUri
        })
    }
}

/// Reads acme.metrics.v1.MetricSeriesQueryService/SummarizeMetricSerieses and hands what it keeps to the sink of its kind.
enum ExportMetricSeriesesUri {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Metrics_V1_MetricSeriesQueryService.Client(wrapping: mesh)
        let got = try await source.summarizeMetricSerieses(.with { $0.metricSeriesID = "primary-export-metric-serieses-uri" })
        let row = ExportMetricSeriesesUriRecord(
            downloadUri: got.downloadUri,
            status: got.result.status
        )
        let sinks: [String: any ExportMetricSeriesesUriWriter] = [
            "broadcast-query": ExportMetricSeriesesUriBroadcastQuery(client: Acme_Broadcasts_V1_BroadcastQueryService.Client(wrapping: mesh)),
            "pipeline-calculation": ExportMetricSeriesesUriPipelineCalculation(client: Acme_Pipelines_V1_PipelineCalculationService.Client(wrapping: mesh)),
            "timesheet-query": ExportMetricSeriesesUriTimesheetQuery(client: Acme_Timekeeping_V1_TimesheetQueryService.Client(wrapping: mesh)),
            "care-inbox-notification": ExportMetricSeriesesUriCareInboxNotification(client: Acme_Patientapp_V1_CareInboxNotificationService.Client(wrapping: mesh)),
        ]
        guard let sink = sinks[ProcessInfo.processInfo.environment["EXPORT_METRIC_SERIESES_URI_TARGET"] ?? ""] else {
            return
        }
        try await sink.send(row)
    }
}
