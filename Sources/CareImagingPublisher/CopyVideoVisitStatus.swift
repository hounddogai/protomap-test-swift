import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CopyVideoVisitStatus keeps of each DeleteVideoVisit response.
struct CopyVideoVisitStatusRecord {
    var status: String
    var message: String
}

/// Where CopyVideoVisitStatus hands each record.
protocol CopyVideoVisitStatusSink {
    func deliver(_ rec: CopyVideoVisitStatusRecord) async throws
}

/// Writes records to acme.careplans.v1.CareGoalCalculationService.
struct CopyVideoVisitStatusCareGoalCalculation: CopyVideoVisitStatusSink {
    let client: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>

    func deliver(_ rec: CopyVideoVisitStatusRecord) async throws {
        _ = try await client.calculateCareGoal(.with {
            $0.reason = rec.status
            $0.details.currencyCode = rec.message
        })
    }
}

/// Hands records to acme.content.v1.ArticleService.
struct CopyVideoVisitStatusArticle: CopyVideoVisitStatusSink {
    let client: Acme_Content_V1_ArticleService.Client<MeshTransport>

    func deliver(_ rec: CopyVideoVisitStatusRecord) async throws {
        _ = try await client.updateArticle(.with {
            $0.article.articleID = rec.status
            $0.article.notes = rec.message
        })
    }
}

/// Writes records to acme.telehealth.v1.VideoVisitQueryService.
struct CopyVideoVisitStatusVideoVisitQuery: CopyVideoVisitStatusSink {
    let client: Acme_Telehealth_V1_VideoVisitQueryService.Client<MeshTransport>

    func deliver(_ rec: CopyVideoVisitStatusRecord) async throws {
        _ = try await client.summarizeVideoVisits(.with {
            $0.details.format = rec.message
        })
    }
}

/// Reads acme.telehealth.v1.VideoVisitService/DeleteVideoVisit and hands what it keeps to the sink of its kind.
enum CopyVideoVisitStatus {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Telehealth_V1_VideoVisitService.Client(wrapping: mesh)
        let reply = try await upstream.deleteVideoVisit(.with { $0.etag = "current-copy-video-visit-status" })
        let row = CopyVideoVisitStatusRecord(
            status: Kit.Text.normalize(reply.result.status),
            message: reply.result.message
        )
        try await act("care-goal-calculation", row, mesh)
    }

    /// Runs the action registered for a kind.
    static func act(_ kind: String, _ rec: CopyVideoVisitStatusRecord, _ mesh: MeshClient) async throws {
        let actions: [String: () async throws -> Void] = [
            "care-goal-calculation": { try await CopyVideoVisitStatusCareGoalCalculation(client: Acme_Careplans_V1_CareGoalCalculationService.Client(wrapping: mesh)).deliver(rec) },
            "article": { try await CopyVideoVisitStatusArticle(client: Acme_Content_V1_ArticleService.Client(wrapping: mesh)).deliver(rec) },
            "video-visit-query": { try await CopyVideoVisitStatusVideoVisitQuery(client: Acme_Telehealth_V1_VideoVisitQueryService.Client(wrapping: mesh)).deliver(rec) },
        ]
        guard let action = actions[kind] else {
            throw Kit.Failure("no action for \(kind)")
        }
        try await action()
    }
}
