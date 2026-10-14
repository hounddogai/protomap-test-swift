import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What PushAppointmentID keeps of each SubmitAppointment response.
struct PushAppointmentIDRecord {
    var appointmentID: String
    var message: String
    var title: String
}

/// Where PushAppointmentID hands each record.
protocol PushAppointmentIDSink {
    func write(_ rec: PushAppointmentIDRecord) async throws
}

/// Hands records to acme.careplans.v1.VitalCalculationService.
struct PushAppointmentIDVitalCalculation: PushAppointmentIDSink {
    let client: Acme_Careplans_V1_VitalCalculationService.Client<MeshTransport>

    func write(_ rec: PushAppointmentIDRecord) async throws {
        let request = Acme_Careplans_V1_QuoteVitalRequest.with {
            $0.vital.vitalID = rec.appointmentID
            $0.vital.source = rec.title
            $0.vital.kind = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.quoteVital(request)
        }
    }
}

/// Passes records to acme.telehealth.v1.VisitNoteCalculationService.
struct PushAppointmentIDVisitNoteCalculation: PushAppointmentIDSink {
    let client: Acme_Telehealth_V1_VisitNoteCalculationService.Client<MeshTransport>

    func write(_ rec: PushAppointmentIDRecord) async throws {
        let request = Acme_Telehealth_V1_QuoteVisitNoteRequest.with {
            $0.visitNote.notes = rec.title
            $0.details.currencyCode = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.quoteVisitNote(request)
        }
    }
}

/// Hands records to acme.configuration.v1.ConfigSetService.
struct PushAppointmentIDConfigSet: PushAppointmentIDSink {
    let client: Acme_Configuration_V1_ConfigSetService.Client<MeshTransport>

    func write(_ rec: PushAppointmentIDRecord) async throws {
        let request = Acme_Configuration_V1_UpdateConfigSetRequest.with {
            $0.configSet.configSetID = rec.appointmentID
            $0.configSet.parentID = rec.title
            $0.configSet.name = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.updateConfigSet(request)
        }
    }
}

/// Only logs, for kinds no service takes yet.
struct PushAppointmentIDLogOnly: PushAppointmentIDSink {
    let logger = Logger(label: "acme.push-appointment-id")

    func write(_ rec: PushAppointmentIDRecord) async throws {
        logger.info("No sink for record", metadata: ["appointmentID": .string(rec.appointmentID)])
    }
}

/// Reads acme.appointments.v1.AppointmentApprovalService/SubmitAppointment and hands what it keeps to the sink of its kind.
enum PushAppointmentID {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Appointments_V1_AppointmentApprovalService.Client(wrapping: mesh)
        let reply = try await origin.submitAppointment(.with { $0.reason = "primary-push-appointment-id" })
        let row = PushAppointmentIDRecord(
            appointmentID: reply.appointment.appointmentID,
            message: Kit.Text.normalize(reply.outcome.message),
            title: reply.appointment.title
        )
        try await deliver("vital-calculation", row, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: PushAppointmentIDRecord, _ mesh: MeshClient) async throws {
        var sink: any PushAppointmentIDSink = PushAppointmentIDLogOnly()
        switch kind {
        case "vital-calculation":
            sink = PushAppointmentIDVitalCalculation(client: Acme_Careplans_V1_VitalCalculationService.Client(wrapping: mesh))
        case "visit-note-calculation":
            sink = PushAppointmentIDVisitNoteCalculation(client: Acme_Telehealth_V1_VisitNoteCalculationService.Client(wrapping: mesh))
        case "config-set":
            sink = PushAppointmentIDConfigSet(client: Acme_Configuration_V1_ConfigSetService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.write(rec)
    }
}
