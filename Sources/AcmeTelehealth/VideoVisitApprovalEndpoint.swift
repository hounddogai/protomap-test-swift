import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Routes video visits through approval, with escalation and delegation.
final class VideoVisitApprovalEndpoint: Acme_Telehealth_V1_VideoVisitApprovalService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let followUps = WorkQueue<Acme_Identity_V1_GetUserRequest>()
    let careplansCarePlanApproval: Acme_Careplans_V1_CarePlanApprovalService.Client<MeshTransport>
    let careplansVitalReporting: Acme_Careplans_V1_VitalReportingService.Client<MeshTransport>
    let featureflagsFeatureFlagValidation: Acme_Featureflags_V1_FeatureFlagValidationService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let notificationsNotificationValidation: Acme_Notifications_V1_NotificationValidationService.Client<MeshTransport>
    let patientsAllergyCalculation: Acme_Patients_V1_AllergyCalculationService.Client<MeshTransport>
    let patientsPatientValidation: Acme_Patients_V1_PatientValidationService.Client<MeshTransport>
    let prescriptionsPrescription: Acme_Prescriptions_V1_PrescriptionService.Client<MeshTransport>
    let ratelimitingRateLimitCalculation: Acme_Ratelimiting_V1_RateLimitCalculationService.Client<MeshTransport>
    let telehealthTriageCalculation: Acme_Telehealth_V1_TriageCalculationService.Client<MeshTransport>
    let telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client<MeshTransport>
    let telehealthVisitNoteQuery: Acme_Telehealth_V1_VisitNoteQueryService.Client<MeshTransport>
    let telehealthVisitNoteValidation: Acme_Telehealth_V1_VisitNoteValidationService.Client<MeshTransport>
    let venuesVenueQuery: Acme_Venues_V1_VenueQueryService.Client<MeshTransport>
    let rejectVideoVisitStep2:
        any RPCPort<Acme_Careplans_V1_ShareVitalReportRequest, Acme_Careplans_V1_ShareVitalReportResponse>
    let submitVideoVisitStep1:
        @Sendable (Acme_Notifications_V1_CheckNotificationEligibilityRequest) async throws ->
            Acme_Notifications_V1_CheckNotificationEligibilityResponse

    init(
        dependencies: any Dependencies,
        careplansCarePlanApproval: Acme_Careplans_V1_CarePlanApprovalService.Client<MeshTransport>,
        careplansVitalReporting: Acme_Careplans_V1_VitalReportingService.Client<MeshTransport>,
        featureflagsFeatureFlagValidation: Acme_Featureflags_V1_FeatureFlagValidationService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        notificationsNotificationValidation: Acme_Notifications_V1_NotificationValidationService.Client<MeshTransport>,
        patientsAllergyCalculation: Acme_Patients_V1_AllergyCalculationService.Client<MeshTransport>,
        patientsPatientValidation: Acme_Patients_V1_PatientValidationService.Client<MeshTransport>,
        prescriptionsPrescription: Acme_Prescriptions_V1_PrescriptionService.Client<MeshTransport>,
        ratelimitingRateLimitCalculation: Acme_Ratelimiting_V1_RateLimitCalculationService.Client<MeshTransport>,
        telehealthTriageCalculation: Acme_Telehealth_V1_TriageCalculationService.Client<MeshTransport>,
        telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client<MeshTransport>,
        telehealthVisitNoteQuery: Acme_Telehealth_V1_VisitNoteQueryService.Client<MeshTransport>,
        telehealthVisitNoteValidation: Acme_Telehealth_V1_VisitNoteValidationService.Client<MeshTransport>,
        venuesVenueQuery: Acme_Venues_V1_VenueQueryService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.careplansCarePlanApproval = careplansCarePlanApproval
        self.careplansVitalReporting = careplansVitalReporting
        self.featureflagsFeatureFlagValidation = featureflagsFeatureFlagValidation
        self.identityUser = identityUser
        self.notificationsNotificationValidation = notificationsNotificationValidation
        self.patientsAllergyCalculation = patientsAllergyCalculation
        self.patientsPatientValidation = patientsPatientValidation
        self.prescriptionsPrescription = prescriptionsPrescription
        self.ratelimitingRateLimitCalculation = ratelimitingRateLimitCalculation
        self.telehealthTriageCalculation = telehealthTriageCalculation
        self.telehealthVideoVisitCalculation = telehealthVideoVisitCalculation
        self.telehealthVisitNoteQuery = telehealthVisitNoteQuery
        self.telehealthVisitNoteValidation = telehealthVisitNoteValidation
        self.venuesVenueQuery = venuesVenueQuery
        self.rejectVideoVisitStep2 = ClosurePort<
            Acme_Careplans_V1_ShareVitalReportRequest, Acme_Careplans_V1_ShareVitalReportResponse
        >({ request in try await careplansVitalReporting.shareVitalReport(request) })
        self.submitVideoVisitStep1 = { request in
            try await notificationsNotificationValidation.checkNotificationEligibility(request)
        }
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
