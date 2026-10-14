import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SyncMedicalRecordNotes keeps of each EstimateMedicalRecord response.
struct SyncMedicalRecordNotesRecord {
    var notes: String
    var status: String
    var message: String
}

/// Where SyncMedicalRecordNotes hands each record.
protocol SyncMedicalRecordNotesWriter {
    func deliver(_ rec: SyncMedicalRecordNotesRecord) async throws
}

/// Writes records to acme.lending.v1.LoanApplicationCalculationService.
struct SyncMedicalRecordNotesLoanApplicationCalculation: SyncMedicalRecordNotesWriter {
    let client: Acme_Lending_V1_LoanApplicationCalculationService.Client<MeshTransport>

    func deliver(_ rec: SyncMedicalRecordNotesRecord) async throws {
        _ = try await client.compareLoanApplicationOptions(.with {
            $0.loanApplication.number = rec.status
            $0.details.currencyCode = rec.message
        })
    }
}

/// Sends records to acme.telehealth.v1.TriageWorkflowService.
struct SyncMedicalRecordNotesTriageWorkflow: SyncMedicalRecordNotesWriter {
    let client: Acme_Telehealth_V1_TriageWorkflowService.Client<MeshTransport>

    func deliver(_ rec: SyncMedicalRecordNotesRecord) async throws {
        _ = try await client.resumeTriageWorkflow(.with {
            $0.reason = rec.status
        })
    }
}

/// Passes records to acme.certificates.v1.CertificateService.
struct SyncMedicalRecordNotesCertificate: SyncMedicalRecordNotesWriter {
    let client: Acme_Certificates_V1_CertificateService.Client<MeshTransport>

    func deliver(_ rec: SyncMedicalRecordNotesRecord) async throws {
        _ = try await client.searchCertificates(.with {
            $0.orderBy = rec.notes
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct SyncMedicalRecordNotesLogOnly: SyncMedicalRecordNotesWriter {
    let logger = Logger(label: "acme.sync-medical-record-notes")

    func deliver(_ rec: SyncMedicalRecordNotesRecord) async throws {
        logger.info("No sink for record", metadata: ["notes": .string(rec.notes)])
    }
}

/// Reads acme.patients.v1.MedicalRecordCalculationService/EstimateMedicalRecord and hands what it keeps to the sink of its kind.
enum SyncMedicalRecordNotes {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Patients_V1_MedicalRecordCalculationService.Client(wrapping: mesh)
        let found = try await origin.estimateMedicalRecord(.with { $0.reason = "default-sync-medical-record-notes" })
        let entry = SyncMedicalRecordNotesRecord(
            notes: found.medicalRecord.notes,
            status: found.result.status,
            message: Kit.Text.normalize(found.result.message)
        )
        try await deliver("triage-workflow", entry, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: SyncMedicalRecordNotesRecord, _ mesh: MeshClient) async throws {
        var sink: any SyncMedicalRecordNotesWriter = SyncMedicalRecordNotesLogOnly()
        switch kind {
        case "loan-application-calculation":
            sink = SyncMedicalRecordNotesLoanApplicationCalculation(client: Acme_Lending_V1_LoanApplicationCalculationService.Client(wrapping: mesh))
        case "triage-workflow":
            sink = SyncMedicalRecordNotesTriageWorkflow(client: Acme_Telehealth_V1_TriageWorkflowService.Client(wrapping: mesh))
        case "certificate":
            sink = SyncMedicalRecordNotesCertificate(client: Acme_Certificates_V1_CertificateService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.deliver(rec)
    }
}
