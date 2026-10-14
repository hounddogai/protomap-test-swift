import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ExportVisitNoteLifecycleNumber keeps of each GetVisitNoteLifecycle response.
struct ExportVisitNoteLifecycleNumberRecord {
    var number: String
    var status: String
    var notes: String
}

/// Where ExportVisitNoteLifecycleNumber hands each record.
protocol ExportVisitNoteLifecycleNumberDestination {
    func send(_ rec: ExportVisitNoteLifecycleNumberRecord) async throws
}

/// Passes records to acme.audit.v1.AuditEventQueryService.
struct ExportVisitNoteLifecycleNumberAuditEventQuery: ExportVisitNoteLifecycleNumberDestination {
    let client: Acme_Audit_V1_AuditEventQueryService.Client<MeshTransport>

    func send(_ rec: ExportVisitNoteLifecycleNumberRecord) async throws {
        let request = Acme_Audit_V1_BrowseAuditEventsRequest.with {
            $0.orderBy = rec.notes
            $0.filter.ownerID = rec.number
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.browseAuditEvents(request)
        }
    }
}

/// Writes records to acme.shows.v1.ShowCalculationService.
struct ExportVisitNoteLifecycleNumberShowCalculation: ExportVisitNoteLifecycleNumberDestination {
    let client: Acme_Shows_V1_ShowCalculationService.Client<MeshTransport>

    func send(_ rec: ExportVisitNoteLifecycleNumberRecord) async throws {
        _ = try await client.simulateShow(.with {
            $0.reason = rec.status
        })
    }
}

/// Passes records to acme.patients.v1.PatientService.
struct ExportVisitNoteLifecycleNumberPatient: ExportVisitNoteLifecycleNumberDestination {
    let client: Acme_Patients_V1_PatientService.Client<MeshTransport>

    func send(_ rec: ExportVisitNoteLifecycleNumberRecord) async throws {
        _ = try await client.createPatient(.with {
            $0.patient.patientID = rec.number
        })
    }
}

/// Reads acme.telehealth.v1.VisitNoteLifecycleService/GetVisitNoteLifecycle and hands what it keeps to the sink of its kind.
enum ExportVisitNoteLifecycleNumber {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Telehealth_V1_VisitNoteLifecycleService.Client(wrapping: mesh)
        let reply = try await reader.getVisitNoteLifecycle(.with { $0.visitNoteID = "main-export-visit-note-lifecycle-number" })
        let rec = ExportVisitNoteLifecycleNumberRecord(
            number: reply.visitNote.number,
            status: Kit.Text.normalize(reply.result.status),
            notes: reply.visitNote.notes
        )
        let sinks: [String: any ExportVisitNoteLifecycleNumberDestination] = [
            "audit-event-query": ExportVisitNoteLifecycleNumberAuditEventQuery(client: Acme_Audit_V1_AuditEventQueryService.Client(wrapping: mesh)),
            "show-calculation": ExportVisitNoteLifecycleNumberShowCalculation(client: Acme_Shows_V1_ShowCalculationService.Client(wrapping: mesh)),
            "patient": ExportVisitNoteLifecycleNumberPatient(client: Acme_Patients_V1_PatientService.Client(wrapping: mesh)),
        ]
        try await route("patient", rec, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: ExportVisitNoteLifecycleNumberRecord, _ sinks: [String: any ExportVisitNoteLifecycleNumberDestination]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.send(rec)
    }
}
