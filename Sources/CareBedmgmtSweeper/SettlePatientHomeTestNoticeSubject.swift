import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SettlePatientHomeTestNoticeSubject keeps of each SendPatientHomeTestNotice response.
struct SettlePatientHomeTestNoticeSubjectRecord {
    var subject: String
    var message: String
    var correlationID: String
}

/// Where SettlePatientHomeTestNoticeSubject hands each record.
protocol SettlePatientHomeTestNoticeSubjectDestination {
    func push(_ rec: SettlePatientHomeTestNoticeSubjectRecord) async throws
}

/// Hands records to acme.prescriptions.v1.PrescriptionWorkflowService.
struct SettlePatientHomeTestNoticeSubjectPrescriptionWorkflow: SettlePatientHomeTestNoticeSubjectDestination {
    let client: Acme_Prescriptions_V1_PrescriptionWorkflowService.Client<MeshTransport>

    func push(_ rec: SettlePatientHomeTestNoticeSubjectRecord) async throws {
        _ = try await client.retryPrescriptionWorkflow(.with {
            $0.reason = rec.subject
        })
    }
}

/// Writes records to acme.patients.v1.AllergyReportingService.
struct SettlePatientHomeTestNoticeSubjectAllergyReporting: SettlePatientHomeTestNoticeSubjectDestination {
    let client: Acme_Patients_V1_AllergyReportingService.Client<MeshTransport>

    func push(_ rec: SettlePatientHomeTestNoticeSubjectRecord) async throws {
        let request = Acme_Patients_V1_ShareAllergyReportRequest.with {
            $0.reason = rec.correlationID
            $0.details.templateID = rec.subject
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.shareAllergyReport(request)
        }
    }
}

/// Sends records to acme.careplans.v1.CareGoalApprovalService.
struct SettlePatientHomeTestNoticeSubjectCareGoalApproval: SettlePatientHomeTestNoticeSubjectDestination {
    let client: Acme_Careplans_V1_CareGoalApprovalService.Client<MeshTransport>

    func push(_ rec: SettlePatientHomeTestNoticeSubjectRecord) async throws {
        _ = try await client.commentCareGoalApproval(.with {
            $0.details.approverEmail = rec.message
            $0.careGoalID = rec.correlationID
            $0.careGoal.careGoalID = rec.subject
        })
    }
}

/// Reads acme.patientapp.v1.PatientHomeNotificationService/SendPatientHomeTestNotice and hands what it keeps to the sink of its kind.
enum SettlePatientHomeTestNoticeSubject {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Patientapp_V1_PatientHomeNotificationService.Client(wrapping: mesh)
        let response = try await upstream.sendPatientHomeTestNotice(.with { $0.reason = "live-settle-patient-home-test-notice-subject" })
        let entry = SettlePatientHomeTestNoticeSubjectRecord(
            subject: Kit.Text.normalize(response.patientHome.subject),
            message: response.result.message,
            correlationID: Kit.Text.normalize(response.result.correlationID)
        )
        try await act("care-goal-approval", entry, mesh)
    }

    /// Runs the action registered for a kind.
    static func act(_ kind: String, _ rec: SettlePatientHomeTestNoticeSubjectRecord, _ mesh: MeshClient) async throws {
        let actions: [String: () async throws -> Void] = [
            "prescription-workflow": { try await SettlePatientHomeTestNoticeSubjectPrescriptionWorkflow(client: Acme_Prescriptions_V1_PrescriptionWorkflowService.Client(wrapping: mesh)).push(rec) },
            "allergy-reporting": { try await SettlePatientHomeTestNoticeSubjectAllergyReporting(client: Acme_Patients_V1_AllergyReportingService.Client(wrapping: mesh)).push(rec) },
            "care-goal-approval": { try await SettlePatientHomeTestNoticeSubjectCareGoalApproval(client: Acme_Careplans_V1_CareGoalApprovalService.Client(wrapping: mesh)).push(rec) },
        ]
        guard let action = actions[kind] else {
            throw Kit.Failure("no action for \(kind)")
        }
        try await action()
    }
}
