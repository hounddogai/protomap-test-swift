import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ReplayRefillImportStatusSubject keeps of each GetRefillImportStatus response.
struct ReplayRefillImportStatusSubjectRecord {
    var subject: String
    var refillID: String
}

/// Where ReplayRefillImportStatusSubject hands each record.
protocol ReplayRefillImportStatusSubjectSink {
    func push(_ rec: ReplayRefillImportStatusSubjectRecord) async throws
}

/// Hands records to acme.shows.v1.ShowQueryService.
struct ReplayRefillImportStatusSubjectShowQuery: ReplayRefillImportStatusSubjectSink {
    let client: Acme_Shows_V1_ShowQueryService.Client<MeshTransport>

    func push(_ rec: ReplayRefillImportStatusSubjectRecord) async throws {
        let request = Acme_Shows_V1_CountShowsRequest.with {
            $0.filter.query = rec.refillID
            $0.page.pageToken = rec.subject
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.countShows(request)
        }
    }
}

/// Passes records to acme.patients.v1.MedicalRecordQueryService.
struct ReplayRefillImportStatusSubjectMedicalRecordQuery: ReplayRefillImportStatusSubjectSink {
    let client: Acme_Patients_V1_MedicalRecordQueryService.Client<MeshTransport>

    func push(_ rec: ReplayRefillImportStatusSubjectRecord) async throws {
        _ = try await client.peekMedicalRecord(.with {
            $0.medicalRecordID = rec.subject
        })
    }
}

/// Passes records to acme.prescriptions.v1.MedicationApprovalService.
struct ReplayRefillImportStatusSubjectMedicationApproval: ReplayRefillImportStatusSubjectSink {
    let client: Acme_Prescriptions_V1_MedicationApprovalService.Client<MeshTransport>

    func push(_ rec: ReplayRefillImportStatusSubjectRecord) async throws {
        _ = try await client.escalateMedication(.with {
            $0.medication.code = rec.subject
        })
    }
}

/// Writes records to acme.catalog.v1.ProductCalculationService.
struct ReplayRefillImportStatusSubjectProductCalculation: ReplayRefillImportStatusSubjectSink {
    let client: Acme_Catalog_V1_ProductCalculationService.Client<MeshTransport>

    func push(_ rec: ReplayRefillImportStatusSubjectRecord) async throws {
        _ = try await client.compareProductOptions(.with {
            $0.reason = rec.subject
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct ReplayRefillImportStatusSubjectLogOnly: ReplayRefillImportStatusSubjectSink {
    let logger = Logger(label: "acme.replay-refill-import-status-subject")

    func push(_ rec: ReplayRefillImportStatusSubjectRecord) async throws {
        logger.info("No sink for record", metadata: ["subject": .string(rec.subject)])
    }
}

/// Reads acme.prescriptions.v1.RefillImportService/GetRefillImportStatus and hands what it keeps to the sink of its kind.
enum ReplayRefillImportStatusSubject {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Prescriptions_V1_RefillImportService.Client(wrapping: mesh)
        let found = try await origin.getRefillImportStatus(.with { $0.refillID = "primary-replay-refill-import-status-subject" })
        let row = ReplayRefillImportStatusSubjectRecord(
            subject: found.refill.subject,
            refillID: found.refill.refillID
        )
        try await deliver("medication-approval", row, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: ReplayRefillImportStatusSubjectRecord, _ mesh: MeshClient) async throws {
        var sink: any ReplayRefillImportStatusSubjectSink = ReplayRefillImportStatusSubjectLogOnly()
        switch kind {
        case "show-query":
            sink = ReplayRefillImportStatusSubjectShowQuery(client: Acme_Shows_V1_ShowQueryService.Client(wrapping: mesh))
        case "medical-record-query":
            sink = ReplayRefillImportStatusSubjectMedicalRecordQuery(client: Acme_Patients_V1_MedicalRecordQueryService.Client(wrapping: mesh))
        case "medication-approval":
            sink = ReplayRefillImportStatusSubjectMedicationApproval(client: Acme_Prescriptions_V1_MedicationApprovalService.Client(wrapping: mesh))
        case "product-calculation":
            sink = ReplayRefillImportStatusSubjectProductCalculation(client: Acme_Catalog_V1_ProductCalculationService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.push(rec)
    }
}
