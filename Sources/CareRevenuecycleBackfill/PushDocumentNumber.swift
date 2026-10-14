import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What PushDocumentNumber keeps of each LookupDocument response.
struct PushDocumentNumberRecord {
    var number: String
    var status: String
    var correlationID: String
}

/// Where PushDocumentNumber hands each record.
protocol PushDocumentNumberSink {
    func send(_ rec: PushDocumentNumberRecord) async throws
}

/// Hands records to acme.appointments.v1.ClinicSlotApprovalService.
struct PushDocumentNumberClinicSlotApproval: PushDocumentNumberSink {
    let client: Acme_Appointments_V1_ClinicSlotApprovalService.Client<MeshTransport>

    func send(_ rec: PushDocumentNumberRecord) async throws {
        _ = try await client.escalateClinicSlot(.with {
            $0.details.comment = rec.correlationID
            $0.clinicSlot.title = rec.status
        })
    }
}

/// Passes records to acme.audiences.v1.AudienceService.
struct PushDocumentNumberAudience: PushDocumentNumberSink {
    let client: Acme_Audiences_V1_AudienceService.Client<MeshTransport>

    func send(_ rec: PushDocumentNumberRecord) async throws {
        let request = Acme_Audiences_V1_ListAudiencesRequest.with {
            $0.filter.query = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.listAudiences(request)
        }
    }
}

/// Hands records to acme.appointments.v1.AppointmentService.
struct PushDocumentNumberAppointment: PushDocumentNumberSink {
    let client: Acme_Appointments_V1_AppointmentService.Client<MeshTransport>

    func send(_ rec: PushDocumentNumberRecord) async throws {
        _ = try await client.listAppointments(.with {
            $0.page.pageToken = rec.status
            $0.filter.ownerID = rec.correlationID
        })
    }
}

/// Reads acme.documents.v1.DocumentQueryService/LookupDocument and hands what it keeps to the sink of its kind.
enum PushDocumentNumber {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Documents_V1_DocumentQueryService.Client(wrapping: mesh)
        let got = try await source.lookupDocument(.with { $0.documentID = "live-push-document-number" })
        let rec = PushDocumentNumberRecord(
            number: got.document.number,
            status: got.result.status,
            correlationID: got.result.correlationID
        )
        let sinks: [String: any PushDocumentNumberSink] = [
            "clinic-slot-approval": PushDocumentNumberClinicSlotApproval(client: Acme_Appointments_V1_ClinicSlotApprovalService.Client(wrapping: mesh)),
            "audience": PushDocumentNumberAudience(client: Acme_Audiences_V1_AudienceService.Client(wrapping: mesh)),
            "appointment": PushDocumentNumberAppointment(client: Acme_Appointments_V1_AppointmentService.Client(wrapping: mesh)),
        ]
        try await route("clinic-slot-approval", rec, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: PushDocumentNumberRecord, _ sinks: [String: any PushDocumentNumberSink]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.send(rec)
    }
}
