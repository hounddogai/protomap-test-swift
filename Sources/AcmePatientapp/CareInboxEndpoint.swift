import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Manages care inboxes: creates, reads, changes, and lists them.
final class CareInboxEndpoint: Acme_Patientapp_V1_CareInboxService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let careplansCarePlanWorkflow: Acme_Careplans_V1_CarePlanWorkflowService.Client<MeshTransport>
    let concessionsConcessionStand: Acme_Concessions_V1_ConcessionStandService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client<MeshTransport>
    let patientappCareInboxIntegration: Acme_Patientapp_V1_CareInboxIntegrationService.Client<MeshTransport>
    let patientappCareInboxNotification: Acme_Patientapp_V1_CareInboxNotificationService.Client<MeshTransport>
    let patientappCareInboxWorkflow: Acme_Patientapp_V1_CareInboxWorkflowService.Client<MeshTransport>
    let patientappPatientHomeQuery: Acme_Patientapp_V1_PatientHomeQueryService.Client<MeshTransport>
    let patientappPatientHomeWorkflow: Acme_Patientapp_V1_PatientHomeWorkflowService.Client<MeshTransport>
    let patientsAllergyApproval: Acme_Patients_V1_AllergyApprovalService.Client<MeshTransport>
    let patientsPatientSync: Acme_Patients_V1_PatientSyncService.Client<MeshTransport>
    let prescriptionsPrescriptionSync: Acme_Prescriptions_V1_PrescriptionSyncService.Client<MeshTransport>
    let telehealthTriageApproval: Acme_Telehealth_V1_TriageApprovalService.Client<MeshTransport>
    let telehealthVisitNoteWorkflow: Acme_Telehealth_V1_VisitNoteWorkflowService.Client<MeshTransport>
    let updateCareInboxStep0:
        any RPCPort<
            Acme_Prescriptions_V1_ReconcilePrescriptionsRequest, Acme_Prescriptions_V1_ReconcilePrescriptionsResponse
        >
    let updateCareInboxStep2:
        @Sendable (Acme_Patientapp_V1_AdvancePatientHomeWorkflowRequest) async throws ->
            Acme_Patientapp_V1_AdvancePatientHomeWorkflowResponse
    let updateCareInboxStep3:
        [String:
            @Sendable (Acme_Patientapp_V1_SendCareInboxTestNoticeRequest) async throws ->
            Acme_Patientapp_V1_SendCareInboxTestNoticeResponse]

    init(
        dependencies: any Dependencies,
        careplansCarePlanWorkflow: Acme_Careplans_V1_CarePlanWorkflowService.Client<MeshTransport>,
        concessionsConcessionStand: Acme_Concessions_V1_ConcessionStandService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client<MeshTransport>,
        patientappCareInboxIntegration: Acme_Patientapp_V1_CareInboxIntegrationService.Client<MeshTransport>,
        patientappCareInboxNotification: Acme_Patientapp_V1_CareInboxNotificationService.Client<MeshTransport>,
        patientappCareInboxWorkflow: Acme_Patientapp_V1_CareInboxWorkflowService.Client<MeshTransport>,
        patientappPatientHomeQuery: Acme_Patientapp_V1_PatientHomeQueryService.Client<MeshTransport>,
        patientappPatientHomeWorkflow: Acme_Patientapp_V1_PatientHomeWorkflowService.Client<MeshTransport>,
        patientsAllergyApproval: Acme_Patients_V1_AllergyApprovalService.Client<MeshTransport>,
        patientsPatientSync: Acme_Patients_V1_PatientSyncService.Client<MeshTransport>,
        prescriptionsPrescriptionSync: Acme_Prescriptions_V1_PrescriptionSyncService.Client<MeshTransport>,
        telehealthTriageApproval: Acme_Telehealth_V1_TriageApprovalService.Client<MeshTransport>,
        telehealthVisitNoteWorkflow: Acme_Telehealth_V1_VisitNoteWorkflowService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.careplansCarePlanWorkflow = careplansCarePlanWorkflow
        self.concessionsConcessionStand = concessionsConcessionStand
        self.identityUser = identityUser
        self.metricsMetricSeriesValidation = metricsMetricSeriesValidation
        self.patientappCareInboxIntegration = patientappCareInboxIntegration
        self.patientappCareInboxNotification = patientappCareInboxNotification
        self.patientappCareInboxWorkflow = patientappCareInboxWorkflow
        self.patientappPatientHomeQuery = patientappPatientHomeQuery
        self.patientappPatientHomeWorkflow = patientappPatientHomeWorkflow
        self.patientsAllergyApproval = patientsAllergyApproval
        self.patientsPatientSync = patientsPatientSync
        self.prescriptionsPrescriptionSync = prescriptionsPrescriptionSync
        self.telehealthTriageApproval = telehealthTriageApproval
        self.telehealthVisitNoteWorkflow = telehealthVisitNoteWorkflow
        self.updateCareInboxStep0 = ClosurePort<
            Acme_Prescriptions_V1_ReconcilePrescriptionsRequest, Acme_Prescriptions_V1_ReconcilePrescriptionsResponse
        >({ request in try await prescriptionsPrescriptionSync.reconcilePrescriptions(request) })
        self.updateCareInboxStep2 = { request in
            try await patientappPatientHomeWorkflow.advancePatientHomeWorkflow(request)
        }
        self.updateCareInboxStep3 = [
            "primary": { request in try await patientappCareInboxNotification.sendCareInboxTestNotice(request) }
        ]
    }
}
