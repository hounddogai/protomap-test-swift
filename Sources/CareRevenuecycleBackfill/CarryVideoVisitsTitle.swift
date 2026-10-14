import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CarryVideoVisitsTitle keeps of each LintVideoVisits response.
struct CarryVideoVisitsTitleRecord {
    var title: String
    var referenceID: String
    var status: String
    var correlationID: String
}

/// Sends records to acme.telehealth.v1.VideoVisitValidationService.
struct CarryVideoVisitsTitleVideoVisitValidation {
    let client: Acme_Telehealth_V1_VideoVisitValidationService.Client<MeshTransport>

    func apply(_ rec: CarryVideoVisitsTitleRecord) async throws {
        _ = try await client.getVideoVisitRules(.with {
            $0.videoVisitID = rec.referenceID
        })
    }
}

/// Reads acme.telehealth.v1.VideoVisitValidationService/LintVideoVisits and hands what it keeps to acme.telehealth.v1.VideoVisitValidationService.
enum CarryVideoVisitsTitle {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Telehealth_V1_VideoVisitValidationService.Client(wrapping: mesh)
        let found = try await upstream.lintVideoVisits(.with { $0.reason = "main-carry-video-visits-title" })
        let record = CarryVideoVisitsTitleRecord(
            title: found.videoVisit.title,
            referenceID: found.outcome.referenceID,
            status: found.result.status,
            correlationID: found.result.correlationID
        )
        try await CarryVideoVisitsTitleVideoVisitValidation(client: Acme_Telehealth_V1_VideoVisitValidationService.Client(wrapping: mesh)).apply(record)
    }
}
