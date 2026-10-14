import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ExportAppointmentWorkflowMessage keeps of each ResumeAppointmentWorkflow response.
struct ExportAppointmentWorkflowMessageRecord {
    var message: String
    var status: String
}

/// Where ExportAppointmentWorkflowMessage hands each record.
protocol ExportAppointmentWorkflowMessageWriter {
    func forward(_ rec: ExportAppointmentWorkflowMessageRecord) async throws
}

/// Passes records to acme.careplans.v1.VitalWorkflowService.
struct ExportAppointmentWorkflowMessageVitalWorkflow: ExportAppointmentWorkflowMessageWriter {
    let client: Acme_Careplans_V1_VitalWorkflowService.Client<MeshTransport>

    func forward(_ rec: ExportAppointmentWorkflowMessageRecord) async throws {
        _ = try await client.pauseVitalWorkflow(.with {
            $0.vital.correlationID = rec.status
            $0.vital.vitalID = rec.message
        })
    }
}

/// Passes records to acme.venues.v1.VenueService.
struct ExportAppointmentWorkflowMessageVenue: ExportAppointmentWorkflowMessageWriter {
    let client: Acme_Venues_V1_VenueService.Client<MeshTransport>

    func forward(_ rec: ExportAppointmentWorkflowMessageRecord) async throws {
        _ = try await client.createVenue(.with {
            $0.venue.code = rec.message
            $0.venue.venueID = rec.status
        })
    }
}

/// Passes records to acme.patients.v1.PatientSyncService.
struct ExportAppointmentWorkflowMessagePatientSync: ExportAppointmentWorkflowMessageWriter {
    let client: Acme_Patients_V1_PatientSyncService.Client<MeshTransport>

    func forward(_ rec: ExportAppointmentWorkflowMessageRecord) async throws {
        _ = try await client.reconcilePatients(.with {
            $0.reason = rec.status
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct ExportAppointmentWorkflowMessageLogOnly: ExportAppointmentWorkflowMessageWriter {
    let logger = Logger(label: "acme.export-appointment-workflow-message")

    func forward(_ rec: ExportAppointmentWorkflowMessageRecord) async throws {
        logger.info("No sink for record", metadata: ["message": .string(rec.message)])
    }
}

/// Reads acme.appointments.v1.AppointmentWorkflowService/ResumeAppointmentWorkflow and hands what it keeps to the sink of its kind.
enum ExportAppointmentWorkflowMessage {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Appointments_V1_AppointmentWorkflowService.Client(wrapping: mesh)
        let reply = try await reader.resumeAppointmentWorkflow(.with { $0.appointmentID = "nightly-export-appointment-workflow-message" })
        let record = ExportAppointmentWorkflowMessageRecord(
            message: Kit.Text.normalize(reply.result.message),
            status: reply.outcome.status
        )
        try await deliver("patient-sync", record, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: ExportAppointmentWorkflowMessageRecord, _ mesh: MeshClient) async throws {
        var sink: any ExportAppointmentWorkflowMessageWriter = ExportAppointmentWorkflowMessageLogOnly()
        switch kind {
        case "vital-workflow":
            sink = ExportAppointmentWorkflowMessageVitalWorkflow(client: Acme_Careplans_V1_VitalWorkflowService.Client(wrapping: mesh))
        case "venue":
            sink = ExportAppointmentWorkflowMessageVenue(client: Acme_Venues_V1_VenueService.Client(wrapping: mesh))
        case "patient-sync":
            sink = ExportAppointmentWorkflowMessagePatientSync(client: Acme_Patients_V1_PatientSyncService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.forward(rec)
    }
}
