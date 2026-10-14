import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Computes the figures of a triage, such as totals, taxes, and estimates.
final class TriageCalculationEndpoint: Acme_Telehealth_V1_TriageCalculationService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let followUps = WorkQueue<Acme_Identity_V1_GetUserRequest>()
    let careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>
    let careplansCareGoalQuery: Acme_Careplans_V1_CareGoalQueryService.Client<MeshTransport>
    let careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>
    let careplansCarePlanCalculation: Acme_Careplans_V1_CarePlanCalculationService.Client<MeshTransport>
    let careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client<MeshTransport>
    let careplansVitalValidation: Acme_Careplans_V1_VitalValidationService.Client<MeshTransport>
    let featureflagsFeatureFlagValidation: Acme_Featureflags_V1_FeatureFlagValidationService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let metricsMetricSeries: Acme_Metrics_V1_MetricSeriesService.Client<MeshTransport>
    let telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client<MeshTransport>
    let telehealthVideoVisitValidation: Acme_Telehealth_V1_VideoVisitValidationService.Client<MeshTransport>
    let telehealthVisitNoteCalculation: Acme_Telehealth_V1_VisitNoteCalculationService.Client<MeshTransport>

    init(
        dependencies: any Dependencies,
        careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>,
        careplansCareGoalQuery: Acme_Careplans_V1_CareGoalQueryService.Client<MeshTransport>,
        careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>,
        careplansCarePlanCalculation: Acme_Careplans_V1_CarePlanCalculationService.Client<MeshTransport>,
        careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client<MeshTransport>,
        careplansVitalValidation: Acme_Careplans_V1_VitalValidationService.Client<MeshTransport>,
        featureflagsFeatureFlagValidation: Acme_Featureflags_V1_FeatureFlagValidationService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        metricsMetricSeries: Acme_Metrics_V1_MetricSeriesService.Client<MeshTransport>,
        telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client<MeshTransport>,
        telehealthVideoVisitValidation: Acme_Telehealth_V1_VideoVisitValidationService.Client<MeshTransport>,
        telehealthVisitNoteCalculation: Acme_Telehealth_V1_VisitNoteCalculationService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.careplansCareGoalCalculation = careplansCareGoalCalculation
        self.careplansCareGoalQuery = careplansCareGoalQuery
        self.careplansCarePlan = careplansCarePlan
        self.careplansCarePlanCalculation = careplansCarePlanCalculation
        self.careplansCarePlanValidation = careplansCarePlanValidation
        self.careplansVitalValidation = careplansVitalValidation
        self.featureflagsFeatureFlagValidation = featureflagsFeatureFlagValidation
        self.identityUser = identityUser
        self.metricsMetricSeries = metricsMetricSeries
        self.telehealthVideoVisitCalculation = telehealthVideoVisitCalculation
        self.telehealthVideoVisitValidation = telehealthVideoVisitValidation
        self.telehealthVisitNoteCalculation = telehealthVisitNoteCalculation
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

    /// Calculates a triage.
    func calculateTriage(
        request: ServerRequest<Acme_Telehealth_V1_CalculateTriageRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_CalculateTriageResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCalculateTriage(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Compares a triage.
    func compareTriageOptions(
        request: ServerRequest<Acme_Telehealth_V1_CompareTriageOptionsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_CompareTriageOptionsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCompareTriageOptions(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Estimates a triage.
    func estimateTriage(
        request: ServerRequest<Acme_Telehealth_V1_EstimateTriageRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_EstimateTriageResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processEstimateTriage(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Explains a triage.
    func explainTriageCalculation(
        request: ServerRequest<Acme_Telehealth_V1_ExplainTriageCalculationRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_ExplainTriageCalculationResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processExplainTriageCalculation(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a triage.
    func getTriageRates(
        request: ServerRequest<Acme_Telehealth_V1_GetTriageRatesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_GetTriageRatesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetTriageRates(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Quotes a triage.
    func quoteTriage(
        request: ServerRequest<Acme_Telehealth_V1_QuoteTriageRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_QuoteTriageResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processQuoteTriage(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Recalculates a triage.
    func recalculateTriages(
        request: ServerRequest<Acme_Telehealth_V1_RecalculateTriagesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_RecalculateTriagesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRecalculateTriages(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Simulates a triage.
    func simulateTriage(
        request: ServerRequest<Acme_Telehealth_V1_SimulateTriageRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_SimulateTriageResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSimulateTriage(request.message)
            return ServerResponse(message: response)
        }
    }
}
