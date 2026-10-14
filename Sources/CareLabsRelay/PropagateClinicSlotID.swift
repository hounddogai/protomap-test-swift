import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What PropagateClinicSlotID keeps of each ApproveClinicSlot response.
struct PropagateClinicSlotIDRecord {
    var referenceID: String
    var status: String
}

/// Where PropagateClinicSlotID hands each record.
protocol PropagateClinicSlotIDTarget {
    func push(_ rec: PropagateClinicSlotIDRecord) async throws
}

/// Hands records to acme.audit.v1.AuditEventValidationService.
struct PropagateClinicSlotIDAuditEventValidation: PropagateClinicSlotIDTarget {
    let client: Acme_Audit_V1_AuditEventValidationService.Client<MeshTransport>

    func push(_ rec: PropagateClinicSlotIDRecord) async throws {
        _ = try await client.validateAuditEvent(.with {
            $0.reason = rec.referenceID
            $0.auditEventID = rec.status
        })
    }
}

/// Hands records to acme.concessions.v1.ConcessionStandQueryService.
struct PropagateClinicSlotIDConcessionStandQuery: PropagateClinicSlotIDTarget {
    let client: Acme_Concessions_V1_ConcessionStandQueryService.Client<MeshTransport>

    func push(_ rec: PropagateClinicSlotIDRecord) async throws {
        _ = try await client.countConcessionStands(.with {
            $0.filter.query = rec.status
            $0.page.pageToken = rec.referenceID
        })
    }
}

/// Reads acme.appointments.v1.ClinicSlotApprovalService/ApproveClinicSlot and hands what it keeps to the sink of its kind.
enum PropagateClinicSlotID {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Appointments_V1_ClinicSlotApprovalService.Client(wrapping: mesh)
        let found = try await origin.approveClinicSlot(.with { $0.clinicSlotID = "main-propagate-clinic-slot-id" })
        let record = PropagateClinicSlotIDRecord(
            referenceID: found.outcome.referenceID,
            status: found.result.status
        )
        let sinks: [String: any PropagateClinicSlotIDTarget] = [
            "audit-event-validation": PropagateClinicSlotIDAuditEventValidation(client: Acme_Audit_V1_AuditEventValidationService.Client(wrapping: mesh)),
            "concession-stand-query": PropagateClinicSlotIDConcessionStandQuery(client: Acme_Concessions_V1_ConcessionStandQueryService.Client(wrapping: mesh)),
        ]
        try await route("concession-stand-query", record, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: PropagateClinicSlotIDRecord, _ sinks: [String: any PropagateClinicSlotIDTarget]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.push(rec)
    }
}
