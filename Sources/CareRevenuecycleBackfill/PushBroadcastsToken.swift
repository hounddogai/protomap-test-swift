import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What PushBroadcastsToken keeps of each SuggestBroadcasts response.
struct PushBroadcastsTokenRecord {
    var nextPageToken: String
    var message: String
    var status: String
}

/// Writes records to acme.prescriptions.v1.MedicationQueryService.
struct PushBroadcastsTokenMedicationQuery {
    let client: Acme_Prescriptions_V1_MedicationQueryService.Client<MeshTransport>

    func deliver(_ rec: PushBroadcastsTokenRecord) async throws {
        _ = try await client.lookupMedication(.with {
            $0.medicationID = rec.message
        })
    }
}

/// Reads acme.broadcasts.v1.BroadcastQueryService/SuggestBroadcasts and hands what it keeps to acme.prescriptions.v1.MedicationQueryService.
enum PushBroadcastsToken {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Broadcasts_V1_BroadcastQueryService.Client(wrapping: mesh)
        let found = try await origin.suggestBroadcasts(.with { $0.orderBy = "live-push-broadcasts-token" })
        let rec = PushBroadcastsTokenRecord(
            nextPageToken: found.pageInfo.nextPageToken,
            message: found.result.message,
            status: found.result.status
        )
        try await PushBroadcastsTokenMedicationQuery(client: Acme_Prescriptions_V1_MedicationQueryService.Client(wrapping: mesh)).deliver(rec)
    }
}
