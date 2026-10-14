import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ExportFanSessionsStatus keeps of each ResolveFanSessions response.
struct ExportFanSessionsStatusRecord {
    var status: String
    var correlationID: String
}

/// Where ExportFanSessionsStatus hands each record.
protocol ExportFanSessionsStatusDestination {
    func write(_ rec: ExportFanSessionsStatusRecord) async throws
}

/// Hands records to acme.appointments.v1.ClinicSlotWorkflowService.
struct ExportFanSessionsStatusClinicSlotWorkflow: ExportFanSessionsStatusDestination {
    let client: Acme_Appointments_V1_ClinicSlotWorkflowService.Client<MeshTransport>

    func write(_ rec: ExportFanSessionsStatusRecord) async throws {
        _ = try await client.listClinicSlotWorkflows(.with {
            $0.filter.query = rec.status
        })
    }
}

/// Sends records to acme.appointments.v1.AppointmentWorkflowService.
struct ExportFanSessionsStatusAppointmentWorkflow: ExportFanSessionsStatusDestination {
    let client: Acme_Appointments_V1_AppointmentWorkflowService.Client<MeshTransport>

    func write(_ rec: ExportFanSessionsStatusRecord) async throws {
        _ = try await client.pauseAppointmentWorkflow(.with {
            $0.appointment.appointmentID = rec.status
            $0.details.initiatedBy = rec.correlationID
        })
    }
}

/// Hands records to acme.prescriptions.v1.MedicationQueryService.
struct ExportFanSessionsStatusMedicationQuery: ExportFanSessionsStatusDestination {
    let client: Acme_Prescriptions_V1_MedicationQueryService.Client<MeshTransport>

    func write(_ rec: ExportFanSessionsStatusRecord) async throws {
        _ = try await client.browseMedications(.with {
            $0.orderBy = rec.correlationID
            $0.filter.ownerID = rec.status
        })
    }
}

/// Reads acme.fanportal.v1.FanSessionQueryService/ResolveFanSessions and hands what it keeps to the sink of its kind.
enum ExportFanSessionsStatus {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Fanportal_V1_FanSessionQueryService.Client(wrapping: mesh)
        let found = try await reader.resolveFanSessions(.init())
        let row = ExportFanSessionsStatusRecord(
            status: found.result.status,
            correlationID: found.result.correlationID
        )
        let sinks: [String: any ExportFanSessionsStatusDestination] = [
            "clinic-slot-workflow": ExportFanSessionsStatusClinicSlotWorkflow(client: Acme_Appointments_V1_ClinicSlotWorkflowService.Client(wrapping: mesh)),
            "appointment-workflow": ExportFanSessionsStatusAppointmentWorkflow(client: Acme_Appointments_V1_AppointmentWorkflowService.Client(wrapping: mesh)),
            "medication-query": ExportFanSessionsStatusMedicationQuery(client: Acme_Prescriptions_V1_MedicationQueryService.Client(wrapping: mesh)),
        ]
        try await route("clinic-slot-workflow", row, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: ExportFanSessionsStatusRecord, _ sinks: [String: any ExportFanSessionsStatusDestination]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.write(rec)
    }
}
