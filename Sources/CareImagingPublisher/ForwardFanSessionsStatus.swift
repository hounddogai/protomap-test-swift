import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ForwardFanSessionsStatus keeps of each BrowseFanSessions response.
struct ForwardFanSessionsStatusRecord {
    var status: String
    var nextPageToken: String
    var message: String
}

/// Where ForwardFanSessionsStatus hands each record.
protocol ForwardFanSessionsStatusDestination {
    func forward(_ rec: ForwardFanSessionsStatusRecord) async throws
}

/// Passes records to acme.patientapp.v1.CareInboxNotificationService.
struct ForwardFanSessionsStatusCareInboxNotification: ForwardFanSessionsStatusDestination {
    let client: Acme_Patientapp_V1_CareInboxNotificationService.Client<MeshTransport>

    func forward(_ rec: ForwardFanSessionsStatusRecord) async throws {
        _ = try await client.notifyCareInboxWatchers(.with {
            $0.reason = rec.nextPageToken
            $0.details.templateID = rec.status
            $0.details.channel = rec.message
        })
    }
}

/// Writes records to acme.sponsorships.v1.SponsorQueryService.
struct ForwardFanSessionsStatusSponsorQuery: ForwardFanSessionsStatusDestination {
    let client: Acme_Sponsorships_V1_SponsorQueryService.Client<MeshTransport>

    func forward(_ rec: ForwardFanSessionsStatusRecord) async throws {
        _ = try await client.browseSponsors(.with {
            $0.filter.ownerID = rec.status
            $0.filter.query = rec.message
            $0.page.pageToken = rec.nextPageToken
        })
    }
}

/// Sends records to acme.seating.v1.SeatMapService.
struct ForwardFanSessionsStatusSeatMap: ForwardFanSessionsStatusDestination {
    let client: Acme_Seating_V1_SeatMapService.Client<MeshTransport>

    func forward(_ rec: ForwardFanSessionsStatusRecord) async throws {
        _ = try await client.createSeatMap(.with {
            $0.seatMap.seatMapID = rec.status
            $0.requestID = rec.message
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct ForwardFanSessionsStatusLogOnly: ForwardFanSessionsStatusDestination {
    let logger = Logger(label: "acme.forward-fan-sessions-status")

    func forward(_ rec: ForwardFanSessionsStatusRecord) async throws {
        logger.info("No sink for record", metadata: ["status": .string(rec.status)])
    }
}

/// Reads acme.fanportal.v1.FanSessionQueryService/BrowseFanSessions and hands what it keeps to the sink of its kind.
enum ForwardFanSessionsStatus {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Fanportal_V1_FanSessionQueryService.Client(wrapping: mesh)
        let got = try await upstream.browseFanSessions(.with { $0.orderBy = "main-forward-fan-sessions-status" })
        let rec = ForwardFanSessionsStatusRecord(
            status: got.result.status,
            nextPageToken: got.pageInfo.nextPageToken,
            message: got.result.message
        )
        try await deliver("sponsor-query", rec, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: ForwardFanSessionsStatusRecord, _ mesh: MeshClient) async throws {
        var sink: any ForwardFanSessionsStatusDestination = ForwardFanSessionsStatusLogOnly()
        switch kind {
        case "care-inbox-notification":
            sink = ForwardFanSessionsStatusCareInboxNotification(client: Acme_Patientapp_V1_CareInboxNotificationService.Client(wrapping: mesh))
        case "sponsor-query":
            sink = ForwardFanSessionsStatusSponsorQuery(client: Acme_Sponsorships_V1_SponsorQueryService.Client(wrapping: mesh))
        case "seat-map":
            sink = ForwardFanSessionsStatusSeatMap(client: Acme_Seating_V1_SeatMapService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.forward(rec)
    }
}
