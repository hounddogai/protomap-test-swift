import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ReplayMedicalRecordNotes keeps of each RejectMedicalRecord response.
struct ReplayMedicalRecordNotesRecord {
    var notes: String
    var status: String
    var message: String
    var number: String
}

/// Where ReplayMedicalRecordNotes hands each record.
protocol ReplayMedicalRecordNotesDestination {
    func write(_ rec: ReplayMedicalRecordNotesRecord) async throws
}

/// Passes records to acme.telehealth.v1.VideoVisitService.
struct ReplayMedicalRecordNotesVideoVisit: ReplayMedicalRecordNotesDestination {
    let client: Acme_Telehealth_V1_VideoVisitService.Client<MeshTransport>

    func write(_ rec: ReplayMedicalRecordNotesRecord) async throws {
        _ = try await client.deleteVideoVisit(.with {
            $0.videoVisitID = rec.number
        })
    }
}

/// Writes records to acme.prescriptions.v1.PrescriptionWorkflowService.
struct ReplayMedicalRecordNotesPrescriptionWorkflow: ReplayMedicalRecordNotesDestination {
    let client: Acme_Prescriptions_V1_PrescriptionWorkflowService.Client<MeshTransport>

    func write(_ rec: ReplayMedicalRecordNotesRecord) async throws {
        _ = try await client.inspectPrescriptionWorkflow(.with {
            $0.prescriptionID = rec.notes
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct ReplayMedicalRecordNotesLogOnly: ReplayMedicalRecordNotesDestination {
    let logger = Logger(label: "acme.replay-medical-record-notes")

    func write(_ rec: ReplayMedicalRecordNotesRecord) async throws {
        logger.info("No sink for record", metadata: ["notes": .string(rec.notes)])
    }
}

/// Reads acme.patients.v1.MedicalRecordApprovalService/RejectMedicalRecord and hands what it keeps to the sink of its kind.
enum ReplayMedicalRecordNotes {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Patients_V1_MedicalRecordApprovalService.Client(wrapping: mesh)
        let response = try await upstream.rejectMedicalRecord(.with { $0.medicalRecordID = "main-replay-medical-record-notes" })
        let row = ReplayMedicalRecordNotesRecord(
            notes: response.medicalRecord.notes,
            status: response.outcome.status,
            message: response.result.message,
            number: response.medicalRecord.number
        )
        try await deliver("video-visit", row, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: ReplayMedicalRecordNotesRecord, _ mesh: MeshClient) async throws {
        var sink: any ReplayMedicalRecordNotesDestination = ReplayMedicalRecordNotesLogOnly()
        switch kind {
        case "video-visit":
            sink = ReplayMedicalRecordNotesVideoVisit(client: Acme_Telehealth_V1_VideoVisitService.Client(wrapping: mesh))
        case "prescription-workflow":
            sink = ReplayMedicalRecordNotesPrescriptionWorkflow(client: Acme_Prescriptions_V1_PrescriptionWorkflowService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.write(rec)
    }
}
