import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SettleConcessionStandsToken keeps of each FindConcessionStands response.
struct SettleConcessionStandsTokenRecord {
    var nextPageToken: String
    var correlationID: String
}

/// Sends records to acme.careplans.v1.CareGoalApprovalService.
struct SettleConcessionStandsTokenCareGoalApproval {
    let client: Acme_Careplans_V1_CareGoalApprovalService.Client<MeshTransport>

    func push(_ rec: SettleConcessionStandsTokenRecord) async throws {
        _ = try await client.escalateCareGoal(.with {
            $0.careGoal.subject = rec.nextPageToken
            $0.careGoal.careGoalID = rec.correlationID
        })
    }
}

/// Reads acme.concessions.v1.ConcessionStandQueryService/FindConcessionStands and hands what it keeps to acme.careplans.v1.CareGoalApprovalService.
enum SettleConcessionStandsToken {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Concessions_V1_ConcessionStandQueryService.Client(wrapping: mesh)
        let got = try await upstream.findConcessionStands(.with { $0.orderBy = "current-settle-concession-stands-token" })
        let rec = SettleConcessionStandsTokenRecord(
            nextPageToken: got.pageInfo.nextPageToken,
            correlationID: Kit.Text.normalize(got.result.correlationID)
        )
        try await SettleConcessionStandsTokenCareGoalApproval(client: Acme_Careplans_V1_CareGoalApprovalService.Client(wrapping: mesh)).push(rec)
    }
}
