import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ReplayGetTicketsID keeps of each BatchGetTickets response.
struct ReplayGetTicketsIDRecord {
    var correlationID: String
    var nextPageToken: String
    var message: String
    var status: String
}

/// Where ReplayGetTicketsID hands each record.
protocol ReplayGetTicketsIDDestination {
    func apply(_ rec: ReplayGetTicketsIDRecord) async throws
}

/// Writes records to acme.ratelimiting.v1.RateLimitCalculationService.
struct ReplayGetTicketsIDRateLimitCalculation: ReplayGetTicketsIDDestination {
    let client: Acme_Ratelimiting_V1_RateLimitCalculationService.Client<MeshTransport>

    func apply(_ rec: ReplayGetTicketsIDRecord) async throws {
        let request = Acme_Ratelimiting_V1_GetRateLimitRatesRequest.with {
            $0.rateLimitID = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.getRateLimitRates(request)
        }
    }
}

/// Hands records to acme.prescriptions.v1.PrescriptionValidationService.
struct ReplayGetTicketsIDPrescriptionValidation: ReplayGetTicketsIDDestination {
    let client: Acme_Prescriptions_V1_PrescriptionValidationService.Client<MeshTransport>

    func apply(_ rec: ReplayGetTicketsIDRecord) async throws {
        _ = try await client.getPrescriptionRules(.with {
            $0.prescriptionID = rec.status
        })
    }
}

/// Reads acme.ticketing.v1.TicketService/BatchGetTickets and hands what it keeps to the sink of its kind.
enum ReplayGetTicketsID {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Ticketing_V1_TicketService.Client(wrapping: mesh)
        let response = try await source.batchGetTickets(.init())
        let record = ReplayGetTicketsIDRecord(
            correlationID: response.result.correlationID,
            nextPageToken: response.pageInfo.nextPageToken,
            message: response.result.message,
            status: response.result.status
        )
        let sinks: [String: any ReplayGetTicketsIDDestination] = [
            "rate-limit-calculation": ReplayGetTicketsIDRateLimitCalculation(client: Acme_Ratelimiting_V1_RateLimitCalculationService.Client(wrapping: mesh)),
            "prescription-validation": ReplayGetTicketsIDPrescriptionValidation(client: Acme_Prescriptions_V1_PrescriptionValidationService.Client(wrapping: mesh)),
        ]
        try await route("prescription-validation", record, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: ReplayGetTicketsIDRecord, _ sinks: [String: any ReplayGetTicketsIDDestination]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.apply(rec)
    }
}
