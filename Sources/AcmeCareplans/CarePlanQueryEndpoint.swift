import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Answers read-only questions about care plans, for screens and reports.
final class CarePlanQueryEndpoint: Acme_Careplans_V1_CarePlanQueryService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let followUps = WorkQueue<Acme_Identity_V1_GetUserRequest>()
    let careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>
    let careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client<MeshTransport>
    let careplansVitalCalculation: Acme_Careplans_V1_VitalCalculationService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let identityUserValidation: Acme_Identity_V1_UserValidationService.Client<MeshTransport>
    let notificationsNotification: Acme_Notifications_V1_NotificationService.Client<MeshTransport>
    let searchSearchIndexValidation: Acme_Search_V1_SearchIndexValidationService.Client<MeshTransport>
    let venuesVenueValidation: Acme_Venues_V1_VenueValidationService.Client<MeshTransport>
    let browseCarePlansStep0:
        any RPCPort<
            Acme_Careplans_V1_CheckCarePlanEligibilityRequest, Acme_Careplans_V1_CheckCarePlanEligibilityResponse
        >
    let exportCarePlansStep0:
        @Sendable (Acme_Careplans_V1_RecalculateCareGoalsRequest) async throws ->
            Acme_Careplans_V1_RecalculateCareGoalsResponse
    let exportCarePlansStep1:
        [String:
            @Sendable (Acme_Careplans_V1_ExplainCareGoalCalculationRequest) async throws ->
            Acme_Careplans_V1_ExplainCareGoalCalculationResponse]

    init(
        dependencies: any Dependencies,
        careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>,
        careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client<MeshTransport>,
        careplansVitalCalculation: Acme_Careplans_V1_VitalCalculationService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        identityUserValidation: Acme_Identity_V1_UserValidationService.Client<MeshTransport>,
        notificationsNotification: Acme_Notifications_V1_NotificationService.Client<MeshTransport>,
        searchSearchIndexValidation: Acme_Search_V1_SearchIndexValidationService.Client<MeshTransport>,
        venuesVenueValidation: Acme_Venues_V1_VenueValidationService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.careplansCareGoalCalculation = careplansCareGoalCalculation
        self.careplansCarePlanValidation = careplansCarePlanValidation
        self.careplansVitalCalculation = careplansVitalCalculation
        self.identityUser = identityUser
        self.identityUserValidation = identityUserValidation
        self.notificationsNotification = notificationsNotification
        self.searchSearchIndexValidation = searchSearchIndexValidation
        self.venuesVenueValidation = venuesVenueValidation
        self.browseCarePlansStep0 = ClosurePort<
            Acme_Careplans_V1_CheckCarePlanEligibilityRequest, Acme_Careplans_V1_CheckCarePlanEligibilityResponse
        >({ request in try await careplansCarePlanValidation.checkCarePlanEligibility(request) })
        self.exportCarePlansStep0 = { request in try await careplansCareGoalCalculation.recalculateCareGoals(request) }
        self.exportCarePlansStep1 = [
            "primary": { request in try await careplansCareGoalCalculation.explainCareGoalCalculation(request) }
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

    /// Lists care plans a page at a time.
    func browseCarePlans(
        request: ServerRequest<Acme_Careplans_V1_BrowseCarePlansRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_BrowseCarePlansResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processBrowseCarePlans(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Counts care plans by status.
    func countCarePlans(
        request: ServerRequest<Acme_Careplans_V1_CountCarePlansRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_CountCarePlansResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCountCarePlans(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Streams every matching care plan.
    func exportCarePlans(
        request: ServerRequest<Acme_Careplans_V1_ExportCarePlansRequest>,
        context: ServerContext
    ) async throws -> StreamingServerResponse<Acme_Careplans_V1_ExportCarePlansResponse> {
        return StreamingServerResponse { writer in
            try await CallerScope.$metadata.withValue(request.metadata) {
                let response = try await self.processExportCarePlans(request.message)
                try await writer.write(response)
                return [:]
            }
        }
    }

    /// Lists care plans a page at a time.
    func findCarePlans(
        request: ServerRequest<Acme_Careplans_V1_FindCarePlansRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_FindCarePlansResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processFindCarePlans(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a care plan.
    func lookupCarePlan(
        request: ServerRequest<Acme_Careplans_V1_LookupCarePlanRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_LookupCarePlanResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processLookupCarePlan(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a care plan.
    func peekCarePlan(
        request: ServerRequest<Acme_Careplans_V1_PeekCarePlanRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_PeekCarePlanResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processPeekCarePlan(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns several care plans at once.
    func resolveCarePlans(
        request: ServerRequest<Acme_Careplans_V1_ResolveCarePlansRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_ResolveCarePlansResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processResolveCarePlans(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists care plans a page at a time.
    func suggestCarePlans(
        request: ServerRequest<Acme_Careplans_V1_SuggestCarePlansRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_SuggestCarePlansResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSuggestCarePlans(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Summarizes a care plan.
    func summarizeCarePlans(
        request: ServerRequest<Acme_Careplans_V1_SummarizeCarePlansRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_SummarizeCarePlansResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSummarizeCarePlans(request.message)
            return ServerResponse(message: response)
        }
    }
}
