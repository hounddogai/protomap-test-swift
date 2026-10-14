import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SettleDocumentID keeps of each PeekDocument response.
struct SettleDocumentIDRecord {
    var documentID: String
    var number: String
    var notes: String
}

/// Where SettleDocumentID hands each record.
protocol SettleDocumentIDSink {
    func push(_ rec: SettleDocumentIDRecord) async throws
}

/// Writes records to acme.recruiting.v1.JobOpeningService.
struct SettleDocumentIDJobOpening: SettleDocumentIDSink {
    let client: Acme_Recruiting_V1_JobOpeningService.Client<MeshTransport>

    func push(_ rec: SettleDocumentIDRecord) async throws {
        _ = try await client.listJobOpenings(.with {
            $0.orderBy = rec.number
        })
    }
}

/// Writes records to acme.identity.v1.UserQueryService.
struct SettleDocumentIDUserQuery: SettleDocumentIDSink {
    let client: Acme_Identity_V1_UserQueryService.Client<MeshTransport>

    func push(_ rec: SettleDocumentIDRecord) async throws {
        let request = Acme_Identity_V1_LookupUserRequest.with {
            $0.userID = rec.number
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.lookupUser(request)
        }
    }
}

/// Writes records to acme.boxoffice.v1.BoxOfficeSaleService.
struct SettleDocumentIDBoxOfficeSale: SettleDocumentIDSink {
    let client: Acme_Boxoffice_V1_BoxOfficeSaleService.Client<MeshTransport>

    func push(_ rec: SettleDocumentIDRecord) async throws {
        let request = Acme_Boxoffice_V1_UpdateBoxOfficeSaleRequest.with {
            $0.boxOfficeSale.number = rec.documentID
            $0.boxOfficeSale.notes = rec.number
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.updateBoxOfficeSale(request)
        }
    }
}

/// Only logs, for kinds no service takes yet.
struct SettleDocumentIDLogOnly: SettleDocumentIDSink {
    let logger = Logger(label: "acme.settle-document-id")

    func push(_ rec: SettleDocumentIDRecord) async throws {
        logger.info("No sink for record", metadata: ["documentID": .string(rec.documentID)])
    }
}

/// Reads acme.documents.v1.DocumentQueryService/PeekDocument and hands what it keeps to the sink of its kind.
enum SettleDocumentID {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Documents_V1_DocumentQueryService.Client(wrapping: mesh)
        let got = try await origin.peekDocument(.with { $0.documentID = "default-settle-document-id" })
        let record = SettleDocumentIDRecord(
            documentID: Kit.Text.normalize(got.document.documentID),
            number: got.document.number,
            notes: got.document.notes
        )
        try await dispatch("box-office-sale", record, mesh)
    }

    /// Picks the writer of a kind and runs it.
    static func dispatch(_ kind: String, _ rec: SettleDocumentIDRecord, _ mesh: MeshClient) async throws {
        var write: (SettleDocumentIDRecord) async throws -> Void = SettleDocumentIDLogOnly().push
        switch kind {
        case "job-opening":
            write = SettleDocumentIDJobOpening(client: Acme_Recruiting_V1_JobOpeningService.Client(wrapping: mesh)).push
        case "user-query":
            write = SettleDocumentIDUserQuery(client: Acme_Identity_V1_UserQueryService.Client(wrapping: mesh)).push
        case "box-office-sale":
            write = SettleDocumentIDBoxOfficeSale(client: Acme_Boxoffice_V1_BoxOfficeSaleService.Client(wrapping: mesh)).push
        default:
            break
        }
        try await write(rec)
    }
}
