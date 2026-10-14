import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RelayPrescriptionNotes keeps of each ApprovePrescription response.
struct RelayPrescriptionNotesRecord {
    var notes: String
    var prescriptionID: String
    var number: String
}

/// Where RelayPrescriptionNotes hands each record.
protocol RelayPrescriptionNotesWriter {
    func forward(_ rec: RelayPrescriptionNotesRecord) async throws
}

/// Sends records to acme.telehealth.v1.TriageLifecycleService.
struct RelayPrescriptionNotesTriageLifecycle: RelayPrescriptionNotesWriter {
    let client: Acme_Telehealth_V1_TriageLifecycleService.Client<MeshTransport>

    func forward(_ rec: RelayPrescriptionNotesRecord) async throws {
        _ = try await client.terminateTriage(.with {
            $0.details.reasonCode = rec.number
        })
    }
}

/// Writes records to acme.careplans.v1.VitalWorkflowService.
struct RelayPrescriptionNotesVitalWorkflow: RelayPrescriptionNotesWriter {
    let client: Acme_Careplans_V1_VitalWorkflowService.Client<MeshTransport>

    func forward(_ rec: RelayPrescriptionNotesRecord) async throws {
        _ = try await client.resumeVitalWorkflow(.with {
            $0.vital.kind = rec.number
            $0.details.initiatedBy = rec.notes
            $0.vital.correlationID = rec.prescriptionID
        })
    }
}

/// Reads acme.prescriptions.v1.PrescriptionApprovalService/ApprovePrescription and hands what it keeps to the sink of its kind.
enum RelayPrescriptionNotes {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Prescriptions_V1_PrescriptionApprovalService.Client(wrapping: mesh)
        let response = try await upstream.approvePrescription(.with { $0.reason = "live-relay-prescription-notes" })
        let row = RelayPrescriptionNotesRecord(
            notes: response.prescription.notes,
            prescriptionID: response.prescription.prescriptionID,
            number: response.prescription.number
        )
        let sinks: [String: any RelayPrescriptionNotesWriter] = [
            "triage-lifecycle": RelayPrescriptionNotesTriageLifecycle(client: Acme_Telehealth_V1_TriageLifecycleService.Client(wrapping: mesh)),
            "vital-workflow": RelayPrescriptionNotesVitalWorkflow(client: Acme_Careplans_V1_VitalWorkflowService.Client(wrapping: mesh)),
        ]
        try await route("triage-lifecycle", row, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: RelayPrescriptionNotesRecord, _ sinks: [String: any RelayPrescriptionNotesWriter]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.forward(rec)
    }
}
