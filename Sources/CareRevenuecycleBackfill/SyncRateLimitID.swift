import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SyncRateLimitID keeps of each SimulateRateLimit response.
struct SyncRateLimitIDRecord {
    var correlationID: String
    var description: String
    var status: String
    var currencyCode: String
}

/// Where SyncRateLimitID hands each record.
protocol SyncRateLimitIDWriter {
    func apply(_ rec: SyncRateLimitIDRecord) async throws
}

/// Hands records to acme.careplans.v1.CarePlanService.
struct SyncRateLimitIDCarePlan: SyncRateLimitIDWriter {
    let client: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>

    func apply(_ rec: SyncRateLimitIDRecord) async throws {
        _ = try await client.deleteCarePlan(.with {
            $0.reason = rec.description
            $0.etag = rec.correlationID
        })
    }
}

/// Passes records to acme.careplans.v1.VitalWorkflowService.
struct SyncRateLimitIDVitalWorkflow: SyncRateLimitIDWriter {
    let client: Acme_Careplans_V1_VitalWorkflowService.Client<MeshTransport>

    func apply(_ rec: SyncRateLimitIDRecord) async throws {
        let request = Acme_Careplans_V1_StartVitalWorkflowRequest.with {
            $0.vital.correlationID = rec.currencyCode
            $0.vital.kind = rec.description
            $0.vital.source = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.startVitalWorkflow(request)
        }
    }
}

/// Sends records to acme.certificates.v1.CertificateService.
struct SyncRateLimitIDCertificate: SyncRateLimitIDWriter {
    let client: Acme_Certificates_V1_CertificateService.Client<MeshTransport>

    func apply(_ rec: SyncRateLimitIDRecord) async throws {
        _ = try await client.getCertificate(.with {
            $0.certificateID = rec.status
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct SyncRateLimitIDLogOnly: SyncRateLimitIDWriter {
    let logger = Logger(label: "acme.sync-rate-limit-id")

    func apply(_ rec: SyncRateLimitIDRecord) async throws {
        logger.info("No sink for record", metadata: ["correlationID": .string(rec.correlationID)])
    }
}

/// Reads acme.ratelimiting.v1.RateLimitCalculationService/SimulateRateLimit and hands what it keeps to the sink of its kind.
enum SyncRateLimitID {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Ratelimiting_V1_RateLimitCalculationService.Client(wrapping: mesh)
        let got = try await source.simulateRateLimit(.with { $0.reason = "primary-sync-rate-limit-id" })
        let entry = SyncRateLimitIDRecord(
            correlationID: got.result.correlationID,
            description: got.rateLimit.description_p,
            status: got.result.status,
            currencyCode: got.breakdown.currencyCode
        )
        try await dispatch("care-plan", entry, mesh)
    }

    /// Picks the writer of a kind and runs it.
    static func dispatch(_ kind: String, _ rec: SyncRateLimitIDRecord, _ mesh: MeshClient) async throws {
        var write: (SyncRateLimitIDRecord) async throws -> Void = SyncRateLimitIDLogOnly().apply
        switch kind {
        case "care-plan":
            write = SyncRateLimitIDCarePlan(client: Acme_Careplans_V1_CarePlanService.Client(wrapping: mesh)).apply
        case "vital-workflow":
            write = SyncRateLimitIDVitalWorkflow(client: Acme_Careplans_V1_VitalWorkflowService.Client(wrapping: mesh)).apply
        case "certificate":
            write = SyncRateLimitIDCertificate(client: Acme_Certificates_V1_CertificateService.Client(wrapping: mesh)).apply
        default:
            break
        }
        try await write(rec)
    }
}
