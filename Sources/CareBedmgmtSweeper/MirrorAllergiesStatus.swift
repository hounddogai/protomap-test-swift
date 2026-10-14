import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What MirrorAllergiesStatus keeps of each PullAllergies response.
struct MirrorAllergiesStatusRecord {
    var status: String
    var resultStatus: String
    var correlationID: String
}

/// Where MirrorAllergiesStatus hands each record.
protocol MirrorAllergiesStatusDestination {
    func deliver(_ rec: MirrorAllergiesStatusRecord) async throws
}

/// Writes records to acme.pipelines.v1.PipelineCalculationService.
struct MirrorAllergiesStatusPipelineCalculation: MirrorAllergiesStatusDestination {
    let client: Acme_Pipelines_V1_PipelineCalculationService.Client<MeshTransport>

    func deliver(_ rec: MirrorAllergiesStatusRecord) async throws {
        let request = Acme_Pipelines_V1_SimulatePipelineRequest.with {
            $0.details.currencyCode = rec.resultStatus
            $0.pipelineID = rec.correlationID
            $0.pipeline.title = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.simulatePipeline(request)
        }
    }
}

/// Passes records to acme.careplans.v1.VitalCalculationService.
struct MirrorAllergiesStatusVitalCalculation: MirrorAllergiesStatusDestination {
    let client: Acme_Careplans_V1_VitalCalculationService.Client<MeshTransport>

    func deliver(_ rec: MirrorAllergiesStatusRecord) async throws {
        _ = try await client.compareVitalOptions(.with {
            $0.details.currencyCode = rec.status
            $0.reason = rec.correlationID
            $0.vitalID = rec.resultStatus
        })
    }
}

/// Sends records to acme.licensing.v1.SoftwareLicenseQueryService.
struct MirrorAllergiesStatusSoftwareLicenseQuery: MirrorAllergiesStatusDestination {
    let client: Acme_Licensing_V1_SoftwareLicenseQueryService.Client<MeshTransport>

    func deliver(_ rec: MirrorAllergiesStatusRecord) async throws {
        _ = try await client.lookupSoftwareLicense(.with {
            $0.softwareLicenseID = rec.status
        })
    }
}

/// Reads acme.patients.v1.AllergySyncService/PullAllergies and hands what it keeps to the sink of its kind.
enum MirrorAllergiesStatus {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Patients_V1_AllergySyncService.Client(wrapping: mesh)
        let reply = try await upstream.pullAllergies(.with { $0.allergyID = "current-mirror-allergies-status" })
        let row = MirrorAllergiesStatusRecord(
            status: reply.outcome.status,
            resultStatus: Kit.Text.normalize(reply.result.status),
            correlationID: reply.result.correlationID
        )
        let sinks: [String: any MirrorAllergiesStatusDestination] = [
            "pipeline-calculation": MirrorAllergiesStatusPipelineCalculation(client: Acme_Pipelines_V1_PipelineCalculationService.Client(wrapping: mesh)),
            "vital-calculation": MirrorAllergiesStatusVitalCalculation(client: Acme_Careplans_V1_VitalCalculationService.Client(wrapping: mesh)),
            "software-license-query": MirrorAllergiesStatusSoftwareLicenseQuery(client: Acme_Licensing_V1_SoftwareLicenseQueryService.Client(wrapping: mesh)),
        ]
        for (kind, sink) in sinks {
            if kind != "software-license-query" {
                continue
            }
            try await sink.deliver(row)
        }
    }
}
