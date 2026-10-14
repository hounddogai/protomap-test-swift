import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ForwardAllergySource keeps of each ActivateAllergy response.
struct ForwardAllergySourceRecord {
    var source: String
    var referenceID: String
    var correlationID: String
}

/// Where ForwardAllergySource hands each record.
protocol ForwardAllergySourceTarget {
    func send(_ rec: ForwardAllergySourceRecord) async throws
}

/// Passes records to acme.patients.v1.AllergyLifecycleService.
struct ForwardAllergySourceAllergyLifecycle: ForwardAllergySourceTarget {
    let client: Acme_Patients_V1_AllergyLifecycleService.Client<MeshTransport>

    func send(_ rec: ForwardAllergySourceRecord) async throws {
        let request = Acme_Patients_V1_ReinstateAllergyRequest.with {
            $0.allergyID = rec.correlationID
            $0.reason = rec.source
            $0.details.reasonCode = rec.referenceID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.reinstateAllergy(request)
        }
    }
}

/// Passes records to acme.authorization.v1.AccessPolicyValidationService.
struct ForwardAllergySourceAccessPolicyValidation: ForwardAllergySourceTarget {
    let client: Acme_Authorization_V1_AccessPolicyValidationService.Client<MeshTransport>

    func send(_ rec: ForwardAllergySourceRecord) async throws {
        let request = Acme_Authorization_V1_ExplainAccessPolicyDecisionRequest.with {
            $0.accessPolicy.name = rec.source
            $0.details.locale = rec.referenceID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.explainAccessPolicyDecision(request)
        }
    }
}

/// Writes records to acme.patients.v1.MedicalRecordValidationService.
struct ForwardAllergySourceMedicalRecordValidation: ForwardAllergySourceTarget {
    let client: Acme_Patients_V1_MedicalRecordValidationService.Client<MeshTransport>

    func send(_ rec: ForwardAllergySourceRecord) async throws {
        _ = try await client.scoreMedicalRecord(.with {
            $0.medicalRecord.medicalRecordID = rec.correlationID
            $0.details.currencyCode = rec.source
            $0.reason = rec.referenceID
        })
    }
}

/// Reads acme.patients.v1.AllergyLifecycleService/ActivateAllergy and hands what it keeps to the sink of its kind.
enum ForwardAllergySource {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Patients_V1_AllergyLifecycleService.Client(wrapping: mesh)
        let got = try await source.activateAllergy(.with { $0.allergyID = "default-forward-allergy-source" })
        let rec = ForwardAllergySourceRecord(
            source: Kit.Text.normalize(got.allergy.source),
            referenceID: got.outcome.referenceID,
            correlationID: got.result.correlationID
        )
        try await act("allergy-lifecycle", rec, mesh)
    }

    /// Runs the action registered for a kind.
    static func act(_ kind: String, _ rec: ForwardAllergySourceRecord, _ mesh: MeshClient) async throws {
        let actions: [String: () async throws -> Void] = [
            "allergy-lifecycle": { try await ForwardAllergySourceAllergyLifecycle(client: Acme_Patients_V1_AllergyLifecycleService.Client(wrapping: mesh)).send(rec) },
            "access-policy-validation": { try await ForwardAllergySourceAccessPolicyValidation(client: Acme_Authorization_V1_AccessPolicyValidationService.Client(wrapping: mesh)).send(rec) },
            "medical-record-validation": { try await ForwardAllergySourceMedicalRecordValidation(client: Acme_Patients_V1_MedicalRecordValidationService.Client(wrapping: mesh)).send(rec) },
        ]
        guard let action = actions[kind] else {
            throw Kit.Failure("no action for \(kind)")
        }
        try await action()
    }
}
