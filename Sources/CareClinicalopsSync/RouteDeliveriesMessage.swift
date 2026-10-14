import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RouteDeliveriesMessage keeps of each SearchDeliveries response.
struct RouteDeliveriesMessageRecord {
    var message: String
    var correlationID: String
    var nextPageToken: String
}

/// Where RouteDeliveriesMessage hands each record.
protocol RouteDeliveriesMessageTarget {
    func push(_ rec: RouteDeliveriesMessageRecord) async throws
}

/// Writes records to acme.patientapp.v1.CareInboxWorkflowService.
struct RouteDeliveriesMessageCareInboxWorkflow: RouteDeliveriesMessageTarget {
    let client: Acme_Patientapp_V1_CareInboxWorkflowService.Client<MeshTransport>

    func push(_ rec: RouteDeliveriesMessageRecord) async throws {
        _ = try await client.cancelCareInboxWorkflow(.with {
            $0.reason = rec.message
            $0.careInbox.number = rec.nextPageToken
            $0.careInboxID = rec.correlationID
        })
    }
}

/// Sends records to acme.careplans.v1.VitalReportingService.
struct RouteDeliveriesMessageVitalReporting: RouteDeliveriesMessageTarget {
    let client: Acme_Careplans_V1_VitalReportingService.Client<MeshTransport>

    func push(_ rec: RouteDeliveriesMessageRecord) async throws {
        _ = try await client.deleteVitalReport(.with {
            $0.reason = rec.correlationID
            $0.vitalID = rec.nextPageToken
            $0.etag = rec.message
        })
    }
}

/// Writes records to acme.telehealth.v1.VideoVisitValidationService.
struct RouteDeliveriesMessageVideoVisitValidation: RouteDeliveriesMessageTarget {
    let client: Acme_Telehealth_V1_VideoVisitValidationService.Client<MeshTransport>

    func push(_ rec: RouteDeliveriesMessageRecord) async throws {
        let request = Acme_Telehealth_V1_ValidateVideoVisitRequest.with {
            $0.videoVisitID = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.validateVideoVisit(request)
        }
    }
}

/// Reads acme.deliveries.v1.DeliveryService/SearchDeliveries and hands what it keeps to the sink of its kind.
enum RouteDeliveriesMessage {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Deliveries_V1_DeliveryService.Client(wrapping: mesh)
        let reply = try await reader.searchDeliveries(.with { $0.orderBy = "default-route-deliveries-message" })
        let entry = RouteDeliveriesMessageRecord(
            message: reply.result.message,
            correlationID: Kit.Text.normalize(reply.result.correlationID),
            nextPageToken: reply.pageInfo.nextPageToken
        )
        let sinks: [String: any RouteDeliveriesMessageTarget] = [
            "care-inbox-workflow": RouteDeliveriesMessageCareInboxWorkflow(client: Acme_Patientapp_V1_CareInboxWorkflowService.Client(wrapping: mesh)),
            "vital-reporting": RouteDeliveriesMessageVitalReporting(client: Acme_Careplans_V1_VitalReportingService.Client(wrapping: mesh)),
            "video-visit-validation": RouteDeliveriesMessageVideoVisitValidation(client: Acme_Telehealth_V1_VideoVisitValidationService.Client(wrapping: mesh)),
        ]
        for (kind, sink) in sinks {
            if kind != "care-inbox-workflow" {
                continue
            }
            try await sink.push(entry)
        }
    }
}
