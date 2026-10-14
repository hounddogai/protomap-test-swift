import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Moves a vital between the states of its lifecycle.
final class VitalLifecycleEndpoint: Acme_Careplans_V1_VitalLifecycleService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let followUps = WorkQueue<Acme_Identity_V1_GetUserRequest>()
    let appointmentsProviderQuery: Acme_Appointments_V1_ProviderQueryService.Client<MeshTransport>
    let auditAuditEventQuery: Acme_Audit_V1_AuditEventQueryService.Client<MeshTransport>
    let careplansCareGoalValidation: Acme_Careplans_V1_CareGoalValidationService.Client<MeshTransport>
    let careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>
    let careplansCarePlanQuery: Acme_Careplans_V1_CarePlanQueryService.Client<MeshTransport>
    let careplansVitalCalculation: Acme_Careplans_V1_VitalCalculationService.Client<MeshTransport>
    let careplansVitalReporting: Acme_Careplans_V1_VitalReportingService.Client<MeshTransport>
    let featureflagsFeatureFlagValidation: Acme_Featureflags_V1_FeatureFlagValidationService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let identityUserQuery: Acme_Identity_V1_UserQueryService.Client<MeshTransport>
    let ledgerLedgerAccount: Acme_Ledger_V1_LedgerAccountService.Client<MeshTransport>
    let ledgerLedgerAccountValidation: Acme_Ledger_V1_LedgerAccountValidationService.Client<MeshTransport>
    let notificationsNotificationQuery: Acme_Notifications_V1_NotificationQueryService.Client<MeshTransport>
    let patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client<MeshTransport>
    let prescriptionsMedicationCalculation: Acme_Prescriptions_V1_MedicationCalculationService.Client<MeshTransport>
    let prescriptionsRefillValidation: Acme_Prescriptions_V1_RefillValidationService.Client<MeshTransport>
    let surveysSurvey: Acme_Surveys_V1_SurveyService.Client<MeshTransport>
    let renewVitalStep0: any RPCPort<Acme_Careplans_V1_LintCareGoalsRequest, Acme_Careplans_V1_LintCareGoalsResponse>
    let scheduleVitalExpiryStep0:
        @Sendable (Acme_Careplans_V1_QuoteVitalRequest) async throws -> Acme_Careplans_V1_QuoteVitalResponse
    let scheduleVitalExpiryStep1:
        [String:
            @Sendable (Acme_Prescriptions_V1_CalculateMedicationRequest) async throws ->
            Acme_Prescriptions_V1_CalculateMedicationResponse]

    init(
        dependencies: any Dependencies,
        appointmentsProviderQuery: Acme_Appointments_V1_ProviderQueryService.Client<MeshTransport>,
        auditAuditEventQuery: Acme_Audit_V1_AuditEventQueryService.Client<MeshTransport>,
        careplansCareGoalValidation: Acme_Careplans_V1_CareGoalValidationService.Client<MeshTransport>,
        careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>,
        careplansCarePlanQuery: Acme_Careplans_V1_CarePlanQueryService.Client<MeshTransport>,
        careplansVitalCalculation: Acme_Careplans_V1_VitalCalculationService.Client<MeshTransport>,
        careplansVitalReporting: Acme_Careplans_V1_VitalReportingService.Client<MeshTransport>,
        featureflagsFeatureFlagValidation: Acme_Featureflags_V1_FeatureFlagValidationService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        identityUserQuery: Acme_Identity_V1_UserQueryService.Client<MeshTransport>,
        ledgerLedgerAccount: Acme_Ledger_V1_LedgerAccountService.Client<MeshTransport>,
        ledgerLedgerAccountValidation: Acme_Ledger_V1_LedgerAccountValidationService.Client<MeshTransport>,
        notificationsNotificationQuery: Acme_Notifications_V1_NotificationQueryService.Client<MeshTransport>,
        patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client<MeshTransport>,
        prescriptionsMedicationCalculation: Acme_Prescriptions_V1_MedicationCalculationService.Client<MeshTransport>,
        prescriptionsRefillValidation: Acme_Prescriptions_V1_RefillValidationService.Client<MeshTransport>,
        surveysSurvey: Acme_Surveys_V1_SurveyService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.appointmentsProviderQuery = appointmentsProviderQuery
        self.auditAuditEventQuery = auditAuditEventQuery
        self.careplansCareGoalValidation = careplansCareGoalValidation
        self.careplansCarePlan = careplansCarePlan
        self.careplansCarePlanQuery = careplansCarePlanQuery
        self.careplansVitalCalculation = careplansVitalCalculation
        self.careplansVitalReporting = careplansVitalReporting
        self.featureflagsFeatureFlagValidation = featureflagsFeatureFlagValidation
        self.identityUser = identityUser
        self.identityUserQuery = identityUserQuery
        self.ledgerLedgerAccount = ledgerLedgerAccount
        self.ledgerLedgerAccountValidation = ledgerLedgerAccountValidation
        self.notificationsNotificationQuery = notificationsNotificationQuery
        self.patientsPatientQuery = patientsPatientQuery
        self.prescriptionsMedicationCalculation = prescriptionsMedicationCalculation
        self.prescriptionsRefillValidation = prescriptionsRefillValidation
        self.surveysSurvey = surveysSurvey
        self.renewVitalStep0 = ClosurePort<
            Acme_Careplans_V1_LintCareGoalsRequest, Acme_Careplans_V1_LintCareGoalsResponse
        >({ request in try await careplansCareGoalValidation.lintCareGoals(request) })
        self.scheduleVitalExpiryStep0 = { request in try await careplansVitalCalculation.quoteVital(request) }
        self.scheduleVitalExpiryStep1 = [
            "primary": { request in try await prescriptionsMedicationCalculation.calculateMedication(request) }
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

    /// Activates a vital.
    func activateVital(
        request: ServerRequest<Acme_Careplans_V1_ActivateVitalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_ActivateVitalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processActivateVital(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Expires a vital.
    func expireVital(
        request: ServerRequest<Acme_Careplans_V1_ExpireVitalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_ExpireVitalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processExpireVital(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a vital.
    func getVitalLifecycle(
        request: ServerRequest<Acme_Careplans_V1_GetVitalLifecycleRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_GetVitalLifecycleResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetVitalLifecycle(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Reinstates a vital.
    func reinstateVital(
        request: ServerRequest<Acme_Careplans_V1_ReinstateVitalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_ReinstateVitalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processReinstateVital(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Renews a vital.
    func renewVital(
        request: ServerRequest<Acme_Careplans_V1_RenewVitalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_RenewVitalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRenewVital(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Schedules a vital.
    func scheduleVitalExpiry(
        request: ServerRequest<Acme_Careplans_V1_ScheduleVitalExpiryRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_ScheduleVitalExpiryResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processScheduleVitalExpiry(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Suspends a vital.
    func suspendVital(
        request: ServerRequest<Acme_Careplans_V1_SuspendVitalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_SuspendVitalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSuspendVital(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Terminates a vital.
    func terminateVital(
        request: ServerRequest<Acme_Careplans_V1_TerminateVitalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_TerminateVitalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processTerminateVital(request.message)
            return ServerResponse(message: response)
        }
    }
}
