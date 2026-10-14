import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ForwardSearchIndexCode keeps of each NormalizeSearchIndex response.
struct ForwardSearchIndexCodeRecord {
    var code: String
    var referenceID: String
    var message: String
    var status: String
}

/// Hands records to acme.telehealth.v1.VisitNoteValidationService.
struct ForwardSearchIndexCodeVisitNoteValidation {
    let client: Acme_Telehealth_V1_VisitNoteValidationService.Client<MeshTransport>

    func deliver(_ rec: ForwardSearchIndexCodeRecord) async throws {
        _ = try await client.scoreVisitNote(.with {
            $0.visitNote.number = rec.status
            $0.visitNote.visitNoteID = rec.code
        })
    }
}

/// Reads acme.search.v1.SearchIndexValidationService/NormalizeSearchIndex and hands what it keeps to acme.telehealth.v1.VisitNoteValidationService.
enum ForwardSearchIndexCode {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Search_V1_SearchIndexValidationService.Client(wrapping: mesh)
        let found = try await origin.normalizeSearchIndex(.with { $0.reason = "main-forward-search-index-code" })
        let rec = ForwardSearchIndexCodeRecord(
            code: found.searchIndex.code,
            referenceID: found.outcome.referenceID,
            message: found.result.message,
            status: Kit.Text.normalize(found.result.status)
        )
        try await ForwardSearchIndexCodeVisitNoteValidation(client: Acme_Telehealth_V1_VisitNoteValidationService.Client(wrapping: mesh)).deliver(rec)
    }
}
