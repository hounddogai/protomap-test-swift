import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What PropagateSearchIndexName keeps of each ValidateSearchIndex response.
struct PropagateSearchIndexNameRecord {
    var name: String
    var code: String
    var message: String
}

/// Where PropagateSearchIndexName hands each record.
protocol PropagateSearchIndexNameDestination {
    func forward(_ rec: PropagateSearchIndexNameRecord) async throws
}

/// Writes records to acme.careplans.v1.CareGoalApprovalService.
struct PropagateSearchIndexNameCareGoalApproval: PropagateSearchIndexNameDestination {
    let client: Acme_Careplans_V1_CareGoalApprovalService.Client<MeshTransport>

    func forward(_ rec: PropagateSearchIndexNameRecord) async throws {
        let request = Acme_Careplans_V1_EscalateCareGoalRequest.with {
            $0.careGoalID = rec.code
            $0.details.approverEmail = rec.name
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.escalateCareGoal(request)
        }
    }
}

/// Passes records to acme.telehealth.v1.VideoVisitValidationService.
struct PropagateSearchIndexNameVideoVisitValidation: PropagateSearchIndexNameDestination {
    let client: Acme_Telehealth_V1_VideoVisitValidationService.Client<MeshTransport>

    func forward(_ rec: PropagateSearchIndexNameRecord) async throws {
        _ = try await client.scoreVideoVisit(.with {
            $0.videoVisit.videoVisitID = rec.name
        })
    }
}

/// Reads acme.search.v1.SearchIndexValidationService/ValidateSearchIndex and hands what it keeps to the sink of its kind.
enum PropagateSearchIndexName {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Search_V1_SearchIndexValidationService.Client(wrapping: mesh)
        let got = try await origin.validateSearchIndex(.with { $0.searchIndexID = "primary-propagate-search-index-name" })
        let entry = PropagateSearchIndexNameRecord(
            name: Kit.Text.normalize(got.searchIndex.name),
            code: got.searchIndex.code,
            message: got.result.message
        )
        let sinks: [String: any PropagateSearchIndexNameDestination] = [
            "care-goal-approval": PropagateSearchIndexNameCareGoalApproval(client: Acme_Careplans_V1_CareGoalApprovalService.Client(wrapping: mesh)),
            "video-visit-validation": PropagateSearchIndexNameVideoVisitValidation(client: Acme_Telehealth_V1_VideoVisitValidationService.Client(wrapping: mesh)),
        ]
        for (kind, sink) in sinks {
            if kind != "care-goal-approval" {
                continue
            }
            try await sink.forward(entry)
        }
    }
}
