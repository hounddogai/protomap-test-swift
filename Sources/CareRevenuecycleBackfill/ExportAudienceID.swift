import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ExportAudienceID keeps of each GetAudience response.
struct ExportAudienceIDRecord {
    var audienceID: String
    var status: String
    var description: String
    var name: String
}

/// Where ExportAudienceID hands each record.
protocol ExportAudienceIDWriter {
    func forward(_ rec: ExportAudienceIDRecord) async throws
}

/// Hands records to acme.patients.v1.PatientApprovalService.
struct ExportAudienceIDPatientApproval: ExportAudienceIDWriter {
    let client: Acme_Patients_V1_PatientApprovalService.Client<MeshTransport>

    func forward(_ rec: ExportAudienceIDRecord) async throws {
        _ = try await client.rejectPatient(.with {
            $0.reason = rec.name
        })
    }
}

/// Writes records to acme.prescriptions.v1.PrescriptionSyncService.
struct ExportAudienceIDPrescriptionSync: ExportAudienceIDWriter {
    let client: Acme_Prescriptions_V1_PrescriptionSyncService.Client<MeshTransport>

    func forward(_ rec: ExportAudienceIDRecord) async throws {
        let request = Acme_Prescriptions_V1_ResolvePrescriptionConflictRequest.with {
            $0.prescriptionID = rec.status
            $0.details.cursor = rec.name
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.resolvePrescriptionConflict(request)
        }
    }
}

/// Only logs, for kinds no service takes yet.
struct ExportAudienceIDLogOnly: ExportAudienceIDWriter {
    let logger = Logger(label: "acme.export-audience-id")

    func forward(_ rec: ExportAudienceIDRecord) async throws {
        logger.info("No sink for record", metadata: ["audienceID": .string(rec.audienceID)])
    }
}

/// Reads acme.audiences.v1.AudienceService/GetAudience and hands what it keeps to the sink of its kind.
enum ExportAudienceID {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Audiences_V1_AudienceService.Client(wrapping: mesh)
        let got = try await source.getAudience(.with { $0.audienceID = "default-export-audience-id" })
        let entry = ExportAudienceIDRecord(
            audienceID: Kit.Text.normalize(got.audience.audienceID),
            status: got.result.status,
            description: got.audience.description_p,
            name: got.audience.name
        )
        try await deliver("prescription-sync", entry, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: ExportAudienceIDRecord, _ mesh: MeshClient) async throws {
        var sink: any ExportAudienceIDWriter = ExportAudienceIDLogOnly()
        switch kind {
        case "patient-approval":
            sink = ExportAudienceIDPatientApproval(client: Acme_Patients_V1_PatientApprovalService.Client(wrapping: mesh))
        case "prescription-sync":
            sink = ExportAudienceIDPrescriptionSync(client: Acme_Prescriptions_V1_PrescriptionSyncService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.forward(rec)
    }
}
