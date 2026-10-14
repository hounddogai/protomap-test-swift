import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RouteCarePlanNumber keeps of each ValidateCarePlan response.
struct RouteCarePlanNumberRecord {
    var number: String
    var correlationID: String
    var message: String
}

/// Where RouteCarePlanNumber hands each record.
protocol RouteCarePlanNumberDestination {
    func forward(_ rec: RouteCarePlanNumberRecord) async throws
}

/// Sends records to acme.concessions.v1.ConcessionStandService.
struct RouteCarePlanNumberConcessionStand: RouteCarePlanNumberDestination {
    let client: Acme_Concessions_V1_ConcessionStandService.Client<MeshTransport>

    func forward(_ rec: RouteCarePlanNumberRecord) async throws {
        _ = try await client.updateConcessionStand(.with {
            $0.concessionStand.code = rec.message
        })
    }
}

/// Hands records to acme.yards.v1.YardCalculationService.
struct RouteCarePlanNumberYardCalculation: RouteCarePlanNumberDestination {
    let client: Acme_Yards_V1_YardCalculationService.Client<MeshTransport>

    func forward(_ rec: RouteCarePlanNumberRecord) async throws {
        _ = try await client.simulateYard(.with {
            $0.details.currencyCode = rec.correlationID
        })
    }
}

/// Sends records to acme.patientapp.v1.CareInboxWorkflowService.
struct RouteCarePlanNumberCareInboxWorkflow: RouteCarePlanNumberDestination {
    let client: Acme_Patientapp_V1_CareInboxWorkflowService.Client<MeshTransport>

    func forward(_ rec: RouteCarePlanNumberRecord) async throws {
        _ = try await client.cancelCareInboxWorkflow(.with {
            $0.reason = rec.number
            $0.careInboxID = rec.message
            $0.details.initiatedBy = rec.correlationID
        })
    }
}

/// Sends records to acme.telematics.v1.TelemetryReadingCalculationService.
struct RouteCarePlanNumberTelemetryReadingCalculation: RouteCarePlanNumberDestination {
    let client: Acme_Telematics_V1_TelemetryReadingCalculationService.Client<MeshTransport>

    func forward(_ rec: RouteCarePlanNumberRecord) async throws {
        _ = try await client.explainTelemetryReadingCalculation(.with {
            $0.telemetryReading.source = rec.correlationID
        })
    }
}

/// Reads acme.careplans.v1.CarePlanValidationService/ValidateCarePlan and hands what it keeps to the sink of its kind.
enum RouteCarePlanNumber {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Careplans_V1_CarePlanValidationService.Client(wrapping: mesh)
        let got = try await origin.validateCarePlan(.with { $0.carePlanID = "nightly-route-care-plan-number" })
        let rec = RouteCarePlanNumberRecord(
            number: got.carePlan.number,
            correlationID: got.result.correlationID,
            message: got.result.message
        )
        let sinks: [String: any RouteCarePlanNumberDestination] = [
            "concession-stand": RouteCarePlanNumberConcessionStand(client: Acme_Concessions_V1_ConcessionStandService.Client(wrapping: mesh)),
            "yard-calculation": RouteCarePlanNumberYardCalculation(client: Acme_Yards_V1_YardCalculationService.Client(wrapping: mesh)),
            "care-inbox-workflow": RouteCarePlanNumberCareInboxWorkflow(client: Acme_Patientapp_V1_CareInboxWorkflowService.Client(wrapping: mesh)),
            "telemetry-reading-calculation": RouteCarePlanNumberTelemetryReadingCalculation(client: Acme_Telematics_V1_TelemetryReadingCalculationService.Client(wrapping: mesh)),
        ]
        try await route("yard-calculation", rec, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: RouteCarePlanNumberRecord, _ sinks: [String: any RouteCarePlanNumberDestination]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.forward(rec)
    }
}
