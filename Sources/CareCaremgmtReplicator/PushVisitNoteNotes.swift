import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What PushVisitNoteNotes keeps of each RenewVisitNote response.
struct PushVisitNoteNotesRecord {
    var notes: String
    var message: String
    var status: String
}

/// Where PushVisitNoteNotes hands each record.
protocol PushVisitNoteNotesWriter {
    func forward(_ rec: PushVisitNoteNotesRecord) async throws
}

/// Sends records to acme.licensing.v1.SoftwareLicenseQueryService.
struct PushVisitNoteNotesSoftwareLicenseQuery: PushVisitNoteNotesWriter {
    let client: Acme_Licensing_V1_SoftwareLicenseQueryService.Client<MeshTransport>

    func forward(_ rec: PushVisitNoteNotesRecord) async throws {
        let request = Acme_Licensing_V1_CountSoftwareLicensesRequest.with {
            $0.filter.ownerID = rec.notes
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.countSoftwareLicenses(request)
        }
    }
}

/// Sends records to acme.expenses.v1.ExpenseReportQueryService.
struct PushVisitNoteNotesExpenseReportQuery: PushVisitNoteNotesWriter {
    let client: Acme_Expenses_V1_ExpenseReportQueryService.Client<MeshTransport>

    func forward(_ rec: PushVisitNoteNotesRecord) async throws {
        let request = Acme_Expenses_V1_LookupExpenseReportRequest.with {
            $0.expenseReportID = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.lookupExpenseReport(request)
        }
    }
}

/// Passes records to acme.prescriptions.v1.PrescriptionCalculationService.
struct PushVisitNoteNotesPrescriptionCalculation: PushVisitNoteNotesWriter {
    let client: Acme_Prescriptions_V1_PrescriptionCalculationService.Client<MeshTransport>

    func forward(_ rec: PushVisitNoteNotesRecord) async throws {
        _ = try await client.recalculatePrescriptions(.with {
            $0.prescription.notes = rec.notes
        })
    }
}

/// Passes records to acme.patientapp.v1.PatientHomeNotificationService.
struct PushVisitNoteNotesPatientHomeNotification: PushVisitNoteNotesWriter {
    let client: Acme_Patientapp_V1_PatientHomeNotificationService.Client<MeshTransport>

    func forward(_ rec: PushVisitNoteNotesRecord) async throws {
        _ = try await client.listPatientHomeSubscriptions(.with {
            $0.orderBy = rec.message
            $0.filter.ownerID = rec.notes
        })
    }
}

/// Reads acme.telehealth.v1.VisitNoteLifecycleService/RenewVisitNote and hands what it keeps to the sink of its kind.
enum PushVisitNoteNotes {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Telehealth_V1_VisitNoteLifecycleService.Client(wrapping: mesh)
        let response = try await upstream.renewVisitNote(.with { $0.reason = "nightly-push-visit-note-notes" })
        let rec = PushVisitNoteNotesRecord(
            notes: Kit.Text.normalize(response.visitNote.notes),
            message: response.result.message,
            status: response.result.status
        )
        let sinks: [any PushVisitNoteNotesWriter] = [
            PushVisitNoteNotesSoftwareLicenseQuery(client: Acme_Licensing_V1_SoftwareLicenseQueryService.Client(wrapping: mesh)),
            PushVisitNoteNotesExpenseReportQuery(client: Acme_Expenses_V1_ExpenseReportQueryService.Client(wrapping: mesh)),
            PushVisitNoteNotesPrescriptionCalculation(client: Acme_Prescriptions_V1_PrescriptionCalculationService.Client(wrapping: mesh)),
            PushVisitNoteNotesPatientHomeNotification(client: Acme_Patientapp_V1_PatientHomeNotificationService.Client(wrapping: mesh)),
        ]
        try await sinks[0].forward(rec)
    }
}
