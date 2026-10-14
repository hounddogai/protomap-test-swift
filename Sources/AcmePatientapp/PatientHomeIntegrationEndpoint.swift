import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Connects external systems that send patient home events.
final class PatientHomeIntegrationEndpoint: Acme_Patientapp_V1_PatientHomeIntegrationService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let followUps = WorkQueue<Acme_Identity_V1_GetUserRequest>()
    let auditAuditEventQuery: Acme_Audit_V1_AuditEventQueryService.Client<MeshTransport>
    let careplansCarePlanApproval: Acme_Careplans_V1_CarePlanApprovalService.Client<MeshTransport>
    let documentsDocument: Acme_Documents_V1_DocumentService.Client<MeshTransport>
    let documentsDocumentQuery: Acme_Documents_V1_DocumentQueryService.Client<MeshTransport>
    let fanportalFanSession: Acme_Fanportal_V1_FanSessionService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let patientappCareInboxWorkflow: Acme_Patientapp_V1_CareInboxWorkflowService.Client<MeshTransport>
    let patientappPatientHomeWorkflow: Acme_Patientapp_V1_PatientHomeWorkflowService.Client<MeshTransport>
    let patientsAllergyApproval: Acme_Patients_V1_AllergyApprovalService.Client<MeshTransport>
    let patientsPatientApproval: Acme_Patients_V1_PatientApprovalService.Client<MeshTransport>
    let patientsPatientSync: Acme_Patients_V1_PatientSyncService.Client<MeshTransport>
    let patientsPatientWorkflow: Acme_Patients_V1_PatientWorkflowService.Client<MeshTransport>
    let payrollPayRunQuery: Acme_Payroll_V1_PayRunQueryService.Client<MeshTransport>
    let prescriptionsPrescriptionApproval: Acme_Prescriptions_V1_PrescriptionApprovalService.Client<MeshTransport>
    let telehealthVideoVisitWorkflow: Acme_Telehealth_V1_VideoVisitWorkflowService.Client<MeshTransport>
    let acknowledgePatientHomeEventStep1:
        @Sendable (Acme_Patientapp_V1_AdvancePatientHomeWorkflowRequest) async throws ->
            Acme_Patientapp_V1_AdvancePatientHomeWorkflowResponse
    let acknowledgePatientHomeEventStep2:
        [String:
            @Sendable (Acme_Patientapp_V1_RetryCareInboxWorkflowRequest) async throws ->
            Acme_Patientapp_V1_RetryCareInboxWorkflowResponse]

    init(
        dependencies: any Dependencies,
        auditAuditEventQuery: Acme_Audit_V1_AuditEventQueryService.Client<MeshTransport>,
        careplansCarePlanApproval: Acme_Careplans_V1_CarePlanApprovalService.Client<MeshTransport>,
        documentsDocument: Acme_Documents_V1_DocumentService.Client<MeshTransport>,
        documentsDocumentQuery: Acme_Documents_V1_DocumentQueryService.Client<MeshTransport>,
        fanportalFanSession: Acme_Fanportal_V1_FanSessionService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        patientappCareInboxWorkflow: Acme_Patientapp_V1_CareInboxWorkflowService.Client<MeshTransport>,
        patientappPatientHomeWorkflow: Acme_Patientapp_V1_PatientHomeWorkflowService.Client<MeshTransport>,
        patientsAllergyApproval: Acme_Patients_V1_AllergyApprovalService.Client<MeshTransport>,
        patientsPatientApproval: Acme_Patients_V1_PatientApprovalService.Client<MeshTransport>,
        patientsPatientSync: Acme_Patients_V1_PatientSyncService.Client<MeshTransport>,
        patientsPatientWorkflow: Acme_Patients_V1_PatientWorkflowService.Client<MeshTransport>,
        payrollPayRunQuery: Acme_Payroll_V1_PayRunQueryService.Client<MeshTransport>,
        prescriptionsPrescriptionApproval: Acme_Prescriptions_V1_PrescriptionApprovalService.Client<MeshTransport>,
        telehealthVideoVisitWorkflow: Acme_Telehealth_V1_VideoVisitWorkflowService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.auditAuditEventQuery = auditAuditEventQuery
        self.careplansCarePlanApproval = careplansCarePlanApproval
        self.documentsDocument = documentsDocument
        self.documentsDocumentQuery = documentsDocumentQuery
        self.fanportalFanSession = fanportalFanSession
        self.identityUser = identityUser
        self.patientappCareInboxWorkflow = patientappCareInboxWorkflow
        self.patientappPatientHomeWorkflow = patientappPatientHomeWorkflow
        self.patientsAllergyApproval = patientsAllergyApproval
        self.patientsPatientApproval = patientsPatientApproval
        self.patientsPatientSync = patientsPatientSync
        self.patientsPatientWorkflow = patientsPatientWorkflow
        self.payrollPayRunQuery = payrollPayRunQuery
        self.prescriptionsPrescriptionApproval = prescriptionsPrescriptionApproval
        self.telehealthVideoVisitWorkflow = telehealthVideoVisitWorkflow
        self.acknowledgePatientHomeEventStep1 = { request in
            try await patientappPatientHomeWorkflow.advancePatientHomeWorkflow(request)
        }
        self.acknowledgePatientHomeEventStep2 = [
            "primary": { request in try await patientappCareInboxWorkflow.retryCareInboxWorkflow(request) }
        ]
    }

    /// Resolve follow-up ownership outside the RPC's lifetime.
    func runFollowUps() async throws {
        for await event in followUps.events {
            try Task.checkCancellation()
            do {
                let user = try await self.identityUser.getUser(event)
                logger.info("Follow-up resolved", metadata: ["user": .string(user.user.userID)])
            } catch {
                logger.error("Follow-up failed", metadata: ["error": .string(String(describing: error))])
            }
        }
    }
}
