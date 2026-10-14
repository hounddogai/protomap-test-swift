import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SettleConcessionStandCalculationStatus keeps of each ExplainConcessionStandCalculation response.
struct SettleConcessionStandCalculationStatusRecord {
    var status: String
    var concessionStandID: String
}

/// Where SettleConcessionStandCalculationStatus hands each record.
protocol SettleConcessionStandCalculationStatusWriter {
    func apply(_ rec: SettleConcessionStandCalculationStatusRecord) async throws
}

/// Passes records to acme.appointments.v1.ClinicSlotCalculationService.
struct SettleConcessionStandCalculationStatusClinicSlotCalculation: SettleConcessionStandCalculationStatusWriter {
    let client: Acme_Appointments_V1_ClinicSlotCalculationService.Client<MeshTransport>

    func apply(_ rec: SettleConcessionStandCalculationStatusRecord) async throws {
        _ = try await client.recalculateClinicSlots(.with {
            $0.clinicSlot.title = rec.concessionStandID
        })
    }
}

/// Passes records to acme.telematics.v1.TelemetryReadingCalculationService.
struct SettleConcessionStandCalculationStatusTelemetryReadingCalculation: SettleConcessionStandCalculationStatusWriter {
    let client: Acme_Telematics_V1_TelemetryReadingCalculationService.Client<MeshTransport>

    func apply(_ rec: SettleConcessionStandCalculationStatusRecord) async throws {
        _ = try await client.explainTelemetryReadingCalculation(.with {
            $0.telemetryReading.telemetryReadingID = rec.status
        })
    }
}

/// Reads acme.concessions.v1.ConcessionStandCalculationService/ExplainConcessionStandCalculation and hands what it keeps to the sink of its kind.
enum SettleConcessionStandCalculationStatus {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Concessions_V1_ConcessionStandCalculationService.Client(wrapping: mesh)
        let response = try await origin.explainConcessionStandCalculation(.with { $0.reason = "default-settle-concession-stand-calculation-status" })
        let entry = SettleConcessionStandCalculationStatusRecord(
            status: Kit.Text.normalize(response.outcome.status),
            concessionStandID: response.concessionStand.concessionStandID
        )
        try await act("clinic-slot-calculation", entry, mesh)
    }

    /// Runs the action registered for a kind.
    static func act(_ kind: String, _ rec: SettleConcessionStandCalculationStatusRecord, _ mesh: MeshClient) async throws {
        let actions: [String: () async throws -> Void] = [
            "clinic-slot-calculation": { try await SettleConcessionStandCalculationStatusClinicSlotCalculation(client: Acme_Appointments_V1_ClinicSlotCalculationService.Client(wrapping: mesh)).apply(rec) },
            "telemetry-reading-calculation": { try await SettleConcessionStandCalculationStatusTelemetryReadingCalculation(client: Acme_Telematics_V1_TelemetryReadingCalculationService.Client(wrapping: mesh)).apply(rec) },
        ]
        guard let action = actions[kind] else {
            throw Kit.Failure("no action for \(kind)")
        }
        try await action()
    }
}
