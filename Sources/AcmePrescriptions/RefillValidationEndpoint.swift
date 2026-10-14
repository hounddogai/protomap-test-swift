import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Checks refills against the rules before anything acts on them.
final class RefillValidationEndpoint: Acme_Prescriptions_V1_RefillValidationService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let authorizationAccessPolicyQuery: Acme_Authorization_V1_AccessPolicyQueryService.Client<MeshTransport>
    let careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let metricsMetricSeriesQuery: Acme_Metrics_V1_MetricSeriesQueryService.Client<MeshTransport>
    let metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client<MeshTransport>
    let notificationsNotificationValidation: Acme_Notifications_V1_NotificationValidationService.Client<MeshTransport>
    let prescriptionsMedicationValidation: Acme_Prescriptions_V1_MedicationValidationService.Client<MeshTransport>
    let prescriptionsPrescriptionCalculation: Acme_Prescriptions_V1_PrescriptionCalculationService.Client<MeshTransport>
    let prescriptionsRefillCalculation: Acme_Prescriptions_V1_RefillCalculationService.Client<MeshTransport>
    let searchSearchIndexQuery: Acme_Search_V1_SearchIndexQueryService.Client<MeshTransport>
    let telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client<MeshTransport>
    let venuesVenueValidation: Acme_Venues_V1_VenueValidationService.Client<MeshTransport>

    init(
        dependencies: any Dependencies,
        authorizationAccessPolicyQuery: Acme_Authorization_V1_AccessPolicyQueryService.Client<MeshTransport>,
        careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        metricsMetricSeriesQuery: Acme_Metrics_V1_MetricSeriesQueryService.Client<MeshTransport>,
        metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client<MeshTransport>,
        notificationsNotificationValidation: Acme_Notifications_V1_NotificationValidationService.Client<MeshTransport>,
        prescriptionsMedicationValidation: Acme_Prescriptions_V1_MedicationValidationService.Client<MeshTransport>,
        prescriptionsPrescriptionCalculation: Acme_Prescriptions_V1_PrescriptionCalculationService.Client<
            MeshTransport
        >,
        prescriptionsRefillCalculation: Acme_Prescriptions_V1_RefillCalculationService.Client<MeshTransport>,
        searchSearchIndexQuery: Acme_Search_V1_SearchIndexQueryService.Client<MeshTransport>,
        telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client<MeshTransport>,
        venuesVenueValidation: Acme_Venues_V1_VenueValidationService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.authorizationAccessPolicyQuery = authorizationAccessPolicyQuery
        self.careplansCarePlanValidation = careplansCarePlanValidation
        self.identityUser = identityUser
        self.metricsMetricSeriesQuery = metricsMetricSeriesQuery
        self.metricsMetricSeriesValidation = metricsMetricSeriesValidation
        self.notificationsNotificationValidation = notificationsNotificationValidation
        self.prescriptionsMedicationValidation = prescriptionsMedicationValidation
        self.prescriptionsPrescriptionCalculation = prescriptionsPrescriptionCalculation
        self.prescriptionsRefillCalculation = prescriptionsRefillCalculation
        self.searchSearchIndexQuery = searchSearchIndexQuery
        self.telehealthVideoVisit = telehealthVideoVisit
        self.venuesVenueValidation = venuesVenueValidation
    }

    /// Checks a refill.
    func checkRefillEligibility(
        request: ServerRequest<Acme_Prescriptions_V1_CheckRefillEligibilityRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_CheckRefillEligibilityResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCheckRefillEligibility(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Explains a refill.
    func explainRefillDecision(
        request: ServerRequest<Acme_Prescriptions_V1_ExplainRefillDecisionRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ExplainRefillDecisionResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processExplainRefillDecision(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a refill.
    func getRefillRules(
        request: ServerRequest<Acme_Prescriptions_V1_GetRefillRulesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_GetRefillRulesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetRefillRules(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lints a refill.
    func lintRefills(
        request: ServerRequest<Acme_Prescriptions_V1_LintRefillsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_LintRefillsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processLintRefills(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Normalizes a refill.
    func normalizeRefill(
        request: ServerRequest<Acme_Prescriptions_V1_NormalizeRefillRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_NormalizeRefillResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processNormalizeRefill(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Previews a refill.
    func previewRefill(
        request: ServerRequest<Acme_Prescriptions_V1_PreviewRefillRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_PreviewRefillResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processPreviewRefill(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Scores a refill.
    func scoreRefill(
        request: ServerRequest<Acme_Prescriptions_V1_ScoreRefillRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ScoreRefillResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processScoreRefill(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Validates a refill.
    func validateRefill(
        request: ServerRequest<Acme_Prescriptions_V1_ValidateRefillRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ValidateRefillResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processValidateRefill(request.message)
            return ServerResponse(message: response)
        }
    }
}
