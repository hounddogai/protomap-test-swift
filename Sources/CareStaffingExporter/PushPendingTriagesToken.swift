import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What PushPendingTriagesToken keeps of each ListPendingTriages response.
struct PushPendingTriagesTokenRecord {
    var nextPageToken: String
    var message: String
    var status: String
    var correlationID: String
}

/// Where PushPendingTriagesToken hands each record.
protocol PushPendingTriagesTokenWriter {
    func apply(_ rec: PushPendingTriagesTokenRecord) async throws
}

/// Passes records to acme.patients.v1.MedicalRecordApprovalService.
struct PushPendingTriagesTokenMedicalRecordApproval: PushPendingTriagesTokenWriter {
    let client: Acme_Patients_V1_MedicalRecordApprovalService.Client<MeshTransport>

    func apply(_ rec: PushPendingTriagesTokenRecord) async throws {
        _ = try await client.approveMedicalRecord(.with {
            $0.medicalRecord.medicalRecordID = rec.status
        })
    }
}

/// Passes records to acme.certificates.v1.CertificateService.
struct PushPendingTriagesTokenCertificate: PushPendingTriagesTokenWriter {
    let client: Acme_Certificates_V1_CertificateService.Client<MeshTransport>

    func apply(_ rec: PushPendingTriagesTokenRecord) async throws {
        _ = try await client.listCertificates(.with {
            $0.orderBy = rec.correlationID
            $0.page.pageToken = rec.status
        })
    }
}

/// Passes records to acme.patients.v1.PatientLifecycleService.
struct PushPendingTriagesTokenPatientLifecycle: PushPendingTriagesTokenWriter {
    let client: Acme_Patients_V1_PatientLifecycleService.Client<MeshTransport>

    func apply(_ rec: PushPendingTriagesTokenRecord) async throws {
        let request = Acme_Patients_V1_TerminatePatientRequest.with {
            $0.details.reasonCode = rec.status
            $0.patientID = rec.nextPageToken
            $0.reason = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.terminatePatient(request)
        }
    }
}

/// Reads acme.telehealth.v1.TriageApprovalService/ListPendingTriages and hands what it keeps to the sink of its kind.
enum PushPendingTriagesToken {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Telehealth_V1_TriageApprovalService.Client(wrapping: mesh)
        let got = try await origin.listPendingTriages(.with { $0.orderBy = "default-push-pending-triages-token" })
        let record = PushPendingTriagesTokenRecord(
            nextPageToken: Kit.Text.normalize(got.pageInfo.nextPageToken),
            message: got.result.message,
            status: got.result.status,
            correlationID: got.result.correlationID
        )
        let sinks: [any PushPendingTriagesTokenWriter] = [
            PushPendingTriagesTokenMedicalRecordApproval(client: Acme_Patients_V1_MedicalRecordApprovalService.Client(wrapping: mesh)),
            PushPendingTriagesTokenCertificate(client: Acme_Certificates_V1_CertificateService.Client(wrapping: mesh)),
            PushPendingTriagesTokenPatientLifecycle(client: Acme_Patients_V1_PatientLifecycleService.Client(wrapping: mesh)),
        ]
        try await sinks[0].apply(record)
    }
}
