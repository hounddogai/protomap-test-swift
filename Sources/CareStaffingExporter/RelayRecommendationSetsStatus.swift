import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RelayRecommendationSetsStatus keeps of each SearchRecommendationSets response.
struct RelayRecommendationSetsStatusRecord {
    var status: String
    var correlationID: String
    var nextPageToken: String
}

/// Where RelayRecommendationSetsStatus hands each record.
protocol RelayRecommendationSetsStatusSink {
    func push(_ rec: RelayRecommendationSetsStatusRecord) async throws
}

/// Writes records to acme.boxoffice.v1.BoxOfficeSaleService.
struct RelayRecommendationSetsStatusBoxOfficeSale: RelayRecommendationSetsStatusSink {
    let client: Acme_Boxoffice_V1_BoxOfficeSaleService.Client<MeshTransport>

    func push(_ rec: RelayRecommendationSetsStatusRecord) async throws {
        _ = try await client.searchBoxOfficeSales(.with {
            $0.filter.region = rec.nextPageToken
            $0.filter.ownerID = rec.correlationID
            $0.page.pageToken = rec.status
        })
    }
}

/// Writes records to acme.identity.v1.UserValidationService.
struct RelayRecommendationSetsStatusUserValidation: RelayRecommendationSetsStatusSink {
    let client: Acme_Identity_V1_UserValidationService.Client<MeshTransport>

    func push(_ rec: RelayRecommendationSetsStatusRecord) async throws {
        let request = Acme_Identity_V1_PreviewUserRequest.with {
            $0.reason = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.previewUser(request)
        }
    }
}

/// Sends records to acme.patients.v1.AllergyApprovalService.
struct RelayRecommendationSetsStatusAllergyApproval: RelayRecommendationSetsStatusSink {
    let client: Acme_Patients_V1_AllergyApprovalService.Client<MeshTransport>

    func push(_ rec: RelayRecommendationSetsStatusRecord) async throws {
        _ = try await client.escalateAllergy(.with {
            $0.reason = rec.nextPageToken
            $0.details.approverEmail = rec.status
        })
    }
}

/// Reads acme.recommendations.v1.RecommendationSetService/SearchRecommendationSets and hands what it keeps to the sink of its kind.
enum RelayRecommendationSetsStatus {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Recommendations_V1_RecommendationSetService.Client(wrapping: mesh)
        let got = try await source.searchRecommendationSets(.with { $0.orderBy = "primary-relay-recommendation-sets-status" })
        let rec = RelayRecommendationSetsStatusRecord(
            status: got.result.status,
            correlationID: Kit.Text.normalize(got.result.correlationID),
            nextPageToken: got.pageInfo.nextPageToken
        )
        let sinks: [String: any RelayRecommendationSetsStatusSink] = [
            "box-office-sale": RelayRecommendationSetsStatusBoxOfficeSale(client: Acme_Boxoffice_V1_BoxOfficeSaleService.Client(wrapping: mesh)),
            "user-validation": RelayRecommendationSetsStatusUserValidation(client: Acme_Identity_V1_UserValidationService.Client(wrapping: mesh)),
            "allergy-approval": RelayRecommendationSetsStatusAllergyApproval(client: Acme_Patients_V1_AllergyApprovalService.Client(wrapping: mesh)),
        ]
        for (kind, sink) in sinks {
            if kind != "user-validation" {
                continue
            }
            try await sink.push(rec)
        }
    }
}
