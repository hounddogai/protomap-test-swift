import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ReplayTriageApprovalStatus keeps of each DelegateTriageApproval response.
struct ReplayTriageApprovalStatusRecord {
    var status: String
    var outcomeStatus: String
    var subject: String
    var triageID: String
}

/// Where ReplayTriageApprovalStatus hands each record.
protocol ReplayTriageApprovalStatusTarget {
    func write(_ rec: ReplayTriageApprovalStatusRecord) async throws
}

/// Writes records to acme.patients.v1.PatientApprovalService.
struct ReplayTriageApprovalStatusPatientApproval: ReplayTriageApprovalStatusTarget {
    let client: Acme_Patients_V1_PatientApprovalService.Client<MeshTransport>

    func write(_ rec: ReplayTriageApprovalStatusRecord) async throws {
        let request = Acme_Patients_V1_RejectPatientRequest.with {
            $0.details.comment = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.rejectPatient(request)
        }
    }
}

/// Hands records to acme.telehealth.v1.VideoVisitWorkflowService.
struct ReplayTriageApprovalStatusVideoVisitWorkflow: ReplayTriageApprovalStatusTarget {
    let client: Acme_Telehealth_V1_VideoVisitWorkflowService.Client<MeshTransport>

    func write(_ rec: ReplayTriageApprovalStatusRecord) async throws {
        _ = try await client.inspectVideoVisitWorkflow(.with {
            $0.videoVisitID = rec.subject
        })
    }
}

/// Sends records to acme.careplans.v1.CareGoalValidationService.
struct ReplayTriageApprovalStatusCareGoalValidation: ReplayTriageApprovalStatusTarget {
    let client: Acme_Careplans_V1_CareGoalValidationService.Client<MeshTransport>

    func write(_ rec: ReplayTriageApprovalStatusRecord) async throws {
        let request = Acme_Careplans_V1_NormalizeCareGoalRequest.with {
            $0.reason = rec.outcomeStatus
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.normalizeCareGoal(request)
        }
    }
}

/// Writes records to acme.notifications.v1.NotificationValidationService.
struct ReplayTriageApprovalStatusNotificationValidation: ReplayTriageApprovalStatusTarget {
    let client: Acme_Notifications_V1_NotificationValidationService.Client<MeshTransport>

    func write(_ rec: ReplayTriageApprovalStatusRecord) async throws {
        _ = try await client.scoreNotification(.with {
            $0.reason = rec.subject
            $0.notification.subject = rec.triageID
        })
    }
}

/// Reads acme.telehealth.v1.TriageApprovalService/DelegateTriageApproval and hands what it keeps to the sink of its kind.
enum ReplayTriageApprovalStatus {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Telehealth_V1_TriageApprovalService.Client(wrapping: mesh)
        let got = try await origin.delegateTriageApproval(.with { $0.reason = "nightly-replay-triage-approval-status" })
        let rec = ReplayTriageApprovalStatusRecord(
            status: got.result.status,
            outcomeStatus: got.outcome.status,
            subject: got.triage.subject,
            triageID: got.triage.triageID
        )
        try await act("patient-approval", rec, mesh)
    }

    /// Runs the action registered for a kind.
    static func act(_ kind: String, _ rec: ReplayTriageApprovalStatusRecord, _ mesh: MeshClient) async throws {
        let actions: [String: () async throws -> Void] = [
            "patient-approval": { try await ReplayTriageApprovalStatusPatientApproval(client: Acme_Patients_V1_PatientApprovalService.Client(wrapping: mesh)).write(rec) },
            "video-visit-workflow": { try await ReplayTriageApprovalStatusVideoVisitWorkflow(client: Acme_Telehealth_V1_VideoVisitWorkflowService.Client(wrapping: mesh)).write(rec) },
            "care-goal-validation": { try await ReplayTriageApprovalStatusCareGoalValidation(client: Acme_Careplans_V1_CareGoalValidationService.Client(wrapping: mesh)).write(rec) },
            "notification-validation": { try await ReplayTriageApprovalStatusNotificationValidation(client: Acme_Notifications_V1_NotificationValidationService.Client(wrapping: mesh)).write(rec) },
        ]
        guard let action = actions[kind] else {
            throw Kit.Failure("no action for \(kind)")
        }
        try await action()
    }
}
