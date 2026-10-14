import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ReplayMedicationsID keeps of each FindMedications response.
struct ReplayMedicationsIDRecord {
    var correlationID: String
    var nextPageToken: String
    var status: String
    var message: String
}

/// Where ReplayMedicationsID hands each record.
protocol ReplayMedicationsIDSink {
    func forward(_ rec: ReplayMedicationsIDRecord) async throws
}

/// Hands records to acme.telehealth.v1.VisitNoteLifecycleService.
struct ReplayMedicationsIDVisitNoteLifecycle: ReplayMedicationsIDSink {
    let client: Acme_Telehealth_V1_VisitNoteLifecycleService.Client<MeshTransport>

    func forward(_ rec: ReplayMedicationsIDRecord) async throws {
        _ = try await client.renewVisitNote(.with {
            $0.details.reasonCode = rec.message
        })
    }
}

/// Hands records to acme.patients.v1.PatientValidationService.
struct ReplayMedicationsIDPatientValidation: ReplayMedicationsIDSink {
    let client: Acme_Patients_V1_PatientValidationService.Client<MeshTransport>

    func forward(_ rec: ReplayMedicationsIDRecord) async throws {
        _ = try await client.explainPatientDecision(.with {
            $0.patientID = rec.message
        })
    }
}

/// Passes records to acme.patients.v1.MedicalRecordApprovalService.
struct ReplayMedicationsIDMedicalRecordApproval: ReplayMedicationsIDSink {
    let client: Acme_Patients_V1_MedicalRecordApprovalService.Client<MeshTransport>

    func forward(_ rec: ReplayMedicationsIDRecord) async throws {
        _ = try await client.listPendingMedicalRecords(.with {
            $0.orderBy = rec.message
            $0.filter.ownerID = rec.status
            $0.page.pageToken = rec.correlationID
        })
    }
}

/// Reads acme.prescriptions.v1.MedicationQueryService/FindMedications and hands what it keeps to the sink of its kind.
enum ReplayMedicationsID {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Prescriptions_V1_MedicationQueryService.Client(wrapping: mesh)
        let reply = try await upstream.findMedications(.with { $0.orderBy = "default-replay-medications-id" })
        let entry = ReplayMedicationsIDRecord(
            correlationID: reply.result.correlationID,
            nextPageToken: reply.pageInfo.nextPageToken,
            status: reply.result.status,
            message: reply.result.message
        )
        let sinks: [any ReplayMedicationsIDSink] = [
            ReplayMedicationsIDVisitNoteLifecycle(client: Acme_Telehealth_V1_VisitNoteLifecycleService.Client(wrapping: mesh)),
            ReplayMedicationsIDPatientValidation(client: Acme_Patients_V1_PatientValidationService.Client(wrapping: mesh)),
            ReplayMedicationsIDMedicalRecordApproval(client: Acme_Patients_V1_MedicalRecordApprovalService.Client(wrapping: mesh)),
        ]
        for sink in sinks {
            try await sink.forward(entry)
        }
    }
}
