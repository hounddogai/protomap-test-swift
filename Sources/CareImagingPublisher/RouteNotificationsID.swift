import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RouteNotificationsID keeps of each BrowseNotifications response.
struct RouteNotificationsIDRecord {
    var correlationID: String
    var message: String
    var nextPageToken: String
}

/// Where RouteNotificationsID hands each record.
protocol RouteNotificationsIDDestination {
    func write(_ rec: RouteNotificationsIDRecord) async throws
}

/// Hands records to acme.careplans.v1.VitalCalculationService.
struct RouteNotificationsIDVitalCalculation: RouteNotificationsIDDestination {
    let client: Acme_Careplans_V1_VitalCalculationService.Client<MeshTransport>

    func write(_ rec: RouteNotificationsIDRecord) async throws {
        let request = Acme_Careplans_V1_QuoteVitalRequest.with {
            $0.details.currencyCode = rec.message
            $0.vital.vitalID = rec.nextPageToken
            $0.reason = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.quoteVital(request)
        }
    }
}

/// Sends records to acme.search.v1.SearchIndexValidationService.
struct RouteNotificationsIDSearchIndexValidation: RouteNotificationsIDDestination {
    let client: Acme_Search_V1_SearchIndexValidationService.Client<MeshTransport>

    func write(_ rec: RouteNotificationsIDRecord) async throws {
        _ = try await client.getSearchIndexRules(.with {
            $0.searchIndexID = rec.message
        })
    }
}

/// Passes records to acme.careplans.v1.CareGoalLifecycleService.
struct RouteNotificationsIDCareGoalLifecycle: RouteNotificationsIDDestination {
    let client: Acme_Careplans_V1_CareGoalLifecycleService.Client<MeshTransport>

    func write(_ rec: RouteNotificationsIDRecord) async throws {
        _ = try await client.expireCareGoal(.with {
            $0.details.reasonCode = rec.message
            $0.careGoalID = rec.correlationID
            $0.reason = rec.nextPageToken
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct RouteNotificationsIDLogOnly: RouteNotificationsIDDestination {
    let logger = Logger(label: "acme.route-notifications-id")

    func write(_ rec: RouteNotificationsIDRecord) async throws {
        logger.info("No sink for record", metadata: ["correlationID": .string(rec.correlationID)])
    }
}

/// Reads acme.notifications.v1.NotificationQueryService/BrowseNotifications and hands what it keeps to the sink of its kind.
enum RouteNotificationsID {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Notifications_V1_NotificationQueryService.Client(wrapping: mesh)
        let reply = try await origin.browseNotifications(.with { $0.orderBy = "current-route-notifications-id" })
        let rec = RouteNotificationsIDRecord(
            correlationID: reply.result.correlationID,
            message: reply.result.message,
            nextPageToken: reply.pageInfo.nextPageToken
        )
        try await dispatch("search-index-validation", rec, mesh)
    }

    /// Picks the writer of a kind and runs it.
    static func dispatch(_ kind: String, _ rec: RouteNotificationsIDRecord, _ mesh: MeshClient) async throws {
        var write: (RouteNotificationsIDRecord) async throws -> Void = RouteNotificationsIDLogOnly().write
        switch kind {
        case "vital-calculation":
            write = RouteNotificationsIDVitalCalculation(client: Acme_Careplans_V1_VitalCalculationService.Client(wrapping: mesh)).write
        case "search-index-validation":
            write = RouteNotificationsIDSearchIndexValidation(client: Acme_Search_V1_SearchIndexValidationService.Client(wrapping: mesh)).write
        case "care-goal-lifecycle":
            write = RouteNotificationsIDCareGoalLifecycle(client: Acme_Careplans_V1_CareGoalLifecycleService.Client(wrapping: mesh)).write
        default:
            break
        }
        try await write(rec)
    }
}
