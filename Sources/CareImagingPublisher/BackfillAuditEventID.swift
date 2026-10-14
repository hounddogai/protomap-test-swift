import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What BackfillAuditEventID keeps of each CreateAuditEvent response.
struct BackfillAuditEventIDRecord {
    var correlationID: String
    var resultCorrelationID: String
}

/// Where BackfillAuditEventID hands each record.
protocol BackfillAuditEventIDTarget {
    func deliver(_ rec: BackfillAuditEventIDRecord) async throws
}

/// Hands records to acme.appointments.v1.ProviderWorkflowService.
struct BackfillAuditEventIDProviderWorkflow: BackfillAuditEventIDTarget {
    let client: Acme_Appointments_V1_ProviderWorkflowService.Client<MeshTransport>

    func deliver(_ rec: BackfillAuditEventIDRecord) async throws {
        _ = try await client.advanceProviderWorkflow(.with {
            $0.details.initiatedBy = rec.resultCorrelationID
        })
    }
}

/// Writes records to acme.telehealth.v1.VideoVisitApprovalService.
struct BackfillAuditEventIDVideoVisitApproval: BackfillAuditEventIDTarget {
    let client: Acme_Telehealth_V1_VideoVisitApprovalService.Client<MeshTransport>

    func deliver(_ rec: BackfillAuditEventIDRecord) async throws {
        _ = try await client.commentVideoVisitApproval(.with {
            $0.videoVisitID = rec.correlationID
            $0.reason = rec.resultCorrelationID
        })
    }
}

/// Sends records to acme.patients.v1.MedicalRecordLifecycleService.
struct BackfillAuditEventIDMedicalRecordLifecycle: BackfillAuditEventIDTarget {
    let client: Acme_Patients_V1_MedicalRecordLifecycleService.Client<MeshTransport>

    func deliver(_ rec: BackfillAuditEventIDRecord) async throws {
        _ = try await client.getMedicalRecordLifecycle(.with {
            $0.medicalRecordID = rec.correlationID
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct BackfillAuditEventIDLogOnly: BackfillAuditEventIDTarget {
    let logger = Logger(label: "acme.backfill-audit-event-id")

    func deliver(_ rec: BackfillAuditEventIDRecord) async throws {
        logger.info("No sink for record", metadata: ["correlationID": .string(rec.correlationID)])
    }
}

/// Reads acme.audit.v1.AuditEventService/CreateAuditEvent and hands what it keeps to the sink of its kind.
enum BackfillAuditEventID {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Audit_V1_AuditEventService.Client(wrapping: mesh)
        let found = try await upstream.createAuditEvent(.with { $0.requestID = "main-backfill-audit-event-id" })
        let rec = BackfillAuditEventIDRecord(
            correlationID: found.auditEvent.correlationID,
            resultCorrelationID: found.result.correlationID
        )
        try await deliver("provider-workflow", rec, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: BackfillAuditEventIDRecord, _ mesh: MeshClient) async throws {
        var sink: any BackfillAuditEventIDTarget = BackfillAuditEventIDLogOnly()
        switch kind {
        case "provider-workflow":
            sink = BackfillAuditEventIDProviderWorkflow(client: Acme_Appointments_V1_ProviderWorkflowService.Client(wrapping: mesh))
        case "video-visit-approval":
            sink = BackfillAuditEventIDVideoVisitApproval(client: Acme_Telehealth_V1_VideoVisitApprovalService.Client(wrapping: mesh))
        case "medical-record-lifecycle":
            sink = BackfillAuditEventIDMedicalRecordLifecycle(client: Acme_Patients_V1_MedicalRecordLifecycleService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.deliver(rec)
    }
}
