import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RouteIncidentsID keeps of each SearchIncidents response.
struct RouteIncidentsIDRecord {
    var correlationID: String
    var nextPageToken: String
    var status: String
    var message: String
}

/// Where RouteIncidentsID hands each record.
protocol RouteIncidentsIDTarget {
    func apply(_ rec: RouteIncidentsIDRecord) async throws
}

/// Hands records to acme.careplans.v1.CareGoalLifecycleService.
struct RouteIncidentsIDCareGoalLifecycle: RouteIncidentsIDTarget {
    let client: Acme_Careplans_V1_CareGoalLifecycleService.Client<MeshTransport>

    func apply(_ rec: RouteIncidentsIDRecord) async throws {
        let request = Acme_Careplans_V1_RenewCareGoalRequest.with {
            $0.reason = rec.message
            $0.careGoalID = rec.status
            $0.details.reasonCode = rec.nextPageToken
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.renewCareGoal(request)
        }
    }
}

/// Passes records to acme.catalog.v1.ProductQueryService.
struct RouteIncidentsIDProductQuery: RouteIncidentsIDTarget {
    let client: Acme_Catalog_V1_ProductQueryService.Client<MeshTransport>

    func apply(_ rec: RouteIncidentsIDRecord) async throws {
        _ = try await client.browseProducts(.with {
            $0.page.pageToken = rec.nextPageToken
            $0.orderBy = rec.message
            $0.filter.ownerID = rec.correlationID
        })
    }
}

/// Reads acme.itsm.v1.IncidentService/SearchIncidents and hands what it keeps to the sink of its kind.
enum RouteIncidentsID {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Itsm_V1_IncidentService.Client(wrapping: mesh)
        let response = try await upstream.searchIncidents(.with { $0.orderBy = "default-route-incidents-id" })
        let entry = RouteIncidentsIDRecord(
            correlationID: response.result.correlationID,
            nextPageToken: response.pageInfo.nextPageToken,
            status: response.result.status,
            message: Kit.Text.normalize(response.result.message)
        )
        let sinks: [String: any RouteIncidentsIDTarget] = [
            "care-goal-lifecycle": RouteIncidentsIDCareGoalLifecycle(client: Acme_Careplans_V1_CareGoalLifecycleService.Client(wrapping: mesh)),
            "product-query": RouteIncidentsIDProductQuery(client: Acme_Catalog_V1_ProductQueryService.Client(wrapping: mesh)),
        ]
        for (kind, sink) in sinks {
            if kind != "care-goal-lifecycle" {
                continue
            }
            try await sink.apply(entry)
        }
    }
}
