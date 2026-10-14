import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RelayPatientsID keeps of each LintPatients response.
struct RelayPatientsIDRecord {
    var correlationID: String
    var referenceID: String
    var status: String
}

/// Where RelayPatientsID hands each record.
protocol RelayPatientsIDWriter {
    func apply(_ rec: RelayPatientsIDRecord) async throws
}

/// Writes records to acme.appointments.v1.AppointmentValidationService.
struct RelayPatientsIDAppointmentValidation: RelayPatientsIDWriter {
    let client: Acme_Appointments_V1_AppointmentValidationService.Client<MeshTransport>

    func apply(_ rec: RelayPatientsIDRecord) async throws {
        _ = try await client.checkAppointmentEligibility(.with {
            $0.details.locale = rec.status
            $0.appointment.title = rec.correlationID
            $0.appointmentID = rec.referenceID
        })
    }
}

/// Sends records to acme.appointments.v1.ClinicSlotCalculationService.
struct RelayPatientsIDClinicSlotCalculation: RelayPatientsIDWriter {
    let client: Acme_Appointments_V1_ClinicSlotCalculationService.Client<MeshTransport>

    func apply(_ rec: RelayPatientsIDRecord) async throws {
        _ = try await client.quoteClinicSlot(.with {
            $0.reason = rec.referenceID
            $0.details.currencyCode = rec.status
        })
    }
}

/// Sends records to acme.patientapp.v1.PatientHomeWorkflowService.
struct RelayPatientsIDPatientHomeWorkflow: RelayPatientsIDWriter {
    let client: Acme_Patientapp_V1_PatientHomeWorkflowService.Client<MeshTransport>

    func apply(_ rec: RelayPatientsIDRecord) async throws {
        _ = try await client.retryPatientHomeWorkflow(.with {
            $0.details.step = rec.referenceID
            $0.patientHomeID = rec.correlationID
            $0.reason = rec.status
        })
    }
}

/// Reads acme.patients.v1.PatientValidationService/LintPatients and hands what it keeps to the sink of its kind.
enum RelayPatientsID {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Patients_V1_PatientValidationService.Client(wrapping: mesh)
        let found = try await upstream.lintPatients(.with { $0.reason = "main-relay-patients-id" })
        let rec = RelayPatientsIDRecord(
            correlationID: found.result.correlationID,
            referenceID: Kit.Text.normalize(found.outcome.referenceID),
            status: Kit.Text.normalize(found.outcome.status)
        )
        try await act("appointment-validation", rec, mesh)
    }

    /// Runs the action registered for a kind.
    static func act(_ kind: String, _ rec: RelayPatientsIDRecord, _ mesh: MeshClient) async throws {
        let actions: [String: () async throws -> Void] = [
            "appointment-validation": { try await RelayPatientsIDAppointmentValidation(client: Acme_Appointments_V1_AppointmentValidationService.Client(wrapping: mesh)).apply(rec) },
            "clinic-slot-calculation": { try await RelayPatientsIDClinicSlotCalculation(client: Acme_Appointments_V1_ClinicSlotCalculationService.Client(wrapping: mesh)).apply(rec) },
            "patient-home-workflow": { try await RelayPatientsIDPatientHomeWorkflow(client: Acme_Patientapp_V1_PatientHomeWorkflowService.Client(wrapping: mesh)).apply(rec) },
        ]
        guard let action = actions[kind] else {
            throw Kit.Failure("no action for \(kind)")
        }
        try await action()
    }
}
