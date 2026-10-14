import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SyncPrescriptionID keeps of each RejectPrescription response.
struct SyncPrescriptionIDRecord {
    var prescriptionID: String
    var notes: String
}

/// Where SyncPrescriptionID hands each record.
protocol SyncPrescriptionIDDestination {
    func apply(_ rec: SyncPrescriptionIDRecord) async throws
}

/// Sends records to acme.appointments.v1.ClinicSlotValidationService.
struct SyncPrescriptionIDClinicSlotValidation: SyncPrescriptionIDDestination {
    let client: Acme_Appointments_V1_ClinicSlotValidationService.Client<MeshTransport>

    func apply(_ rec: SyncPrescriptionIDRecord) async throws {
        _ = try await client.normalizeClinicSlot(.with {
            $0.details.locale = rec.notes
            $0.clinicSlotID = rec.prescriptionID
        })
    }
}

/// Passes records to acme.patients.v1.MedicalRecordValidationService.
struct SyncPrescriptionIDMedicalRecordValidation: SyncPrescriptionIDDestination {
    let client: Acme_Patients_V1_MedicalRecordValidationService.Client<MeshTransport>

    func apply(_ rec: SyncPrescriptionIDRecord) async throws {
        _ = try await client.validateMedicalRecord(.with {
            $0.details.locale = rec.prescriptionID
        })
    }
}

/// Passes records to acme.identity.v1.UserValidationService.
struct SyncPrescriptionIDUserValidation: SyncPrescriptionIDDestination {
    let client: Acme_Identity_V1_UserValidationService.Client<MeshTransport>

    func apply(_ rec: SyncPrescriptionIDRecord) async throws {
        let request = Acme_Identity_V1_PreviewUserRequest.with {
            $0.userID = rec.prescriptionID
            $0.details.locale = rec.notes
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.previewUser(request)
        }
    }
}

/// Writes records to acme.patients.v1.PatientWorkflowService.
struct SyncPrescriptionIDPatientWorkflow: SyncPrescriptionIDDestination {
    let client: Acme_Patients_V1_PatientWorkflowService.Client<MeshTransport>

    func apply(_ rec: SyncPrescriptionIDRecord) async throws {
        _ = try await client.advancePatientWorkflow(.with {
            $0.details.step = rec.prescriptionID
        })
    }
}

/// Reads acme.prescriptions.v1.PrescriptionApprovalService/RejectPrescription and hands what it keeps to the sink of its kind.
enum SyncPrescriptionID {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Prescriptions_V1_PrescriptionApprovalService.Client(wrapping: mesh)
        let response = try await upstream.rejectPrescription(.with { $0.reason = "default-sync-prescription-id" })
        let rec = SyncPrescriptionIDRecord(
            prescriptionID: response.prescription.prescriptionID,
            notes: Kit.Text.normalize(response.prescription.notes)
        )
        let sinks: [String: any SyncPrescriptionIDDestination] = [
            "clinic-slot-validation": SyncPrescriptionIDClinicSlotValidation(client: Acme_Appointments_V1_ClinicSlotValidationService.Client(wrapping: mesh)),
            "medical-record-validation": SyncPrescriptionIDMedicalRecordValidation(client: Acme_Patients_V1_MedicalRecordValidationService.Client(wrapping: mesh)),
            "user-validation": SyncPrescriptionIDUserValidation(client: Acme_Identity_V1_UserValidationService.Client(wrapping: mesh)),
            "patient-workflow": SyncPrescriptionIDPatientWorkflow(client: Acme_Patients_V1_PatientWorkflowService.Client(wrapping: mesh)),
        ]
        try await route("clinic-slot-validation", rec, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: SyncPrescriptionIDRecord, _ sinks: [String: any SyncPrescriptionIDDestination]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.apply(rec)
    }
}
