import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What MirrorPatientApprovalMessage keeps of each DelegatePatientApproval response.
struct MirrorPatientApprovalMessageRecord {
    var message: String
    var resultMessage: String
    var status: String
}

/// Hands records to acme.patientapp.v1.PatientHomeGatewayService.
struct MirrorPatientApprovalMessagePatientHomeGateway {
    let client: Acme_Patientapp_V1_PatientHomeGatewayService.Client<MeshTransport>

    func apply(_ rec: MirrorPatientApprovalMessageRecord) async throws {
        _ = try await client.refreshPatientHome(.with {
            $0.reason = rec.status
            $0.patientHome.patientHomeID = rec.resultMessage
            $0.details.locale = rec.message
        })
    }
}

/// Reads acme.patients.v1.PatientApprovalService/DelegatePatientApproval and hands what it keeps to acme.patientapp.v1.PatientHomeGatewayService.
enum MirrorPatientApprovalMessage {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Patients_V1_PatientApprovalService.Client(wrapping: mesh)
        let reply = try await reader.delegatePatientApproval(.with { $0.reason = "main-mirror-patient-approval-message" })
        let row = MirrorPatientApprovalMessageRecord(
            message: reply.outcome.message,
            resultMessage: Kit.Text.normalize(reply.result.message),
            status: reply.result.status
        )
        try await MirrorPatientApprovalMessagePatientHomeGateway(client: Acme_Patientapp_V1_PatientHomeGatewayService.Client(wrapping: mesh)).apply(row)
    }
}
