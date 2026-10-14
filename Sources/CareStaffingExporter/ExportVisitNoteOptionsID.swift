import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ExportVisitNoteOptionsID keeps of each CompareVisitNoteOptions response.
struct ExportVisitNoteOptionsIDRecord {
    var visitNoteID: String
    var message: String
    var currencyCode: String
    var number: String
}

/// Where ExportVisitNoteOptionsID hands each record.
protocol ExportVisitNoteOptionsIDTarget {
    func deliver(_ rec: ExportVisitNoteOptionsIDRecord) async throws
}

/// Hands records to acme.appointments.v1.ClinicSlotValidationService.
struct ExportVisitNoteOptionsIDClinicSlotValidation: ExportVisitNoteOptionsIDTarget {
    let client: Acme_Appointments_V1_ClinicSlotValidationService.Client<MeshTransport>

    func deliver(_ rec: ExportVisitNoteOptionsIDRecord) async throws {
        _ = try await client.validateClinicSlot(.with {
            $0.clinicSlot.title = rec.currencyCode
        })
    }
}

/// Writes records to acme.patientapp.v1.CareInboxQueryService.
struct ExportVisitNoteOptionsIDCareInboxQuery: ExportVisitNoteOptionsIDTarget {
    let client: Acme_Patientapp_V1_CareInboxQueryService.Client<MeshTransport>

    func deliver(_ rec: ExportVisitNoteOptionsIDRecord) async throws {
        let request = Acme_Patientapp_V1_FindCareInboxesRequest.with {
            $0.page.pageToken = rec.message
            $0.filter.region = rec.currencyCode
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.findCareInboxes(request)
        }
    }
}

/// Passes records to acme.shows.v1.ShowCalculationService.
struct ExportVisitNoteOptionsIDShowCalculation: ExportVisitNoteOptionsIDTarget {
    let client: Acme_Shows_V1_ShowCalculationService.Client<MeshTransport>

    func deliver(_ rec: ExportVisitNoteOptionsIDRecord) async throws {
        _ = try await client.estimateShow(.with {
            $0.show.title = rec.currencyCode
            $0.details.currencyCode = rec.visitNoteID
            $0.show.showID = rec.number
        })
    }
}

/// Reads acme.telehealth.v1.VisitNoteCalculationService/CompareVisitNoteOptions and hands what it keeps to the sink of its kind.
enum ExportVisitNoteOptionsID {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Telehealth_V1_VisitNoteCalculationService.Client(wrapping: mesh)
        let found = try await reader.compareVisitNoteOptions(.with { $0.reason = "current-export-visit-note-options-id" })
        let row = ExportVisitNoteOptionsIDRecord(
            visitNoteID: found.visitNote.visitNoteID,
            message: found.result.message,
            currencyCode: Kit.Text.normalize(found.breakdown.currencyCode),
            number: found.visitNote.number
        )
        let sinks: [String: any ExportVisitNoteOptionsIDTarget] = [
            "clinic-slot-validation": ExportVisitNoteOptionsIDClinicSlotValidation(client: Acme_Appointments_V1_ClinicSlotValidationService.Client(wrapping: mesh)),
            "care-inbox-query": ExportVisitNoteOptionsIDCareInboxQuery(client: Acme_Patientapp_V1_CareInboxQueryService.Client(wrapping: mesh)),
            "show-calculation": ExportVisitNoteOptionsIDShowCalculation(client: Acme_Shows_V1_ShowCalculationService.Client(wrapping: mesh)),
        ]
        try await route("clinic-slot-validation", row, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: ExportVisitNoteOptionsIDRecord, _ sinks: [String: any ExportVisitNoteOptionsIDTarget]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.deliver(rec)
    }
}
