import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension PrescriptionCalculationEndpoint {
    /// Calculates a prescription.
    func calculatePrescription(
        request: ServerRequest<Acme_Prescriptions_V1_CalculatePrescriptionRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_CalculatePrescriptionResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCalculatePrescription(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Compares a prescription.
    func comparePrescriptionOptions(
        request: ServerRequest<Acme_Prescriptions_V1_ComparePrescriptionOptionsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ComparePrescriptionOptionsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processComparePrescriptionOptions(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Estimates a prescription.
    func estimatePrescription(
        request: ServerRequest<Acme_Prescriptions_V1_EstimatePrescriptionRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_EstimatePrescriptionResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processEstimatePrescription(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Explains a prescription.
    func explainPrescriptionCalculation(
        request: ServerRequest<Acme_Prescriptions_V1_ExplainPrescriptionCalculationRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ExplainPrescriptionCalculationResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processExplainPrescriptionCalculation(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a prescription.
    func getPrescriptionRates(
        request: ServerRequest<Acme_Prescriptions_V1_GetPrescriptionRatesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_GetPrescriptionRatesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetPrescriptionRates(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Quotes a prescription.
    func quotePrescription(
        request: ServerRequest<Acme_Prescriptions_V1_QuotePrescriptionRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_QuotePrescriptionResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processQuotePrescription(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Recalculates a prescription.
    func recalculatePrescriptions(
        request: ServerRequest<Acme_Prescriptions_V1_RecalculatePrescriptionsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_RecalculatePrescriptionsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRecalculatePrescriptions(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Simulates a prescription.
    func simulatePrescription(
        request: ServerRequest<Acme_Prescriptions_V1_SimulatePrescriptionRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_SimulatePrescriptionResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSimulatePrescription(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processCalculatePrescription(_ input: Acme_Prescriptions_V1_CalculatePrescriptionRequest) async throws
        -> Acme_Prescriptions_V1_CalculatePrescriptionResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.currencyCode)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "audit", detail: input.details.currencyCode
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "CalculatePrescription",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PrescriptionRecord(input.prescription, tenant: input.context.tenantID)
        try await store.save(record.stored)
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        let importFrame = Acme_Telehealth_V1_BatchCreateVideoVisitsRequest.with {
            $0.context = input.context
        }
        _ = try await self.telehealthVideoVisit.batchCreateVideoVisits { writer in
            try await writer.write(importFrame)
        }
        let outbound0 = Acme_Metrics_V1_UpdateMetricSeriesRequest.with {
            $0.context = input.context
            $0.metricSeries = Acme_Metrics_V1_MetricSeries.with {
                $0.address = Acme_Common_V1_PostalAddress.with {
                    $0.locality = input.prescription.billingAddress.locality
                    $0.recipient = input.details.destination.recipient
                    $0.region = input.prescription.billingAddress.region
                }
            }
        }
        let reply0 = try await self.metricsMetricSeries.updateMetricSeries(outbound0)
        let outbound1 = Acme_Careplans_V1_BrowseCarePlansRequest.with {
            $0.context = input.context
            $0.filter = Acme_Careplans_V1_BrowseCarePlansRequest.Filter.with {
                $0.region = input.prescription.billingAddress.region
            }
        }
        async let remote1 = self.careplansCarePlanQuery.browseCarePlans(outbound1)
        async let persisted1 = store.count(tenant: input.context.tenantID)
        let (reply1, count1) = try await (remote1, persisted1)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count1)])
        return Acme_Prescriptions_V1_CalculatePrescriptionResponse.with {
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply0.metricSeries.audit.etag
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = reply0.metricSeries.address.postalCode
                }
                $0.number = input.prescription.number
                $0.prescriptionID = input.prescriptionID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply1.result.details
                $0.status = reply1.result.status
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processComparePrescriptionOptions(_ input: Acme_Prescriptions_V1_ComparePrescriptionOptionsRequest)
        async throws -> Acme_Prescriptions_V1_ComparePrescriptionOptionsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.currencyCode)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "audit", detail: input.details.currencyCode
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ComparePrescriptionOptions",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PrescriptionRecord(input.prescription, tenant: input.context.tenantID)
        try await store.save(record.stored)
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        let outbound0 = Acme_Telehealth_V1_LintVideoVisitsRequest.with {
            $0.context = input.context
            $0.details = Acme_Telehealth_V1_LintVideoVisitsRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.prescription.counterparty.email
                }
            }
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.details.destination.region
                }
            }
        }
        let reply0 = try await self.comparePrescriptionOptionsStep0.execute(outbound0)
        let outbound1 = Acme_Venues_V1_ExplainVenueDecisionRequest.with {
            $0.context = input.context
            $0.venue = Acme_Venues_V1_Venue.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply0.videoVisit.audit.updatedAt
                }
            }
        }
        let port1 = RPCOperations.port { (request: Acme_Venues_V1_ExplainVenueDecisionRequest) in
            try await self.venuesVenueValidation.explainVenueDecision(request)
        }
        let reply1 = try await port1.execute(outbound1)
        let requests2 = input.prescription.lines.map { element in
            Acme_Audit_V1_LintAuditEventsRequest.with {
                $0.auditEvent = Acme_Audit_V1_AuditEvent.with {
                    $0.attributes = element.attributes
                }
                $0.context = input.context
            }
        }
        let replies2 = try await FanOut.map(requests2) { candidate in
            try await self.auditAuditEventValidation.lintAuditEvents(candidate)
        }
        let reply2 = replies2.first ?? Acme_Audit_V1_LintAuditEventsResponse()
        _ = reply2
        return Acme_Prescriptions_V1_ComparePrescriptionOptionsResponse.with {
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply0.videoVisit.audit.updatedAt
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.email = reply0.videoVisit.organizer.email
                }
                $0.number = input.prescription.number
                $0.prescriptionID = input.prescriptionID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply1.result.details
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processEstimatePrescription(_ input: Acme_Prescriptions_V1_EstimatePrescriptionRequest) async throws
        -> Acme_Prescriptions_V1_EstimatePrescriptionResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.currencyCode)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "audit", detail: input.details.currencyCode
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "EstimatePrescription",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PrescriptionRecord(input.prescription, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Telehealth_V1_CountVisitNotesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Telehealth_V1_CountVisitNotesRequest.Filter.with {
                $0.createdAfter = input.prescription.dueAt
                $0.region = input.prescription.billingAddress.region
            }
        }
        let reply0 = try await self.estimatePrescriptionStep0(outbound0)
        let outbound1 = Acme_Telehealth_V1_SuggestVisitNotesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Telehealth_V1_SuggestVisitNotesRequest.Filter.with {
                $0.createdAfter = input.prescription.audit.updatedAt
                $0.region = input.details.destination.region
            }
        }
        guard
            let execute1 = self.estimatePrescriptionStep1[settings.region] ?? self.estimatePrescriptionStep1["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply1 = try await execute1(outbound1)
        let outbound2 = Acme_Telehealth_V1_SummarizeVisitNotesRequest.with {
            $0.annotations = input.annotations
            $0.context = input.context
            $0.details = Acme_Telehealth_V1_SummarizeVisitNotesRequest.Details.with {
                $0.filters = reply1.result.details
            }
            $0.reason = input.reason
        }
        let reply2 = try await self.telehealthVisitNoteQuery.summarizeVisitNotes(outbound2)
        let outbound3 = Acme_Telehealth_V1_CloneVideoVisitRequest.with {
            $0.context = input.context
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.prescription.audit.createdAt
                }
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = input.details.destination.countryCode
                    $0.postalCode = input.details.destination.postalCode
                }
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.email = input.prescription.counterparty.email
                }
            }
        }
        let envelope3 = try Google_Protobuf_Any(message: outbound3)
        let unpacked3 = try Acme_Telehealth_V1_CloneVideoVisitRequest(unpackingAny: envelope3)
        let reply3 = try await self.telehealthVideoVisit.cloneVideoVisit(unpacked3)
        return Acme_Prescriptions_V1_EstimatePrescriptionResponse.with {
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.email = reply3.videoVisit.organizer.email
                }
                $0.issuedAt = input.prescription.issuedAt
                $0.prescriptionID = input.prescriptionID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = Projection.firstValue(
                    [
                        reply1.result.correlationID,
                        reply2.result.correlationID,
                    ], default: .init())
                $0.message = Projection.firstValue(
                    [
                        reply0.result.message,
                        reply2.result.message,
                    ], default: .init())
                $0.status = reply1.result.status
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processExplainPrescriptionCalculation(_ input: Acme_Prescriptions_V1_ExplainPrescriptionCalculationRequest)
        async throws -> Acme_Prescriptions_V1_ExplainPrescriptionCalculationResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.phone)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "audit", detail: input.details.contact.phone
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ExplainPrescriptionCalculation",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PrescriptionRecord(input.prescription, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Careplans_V1_QuoteCareGoalRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = input.prescription.audit.etag
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.contact.email
                }
            }
            $0.context = input.context
        }
        let json0 = try outbound0.jsonString()
        let decoded0 = try Acme_Careplans_V1_QuoteCareGoalRequest(jsonString: json0)
        let reply0 = try await self.careplansCareGoalCalculation.quoteCareGoal(decoded0)
        return Acme_Prescriptions_V1_ExplainPrescriptionCalculationResponse.with {
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply0.careGoal.audit.createdAt
                }
                $0.billingAddress = input.prescription.billingAddress
                $0.prescriptionID = input.prescriptionID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processGetPrescriptionRates(_ input: Acme_Prescriptions_V1_GetPrescriptionRatesRequest) async throws
        -> Acme_Prescriptions_V1_GetPrescriptionRatesResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "GetPrescriptionRates",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "GetPrescriptionRates", detail: input.context.traceID
        )
        let outbound0 =
            Acme_Careplans_V1_CheckCareGoalEligibilityRequest.forPrescriptionCalculationEndpointGetPrescriptionRates0(
                input
            )
        let reply0 = try await self.careplansCareGoalValidation.checkCareGoalEligibility(outbound0)
        let outbound1 = Acme_Ledger_V1_CountLedgerAccountsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Ledger_V1_CountLedgerAccountsRequest.Filter.with {
                $0.createdAfter = reply0.careGoal.sla.dueAt
                $0.ownerID = reply0.careGoal.sla.policyID
            }
        }
        let reply1 = try await self.ledgerLedgerAccountQuery.countLedgerAccounts(
            outbound1, metadata: ["x-acme-region": .string(settings.region)]
        )
        return Acme_Prescriptions_V1_GetPrescriptionRatesResponse.with {
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.prescriptionID = input.prescriptionID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply1.result.details
                $0.referenceIds = reply1.result.referenceIds
                $0.status = reply0.outcome.status
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processQuotePrescription(_ input: Acme_Prescriptions_V1_QuotePrescriptionRequest) async throws
        -> Acme_Prescriptions_V1_QuotePrescriptionResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.currencyCode)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "audit", detail: input.details.currencyCode
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "QuotePrescription",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PrescriptionRecord(input.prescription, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Audit_V1_LintAuditEventsRequest.with {
            $0.context = input.context
            $0.details = Acme_Audit_V1_LintAuditEventsRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.prescription.counterparty.email
                }
            }
        }
        let reply0 = try await RPCOperations.call(outbound0) { request in
            try await self.auditAuditEventValidation.lintAuditEvents(request)
        }
        let outbound1 = Acme_Telehealth_V1_ScoreTriageRequest.with {
            $0.context = Projection.read(input, at: \Acme_Prescriptions_V1_QuotePrescriptionRequest.context)
            $0.details = Acme_Telehealth_V1_ScoreTriageRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = Projection.read(
                        input,
                        at: \Acme_Prescriptions_V1_QuotePrescriptionRequest.prescription.billingAddress.countryCode)
                }
            }
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.displayName = Projection.read(
                        input, at: \Acme_Prescriptions_V1_QuotePrescriptionRequest.prescription.counterparty.displayName
                    )
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = Projection.read(
                        input, at: \Acme_Prescriptions_V1_QuotePrescriptionRequest.prescription.audit.createdAt)
                }
            }
        }
        let reply1 = try await self.telehealthTriageValidation.scoreTriage(outbound1)
        return Acme_Prescriptions_V1_QuotePrescriptionResponse.with {
            $0.breakdown = Acme_Prescriptions_V1_QuotePrescriptionResponse.Breakdown.with {
                $0.currencyCode = reply1.breakdown.currencyCode
            }
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.billingAddress = input.prescription.billingAddress
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = reply1.triage.assignee.displayName
                }
                $0.prescriptionID = input.prescriptionID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processRecalculatePrescriptions(_ input: Acme_Prescriptions_V1_RecalculatePrescriptionsRequest) async throws
        -> Acme_Prescriptions_V1_RecalculatePrescriptionsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.currencyCode)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "audit", detail: input.details.currencyCode
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "RecalculatePrescriptions",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PrescriptionRecord(input.prescription, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Careplans_V1_ValidateCarePlanRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = input.prescription.audit.createdBy
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.recipient = input.prescription.billingAddress.recipient
                    $0.region = input.details.destination.region
                }
            }
            $0.context = input.context
        }
        let step0: @Sendable () async throws -> Acme_Careplans_V1_ValidateCarePlanResponse = {
            try await self.careplansCarePlanValidation.validateCarePlan(outbound0)
        }
        let reply0 = try await step0()
        var outbound1 = Acme_Metrics_V1_ListMetricSeriesesRequest()
        outbound1.context = input.context
        outbound1.filter = Acme_Metrics_V1_ListMetricSeriesesRequest.Filter.with {
            $0.createdAfter = input.prescription.audit.updatedAt
            $0.ownerID = reply0.result.correlationID
            $0.region = input.prescription.billingAddress.region
        }
        let reply1 = try await self.metricsMetricSeries.listMetricSerieses(outbound1)
        return Acme_Prescriptions_V1_RecalculatePrescriptionsResponse.with {
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply0.carePlan.audit.updatedAt
                }
                $0.prescriptionID = input.prescriptionID
                $0.total = input.prescription.total
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = Projection.firstValue(
                    [
                        reply0.outcome.message,
                        reply1.result.message,
                    ], default: .init())
                $0.referenceIds = reply1.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processSimulatePrescription(_ input: Acme_Prescriptions_V1_SimulatePrescriptionRequest) async throws
        -> Acme_Prescriptions_V1_SimulatePrescriptionResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.currencyCode)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "audit", detail: input.details.currencyCode
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SimulatePrescription",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PrescriptionRecord(input.prescription, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Shows_V1_CompareShowOptionsRequest.with {
            $0.context = input.context
            $0.show = Acme_Shows_V1_Show.with {
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.locality = input.details.destination.locality
                }
                $0.participants = [
                    Acme_Shows_V1_ShowParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = input.prescription.counterparty.email
                        }
                    }
                ]
            }
        }
        let step0: @Sendable () async throws -> Acme_Shows_V1_CompareShowOptionsResponse = {
            try await self.showsShowCalculation.compareShowOptions(outbound0)
        }
        let reply0 = try await step0()
        return Acme_Prescriptions_V1_SimulatePrescriptionResponse.with {
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = reply0.show.location.countryCode
                }
                $0.counterparty = input.prescription.counterparty
                $0.prescriptionID = input.prescriptionID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }
}
