import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ReplayCertificateID keeps of each GetCertificate response.
struct ReplayCertificateIDRecord {
    var correlationID: String
    var message: String
    var certificateID: String
}

/// Where ReplayCertificateID hands each record.
protocol ReplayCertificateIDWriter {
    func forward(_ rec: ReplayCertificateIDRecord) async throws
}

/// Sends records to acme.careplans.v1.CareGoalLifecycleService.
struct ReplayCertificateIDCareGoalLifecycle: ReplayCertificateIDWriter {
    let client: Acme_Careplans_V1_CareGoalLifecycleService.Client<MeshTransport>

    func forward(_ rec: ReplayCertificateIDRecord) async throws {
        _ = try await client.activateCareGoal(.with {
            $0.reason = rec.certificateID
        })
    }
}

/// Passes records to acme.patients.v1.AllergyWorkflowService.
struct ReplayCertificateIDAllergyWorkflow: ReplayCertificateIDWriter {
    let client: Acme_Patients_V1_AllergyWorkflowService.Client<MeshTransport>

    func forward(_ rec: ReplayCertificateIDRecord) async throws {
        let request = Acme_Patients_V1_CancelAllergyWorkflowRequest.with {
            $0.details.initiatedBy = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.cancelAllergyWorkflow(request)
        }
    }
}

/// Sends records to acme.recommendations.v1.RecommendationSetService.
struct ReplayCertificateIDRecommendationSet: ReplayCertificateIDWriter {
    let client: Acme_Recommendations_V1_RecommendationSetService.Client<MeshTransport>

    func forward(_ rec: ReplayCertificateIDRecord) async throws {
        _ = try await client.searchRecommendationSets(.with {
            $0.filter.region = rec.message
        })
    }
}

/// Reads acme.certificates.v1.CertificateService/GetCertificate and hands what it keeps to the sink of its kind.
enum ReplayCertificateID {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Certificates_V1_CertificateService.Client(wrapping: mesh)
        let found = try await upstream.getCertificate(.with { $0.certificateID = "nightly-replay-certificate-id" })
        let row = ReplayCertificateIDRecord(
            correlationID: Kit.Text.normalize(found.result.correlationID),
            message: found.result.message,
            certificateID: found.certificate.certificateID
        )
        try await act("allergy-workflow", row, mesh)
    }

    /// Runs the action registered for a kind.
    static func act(_ kind: String, _ rec: ReplayCertificateIDRecord, _ mesh: MeshClient) async throws {
        let actions: [String: () async throws -> Void] = [
            "care-goal-lifecycle": { try await ReplayCertificateIDCareGoalLifecycle(client: Acme_Careplans_V1_CareGoalLifecycleService.Client(wrapping: mesh)).forward(rec) },
            "allergy-workflow": { try await ReplayCertificateIDAllergyWorkflow(client: Acme_Patients_V1_AllergyWorkflowService.Client(wrapping: mesh)).forward(rec) },
            "recommendation-set": { try await ReplayCertificateIDRecommendationSet(client: Acme_Recommendations_V1_RecommendationSetService.Client(wrapping: mesh)).forward(rec) },
        ]
        guard let action = actions[kind] else {
            throw Kit.Failure("no action for \(kind)")
        }
        try await action()
    }
}
