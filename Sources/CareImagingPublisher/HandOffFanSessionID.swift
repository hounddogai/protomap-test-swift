import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What HandOffFanSessionID keeps of each PeekFanSession response.
struct HandOffFanSessionIDRecord {
    var correlationID: String
    var subject: String
}

/// Where HandOffFanSessionID hands each record.
protocol HandOffFanSessionIDTarget {
    func send(_ rec: HandOffFanSessionIDRecord) async throws
}

/// Hands records to acme.certificates.v1.CertificateService.
struct HandOffFanSessionIDCertificate: HandOffFanSessionIDTarget {
    let client: Acme_Certificates_V1_CertificateService.Client<MeshTransport>

    func send(_ rec: HandOffFanSessionIDRecord) async throws {
        let request = Acme_Certificates_V1_SearchCertificatesRequest.with {
            $0.filter.query = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.searchCertificates(request)
        }
    }
}

/// Sends records to acme.patientapp.v1.PatientHomeService.
struct HandOffFanSessionIDPatientHome: HandOffFanSessionIDTarget {
    let client: Acme_Patientapp_V1_PatientHomeService.Client<MeshTransport>

    func send(_ rec: HandOffFanSessionIDRecord) async throws {
        let request = Acme_Patientapp_V1_CreatePatientHomeRequest.with {
            $0.patientHome.subject = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.createPatientHome(request)
        }
    }
}

/// Sends records to acme.patients.v1.MedicalRecordCalculationService.
struct HandOffFanSessionIDMedicalRecordCalculation: HandOffFanSessionIDTarget {
    let client: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>

    func send(_ rec: HandOffFanSessionIDRecord) async throws {
        let request = Acme_Patients_V1_SimulateMedicalRecordRequest.with {
            $0.medicalRecord.notes = rec.subject
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.simulateMedicalRecord(request)
        }
    }
}

/// Reads acme.fanportal.v1.FanSessionQueryService/PeekFanSession and hands what it keeps to the sink of its kind.
enum HandOffFanSessionID {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Fanportal_V1_FanSessionQueryService.Client(wrapping: mesh)
        let got = try await source.peekFanSession(.with { $0.fanSessionID = "nightly-hand-off-fan-session-id" })
        let row = HandOffFanSessionIDRecord(
            correlationID: got.result.correlationID,
            subject: Kit.Text.normalize(got.fanSession.subject)
        )
        let sinks: [any HandOffFanSessionIDTarget] = [
            HandOffFanSessionIDCertificate(client: Acme_Certificates_V1_CertificateService.Client(wrapping: mesh)),
            HandOffFanSessionIDPatientHome(client: Acme_Patientapp_V1_PatientHomeService.Client(wrapping: mesh)),
            HandOffFanSessionIDMedicalRecordCalculation(client: Acme_Patients_V1_MedicalRecordCalculationService.Client(wrapping: mesh)),
        ]
        try await sinks[0].send(row)
    }
}
