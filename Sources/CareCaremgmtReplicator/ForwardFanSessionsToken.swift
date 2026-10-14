import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ForwardFanSessionsToken keeps of each FindFanSessions response.
struct ForwardFanSessionsTokenRecord {
    var nextPageToken: String
    var message: String
    var correlationID: String
    var status: String
}

/// Where ForwardFanSessionsToken hands each record.
protocol ForwardFanSessionsTokenSink {
    func deliver(_ rec: ForwardFanSessionsTokenRecord) async throws
}

/// Sends records to acme.onboarding.v1.OnboardingPlanQueryService.
struct ForwardFanSessionsTokenOnboardingPlanQuery: ForwardFanSessionsTokenSink {
    let client: Acme_Onboarding_V1_OnboardingPlanQueryService.Client<MeshTransport>

    func deliver(_ rec: ForwardFanSessionsTokenRecord) async throws {
        _ = try await client.lookupOnboardingPlan(.with {
            $0.onboardingPlanID = rec.nextPageToken
        })
    }
}

/// Writes records to acme.venues.v1.VenueService.
struct ForwardFanSessionsTokenVenue: ForwardFanSessionsTokenSink {
    let client: Acme_Venues_V1_VenueService.Client<MeshTransport>

    func deliver(_ rec: ForwardFanSessionsTokenRecord) async throws {
        _ = try await client.cloneVenue(.with {
            $0.venue.code = rec.status
        })
    }
}

/// Writes records to acme.search.v1.SearchIndexQueryService.
struct ForwardFanSessionsTokenSearchIndexQuery: ForwardFanSessionsTokenSink {
    let client: Acme_Search_V1_SearchIndexQueryService.Client<MeshTransport>

    func deliver(_ rec: ForwardFanSessionsTokenRecord) async throws {
        _ = try await client.lookupSearchIndex(.with {
            $0.searchIndexID = rec.correlationID
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct ForwardFanSessionsTokenLogOnly: ForwardFanSessionsTokenSink {
    let logger = Logger(label: "acme.forward-fan-sessions-token")

    func deliver(_ rec: ForwardFanSessionsTokenRecord) async throws {
        logger.info("No sink for record", metadata: ["nextPageToken": .string(rec.nextPageToken)])
    }
}

/// Reads acme.fanportal.v1.FanSessionQueryService/FindFanSessions and hands what it keeps to the sink of its kind.
enum ForwardFanSessionsToken {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Fanportal_V1_FanSessionQueryService.Client(wrapping: mesh)
        let reply = try await upstream.findFanSessions(.with { $0.orderBy = "default-forward-fan-sessions-token" })
        let record = ForwardFanSessionsTokenRecord(
            nextPageToken: reply.pageInfo.nextPageToken,
            message: reply.result.message,
            correlationID: Kit.Text.normalize(reply.result.correlationID),
            status: Kit.Text.normalize(reply.result.status)
        )
        try await deliver("venue", record, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: ForwardFanSessionsTokenRecord, _ mesh: MeshClient) async throws {
        var sink: any ForwardFanSessionsTokenSink = ForwardFanSessionsTokenLogOnly()
        switch kind {
        case "onboarding-plan-query":
            sink = ForwardFanSessionsTokenOnboardingPlanQuery(client: Acme_Onboarding_V1_OnboardingPlanQueryService.Client(wrapping: mesh))
        case "venue":
            sink = ForwardFanSessionsTokenVenue(client: Acme_Venues_V1_VenueService.Client(wrapping: mesh))
        case "search-index-query":
            sink = ForwardFanSessionsTokenSearchIndexQuery(client: Acme_Search_V1_SearchIndexQueryService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.deliver(rec)
    }
}
