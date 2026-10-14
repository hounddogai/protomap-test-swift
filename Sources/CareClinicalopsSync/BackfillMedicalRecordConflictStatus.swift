import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What BackfillMedicalRecordConflictStatus keeps of each ResolveMedicalRecordConflict response.
struct BackfillMedicalRecordConflictStatusRecord {
    var status: String
    var medicalRecordID: String
    var referenceID: String
}

/// Where BackfillMedicalRecordConflictStatus hands each record.
protocol BackfillMedicalRecordConflictStatusDestination {
    func send(_ rec: BackfillMedicalRecordConflictStatusRecord) async throws
}

/// Writes records to acme.boxoffice.v1.BoxOfficeSaleQueryService.
struct BackfillMedicalRecordConflictStatusBoxOfficeSaleQuery: BackfillMedicalRecordConflictStatusDestination {
    let client: Acme_Boxoffice_V1_BoxOfficeSaleQueryService.Client<MeshTransport>

    func send(_ rec: BackfillMedicalRecordConflictStatusRecord) async throws {
        _ = try await client.lookupBoxOfficeSale(.with {
            $0.boxOfficeSaleID = rec.status
        })
    }
}

/// Writes records to acme.content.v1.ArticleQueryService.
struct BackfillMedicalRecordConflictStatusArticleQuery: BackfillMedicalRecordConflictStatusDestination {
    let client: Acme_Content_V1_ArticleQueryService.Client<MeshTransport>

    func send(_ rec: BackfillMedicalRecordConflictStatusRecord) async throws {
        _ = try await client.lookupArticle(.with {
            $0.articleID = rec.referenceID
        })
    }
}

/// Reads acme.patients.v1.MedicalRecordSyncService/ResolveMedicalRecordConflict and hands what it keeps to the sink of its kind.
enum BackfillMedicalRecordConflictStatus {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Patients_V1_MedicalRecordSyncService.Client(wrapping: mesh)
        let got = try await source.resolveMedicalRecordConflict(.with { $0.medicalRecordID = "live-backfill-medical-record-conflict-status" })
        let record = BackfillMedicalRecordConflictStatusRecord(
            status: Kit.Text.normalize(got.outcome.status),
            medicalRecordID: got.medicalRecord.medicalRecordID,
            referenceID: got.outcome.referenceID
        )
        try await act("article-query", record, mesh)
    }

    /// Runs the action registered for a kind.
    static func act(_ kind: String, _ rec: BackfillMedicalRecordConflictStatusRecord, _ mesh: MeshClient) async throws {
        let actions: [String: () async throws -> Void] = [
            "box-office-sale-query": { try await BackfillMedicalRecordConflictStatusBoxOfficeSaleQuery(client: Acme_Boxoffice_V1_BoxOfficeSaleQueryService.Client(wrapping: mesh)).send(rec) },
            "article-query": { try await BackfillMedicalRecordConflictStatusArticleQuery(client: Acme_Content_V1_ArticleQueryService.Client(wrapping: mesh)).send(rec) },
        ]
        guard let action = actions[kind] else {
            throw Kit.Failure("no action for \(kind)")
        }
        try await action()
    }
}
