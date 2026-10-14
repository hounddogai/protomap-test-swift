import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RelayGetAudiencesToken keeps of each BatchGetAudiences response.
struct RelayGetAudiencesTokenRecord {
    var nextPageToken: String
    var message: String
}

/// Where RelayGetAudiencesToken hands each record.
protocol RelayGetAudiencesTokenTarget {
    func deliver(_ rec: RelayGetAudiencesTokenRecord) async throws
}

/// Passes records to acme.documents.v1.DocumentValidationService.
struct RelayGetAudiencesTokenDocumentValidation: RelayGetAudiencesTokenTarget {
    let client: Acme_Documents_V1_DocumentValidationService.Client<MeshTransport>

    func deliver(_ rec: RelayGetAudiencesTokenRecord) async throws {
        let request = Acme_Documents_V1_CheckDocumentEligibilityRequest.with {
            $0.reason = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.checkDocumentEligibility(request)
        }
    }
}

/// Writes records to acme.featureflags.v1.FeatureFlagService.
struct RelayGetAudiencesTokenFeatureFlag: RelayGetAudiencesTokenTarget {
    let client: Acme_Featureflags_V1_FeatureFlagService.Client<MeshTransport>

    func deliver(_ rec: RelayGetAudiencesTokenRecord) async throws {
        _ = try await client.listFeatureFlags(.with {
            $0.filter.region = rec.nextPageToken
            $0.filter.ownerID = rec.message
        })
    }
}

/// Reads acme.audiences.v1.AudienceService/BatchGetAudiences and hands what it keeps to the sink of its kind.
enum RelayGetAudiencesToken {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Audiences_V1_AudienceService.Client(wrapping: mesh)
        let got = try await source.batchGetAudiences(.init())
        let row = RelayGetAudiencesTokenRecord(
            nextPageToken: got.pageInfo.nextPageToken,
            message: got.result.message
        )
        let sinks: [String: any RelayGetAudiencesTokenTarget] = [
            "document-validation": RelayGetAudiencesTokenDocumentValidation(client: Acme_Documents_V1_DocumentValidationService.Client(wrapping: mesh)),
            "feature-flag": RelayGetAudiencesTokenFeatureFlag(client: Acme_Featureflags_V1_FeatureFlagService.Client(wrapping: mesh)),
        ]
        try await route("document-validation", row, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: RelayGetAudiencesTokenRecord, _ sinks: [String: any RelayGetAudiencesTokenTarget]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.deliver(rec)
    }
}
