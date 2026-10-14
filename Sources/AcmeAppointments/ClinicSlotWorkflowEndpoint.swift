import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Runs the long-lived workflow that takes a clinic slot from start to finish.
final class ClinicSlotWorkflowEndpoint: Acme_Appointments_V1_ClinicSlotWorkflowService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let followUps = WorkQueue<Acme_Identity_V1_GetUserRequest>()
    let appointmentsAppointmentApproval: Acme_Appointments_V1_AppointmentApprovalService.Client<MeshTransport>
    let appointmentsAppointmentQuery: Acme_Appointments_V1_AppointmentQueryService.Client<MeshTransport>
    let appointmentsAppointmentValidation: Acme_Appointments_V1_AppointmentValidationService.Client<MeshTransport>
    let appointmentsAppointmentWorkflow: Acme_Appointments_V1_AppointmentWorkflowService.Client<MeshTransport>
    let appointmentsClinicSlotValidation: Acme_Appointments_V1_ClinicSlotValidationService.Client<MeshTransport>
    let appointmentsProviderWorkflow: Acme_Appointments_V1_ProviderWorkflowService.Client<MeshTransport>
    let authorizationAccessPolicyQuery: Acme_Authorization_V1_AccessPolicyQueryService.Client<MeshTransport>
    let authorizationAccessPolicyValidation: Acme_Authorization_V1_AccessPolicyValidationService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let notificationsNotificationQuery: Acme_Notifications_V1_NotificationQueryService.Client<MeshTransport>
    let prescriptionsMedicationReporting: Acme_Prescriptions_V1_MedicationReportingService.Client<MeshTransport>
    let prescriptionsMedicationWorkflow: Acme_Prescriptions_V1_MedicationWorkflowService.Client<MeshTransport>
    let prescriptionsRefillSync: Acme_Prescriptions_V1_RefillSyncService.Client<MeshTransport>
    let promotionsPromotionCalculation: Acme_Promotions_V1_PromotionCalculationService.Client<MeshTransport>
    let searchSearchIndexValidation: Acme_Search_V1_SearchIndexValidationService.Client<MeshTransport>
    let telehealthVideoVisitWorkflow: Acme_Telehealth_V1_VideoVisitWorkflowService.Client<MeshTransport>
    let venuesVenue: Acme_Venues_V1_VenueService.Client<MeshTransport>
    let venuesVenueValidation: Acme_Venues_V1_VenueValidationService.Client<MeshTransport>
    let startClinicSlotWorkflowStep3:
        any RPCPort<Acme_Appointments_V1_ApproveAppointmentRequest, Acme_Appointments_V1_ApproveAppointmentResponse>

    init(
        dependencies: any Dependencies,
        appointmentsAppointmentApproval: Acme_Appointments_V1_AppointmentApprovalService.Client<MeshTransport>,
        appointmentsAppointmentQuery: Acme_Appointments_V1_AppointmentQueryService.Client<MeshTransport>,
        appointmentsAppointmentValidation: Acme_Appointments_V1_AppointmentValidationService.Client<MeshTransport>,
        appointmentsAppointmentWorkflow: Acme_Appointments_V1_AppointmentWorkflowService.Client<MeshTransport>,
        appointmentsClinicSlotValidation: Acme_Appointments_V1_ClinicSlotValidationService.Client<MeshTransport>,
        appointmentsProviderWorkflow: Acme_Appointments_V1_ProviderWorkflowService.Client<MeshTransport>,
        authorizationAccessPolicyQuery: Acme_Authorization_V1_AccessPolicyQueryService.Client<MeshTransport>,
        authorizationAccessPolicyValidation: Acme_Authorization_V1_AccessPolicyValidationService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        notificationsNotificationQuery: Acme_Notifications_V1_NotificationQueryService.Client<MeshTransport>,
        prescriptionsMedicationReporting: Acme_Prescriptions_V1_MedicationReportingService.Client<MeshTransport>,
        prescriptionsMedicationWorkflow: Acme_Prescriptions_V1_MedicationWorkflowService.Client<MeshTransport>,
        prescriptionsRefillSync: Acme_Prescriptions_V1_RefillSyncService.Client<MeshTransport>,
        promotionsPromotionCalculation: Acme_Promotions_V1_PromotionCalculationService.Client<MeshTransport>,
        searchSearchIndexValidation: Acme_Search_V1_SearchIndexValidationService.Client<MeshTransport>,
        telehealthVideoVisitWorkflow: Acme_Telehealth_V1_VideoVisitWorkflowService.Client<MeshTransport>,
        venuesVenue: Acme_Venues_V1_VenueService.Client<MeshTransport>,
        venuesVenueValidation: Acme_Venues_V1_VenueValidationService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.appointmentsAppointmentApproval = appointmentsAppointmentApproval
        self.appointmentsAppointmentQuery = appointmentsAppointmentQuery
        self.appointmentsAppointmentValidation = appointmentsAppointmentValidation
        self.appointmentsAppointmentWorkflow = appointmentsAppointmentWorkflow
        self.appointmentsClinicSlotValidation = appointmentsClinicSlotValidation
        self.appointmentsProviderWorkflow = appointmentsProviderWorkflow
        self.authorizationAccessPolicyQuery = authorizationAccessPolicyQuery
        self.authorizationAccessPolicyValidation = authorizationAccessPolicyValidation
        self.identityUser = identityUser
        self.notificationsNotificationQuery = notificationsNotificationQuery
        self.prescriptionsMedicationReporting = prescriptionsMedicationReporting
        self.prescriptionsMedicationWorkflow = prescriptionsMedicationWorkflow
        self.prescriptionsRefillSync = prescriptionsRefillSync
        self.promotionsPromotionCalculation = promotionsPromotionCalculation
        self.searchSearchIndexValidation = searchSearchIndexValidation
        self.telehealthVideoVisitWorkflow = telehealthVideoVisitWorkflow
        self.venuesVenue = venuesVenue
        self.venuesVenueValidation = venuesVenueValidation
        self.startClinicSlotWorkflowStep3 = ClosurePort<
            Acme_Appointments_V1_ApproveAppointmentRequest, Acme_Appointments_V1_ApproveAppointmentResponse
        >({ request in try await appointmentsAppointmentApproval.approveAppointment(request) })
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
