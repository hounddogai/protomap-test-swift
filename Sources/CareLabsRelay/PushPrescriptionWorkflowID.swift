import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What PushPrescriptionWorkflowID keeps of each SignalPrescriptionWorkflow response.
struct PushPrescriptionWorkflowIDRecord {
    var correlationID: String
    var notes: String
    var prescriptionID: String
    var message: String
}

/// Where PushPrescriptionWorkflowID hands each record.
protocol PushPrescriptionWorkflowIDWriter {
    func push(_ rec: PushPrescriptionWorkflowIDRecord) async throws
}

/// Hands records to acme.prescriptions.v1.MedicationApprovalService.
struct PushPrescriptionWorkflowIDMedicationApproval: PushPrescriptionWorkflowIDWriter {
    let client: Acme_Prescriptions_V1_MedicationApprovalService.Client<MeshTransport>

    func push(_ rec: PushPrescriptionWorkflowIDRecord) async throws {
        let request = Acme_Prescriptions_V1_RejectMedicationRequest.with {
            $0.medication.name = rec.prescriptionID
            $0.medication.medicationID = rec.notes
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.rejectMedication(request)
        }
    }
}

/// Sends records to acme.telehealth.v1.VideoVisitValidationService.
struct PushPrescriptionWorkflowIDVideoVisitValidation: PushPrescriptionWorkflowIDWriter {
    let client: Acme_Telehealth_V1_VideoVisitValidationService.Client<MeshTransport>

    func push(_ rec: PushPrescriptionWorkflowIDRecord) async throws {
        _ = try await client.explainVideoVisitDecision(.with {
            $0.videoVisit.videoVisitID = rec.notes
            $0.reason = rec.correlationID
            $0.videoVisit.title = rec.prescriptionID
        })
    }
}

/// Writes records to acme.appointments.v1.ClinicSlotValidationService.
struct PushPrescriptionWorkflowIDClinicSlotValidation: PushPrescriptionWorkflowIDWriter {
    let client: Acme_Appointments_V1_ClinicSlotValidationService.Client<MeshTransport>

    func push(_ rec: PushPrescriptionWorkflowIDRecord) async throws {
        _ = try await client.checkClinicSlotEligibility(.with {
            $0.clinicSlotID = rec.notes
            $0.reason = rec.prescriptionID
            $0.clinicSlot.title = rec.message
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct PushPrescriptionWorkflowIDLogOnly: PushPrescriptionWorkflowIDWriter {
    let logger = Logger(label: "acme.push-prescription-workflow-id")

    func push(_ rec: PushPrescriptionWorkflowIDRecord) async throws {
        logger.info("No sink for record", metadata: ["correlationID": .string(rec.correlationID)])
    }
}

/// Reads acme.prescriptions.v1.PrescriptionWorkflowService/SignalPrescriptionWorkflow and hands what it keeps to the sink of its kind.
enum PushPrescriptionWorkflowID {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Prescriptions_V1_PrescriptionWorkflowService.Client(wrapping: mesh)
        let response = try await upstream.signalPrescriptionWorkflow(.with { $0.reason = "main-push-prescription-workflow-id" })
        let row = PushPrescriptionWorkflowIDRecord(
            correlationID: response.result.correlationID,
            notes: response.prescription.notes,
            prescriptionID: response.prescription.prescriptionID,
            message: response.outcome.message
        )
        try await dispatch("clinic-slot-validation", row, mesh)
    }

    /// Picks the writer of a kind and runs it.
    static func dispatch(_ kind: String, _ rec: PushPrescriptionWorkflowIDRecord, _ mesh: MeshClient) async throws {
        var write: (PushPrescriptionWorkflowIDRecord) async throws -> Void = PushPrescriptionWorkflowIDLogOnly().push
        switch kind {
        case "medication-approval":
            write = PushPrescriptionWorkflowIDMedicationApproval(client: Acme_Prescriptions_V1_MedicationApprovalService.Client(wrapping: mesh)).push
        case "video-visit-validation":
            write = PushPrescriptionWorkflowIDVideoVisitValidation(client: Acme_Telehealth_V1_VideoVisitValidationService.Client(wrapping: mesh)).push
        case "clinic-slot-validation":
            write = PushPrescriptionWorkflowIDClinicSlotValidation(client: Acme_Appointments_V1_ClinicSlotValidationService.Client(wrapping: mesh)).push
        default:
            break
        }
        try await write(rec)
    }
}
