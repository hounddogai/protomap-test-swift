import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SettlePatientHomeWorkflowSubject keeps of each PausePatientHomeWorkflow response.
struct SettlePatientHomeWorkflowSubjectRecord {
    var subject: String
    var message: String
    var resultMessage: String
}

/// Where SettlePatientHomeWorkflowSubject hands each record.
protocol SettlePatientHomeWorkflowSubjectWriter {
    func apply(_ rec: SettlePatientHomeWorkflowSubjectRecord) async throws
}

/// Passes records to acme.careplans.v1.CarePlanApprovalService.
struct SettlePatientHomeWorkflowSubjectCarePlanApproval: SettlePatientHomeWorkflowSubjectWriter {
    let client: Acme_Careplans_V1_CarePlanApprovalService.Client<MeshTransport>

    func apply(_ rec: SettlePatientHomeWorkflowSubjectRecord) async throws {
        _ = try await client.listPendingCarePlans(.with {
            $0.filter.query = rec.subject
            $0.filter.ownerID = rec.resultMessage
        })
    }
}

/// Passes records to acme.authorization.v1.AccessPolicyService.
struct SettlePatientHomeWorkflowSubjectAccessPolicy: SettlePatientHomeWorkflowSubjectWriter {
    let client: Acme_Authorization_V1_AccessPolicyService.Client<MeshTransport>

    func apply(_ rec: SettlePatientHomeWorkflowSubjectRecord) async throws {
        let request = Acme_Authorization_V1_GetAccessPolicyRequest.with {
            $0.accessPolicyID = rec.resultMessage
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.getAccessPolicy(request)
        }
    }
}

/// Writes records to acme.telehealth.v1.VisitNoteQueryService.
struct SettlePatientHomeWorkflowSubjectVisitNoteQuery: SettlePatientHomeWorkflowSubjectWriter {
    let client: Acme_Telehealth_V1_VisitNoteQueryService.Client<MeshTransport>

    func apply(_ rec: SettlePatientHomeWorkflowSubjectRecord) async throws {
        let request = Acme_Telehealth_V1_BrowseVisitNotesRequest.with {
            $0.page.pageToken = rec.subject
            $0.filter.ownerID = rec.message
            $0.filter.region = rec.resultMessage
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.browseVisitNotes(request)
        }
    }
}

/// Only logs, for kinds no service takes yet.
struct SettlePatientHomeWorkflowSubjectLogOnly: SettlePatientHomeWorkflowSubjectWriter {
    let logger = Logger(label: "acme.settle-patient-home-workflow-subject")

    func apply(_ rec: SettlePatientHomeWorkflowSubjectRecord) async throws {
        logger.info("No sink for record", metadata: ["subject": .string(rec.subject)])
    }
}

/// Reads acme.patientapp.v1.PatientHomeWorkflowService/PausePatientHomeWorkflow and hands what it keeps to the sink of its kind.
enum SettlePatientHomeWorkflowSubject {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Patientapp_V1_PatientHomeWorkflowService.Client(wrapping: mesh)
        let found = try await origin.pausePatientHomeWorkflow(.with { $0.patientHomeID = "default-settle-patient-home-workflow-subject" })
        let entry = SettlePatientHomeWorkflowSubjectRecord(
            subject: Kit.Text.normalize(found.patientHome.subject),
            message: Kit.Text.normalize(found.outcome.message),
            resultMessage: found.result.message
        )
        try await deliver("access-policy", entry, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: SettlePatientHomeWorkflowSubjectRecord, _ mesh: MeshClient) async throws {
        var sink: any SettlePatientHomeWorkflowSubjectWriter = SettlePatientHomeWorkflowSubjectLogOnly()
        switch kind {
        case "care-plan-approval":
            sink = SettlePatientHomeWorkflowSubjectCarePlanApproval(client: Acme_Careplans_V1_CarePlanApprovalService.Client(wrapping: mesh))
        case "access-policy":
            sink = SettlePatientHomeWorkflowSubjectAccessPolicy(client: Acme_Authorization_V1_AccessPolicyService.Client(wrapping: mesh))
        case "visit-note-query":
            sink = SettlePatientHomeWorkflowSubjectVisitNoteQuery(client: Acme_Telehealth_V1_VisitNoteQueryService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.apply(rec)
    }
}
