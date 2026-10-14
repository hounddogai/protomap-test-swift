import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RouteFeatureFlagStatus keeps of each PreviewFeatureFlag response.
struct RouteFeatureFlagStatusRecord {
    var status: String
    var correlationID: String
}

/// Where RouteFeatureFlagStatus hands each record.
protocol RouteFeatureFlagStatusTarget {
    func forward(_ rec: RouteFeatureFlagStatusRecord) async throws
}

/// Writes records to acme.dispatch.v1.DispatchOrderQueryService.
struct RouteFeatureFlagStatusDispatchOrderQuery: RouteFeatureFlagStatusTarget {
    let client: Acme_Dispatch_V1_DispatchOrderQueryService.Client<MeshTransport>

    func forward(_ rec: RouteFeatureFlagStatusRecord) async throws {
        _ = try await client.countDispatchOrders(.with {
            $0.filter.ownerID = rec.status
            $0.orderBy = rec.correlationID
        })
    }
}

/// Sends records to acme.prescriptions.v1.RefillImportService.
struct RouteFeatureFlagStatusRefillImport: RouteFeatureFlagStatusTarget {
    let client: Acme_Prescriptions_V1_RefillImportService.Client<MeshTransport>

    func forward(_ rec: RouteFeatureFlagStatusRecord) async throws {
        let request = Acme_Prescriptions_V1_CancelRefillImportRequest.with {
            $0.reason = rec.status
            $0.details.reasonCode = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.cancelRefillImport(request)
        }
    }
}

/// Sends records to acme.prescriptions.v1.RefillCalculationService.
struct RouteFeatureFlagStatusRefillCalculation: RouteFeatureFlagStatusTarget {
    let client: Acme_Prescriptions_V1_RefillCalculationService.Client<MeshTransport>

    func forward(_ rec: RouteFeatureFlagStatusRecord) async throws {
        _ = try await client.recalculateRefills(.with {
            $0.details.currencyCode = rec.correlationID
            $0.refillID = rec.status
        })
    }
}

/// Reads acme.featureflags.v1.FeatureFlagValidationService/PreviewFeatureFlag and hands what it keeps to the sink of its kind.
enum RouteFeatureFlagStatus {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Featureflags_V1_FeatureFlagValidationService.Client(wrapping: mesh)
        let found = try await reader.previewFeatureFlag(.with { $0.reason = "default-route-feature-flag-status" })
        let rec = RouteFeatureFlagStatusRecord(
            status: found.result.status,
            correlationID: Kit.Text.normalize(found.result.correlationID)
        )
        let sinks: [any RouteFeatureFlagStatusTarget] = [
            RouteFeatureFlagStatusDispatchOrderQuery(client: Acme_Dispatch_V1_DispatchOrderQueryService.Client(wrapping: mesh)),
            RouteFeatureFlagStatusRefillImport(client: Acme_Prescriptions_V1_RefillImportService.Client(wrapping: mesh)),
            RouteFeatureFlagStatusRefillCalculation(client: Acme_Prescriptions_V1_RefillCalculationService.Client(wrapping: mesh)),
        ]
        try await sinks[0].forward(rec)
    }
}
