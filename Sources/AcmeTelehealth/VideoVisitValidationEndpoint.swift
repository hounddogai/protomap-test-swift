import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Checks video visits against the rules before anything acts on them.
final class VideoVisitValidationEndpoint: Acme_Telehealth_V1_VideoVisitValidationService.ServiceProtocol {
    private let store: any RecordRepository
    private let logger: Logger
    private let settings: Settings
    private let followUps = WorkQueue<Acme_Identity_V1_GetUserRequest>()
    private let careplansCareGoalQuery: Acme_Careplans_V1_CareGoalQueryService.Client<MeshTransport>
    private let careplansCareGoalValidation: Acme_Careplans_V1_CareGoalValidationService.Client<MeshTransport>
    private let careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>
    private let careplansCarePlanQuery: Acme_Careplans_V1_CarePlanQueryService.Client<MeshTransport>
    private let careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client<MeshTransport>
    private let featureflagsFeatureFlagQuery: Acme_Featureflags_V1_FeatureFlagQueryService.Client<MeshTransport>
    private let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    private let ledgerLedgerAccountQuery: Acme_Ledger_V1_LedgerAccountQueryService.Client<MeshTransport>
    private let notificationsNotificationValidation:
        Acme_Notifications_V1_NotificationValidationService.Client<MeshTransport>
    private let searchSearchIndex: Acme_Search_V1_SearchIndexService.Client<MeshTransport>
    private let sponsorshipsSponsor: Acme_Sponsorships_V1_SponsorService.Client<MeshTransport>
    private let telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client<MeshTransport>
    private let telehealthVisitNoteCalculation: Acme_Telehealth_V1_VisitNoteCalculationService.Client<MeshTransport>
    private let getVideoVisitRulesStep0:
        any RPCPort<Acme_Telehealth_V1_SimulateVideoVisitRequest, Acme_Telehealth_V1_SimulateVideoVisitResponse>
    private let lintVideoVisitsStep1:
        @Sendable (Acme_Telehealth_V1_QuoteVideoVisitRequest) async throws -> Acme_Telehealth_V1_QuoteVideoVisitResponse
    private let normalizeVideoVisitStep0:
        [String:
            @Sendable (Acme_Telehealth_V1_GetVideoVisitRatesRequest) async throws ->
            Acme_Telehealth_V1_GetVideoVisitRatesResponse]

    init(
        dependencies: any Dependencies,
        careplansCareGoalQuery: Acme_Careplans_V1_CareGoalQueryService.Client<MeshTransport>,
        careplansCareGoalValidation: Acme_Careplans_V1_CareGoalValidationService.Client<MeshTransport>,
        careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>,
        careplansCarePlanQuery: Acme_Careplans_V1_CarePlanQueryService.Client<MeshTransport>,
        careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client<MeshTransport>,
        featureflagsFeatureFlagQuery: Acme_Featureflags_V1_FeatureFlagQueryService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        ledgerLedgerAccountQuery: Acme_Ledger_V1_LedgerAccountQueryService.Client<MeshTransport>,
        notificationsNotificationValidation: Acme_Notifications_V1_NotificationValidationService.Client<MeshTransport>,
        searchSearchIndex: Acme_Search_V1_SearchIndexService.Client<MeshTransport>,
        sponsorshipsSponsor: Acme_Sponsorships_V1_SponsorService.Client<MeshTransport>,
        telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client<MeshTransport>,
        telehealthVisitNoteCalculation: Acme_Telehealth_V1_VisitNoteCalculationService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.careplansCareGoalQuery = careplansCareGoalQuery
        self.careplansCareGoalValidation = careplansCareGoalValidation
        self.careplansCarePlan = careplansCarePlan
        self.careplansCarePlanQuery = careplansCarePlanQuery
        self.careplansCarePlanValidation = careplansCarePlanValidation
        self.featureflagsFeatureFlagQuery = featureflagsFeatureFlagQuery
        self.identityUser = identityUser
        self.ledgerLedgerAccountQuery = ledgerLedgerAccountQuery
        self.notificationsNotificationValidation = notificationsNotificationValidation
        self.searchSearchIndex = searchSearchIndex
        self.sponsorshipsSponsor = sponsorshipsSponsor
        self.telehealthVideoVisitCalculation = telehealthVideoVisitCalculation
        self.telehealthVisitNoteCalculation = telehealthVisitNoteCalculation
        self.getVideoVisitRulesStep0 = ClosurePort<
            Acme_Telehealth_V1_SimulateVideoVisitRequest, Acme_Telehealth_V1_SimulateVideoVisitResponse
        >({ request in try await telehealthVideoVisitCalculation.simulateVideoVisit(request) })
        self.lintVideoVisitsStep1 = { request in try await telehealthVideoVisitCalculation.quoteVideoVisit(request) }
        self.normalizeVideoVisitStep0 = [
            "primary": { request in try await telehealthVideoVisitCalculation.getVideoVisitRates(request) }
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

    /// Explains a video visit.
    func explainVideoVisitDecision(
        request: ServerRequest<Acme_Telehealth_V1_ExplainVideoVisitDecisionRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_ExplainVideoVisitDecisionResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processExplainVideoVisitDecision(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a video visit.
    func getVideoVisitRules(
        request: ServerRequest<Acme_Telehealth_V1_GetVideoVisitRulesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_GetVideoVisitRulesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetVideoVisitRules(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lints a video visit.
    func lintVideoVisits(
        request: ServerRequest<Acme_Telehealth_V1_LintVideoVisitsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_LintVideoVisitsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processLintVideoVisits(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Normalizes a video visit.
    func normalizeVideoVisit(
        request: ServerRequest<Acme_Telehealth_V1_NormalizeVideoVisitRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_NormalizeVideoVisitResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processNormalizeVideoVisit(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Previews a video visit.
    func previewVideoVisit(
        request: ServerRequest<Acme_Telehealth_V1_PreviewVideoVisitRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_PreviewVideoVisitResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processPreviewVideoVisit(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Scores a video visit.
    func scoreVideoVisit(
        request: ServerRequest<Acme_Telehealth_V1_ScoreVideoVisitRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_ScoreVideoVisitResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processScoreVideoVisit(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Validates a video visit.
    func validateVideoVisit(
        request: ServerRequest<Acme_Telehealth_V1_ValidateVideoVisitRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_ValidateVideoVisitResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processValidateVideoVisit(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processExplainVideoVisitDecision(_ input: Acme_Telehealth_V1_ExplainVideoVisitDecisionRequest) async throws
        -> Acme_Telehealth_V1_ExplainVideoVisitDecisionResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "audit", detail: input.details.contact.email
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ExplainVideoVisitDecision",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VideoVisitRecord(input.videoVisit, tenant: input.context.tenantID)
        try await store.save(record.stored)
        try followUps.submit(
            Acme_Identity_V1_GetUserRequest.with {
                $0.context = input.context
                $0.userID = input.context.actor.userID
            })
        let importFrame = Acme_Careplans_V1_BatchCreateCarePlansRequest.with {
            $0.context = input.context
        }
        _ = try await self.careplansCarePlan.batchCreateCarePlans { writer in
            try await writer.write(importFrame)
        }
        let requests0 = input.videoVisit.participants.map { element in
            Acme_Telehealth_V1_QuoteVideoVisitRequest.with {
                $0.context = input.context
                $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                    $0.participants = [
                        Acme_Telehealth_V1_VideoVisitParticipant.with {
                            $0.contact = Acme_Common_V1_ContactInfo.with {
                                $0.phone = element.contact.phone
                            }
                        }
                    ]
                }
            }
        }
        let replies0 = try await FanOut.map(requests0) { candidate in
            try await self.telehealthVideoVisitCalculation.quoteVideoVisit(candidate)
        }
        let reply0 = replies0.first ?? Acme_Telehealth_V1_QuoteVideoVisitResponse()
        _ = reply0
        let requests1 = input.videoVisit.participants.map { element in
            Acme_Telehealth_V1_ExplainVideoVisitCalculationRequest.with {
                $0.context = input.context
                $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                    $0.participants = [
                        Acme_Telehealth_V1_VideoVisitParticipant.with {
                            $0.contact = Acme_Common_V1_ContactInfo.with {
                                $0.name = element.contact.name
                                $0.preferredChannel = element.contact.preferredChannel
                            }
                        }
                    ]
                }
            }
        }
        let replies1 = try await FanOut.map(requests1) { candidate in
            try await self.telehealthVideoVisitCalculation.explainVideoVisitCalculation(candidate)
        }
        let reply1 = replies1.first ?? Acme_Telehealth_V1_ExplainVideoVisitCalculationResponse()
        _ = reply1
        return Acme_Telehealth_V1_ExplainVideoVisitDecisionResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.title = input.videoVisit.title
                $0.videoVisitID = input.videoVisitID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processGetVideoVisitRules(_ input: Acme_Telehealth_V1_GetVideoVisitRulesRequest) async throws
        -> Acme_Telehealth_V1_GetVideoVisitRulesResponse
    {
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "GetVideoVisitRules",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "GetVideoVisitRules", detail: input.context.traceID
        )
        let outbound0 = Acme_Telehealth_V1_SimulateVideoVisitRequest.with {
            $0.context = input.context
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.context.actor.userID
                }
                $0.participants = [
                    Acme_Telehealth_V1_VideoVisitParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = input.context.actor.email
                        }
                    }
                ]
                $0.videoVisitID = input.videoVisitID
            }
        }
        let reply0 = try await self.getVideoVisitRulesStep0.execute(outbound0)
        return Acme_Telehealth_V1_GetVideoVisitRulesResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.recipient = reply0.videoVisit.location.recipient
                }
                $0.metadata = reply0.videoVisit.metadata
                $0.videoVisitID = input.videoVisitID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processLintVideoVisits(_ input: Acme_Telehealth_V1_LintVideoVisitsRequest) async throws
        -> Acme_Telehealth_V1_LintVideoVisitsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "audit", detail: input.details.contact.email
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "LintVideoVisits",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VideoVisitRecord(input.videoVisit, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Sponsorships_V1_ListSponsorsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Sponsorships_V1_ListSponsorsRequest.Filter.with {
                $0.region = input.videoVisit.location.region
            }
        }
        let port0 = RPCOperations.port { (request: Acme_Sponsorships_V1_ListSponsorsRequest) in
            try await self.sponsorshipsSponsor.listSponsors(request)
        }
        let reply0 = try await port0.execute(outbound0)
        let outbound1 = Acme_Telehealth_V1_QuoteVideoVisitRequest.with {
            $0.context = input.context
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.participants = [
                    Acme_Telehealth_V1_VideoVisitParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = input.videoVisit.organizer.email
                        }
                    }
                ]
            }
        }
        let reply1 = try await self.lintVideoVisitsStep1(outbound1)
        return Acme_Telehealth_V1_LintVideoVisitsResponse.with {
            $0.outcome = Acme_Telehealth_V1_LintVideoVisitsResponse.Outcome.with {
                $0.status = reply0.result.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply1.videoVisit.audit.updatedAt
                }
                $0.status = input.videoVisit.status
                $0.title = reply1.videoVisit.title
                $0.videoVisitID = input.videoVisitID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processNormalizeVideoVisit(_ input: Acme_Telehealth_V1_NormalizeVideoVisitRequest) async throws
        -> Acme_Telehealth_V1_NormalizeVideoVisitResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "audit", detail: input.details.contact.email
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "NormalizeVideoVisit",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VideoVisitRecord(input.videoVisit, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Telehealth_V1_GetVideoVisitRatesRequest.with {
            $0.context = input.context
            $0.videoVisitID = input.videoVisitID
        }
        guard let execute0 = self.normalizeVideoVisitStep0[settings.region] ?? self.normalizeVideoVisitStep0["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply0 = try await execute0(outbound0)
        let outbound1 = Acme_Telehealth_V1_RecalculateVideoVisitsRequest.with {
            $0.context = input.context
            $0.details = Acme_Telehealth_V1_RecalculateVideoVisitsRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = reply0.videoVisit.location.postalCode
                }
            }
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.recipient = input.videoVisit.location.recipient
                }
                $0.participants = [
                    Acme_Telehealth_V1_VideoVisitParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = input.videoVisit.organizer.email
                            $0.preferredChannel = input.details.contact.preferredChannel
                        }
                    }
                ]
            }
        }
        let reply1 = try await self.telehealthVideoVisitCalculation.recalculateVideoVisits(outbound1)
        let outbound2 = Acme_Careplans_V1_CheckCarePlanEligibilityRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.videoVisit.audit.createdAt
                    $0.updatedAt = reply0.videoVisit.audit.updatedAt
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = input.videoVisit.location.postalCode
                }
            }
            $0.context = input.context
        }
        let envelope2 = try Google_Protobuf_Any(message: outbound2)
        let unpacked2 = try Acme_Careplans_V1_CheckCarePlanEligibilityRequest(unpackingAny: envelope2)
        let reply2 = try await self.careplansCarePlanValidation.checkCarePlanEligibility(unpacked2)
        let outbound3 = Acme_Careplans_V1_SummarizeCarePlansRequest.with {
            $0.carePlanID = reply2.carePlan.carePlanID
            $0.context = input.context
            $0.reason = input.reason
        }
        let json3 = try outbound3.jsonString()
        let decoded3 = try Acme_Careplans_V1_SummarizeCarePlansRequest(jsonString: json3)
        let reply3 = try await self.careplansCarePlanQuery.summarizeCarePlans(decoded3)
        return Acme_Telehealth_V1_NormalizeVideoVisitResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply2.result.correlationID
                $0.details = reply3.result.details
                $0.status = "ok"
            }
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply1.videoVisit.audit.updatedAt
                }
                $0.location = input.videoVisit.location
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply1.videoVisit.organizer.displayName
                    $0.email = reply0.videoVisit.organizer.email
                }
                $0.videoVisitID = input.videoVisitID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processPreviewVideoVisit(_ input: Acme_Telehealth_V1_PreviewVideoVisitRequest) async throws
        -> Acme_Telehealth_V1_PreviewVideoVisitResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "audit", detail: input.details.contact.email
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "PreviewVideoVisit",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VideoVisitRecord(input.videoVisit, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let requests0 = input.videoVisit.participants.map { element in
            Acme_Careplans_V1_ScoreCareGoalRequest.with {
                $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                    $0.requester = Acme_Common_V1_ContactInfo.with {
                        $0.phone = element.contact.phone
                        $0.preferredChannel = element.contact.preferredChannel
                    }
                }
                $0.context = input.context
            }
        }
        let replies0 = try await FanOut.map(requests0) { candidate in
            try await self.careplansCareGoalValidation.scoreCareGoal(candidate)
        }
        let reply0 = replies0.first ?? Acme_Careplans_V1_ScoreCareGoalResponse()
        let outbound1 =
            Acme_Notifications_V1_ExplainNotificationDecisionRequest.forVideoVisitValidationEndpointPreviewVideoVisit1(
                input,
                reply0: reply0
            )
        let reply1 = try await self.notificationsNotificationValidation.explainNotificationDecision(outbound1)
        let selection2_2: String
        switch reply0.careGoal.origin {
        case .customer(let customer):
            selection2_2 = customer.displayName
        default: selection2_2 = .init()
        }
        let outbound2 = Acme_Search_V1_CreateSearchIndexRequest.with {
            $0.context = input.context
            $0.searchIndex = Acme_Search_V1_SearchIndex.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply1.notification.audit.createdBy
                    $0.etag = reply1.notification.audit.etag
                    $0.updatedBy = input.videoVisit.audit.updatedBy
                }
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.displayName = selection2_2
                }
            }
        }
        let reply2 = try await self.searchSearchIndex.createSearchIndex(outbound2)
        let outbound3 = Acme_Featureflags_V1_CountFeatureFlagsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Featureflags_V1_CountFeatureFlagsRequest.Filter.with {
                $0.region = input.videoVisit.location.region
            }
        }
        let reply3 = try await self.featureflagsFeatureFlagQuery.countFeatureFlags(
            outbound3, metadata: ["x-acme-region": .string(settings.region)]
        )
        return Acme_Telehealth_V1_PreviewVideoVisitResponse.with {
            $0.outcome = Acme_Telehealth_V1_PreviewVideoVisitResponse.Outcome.with {
                $0.message = reply3.result.message
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply1.notification.audit.createdAt
                    $0.createdBy = reply2.searchIndex.audit.createdBy
                }
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.locality = reply2.searchIndex.address.locality
                }
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply1.notification.customer.displayName
                }
                $0.status = input.videoVisit.status
                $0.videoVisitID = input.videoVisitID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processScoreVideoVisit(_ input: Acme_Telehealth_V1_ScoreVideoVisitRequest) async throws
        -> Acme_Telehealth_V1_ScoreVideoVisitResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.currencyCode)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "audit", detail: input.details.currencyCode
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ScoreVideoVisit",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VideoVisitRecord(input.videoVisit, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Ledger_V1_ResolveLedgerAccountsRequest.with {
            $0.context = input.context
        }
        let reply0 = try await RPCOperations.call(outbound0) { request in
            try await self.ledgerLedgerAccountQuery.resolveLedgerAccounts(request)
        }
        return Acme_Telehealth_V1_ScoreVideoVisitResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.details = reply0.result.details
                $0.status = "ok"
            }
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.status = input.videoVisit.status
                $0.videoVisitID = input.videoVisitID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processValidateVideoVisit(_ input: Acme_Telehealth_V1_ValidateVideoVisitRequest) async throws
        -> Acme_Telehealth_V1_ValidateVideoVisitResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.phone)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "audit", detail: input.details.contact.phone
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ValidateVideoVisit",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VideoVisitRecord(input.videoVisit, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Careplans_V1_ExportCareGoalsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Careplans_V1_ExportCareGoalsRequest.Filter.with {
                $0.createdAfter = input.videoVisit.audit.updatedAt
                $0.labels = input.videoVisit.metadata
                $0.ownerID = input.videoVisit.organizer.userID
                $0.region = input.videoVisit.location.region
            }
        }
        let reply0 = try await self.careplansCareGoalQuery.exportCareGoals(outbound0) { response in
            var latest = Acme_Careplans_V1_ExportCareGoalsResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        _ = reply0
        let outbound1 = Acme_Telehealth_V1_ExplainVisitNoteCalculationRequest.with {
            $0.context = Projection.read(input, at: \Acme_Telehealth_V1_ValidateVideoVisitRequest.context)
            $0.details = Acme_Telehealth_V1_ExplainVisitNoteCalculationRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = Projection.read(
                        input, at: \Acme_Telehealth_V1_ValidateVideoVisitRequest.details.contact.email)
                }
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.lines = input.videoVisit.location.lines
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = Projection.read(
                        input, at: \Acme_Telehealth_V1_ValidateVideoVisitRequest.videoVisit.organizer.displayName)
                }
            }
        }
        let reply1 = try await self.telehealthVisitNoteCalculation.explainVisitNoteCalculation(outbound1)
        return Acme_Telehealth_V1_ValidateVideoVisitResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.participants = [
                    Acme_Telehealth_V1_VideoVisitParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = reply1.visitNote.counterparty.email
                        }
                    }
                ]
                $0.title = input.videoVisit.title
                $0.videoVisitID = input.videoVisitID
            }
        }
    }
}
