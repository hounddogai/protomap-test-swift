import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Routes care goals through approval, with escalation and delegation.
final class CareGoalApprovalEndpoint: Acme_Careplans_V1_CareGoalApprovalService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>
    let careplansCareGoalLifecycle: Acme_Careplans_V1_CareGoalLifecycleService.Client<MeshTransport>
    let careplansCarePlanApproval: Acme_Careplans_V1_CarePlanApprovalService.Client<MeshTransport>
    let careplansVitalValidation: Acme_Careplans_V1_VitalValidationService.Client<MeshTransport>
    let featureflagsFeatureFlagValidation: Acme_Featureflags_V1_FeatureFlagValidationService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let notificationsNotificationQuery: Acme_Notifications_V1_NotificationQueryService.Client<MeshTransport>
    let patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>
    let patientsPatient: Acme_Patients_V1_PatientService.Client<MeshTransport>
    let prescriptionsMedicationCalculation: Acme_Prescriptions_V1_MedicationCalculationService.Client<MeshTransport>
    let promotionsPromotionCalculation: Acme_Promotions_V1_PromotionCalculationService.Client<MeshTransport>
    let telehealthTriageCalculation: Acme_Telehealth_V1_TriageCalculationService.Client<MeshTransport>
    let telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client<MeshTransport>
    let venuesVenue: Acme_Venues_V1_VenueService.Client<MeshTransport>
    let commentCareGoalApprovalStep1:
        any RPCPort<Acme_Careplans_V1_CheckVitalEligibilityRequest, Acme_Careplans_V1_CheckVitalEligibilityResponse>
    let delegateCareGoalApprovalStep1:
        @Sendable (Acme_Promotions_V1_RecalculatePromotionsRequest) async throws ->
            Acme_Promotions_V1_RecalculatePromotionsResponse
    let listPendingCareGoalsStep0:
        [String:
            @Sendable (Acme_Featureflags_V1_ScoreFeatureFlagRequest) async throws ->
            Acme_Featureflags_V1_ScoreFeatureFlagResponse]

    init(
        dependencies: any Dependencies,
        careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>,
        careplansCareGoalLifecycle: Acme_Careplans_V1_CareGoalLifecycleService.Client<MeshTransport>,
        careplansCarePlanApproval: Acme_Careplans_V1_CarePlanApprovalService.Client<MeshTransport>,
        careplansVitalValidation: Acme_Careplans_V1_VitalValidationService.Client<MeshTransport>,
        featureflagsFeatureFlagValidation: Acme_Featureflags_V1_FeatureFlagValidationService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        notificationsNotificationQuery: Acme_Notifications_V1_NotificationQueryService.Client<MeshTransport>,
        patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>,
        patientsPatient: Acme_Patients_V1_PatientService.Client<MeshTransport>,
        prescriptionsMedicationCalculation: Acme_Prescriptions_V1_MedicationCalculationService.Client<MeshTransport>,
        promotionsPromotionCalculation: Acme_Promotions_V1_PromotionCalculationService.Client<MeshTransport>,
        telehealthTriageCalculation: Acme_Telehealth_V1_TriageCalculationService.Client<MeshTransport>,
        telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client<MeshTransport>,
        venuesVenue: Acme_Venues_V1_VenueService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.careplansCareGoalCalculation = careplansCareGoalCalculation
        self.careplansCareGoalLifecycle = careplansCareGoalLifecycle
        self.careplansCarePlanApproval = careplansCarePlanApproval
        self.careplansVitalValidation = careplansVitalValidation
        self.featureflagsFeatureFlagValidation = featureflagsFeatureFlagValidation
        self.identityUser = identityUser
        self.notificationsNotificationQuery = notificationsNotificationQuery
        self.patientsMedicalRecordCalculation = patientsMedicalRecordCalculation
        self.patientsPatient = patientsPatient
        self.prescriptionsMedicationCalculation = prescriptionsMedicationCalculation
        self.promotionsPromotionCalculation = promotionsPromotionCalculation
        self.telehealthTriageCalculation = telehealthTriageCalculation
        self.telehealthVideoVisitCalculation = telehealthVideoVisitCalculation
        self.venuesVenue = venuesVenue
        self.commentCareGoalApprovalStep1 = ClosurePort<
            Acme_Careplans_V1_CheckVitalEligibilityRequest, Acme_Careplans_V1_CheckVitalEligibilityResponse
        >({ request in try await careplansVitalValidation.checkVitalEligibility(request) })
        self.delegateCareGoalApprovalStep1 = { request in
            try await promotionsPromotionCalculation.recalculatePromotions(request)
        }
        self.listPendingCareGoalsStep0 = [
            "primary": { request in try await featureflagsFeatureFlagValidation.scoreFeatureFlag(request) }
        ]
    }

    /// Approves a care goal.
    func approveCareGoal(
        request: ServerRequest<Acme_Careplans_V1_ApproveCareGoalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_ApproveCareGoalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processApproveCareGoal(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Comments a care goal.
    func commentCareGoalApproval(
        request: ServerRequest<Acme_Careplans_V1_CommentCareGoalApprovalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_CommentCareGoalApprovalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCommentCareGoalApproval(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Delegates a care goal.
    func delegateCareGoalApproval(
        request: ServerRequest<Acme_Careplans_V1_DelegateCareGoalApprovalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_DelegateCareGoalApprovalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processDelegateCareGoalApproval(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Escalates a care goal.
    func escalateCareGoal(
        request: ServerRequest<Acme_Careplans_V1_EscalateCareGoalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_EscalateCareGoalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processEscalateCareGoal(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists care goals a page at a time.
    func listPendingCareGoals(
        request: ServerRequest<Acme_Careplans_V1_ListPendingCareGoalsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_ListPendingCareGoalsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListPendingCareGoals(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Recalls a care goal.
    func recallCareGoal(
        request: ServerRequest<Acme_Careplans_V1_RecallCareGoalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_RecallCareGoalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRecallCareGoal(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Rejects a care goal.
    func rejectCareGoal(
        request: ServerRequest<Acme_Careplans_V1_RejectCareGoalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_RejectCareGoalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRejectCareGoal(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Submits a care goal.
    func submitCareGoal(
        request: ServerRequest<Acme_Careplans_V1_SubmitCareGoalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_SubmitCareGoalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSubmitCareGoal(request.message)
            return ServerResponse(message: response)
        }
    }
}
