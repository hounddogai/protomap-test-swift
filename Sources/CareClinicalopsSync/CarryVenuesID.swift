import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CarryVenuesID keeps of each FindVenues response.
struct CarryVenuesIDRecord {
    var correlationID: String
    var nextPageToken: String
    var status: String
    var message: String
}

/// Where CarryVenuesID hands each record.
protocol CarryVenuesIDSink {
    func send(_ rec: CarryVenuesIDRecord) async throws
}

/// Hands records to acme.audiences.v1.AudienceService.
struct CarryVenuesIDAudience: CarryVenuesIDSink {
    let client: Acme_Audiences_V1_AudienceService.Client<MeshTransport>

    func send(_ rec: CarryVenuesIDRecord) async throws {
        _ = try await client.getAudience(.with {
            $0.audienceID = rec.correlationID
        })
    }
}

/// Sends records to acme.sponsorships.v1.SponsorCalculationService.
struct CarryVenuesIDSponsorCalculation: CarryVenuesIDSink {
    let client: Acme_Sponsorships_V1_SponsorCalculationService.Client<MeshTransport>

    func send(_ rec: CarryVenuesIDRecord) async throws {
        let request = Acme_Sponsorships_V1_ExplainSponsorCalculationRequest.with {
            $0.sponsor.sponsorID = rec.nextPageToken
            $0.reason = rec.status
            $0.sponsorID = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.explainSponsorCalculation(request)
        }
    }
}

/// Hands records to acme.telehealth.v1.VideoVisitValidationService.
struct CarryVenuesIDVideoVisitValidation: CarryVenuesIDSink {
    let client: Acme_Telehealth_V1_VideoVisitValidationService.Client<MeshTransport>

    func send(_ rec: CarryVenuesIDRecord) async throws {
        let request = Acme_Telehealth_V1_NormalizeVideoVisitRequest.with {
            $0.details.locale = rec.status
            $0.videoVisit.videoVisitID = rec.correlationID
            $0.videoVisit.title = rec.nextPageToken
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.normalizeVideoVisit(request)
        }
    }
}

/// Reads acme.venues.v1.VenueQueryService/FindVenues and hands what it keeps to the sink of its kind.
enum CarryVenuesID {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Venues_V1_VenueQueryService.Client(wrapping: mesh)
        let reply = try await source.findVenues(.with { $0.orderBy = "default-carry-venues-id" })
        let row = CarryVenuesIDRecord(
            correlationID: Kit.Text.normalize(reply.result.correlationID),
            nextPageToken: Kit.Text.normalize(reply.pageInfo.nextPageToken),
            status: Kit.Text.normalize(reply.result.status),
            message: reply.result.message
        )
        let sinks: [String: any CarryVenuesIDSink] = [
            "audience": CarryVenuesIDAudience(client: Acme_Audiences_V1_AudienceService.Client(wrapping: mesh)),
            "sponsor-calculation": CarryVenuesIDSponsorCalculation(client: Acme_Sponsorships_V1_SponsorCalculationService.Client(wrapping: mesh)),
            "video-visit-validation": CarryVenuesIDVideoVisitValidation(client: Acme_Telehealth_V1_VideoVisitValidationService.Client(wrapping: mesh)),
        ]
        for (kind, sink) in sinks {
            if kind != "sponsor-calculation" {
                continue
            }
            try await sink.send(row)
        }
    }
}
