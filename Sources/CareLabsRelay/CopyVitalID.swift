import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CopyVitalID keeps of each EscalateVital response.
struct CopyVitalIDRecord {
    var correlationID: String
    var status: String
}

/// Where CopyVitalID hands each record.
protocol CopyVitalIDWriter {
    func forward(_ rec: CopyVitalIDRecord) async throws
}

/// Sends records to acme.audiences.v1.AudienceService.
struct CopyVitalIDAudience: CopyVitalIDWriter {
    let client: Acme_Audiences_V1_AudienceService.Client<MeshTransport>

    func forward(_ rec: CopyVitalIDRecord) async throws {
        _ = try await client.deleteAudience(.with {
            $0.etag = rec.status
            $0.audienceID = rec.correlationID
        })
    }
}

/// Hands records to acme.audit.v1.AuditEventValidationService.
struct CopyVitalIDAuditEventValidation: CopyVitalIDWriter {
    let client: Acme_Audit_V1_AuditEventValidationService.Client<MeshTransport>

    func forward(_ rec: CopyVitalIDRecord) async throws {
        _ = try await client.checkAuditEventEligibility(.with {
            $0.auditEvent.auditEventID = rec.status
            $0.auditEvent.kind = rec.correlationID
        })
    }
}

/// Reads acme.careplans.v1.VitalApprovalService/EscalateVital and hands what it keeps to the sink of its kind.
enum CopyVitalID {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Careplans_V1_VitalApprovalService.Client(wrapping: mesh)
        let response = try await reader.escalateVital(.with { $0.vitalID = "nightly-copy-vital-id" })
        let rec = CopyVitalIDRecord(
            correlationID: response.result.correlationID,
            status: response.outcome.status
        )
        try await act("audit-event-validation", rec, mesh)
    }

    /// Runs the action registered for a kind.
    static func act(_ kind: String, _ rec: CopyVitalIDRecord, _ mesh: MeshClient) async throws {
        let actions: [String: () async throws -> Void] = [
            "audience": { try await CopyVitalIDAudience(client: Acme_Audiences_V1_AudienceService.Client(wrapping: mesh)).forward(rec) },
            "audit-event-validation": { try await CopyVitalIDAuditEventValidation(client: Acme_Audit_V1_AuditEventValidationService.Client(wrapping: mesh)).forward(rec) },
        ]
        guard let action = actions[kind] else {
            throw Kit.Failure("no action for \(kind)")
        }
        try await action()
    }
}
