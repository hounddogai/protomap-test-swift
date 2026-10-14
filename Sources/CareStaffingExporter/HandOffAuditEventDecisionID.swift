import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What HandOffAuditEventDecisionID keeps of each ExplainAuditEventDecision response.
struct HandOffAuditEventDecisionIDRecord {
    var auditEventID: String
    var correlationID: String
}

/// Where HandOffAuditEventDecisionID hands each record.
protocol HandOffAuditEventDecisionIDTarget {
    func send(_ rec: HandOffAuditEventDecisionIDRecord) async throws
}

/// Passes records to acme.featureflags.v1.FeatureFlagQueryService.
struct HandOffAuditEventDecisionIDFeatureFlagQuery: HandOffAuditEventDecisionIDTarget {
    let client: Acme_Featureflags_V1_FeatureFlagQueryService.Client<MeshTransport>

    func send(_ rec: HandOffAuditEventDecisionIDRecord) async throws {
        _ = try await client.peekFeatureFlag(.with {
            $0.featureFlagID = rec.auditEventID
        })
    }
}

/// Hands records to acme.patients.v1.MedicalRecordCalculationService.
struct HandOffAuditEventDecisionIDMedicalRecordCalculation: HandOffAuditEventDecisionIDTarget {
    let client: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>

    func send(_ rec: HandOffAuditEventDecisionIDRecord) async throws {
        let request = Acme_Patients_V1_CompareMedicalRecordOptionsRequest.with {
            $0.medicalRecordID = rec.auditEventID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.compareMedicalRecordOptions(request)
        }
    }
}

/// Reads acme.audit.v1.AuditEventValidationService/ExplainAuditEventDecision and hands what it keeps to the sink of its kind.
enum HandOffAuditEventDecisionID {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Audit_V1_AuditEventValidationService.Client(wrapping: mesh)
        let found = try await reader.explainAuditEventDecision(.with { $0.auditEventID = "nightly-hand-off-audit-event-decision-id" })
        let rec = HandOffAuditEventDecisionIDRecord(
            auditEventID: found.auditEvent.auditEventID,
            correlationID: Kit.Text.normalize(found.result.correlationID)
        )
        let sinks: [String: any HandOffAuditEventDecisionIDTarget] = [
            "feature-flag-query": HandOffAuditEventDecisionIDFeatureFlagQuery(client: Acme_Featureflags_V1_FeatureFlagQueryService.Client(wrapping: mesh)),
            "medical-record-calculation": HandOffAuditEventDecisionIDMedicalRecordCalculation(client: Acme_Patients_V1_MedicalRecordCalculationService.Client(wrapping: mesh)),
        ]
        try await route("medical-record-calculation", rec, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: HandOffAuditEventDecisionIDRecord, _ sinks: [String: any HandOffAuditEventDecisionIDTarget]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.send(rec)
    }
}
