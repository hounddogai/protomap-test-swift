import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ForwardPatientHomesToken keeps of each ListPatientHomes response.
struct ForwardPatientHomesTokenRecord {
    var nextPageToken: String
    var message: String
    var correlationID: String
}

/// Where ForwardPatientHomesToken hands each record.
protocol ForwardPatientHomesTokenDestination {
    func deliver(_ rec: ForwardPatientHomesTokenRecord) async throws
}

/// Hands records to acme.treasury.v1.CashPositionService.
struct ForwardPatientHomesTokenCashPosition: ForwardPatientHomesTokenDestination {
    let client: Acme_Treasury_V1_CashPositionService.Client<MeshTransport>

    func deliver(_ rec: ForwardPatientHomesTokenRecord) async throws {
        _ = try await client.createCashPosition(.with {
            $0.requestID = rec.correlationID
        })
    }
}

/// Hands records to acme.content.v1.ArticleQueryService.
struct ForwardPatientHomesTokenArticleQuery: ForwardPatientHomesTokenDestination {
    let client: Acme_Content_V1_ArticleQueryService.Client<MeshTransport>

    func deliver(_ rec: ForwardPatientHomesTokenRecord) async throws {
        let request = Acme_Content_V1_PeekArticleRequest.with {
            $0.articleID = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.peekArticle(request)
        }
    }
}

/// Passes records to acme.careplans.v1.VitalApprovalService.
struct ForwardPatientHomesTokenVitalApproval: ForwardPatientHomesTokenDestination {
    let client: Acme_Careplans_V1_VitalApprovalService.Client<MeshTransport>

    func deliver(_ rec: ForwardPatientHomesTokenRecord) async throws {
        _ = try await client.getVitalApprovalStatus(.with {
            $0.vitalID = rec.correlationID
        })
    }
}

/// Reads acme.patientapp.v1.PatientHomeService/ListPatientHomes and hands what it keeps to the sink of its kind.
enum ForwardPatientHomesToken {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Patientapp_V1_PatientHomeService.Client(wrapping: mesh)
        let got = try await reader.listPatientHomes(.with { $0.orderBy = "default-forward-patient-homes-token" })
        let record = ForwardPatientHomesTokenRecord(
            nextPageToken: got.pageInfo.nextPageToken,
            message: Kit.Text.normalize(got.result.message),
            correlationID: got.result.correlationID
        )
        let sinks: [String: any ForwardPatientHomesTokenDestination] = [
            "cash-position": ForwardPatientHomesTokenCashPosition(client: Acme_Treasury_V1_CashPositionService.Client(wrapping: mesh)),
            "article-query": ForwardPatientHomesTokenArticleQuery(client: Acme_Content_V1_ArticleQueryService.Client(wrapping: mesh)),
            "vital-approval": ForwardPatientHomesTokenVitalApproval(client: Acme_Careplans_V1_VitalApprovalService.Client(wrapping: mesh)),
        ]
        guard let sink = sinks[ProcessInfo.processInfo.environment["FORWARD_PATIENT_HOMES_TOKEN_TARGET"] ?? ""] else {
            return
        }
        try await sink.deliver(record)
    }
}
