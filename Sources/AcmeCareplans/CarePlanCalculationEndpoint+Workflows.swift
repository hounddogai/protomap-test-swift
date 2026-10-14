import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension CarePlanCalculationEndpoint {
    /// Calculates a care plan.
    func calculateCarePlan(
        request: ServerRequest<Acme_Careplans_V1_CalculateCarePlanRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_CalculateCarePlanResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCalculateCarePlan(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Compares a care plan.
    func compareCarePlanOptions(
        request: ServerRequest<Acme_Careplans_V1_CompareCarePlanOptionsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_CompareCarePlanOptionsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCompareCarePlanOptions(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Estimates a care plan.
    func estimateCarePlan(
        request: ServerRequest<Acme_Careplans_V1_EstimateCarePlanRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_EstimateCarePlanResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processEstimateCarePlan(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Explains a care plan.
    func explainCarePlanCalculation(
        request: ServerRequest<Acme_Careplans_V1_ExplainCarePlanCalculationRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_ExplainCarePlanCalculationResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processExplainCarePlanCalculation(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a care plan.
    func getCarePlanRates(
        request: ServerRequest<Acme_Careplans_V1_GetCarePlanRatesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_GetCarePlanRatesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetCarePlanRates(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Quotes a care plan.
    func quoteCarePlan(
        request: ServerRequest<Acme_Careplans_V1_QuoteCarePlanRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_QuoteCarePlanResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processQuoteCarePlan(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Recalculates a care plan.
    func recalculateCarePlans(
        request: ServerRequest<Acme_Careplans_V1_RecalculateCarePlansRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_RecalculateCarePlansResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRecalculateCarePlans(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Simulates a care plan.
    func simulateCarePlan(
        request: ServerRequest<Acme_Careplans_V1_SimulateCarePlanRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_SimulateCarePlanResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSimulateCarePlan(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processCalculateCarePlan(_ input: Acme_Careplans_V1_CalculateCarePlanRequest) async throws
        -> Acme_Careplans_V1_CalculateCarePlanResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.carePlan.audit.createdBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "audit", detail: input.carePlan.audit.createdBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "CalculateCarePlan",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CarePlanRecord(input.carePlan, tenant: input.context.tenantID)
        try await store.save(record.stored)
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        try followUps.submit(
            Acme_Identity_V1_GetUserRequest.with {
                $0.context = input.context
                $0.userID = input.context.actor.userID
            })
        let outbound0 = Acme_Metrics_V1_CheckMetricSeriesEligibilityRequest.with {
            $0.context = input.context
            $0.metricSeries = Acme_Metrics_V1_MetricSeries.with {
                $0.address = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = input.carePlan.billingAddress.countryCode
                    $0.postalCode = input.carePlan.billingAddress.postalCode
                    $0.recipient = input.carePlan.billingAddress.recipient
                }
            }
        }
        let port0 = RPCOperations.port { (request: Acme_Metrics_V1_CheckMetricSeriesEligibilityRequest) in
            try await self.metricsMetricSeriesValidation.checkMetricSeriesEligibility(request)
        }
        let reply0 = try await port0.execute(outbound0)
        let outbound1 = Acme_Notifications_V1_ExportNotificationsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Notifications_V1_ExportNotificationsRequest.Filter.with {
                $0.createdAfter = input.carePlan.counterparty.startsAt
                $0.labels = reply0.metricSeries.specs
                $0.region = reply0.metricSeries.address.region
            }
        }
        let reply1 = try await self.notificationsNotificationQuery.exportNotifications(outbound1) { response in
            var latest = Acme_Notifications_V1_ExportNotificationsResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        _ = reply1
        let outbound2 = Acme_Documents_V1_LintDocumentsRequest.with {
            $0.context = input.context
            $0.document = Acme_Documents_V1_Document.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply0.metricSeries.audit.createdAt
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.carePlan.billingAddress.region
                }
            }
        }
        let reply2 = try await self.calculateCarePlanStep2(outbound2)
        return Acme_Careplans_V1_CalculateCarePlanResponse.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.carePlanID = input.carePlanID
                $0.counterparty = Acme_Appointments_V1_AppointmentRef.with {
                    $0.displayName = reply0.metricSeries.owner.displayName
                }
                $0.issuedAt = input.carePlan.issuedAt
                $0.lines = [
                    Acme_Careplans_V1_CarePlanLine.with {
                        $0.description_p = reply0.metricSeries.components["primary", default: .init()].description_p
                    }
                ]
                $0.number = reply2.document.number
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processCompareCarePlanOptions(_ input: Acme_Careplans_V1_CompareCarePlanOptionsRequest) async throws
        -> Acme_Careplans_V1_CompareCarePlanOptionsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.carePlan.audit.createdBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "audit", detail: input.carePlan.audit.createdBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "CompareCarePlanOptions",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CarePlanRecord(input.carePlan, tenant: input.context.tenantID)
        try await store.save(record.stored)
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        let outbound0 = Acme_Featureflags_V1_LintFeatureFlagsRequest.with {
            $0.context = input.context
            $0.featureFlag = Acme_Featureflags_V1_FeatureFlag.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = input.carePlan.audit.etag
                    $0.updatedBy = input.carePlan.audit.updatedBy
                }
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.carePlan.counterparty.displayName
                }
            }
        }
        guard
            let execute0 = self.compareCarePlanOptionsStep0[settings.region]
                ?? self.compareCarePlanOptionsStep0["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply0 = try await execute0(outbound0)
        let outbound1 = Acme_Notifications_V1_CountNotificationsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Notifications_V1_CountNotificationsRequest.Filter.with {
                $0.createdAfter = input.carePlan.audit.updatedAt
                $0.labels = reply0.featureFlag.parameters
                $0.region = input.carePlan.billingAddress.region
            }
        }
        let reply1 = try await self.notificationsNotificationQuery.countNotifications(outbound1)
        return Acme_Careplans_V1_CompareCarePlanOptionsResponse.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.carePlanID = input.carePlanID
                $0.notes = input.carePlan.notes
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.message = reply0.outcome.message
                $0.status = reply1.result.status
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processEstimateCarePlan(_ input: Acme_Careplans_V1_EstimateCarePlanRequest) async throws
        -> Acme_Careplans_V1_EstimateCarePlanResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.carePlan.audit.createdBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "audit", detail: input.carePlan.audit.createdBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "EstimateCarePlan",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CarePlanRecord(input.carePlan, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Identity_V1_GetUserRulesRequest.with {
            $0.context = input.context
            $0.userID = input.context.actor.userID
        }
        let envelope0 = try Google_Protobuf_Any(message: outbound0)
        let unpacked0 = try Acme_Identity_V1_GetUserRulesRequest(unpackingAny: envelope0)
        let reply0 = try await self.identityUserValidation.getUserRules(unpacked0)
        let outbound1 = Acme_Boxoffice_V1_QuoteBoxOfficeSaleRequest.with {
            $0.boxOfficeSale = Acme_Boxoffice_V1_BoxOfficeSale.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply0.user.audit.updatedBy
                }
            }
            $0.context = input.context
        }
        let json1 = try outbound1.jsonString()
        let decoded1 = try Acme_Boxoffice_V1_QuoteBoxOfficeSaleRequest(jsonString: json1)
        let reply1 = try await self.boxofficeBoxOfficeSaleCalculation.quoteBoxOfficeSale(decoded1)
        let outbound2 = Acme_Identity_V1_ExplainUserDecisionRequest.forCarePlanCalculationEndpointEstimateCarePlan2(
            input,
            reply0: reply0,
            reply1: reply1
        )
        let reply2 = try await self.identityUserValidation.explainUserDecision(outbound2)
        let outbound3 = Acme_Documents_V1_ValidateDocumentRequest.with {
            $0.context = input.context
            $0.document = Acme_Documents_V1_Document.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = input.carePlan.audit.updatedBy
                }
            }
        }
        let reply3 = try await self.documentsDocumentValidation.validateDocument(
            outbound3, metadata: ["x-acme-region": .string(settings.region)]
        )
        return Acme_Careplans_V1_EstimateCarePlanResponse.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = reply2.user.primaryAddress.countryCode
                }
                $0.carePlanID = input.carePlanID
                $0.lines = [
                    Acme_Careplans_V1_CarePlanLine.with {
                        $0.attributes = reply0.user.attributes
                    }
                ]
                $0.metadata = reply1.boxOfficeSale.metadata
                $0.notes = input.carePlan.notes
                $0.number = reply2.user.nationalID.number
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply3.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processExplainCarePlanCalculation(_ input: Acme_Careplans_V1_ExplainCarePlanCalculationRequest) async throws
        -> Acme_Careplans_V1_ExplainCarePlanCalculationResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.carePlan.audit.createdBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "audit", detail: input.carePlan.audit.createdBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ExplainCarePlanCalculation",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CarePlanRecord(input.carePlan, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Authorization_V1_NormalizeAccessPolicyRequest.with {
            $0.accessPolicy = Acme_Authorization_V1_AccessPolicy.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = input.carePlan.audit.updatedBy
                }
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.carePlan.counterparty.displayName
                    $0.email = input.details.contact.email
                }
            }
            $0.context = input.context
            $0.details = Acme_Authorization_V1_NormalizeAccessPolicyRequest.Details.with {
                $0.contact = input.details.contact
            }
        }
        let reply0 = try await RPCOperations.call(outbound0) { request in
            try await self.authorizationAccessPolicyValidation.normalizeAccessPolicy(request)
        }
        let outbound1 = Acme_Authorization_V1_ValidateAccessPolicyRequest.with {
            $0.accessPolicy = Acme_Authorization_V1_AccessPolicy.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = Projection.read(
                        reply0, at: \Acme_Authorization_V1_NormalizeAccessPolicyResponse.accessPolicy.audit.updatedAt)
                    $0.updatedBy = Projection.read(
                        input, at: \Acme_Careplans_V1_ExplainCarePlanCalculationRequest.carePlan.audit.updatedBy)
                }
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.userID = Projection.read(
                        reply0, at: \Acme_Authorization_V1_NormalizeAccessPolicyResponse.accessPolicy.owner.userID)
                }
            }
            $0.context = Projection.read(input, at: \Acme_Careplans_V1_ExplainCarePlanCalculationRequest.context)
            $0.details = Acme_Authorization_V1_ValidateAccessPolicyRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = Projection.read(
                        reply0, at: \Acme_Authorization_V1_NormalizeAccessPolicyResponse.accessPolicy.owner.email)
                }
            }
        }
        let reply1 = try await self.authorizationAccessPolicyValidation.validateAccessPolicy(outbound1)
        let selection2_3: String
        switch reply0.accessPolicy.action {
        case .route(let route):
            selection2_3 = route.target
        default: selection2_3 = .init()
        }
        let outbound2 = Acme_Featureflags_V1_ExplainFeatureFlagDecisionRequest.with {
            $0.context = input.context
            $0.details = Acme_Featureflags_V1_ExplainFeatureFlagDecisionRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.preferredChannel = input.details.contact.preferredChannel
                }
            }
            $0.featureFlag = Acme_Featureflags_V1_FeatureFlag.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.carePlan.audit.createdAt
                    $0.etag = reply0.accessPolicy.audit.etag
                }
                $0.route = Acme_Featureflags_V1_FeatureFlagRouteAction.with {
                    $0.target = selection2_3
                }
            }
        }
        let reply2 = try await self.featureflagsFeatureFlagValidation.explainFeatureFlagDecision(outbound2)
        let outbound3 = Acme_Shows_V1_CompareShowOptionsRequest.with {
            $0.context = input.context
            $0.show = Acme_Shows_V1_Show.with {
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.carePlan.counterparty.displayName
                    $0.email = reply1.accessPolicy.owner.email
                }
            }
        }
        let step3: @Sendable () async throws -> Acme_Shows_V1_CompareShowOptionsResponse = {
            try await self.showsShowCalculation.compareShowOptions(outbound3)
        }
        let reply3 = try await step3()
        return Acme_Careplans_V1_ExplainCarePlanCalculationResponse.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply0.accessPolicy.audit.createdBy
                    $0.etag = Projection.firstValue(
                        [
                            reply1.accessPolicy.audit.etag,
                            reply3.show.audit.etag,
                        ], default: .init())
                }
                $0.carePlanID = input.carePlanID
                $0.status = input.carePlan.status
            }
            $0.outcome = Acme_Careplans_V1_ExplainCarePlanCalculationResponse.Outcome.with {
                $0.message = reply0.result.message
                $0.status = reply3.result.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply2.result.correlationID
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processGetCarePlanRates(_ input: Acme_Careplans_V1_GetCarePlanRatesRequest) async throws
        -> Acme_Careplans_V1_GetCarePlanRatesResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "GetCarePlanRates",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "GetCarePlanRates", detail: input.context.traceID
        )
        let outbound0 = Acme_Broadcasts_V1_ExportBroadcastsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Broadcasts_V1_ExportBroadcastsRequest.Filter.with {
                $0.createdAfter = input.context.deadline
                $0.ownerID = input.carePlanID
            }
        }
        let reply0 = try await self.broadcastsBroadcastQuery.exportBroadcasts(outbound0) { response in
            var latest = Acme_Broadcasts_V1_ExportBroadcastsResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        _ = reply0
        var outbound1 = Acme_Authorization_V1_NormalizeAccessPolicyRequest()
        outbound1.accessPolicy = Acme_Authorization_V1_AccessPolicy.with {
            $0.owner = Acme_Identity_V1_UserRef.with {
                $0.email = input.context.actor.email
            }
        }
        outbound1.context = input.context
        let reply1 = try await self.authorizationAccessPolicyValidation.normalizeAccessPolicy(outbound1)
        return Acme_Careplans_V1_GetCarePlanRatesResponse.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.carePlanID = input.carePlanID
                $0.lines = [
                    Acme_Careplans_V1_CarePlanLine.with {
                        $0.description_p = reply1.accessPolicy.description_p
                    }
                ]
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply1.result.status
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processQuoteCarePlan(_ input: Acme_Careplans_V1_QuoteCarePlanRequest) async throws
        -> Acme_Careplans_V1_QuoteCarePlanResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.carePlan.audit.createdBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "audit", detail: input.carePlan.audit.createdBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "QuoteCarePlan",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CarePlanRecord(input.carePlan, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let requests0 = input.carePlan.lines.map { element in
            Acme_Ledger_V1_CountLedgerAccountsRequest.with {
                $0.context = input.context
                $0.filter = Acme_Ledger_V1_CountLedgerAccountsRequest.Filter.with {
                    $0.labels = element.attributes
                    $0.ownerID = element.lineID
                    $0.region = input.carePlan.billingAddress.region
                }
            }
        }
        let replies0 = try await FanOut.map(requests0) { candidate in
            try await self.ledgerLedgerAccountQuery.countLedgerAccounts(candidate)
        }
        let reply0 = replies0.first ?? Acme_Ledger_V1_CountLedgerAccountsResponse()
        _ = reply0
        let outbound1 = Acme_Identity_V1_ValidateUserRequest.with {
            $0.context = input.context
            $0.user = Acme_Identity_V1_User.with {
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = input.details.destination.countryCode
                    $0.lines = input.details.destination.lines
                }
            }
        }
        let step1: @Sendable () async throws -> Acme_Identity_V1_ValidateUserResponse = {
            try await self.identityUserValidation.validateUser(outbound1)
        }
        let reply1 = try await step1()
        return Acme_Careplans_V1_QuoteCarePlanResponse.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.carePlanID = input.carePlanID
                $0.dueAt = input.carePlan.dueAt
                $0.number = reply1.user.passport.number
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processRecalculateCarePlans(_ input: Acme_Careplans_V1_RecalculateCarePlansRequest) async throws
        -> Acme_Careplans_V1_RecalculateCarePlansResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.carePlan.bank.accountHolder)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "audit", detail: input.carePlan.bank.accountHolder
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "RecalculateCarePlans",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CarePlanRecord(input.carePlan, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Shows_V1_BatchGetShowsRequest.with {
            $0.context = input.context
        }
        let reply0 = try await self.showsShow.batchGetShows(outbound0)
        let requests1 = input.carePlan.lines.map { element in
            Acme_Identity_V1_BrowseUsersRequest.with {
                $0.context = input.context
                $0.filter = Acme_Identity_V1_BrowseUsersRequest.Filter.with {
                    $0.ownerID = element.lineID
                    $0.region = input.details.destination.region
                }
            }
        }
        let replies1 = try await FanOut.map(requests1) { candidate in
            try await self.identityUserQuery.browseUsers(candidate)
        }
        let reply1 = replies1.first ?? Acme_Identity_V1_BrowseUsersResponse()
        _ = reply1
        let outbound2 = Acme_Featureflags_V1_LintFeatureFlagsRequest.with {
            $0.context = input.context
            $0.featureFlag = Acme_Featureflags_V1_FeatureFlag.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.carePlan.audit.createdAt
                    $0.createdBy = input.carePlan.audit.createdBy
                    $0.etag = input.carePlan.audit.etag
                    $0.updatedBy = input.carePlan.audit.updatedBy
                }
            }
        }
        async let remote2 = self.featureflagsFeatureFlagValidation.lintFeatureFlags(outbound2)
        async let persisted2 = store.count(tenant: input.context.tenantID)
        let (reply2, count2) = try await (remote2, persisted2)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count2)])
        return Acme_Careplans_V1_RecalculateCarePlansResponse.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply2.featureFlag.audit.createdBy
                }
                $0.carePlanID = input.carePlanID
                $0.number = input.carePlan.number
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.details = reply0.result.details
                $0.message = reply2.outcome.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processSimulateCarePlan(_ input: Acme_Careplans_V1_SimulateCarePlanRequest) async throws
        -> Acme_Careplans_V1_SimulateCarePlanResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.carePlan.audit.createdBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "audit", detail: input.carePlan.audit.createdBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SimulateCarePlan",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CarePlanRecord(input.carePlan, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Notifications_V1_NormalizeNotificationRequest.with {
            $0.context = input.context
            $0.notification = Acme_Notifications_V1_Notification.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.carePlan.audit.createdAt
                }
                $0.customer = Acme_Notifications_V1_NotificationTemplateRef.with {
                    $0.displayName = input.carePlan.counterparty.displayName
                }
                $0.sla = Acme_Notifications_V1_NotificationSla.with {
                    $0.dueAt = input.carePlan.dueAt
                }
            }
        }
        let reply0 = try await self.simulateCarePlanStep0.execute(outbound0)
        return Acme_Careplans_V1_SimulateCarePlanResponse.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply0.notification.audit.createdBy
                }
                $0.carePlanID = input.carePlanID
                $0.dueAt = reply0.notification.sla.dueAt
                $0.total = input.carePlan.total
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }
}
