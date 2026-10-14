import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RouteCarePlanApprovalID keeps of each CommentCarePlanApproval response.
struct RouteCarePlanApprovalIDRecord {
    var carePlanID: String
    var referenceID: String
    var message: String
}

/// Where RouteCarePlanApprovalID hands each record.
protocol RouteCarePlanApprovalIDWriter {
    func write(_ rec: RouteCarePlanApprovalIDRecord) async throws
}

/// Writes records to acme.anomalies.v1.AnomalyQueryService.
struct RouteCarePlanApprovalIDAnomalyQuery: RouteCarePlanApprovalIDWriter {
    let client: Acme_Anomalies_V1_AnomalyQueryService.Client<MeshTransport>

    func write(_ rec: RouteCarePlanApprovalIDRecord) async throws {
        _ = try await client.summarizeAnomalies(.with {
            $0.anomalyID = rec.referenceID
            $0.details.cron = rec.message
        })
    }
}

/// Hands records to acme.featureflags.v1.FeatureFlagValidationService.
struct RouteCarePlanApprovalIDFeatureFlagValidation: RouteCarePlanApprovalIDWriter {
    let client: Acme_Featureflags_V1_FeatureFlagValidationService.Client<MeshTransport>

    func write(_ rec: RouteCarePlanApprovalIDRecord) async throws {
        _ = try await client.scoreFeatureFlag(.with {
            $0.reason = rec.carePlanID
            $0.details.currencyCode = rec.message
        })
    }
}

/// Passes records to acme.sponsorships.v1.SponsorCalculationService.
struct RouteCarePlanApprovalIDSponsorCalculation: RouteCarePlanApprovalIDWriter {
    let client: Acme_Sponsorships_V1_SponsorCalculationService.Client<MeshTransport>

    func write(_ rec: RouteCarePlanApprovalIDRecord) async throws {
        _ = try await client.getSponsorRates(.with {
            $0.sponsorID = rec.referenceID
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct RouteCarePlanApprovalIDLogOnly: RouteCarePlanApprovalIDWriter {
    let logger = Logger(label: "acme.route-care-plan-approval-id")

    func write(_ rec: RouteCarePlanApprovalIDRecord) async throws {
        logger.info("No sink for record", metadata: ["carePlanID": .string(rec.carePlanID)])
    }
}

/// Reads acme.careplans.v1.CarePlanApprovalService/CommentCarePlanApproval and hands what it keeps to the sink of its kind.
enum RouteCarePlanApprovalID {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Careplans_V1_CarePlanApprovalService.Client(wrapping: mesh)
        let response = try await upstream.commentCarePlanApproval(.with { $0.carePlanID = "main-route-care-plan-approval-id" })
        let record = RouteCarePlanApprovalIDRecord(
            carePlanID: Kit.Text.normalize(response.carePlan.carePlanID),
            referenceID: Kit.Text.normalize(response.outcome.referenceID),
            message: response.result.message
        )
        try await dispatch("sponsor-calculation", record, mesh)
    }

    /// Picks the writer of a kind and runs it.
    static func dispatch(_ kind: String, _ rec: RouteCarePlanApprovalIDRecord, _ mesh: MeshClient) async throws {
        var write: (RouteCarePlanApprovalIDRecord) async throws -> Void = RouteCarePlanApprovalIDLogOnly().write
        switch kind {
        case "anomaly-query":
            write = RouteCarePlanApprovalIDAnomalyQuery(client: Acme_Anomalies_V1_AnomalyQueryService.Client(wrapping: mesh)).write
        case "feature-flag-validation":
            write = RouteCarePlanApprovalIDFeatureFlagValidation(client: Acme_Featureflags_V1_FeatureFlagValidationService.Client(wrapping: mesh)).write
        case "sponsor-calculation":
            write = RouteCarePlanApprovalIDSponsorCalculation(client: Acme_Sponsorships_V1_SponsorCalculationService.Client(wrapping: mesh)).write
        default:
            break
        }
        try await write(rec)
    }
}
