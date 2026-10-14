import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension RefillValidationEndpoint {
    /// Execute the prescriptions workflow and project its upstream replies.
    func processCheckRefillEligibility(_ input: Acme_Prescriptions_V1_CheckRefillEligibilityRequest) async throws
        -> Acme_Prescriptions_V1_CheckRefillEligibilityResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "audit", detail: input.details.contact.email
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "CheckRefillEligibility",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try RefillRecord(input.refill, tenant: input.context.tenantID)
        try await store.save(record.stored)
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        let importFrame = Acme_Telehealth_V1_BatchCreateVideoVisitsRequest.with {
            $0.context = input.context
        }
        _ = try await self.telehealthVideoVisit.batchCreateVideoVisits { writer in
            try await writer.write(importFrame)
        }
        let requests0 = input.refill.history.map { element in
            Acme_Authorization_V1_CountAccessPoliciesRequest.with {
                $0.context = input.context
                $0.filter = Acme_Authorization_V1_CountAccessPoliciesRequest.Filter.with {
                    $0.createdAfter = element.changedAt
                    $0.ownerID = input.refillID
                }
            }
        }
        let replies0 = try await FanOut.map(requests0) { candidate in
            try await self.authorizationAccessPolicyQuery.countAccessPolicies(candidate)
        }
        let reply0 = replies0.first ?? Acme_Authorization_V1_CountAccessPoliciesResponse()
        _ = reply0
        let selection1_1: String
        switch input.refill.origin {
        case .customer(let customer):
            selection1_1 = customer.number
        default: selection1_1 = .init()
        }
        let outbound1 = Acme_Notifications_V1_ValidateNotificationRequest.with {
            $0.context = input.context
            $0.notification = Acme_Notifications_V1_Notification.with {
                $0.customer = Acme_Notifications_V1_NotificationTemplateRef.with {
                    $0.number = selection1_1
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.refill.assignee.email
                    $0.name = input.refill.requester.name
                }
            }
        }
        let reply1 = try await self.notificationsNotificationValidation.validateNotification(outbound1)
        let selection2_2: String
        switch input.refill.origin {
        case .customer(let customer):
            selection2_2 = customer.number
        default: selection2_2 = .init()
        }
        let outbound2 = Acme_Prescriptions_V1_CompareRefillOptionsRequest.with {
            $0.context = input.context
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = input.refill.audit.updatedAt
                }
                $0.customer = Acme_Prescriptions_V1_PrescriptionRef.with {
                    $0.displayName = reply1.notification.assignee.displayName
                    $0.number = selection2_2
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply1.notification.assignee.email
                }
            }
        }
        let reply2 = try await self.prescriptionsRefillCalculation.compareRefillOptions(outbound2)
        return Acme_Prescriptions_V1_CheckRefillEligibilityResponse.with {
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply1.notification.audit.createdBy
                }
                $0.priority = input.refill.priority
                $0.refillID = input.refillID
                $0.requester = reply2.refill.requester
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processExplainRefillDecision(_ input: Acme_Prescriptions_V1_ExplainRefillDecisionRequest) async throws
        -> Acme_Prescriptions_V1_ExplainRefillDecisionResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "audit", detail: input.details.contact.email
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ExplainRefillDecision",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try RefillRecord(input.refill, tenant: input.context.tenantID)
        try await store.save(record.stored)
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        let requests0 = input.refill.history.map { element in
            Acme_Metrics_V1_SuggestMetricSeriesesRequest.with {
                $0.context = input.context
                $0.filter = Acme_Metrics_V1_SuggestMetricSeriesesRequest.Filter.with {
                    $0.createdAfter = element.changedAt
                }
            }
        }
        let replies0 = try await FanOut.map(requests0) { candidate in
            try await self.metricsMetricSeriesQuery.suggestMetricSerieses(candidate)
        }
        let reply0 = replies0.first ?? Acme_Metrics_V1_SuggestMetricSeriesesResponse()
        _ = reply0
        return Acme_Prescriptions_V1_ExplainRefillDecisionResponse.with {
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.refillID = input.refillID
                $0.subject = input.refill.subject
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processGetRefillRules(_ input: Acme_Prescriptions_V1_GetRefillRulesRequest) async throws
        -> Acme_Prescriptions_V1_GetRefillRulesResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "GetRefillRules",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "GetRefillRules", detail: input.context.traceID
        )
        let outbound0 = Acme_Metrics_V1_NormalizeMetricSeriesRequest.with {
            $0.context = input.context
            $0.details = Acme_Metrics_V1_NormalizeMetricSeriesRequest.Details.with {
                $0.locale = input.context.locale
            }
            $0.metricSeries = Acme_Metrics_V1_MetricSeries.with {
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.email = input.context.actor.email
                    $0.userID = input.context.actor.userID
                }
            }
        }
        let envelope0 = try Google_Protobuf_Any(message: outbound0)
        let unpacked0 = try Acme_Metrics_V1_NormalizeMetricSeriesRequest(unpackingAny: envelope0)
        let reply0 = try await self.metricsMetricSeriesValidation.normalizeMetricSeries(unpacked0)
        let outbound1 = Acme_Prescriptions_V1_PreviewMedicationRequest.with {
            $0.context = input.context
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply0.metricSeries.audit.etag
                }
            }
        }
        let json1 = try outbound1.jsonString()
        let decoded1 = try Acme_Prescriptions_V1_PreviewMedicationRequest(jsonString: json1)
        let reply1 = try await self.prescriptionsMedicationValidation.previewMedication(decoded1)
        return Acme_Prescriptions_V1_GetRefillRulesResponse.with {
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply0.metricSeries.audit.createdAt
                }
                $0.refillID = input.refillID
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply1.medication.owner.email
                }
                $0.tags = reply0.metricSeries.tags
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply1.result.details
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processLintRefills(_ input: Acme_Prescriptions_V1_LintRefillsRequest) async throws
        -> Acme_Prescriptions_V1_LintRefillsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "audit", detail: input.details.contact.email
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "LintRefills",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try RefillRecord(input.refill, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Metrics_V1_SummarizeMetricSeriesesRequest.forRefillValidationEndpointLintRefills0(
            input
        )
        let reply0 = try await self.metricsMetricSeriesQuery.summarizeMetricSerieses(outbound0)
        let requests1 = input.refill.comments.map { element in
            Acme_Notifications_V1_ScoreNotificationRequest.with {
                $0.context = input.context
                $0.notification = Acme_Notifications_V1_Notification.with {
                    $0.audit = Acme_Common_V1_AuditInfo.with {
                        $0.createdAt = element.createdAt
                    }
                    $0.comments = [
                        Acme_Notifications_V1_NotificationComment.with {
                            $0.commentID = element.commentID
                        }
                    ]
                }
            }
        }
        let replies1 = try await FanOut.map(requests1) { candidate in
            try await self.notificationsNotificationValidation.scoreNotification(candidate)
        }
        let reply1 = replies1.first ?? Acme_Notifications_V1_ScoreNotificationResponse()
        _ = reply1
        return Acme_Prescriptions_V1_LintRefillsResponse.with {
            $0.outcome = Acme_Prescriptions_V1_LintRefillsResponse.Outcome.with {
                $0.message = reply0.result.message
            }
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.refillID = input.refillID
                $0.status = input.refill.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processNormalizeRefill(_ input: Acme_Prescriptions_V1_NormalizeRefillRequest) async throws
        -> Acme_Prescriptions_V1_NormalizeRefillResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "audit", detail: input.details.contact.email
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "NormalizeRefill",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try RefillRecord(input.refill, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Prescriptions_V1_ExplainRefillCalculationRequest.with {
            $0.context = input.context
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.email = input.refill.requester.email
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.phone = input.details.contact.phone
                }
                $0.sla = Acme_Prescriptions_V1_RefillSla.with {
                    $0.breached = input.refill.sla.breached
                }
            }
        }
        let reply0 = try await self.prescriptionsRefillCalculation.explainRefillCalculation(
            outbound0, metadata: ["x-acme-region": .string(settings.region)]
        )
        return Acme_Prescriptions_V1_NormalizeRefillResponse.with {
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply0.refill.audit.updatedAt
                }
                $0.priority = input.refill.priority
                $0.refillID = input.refillID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processPreviewRefill(_ input: Acme_Prescriptions_V1_PreviewRefillRequest) async throws
        -> Acme_Prescriptions_V1_PreviewRefillResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "audit", detail: input.details.contact.email
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "PreviewRefill",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try RefillRecord(input.refill, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let selection0_1: String
        switch input.refill.origin {
        case .customer(let customer):
            selection0_1 = customer.displayName
        default: selection0_1 = .init()
        }
        let outbound0 = Acme_Venues_V1_ScoreVenueRequest.with {
            $0.context = input.context
            $0.venue = Acme_Venues_V1_Venue.with {
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.displayName = selection0_1
                }
            }
        }
        let reply0 = try await self.venuesVenueValidation.scoreVenue(outbound0)
        let requests1 = input.refill.comments.map { element in
            Acme_Prescriptions_V1_CalculatePrescriptionRequest.with {
                $0.context = input.context
                $0.details = Acme_Prescriptions_V1_CalculatePrescriptionRequest.Details.with {
                    $0.destination = Acme_Common_V1_PostalAddress.with {
                        $0.recipient = reply0.venue.address.recipient
                    }
                }
                $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                    $0.audit = Acme_Common_V1_AuditInfo.with {
                        $0.createdAt = element.createdAt
                    }
                    $0.counterparty = Acme_Patients_V1_PatientRef.with {
                        $0.email = element.authorEmail
                    }
                }
            }
        }
        let replies1 = try await FanOut.map(requests1) { candidate in
            try await self.prescriptionsPrescriptionCalculation.calculatePrescription(candidate)
        }
        let reply1 = replies1.first ?? Acme_Prescriptions_V1_CalculatePrescriptionResponse()
        _ = reply1
        return Acme_Prescriptions_V1_PreviewRefillResponse.with {
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.customFields = input.refill.customFields
                $0.refillID = input.refillID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processScoreRefill(_ input: Acme_Prescriptions_V1_ScoreRefillRequest) async throws
        -> Acme_Prescriptions_V1_ScoreRefillResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.currencyCode)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "audit", detail: input.details.currencyCode
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ScoreRefill",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try RefillRecord(input.refill, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let requests0 = input.refill.history.map { element in
            Acme_Search_V1_BrowseSearchIndexesRequest.with {
                $0.context = input.context
                $0.filter = Acme_Search_V1_BrowseSearchIndexesRequest.Filter.with {
                    $0.createdAfter = element.changedAt
                    $0.labels = input.annotations
                    $0.ownerID = input.refill.assignee.userID
                    $0.region = input.details.destination.region
                }
            }
        }
        let replies0 = try await FanOut.map(requests0) { candidate in
            try await self.searchSearchIndexQuery.browseSearchIndexes(candidate)
        }
        let reply0 = replies0.first ?? Acme_Search_V1_BrowseSearchIndexesResponse()
        _ = reply0
        let outbound1 = Acme_Prescriptions_V1_ExplainRefillCalculationRequest.with {
            $0.context = input.context
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.refill.assignee.displayName
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = input.refill.audit.createdBy
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.phone = input.refill.requester.phone
                }
                $0.sla = Acme_Prescriptions_V1_RefillSla.with {
                    $0.dueAt = input.refill.sla.dueAt
                }
            }
        }
        let reply1 = try await RPCOperations.call(outbound1) { request in
            try await self.prescriptionsRefillCalculation.explainRefillCalculation(request)
        }
        return Acme_Prescriptions_V1_ScoreRefillResponse.with {
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.priority = input.refill.priority
                $0.refillID = input.refillID
                $0.subject = reply1.refill.subject
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processValidateRefill(_ input: Acme_Prescriptions_V1_ValidateRefillRequest) async throws
        -> Acme_Prescriptions_V1_ValidateRefillResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "audit", detail: input.details.contact.email
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ValidateRefill",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try RefillRecord(input.refill, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let selection0_2: String
        switch input.refill.origin {
        case .channel(let channel):
            selection0_2 = channel.channel
        default: selection0_2 = .init()
        }
        let outbound0 = Acme_Prescriptions_V1_ExplainRefillCalculationRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_ExplainRefillCalculationRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.name = input.refill.requester.name
                    $0.phone = input.details.contact.phone
                }
            }
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.channel = Acme_Prescriptions_V1_RefillChannelOrigin.with {
                    $0.channel = selection0_2
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.preferredChannel = input.details.contact.preferredChannel
                }
            }
        }
        let reply0 = try await self.prescriptionsRefillCalculation.explainRefillCalculation(outbound0)
        let outbound1 = Acme_Careplans_V1_LintCarePlansRequest.with {
            $0.context = Projection.read(input, at: \Acme_Prescriptions_V1_ValidateRefillRequest.context)
            $0.details = Acme_Careplans_V1_LintCarePlansRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.name = Projection.read(
                        input, at: \Acme_Prescriptions_V1_ValidateRefillRequest.details.contact.name)
                }
            }
        }
        let reply1 = try await self.careplansCarePlanValidation.lintCarePlans(outbound1)
        return Acme_Prescriptions_V1_ValidateRefillResponse.with {
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply0.refill.audit.createdAt
                }
                $0.customFields = input.refill.customFields
                $0.refillID = input.refillID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply1.result.details
                $0.status = reply0.outcome.status
            }
        }
    }
}
