import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension TriageCalculationEndpoint {
    /// Execute the telehealth workflow and project its upstream replies.
    func processCalculateTriage(_ input: Acme_Telehealth_V1_CalculateTriageRequest) async throws
        -> Acme_Telehealth_V1_CalculateTriageResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.currencyCode)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "triage",
            action: "audit", detail: input.details.currencyCode
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "CalculateTriage",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try TriageRecord(input.triage, tenant: input.context.tenantID)
        try await store.save(record.stored)
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
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
        let outbound0 = Acme_Careplans_V1_FindCareGoalsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Careplans_V1_FindCareGoalsRequest.Filter.with {
                $0.createdAfter = input.triage.audit.updatedAt
                $0.labels = input.triage.customFields
                $0.ownerID = input.triage.assignee.userID
                $0.region = input.details.destination.region
            }
        }
        let reply0 = try await self.careplansCareGoalQuery.findCareGoals(outbound0)
        let outbound1 = Acme_Telehealth_V1_ValidateVideoVisitRequest.with {
            $0.context = input.context
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.participants = [
                    Acme_Telehealth_V1_VideoVisitParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = input.triage.requester.email
                        }
                    }
                ]
            }
        }
        let envelope1 = try Google_Protobuf_Any(message: outbound1)
        let unpacked1 = try Acme_Telehealth_V1_ValidateVideoVisitRequest(unpackingAny: envelope1)
        let reply1 = try await self.telehealthVideoVisitValidation.validateVideoVisit(unpacked1)
        return Acme_Telehealth_V1_CalculateTriageResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.status = "ok"
            }
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply1.videoVisit.audit.etag
                }
                $0.customFields = input.triage.customFields
                $0.triageID = input.triageID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processCompareTriageOptions(_ input: Acme_Telehealth_V1_CompareTriageOptionsRequest) async throws
        -> Acme_Telehealth_V1_CompareTriageOptionsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.destination.countryCode)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "triage",
            action: "audit", detail: input.details.destination.countryCode
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "CompareTriageOptions",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try TriageRecord(input.triage, tenant: input.context.tenantID)
        try await store.save(record.stored)
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        let outbound0 = Acme_Telehealth_V1_QuoteVisitNoteRequest.with {
            $0.context = input.context
            $0.details = Acme_Telehealth_V1_QuoteVisitNoteRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = input.details.destination.postalCode
                    $0.recipient = input.details.destination.recipient
                }
            }
        }
        let json0 = try outbound0.jsonString()
        let decoded0 = try Acme_Telehealth_V1_QuoteVisitNoteRequest(jsonString: json0)
        let reply0 = try await self.telehealthVisitNoteCalculation.quoteVisitNote(decoded0)
        return Acme_Telehealth_V1_CompareTriageOptionsResponse.with {
            $0.breakdown = Acme_Telehealth_V1_CompareTriageOptionsResponse.Breakdown.with {
                $0.currencyCode = input.details.currencyCode
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply0.visitNote.counterparty.email
                }
                $0.triageID = input.triageID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processEstimateTriage(_ input: Acme_Telehealth_V1_EstimateTriageRequest) async throws
        -> Acme_Telehealth_V1_EstimateTriageResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.currencyCode)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "triage",
            action: "audit", detail: input.details.currencyCode
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "EstimateTriage",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try TriageRecord(input.triage, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Metrics_V1_CloneMetricSeriesRequest.forTriageCalculationEndpointEstimateTriage0(
            input
        )
        let reply0 = try await self.metricsMetricSeries.cloneMetricSeries(outbound0)
        let selection1_1: String
        switch input.triage.origin {
        case .channel(let channel):
            selection1_1 = channel.channel
        default: selection1_1 = .init()
        }
        let outbound1 = Acme_Careplans_V1_CalculateCareGoalRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.userID = reply0.metricSeries.owner.userID
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = input.triage.audit.updatedAt
                }
                $0.channel = Acme_Careplans_V1_CareGoalChannelOrigin.with {
                    $0.channel = selection1_1
                }
            }
            $0.context = input.context
            $0.details = Acme_Careplans_V1_CalculateCareGoalRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = input.details.destination.countryCode
                }
            }
        }
        let reply1 = try await self.careplansCareGoalCalculation.calculateCareGoal(outbound1)
        let outbound2 = Acme_Telehealth_V1_ExplainVideoVisitDecisionRequest.with {
            $0.context = input.context
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.participants = [
                    Acme_Telehealth_V1_VideoVisitParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = reply1.careGoal.requester.email
                        }
                    }
                ]
            }
        }
        let reply2 = try await self.telehealthVideoVisitValidation.explainVideoVisitDecision(
            outbound2, metadata: ["x-acme-region": .string(settings.region)]
        )
        return Acme_Telehealth_V1_EstimateTriageResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply2.videoVisit.audit.updatedAt
                    $0.updatedBy = reply2.videoVisit.audit.updatedBy
                }
                $0.priority = input.triage.priority
                $0.tags = reply1.careGoal.tags
                $0.triageID = input.triageID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processExplainTriageCalculation(_ input: Acme_Telehealth_V1_ExplainTriageCalculationRequest) async throws
        -> Acme_Telehealth_V1_ExplainTriageCalculationResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "triage",
            action: "audit", detail: input.details.contact.email
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ExplainTriageCalculation",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try TriageRecord(input.triage, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Telehealth_V1_CalculateVisitNoteRequest.with {
            $0.context = input.context
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.email = input.triage.requester.email
                }
            }
        }
        let reply0 = try await RPCOperations.call(outbound0) { request in
            try await self.telehealthVisitNoteCalculation.calculateVisitNote(request)
        }
        let outbound1 = Acme_Careplans_V1_ResolveCareGoalsRequest.with {
            $0.context = Projection.read(input, at: \Acme_Telehealth_V1_ExplainTriageCalculationRequest.context)
        }
        let reply1 = try await self.careplansCareGoalQuery.resolveCareGoals(outbound1)
        return Acme_Telehealth_V1_ExplainTriageCalculationResponse.with {
            $0.outcome = Acme_Telehealth_V1_ExplainTriageCalculationResponse.Outcome.with {
                $0.status = reply1.result.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.message = reply0.result.message
                $0.status = reply1.result.status
            }
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.subject = input.triage.subject
                $0.triageID = input.triageID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processGetTriageRates(_ input: Acme_Telehealth_V1_GetTriageRatesRequest) async throws
        -> Acme_Telehealth_V1_GetTriageRatesResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "GetTriageRates",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "triage",
            action: "GetTriageRates", detail: input.context.traceID
        )
        let outbound0 = Acme_Careplans_V1_SimulateCarePlanRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.counterparty = Acme_Appointments_V1_AppointmentRef.with {
                    $0.startsAt = input.context.deadline
                }
                $0.lines = [
                    Acme_Careplans_V1_CarePlanLine.with {
                        $0.attributes = input.context.baggage
                    }
                ]
            }
            $0.context = input.context
        }
        let step0: @Sendable () async throws -> Acme_Careplans_V1_SimulateCarePlanResponse = {
            try await self.careplansCarePlanCalculation.simulateCarePlan(outbound0)
        }
        let reply0 = try await step0()
        return Acme_Telehealth_V1_GetTriageRatesResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.status = "ok"
            }
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.triageID = input.triageID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processQuoteTriage(_ input: Acme_Telehealth_V1_QuoteTriageRequest) async throws
        -> Acme_Telehealth_V1_QuoteTriageResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.currencyCode)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "triage",
            action: "audit", detail: input.details.currencyCode
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "QuoteTriage",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try TriageRecord(input.triage, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let selection0_1: String
        switch input.triage.origin {
        case .customer(let customer):
            selection0_1 = customer.displayName
        default: selection0_1 = .init()
        }
        let outbound0 = Acme_Careplans_V1_ExplainCarePlanDecisionRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.counterparty = Acme_Appointments_V1_AppointmentRef.with {
                    $0.displayName = selection0_1
                }
            }
            $0.context = input.context
        }
        let reply0 = try await self.careplansCarePlanValidation.explainCarePlanDecision(outbound0)
        return Acme_Telehealth_V1_QuoteTriageResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply0.carePlan.audit.createdBy
                }
                $0.status = input.triage.status
                $0.triageID = input.triageID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processRecalculateTriages(_ input: Acme_Telehealth_V1_RecalculateTriagesRequest) async throws
        -> Acme_Telehealth_V1_RecalculateTriagesResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.currencyCode)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "triage",
            action: "audit", detail: input.details.currencyCode
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "RecalculateTriages",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try TriageRecord(input.triage, tenant: input.context.tenantID)
        try await store.save(record.stored)
        var outbound0 = Acme_Telehealth_V1_EstimateVideoVisitRequest()
        outbound0.context = input.context
        outbound0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
            $0.audit = Acme_Common_V1_AuditInfo.with {
                $0.createdBy = input.triage.audit.createdBy
            }
        }
        let reply0 = try await self.telehealthVideoVisitCalculation.estimateVideoVisit(outbound0)
        let outbound1 = Acme_Careplans_V1_ValidateVitalRequest.with {
            $0.context = input.context
            $0.details = Acme_Careplans_V1_ValidateVitalRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply0.videoVisit.organizer.email
                    $0.name = input.triage.requester.name
                }
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.subject = Acme_Appointments_V1_AppointmentRef.with {
                    $0.displayName = reply0.videoVisit.organizer.displayName
                }
            }
        }
        let step1: @Sendable () async throws -> Acme_Careplans_V1_ValidateVitalResponse = {
            try await self.careplansVitalValidation.validateVital(outbound1)
        }
        let reply1 = try await step1()
        let outbound2 = Acme_Telehealth_V1_PreviewVideoVisitRequest.with {
            $0.context = input.context
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply0.videoVisit.audit.createdBy
                    $0.updatedBy = reply0.videoVisit.audit.updatedBy
                }
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.email = reply0.videoVisit.organizer.email
                }
                $0.participants = [
                    Acme_Telehealth_V1_VideoVisitParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = input.triage.assignee.email
                        }
                    }
                ]
            }
        }
        let reply2 = try await self.telehealthVideoVisitValidation.previewVideoVisit(outbound2)
        return Acme_Telehealth_V1_RecalculateTriagesResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.message = Projection.firstValue(
                    [
                        reply0.result.message,
                        reply1.result.message,
                    ], default: .init())
                $0.status = "ok"
            }
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.assignee = input.triage.assignee
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply2.videoVisit.audit.updatedBy
                }
                $0.triageID = input.triageID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processSimulateTriage(_ input: Acme_Telehealth_V1_SimulateTriageRequest) async throws
        -> Acme_Telehealth_V1_SimulateTriageResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.currencyCode)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "triage",
            action: "audit", detail: input.details.currencyCode
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SimulateTriage",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try TriageRecord(input.triage, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let requests0 = input.triage.comments.map { element in
            Acme_Featureflags_V1_ValidateFeatureFlagRequest.with {
                $0.context = input.context
                $0.featureFlag = Acme_Featureflags_V1_FeatureFlag.with {
                    $0.audit = Acme_Common_V1_AuditInfo.with {
                        $0.createdAt = element.createdAt
                    }
                    $0.block = Acme_Featureflags_V1_FeatureFlagBlockAction.with {
                        $0.notifyEmail = element.authorEmail
                    }
                    $0.owner = Acme_Identity_V1_UserRef.with {
                        $0.displayName = input.triage.assignee.displayName
                    }
                }
            }
        }
        let replies0 = try await FanOut.map(requests0) { candidate in
            try await self.featureflagsFeatureFlagValidation.validateFeatureFlag(candidate)
        }
        let reply0 = replies0.first ?? Acme_Featureflags_V1_ValidateFeatureFlagResponse()
        _ = reply0
        let requests1 = input.triage.comments.map { element in
            Acme_Careplans_V1_WatchCarePlansRequest.with {
                $0.context = input.context
                $0.filter = Acme_Careplans_V1_WatchCarePlansRequest.Filter.with {
                    $0.createdAfter = element.createdAt
                }
                $0.subscriber = Acme_Common_V1_ContactInfo.with {
                    $0.email = element.authorEmail
                }
            }
        }
        let replies1 = try await FanOut.map(requests1) { candidate in
            let streamReply = try await self.careplansCarePlan.watchCarePlans(candidate) { response in
                var latest = Acme_Careplans_V1_WatchCarePlansResponse()
                for try await message in response.messages {
                    latest = message
                }
                return latest
            }
            return streamReply
        }
        let reply1 = replies1.first ?? Acme_Careplans_V1_WatchCarePlansResponse()
        _ = reply1
        return Acme_Telehealth_V1_SimulateTriageResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.customFields = input.triage.customFields
                $0.triageID = input.triageID
            }
        }
    }
}
