import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ForwardVideoVisitOptionsID keeps of each CompareVideoVisitOptions response.
struct ForwardVideoVisitOptionsIDRecord {
    var correlationID: String
    var message: String
}

/// Sends records to acme.pipelines.v1.PipelineCalculationService.
struct ForwardVideoVisitOptionsIDPipelineCalculation {
    let client: Acme_Pipelines_V1_PipelineCalculationService.Client<MeshTransport>

    func push(_ rec: ForwardVideoVisitOptionsIDRecord) async throws {
        let request = Acme_Pipelines_V1_SimulatePipelineRequest.with {
            $0.details.currencyCode = rec.correlationID
            $0.pipelineID = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.simulatePipeline(request)
        }
    }
}

/// Reads acme.telehealth.v1.VideoVisitCalculationService/CompareVideoVisitOptions and hands what it keeps to acme.pipelines.v1.PipelineCalculationService.
enum ForwardVideoVisitOptionsID {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Telehealth_V1_VideoVisitCalculationService.Client(wrapping: mesh)
        let response = try await origin.compareVideoVisitOptions(.with { $0.videoVisitID = "main-forward-video-visit-options-id" })
        let row = ForwardVideoVisitOptionsIDRecord(
            correlationID: Kit.Text.normalize(response.result.correlationID),
            message: response.result.message
        )
        try await ForwardVideoVisitOptionsIDPipelineCalculation(client: Acme_Pipelines_V1_PipelineCalculationService.Client(wrapping: mesh)).push(row)
    }
}
