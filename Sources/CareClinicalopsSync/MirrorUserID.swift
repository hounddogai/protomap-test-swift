import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What MirrorUserID keeps of each NormalizeUser response.
struct MirrorUserIDRecord {
    var referenceID: String
    var userID: String
}

/// Where MirrorUserID hands each record.
protocol MirrorUserIDWriter {
    func forward(_ rec: MirrorUserIDRecord) async throws
}

/// Sends records to acme.careplans.v1.VitalValidationService.
struct MirrorUserIDVitalValidation: MirrorUserIDWriter {
    let client: Acme_Careplans_V1_VitalValidationService.Client<MeshTransport>

    func forward(_ rec: MirrorUserIDRecord) async throws {
        let request = Acme_Careplans_V1_GetVitalRulesRequest.with {
            $0.vitalID = rec.referenceID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.getVitalRules(request)
        }
    }
}

/// Hands records to acme.patients.v1.PatientWorkflowService.
struct MirrorUserIDPatientWorkflow: MirrorUserIDWriter {
    let client: Acme_Patients_V1_PatientWorkflowService.Client<MeshTransport>

    func forward(_ rec: MirrorUserIDRecord) async throws {
        let request = Acme_Patients_V1_InspectPatientWorkflowRequest.with {
            $0.patientID = rec.referenceID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.inspectPatientWorkflow(request)
        }
    }
}

/// Sends records to acme.prescriptions.v1.RefillReportingService.
struct MirrorUserIDRefillReporting: MirrorUserIDWriter {
    let client: Acme_Prescriptions_V1_RefillReportingService.Client<MeshTransport>

    func forward(_ rec: MirrorUserIDRecord) async throws {
        _ = try await client.deleteRefillReport(.with {
            $0.etag = rec.referenceID
            $0.reason = rec.userID
        })
    }
}

/// Reads acme.identity.v1.UserValidationService/NormalizeUser and hands what it keeps to the sink of its kind.
enum MirrorUserID {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Identity_V1_UserValidationService.Client(wrapping: mesh)
        let response = try await reader.normalizeUser(.with { $0.userID = "main-mirror-user-id" })
        let record = MirrorUserIDRecord(
            referenceID: response.outcome.referenceID,
            userID: Kit.Text.normalize(response.user.userID)
        )
        let sinks: [String: any MirrorUserIDWriter] = [
            "vital-validation": MirrorUserIDVitalValidation(client: Acme_Careplans_V1_VitalValidationService.Client(wrapping: mesh)),
            "patient-workflow": MirrorUserIDPatientWorkflow(client: Acme_Patients_V1_PatientWorkflowService.Client(wrapping: mesh)),
            "refill-reporting": MirrorUserIDRefillReporting(client: Acme_Prescriptions_V1_RefillReportingService.Client(wrapping: mesh)),
        ]
        for (kind, sink) in sinks {
            if kind != "vital-validation" {
                continue
            }
            try await sink.forward(record)
        }
    }
}
