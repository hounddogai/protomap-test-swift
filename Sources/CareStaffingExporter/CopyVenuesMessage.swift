import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CopyVenuesMessage keeps of each SuggestVenues response.
struct CopyVenuesMessageRecord {
    var message: String
    var status: String
}

/// Passes records to acme.careplans.v1.CareGoalValidationService.
struct CopyVenuesMessageCareGoalValidation {
    let client: Acme_Careplans_V1_CareGoalValidationService.Client<MeshTransport>

    func forward(_ rec: CopyVenuesMessageRecord) async throws {
        _ = try await client.scoreCareGoal(.with {
            $0.reason = rec.status
            $0.careGoal.subject = rec.message
        })
    }
}

/// Reads acme.venues.v1.VenueQueryService/SuggestVenues and hands what it keeps to acme.careplans.v1.CareGoalValidationService.
enum CopyVenuesMessage {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Venues_V1_VenueQueryService.Client(wrapping: mesh)
        let response = try await reader.suggestVenues(.with { $0.orderBy = "live-copy-venues-message" })
        let entry = CopyVenuesMessageRecord(
            message: Kit.Text.normalize(response.result.message),
            status: response.result.status
        )
        try await CopyVenuesMessageCareGoalValidation(client: Acme_Careplans_V1_CareGoalValidationService.Client(wrapping: mesh)).forward(entry)
    }
}
