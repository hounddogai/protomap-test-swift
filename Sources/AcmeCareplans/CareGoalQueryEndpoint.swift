import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Answers read-only questions about care goals, for screens and reports.
final class CareGoalQueryEndpoint: Acme_Careplans_V1_CareGoalQueryService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let followUps = WorkQueue<Acme_Identity_V1_GetUserRequest>()
    let careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>
    let careplansCareGoalValidation: Acme_Careplans_V1_CareGoalValidationService.Client<MeshTransport>
    let careplansCarePlanQuery: Acme_Careplans_V1_CarePlanQueryService.Client<MeshTransport>
    let careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client<MeshTransport>
    let careplansVitalCalculation: Acme_Careplans_V1_VitalCalculationService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let summarizeCareGoalsStep0:
        any RPCPort<Acme_Careplans_V1_PreviewCarePlanRequest, Acme_Careplans_V1_PreviewCarePlanResponse>
    let summarizeCareGoalsStep2:
        @Sendable (Acme_Careplans_V1_NormalizeCareGoalRequest) async throws ->
            Acme_Careplans_V1_NormalizeCareGoalResponse

    init(
        dependencies: any Dependencies,
        careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>,
        careplansCareGoalValidation: Acme_Careplans_V1_CareGoalValidationService.Client<MeshTransport>,
        careplansCarePlanQuery: Acme_Careplans_V1_CarePlanQueryService.Client<MeshTransport>,
        careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client<MeshTransport>,
        careplansVitalCalculation: Acme_Careplans_V1_VitalCalculationService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.careplansCareGoalCalculation = careplansCareGoalCalculation
        self.careplansCareGoalValidation = careplansCareGoalValidation
        self.careplansCarePlanQuery = careplansCarePlanQuery
        self.careplansCarePlanValidation = careplansCarePlanValidation
        self.careplansVitalCalculation = careplansVitalCalculation
        self.identityUser = identityUser
        self.summarizeCareGoalsStep0 = ClosurePort<
            Acme_Careplans_V1_PreviewCarePlanRequest, Acme_Careplans_V1_PreviewCarePlanResponse
        >({ request in try await careplansCarePlanValidation.previewCarePlan(request) })
        self.summarizeCareGoalsStep2 = { request in try await careplansCareGoalValidation.normalizeCareGoal(request) }
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

    /// Lists care goals a page at a time.
    func browseCareGoals(
        request: ServerRequest<Acme_Careplans_V1_BrowseCareGoalsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_BrowseCareGoalsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processBrowseCareGoals(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Counts care goals by status.
    func countCareGoals(
        request: ServerRequest<Acme_Careplans_V1_CountCareGoalsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_CountCareGoalsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCountCareGoals(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Streams every matching care goal.
    func exportCareGoals(
        request: ServerRequest<Acme_Careplans_V1_ExportCareGoalsRequest>,
        context: ServerContext
    ) async throws -> StreamingServerResponse<Acme_Careplans_V1_ExportCareGoalsResponse> {
        return StreamingServerResponse { writer in
            try await CallerScope.$metadata.withValue(request.metadata) {
                let response = try await self.processExportCareGoals(request.message)
                try await writer.write(response)
                return [:]
            }
        }
    }

    /// Lists care goals a page at a time.
    func findCareGoals(
        request: ServerRequest<Acme_Careplans_V1_FindCareGoalsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_FindCareGoalsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processFindCareGoals(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a care goal.
    func lookupCareGoal(
        request: ServerRequest<Acme_Careplans_V1_LookupCareGoalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_LookupCareGoalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processLookupCareGoal(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a care goal.
    func peekCareGoal(
        request: ServerRequest<Acme_Careplans_V1_PeekCareGoalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_PeekCareGoalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processPeekCareGoal(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns several care goals at once.
    func resolveCareGoals(
        request: ServerRequest<Acme_Careplans_V1_ResolveCareGoalsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_ResolveCareGoalsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processResolveCareGoals(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists care goals a page at a time.
    func suggestCareGoals(
        request: ServerRequest<Acme_Careplans_V1_SuggestCareGoalsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_SuggestCareGoalsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSuggestCareGoals(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Summarizes a care goal.
    func summarizeCareGoals(
        request: ServerRequest<Acme_Careplans_V1_SummarizeCareGoalsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_SummarizeCareGoalsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSummarizeCareGoals(request.message)
            return ServerResponse(message: response)
        }
    }
}
