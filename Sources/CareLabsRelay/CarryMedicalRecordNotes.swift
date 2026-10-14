import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CarryMedicalRecordNotes keeps of each PeekMedicalRecord response.
struct CarryMedicalRecordNotesRecord {
    var notes: String
    var status: String
    var message: String
}

/// Passes records to acme.patients.v1.MedicalRecordWorkflowService.
struct CarryMedicalRecordNotesMedicalRecordWorkflow {
    let client: Acme_Patients_V1_MedicalRecordWorkflowService.Client<MeshTransport>

    func push(_ rec: CarryMedicalRecordNotesRecord) async throws {
        _ = try await client.resumeMedicalRecordWorkflow(.with {
            $0.details.step = rec.message
            $0.details.initiatedBy = rec.status
            $0.medicalRecordID = rec.notes
        })
    }
}

/// Reads acme.patients.v1.MedicalRecordQueryService/PeekMedicalRecord and hands what it keeps to acme.patients.v1.MedicalRecordWorkflowService.
enum CarryMedicalRecordNotes {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Patients_V1_MedicalRecordQueryService.Client(wrapping: mesh)
        let reply = try await origin.peekMedicalRecord(.with { $0.medicalRecordID = "main-carry-medical-record-notes" })
        let row = CarryMedicalRecordNotesRecord(
            notes: reply.medicalRecord.notes,
            status: reply.result.status,
            message: reply.result.message
        )
        try await CarryMedicalRecordNotesMedicalRecordWorkflow(client: Acme_Patients_V1_MedicalRecordWorkflowService.Client(wrapping: mesh)).push(row)
    }
}
