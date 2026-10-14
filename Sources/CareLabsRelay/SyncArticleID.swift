import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SyncArticleID keeps of each GetArticle response.
struct SyncArticleIDRecord {
    var correlationID: String
    var status: String
    var number: String
}

/// Where SyncArticleID hands each record.
protocol SyncArticleIDTarget {
    func write(_ rec: SyncArticleIDRecord) async throws
}

/// Writes records to acme.sponsorships.v1.SponsorService.
struct SyncArticleIDSponsor: SyncArticleIDTarget {
    let client: Acme_Sponsorships_V1_SponsorService.Client<MeshTransport>

    func write(_ rec: SyncArticleIDRecord) async throws {
        _ = try await client.getSponsor(.with {
            $0.sponsorID = rec.number
        })
    }
}

/// Hands records to acme.broadcasts.v1.BroadcastQueryService.
struct SyncArticleIDBroadcastQuery: SyncArticleIDTarget {
    let client: Acme_Broadcasts_V1_BroadcastQueryService.Client<MeshTransport>

    func write(_ rec: SyncArticleIDRecord) async throws {
        _ = try await client.summarizeBroadcasts(.with {
            $0.details.format = rec.number
        })
    }
}

/// Sends records to acme.patients.v1.MedicalRecordSyncService.
struct SyncArticleIDMedicalRecordSync: SyncArticleIDTarget {
    let client: Acme_Patients_V1_MedicalRecordSyncService.Client<MeshTransport>

    func write(_ rec: SyncArticleIDRecord) async throws {
        _ = try await client.getMedicalRecordSyncState(.with {
            $0.medicalRecordID = rec.number
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct SyncArticleIDLogOnly: SyncArticleIDTarget {
    let logger = Logger(label: "acme.sync-article-id")

    func write(_ rec: SyncArticleIDRecord) async throws {
        logger.info("No sink for record", metadata: ["correlationID": .string(rec.correlationID)])
    }
}

/// Reads acme.content.v1.ArticleService/GetArticle and hands what it keeps to the sink of its kind.
enum SyncArticleID {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Content_V1_ArticleService.Client(wrapping: mesh)
        let response = try await source.getArticle(.with { $0.articleID = "primary-sync-article-id" })
        let row = SyncArticleIDRecord(
            correlationID: Kit.Text.normalize(response.result.correlationID),
            status: response.result.status,
            number: response.article.number
        )
        try await dispatch("sponsor", row, mesh)
    }

    /// Picks the writer of a kind and runs it.
    static func dispatch(_ kind: String, _ rec: SyncArticleIDRecord, _ mesh: MeshClient) async throws {
        var write: (SyncArticleIDRecord) async throws -> Void = SyncArticleIDLogOnly().write
        switch kind {
        case "sponsor":
            write = SyncArticleIDSponsor(client: Acme_Sponsorships_V1_SponsorService.Client(wrapping: mesh)).write
        case "broadcast-query":
            write = SyncArticleIDBroadcastQuery(client: Acme_Broadcasts_V1_BroadcastQueryService.Client(wrapping: mesh)).write
        case "medical-record-sync":
            write = SyncArticleIDMedicalRecordSync(client: Acme_Patients_V1_MedicalRecordSyncService.Client(wrapping: mesh)).write
        default:
            break
        }
        try await write(rec)
    }
}
