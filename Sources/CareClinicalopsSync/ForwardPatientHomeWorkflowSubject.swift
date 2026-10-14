import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ForwardPatientHomeWorkflowSubject keeps of each AdvancePatientHomeWorkflow response.
struct ForwardPatientHomeWorkflowSubjectRecord {
    var subject: String
    var status: String
}

/// Where ForwardPatientHomeWorkflowSubject hands each record.
protocol ForwardPatientHomeWorkflowSubjectWriter {
    func send(_ rec: ForwardPatientHomeWorkflowSubjectRecord) async throws
}

/// Hands records to acme.careplans.v1.CareGoalWorkflowService.
struct ForwardPatientHomeWorkflowSubjectCareGoalWorkflow: ForwardPatientHomeWorkflowSubjectWriter {
    let client: Acme_Careplans_V1_CareGoalWorkflowService.Client<MeshTransport>

    func send(_ rec: ForwardPatientHomeWorkflowSubjectRecord) async throws {
        _ = try await client.resumeCareGoalWorkflow(.with {
            $0.reason = rec.subject
        })
    }
}

/// Passes records to acme.prescriptions.v1.RefillWorkflowService.
struct ForwardPatientHomeWorkflowSubjectRefillWorkflow: ForwardPatientHomeWorkflowSubjectWriter {
    let client: Acme_Prescriptions_V1_RefillWorkflowService.Client<MeshTransport>

    func send(_ rec: ForwardPatientHomeWorkflowSubjectRecord) async throws {
        _ = try await client.listRefillWorkflows(.with {
            $0.page.pageToken = rec.status
            $0.filter.ownerID = rec.subject
        })
    }
}

/// Passes records to acme.notifications.v1.NotificationValidationService.
struct ForwardPatientHomeWorkflowSubjectNotificationValidation: ForwardPatientHomeWorkflowSubjectWriter {
    let client: Acme_Notifications_V1_NotificationValidationService.Client<MeshTransport>

    func send(_ rec: ForwardPatientHomeWorkflowSubjectRecord) async throws {
        _ = try await client.normalizeNotification(.with {
            $0.details.locale = rec.status
        })
    }
}

/// Passes records to acme.configuration.v1.ConfigSetService.
struct ForwardPatientHomeWorkflowSubjectConfigSet: ForwardPatientHomeWorkflowSubjectWriter {
    let client: Acme_Configuration_V1_ConfigSetService.Client<MeshTransport>

    func send(_ rec: ForwardPatientHomeWorkflowSubjectRecord) async throws {
        _ = try await client.getConfigSet(.with {
            $0.configSetID = rec.subject
        })
    }
}

/// Reads acme.patientapp.v1.PatientHomeWorkflowService/AdvancePatientHomeWorkflow and hands what it keeps to the sink of its kind.
enum ForwardPatientHomeWorkflowSubject {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Patientapp_V1_PatientHomeWorkflowService.Client(wrapping: mesh)
        let found = try await upstream.advancePatientHomeWorkflow(.with { $0.patientHomeID = "live-forward-patient-home-workflow-subject" })
        let rec = ForwardPatientHomeWorkflowSubjectRecord(
            subject: Kit.Text.normalize(found.patientHome.subject),
            status: found.outcome.status
        )
        let sinks: [String: any ForwardPatientHomeWorkflowSubjectWriter] = [
            "care-goal-workflow": ForwardPatientHomeWorkflowSubjectCareGoalWorkflow(client: Acme_Careplans_V1_CareGoalWorkflowService.Client(wrapping: mesh)),
            "refill-workflow": ForwardPatientHomeWorkflowSubjectRefillWorkflow(client: Acme_Prescriptions_V1_RefillWorkflowService.Client(wrapping: mesh)),
            "notification-validation": ForwardPatientHomeWorkflowSubjectNotificationValidation(client: Acme_Notifications_V1_NotificationValidationService.Client(wrapping: mesh)),
            "config-set": ForwardPatientHomeWorkflowSubjectConfigSet(client: Acme_Configuration_V1_ConfigSetService.Client(wrapping: mesh)),
        ]
        guard let sink = sinks[ProcessInfo.processInfo.environment["FORWARD_PATIENT_HOME_WORKFLOW_SUBJECT_TARGET"] ?? ""] else {
            return
        }
        try await sink.send(rec)
    }
}
