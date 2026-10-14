import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension CareGoalValidationEndpoint {
    /// Checks a care goal.
    func checkCareGoalEligibility(
        request: ServerRequest<Acme_Careplans_V1_CheckCareGoalEligibilityRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_CheckCareGoalEligibilityResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCheckCareGoalEligibility(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Explains a care goal.
    func explainCareGoalDecision(
        request: ServerRequest<Acme_Careplans_V1_ExplainCareGoalDecisionRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_ExplainCareGoalDecisionResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processExplainCareGoalDecision(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a care goal.
    func getCareGoalRules(
        request: ServerRequest<Acme_Careplans_V1_GetCareGoalRulesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_GetCareGoalRulesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetCareGoalRules(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lints a care goal.
    func lintCareGoals(
        request: ServerRequest<Acme_Careplans_V1_LintCareGoalsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_LintCareGoalsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processLintCareGoals(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Normalizes a care goal.
    func normalizeCareGoal(
        request: ServerRequest<Acme_Careplans_V1_NormalizeCareGoalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_NormalizeCareGoalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processNormalizeCareGoal(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Previews a care goal.
    func previewCareGoal(
        request: ServerRequest<Acme_Careplans_V1_PreviewCareGoalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_PreviewCareGoalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processPreviewCareGoal(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Scores a care goal.
    func scoreCareGoal(
        request: ServerRequest<Acme_Careplans_V1_ScoreCareGoalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_ScoreCareGoalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processScoreCareGoal(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Validates a care goal.
    func validateCareGoal(
        request: ServerRequest<Acme_Careplans_V1_ValidateCareGoalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_ValidateCareGoalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processValidateCareGoal(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processCheckCareGoalEligibility(_ input: Acme_Careplans_V1_CheckCareGoalEligibilityRequest) async throws
        -> Acme_Careplans_V1_CheckCareGoalEligibilityResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.careGoal.audit.createdBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "audit", detail: input.careGoal.audit.createdBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "CheckCareGoalEligibility",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CareGoalRecord(input.careGoal, tenant: input.context.tenantID)
        try await store.save(record.stored)
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        let selection0_2: String
        switch input.careGoal.origin {
        case .channel(let channel):
            selection0_2 = channel.address
        default: selection0_2 = .init()
        }
        let outbound0 = Acme_Careplans_V1_CalculateCareGoalRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.careGoal.audit.createdAt
                }
                $0.channel = Acme_Careplans_V1_CareGoalChannelOrigin.with {
                    $0.address = selection0_2
                }
                $0.sla = Acme_Careplans_V1_CareGoalSla.with {
                    $0.breached = input.careGoal.sla.breached
                }
            }
            $0.context = input.context
        }
        let reply0 = try await self.careplansCareGoalCalculation.calculateCareGoal(outbound0)
        return Acme_Careplans_V1_CheckCareGoalEligibilityResponse.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.assignee = input.careGoal.assignee
                $0.careGoalID = input.careGoalID
                $0.comments = [
                    Acme_Careplans_V1_CareGoalComment.with {
                        $0.createdAt = reply0.careGoal.audit.createdAt
                    }
                ]
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processExplainCareGoalDecision(_ input: Acme_Careplans_V1_ExplainCareGoalDecisionRequest) async throws
        -> Acme_Careplans_V1_ExplainCareGoalDecisionResponse
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
            "ExplainCareGoalDecision",
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
        let selection0_3: String
        switch input.careGoal.origin {
        case .customer(let customer):
            selection0_3 = customer.displayName
        default: selection0_3 = .init()
        }
        let outbound0 = Acme_Ledger_V1_LintLedgerAccountsRequest.with {
            $0.context = input.context
            $0.details = Acme_Ledger_V1_LintLedgerAccountsRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.careGoal.assignee.email
                }
            }
            $0.ledgerAccount = Acme_Ledger_V1_LedgerAccount.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.preferredChannel = input.careGoal.requester.preferredChannel
                }
                $0.holder = Acme_Ledger_V1_PostingBatchRef.with {
                    $0.displayName = selection0_3
                }
            }
        }
        let reply0 = try await self.ledgerLedgerAccountValidation.lintLedgerAccounts(outbound0)
        let selection1_1: String
        switch input.careGoal.origin {
        case .customer(let customer):
            selection1_1 = customer.patientID
        default: selection1_1 = .init()
        }
        let outbound1 = Acme_Careplans_V1_ExplainCareGoalCalculationRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.customer = Acme_Patients_V1_PatientRef.with {
                    $0.patientID = selection1_1
                }
            }
            $0.context = input.context
            $0.details = Acme_Careplans_V1_ExplainCareGoalCalculationRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.preferredChannel = input.details.contact.preferredChannel
                }
            }
        }
        let reply1 = try await self.careplansCareGoalCalculation.explainCareGoalCalculation(outbound1)
        return Acme_Careplans_V1_ExplainCareGoalDecisionResponse.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.careGoalID = input.careGoalID
                $0.requester = input.careGoal.requester
            }
            $0.outcome = Acme_Careplans_V1_ExplainCareGoalDecisionResponse.Outcome.with {
                $0.message = reply0.outcome.message
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply1.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processGetCareGoalRules(_ input: Acme_Careplans_V1_GetCareGoalRulesRequest) async throws
        -> Acme_Careplans_V1_GetCareGoalRulesResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "GetCareGoalRules",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "GetCareGoalRules", detail: input.context.traceID
        )
        let outbound0 = Acme_Careplans_V1_LintCarePlansRequest.with {
            $0.context = input.context
            $0.details = Acme_Careplans_V1_LintCarePlansRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.context.actor.email
                }
                $0.locale = input.context.locale
            }
        }
        guard let execute0 = self.getCareGoalRulesStep0[settings.region] ?? self.getCareGoalRulesStep0["primary"] else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply0 = try await execute0(outbound0)
        return Acme_Careplans_V1_GetCareGoalRulesResponse.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply0.carePlan.audit.updatedAt
                }
                $0.careGoalID = input.careGoalID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply0.result.status
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processLintCareGoals(_ input: Acme_Careplans_V1_LintCareGoalsRequest) async throws
        -> Acme_Careplans_V1_LintCareGoalsResponse
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
            "LintCareGoals",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CareGoalRecord(input.careGoal, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let selection0_4: String
        switch input.careGoal.origin {
        case .customer(let customer):
            selection0_4 = customer.displayName
        default: selection0_4 = .init()
        }
        let outbound0 = Acme_Metrics_V1_ValidateMetricSeriesRequest.with {
            $0.context = input.context
            $0.details = Acme_Metrics_V1_ValidateMetricSeriesRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.careGoal.requester.email
                    $0.preferredChannel = input.details.contact.preferredChannel
                }
            }
            $0.metricSeries = Acme_Metrics_V1_MetricSeries.with {
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.displayName = selection0_4
                    $0.email = input.careGoal.assignee.email
                }
            }
        }
        let reply0 = try await self.metricsMetricSeriesValidation.validateMetricSeries(outbound0)
        let outbound1 = Acme_Careplans_V1_SimulateCareGoalRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.userID = reply0.metricSeries.owner.userID
                }
            }
            $0.context = input.context
        }
        let reply1 = try await self.careplansCareGoalCalculation.simulateCareGoal(outbound1)
        return Acme_Careplans_V1_LintCareGoalsResponse.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply0.metricSeries.audit.createdAt
                }
                $0.careGoalID = input.careGoalID
                $0.sla = Acme_Careplans_V1_CareGoalSla.with {
                    $0.policyID = reply1.careGoal.sla.policyID
                }
                $0.status = input.careGoal.status
            }
            $0.outcome = Acme_Careplans_V1_LintCareGoalsResponse.Outcome.with {
                $0.referenceID = reply0.outcome.referenceID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processNormalizeCareGoal(_ input: Acme_Careplans_V1_NormalizeCareGoalRequest) async throws
        -> Acme_Careplans_V1_NormalizeCareGoalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.careGoal.audit.createdBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "audit", detail: input.careGoal.audit.createdBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "NormalizeCareGoal",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CareGoalRecord(input.careGoal, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Careplans_V1_SimulateCareGoalRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.email = input.careGoal.assignee.email
                }
                $0.customer = Acme_Patients_V1_PatientRef.with {
                    $0.email = input.details.contact.email
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.name = input.careGoal.requester.name
                }
            }
            $0.context = input.context
        }
        let envelope0 = try Google_Protobuf_Any(message: outbound0)
        let unpacked0 = try Acme_Careplans_V1_SimulateCareGoalRequest(unpackingAny: envelope0)
        let reply0 = try await self.careplansCareGoalCalculation.simulateCareGoal(unpacked0)
        let outbound1 = Acme_Careplans_V1_ExplainCareGoalCalculationRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = input.careGoal.audit.etag
                    $0.updatedAt = input.careGoal.audit.updatedAt
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.careGoal.requester.email
                }
                $0.sla = Acme_Careplans_V1_CareGoalSla.with {
                    $0.pausedFor = reply0.careGoal.sla.pausedFor
                }
            }
            $0.context = input.context
        }
        let json1 = try outbound1.jsonString()
        let decoded1 = try Acme_Careplans_V1_ExplainCareGoalCalculationRequest(jsonString: json1)
        let reply1 = try await self.careplansCareGoalCalculation.explainCareGoalCalculation(decoded1)
        return Acme_Careplans_V1_NormalizeCareGoalResponse.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.assignee = input.careGoal.assignee
                $0.careGoalID = input.careGoalID
                $0.customFields = reply0.careGoal.customFields
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.details = reply1.result.details
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processPreviewCareGoal(_ input: Acme_Careplans_V1_PreviewCareGoalRequest) async throws
        -> Acme_Careplans_V1_PreviewCareGoalResponse
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
            "PreviewCareGoal",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CareGoalRecord(input.careGoal, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let requests0 = input.careGoal.history.map { element in
            Acme_Careplans_V1_ExplainCarePlanCalculationRequest.with {
                $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                    $0.audit = Acme_Common_V1_AuditInfo.with {
                        $0.updatedAt = input.careGoal.audit.updatedAt
                    }
                    $0.counterparty = Acme_Appointments_V1_AppointmentRef.with {
                        $0.startsAt = element.changedAt
                    }
                }
                $0.context = input.context
                $0.details = Acme_Careplans_V1_ExplainCarePlanCalculationRequest.Details.with {
                    $0.contact = Acme_Common_V1_ContactInfo.with {
                        $0.email = input.careGoal.requester.email
                    }
                }
            }
        }
        let replies0 = try await FanOut.map(requests0) { candidate in
            try await self.careplansCarePlanCalculation.explainCarePlanCalculation(candidate)
        }
        let reply0 = replies0.first ?? Acme_Careplans_V1_ExplainCarePlanCalculationResponse()
        let requests1 = input.careGoal.comments.map { element in
            Acme_Boxoffice_V1_CountBoxOfficeSalesRequest.with {
                $0.context = input.context
                $0.filter = Acme_Boxoffice_V1_CountBoxOfficeSalesRequest.Filter.with {
                    $0.createdAfter = element.createdAt
                    $0.region = reply0.carePlan.billingAddress.region
                }
            }
        }
        let replies1 = try await FanOut.map(requests1) { candidate in
            try await self.boxofficeBoxOfficeSaleQuery.countBoxOfficeSales(candidate)
        }
        let reply1 = replies1.first ?? Acme_Boxoffice_V1_CountBoxOfficeSalesResponse()
        _ = reply1
        return Acme_Careplans_V1_PreviewCareGoalResponse.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.careGoalID = input.careGoalID
                $0.status = input.careGoal.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processScoreCareGoal(_ input: Acme_Careplans_V1_ScoreCareGoalRequest) async throws
        -> Acme_Careplans_V1_ScoreCareGoalResponse
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
            "ScoreCareGoal",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CareGoalRecord(input.careGoal, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Careplans_V1_CalculateCareGoalRequest.forCareGoalValidationEndpointScoreCareGoal0(
            input
        )
        let reply0 = try await self.careplansCareGoalCalculation.calculateCareGoal(outbound0)
        let selection1_3: String
        switch reply0.careGoal.origin {
        case .customer(let customer):
            selection1_3 = customer.patientID
        default: selection1_3 = .init()
        }
        let outbound1 = Acme_Boxoffice_V1_ListBoxOfficeSalesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Boxoffice_V1_ListBoxOfficeSalesRequest.Filter.with {
                $0.createdAfter = reply0.careGoal.audit.createdAt
                $0.labels = reply0.careGoal.customFields
                $0.ownerID = selection1_3
                $0.region = input.details.destination.region
            }
        }
        let reply1 = try await self.boxofficeBoxOfficeSale.listBoxOfficeSales(outbound1)
        let outbound2 = Acme_Boxoffice_V1_SuggestBoxOfficeSalesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Boxoffice_V1_SuggestBoxOfficeSalesRequest.Filter.with {
                $0.region = input.details.destination.region
            }
        }
        let reply2 = try await self.boxofficeBoxOfficeSaleQuery.suggestBoxOfficeSales(
            outbound2, metadata: ["x-acme-region": .string(settings.region)]
        )
        return Acme_Careplans_V1_ScoreCareGoalResponse.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply0.careGoal.audit.updatedAt
                }
                $0.careGoalID = input.careGoalID
                $0.customFields = input.careGoal.customFields
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply0.careGoal.customer.email
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply2.result.correlationID
                $0.message = reply1.result.message
                $0.referenceIds = reply1.result.referenceIds
                $0.status = reply2.result.status
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processValidateCareGoal(_ input: Acme_Careplans_V1_ValidateCareGoalRequest) async throws
        -> Acme_Careplans_V1_ValidateCareGoalResponse
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
            "ValidateCareGoal",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CareGoalRecord(input.careGoal, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Careplans_V1_ExplainCarePlanDecisionRequest.with {
            $0.context = input.context
            $0.details = Acme_Careplans_V1_ExplainCarePlanDecisionRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.name = input.details.contact.name
                    $0.phone = input.careGoal.requester.phone
                }
            }
        }
        let reply0 = try await RPCOperations.call(outbound0) { request in
            try await self.careplansCarePlanValidation.explainCarePlanDecision(request)
        }
        let requests1 = input.careGoal.history.map { element in
            Acme_Careplans_V1_RecalculateCareGoalsRequest.with {
                $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                    $0.history = [
                        Acme_Careplans_V1_CareGoalStatusChange.with {
                            $0.changedAt = element.changedAt
                            $0.changedBy = element.changedBy
                            $0.fromStatus = element.fromStatus
                            $0.toStatus = element.toStatus
                        }
                    ]
                }
                $0.context = input.context
            }
        }
        let replies1 = try await FanOut.map(requests1) { candidate in
            try await self.careplansCareGoalCalculation.recalculateCareGoals(candidate)
        }
        let reply1 = replies1.first ?? Acme_Careplans_V1_RecalculateCareGoalsResponse()
        _ = reply1
        return Acme_Careplans_V1_ValidateCareGoalResponse.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply0.carePlan.audit.createdBy
                }
                $0.careGoalID = input.careGoalID
                $0.status = input.careGoal.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }
}
