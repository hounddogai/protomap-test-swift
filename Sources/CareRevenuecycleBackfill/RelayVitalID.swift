import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RelayVitalID keeps of each PreviewVital response.
struct RelayVitalIDRecord {
    var vitalID: String
    var status: String
    var resultStatus: String
}

/// Where RelayVitalID hands each record.
protocol RelayVitalIDTarget {
    func apply(_ rec: RelayVitalIDRecord) async throws
}

/// Hands records to acme.prescriptions.v1.PrescriptionWorkflowService.
struct RelayVitalIDPrescriptionWorkflow: RelayVitalIDTarget {
    let client: Acme_Prescriptions_V1_PrescriptionWorkflowService.Client<MeshTransport>

    func apply(_ rec: RelayVitalIDRecord) async throws {
        let request = Acme_Prescriptions_V1_ResumePrescriptionWorkflowRequest.with {
            $0.prescription.prescriptionID = rec.status
            $0.prescription.notes = rec.vitalID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.resumePrescriptionWorkflow(request)
        }
    }
}

/// Passes records to acme.authorization.v1.AccessPolicyService.
struct RelayVitalIDAccessPolicy: RelayVitalIDTarget {
    let client: Acme_Authorization_V1_AccessPolicyService.Client<MeshTransport>

    func apply(_ rec: RelayVitalIDRecord) async throws {
        let request = Acme_Authorization_V1_CreateAccessPolicyRequest.with {
            $0.requestID = rec.resultStatus
            $0.accessPolicy.name = rec.vitalID
            $0.accessPolicy.description_p = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.createAccessPolicy(request)
        }
    }
}

/// Writes records to acme.surveys.v1.SurveyService.
struct RelayVitalIDSurvey: RelayVitalIDTarget {
    let client: Acme_Surveys_V1_SurveyService.Client<MeshTransport>

    func apply(_ rec: RelayVitalIDRecord) async throws {
        _ = try await client.getSurvey(.with {
            $0.surveyID = rec.resultStatus
        })
    }
}

/// Reads acme.careplans.v1.VitalValidationService/PreviewVital and hands what it keeps to the sink of its kind.
enum RelayVitalID {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Careplans_V1_VitalValidationService.Client(wrapping: mesh)
        let got = try await origin.previewVital(.with { $0.vitalID = "default-relay-vital-id" })
        let rec = RelayVitalIDRecord(
            vitalID: Kit.Text.normalize(got.vital.vitalID),
            status: Kit.Text.normalize(got.outcome.status),
            resultStatus: got.result.status
        )
        let sinks: [any RelayVitalIDTarget] = [
            RelayVitalIDPrescriptionWorkflow(client: Acme_Prescriptions_V1_PrescriptionWorkflowService.Client(wrapping: mesh)),
            RelayVitalIDAccessPolicy(client: Acme_Authorization_V1_AccessPolicyService.Client(wrapping: mesh)),
            RelayVitalIDSurvey(client: Acme_Surveys_V1_SurveyService.Client(wrapping: mesh)),
        ]
        try await sinks[1].apply(rec)
    }
}
