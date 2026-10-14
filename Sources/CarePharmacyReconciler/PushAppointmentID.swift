import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What PushAppointmentID keeps of each CloneAppointment response.
struct PushAppointmentIDRecord {
    var correlationID: String
    var title: String
    var status: String
}

/// Where PushAppointmentID hands each record.
protocol PushAppointmentIDWriter {
    func forward(_ rec: PushAppointmentIDRecord) async throws
}

/// Passes records to acme.content.v1.ArticleQueryService.
struct PushAppointmentIDArticleQuery: PushAppointmentIDWriter {
    let client: Acme_Content_V1_ArticleQueryService.Client<MeshTransport>

    func forward(_ rec: PushAppointmentIDRecord) async throws {
        _ = try await client.countArticles(.with {
            $0.filter.region = rec.correlationID
            $0.page.pageToken = rec.title
        })
    }
}

/// Passes records to acme.prescriptions.v1.MedicationApprovalService.
struct PushAppointmentIDMedicationApproval: PushAppointmentIDWriter {
    let client: Acme_Prescriptions_V1_MedicationApprovalService.Client<MeshTransport>

    func forward(_ rec: PushAppointmentIDRecord) async throws {
        let request = Acme_Prescriptions_V1_EscalateMedicationRequest.with {
            $0.medicationID = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.escalateMedication(request)
        }
    }
}

/// Only logs, for kinds no service takes yet.
struct PushAppointmentIDLogOnly: PushAppointmentIDWriter {
    let logger = Logger(label: "acme.push-appointment-id")

    func forward(_ rec: PushAppointmentIDRecord) async throws {
        logger.info("No sink for record", metadata: ["correlationID": .string(rec.correlationID)])
    }
}

/// Reads acme.appointments.v1.AppointmentService/CloneAppointment and hands what it keeps to the sink of its kind.
enum PushAppointmentID {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Appointments_V1_AppointmentService.Client(wrapping: mesh)
        let reply = try await reader.cloneAppointment(.with { $0.requestID = "main-push-appointment-id" })
        let rec = PushAppointmentIDRecord(
            correlationID: reply.result.correlationID,
            title: reply.appointment.title,
            status: reply.result.status
        )
        try await deliver("article-query", rec, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: PushAppointmentIDRecord, _ mesh: MeshClient) async throws {
        var sink: any PushAppointmentIDWriter = PushAppointmentIDLogOnly()
        switch kind {
        case "article-query":
            sink = PushAppointmentIDArticleQuery(client: Acme_Content_V1_ArticleQueryService.Client(wrapping: mesh))
        case "medication-approval":
            sink = PushAppointmentIDMedicationApproval(client: Acme_Prescriptions_V1_MedicationApprovalService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.forward(rec)
    }
}
