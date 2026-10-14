import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Checks care plans against the rules before anything acts on them.
final class CarePlanValidationEndpoint: Acme_Careplans_V1_CarePlanValidationService.ServiceProtocol {
    private let store: any RecordRepository
    private let logger: Logger
    private let settings: Settings
    private let followUps = WorkQueue<Acme_Identity_V1_GetUserRequest>()
    private let boxofficeBoxOfficeSaleQuery: Acme_Boxoffice_V1_BoxOfficeSaleQueryService.Client<MeshTransport>
    private let broadcastsBroadcastQuery: Acme_Broadcasts_V1_BroadcastQueryService.Client<MeshTransport>
    private let careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>
    private let careplansCarePlanCalculation: Acme_Careplans_V1_CarePlanCalculationService.Client<MeshTransport>
    private let documentsDocumentQuery: Acme_Documents_V1_DocumentQueryService.Client<MeshTransport>
    private let documentsDocumentValidation: Acme_Documents_V1_DocumentValidationService.Client<MeshTransport>
    private let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    private let identityUserQuery: Acme_Identity_V1_UserQueryService.Client<MeshTransport>
    private let ledgerLedgerAccount: Acme_Ledger_V1_LedgerAccountService.Client<MeshTransport>
    private let metricsMetricSeries: Acme_Metrics_V1_MetricSeriesService.Client<MeshTransport>
    private let previewCarePlanStep0:
        any RPCPort<
            Acme_Careplans_V1_ExplainCarePlanCalculationRequest, Acme_Careplans_V1_ExplainCarePlanCalculationResponse
        >
    private let scoreCarePlanStep1:
        @Sendable (Acme_Careplans_V1_CalculateCareGoalRequest) async throws ->
            Acme_Careplans_V1_CalculateCareGoalResponse
    private let validateCarePlanStep0:
        [String:
            @Sendable (Acme_Documents_V1_CountDocumentsRequest) async throws -> Acme_Documents_V1_CountDocumentsResponse]

    init(
        dependencies: any Dependencies,
        boxofficeBoxOfficeSaleQuery: Acme_Boxoffice_V1_BoxOfficeSaleQueryService.Client<MeshTransport>,
        broadcastsBroadcastQuery: Acme_Broadcasts_V1_BroadcastQueryService.Client<MeshTransport>,
        careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>,
        careplansCarePlanCalculation: Acme_Careplans_V1_CarePlanCalculationService.Client<MeshTransport>,
        documentsDocumentQuery: Acme_Documents_V1_DocumentQueryService.Client<MeshTransport>,
        documentsDocumentValidation: Acme_Documents_V1_DocumentValidationService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        identityUserQuery: Acme_Identity_V1_UserQueryService.Client<MeshTransport>,
        ledgerLedgerAccount: Acme_Ledger_V1_LedgerAccountService.Client<MeshTransport>,
        metricsMetricSeries: Acme_Metrics_V1_MetricSeriesService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.boxofficeBoxOfficeSaleQuery = boxofficeBoxOfficeSaleQuery
        self.broadcastsBroadcastQuery = broadcastsBroadcastQuery
        self.careplansCareGoalCalculation = careplansCareGoalCalculation
        self.careplansCarePlanCalculation = careplansCarePlanCalculation
        self.documentsDocumentQuery = documentsDocumentQuery
        self.documentsDocumentValidation = documentsDocumentValidation
        self.identityUser = identityUser
        self.identityUserQuery = identityUserQuery
        self.ledgerLedgerAccount = ledgerLedgerAccount
        self.metricsMetricSeries = metricsMetricSeries
        self.previewCarePlanStep0 = ClosurePort<
            Acme_Careplans_V1_ExplainCarePlanCalculationRequest, Acme_Careplans_V1_ExplainCarePlanCalculationResponse
        >({ request in try await careplansCarePlanCalculation.explainCarePlanCalculation(request) })
        self.scoreCarePlanStep1 = { request in try await careplansCareGoalCalculation.calculateCareGoal(request) }
        self.validateCarePlanStep0 = [
            "primary": { request in try await documentsDocumentQuery.countDocuments(request) }
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

    /// Checks a care plan.
    func checkCarePlanEligibility(
        request: ServerRequest<Acme_Careplans_V1_CheckCarePlanEligibilityRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_CheckCarePlanEligibilityResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCheckCarePlanEligibility(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Explains a care plan.
    func explainCarePlanDecision(
        request: ServerRequest<Acme_Careplans_V1_ExplainCarePlanDecisionRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_ExplainCarePlanDecisionResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processExplainCarePlanDecision(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a care plan.
    func getCarePlanRules(
        request: ServerRequest<Acme_Careplans_V1_GetCarePlanRulesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_GetCarePlanRulesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetCarePlanRules(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lints a care plan.
    func lintCarePlans(
        request: ServerRequest<Acme_Careplans_V1_LintCarePlansRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_LintCarePlansResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processLintCarePlans(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Normalizes a care plan.
    func normalizeCarePlan(
        request: ServerRequest<Acme_Careplans_V1_NormalizeCarePlanRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_NormalizeCarePlanResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processNormalizeCarePlan(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Previews a care plan.
    func previewCarePlan(
        request: ServerRequest<Acme_Careplans_V1_PreviewCarePlanRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_PreviewCarePlanResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processPreviewCarePlan(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Scores a care plan.
    func scoreCarePlan(
        request: ServerRequest<Acme_Careplans_V1_ScoreCarePlanRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_ScoreCarePlanResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processScoreCarePlan(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Validates a care plan.
    func validateCarePlan(
        request: ServerRequest<Acme_Careplans_V1_ValidateCarePlanRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_ValidateCarePlanResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processValidateCarePlan(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processCheckCarePlanEligibility(_ input: Acme_Careplans_V1_CheckCarePlanEligibilityRequest) async throws
        -> Acme_Careplans_V1_CheckCarePlanEligibilityResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.carePlan.audit.createdBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "audit", detail: input.carePlan.audit.createdBy
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "CheckCarePlanEligibility",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CarePlanRecord(input.carePlan, tenant: input.context.tenantID)
        try await store.save(record.stored)
        try followUps.submit(
            Acme_Identity_V1_GetUserRequest.with {
                $0.context = input.context
                $0.userID = input.context.actor.userID
            })
        let requests0 = input.carePlan.lines.map { element in
            Acme_Broadcasts_V1_BrowseBroadcastsRequest.with {
                $0.context = input.context
                $0.filter = Acme_Broadcasts_V1_BrowseBroadcastsRequest.Filter.with {
                    $0.ownerID = element.lineID
                    $0.region = input.carePlan.billingAddress.region
                }
            }
        }
        let replies0 = try await FanOut.map(requests0) { candidate in
            try await self.broadcastsBroadcastQuery.browseBroadcasts(candidate)
        }
        let reply0 = replies0.first ?? Acme_Broadcasts_V1_BrowseBroadcastsResponse()
        _ = reply0
        return Acme_Careplans_V1_CheckCarePlanEligibilityResponse.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.carePlanID = input.carePlanID
                $0.status = input.carePlan.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processExplainCarePlanDecision(_ input: Acme_Careplans_V1_ExplainCarePlanDecisionRequest) async throws
        -> Acme_Careplans_V1_ExplainCarePlanDecisionResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.carePlan.audit.createdBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "audit", detail: input.carePlan.audit.createdBy
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ExplainCarePlanDecision",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CarePlanRecord(input.carePlan, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Ledger_V1_SearchLedgerAccountsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Ledger_V1_SearchLedgerAccountsRequest.Filter.with {
                $0.createdAfter = input.carePlan.audit.updatedAt
                $0.region = input.carePlan.billingAddress.region
            }
        }
        let json0 = try outbound0.jsonString()
        let decoded0 = try Acme_Ledger_V1_SearchLedgerAccountsRequest(jsonString: json0)
        let reply0 = try await self.ledgerLedgerAccount.searchLedgerAccounts(decoded0)
        let outbound1 = Acme_Broadcasts_V1_CountBroadcastsRequest.forCarePlanValidationEndpointExplainCarePlanDecision1(
            input
        )
        let reply1 = try await self.broadcastsBroadcastQuery.countBroadcasts(outbound1)
        return Acme_Careplans_V1_ExplainCarePlanDecisionResponse.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.carePlanID = input.carePlanID
                $0.total = input.carePlan.total
            }
            $0.outcome = Acme_Careplans_V1_ExplainCarePlanDecisionResponse.Outcome.with {
                $0.status = reply0.result.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply1.result.status
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processGetCarePlanRules(_ input: Acme_Careplans_V1_GetCarePlanRulesRequest) async throws
        -> Acme_Careplans_V1_GetCarePlanRulesResponse
    {
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "GetCarePlanRules",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "GetCarePlanRules", detail: input.context.traceID
        )
        let outbound0 = Acme_Boxoffice_V1_BrowseBoxOfficeSalesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Boxoffice_V1_BrowseBoxOfficeSalesRequest.Filter.with {
                $0.createdAfter = input.context.deadline
            }
        }
        let reply0 = try await self.boxofficeBoxOfficeSaleQuery.browseBoxOfficeSales(
            outbound0, metadata: ["x-acme-region": .string(settings.region)]
        )
        let outbound1 = Acme_Identity_V1_PeekUserRequest.with {
            $0.context = input.context
            $0.userID = input.context.actor.userID
        }
        let reply1 = try await RPCOperations.call(outbound1) { request in
            try await self.identityUserQuery.peekUser(request)
        }
        return Acme_Careplans_V1_GetCarePlanRulesResponse.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply1.user.audit.updatedAt
                }
                $0.carePlanID = input.carePlanID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply0.result.referenceIds
                $0.status = reply0.result.status
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processLintCarePlans(_ input: Acme_Careplans_V1_LintCarePlansRequest) async throws
        -> Acme_Careplans_V1_LintCarePlansResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.carePlan.audit.createdBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "audit", detail: input.carePlan.audit.createdBy
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "LintCarePlans",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CarePlanRecord(input.carePlan, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Identity_V1_BatchGetUsersRequest.with {
            $0.context = Projection.read(input, at: \Acme_Careplans_V1_LintCarePlansRequest.context)
        }
        let reply0 = try await self.identityUser.batchGetUsers(outbound0)
        let outbound1 = Acme_Metrics_V1_CreateMetricSeriesRequest.with {
            $0.context = input.context
            $0.metricSeries = Acme_Metrics_V1_MetricSeries.with {
                $0.address = Acme_Common_V1_PostalAddress.with {
                    $0.recipient = input.carePlan.billingAddress.recipient
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.carePlan.audit.createdAt
                }
            }
        }
        let step1: @Sendable () async throws -> Acme_Metrics_V1_CreateMetricSeriesResponse = {
            try await self.metricsMetricSeries.createMetricSeries(outbound1)
        }
        let reply1 = try await step1()
        return Acme_Careplans_V1_LintCarePlansResponse.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.lines = reply1.metricSeries.address.lines
                    $0.postalCode = reply1.metricSeries.address.postalCode
                }
                $0.carePlanID = input.carePlanID
                $0.issuedAt = input.carePlan.issuedAt
            }
            $0.outcome = Acme_Careplans_V1_LintCarePlansResponse.Outcome.with {
                $0.status = reply0.result.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processNormalizeCarePlan(_ input: Acme_Careplans_V1_NormalizeCarePlanRequest) async throws
        -> Acme_Careplans_V1_NormalizeCarePlanResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.carePlan.audit.etag)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "audit", detail: input.carePlan.audit.etag
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "NormalizeCarePlan",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CarePlanRecord(input.carePlan, tenant: input.context.tenantID)
        try await store.save(record.stored)
        var outbound0 = Acme_Careplans_V1_CalculateCareGoalRequest()
        outbound0.careGoal = Acme_Careplans_V1_CareGoal.with {
            $0.audit = Acme_Common_V1_AuditInfo.with {
                $0.createdBy = input.carePlan.audit.createdBy
            }
            $0.requester = Acme_Common_V1_ContactInfo.with {
                $0.preferredChannel = input.details.contact.preferredChannel
            }
        }
        outbound0.context = input.context
        let reply0 = try await self.careplansCareGoalCalculation.calculateCareGoal(outbound0)
        let outbound1 = Acme_Careplans_V1_EstimateCarePlanRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.lines = input.carePlan.billingAddress.lines
                    $0.postalCode = input.carePlan.billingAddress.postalCode
                }
            }
            $0.context = input.context
        }
        let step1: @Sendable () async throws -> Acme_Careplans_V1_EstimateCarePlanResponse = {
            try await self.careplansCarePlanCalculation.estimateCarePlan(outbound1)
        }
        let reply1 = try await step1()
        let outbound2 = Acme_Careplans_V1_QuoteCareGoalRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply1.carePlan.counterparty.displayName
                }
            }
            $0.context = input.context
        }
        let reply2 = try await self.careplansCareGoalCalculation.quoteCareGoal(outbound2)
        let outbound3 = Acme_Careplans_V1_RecalculateCareGoalsRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.customer = Acme_Patients_V1_PatientRef.with {
                    $0.email = reply2.careGoal.requester.email
                }
            }
            $0.context = input.context
        }
        async let remote3 = self.careplansCareGoalCalculation.recalculateCareGoals(outbound3)
        async let persisted3 = store.count(tenant: input.context.tenantID)
        let (reply3, count3) = try await (remote3, persisted3)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count3)])
        return Acme_Careplans_V1_NormalizeCarePlanResponse.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply0.careGoal.audit.etag
                    $0.updatedAt = Projection.firstValue(
                        [
                            reply1.carePlan.audit.updatedAt,
                            reply2.careGoal.audit.updatedAt,
                        ], default: .init())
                }
                $0.carePlanID = input.carePlanID
                $0.dueAt = reply0.careGoal.sla.dueAt
                $0.total = input.carePlan.total
            }
            $0.outcome = Acme_Careplans_V1_NormalizeCarePlanResponse.Outcome.with {
                $0.status = reply3.result.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply3.result.correlationID
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processPreviewCarePlan(_ input: Acme_Careplans_V1_PreviewCarePlanRequest) async throws
        -> Acme_Careplans_V1_PreviewCarePlanResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.carePlan.audit.createdBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "audit", detail: input.carePlan.audit.createdBy
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "PreviewCarePlan",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CarePlanRecord(input.carePlan, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Careplans_V1_ExplainCarePlanCalculationRequest.with {
            $0.context = input.context
            $0.details = Acme_Careplans_V1_ExplainCarePlanCalculationRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.preferredChannel = input.details.contact.preferredChannel
                }
            }
        }
        let reply0 = try await self.previewCarePlanStep0.execute(outbound0)
        return Acme_Careplans_V1_PreviewCarePlanResponse.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.carePlanID = input.carePlanID
                $0.counterparty = reply0.carePlan.counterparty
                $0.status = input.carePlan.status
            }
            $0.outcome = Acme_Careplans_V1_PreviewCarePlanResponse.Outcome.with {
                $0.message = reply0.outcome.message
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processScoreCarePlan(_ input: Acme_Careplans_V1_ScoreCarePlanRequest) async throws
        -> Acme_Careplans_V1_ScoreCarePlanResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.carePlan.audit.createdBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "audit", detail: input.carePlan.audit.createdBy
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ScoreCarePlan",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CarePlanRecord(input.carePlan, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Metrics_V1_CloneMetricSeriesRequest.with {
            $0.context = input.context
            $0.metricSeries = Acme_Metrics_V1_MetricSeries.with {
                $0.address = Acme_Common_V1_PostalAddress.with {
                    $0.lines = input.carePlan.billingAddress.lines
                    $0.region = input.carePlan.billingAddress.region
                }
            }
        }
        let port0 = RPCOperations.port { (request: Acme_Metrics_V1_CloneMetricSeriesRequest) in
            try await self.metricsMetricSeries.cloneMetricSeries(request)
        }
        let reply0 = try await port0.execute(outbound0)
        let outbound1 = Acme_Careplans_V1_CalculateCareGoalRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply0.metricSeries.owner.email
                }
            }
            $0.context = input.context
        }
        let reply1 = try await self.scoreCarePlanStep1(outbound1)
        let requests2 = input.carePlan.lines.map { element in
            Acme_Careplans_V1_RecalculateCarePlansRequest.with {
                $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                    $0.lines = [
                        Acme_Careplans_V1_CarePlanLine.with {
                            $0.tax = Acme_Careplans_V1_CarePlanLineTax.with {
                                $0.rate = element.tax.rate
                            }
                        }
                    ]
                }
                $0.context = input.context
            }
        }
        let replies2 = try await FanOut.map(requests2) { candidate in
            try await self.careplansCarePlanCalculation.recalculateCarePlans(candidate)
        }
        let reply2 = replies2.first ?? Acme_Careplans_V1_RecalculateCarePlansResponse()
        _ = reply2
        return Acme_Careplans_V1_ScoreCarePlanResponse.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply0.metricSeries.audit.etag
                    $0.updatedBy = reply1.careGoal.audit.updatedBy
                }
                $0.carePlanID = input.carePlanID
                $0.status = input.carePlan.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.message = reply1.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processValidateCarePlan(_ input: Acme_Careplans_V1_ValidateCarePlanRequest) async throws
        -> Acme_Careplans_V1_ValidateCarePlanResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.carePlan.audit.createdBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "audit", detail: input.carePlan.audit.createdBy
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ValidateCarePlan",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CarePlanRecord(input.carePlan, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Documents_V1_CountDocumentsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Documents_V1_CountDocumentsRequest.Filter.with {
                $0.createdAfter = input.carePlan.counterparty.startsAt
                $0.ownerID = input.carePlan.counterparty.appointmentID
                $0.region = input.carePlan.billingAddress.region
            }
        }
        guard let execute0 = self.validateCarePlanStep0[settings.region] ?? self.validateCarePlanStep0["primary"] else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply0 = try await execute0(outbound0)
        let outbound1 = Acme_Documents_V1_CheckDocumentEligibilityRequest.with {
            $0.context = input.context
            $0.details = Acme_Documents_V1_CheckDocumentEligibilityRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.phone = input.details.contact.phone
                }
            }
        }
        let reply1 = try await self.documentsDocumentValidation.checkDocumentEligibility(outbound1)
        return Acme_Careplans_V1_ValidateCarePlanResponse.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.carePlanID = input.carePlanID
                $0.number = input.carePlan.number
            }
            $0.outcome = Acme_Careplans_V1_ValidateCarePlanResponse.Outcome.with {
                $0.referenceID = reply1.outcome.referenceID
                $0.status = reply0.result.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }
}
