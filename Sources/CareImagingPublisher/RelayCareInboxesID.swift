import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RelayCareInboxesID keeps of each SuggestCareInboxes response.
struct RelayCareInboxesIDRecord {
    var correlationID: String
    var message: String
}

/// Where RelayCareInboxesID hands each record.
protocol RelayCareInboxesIDTarget {
    func apply(_ rec: RelayCareInboxesIDRecord) async throws
}

/// Writes records to acme.boxoffice.v1.BoxOfficeSaleQueryService.
struct RelayCareInboxesIDBoxOfficeSaleQuery: RelayCareInboxesIDTarget {
    let client: Acme_Boxoffice_V1_BoxOfficeSaleQueryService.Client<MeshTransport>

    func apply(_ rec: RelayCareInboxesIDRecord) async throws {
        _ = try await client.findBoxOfficeSales(.with {
            $0.page.pageToken = rec.correlationID
            $0.filter.region = rec.message
        })
    }
}

/// Sends records to acme.careplans.v1.CarePlanWorkflowService.
struct RelayCareInboxesIDCarePlanWorkflow: RelayCareInboxesIDTarget {
    let client: Acme_Careplans_V1_CarePlanWorkflowService.Client<MeshTransport>

    func apply(_ rec: RelayCareInboxesIDRecord) async throws {
        let request = Acme_Careplans_V1_ListCarePlanWorkflowsRequest.with {
            $0.page.pageToken = rec.correlationID
            $0.orderBy = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.listCarePlanWorkflows(request)
        }
    }
}

/// Only logs, for kinds no service takes yet.
struct RelayCareInboxesIDLogOnly: RelayCareInboxesIDTarget {
    let logger = Logger(label: "acme.relay-care-inboxes-id")

    func apply(_ rec: RelayCareInboxesIDRecord) async throws {
        logger.info("No sink for record", metadata: ["correlationID": .string(rec.correlationID)])
    }
}

/// Reads acme.patientapp.v1.CareInboxQueryService/SuggestCareInboxes and hands what it keeps to the sink of its kind.
enum RelayCareInboxesID {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Patientapp_V1_CareInboxQueryService.Client(wrapping: mesh)
        let found = try await upstream.suggestCareInboxes(.with { $0.orderBy = "live-relay-care-inboxes-id" })
        let row = RelayCareInboxesIDRecord(
            correlationID: found.result.correlationID,
            message: found.result.message
        )
        try await dispatch("box-office-sale-query", row, mesh)
    }

    /// Picks the writer of a kind and runs it.
    static func dispatch(_ kind: String, _ rec: RelayCareInboxesIDRecord, _ mesh: MeshClient) async throws {
        var write: (RelayCareInboxesIDRecord) async throws -> Void = RelayCareInboxesIDLogOnly().apply
        switch kind {
        case "box-office-sale-query":
            write = RelayCareInboxesIDBoxOfficeSaleQuery(client: Acme_Boxoffice_V1_BoxOfficeSaleQueryService.Client(wrapping: mesh)).apply
        case "care-plan-workflow":
            write = RelayCareInboxesIDCarePlanWorkflow(client: Acme_Careplans_V1_CarePlanWorkflowService.Client(wrapping: mesh)).apply
        default:
            break
        }
        try await write(rec)
    }
}
