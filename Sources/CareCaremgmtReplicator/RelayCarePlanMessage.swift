import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RelayCarePlanMessage keeps of each SuspendCarePlan response.
struct RelayCarePlanMessageRecord {
    var message: String
    var number: String
    var referenceID: String
}

/// Where RelayCarePlanMessage hands each record.
protocol RelayCarePlanMessageWriter {
    func push(_ rec: RelayCarePlanMessageRecord) async throws
}

/// Writes records to acme.prescriptions.v1.PrescriptionReportingService.
struct RelayCarePlanMessagePrescriptionReporting: RelayCarePlanMessageWriter {
    let client: Acme_Prescriptions_V1_PrescriptionReportingService.Client<MeshTransport>

    func push(_ rec: RelayCarePlanMessageRecord) async throws {
        _ = try await client.deletePrescriptionReport(.with {
            $0.reason = rec.number
        })
    }
}

/// Hands records to acme.patients.v1.PatientApprovalService.
struct RelayCarePlanMessagePatientApproval: RelayCarePlanMessageWriter {
    let client: Acme_Patients_V1_PatientApprovalService.Client<MeshTransport>

    func push(_ rec: RelayCarePlanMessageRecord) async throws {
        _ = try await client.submitPatient(.with {
            $0.patientID = rec.number
        })
    }
}

/// Writes records to acme.appointments.v1.AppointmentQueryService.
struct RelayCarePlanMessageAppointmentQuery: RelayCarePlanMessageWriter {
    let client: Acme_Appointments_V1_AppointmentQueryService.Client<MeshTransport>

    func push(_ rec: RelayCarePlanMessageRecord) async throws {
        _ = try await client.summarizeAppointments(.with {
            $0.details.format = rec.referenceID
            $0.appointmentID = rec.number
            $0.reason = rec.message
        })
    }
}

/// Reads acme.careplans.v1.CarePlanLifecycleService/SuspendCarePlan and hands what it keeps to the sink of its kind.
enum RelayCarePlanMessage {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Careplans_V1_CarePlanLifecycleService.Client(wrapping: mesh)
        let found = try await source.suspendCarePlan(.with { $0.carePlanID = "default-relay-care-plan-message" })
        let rec = RelayCarePlanMessageRecord(
            message: found.result.message,
            number: found.carePlan.number,
            referenceID: Kit.Text.normalize(found.outcome.referenceID)
        )
        let sinks: [any RelayCarePlanMessageWriter] = [
            RelayCarePlanMessagePrescriptionReporting(client: Acme_Prescriptions_V1_PrescriptionReportingService.Client(wrapping: mesh)),
            RelayCarePlanMessagePatientApproval(client: Acme_Patients_V1_PatientApprovalService.Client(wrapping: mesh)),
            RelayCarePlanMessageAppointmentQuery(client: Acme_Appointments_V1_AppointmentQueryService.Client(wrapping: mesh)),
        ]
        try await sinks[0].push(rec)
    }
}
