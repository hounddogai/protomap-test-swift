import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Runs the long-lived workflow that takes an allergy from start to finish.
final class AllergyWorkflowEndpoint: Acme_Patients_V1_AllergyWorkflowService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let followUps = WorkQueue<Acme_Identity_V1_GetUserRequest>()
    let auditAuditEventQuery: Acme_Audit_V1_AuditEventQueryService.Client<MeshTransport>
    let benefitsBenefitPlan: Acme_Benefits_V1_BenefitPlanService.Client<MeshTransport>
    let documentsDocumentValidation: Acme_Documents_V1_DocumentValidationService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let notificationsNotificationQuery: Acme_Notifications_V1_NotificationQueryService.Client<MeshTransport>
    let patientsAllergyApproval: Acme_Patients_V1_AllergyApprovalService.Client<MeshTransport>
    let patientsAllergyCalculation: Acme_Patients_V1_AllergyCalculationService.Client<MeshTransport>
    let patientsAllergyImport: Acme_Patients_V1_AllergyImportService.Client<MeshTransport>
    let patientsAllergyReporting: Acme_Patients_V1_AllergyReportingService.Client<MeshTransport>
    let patientsMedicalRecordReporting: Acme_Patients_V1_MedicalRecordReportingService.Client<MeshTransport>
    let patientsPatientSync: Acme_Patients_V1_PatientSyncService.Client<MeshTransport>
    let prescriptionsPrescriptionSync: Acme_Prescriptions_V1_PrescriptionSyncService.Client<MeshTransport>
    let prescriptionsRefillSync: Acme_Prescriptions_V1_RefillSyncService.Client<MeshTransport>
    let telehealthVideoVisitWorkflow: Acme_Telehealth_V1_VideoVisitWorkflowService.Client<MeshTransport>
    let resumeAllergyWorkflowStep0:
        any RPCPort<Acme_Prescriptions_V1_PushRefillRequest, Acme_Prescriptions_V1_PushRefillResponse>
    let retryAllergyWorkflowStep1:
        @Sendable (Acme_Patients_V1_GenerateMedicalRecordReportRequest) async throws ->
            Acme_Patients_V1_GenerateMedicalRecordReportResponse
    let signalAllergyWorkflowStep0:
        [String:
            @Sendable (Acme_Prescriptions_V1_ReconcilePrescriptionsRequest) async throws ->
            Acme_Prescriptions_V1_ReconcilePrescriptionsResponse]

    init(
        dependencies: any Dependencies,
        auditAuditEventQuery: Acme_Audit_V1_AuditEventQueryService.Client<MeshTransport>,
        benefitsBenefitPlan: Acme_Benefits_V1_BenefitPlanService.Client<MeshTransport>,
        documentsDocumentValidation: Acme_Documents_V1_DocumentValidationService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        notificationsNotificationQuery: Acme_Notifications_V1_NotificationQueryService.Client<MeshTransport>,
        patientsAllergyApproval: Acme_Patients_V1_AllergyApprovalService.Client<MeshTransport>,
        patientsAllergyCalculation: Acme_Patients_V1_AllergyCalculationService.Client<MeshTransport>,
        patientsAllergyImport: Acme_Patients_V1_AllergyImportService.Client<MeshTransport>,
        patientsAllergyReporting: Acme_Patients_V1_AllergyReportingService.Client<MeshTransport>,
        patientsMedicalRecordReporting: Acme_Patients_V1_MedicalRecordReportingService.Client<MeshTransport>,
        patientsPatientSync: Acme_Patients_V1_PatientSyncService.Client<MeshTransport>,
        prescriptionsPrescriptionSync: Acme_Prescriptions_V1_PrescriptionSyncService.Client<MeshTransport>,
        prescriptionsRefillSync: Acme_Prescriptions_V1_RefillSyncService.Client<MeshTransport>,
        telehealthVideoVisitWorkflow: Acme_Telehealth_V1_VideoVisitWorkflowService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.auditAuditEventQuery = auditAuditEventQuery
        self.benefitsBenefitPlan = benefitsBenefitPlan
        self.documentsDocumentValidation = documentsDocumentValidation
        self.identityUser = identityUser
        self.notificationsNotificationQuery = notificationsNotificationQuery
        self.patientsAllergyApproval = patientsAllergyApproval
        self.patientsAllergyCalculation = patientsAllergyCalculation
        self.patientsAllergyImport = patientsAllergyImport
        self.patientsAllergyReporting = patientsAllergyReporting
        self.patientsMedicalRecordReporting = patientsMedicalRecordReporting
        self.patientsPatientSync = patientsPatientSync
        self.prescriptionsPrescriptionSync = prescriptionsPrescriptionSync
        self.prescriptionsRefillSync = prescriptionsRefillSync
        self.telehealthVideoVisitWorkflow = telehealthVideoVisitWorkflow
        self.resumeAllergyWorkflowStep0 = ClosurePort<
            Acme_Prescriptions_V1_PushRefillRequest, Acme_Prescriptions_V1_PushRefillResponse
        >({ request in try await prescriptionsRefillSync.pushRefill(request) })
        self.retryAllergyWorkflowStep1 = { request in
            try await patientsMedicalRecordReporting.generateMedicalRecordReport(request)
        }
        self.signalAllergyWorkflowStep0 = [
            "primary": { request in try await prescriptionsPrescriptionSync.reconcilePrescriptions(request) }
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
