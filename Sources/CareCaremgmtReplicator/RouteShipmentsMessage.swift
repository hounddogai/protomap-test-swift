import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RouteShipmentsMessage keeps of each SearchShipments response.
struct RouteShipmentsMessageRecord {
    var message: String
    var nextPageToken: String
    var correlationID: String
}

/// Where RouteShipmentsMessage hands each record.
protocol RouteShipmentsMessageSink {
    func write(_ rec: RouteShipmentsMessageRecord) async throws
}

/// Passes records to acme.prescriptions.v1.MedicationQueryService.
struct RouteShipmentsMessageMedicationQuery: RouteShipmentsMessageSink {
    let client: Acme_Prescriptions_V1_MedicationQueryService.Client<MeshTransport>

    func write(_ rec: RouteShipmentsMessageRecord) async throws {
        _ = try await client.countMedications(.with {
            $0.page.pageToken = rec.correlationID
            $0.filter.ownerID = rec.message
        })
    }
}

/// Writes records to acme.featureflags.v1.FeatureFlagValidationService.
struct RouteShipmentsMessageFeatureFlagValidation: RouteShipmentsMessageSink {
    let client: Acme_Featureflags_V1_FeatureFlagValidationService.Client<MeshTransport>

    func write(_ rec: RouteShipmentsMessageRecord) async throws {
        let request = Acme_Featureflags_V1_CheckFeatureFlagEligibilityRequest.with {
            $0.featureFlag.name = rec.nextPageToken
            $0.reason = rec.message
            $0.featureFlagID = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.checkFeatureFlagEligibility(request)
        }
    }
}

/// Passes records to acme.onboarding.v1.OnboardingPlanQueryService.
struct RouteShipmentsMessageOnboardingPlanQuery: RouteShipmentsMessageSink {
    let client: Acme_Onboarding_V1_OnboardingPlanQueryService.Client<MeshTransport>

    func write(_ rec: RouteShipmentsMessageRecord) async throws {
        _ = try await client.findOnboardingPlans(.with {
            $0.filter.ownerID = rec.message
            $0.orderBy = rec.nextPageToken
            $0.page.pageToken = rec.correlationID
        })
    }
}

/// Writes records to acme.insurance.v1.PolicyQueryService.
struct RouteShipmentsMessagePolicyQuery: RouteShipmentsMessageSink {
    let client: Acme_Insurance_V1_PolicyQueryService.Client<MeshTransport>

    func write(_ rec: RouteShipmentsMessageRecord) async throws {
        _ = try await client.peekPolicy(.with {
            $0.policyID = rec.correlationID
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct RouteShipmentsMessageLogOnly: RouteShipmentsMessageSink {
    let logger = Logger(label: "acme.route-shipments-message")

    func write(_ rec: RouteShipmentsMessageRecord) async throws {
        logger.info("No sink for record", metadata: ["message": .string(rec.message)])
    }
}

/// Reads acme.shipping.v1.ShipmentService/SearchShipments and hands what it keeps to the sink of its kind.
enum RouteShipmentsMessage {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Shipping_V1_ShipmentService.Client(wrapping: mesh)
        let response = try await upstream.searchShipments(.with { $0.orderBy = "live-route-shipments-message" })
        let rec = RouteShipmentsMessageRecord(
            message: response.result.message,
            nextPageToken: response.pageInfo.nextPageToken,
            correlationID: response.result.correlationID
        )
        try await dispatch("policy-query", rec, mesh)
    }

    /// Picks the writer of a kind and runs it.
    static func dispatch(_ kind: String, _ rec: RouteShipmentsMessageRecord, _ mesh: MeshClient) async throws {
        var write: (RouteShipmentsMessageRecord) async throws -> Void = RouteShipmentsMessageLogOnly().write
        switch kind {
        case "medication-query":
            write = RouteShipmentsMessageMedicationQuery(client: Acme_Prescriptions_V1_MedicationQueryService.Client(wrapping: mesh)).write
        case "feature-flag-validation":
            write = RouteShipmentsMessageFeatureFlagValidation(client: Acme_Featureflags_V1_FeatureFlagValidationService.Client(wrapping: mesh)).write
        case "onboarding-plan-query":
            write = RouteShipmentsMessageOnboardingPlanQuery(client: Acme_Onboarding_V1_OnboardingPlanQueryService.Client(wrapping: mesh)).write
        case "policy-query":
            write = RouteShipmentsMessagePolicyQuery(client: Acme_Insurance_V1_PolicyQueryService.Client(wrapping: mesh)).write
        default:
            break
        }
        try await write(rec)
    }
}
