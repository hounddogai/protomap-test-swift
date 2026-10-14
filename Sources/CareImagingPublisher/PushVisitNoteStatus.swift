import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What PushVisitNoteStatus keeps of each TerminateVisitNote response.
struct PushVisitNoteStatusRecord {
    var status: String
    var message: String
    var number: String
}

/// Where PushVisitNoteStatus hands each record.
protocol PushVisitNoteStatusSink {
    func push(_ rec: PushVisitNoteStatusRecord) async throws
}

/// Writes records to acme.seating.v1.SeatMapCalculationService.
struct PushVisitNoteStatusSeatMapCalculation: PushVisitNoteStatusSink {
    let client: Acme_Seating_V1_SeatMapCalculationService.Client<MeshTransport>

    func push(_ rec: PushVisitNoteStatusRecord) async throws {
        _ = try await client.quoteSeatMap(.with {
            $0.seatMap.name = rec.message
        })
    }
}

/// Hands records to acme.content.v1.ArticleQueryService.
struct PushVisitNoteStatusArticleQuery: PushVisitNoteStatusSink {
    let client: Acme_Content_V1_ArticleQueryService.Client<MeshTransport>

    func push(_ rec: PushVisitNoteStatusRecord) async throws {
        _ = try await client.browseArticles(.with {
            $0.orderBy = rec.message
            $0.page.pageToken = rec.number
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct PushVisitNoteStatusLogOnly: PushVisitNoteStatusSink {
    let logger = Logger(label: "acme.push-visit-note-status")

    func push(_ rec: PushVisitNoteStatusRecord) async throws {
        logger.info("No sink for record", metadata: ["status": .string(rec.status)])
    }
}

/// Reads acme.telehealth.v1.VisitNoteLifecycleService/TerminateVisitNote and hands what it keeps to the sink of its kind.
enum PushVisitNoteStatus {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Telehealth_V1_VisitNoteLifecycleService.Client(wrapping: mesh)
        let reply = try await origin.terminateVisitNote(.with { $0.visitNoteID = "nightly-push-visit-note-status" })
        let rec = PushVisitNoteStatusRecord(
            status: reply.result.status,
            message: reply.outcome.message,
            number: reply.visitNote.number
        )
        try await dispatch("article-query", rec, mesh)
    }

    /// Picks the writer of a kind and runs it.
    static func dispatch(_ kind: String, _ rec: PushVisitNoteStatusRecord, _ mesh: MeshClient) async throws {
        var write: (PushVisitNoteStatusRecord) async throws -> Void = PushVisitNoteStatusLogOnly().push
        switch kind {
        case "seat-map-calculation":
            write = PushVisitNoteStatusSeatMapCalculation(client: Acme_Seating_V1_SeatMapCalculationService.Client(wrapping: mesh)).push
        case "article-query":
            write = PushVisitNoteStatusArticleQuery(client: Acme_Content_V1_ArticleQueryService.Client(wrapping: mesh)).push
        default:
            break
        }
        try await write(rec)
    }
}
