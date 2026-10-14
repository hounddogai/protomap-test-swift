import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Manages patient homes: creates, reads, changes, and lists them.
final class PatientHomeEndpoint: Acme_Patientapp_V1_PatientHomeService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let appointmentsAppointmentWorkflow: Acme_Appointments_V1_AppointmentWorkflowService.Client<MeshTransport>
    let dispatchDispatchOrderQuery: Acme_Dispatch_V1_DispatchOrderQueryService.Client<MeshTransport>
    let fanportalFanSessionQuery: Acme_Fanportal_V1_FanSessionQueryService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let notificationsNotification: Acme_Notifications_V1_NotificationService.Client<MeshTransport>
    let notificationsNotificationQuery: Acme_Notifications_V1_NotificationQueryService.Client<MeshTransport>
    let notificationsNotificationValidation: Acme_Notifications_V1_NotificationValidationService.Client<MeshTransport>
    let patientappCareInboxIntegration: Acme_Patientapp_V1_CareInboxIntegrationService.Client<MeshTransport>
    let patientappCareInboxQuery: Acme_Patientapp_V1_CareInboxQueryService.Client<MeshTransport>
    let patientappPatientHomeQuery: Acme_Patientapp_V1_PatientHomeQueryService.Client<MeshTransport>
    let patientappPatientHomeWorkflow: Acme_Patientapp_V1_PatientHomeWorkflowService.Client<MeshTransport>
    let patientsPatientApproval: Acme_Patients_V1_PatientApprovalService.Client<MeshTransport>
    let patientsPatientWorkflow: Acme_Patients_V1_PatientWorkflowService.Client<MeshTransport>
    let prescriptionsMedicationSync: Acme_Prescriptions_V1_MedicationSyncService.Client<MeshTransport>
    let searchSearchIndexValidation: Acme_Search_V1_SearchIndexValidationService.Client<MeshTransport>
    let telehealthTriageWorkflow: Acme_Telehealth_V1_TriageWorkflowService.Client<MeshTransport>
    let updatePatientHomeStep3:
        any RPCPort<Acme_Patients_V1_RetryPatientWorkflowRequest, Acme_Patients_V1_RetryPatientWorkflowResponse>
    let watchPatientHomesStep2:
        @Sendable (Acme_Dispatch_V1_ResolveDispatchOrdersRequest) async throws ->
            Acme_Dispatch_V1_ResolveDispatchOrdersResponse
    let watchPatientHomesStep3:
        [String:
            @Sendable (Acme_Patientapp_V1_CountCareInboxesRequest) async throws ->
            Acme_Patientapp_V1_CountCareInboxesResponse]

    init(
        dependencies: any Dependencies,
        appointmentsAppointmentWorkflow: Acme_Appointments_V1_AppointmentWorkflowService.Client<MeshTransport>,
        dispatchDispatchOrderQuery: Acme_Dispatch_V1_DispatchOrderQueryService.Client<MeshTransport>,
        fanportalFanSessionQuery: Acme_Fanportal_V1_FanSessionQueryService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        notificationsNotification: Acme_Notifications_V1_NotificationService.Client<MeshTransport>,
        notificationsNotificationQuery: Acme_Notifications_V1_NotificationQueryService.Client<MeshTransport>,
        notificationsNotificationValidation: Acme_Notifications_V1_NotificationValidationService.Client<MeshTransport>,
        patientappCareInboxIntegration: Acme_Patientapp_V1_CareInboxIntegrationService.Client<MeshTransport>,
        patientappCareInboxQuery: Acme_Patientapp_V1_CareInboxQueryService.Client<MeshTransport>,
        patientappPatientHomeQuery: Acme_Patientapp_V1_PatientHomeQueryService.Client<MeshTransport>,
        patientappPatientHomeWorkflow: Acme_Patientapp_V1_PatientHomeWorkflowService.Client<MeshTransport>,
        patientsPatientApproval: Acme_Patients_V1_PatientApprovalService.Client<MeshTransport>,
        patientsPatientWorkflow: Acme_Patients_V1_PatientWorkflowService.Client<MeshTransport>,
        prescriptionsMedicationSync: Acme_Prescriptions_V1_MedicationSyncService.Client<MeshTransport>,
        searchSearchIndexValidation: Acme_Search_V1_SearchIndexValidationService.Client<MeshTransport>,
        telehealthTriageWorkflow: Acme_Telehealth_V1_TriageWorkflowService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.appointmentsAppointmentWorkflow = appointmentsAppointmentWorkflow
        self.dispatchDispatchOrderQuery = dispatchDispatchOrderQuery
        self.fanportalFanSessionQuery = fanportalFanSessionQuery
        self.identityUser = identityUser
        self.notificationsNotification = notificationsNotification
        self.notificationsNotificationQuery = notificationsNotificationQuery
        self.notificationsNotificationValidation = notificationsNotificationValidation
        self.patientappCareInboxIntegration = patientappCareInboxIntegration
        self.patientappCareInboxQuery = patientappCareInboxQuery
        self.patientappPatientHomeQuery = patientappPatientHomeQuery
        self.patientappPatientHomeWorkflow = patientappPatientHomeWorkflow
        self.patientsPatientApproval = patientsPatientApproval
        self.patientsPatientWorkflow = patientsPatientWorkflow
        self.prescriptionsMedicationSync = prescriptionsMedicationSync
        self.searchSearchIndexValidation = searchSearchIndexValidation
        self.telehealthTriageWorkflow = telehealthTriageWorkflow
        self.updatePatientHomeStep3 = ClosurePort<
            Acme_Patients_V1_RetryPatientWorkflowRequest, Acme_Patients_V1_RetryPatientWorkflowResponse
        >({ request in try await patientsPatientWorkflow.retryPatientWorkflow(request) })
        self.watchPatientHomesStep2 = { request in try await dispatchDispatchOrderQuery.resolveDispatchOrders(request) }
        self.watchPatientHomesStep3 = [
            "primary": { request in try await patientappCareInboxQuery.countCareInboxes(request) }
        ]
    }
}
