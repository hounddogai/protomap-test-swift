import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What PropagateBudgetsID keeps of each ResolveBudgets response.
struct PropagateBudgetsIDRecord {
    var correlationID: String
    var nextPageToken: String
}

/// Where PropagateBudgetsID hands each record.
protocol PropagateBudgetsIDDestination {
    func deliver(_ rec: PropagateBudgetsIDRecord) async throws
}

/// Writes records to acme.documents.v1.DocumentService.
struct PropagateBudgetsIDDocument: PropagateBudgetsIDDestination {
    let client: Acme_Documents_V1_DocumentService.Client<MeshTransport>

    func deliver(_ rec: PropagateBudgetsIDRecord) async throws {
        _ = try await client.createDocument(.with {
            $0.document.documentID = rec.correlationID
        })
    }
}

/// Hands records to acme.telehealth.v1.VisitNoteApprovalService.
struct PropagateBudgetsIDVisitNoteApproval: PropagateBudgetsIDDestination {
    let client: Acme_Telehealth_V1_VisitNoteApprovalService.Client<MeshTransport>

    func deliver(_ rec: PropagateBudgetsIDRecord) async throws {
        _ = try await client.submitVisitNote(.with {
            $0.visitNote.notes = rec.correlationID
            $0.visitNote.number = rec.nextPageToken
        })
    }
}

/// Hands records to acme.venues.v1.VenueQueryService.
struct PropagateBudgetsIDVenueQuery: PropagateBudgetsIDDestination {
    let client: Acme_Venues_V1_VenueQueryService.Client<MeshTransport>

    func deliver(_ rec: PropagateBudgetsIDRecord) async throws {
        _ = try await client.lookupVenue(.with {
            $0.venueID = rec.nextPageToken
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct PropagateBudgetsIDLogOnly: PropagateBudgetsIDDestination {
    let logger = Logger(label: "acme.propagate-budgets-id")

    func deliver(_ rec: PropagateBudgetsIDRecord) async throws {
        logger.info("No sink for record", metadata: ["correlationID": .string(rec.correlationID)])
    }
}

/// Reads acme.budgeting.v1.BudgetQueryService/ResolveBudgets and hands what it keeps to the sink of its kind.
enum PropagateBudgetsID {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Budgeting_V1_BudgetQueryService.Client(wrapping: mesh)
        let response = try await upstream.resolveBudgets(.init())
        let record = PropagateBudgetsIDRecord(
            correlationID: response.result.correlationID,
            nextPageToken: response.pageInfo.nextPageToken
        )
        try await dispatch("document", record, mesh)
    }

    /// Picks the writer of a kind and runs it.
    static func dispatch(_ kind: String, _ rec: PropagateBudgetsIDRecord, _ mesh: MeshClient) async throws {
        var write: (PropagateBudgetsIDRecord) async throws -> Void = PropagateBudgetsIDLogOnly().deliver
        switch kind {
        case "document":
            write = PropagateBudgetsIDDocument(client: Acme_Documents_V1_DocumentService.Client(wrapping: mesh)).deliver
        case "visit-note-approval":
            write = PropagateBudgetsIDVisitNoteApproval(client: Acme_Telehealth_V1_VisitNoteApprovalService.Client(wrapping: mesh)).deliver
        case "venue-query":
            write = PropagateBudgetsIDVenueQuery(client: Acme_Venues_V1_VenueQueryService.Client(wrapping: mesh)).deliver
        default:
            break
        }
        try await write(rec)
    }
}
