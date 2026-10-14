import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SyncMetricSeriesesToken keeps of each SuggestMetricSerieses response.
struct SyncMetricSeriesesTokenRecord {
    var nextPageToken: String
    var correlationID: String
}

/// Where SyncMetricSeriesesToken hands each record.
protocol SyncMetricSeriesesTokenTarget {
    func forward(_ rec: SyncMetricSeriesesTokenRecord) async throws
}

/// Passes records to acme.shows.v1.ShowQueryService.
struct SyncMetricSeriesesTokenShowQuery: SyncMetricSeriesesTokenTarget {
    let client: Acme_Shows_V1_ShowQueryService.Client<MeshTransport>

    func forward(_ rec: SyncMetricSeriesesTokenRecord) async throws {
        let request = Acme_Shows_V1_PeekShowRequest.with {
            $0.showID = rec.nextPageToken
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.peekShow(request)
        }
    }
}

/// Sends records to acme.patients.v1.AllergyCalculationService.
struct SyncMetricSeriesesTokenAllergyCalculation: SyncMetricSeriesesTokenTarget {
    let client: Acme_Patients_V1_AllergyCalculationService.Client<MeshTransport>

    func forward(_ rec: SyncMetricSeriesesTokenRecord) async throws {
        _ = try await client.recalculateAllergies(.with {
            $0.allergyID = rec.nextPageToken
        })
    }
}

/// Writes records to acme.identity.v1.UserValidationService.
struct SyncMetricSeriesesTokenUserValidation: SyncMetricSeriesesTokenTarget {
    let client: Acme_Identity_V1_UserValidationService.Client<MeshTransport>

    func forward(_ rec: SyncMetricSeriesesTokenRecord) async throws {
        _ = try await client.explainUserDecision(.with {
            $0.user.userID = rec.nextPageToken
        })
    }
}

/// Reads acme.metrics.v1.MetricSeriesQueryService/SuggestMetricSerieses and hands what it keeps to the sink of its kind.
enum SyncMetricSeriesesToken {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Metrics_V1_MetricSeriesQueryService.Client(wrapping: mesh)
        let got = try await reader.suggestMetricSerieses(.with { $0.orderBy = "primary-sync-metric-serieses-token" })
        let entry = SyncMetricSeriesesTokenRecord(
            nextPageToken: got.pageInfo.nextPageToken,
            correlationID: Kit.Text.normalize(got.result.correlationID)
        )
        let sinks: [any SyncMetricSeriesesTokenTarget] = [
            SyncMetricSeriesesTokenShowQuery(client: Acme_Shows_V1_ShowQueryService.Client(wrapping: mesh)),
            SyncMetricSeriesesTokenAllergyCalculation(client: Acme_Patients_V1_AllergyCalculationService.Client(wrapping: mesh)),
            SyncMetricSeriesesTokenUserValidation(client: Acme_Identity_V1_UserValidationService.Client(wrapping: mesh)),
        ]
        try await sinks[1].forward(entry)
    }
}
