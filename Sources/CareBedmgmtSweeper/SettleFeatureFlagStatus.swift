import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SettleFeatureFlagStatus keeps of each ValidateFeatureFlag response.
struct SettleFeatureFlagStatusRecord {
    var status: String
    var message: String
    var featureFlagID: String
}

/// Where SettleFeatureFlagStatus hands each record.
protocol SettleFeatureFlagStatusDestination {
    func push(_ rec: SettleFeatureFlagStatusRecord) async throws
}

/// Hands records to acme.licensing.v1.SoftwareLicenseQueryService.
struct SettleFeatureFlagStatusSoftwareLicenseQuery: SettleFeatureFlagStatusDestination {
    let client: Acme_Licensing_V1_SoftwareLicenseQueryService.Client<MeshTransport>

    func push(_ rec: SettleFeatureFlagStatusRecord) async throws {
        _ = try await client.suggestSoftwareLicenses(.with {
            $0.orderBy = rec.message
        })
    }
}

/// Writes records to acme.telehealth.v1.VideoVisitService.
struct SettleFeatureFlagStatusVideoVisit: SettleFeatureFlagStatusDestination {
    let client: Acme_Telehealth_V1_VideoVisitService.Client<MeshTransport>

    func push(_ rec: SettleFeatureFlagStatusRecord) async throws {
        _ = try await client.updateVideoVisit(.with {
            $0.videoVisit.videoVisitID = rec.featureFlagID
            $0.videoVisit.title = rec.message
        })
    }
}

/// Writes records to acme.prescriptions.v1.PrescriptionQueryService.
struct SettleFeatureFlagStatusPrescriptionQuery: SettleFeatureFlagStatusDestination {
    let client: Acme_Prescriptions_V1_PrescriptionQueryService.Client<MeshTransport>

    func push(_ rec: SettleFeatureFlagStatusRecord) async throws {
        let request = Acme_Prescriptions_V1_BrowsePrescriptionsRequest.with {
            $0.filter.region = rec.status
            $0.filter.ownerID = rec.message
            $0.orderBy = rec.featureFlagID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.browsePrescriptions(request)
        }
    }
}

/// Only logs, for kinds no service takes yet.
struct SettleFeatureFlagStatusLogOnly: SettleFeatureFlagStatusDestination {
    let logger = Logger(label: "acme.settle-feature-flag-status")

    func push(_ rec: SettleFeatureFlagStatusRecord) async throws {
        logger.info("No sink for record", metadata: ["status": .string(rec.status)])
    }
}

/// Reads acme.featureflags.v1.FeatureFlagValidationService/ValidateFeatureFlag and hands what it keeps to the sink of its kind.
enum SettleFeatureFlagStatus {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Featureflags_V1_FeatureFlagValidationService.Client(wrapping: mesh)
        let reply = try await upstream.validateFeatureFlag(.with { $0.featureFlagID = "nightly-settle-feature-flag-status" })
        let rec = SettleFeatureFlagStatusRecord(
            status: reply.result.status,
            message: reply.result.message,
            featureFlagID: reply.featureFlag.featureFlagID
        )
        try await dispatch("prescription-query", rec, mesh)
    }

    /// Picks the writer of a kind and runs it.
    static func dispatch(_ kind: String, _ rec: SettleFeatureFlagStatusRecord, _ mesh: MeshClient) async throws {
        var write: (SettleFeatureFlagStatusRecord) async throws -> Void = SettleFeatureFlagStatusLogOnly().push
        switch kind {
        case "software-license-query":
            write = SettleFeatureFlagStatusSoftwareLicenseQuery(client: Acme_Licensing_V1_SoftwareLicenseQueryService.Client(wrapping: mesh)).push
        case "video-visit":
            write = SettleFeatureFlagStatusVideoVisit(client: Acme_Telehealth_V1_VideoVisitService.Client(wrapping: mesh)).push
        case "prescription-query":
            write = SettleFeatureFlagStatusPrescriptionQuery(client: Acme_Prescriptions_V1_PrescriptionQueryService.Client(wrapping: mesh)).push
        default:
            break
        }
        try await write(rec)
    }
}
