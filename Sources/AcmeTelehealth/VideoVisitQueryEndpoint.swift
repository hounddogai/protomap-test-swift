import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Answers read-only questions about video visits, for screens and reports.
final class VideoVisitQueryEndpoint: Acme_Telehealth_V1_VideoVisitQueryService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let followUps = WorkQueue<Acme_Identity_V1_GetUserRequest>()
    let careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>
    let careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client<MeshTransport>
    let documentsDocumentQuery: Acme_Documents_V1_DocumentQueryService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let metricsMetricSeriesQuery: Acme_Metrics_V1_MetricSeriesQueryService.Client<MeshTransport>
    let metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client<MeshTransport>
    let telehealthTriageCalculation: Acme_Telehealth_V1_TriageCalculationService.Client<MeshTransport>
    let telehealthVisitNoteCalculation: Acme_Telehealth_V1_VisitNoteCalculationService.Client<MeshTransport>
    let suggestVideoVisitsStep0:
        any RPCPort<Acme_Careplans_V1_ScoreCarePlanRequest, Acme_Careplans_V1_ScoreCarePlanResponse>

    init(
        dependencies: any Dependencies,
        careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>,
        careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client<MeshTransport>,
        documentsDocumentQuery: Acme_Documents_V1_DocumentQueryService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        metricsMetricSeriesQuery: Acme_Metrics_V1_MetricSeriesQueryService.Client<MeshTransport>,
        metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client<MeshTransport>,
        telehealthTriageCalculation: Acme_Telehealth_V1_TriageCalculationService.Client<MeshTransport>,
        telehealthVisitNoteCalculation: Acme_Telehealth_V1_VisitNoteCalculationService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.careplansCarePlan = careplansCarePlan
        self.careplansCarePlanValidation = careplansCarePlanValidation
        self.documentsDocumentQuery = documentsDocumentQuery
        self.identityUser = identityUser
        self.metricsMetricSeriesQuery = metricsMetricSeriesQuery
        self.metricsMetricSeriesValidation = metricsMetricSeriesValidation
        self.telehealthTriageCalculation = telehealthTriageCalculation
        self.telehealthVisitNoteCalculation = telehealthVisitNoteCalculation
        self.suggestVideoVisitsStep0 = ClosurePort<
            Acme_Careplans_V1_ScoreCarePlanRequest, Acme_Careplans_V1_ScoreCarePlanResponse
        >({ request in try await careplansCarePlanValidation.scoreCarePlan(request) })
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

    /// Lists video visits a page at a time.
    func browseVideoVisits(
        request: ServerRequest<Acme_Telehealth_V1_BrowseVideoVisitsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_BrowseVideoVisitsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processBrowseVideoVisits(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Counts video visits by status.
    func countVideoVisits(
        request: ServerRequest<Acme_Telehealth_V1_CountVideoVisitsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_CountVideoVisitsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCountVideoVisits(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Streams every matching video visit.
    func exportVideoVisits(
        request: ServerRequest<Acme_Telehealth_V1_ExportVideoVisitsRequest>,
        context: ServerContext
    ) async throws -> StreamingServerResponse<Acme_Telehealth_V1_ExportVideoVisitsResponse> {
        return StreamingServerResponse { writer in
            try await CallerScope.$metadata.withValue(request.metadata) {
                let response = try await self.processExportVideoVisits(request.message)
                try await writer.write(response)
                return [:]
            }
        }
    }

    /// Returns a video visit.
    func lookupVideoVisit(
        request: ServerRequest<Acme_Telehealth_V1_LookupVideoVisitRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_LookupVideoVisitResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processLookupVideoVisit(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a video visit.
    func peekVideoVisit(
        request: ServerRequest<Acme_Telehealth_V1_PeekVideoVisitRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_PeekVideoVisitResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processPeekVideoVisit(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns several video visits at once.
    func resolveVideoVisits(
        request: ServerRequest<Acme_Telehealth_V1_ResolveVideoVisitsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_ResolveVideoVisitsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processResolveVideoVisits(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists video visits a page at a time.
    func suggestVideoVisits(
        request: ServerRequest<Acme_Telehealth_V1_SuggestVideoVisitsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_SuggestVideoVisitsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSuggestVideoVisits(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Summarizes a video visit.
    func summarizeVideoVisits(
        request: ServerRequest<Acme_Telehealth_V1_SummarizeVideoVisitsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_SummarizeVideoVisitsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSummarizeVideoVisits(request.message)
            return ServerResponse(message: response)
        }
    }
}
