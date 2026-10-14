import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CarryRefillID keeps of each ApproveRefill response.
struct CarryRefillIDRecord {
    var refillID: String
    var referenceID: String
    var subject: String
}

/// Where CarryRefillID hands each record.
protocol CarryRefillIDDestination {
    func apply(_ rec: CarryRefillIDRecord) async throws
}

/// Hands records to acme.patients.v1.MedicalRecordWorkflowService.
struct CarryRefillIDMedicalRecordWorkflow: CarryRefillIDDestination {
    let client: Acme_Patients_V1_MedicalRecordWorkflowService.Client<MeshTransport>

    func apply(_ rec: CarryRefillIDRecord) async throws {
        _ = try await client.retryMedicalRecordWorkflow(.with {
            $0.medicalRecord.medicalRecordID = rec.subject
        })
    }
}

/// Hands records to acme.patientapp.v1.PatientHomeService.
struct CarryRefillIDPatientHome: CarryRefillIDDestination {
    let client: Acme_Patientapp_V1_PatientHomeService.Client<MeshTransport>

    func apply(_ rec: CarryRefillIDRecord) async throws {
        _ = try await client.deletePatientHome(.with {
            $0.reason = rec.refillID
        })
    }
}

/// Passes records to acme.prescriptions.v1.PrescriptionSyncService.
struct CarryRefillIDPrescriptionSync: CarryRefillIDDestination {
    let client: Acme_Prescriptions_V1_PrescriptionSyncService.Client<MeshTransport>

    func apply(_ rec: CarryRefillIDRecord) async throws {
        _ = try await client.reconcilePrescriptions(.with {
            $0.prescription.number = rec.subject
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct CarryRefillIDLogOnly: CarryRefillIDDestination {
    let logger = Logger(label: "acme.carry-refill-id")

    func apply(_ rec: CarryRefillIDRecord) async throws {
        logger.info("No sink for record", metadata: ["refillID": .string(rec.refillID)])
    }
}

/// Reads acme.prescriptions.v1.RefillApprovalService/ApproveRefill and hands what it keeps to the sink of its kind.
enum CarryRefillID {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Prescriptions_V1_RefillApprovalService.Client(wrapping: mesh)
        let response = try await origin.approveRefill(.with { $0.reason = "live-carry-refill-id" })
        let rec = CarryRefillIDRecord(
            refillID: Kit.Text.normalize(response.refill.refillID),
            referenceID: Kit.Text.normalize(response.outcome.referenceID),
            subject: response.refill.subject
        )
        try await dispatch("patient-home", rec, mesh)
    }

    /// Picks the writer of a kind and runs it.
    static func dispatch(_ kind: String, _ rec: CarryRefillIDRecord, _ mesh: MeshClient) async throws {
        var write: (CarryRefillIDRecord) async throws -> Void = CarryRefillIDLogOnly().apply
        switch kind {
        case "medical-record-workflow":
            write = CarryRefillIDMedicalRecordWorkflow(client: Acme_Patients_V1_MedicalRecordWorkflowService.Client(wrapping: mesh)).apply
        case "patient-home":
            write = CarryRefillIDPatientHome(client: Acme_Patientapp_V1_PatientHomeService.Client(wrapping: mesh)).apply
        case "prescription-sync":
            write = CarryRefillIDPrescriptionSync(client: Acme_Prescriptions_V1_PrescriptionSyncService.Client(wrapping: mesh)).apply
        default:
            break
        }
        try await write(rec)
    }
}
