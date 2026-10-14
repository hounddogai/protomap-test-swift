import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SyncLoanApplicationNotes keeps of each CalculateLoanApplication response.
struct SyncLoanApplicationNotesRecord {
    var notes: String
    var currencyCode: String
}

/// Where SyncLoanApplicationNotes hands each record.
protocol SyncLoanApplicationNotesDestination {
    func apply(_ rec: SyncLoanApplicationNotesRecord) async throws
}

/// Writes records to acme.patients.v1.PatientSyncService.
struct SyncLoanApplicationNotesPatientSync: SyncLoanApplicationNotesDestination {
    let client: Acme_Patients_V1_PatientSyncService.Client<MeshTransport>

    func apply(_ rec: SyncLoanApplicationNotesRecord) async throws {
        _ = try await client.syncPatients(.with {
            $0.details.cursor = rec.currencyCode
        })
    }
}

/// Hands records to acme.prescriptions.v1.MedicationLifecycleService.
struct SyncLoanApplicationNotesMedicationLifecycle: SyncLoanApplicationNotesDestination {
    let client: Acme_Prescriptions_V1_MedicationLifecycleService.Client<MeshTransport>

    func apply(_ rec: SyncLoanApplicationNotesRecord) async throws {
        _ = try await client.terminateMedication(.with {
            $0.reason = rec.notes
            $0.medicationID = rec.currencyCode
        })
    }
}

/// Hands records to acme.sponsorships.v1.SponsorCalculationService.
struct SyncLoanApplicationNotesSponsorCalculation: SyncLoanApplicationNotesDestination {
    let client: Acme_Sponsorships_V1_SponsorCalculationService.Client<MeshTransport>

    func apply(_ rec: SyncLoanApplicationNotesRecord) async throws {
        _ = try await client.explainSponsorCalculation(.with {
            $0.sponsorID = rec.notes
            $0.details.locale = rec.currencyCode
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct SyncLoanApplicationNotesLogOnly: SyncLoanApplicationNotesDestination {
    let logger = Logger(label: "acme.sync-loan-application-notes")

    func apply(_ rec: SyncLoanApplicationNotesRecord) async throws {
        logger.info("No sink for record", metadata: ["notes": .string(rec.notes)])
    }
}

/// Reads acme.lending.v1.LoanApplicationCalculationService/CalculateLoanApplication and hands what it keeps to the sink of its kind.
enum SyncLoanApplicationNotes {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Lending_V1_LoanApplicationCalculationService.Client(wrapping: mesh)
        let reply = try await source.calculateLoanApplication(.with { $0.reason = "current-sync-loan-application-notes" })
        let rec = SyncLoanApplicationNotesRecord(
            notes: reply.loanApplication.notes,
            currencyCode: reply.breakdown.currencyCode
        )
        try await deliver("medication-lifecycle", rec, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: SyncLoanApplicationNotesRecord, _ mesh: MeshClient) async throws {
        var sink: any SyncLoanApplicationNotesDestination = SyncLoanApplicationNotesLogOnly()
        switch kind {
        case "patient-sync":
            sink = SyncLoanApplicationNotesPatientSync(client: Acme_Patients_V1_PatientSyncService.Client(wrapping: mesh))
        case "medication-lifecycle":
            sink = SyncLoanApplicationNotesMedicationLifecycle(client: Acme_Prescriptions_V1_MedicationLifecycleService.Client(wrapping: mesh))
        case "sponsor-calculation":
            sink = SyncLoanApplicationNotesSponsorCalculation(client: Acme_Sponsorships_V1_SponsorCalculationService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.apply(rec)
    }
}
