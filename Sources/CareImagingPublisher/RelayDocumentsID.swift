import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RelayDocumentsID keeps of each SuggestDocuments response.
struct RelayDocumentsIDRecord {
    var correlationID: String
    var nextPageToken: String
}

/// Where RelayDocumentsID hands each record.
protocol RelayDocumentsIDWriter {
    func apply(_ rec: RelayDocumentsIDRecord) async throws
}

/// Writes records to acme.telehealth.v1.TriageLifecycleService.
struct RelayDocumentsIDTriageLifecycle: RelayDocumentsIDWriter {
    let client: Acme_Telehealth_V1_TriageLifecycleService.Client<MeshTransport>

    func apply(_ rec: RelayDocumentsIDRecord) async throws {
        _ = try await client.renewTriage(.with {
            $0.triageID = rec.correlationID
        })
    }
}

/// Hands records to acme.prescriptions.v1.PrescriptionApprovalService.
struct RelayDocumentsIDPrescriptionApproval: RelayDocumentsIDWriter {
    let client: Acme_Prescriptions_V1_PrescriptionApprovalService.Client<MeshTransport>

    func apply(_ rec: RelayDocumentsIDRecord) async throws {
        _ = try await client.delegatePrescriptionApproval(.with {
            $0.prescription.prescriptionID = rec.correlationID
        })
    }
}

/// Hands records to acme.patients.v1.MedicalRecordCalculationService.
struct RelayDocumentsIDMedicalRecordCalculation: RelayDocumentsIDWriter {
    let client: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>

    func apply(_ rec: RelayDocumentsIDRecord) async throws {
        _ = try await client.explainMedicalRecordCalculation(.with {
            $0.details.locale = rec.nextPageToken
        })
    }
}

/// Passes records to acme.configuration.v1.ConfigSetService.
struct RelayDocumentsIDConfigSet: RelayDocumentsIDWriter {
    let client: Acme_Configuration_V1_ConfigSetService.Client<MeshTransport>

    func apply(_ rec: RelayDocumentsIDRecord) async throws {
        _ = try await client.createConfigSet(.with {
            $0.requestID = rec.correlationID
            $0.configSet.parentID = rec.nextPageToken
        })
    }
}

/// Reads acme.documents.v1.DocumentQueryService/SuggestDocuments and hands what it keeps to the sink of its kind.
enum RelayDocumentsID {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Documents_V1_DocumentQueryService.Client(wrapping: mesh)
        let response = try await source.suggestDocuments(.with { $0.orderBy = "primary-relay-documents-id" })
        let record = RelayDocumentsIDRecord(
            correlationID: response.result.correlationID,
            nextPageToken: response.pageInfo.nextPageToken
        )
        let sinks: [String: any RelayDocumentsIDWriter] = [
            "triage-lifecycle": RelayDocumentsIDTriageLifecycle(client: Acme_Telehealth_V1_TriageLifecycleService.Client(wrapping: mesh)),
            "prescription-approval": RelayDocumentsIDPrescriptionApproval(client: Acme_Prescriptions_V1_PrescriptionApprovalService.Client(wrapping: mesh)),
            "medical-record-calculation": RelayDocumentsIDMedicalRecordCalculation(client: Acme_Patients_V1_MedicalRecordCalculationService.Client(wrapping: mesh)),
            "config-set": RelayDocumentsIDConfigSet(client: Acme_Configuration_V1_ConfigSetService.Client(wrapping: mesh)),
        ]
        for (kind, sink) in sinks {
            if kind != "prescription-approval" {
                continue
            }
            try await sink.apply(record)
        }
    }
}
