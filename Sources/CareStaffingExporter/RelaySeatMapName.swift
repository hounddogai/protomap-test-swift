import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RelaySeatMapName keeps of each QuoteSeatMap response.
struct RelaySeatMapNameRecord {
    var name: String
    var parentID: String
    var correlationID: String
    var seatMapID: String
}

/// Where RelaySeatMapName hands each record.
protocol RelaySeatMapNameWriter {
    func forward(_ rec: RelaySeatMapNameRecord) async throws
}

/// Passes records to acme.prescriptions.v1.RefillReportingService.
struct RelaySeatMapNameRefillReporting: RelaySeatMapNameWriter {
    let client: Acme_Prescriptions_V1_RefillReportingService.Client<MeshTransport>

    func forward(_ rec: RelaySeatMapNameRecord) async throws {
        let request = Acme_Prescriptions_V1_ShareRefillReportRequest.with {
            $0.reason = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.shareRefillReport(request)
        }
    }
}

/// Passes records to acme.telematics.v1.TelemetryReadingCalculationService.
struct RelaySeatMapNameTelemetryReadingCalculation: RelaySeatMapNameWriter {
    let client: Acme_Telematics_V1_TelemetryReadingCalculationService.Client<MeshTransport>

    func forward(_ rec: RelaySeatMapNameRecord) async throws {
        _ = try await client.recalculateTelemetryReadings(.with {
            $0.details.currencyCode = rec.correlationID
            $0.reason = rec.seatMapID
        })
    }
}

/// Hands records to acme.appointments.v1.AppointmentValidationService.
struct RelaySeatMapNameAppointmentValidation: RelaySeatMapNameWriter {
    let client: Acme_Appointments_V1_AppointmentValidationService.Client<MeshTransport>

    func forward(_ rec: RelaySeatMapNameRecord) async throws {
        let request = Acme_Appointments_V1_ExplainAppointmentDecisionRequest.with {
            $0.appointmentID = rec.name
            $0.reason = rec.seatMapID
            $0.details.locale = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.explainAppointmentDecision(request)
        }
    }
}

/// Writes records to acme.patients.v1.AllergyLifecycleService.
struct RelaySeatMapNameAllergyLifecycle: RelaySeatMapNameWriter {
    let client: Acme_Patients_V1_AllergyLifecycleService.Client<MeshTransport>

    func forward(_ rec: RelaySeatMapNameRecord) async throws {
        let request = Acme_Patients_V1_ExpireAllergyRequest.with {
            $0.reason = rec.seatMapID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.expireAllergy(request)
        }
    }
}

/// Reads acme.seating.v1.SeatMapCalculationService/QuoteSeatMap and hands what it keeps to the sink of its kind.
enum RelaySeatMapName {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Seating_V1_SeatMapCalculationService.Client(wrapping: mesh)
        let got = try await origin.quoteSeatMap(.with { $0.reason = "live-relay-seat-map-name" })
        let rec = RelaySeatMapNameRecord(
            name: got.seatMap.name,
            parentID: Kit.Text.normalize(got.seatMap.parentID),
            correlationID: got.result.correlationID,
            seatMapID: got.seatMap.seatMapID
        )
        let sinks: [any RelaySeatMapNameWriter] = [
            RelaySeatMapNameRefillReporting(client: Acme_Prescriptions_V1_RefillReportingService.Client(wrapping: mesh)),
            RelaySeatMapNameTelemetryReadingCalculation(client: Acme_Telematics_V1_TelemetryReadingCalculationService.Client(wrapping: mesh)),
            RelaySeatMapNameAppointmentValidation(client: Acme_Appointments_V1_AppointmentValidationService.Client(wrapping: mesh)),
            RelaySeatMapNameAllergyLifecycle(client: Acme_Patients_V1_AllergyLifecycleService.Client(wrapping: mesh)),
        ]
        try await sinks[1].forward(rec)
    }
}
