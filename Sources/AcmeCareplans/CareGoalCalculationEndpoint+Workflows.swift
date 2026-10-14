import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension CareGoalCalculationEndpoint {
    /// Calculates a care goal.
    func calculateCareGoal(
        request: ServerRequest<Acme_Careplans_V1_CalculateCareGoalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_CalculateCareGoalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCalculateCareGoal(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Compares a care goal.
    func compareCareGoalOptions(
        request: ServerRequest<Acme_Careplans_V1_CompareCareGoalOptionsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_CompareCareGoalOptionsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCompareCareGoalOptions(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Estimates a care goal.
    func estimateCareGoal(
        request: ServerRequest<Acme_Careplans_V1_EstimateCareGoalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_EstimateCareGoalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processEstimateCareGoal(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Explains a care goal.
    func explainCareGoalCalculation(
        request: ServerRequest<Acme_Careplans_V1_ExplainCareGoalCalculationRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_ExplainCareGoalCalculationResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processExplainCareGoalCalculation(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a care goal.
    func getCareGoalRates(
        request: ServerRequest<Acme_Careplans_V1_GetCareGoalRatesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_GetCareGoalRatesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetCareGoalRates(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Quotes a care goal.
    func quoteCareGoal(
        request: ServerRequest<Acme_Careplans_V1_QuoteCareGoalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_QuoteCareGoalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processQuoteCareGoal(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Recalculates a care goal.
    func recalculateCareGoals(
        request: ServerRequest<Acme_Careplans_V1_RecalculateCareGoalsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_RecalculateCareGoalsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRecalculateCareGoals(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Simulates a care goal.
    func simulateCareGoal(
        request: ServerRequest<Acme_Careplans_V1_SimulateCareGoalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_SimulateCareGoalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSimulateCareGoal(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processCalculateCareGoal(_ input: Acme_Careplans_V1_CalculateCareGoalRequest) async throws
        -> Acme_Careplans_V1_CalculateCareGoalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.careGoal.assignee.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "audit", detail: input.careGoal.assignee.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "CalculateCareGoal",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CareGoalRecord(input.careGoal, tenant: input.context.tenantID)
        try await store.save(record.stored)
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        try followUps.submit(
            Acme_Identity_V1_GetUserRequest.with {
                $0.context = input.context
                $0.userID = input.context.actor.userID
            })
        let outbound0 = Acme_Careplans_V1_CompareCarePlanOptionsRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = input.careGoal.audit.updatedBy
                }
            }
            $0.context = input.context
        }
        let json0 = try outbound0.jsonString()
        let decoded0 = try Acme_Careplans_V1_CompareCarePlanOptionsRequest(jsonString: json0)
        let reply0 = try await self.careplansCarePlanCalculation.compareCarePlanOptions(decoded0)
        let selection1_1: String
        switch reply0.carePlan.settlement {
        case .bank(let bank):
            selection1_1 = bank.iban
        default: selection1_1 = .init()
        }
        let outbound1 = Acme_Careplans_V1_CalculateCarePlanRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.bank = Acme_Careplans_V1_CarePlanBankSettlement.with {
                    $0.iban = selection1_1
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.locality = reply0.carePlan.billingAddress.locality
                    $0.postalCode = reply0.carePlan.billingAddress.postalCode
                }
            }
            $0.context = input.context
        }
        let reply1 = try await self.careplansCarePlanCalculation.calculateCarePlan(outbound1)
        return Acme_Careplans_V1_CalculateCareGoalResponse.with {
            $0.breakdown = Acme_Careplans_V1_CalculateCareGoalResponse.Breakdown.with {
                $0.total = reply0.breakdown.total
            }
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply1.carePlan.audit.updatedAt
                }
                $0.careGoalID = input.careGoalID
                $0.requester = input.careGoal.requester
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processCompareCareGoalOptions(_ input: Acme_Careplans_V1_CompareCareGoalOptionsRequest) async throws
        -> Acme_Careplans_V1_CompareCareGoalOptionsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.careGoal.assignee.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "audit", detail: input.careGoal.assignee.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "CompareCareGoalOptions",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CareGoalRecord(input.careGoal, tenant: input.context.tenantID)
        try await store.save(record.stored)
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        let outbound0 =
            Acme_Metrics_V1_ExplainMetricSeriesDecisionRequest.forCareGoalCalculationEndpointCompareCareGoalOptions0(
                input
            )
        let reply0 = try await self.metricsMetricSeriesValidation.explainMetricSeriesDecision(outbound0)
        let requests1 = input.careGoal.comments.map { element in
            Acme_Careplans_V1_ExplainCarePlanCalculationRequest.with {
                $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                    $0.audit = Acme_Common_V1_AuditInfo.with {
                        $0.createdAt = element.createdAt
                    }
                }
                $0.context = input.context
            }
        }
        let replies1 = try await FanOut.map(requests1) { candidate in
            try await self.careplansCarePlanCalculation.explainCarePlanCalculation(candidate)
        }
        let reply1 = replies1.first ?? Acme_Careplans_V1_ExplainCarePlanCalculationResponse()
        let requests2 = input.careGoal.comments.map { element in
            Acme_Metrics_V1_PreviewMetricSeriesRequest.with {
                $0.context = input.context
                $0.metricSeries = Acme_Metrics_V1_MetricSeries.with {
                    $0.address = Acme_Common_V1_PostalAddress.with {
                        $0.countryCode = reply1.carePlan.billingAddress.countryCode
                    }
                    $0.audit = Acme_Common_V1_AuditInfo.with {
                        $0.createdAt = element.createdAt
                        $0.createdBy = reply1.carePlan.audit.createdBy
                    }
                    $0.owner = Acme_Identity_V1_UserRef.with {
                        $0.email = element.authorEmail
                    }
                }
            }
        }
        let replies2 = try await FanOut.map(requests2) { candidate in
            try await self.metricsMetricSeriesValidation.previewMetricSeries(candidate)
        }
        let reply2 = replies2.first ?? Acme_Metrics_V1_PreviewMetricSeriesResponse()
        _ = reply2
        let selection3_1: String
        switch reply1.carePlan.settlement {
        case .bank(let bank):
            selection3_1 = bank.bic
        default: selection3_1 = .init()
        }
        let outbound3 = Acme_Careplans_V1_RecalculateCarePlansRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = input.careGoal.audit.updatedBy
                }
                $0.bank = Acme_Careplans_V1_CarePlanBankSettlement.with {
                    $0.bic = selection3_1
                }
            }
            $0.context = input.context
        }
        let reply3 = try await self.careplansCarePlanCalculation.recalculateCarePlans(outbound3)
        return Acme_Careplans_V1_CompareCareGoalOptionsResponse.with {
            $0.breakdown = Acme_Careplans_V1_CompareCareGoalOptionsResponse.Breakdown.with {
                $0.total = reply3.carePlan.total
            }
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply3.carePlan.counterparty.displayName
                }
                $0.careGoalID = input.careGoalID
                $0.customFields = input.careGoal.customFields
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processEstimateCareGoal(_ input: Acme_Careplans_V1_EstimateCareGoalRequest) async throws
        -> Acme_Careplans_V1_EstimateCareGoalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.careGoal.assignee.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "audit", detail: input.careGoal.assignee.email
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "EstimateCareGoal",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CareGoalRecord(input.careGoal, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let selection0_1: String
        switch input.careGoal.origin {
        case .customer(let customer):
            selection0_1 = customer.displayName
        default: selection0_1 = .init()
        }
        let outbound0 = Acme_Concessions_V1_RecalculateConcessionStandsRequest.with {
            $0.concessionStand = Acme_Concessions_V1_ConcessionStand.with {
                $0.address = Acme_Common_V1_PostalAddress.with {
                    $0.locality = input.details.destination.locality
                }
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.displayName = selection0_1
                }
            }
            $0.context = input.context
        }
        let reply0 = try await self.concessionsConcessionStandCalculation.recalculateConcessionStands(outbound0)
        let outbound1 = Acme_Careplans_V1_QuoteCarePlanRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = input.details.destination.countryCode
                    $0.lines = input.details.destination.lines
                }
                $0.counterparty = Acme_Appointments_V1_AppointmentRef.with {
                    $0.displayName = reply0.concessionStand.owner.displayName
                }
            }
            $0.context = input.context
        }
        let reply1 = try await self.careplansCarePlanCalculation.quoteCarePlan(
            outbound1, metadata: ["x-acme-region": .string(settings.region)]
        )
        let selection2_2: String
        switch reply0.concessionStand.locator {
        case .address(let address):
            selection2_2 = address.recipient
        default: selection2_2 = .init()
        }
        let selection2_3: String
        switch reply1.carePlan.settlement {
        case .card(let card):
            selection2_3 = card.last4
        default: selection2_3 = .init()
        }
        let outbound2 = Acme_Careplans_V1_CalculateCarePlanRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.recipient = selection2_2
                }
                $0.card = Acme_Careplans_V1_CarePlanCardSettlement.with {
                    $0.last4 = selection2_3
                }
                $0.counterparty = Acme_Appointments_V1_AppointmentRef.with {
                    $0.displayName = input.careGoal.assignee.displayName
                }
            }
            $0.context = input.context
        }
        let reply2 = try await self.careplansCarePlanCalculation.calculateCarePlan(outbound2)
        let selection3_2: String
        switch reply0.concessionStand.locator {
        case .address(let address):
            selection3_2 = address.locality
        default: selection3_2 = .init()
        }
        let outbound3 = Acme_Careplans_V1_RecalculateCarePlansRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply0.concessionStand.audit.updatedAt
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = input.details.destination.countryCode
                    $0.locality = selection3_2
                }
            }
            $0.context = input.context
        }
        let reply3 = try await self.careplansCarePlanCalculation.recalculateCarePlans(outbound3)
        return Acme_Careplans_V1_EstimateCareGoalResponse.with {
            $0.breakdown = Acme_Careplans_V1_EstimateCareGoalResponse.Breakdown.with {
                $0.total = reply0.breakdown.total
            }
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = Projection.firstValue(
                        [
                            reply1.carePlan.audit.createdAt,
                            reply2.carePlan.audit.createdAt,
                        ], default: .init())
                }
                $0.careGoalID = input.careGoalID
                $0.customFields = input.careGoal.customFields
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply3.result.referenceIds
                $0.status = reply2.result.status
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processExplainCareGoalCalculation(_ input: Acme_Careplans_V1_ExplainCareGoalCalculationRequest) async throws
        -> Acme_Careplans_V1_ExplainCareGoalCalculationResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.careGoal.assignee.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "audit", detail: input.careGoal.assignee.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ExplainCareGoalCalculation",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CareGoalRecord(input.careGoal, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Careplans_V1_CompareCarePlanOptionsRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = input.careGoal.audit.etag
                    $0.updatedBy = input.careGoal.audit.updatedBy
                }
            }
            $0.context = input.context
        }
        let reply0 = try await RPCOperations.call(outbound0) { request in
            try await self.careplansCarePlanCalculation.compareCarePlanOptions(request)
        }
        let requests1 = input.careGoal.comments.map { element in
            Acme_Careplans_V1_SimulateCarePlanRequest.with {
                $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                    $0.audit = Acme_Common_V1_AuditInfo.with {
                        $0.createdAt = element.createdAt
                        $0.etag = reply0.carePlan.audit.etag
                    }
                    $0.counterparty = Acme_Appointments_V1_AppointmentRef.with {
                        $0.startsAt = reply0.carePlan.counterparty.startsAt
                    }
                }
                $0.context = input.context
            }
        }
        let replies1 = try await FanOut.map(requests1) { candidate in
            try await self.careplansCarePlanCalculation.simulateCarePlan(candidate)
        }
        let reply1 = replies1.first ?? Acme_Careplans_V1_SimulateCarePlanResponse()
        _ = reply1
        return Acme_Careplans_V1_ExplainCareGoalCalculationResponse.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.careGoalID = input.careGoalID
                $0.priority = input.careGoal.priority
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processGetCareGoalRates(_ input: Acme_Careplans_V1_GetCareGoalRatesRequest) async throws
        -> Acme_Careplans_V1_GetCareGoalRatesResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "GetCareGoalRates",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "GetCareGoalRates", detail: input.context.traceID
        )
        let outbound0 = Acme_Metrics_V1_CountMetricSeriesesRequest.with {
            $0.context = Projection.read(input, at: \Acme_Careplans_V1_GetCareGoalRatesRequest.context)
            $0.filter = Acme_Metrics_V1_CountMetricSeriesesRequest.Filter.with {
                $0.createdAfter = Projection.read(
                    input, at: \Acme_Careplans_V1_GetCareGoalRatesRequest.context.deadline)
                $0.ownerID = Projection.read(input, at: \Acme_Careplans_V1_GetCareGoalRatesRequest.context.actor.userID)
            }
        }
        let reply0 = try await self.metricsMetricSeriesQuery.countMetricSerieses(outbound0)
        let outbound1 = Acme_Careplans_V1_CalculateCarePlanRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.counterparty = Acme_Appointments_V1_AppointmentRef.with {
                    $0.startsAt = input.context.deadline
                }
                $0.lines = [
                    Acme_Careplans_V1_CarePlanLine.with {
                        $0.attributes = input.context.baggage
                    }
                ]
                $0.metadata = reply0.result.details
            }
            $0.context = input.context
        }
        let step1: @Sendable () async throws -> Acme_Careplans_V1_CalculateCarePlanResponse = {
            try await self.careplansCarePlanCalculation.calculateCarePlan(outbound1)
        }
        let reply1 = try await step1()
        return Acme_Careplans_V1_GetCareGoalRatesResponse.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.careGoalID = input.careGoalID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.message = reply1.result.message
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processQuoteCareGoal(_ input: Acme_Careplans_V1_QuoteCareGoalRequest) async throws
        -> Acme_Careplans_V1_QuoteCareGoalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.careGoal.assignee.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "audit", detail: input.careGoal.assignee.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "QuoteCareGoal",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CareGoalRecord(input.careGoal, tenant: input.context.tenantID)
        try await store.save(record.stored)
        var outbound0 = Acme_Careplans_V1_ExplainCarePlanCalculationRequest()
        outbound0.carePlan = Acme_Careplans_V1_CarePlan.with {
            $0.audit = Acme_Common_V1_AuditInfo.with {
                $0.updatedBy = input.careGoal.audit.updatedBy
            }
            $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                $0.lines = input.details.destination.lines
                $0.postalCode = input.details.destination.postalCode
            }
        }
        outbound0.context = input.context
        outbound0.details = Acme_Careplans_V1_ExplainCarePlanCalculationRequest.Details.with {
            $0.contact = Acme_Common_V1_ContactInfo.with {
                $0.email = input.careGoal.requester.email
            }
        }
        let reply0 = try await self.careplansCarePlanCalculation.explainCarePlanCalculation(outbound0)
        let outbound1 = Acme_Careplans_V1_RecalculateCarePlansRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply0.carePlan.audit.updatedAt
                }
            }
            $0.context = input.context
        }
        let step1: @Sendable () async throws -> Acme_Careplans_V1_RecalculateCarePlansResponse = {
            try await self.careplansCarePlanCalculation.recalculateCarePlans(outbound1)
        }
        let reply1 = try await step1()
        let outbound2 = Acme_Ledger_V1_SearchLedgerAccountsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Ledger_V1_SearchLedgerAccountsRequest.Filter.with {
                $0.createdAfter = reply0.carePlan.audit.updatedAt
                $0.region = reply0.carePlan.billingAddress.region
            }
        }
        let reply2 = try await self.ledgerLedgerAccount.searchLedgerAccounts(outbound2)
        return Acme_Careplans_V1_QuoteCareGoalResponse.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.displayName = Projection.firstValue(
                        [
                            reply0.carePlan.counterparty.displayName,
                            reply1.carePlan.counterparty.displayName,
                        ], default: .init())
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply0.carePlan.audit.updatedBy
                }
                $0.careGoalID = input.careGoalID
                $0.subject = input.careGoal.subject
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply2.result.status
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processRecalculateCareGoals(_ input: Acme_Careplans_V1_RecalculateCareGoalsRequest) async throws
        -> Acme_Careplans_V1_RecalculateCareGoalsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.careGoal.assignee.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "audit", detail: input.careGoal.assignee.email
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "RecalculateCareGoals",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CareGoalRecord(input.careGoal, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Concessions_V1_SimulateConcessionStandRequest.with {
            $0.concessionStand = Acme_Concessions_V1_ConcessionStand.with {
                $0.address = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.details.destination.region
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.careGoal.audit.createdAt
                }
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.careGoal.assignee.userID
                }
            }
            $0.context = input.context
            $0.details = Acme_Concessions_V1_SimulateConcessionStandRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.lines = input.details.destination.lines
                }
            }
        }
        async let remote0 = self.concessionsConcessionStandCalculation.simulateConcessionStand(outbound0)
        async let persisted0 = store.count(tenant: input.context.tenantID)
        let (reply0, count0) = try await (remote0, persisted0)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count0)])
        let selection1_1: String
        switch reply0.concessionStand.locator {
        case .address(let address):
            selection1_1 = address.region
        default: selection1_1 = .init()
        }
        let outbound1 = Acme_Careplans_V1_EstimateCarePlanRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply0.concessionStand.audit.createdAt
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = selection1_1
                }
                $0.counterparty = Acme_Appointments_V1_AppointmentRef.with {
                    $0.displayName = input.careGoal.assignee.displayName
                }
            }
            $0.context = input.context
        }
        let reply1 = try await self.careplansCarePlanCalculation.estimateCarePlan(outbound1)
        return Acme_Careplans_V1_RecalculateCareGoalsResponse.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.email = reply0.concessionStand.owner.email
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply1.carePlan.audit.etag
                }
                $0.careGoalID = input.careGoalID
                $0.customFields = input.careGoal.customFields
                $0.tags = reply0.concessionStand.tags
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processSimulateCareGoal(_ input: Acme_Careplans_V1_SimulateCareGoalRequest) async throws
        -> Acme_Careplans_V1_SimulateCareGoalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.careGoal.assignee.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "audit", detail: input.careGoal.assignee.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SimulateCareGoal",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CareGoalRecord(input.careGoal, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Careplans_V1_CalculateCarePlanRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.locality = input.details.destination.locality
                }
            }
            $0.context = input.context
            $0.details = Acme_Careplans_V1_CalculateCarePlanRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.lines = input.details.destination.lines
                }
            }
        }
        let reply0 = try await self.simulateCareGoalStep0.execute(outbound0)
        let selection1_1: String
        switch input.careGoal.origin {
        case .customer(let customer):
            selection1_1 = customer.displayName
        default: selection1_1 = .init()
        }
        let selection1_4: String
        switch reply0.carePlan.settlement {
        case .card(let card):
            selection1_4 = card.network
        default: selection1_4 = .init()
        }
        let outbound1 = Acme_Careplans_V1_QuoteCarePlanRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.lines = reply0.carePlan.billingAddress.lines
                }
                $0.card = Acme_Careplans_V1_CarePlanCardSettlement.with {
                    $0.network = selection1_4
                }
                $0.counterparty = Acme_Appointments_V1_AppointmentRef.with {
                    $0.displayName = selection1_1
                }
            }
            $0.context = input.context
            $0.details = Acme_Careplans_V1_QuoteCarePlanRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = reply0.carePlan.billingAddress.postalCode
                }
            }
        }
        let reply1 = try await self.careplansCarePlanCalculation.quoteCarePlan(outbound1)
        return Acme_Careplans_V1_SimulateCareGoalResponse.with {
            $0.breakdown = Acme_Careplans_V1_SimulateCareGoalResponse.Breakdown.with {
                $0.total = reply1.carePlan.total
            }
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply0.carePlan.audit.etag
                }
                $0.careGoalID = input.careGoalID
                $0.comments = [
                    Acme_Careplans_V1_CareGoalComment.with {
                        $0.createdAt = reply0.carePlan.audit.createdAt
                    }
                ]
                $0.priority = input.careGoal.priority
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply1.result.details
                $0.status = "ok"
            }
        }
    }
}
