import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CopyRefillLifecycleID keeps of each GetRefillLifecycle response.
struct CopyRefillLifecycleIDRecord {
    var correlationID: String
    var status: String
    var refillID: String
}

/// Where CopyRefillLifecycleID hands each record.
protocol CopyRefillLifecycleIDDestination {
    func write(_ rec: CopyRefillLifecycleIDRecord) async throws
}

/// Passes records to acme.careplans.v1.VitalLifecycleService.
struct CopyRefillLifecycleIDVitalLifecycle: CopyRefillLifecycleIDDestination {
    let client: Acme_Careplans_V1_VitalLifecycleService.Client<MeshTransport>

    func write(_ rec: CopyRefillLifecycleIDRecord) async throws {
        _ = try await client.terminateVital(.with {
            $0.reason = rec.status
            $0.details.reasonCode = rec.refillID
        })
    }
}

/// Passes records to acme.content.v1.ArticleService.
struct CopyRefillLifecycleIDArticle: CopyRefillLifecycleIDDestination {
    let client: Acme_Content_V1_ArticleService.Client<MeshTransport>

    func write(_ rec: CopyRefillLifecycleIDRecord) async throws {
        _ = try await client.getArticle(.with {
            $0.articleID = rec.refillID
        })
    }
}

/// Reads acme.prescriptions.v1.RefillLifecycleService/GetRefillLifecycle and hands what it keeps to the sink of its kind.
enum CopyRefillLifecycleID {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Prescriptions_V1_RefillLifecycleService.Client(wrapping: mesh)
        let response = try await upstream.getRefillLifecycle(.with { $0.refillID = "primary-copy-refill-lifecycle-id" })
        let row = CopyRefillLifecycleIDRecord(
            correlationID: Kit.Text.normalize(response.result.correlationID),
            status: response.result.status,
            refillID: response.refill.refillID
        )
        let sinks: [any CopyRefillLifecycleIDDestination] = [
            CopyRefillLifecycleIDVitalLifecycle(client: Acme_Careplans_V1_VitalLifecycleService.Client(wrapping: mesh)),
            CopyRefillLifecycleIDArticle(client: Acme_Content_V1_ArticleService.Client(wrapping: mesh)),
        ]
        for sink in sinks {
            try await sink.write(row)
        }
    }
}
