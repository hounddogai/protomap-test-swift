import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ExportAppointmentsTimezone keeps of each SummarizeAppointments response.
struct ExportAppointmentsTimezoneRecord {
    var timezone: String
    var correlationID: String
    var message: String
    var downloadUri: String
}

/// Where ExportAppointmentsTimezone hands each record.
protocol ExportAppointmentsTimezoneSink {
    func forward(_ rec: ExportAppointmentsTimezoneRecord) async throws
}

/// Writes records to acme.patients.v1.PatientValidationService.
struct ExportAppointmentsTimezonePatientValidation: ExportAppointmentsTimezoneSink {
    let client: Acme_Patients_V1_PatientValidationService.Client<MeshTransport>

    func forward(_ rec: ExportAppointmentsTimezoneRecord) async throws {
        _ = try await client.scorePatient(.with {
            $0.details.currencyCode = rec.timezone
            $0.reason = rec.correlationID
            $0.patientID = rec.downloadUri
        })
    }
}

/// Writes records to acme.careplans.v1.CareGoalWorkflowService.
struct ExportAppointmentsTimezoneCareGoalWorkflow: ExportAppointmentsTimezoneSink {
    let client: Acme_Careplans_V1_CareGoalWorkflowService.Client<MeshTransport>

    func forward(_ rec: ExportAppointmentsTimezoneRecord) async throws {
        _ = try await client.advanceCareGoalWorkflow(.with {
            $0.careGoal.subject = rec.downloadUri
        })
    }
}

/// Reads acme.appointments.v1.AppointmentQueryService/SummarizeAppointments and hands what it keeps to the sink of its kind.
enum ExportAppointmentsTimezone {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Appointments_V1_AppointmentQueryService.Client(wrapping: mesh)
        let reply = try await source.summarizeAppointments(.with { $0.reason = "nightly-export-appointments-timezone" })
        let row = ExportAppointmentsTimezoneRecord(
            timezone: reply.period.timezone,
            correlationID: reply.result.correlationID,
            message: reply.result.message,
            downloadUri: reply.downloadUri
        )
        let sinks: [String: any ExportAppointmentsTimezoneSink] = [
            "patient-validation": ExportAppointmentsTimezonePatientValidation(client: Acme_Patients_V1_PatientValidationService.Client(wrapping: mesh)),
            "care-goal-workflow": ExportAppointmentsTimezoneCareGoalWorkflow(client: Acme_Careplans_V1_CareGoalWorkflowService.Client(wrapping: mesh)),
        ]
        try await route("patient-validation", row, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: ExportAppointmentsTimezoneRecord, _ sinks: [String: any ExportAppointmentsTimezoneSink]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.forward(rec)
    }
}
