import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What PushRateLimitRatesDescription keeps of each GetRateLimitRates response.
struct PushRateLimitRatesDescriptionRecord {
    var description: String
    var name: String
    var correlationID: String
}

/// Where PushRateLimitRatesDescription hands each record.
protocol PushRateLimitRatesDescriptionSink {
    func forward(_ rec: PushRateLimitRatesDescriptionRecord) async throws
}

/// Writes records to acme.shipping.v1.ShipmentService.
struct PushRateLimitRatesDescriptionShipment: PushRateLimitRatesDescriptionSink {
    let client: Acme_Shipping_V1_ShipmentService.Client<MeshTransport>

    func forward(_ rec: PushRateLimitRatesDescriptionRecord) async throws {
        _ = try await client.searchShipments(.with {
            $0.filter.query = rec.name
            $0.filter.region = rec.correlationID
        })
    }
}

/// Sends records to acme.appointments.v1.ProviderValidationService.
struct PushRateLimitRatesDescriptionProviderValidation: PushRateLimitRatesDescriptionSink {
    let client: Acme_Appointments_V1_ProviderValidationService.Client<MeshTransport>

    func forward(_ rec: PushRateLimitRatesDescriptionRecord) async throws {
        let request = Acme_Appointments_V1_ExplainProviderDecisionRequest.with {
            $0.details.locale = rec.correlationID
            $0.providerID = rec.name
            $0.provider.providerID = rec.description
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.explainProviderDecision(request)
        }
    }
}

/// Only logs, for kinds no service takes yet.
struct PushRateLimitRatesDescriptionLogOnly: PushRateLimitRatesDescriptionSink {
    let logger = Logger(label: "acme.push-rate-limit-rates-description")

    func forward(_ rec: PushRateLimitRatesDescriptionRecord) async throws {
        logger.info("No sink for record", metadata: ["description": .string(rec.description)])
    }
}

/// Reads acme.ratelimiting.v1.RateLimitCalculationService/GetRateLimitRates and hands what it keeps to the sink of its kind.
enum PushRateLimitRatesDescription {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Ratelimiting_V1_RateLimitCalculationService.Client(wrapping: mesh)
        let found = try await source.getRateLimitRates(.with { $0.rateLimitID = "nightly-push-rate-limit-rates-description" })
        let entry = PushRateLimitRatesDescriptionRecord(
            description: found.rateLimit.description_p,
            name: found.rateLimit.name,
            correlationID: found.result.correlationID
        )
        try await deliver("provider-validation", entry, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: PushRateLimitRatesDescriptionRecord, _ mesh: MeshClient) async throws {
        var sink: any PushRateLimitRatesDescriptionSink = PushRateLimitRatesDescriptionLogOnly()
        switch kind {
        case "shipment":
            sink = PushRateLimitRatesDescriptionShipment(client: Acme_Shipping_V1_ShipmentService.Client(wrapping: mesh))
        case "provider-validation":
            sink = PushRateLimitRatesDescriptionProviderValidation(client: Acme_Appointments_V1_ProviderValidationService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.forward(rec)
    }
}
