import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ExportCareGoalCalculationMessage keeps of each ExplainCareGoalCalculation response.
struct ExportCareGoalCalculationMessageRecord {
    var message: String
    var referenceID: String
    var status: String
}

/// Where ExportCareGoalCalculationMessage hands each record.
protocol ExportCareGoalCalculationMessageSink {
    func push(_ rec: ExportCareGoalCalculationMessageRecord) async throws
}

/// Sends records to acme.prescriptions.v1.PrescriptionReportingService.
struct ExportCareGoalCalculationMessagePrescriptionReporting: ExportCareGoalCalculationMessageSink {
    let client: Acme_Prescriptions_V1_PrescriptionReportingService.Client<MeshTransport>

    func push(_ rec: ExportCareGoalCalculationMessageRecord) async throws {
        _ = try await client.countPrescriptionTotals(.with {
            $0.filter.ownerID = rec.message
            $0.orderBy = rec.status
        })
    }
}

/// Sends records to acme.shipping.v1.ShipmentService.
struct ExportCareGoalCalculationMessageShipment: ExportCareGoalCalculationMessageSink {
    let client: Acme_Shipping_V1_ShipmentService.Client<MeshTransport>

    func push(_ rec: ExportCareGoalCalculationMessageRecord) async throws {
        let request = Acme_Shipping_V1_GetShipmentRequest.with {
            $0.shipmentID = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.getShipment(request)
        }
    }
}

/// Sends records to acme.patients.v1.AllergyLifecycleService.
struct ExportCareGoalCalculationMessageAllergyLifecycle: ExportCareGoalCalculationMessageSink {
    let client: Acme_Patients_V1_AllergyLifecycleService.Client<MeshTransport>

    func push(_ rec: ExportCareGoalCalculationMessageRecord) async throws {
        let request = Acme_Patients_V1_SuspendAllergyRequest.with {
            $0.details.reasonCode = rec.status
            $0.reason = rec.referenceID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.suspendAllergy(request)
        }
    }
}

/// Reads acme.careplans.v1.CareGoalCalculationService/ExplainCareGoalCalculation and hands what it keeps to the sink of its kind.
enum ExportCareGoalCalculationMessage {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Careplans_V1_CareGoalCalculationService.Client(wrapping: mesh)
        let got = try await upstream.explainCareGoalCalculation(.with { $0.careGoalID = "live-export-care-goal-calculation-message" })
        let record = ExportCareGoalCalculationMessageRecord(
            message: Kit.Text.normalize(got.result.message),
            referenceID: got.outcome.referenceID,
            status: got.result.status
        )
        let sinks: [String: any ExportCareGoalCalculationMessageSink] = [
            "prescription-reporting": ExportCareGoalCalculationMessagePrescriptionReporting(client: Acme_Prescriptions_V1_PrescriptionReportingService.Client(wrapping: mesh)),
            "shipment": ExportCareGoalCalculationMessageShipment(client: Acme_Shipping_V1_ShipmentService.Client(wrapping: mesh)),
            "allergy-lifecycle": ExportCareGoalCalculationMessageAllergyLifecycle(client: Acme_Patients_V1_AllergyLifecycleService.Client(wrapping: mesh)),
        ]
        try await route("shipment", record, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: ExportCareGoalCalculationMessageRecord, _ sinks: [String: any ExportCareGoalCalculationMessageSink]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.push(rec)
    }
}
