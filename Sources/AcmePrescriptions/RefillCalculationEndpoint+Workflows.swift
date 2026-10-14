import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension RefillCalculationEndpoint {
    /// Calculates a refill.
    func calculateRefill(
        request: ServerRequest<Acme_Prescriptions_V1_CalculateRefillRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_CalculateRefillResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCalculateRefill(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Compares a refill.
    func compareRefillOptions(
        request: ServerRequest<Acme_Prescriptions_V1_CompareRefillOptionsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_CompareRefillOptionsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCompareRefillOptions(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Estimates a refill.
    func estimateRefill(
        request: ServerRequest<Acme_Prescriptions_V1_EstimateRefillRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_EstimateRefillResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processEstimateRefill(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Explains a refill.
    func explainRefillCalculation(
        request: ServerRequest<Acme_Prescriptions_V1_ExplainRefillCalculationRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ExplainRefillCalculationResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processExplainRefillCalculation(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a refill.
    func getRefillRates(
        request: ServerRequest<Acme_Prescriptions_V1_GetRefillRatesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_GetRefillRatesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetRefillRates(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Quotes a refill.
    func quoteRefill(
        request: ServerRequest<Acme_Prescriptions_V1_QuoteRefillRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_QuoteRefillResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processQuoteRefill(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Recalculates a refill.
    func recalculateRefills(
        request: ServerRequest<Acme_Prescriptions_V1_RecalculateRefillsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_RecalculateRefillsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRecalculateRefills(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Simulates a refill.
    func simulateRefill(
        request: ServerRequest<Acme_Prescriptions_V1_SimulateRefillRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_SimulateRefillResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSimulateRefill(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processCalculateRefill(_ input: Acme_Prescriptions_V1_CalculateRefillRequest) async throws
        -> Acme_Prescriptions_V1_CalculateRefillResponse
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
            "CalculateRefill",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try RefillRecord(input.refill, tenant: input.context.tenantID)
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
        let outbound0 = Acme_Documents_V1_SummarizeDocumentsRequest.with {
            $0.annotations = input.annotations
            $0.context = input.context
            $0.reason = input.reason
        }
        guard let execute0 = self.calculateRefillStep0[settings.region] ?? self.calculateRefillStep0["primary"] else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply0 = try await execute0(outbound0)
        let outbound1 = Acme_Telehealth_V1_CountVisitNotesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Telehealth_V1_CountVisitNotesRequest.Filter.with {
                $0.region = input.details.destination.region
            }
        }
        let reply1 = try await self.telehealthVisitNoteQuery.countVisitNotes(outbound1)
        let outbound2 = Acme_Prescriptions_V1_SimulatePrescriptionRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_SimulatePrescriptionRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = input.details.destination.countryCode
                    $0.region = input.details.destination.region
                }
            }
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = input.details.destination.postalCode
                }
            }
        }
        let envelope2 = try Google_Protobuf_Any(message: outbound2)
        let unpacked2 = try Acme_Prescriptions_V1_SimulatePrescriptionRequest(unpackingAny: envelope2)
        let reply2 = try await self.prescriptionsPrescriptionCalculation.simulatePrescription(unpacked2)
        return Acme_Prescriptions_V1_CalculateRefillResponse.with {
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply2.prescription.audit.createdBy
                }
                $0.refillID = input.refillID
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply2.prescription.counterparty.email
                }
                $0.subject = input.refill.subject
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply1.result.details
                $0.referenceIds = reply0.result.referenceIds
                $0.status = reply1.result.status
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processCompareRefillOptions(_ input: Acme_Prescriptions_V1_CompareRefillOptionsRequest) async throws
        -> Acme_Prescriptions_V1_CompareRefillOptionsResponse
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
            "CompareRefillOptions",
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
        let outbound0 = Acme_Documents_V1_FindDocumentsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Documents_V1_FindDocumentsRequest.Filter.with {
                $0.region = input.details.destination.region
            }
        }
        let json0 = try outbound0.jsonString()
        let decoded0 = try Acme_Documents_V1_FindDocumentsRequest(jsonString: json0)
        let reply0 = try await self.documentsDocumentQuery.findDocuments(decoded0)
        let outbound1 =
            Acme_Prescriptions_V1_CalculatePrescriptionRequest.forRefillCalculationEndpointCompareRefillOptions1(
                input
            )
        let reply1 = try await self.prescriptionsPrescriptionCalculation.calculatePrescription(outbound1)
        return Acme_Prescriptions_V1_CompareRefillOptionsResponse.with {
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply1.prescription.audit.updatedBy
                }
                $0.refillID = input.refillID
                $0.subject = input.refill.subject
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.message = reply0.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processEstimateRefill(_ input: Acme_Prescriptions_V1_EstimateRefillRequest) async throws
        -> Acme_Prescriptions_V1_EstimateRefillResponse
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
            "EstimateRefill",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try RefillRecord(input.refill, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Prescriptions_V1_RecalculatePrescriptionsRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_RecalculatePrescriptionsRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = input.details.destination.countryCode
                }
            }
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = input.refill.assignee.displayName
                }
            }
        }
        let reply0 = try await self.prescriptionsPrescriptionCalculation.recalculatePrescriptions(
            outbound0, metadata: ["x-acme-region": .string(settings.region)]
        )
        return Acme_Prescriptions_V1_EstimateRefillResponse.with {
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.refillID = input.refillID
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply0.prescription.counterparty.email
                }
                $0.status = input.refill.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processExplainRefillCalculation(_ input: Acme_Prescriptions_V1_ExplainRefillCalculationRequest) async throws
        -> Acme_Prescriptions_V1_ExplainRefillCalculationResponse
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
            "ExplainRefillCalculation",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try RefillRecord(input.refill, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let selection0_2: String
        switch input.refill.origin {
        case .customer(let customer):
            selection0_2 = customer.prescriptionID
        default: selection0_2 = .init()
        }
        let outbound0 = Acme_Venues_V1_BrowseVenuesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Venues_V1_BrowseVenuesRequest.Filter.with {
                $0.createdAfter = input.refill.audit.createdAt
                $0.ownerID = selection0_2
            }
        }
        let reply0 = try await self.venuesVenueQuery.browseVenues(outbound0)
        return Acme_Prescriptions_V1_ExplainRefillCalculationResponse.with {
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.refillID = input.refillID
                $0.status = input.refill.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processGetRefillRates(_ input: Acme_Prescriptions_V1_GetRefillRatesRequest) async throws
        -> Acme_Prescriptions_V1_GetRefillRatesResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "GetRefillRates",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "GetRefillRates", detail: input.context.traceID
        )
        let outbound0 = Acme_Ledger_V1_NormalizeLedgerAccountRequest.with {
            $0.context = input.context
            $0.details = Acme_Ledger_V1_NormalizeLedgerAccountRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.context.actor.email
                }
                $0.locale = input.context.locale
            }
            $0.ledgerAccount = Acme_Ledger_V1_LedgerAccount.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.context.deadline
                }
                $0.externalAccountID = input.refillID
            }
        }
        let reply0 = try await RPCOperations.call(outbound0) { request in
            try await self.ledgerLedgerAccountValidation.normalizeLedgerAccount(request)
        }
        return Acme_Prescriptions_V1_GetRefillRatesResponse.with {
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply0.ledgerAccount.audit.createdAt
                    $0.updatedAt = reply0.ledgerAccount.audit.updatedAt
                }
                $0.refillID = input.refillID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processQuoteRefill(_ input: Acme_Prescriptions_V1_QuoteRefillRequest) async throws
        -> Acme_Prescriptions_V1_QuoteRefillResponse
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
            "QuoteRefill",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try RefillRecord(input.refill, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Prescriptions_V1_ComparePrescriptionOptionsRequest.with {
            $0.context = Projection.read(input, at: \Acme_Prescriptions_V1_QuoteRefillRequest.context)
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = Projection.read(input, at: \Acme_Prescriptions_V1_QuoteRefillRequest.refill.audit.etag)
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = Projection.read(
                        input, at: \Acme_Prescriptions_V1_QuoteRefillRequest.details.destination.countryCode)
                    $0.locality = Projection.read(
                        input, at: \Acme_Prescriptions_V1_QuoteRefillRequest.details.destination.locality)
                }
            }
        }
        let reply0 = try await self.prescriptionsPrescriptionCalculation.comparePrescriptionOptions(outbound0)
        let outbound1 = Acme_Concessions_V1_BrowseConcessionStandsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Concessions_V1_BrowseConcessionStandsRequest.Filter.with {
                $0.createdAfter = reply0.prescription.audit.createdAt
                $0.ownerID = reply0.result.correlationID
                $0.region = reply0.prescription.billingAddress.region
            }
        }
        let step1: @Sendable () async throws -> Acme_Concessions_V1_BrowseConcessionStandsResponse = {
            try await self.concessionsConcessionStandQuery.browseConcessionStands(outbound1)
        }
        let reply1 = try await step1()
        return Acme_Prescriptions_V1_QuoteRefillResponse.with {
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.refillID = input.refillID
                $0.subject = input.refill.subject
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = Projection.firstValue(
                    [
                        reply0.result.details,
                        reply1.result.details,
                    ], default: .init())
                $0.referenceIds = reply1.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processRecalculateRefills(_ input: Acme_Prescriptions_V1_RecalculateRefillsRequest) async throws
        -> Acme_Prescriptions_V1_RecalculateRefillsResponse
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
            "RecalculateRefills",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try RefillRecord(input.refill, tenant: input.context.tenantID)
        try await store.save(record.stored)
        var outbound0 = Acme_Venues_V1_LintVenuesRequest()
        outbound0.context = input.context
        outbound0.venue = Acme_Venues_V1_Venue.with {
            $0.audit = Acme_Common_V1_AuditInfo.with {
                $0.createdAt = input.refill.audit.createdAt
                $0.updatedAt = input.refill.audit.updatedAt
            }
        }
        let reply0 = try await self.venuesVenueValidation.lintVenues(outbound0)
        return Acme_Prescriptions_V1_RecalculateRefillsResponse.with {
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply0.venue.audit.updatedAt
                }
                $0.priority = input.refill.priority
                $0.refillID = input.refillID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processSimulateRefill(_ input: Acme_Prescriptions_V1_SimulateRefillRequest) async throws
        -> Acme_Prescriptions_V1_SimulateRefillResponse
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
            "SimulateRefill",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try RefillRecord(input.refill, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Boxoffice_V1_EstimateBoxOfficeSaleRequest.with {
            $0.boxOfficeSale = Acme_Boxoffice_V1_BoxOfficeSale.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = input.refill.audit.updatedAt
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = input.details.destination.countryCode
                }
            }
            $0.context = input.context
            $0.details = Acme_Boxoffice_V1_EstimateBoxOfficeSaleRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.lines = input.details.destination.lines
                    $0.postalCode = input.details.destination.postalCode
                }
            }
        }
        let step0: @Sendable () async throws -> Acme_Boxoffice_V1_EstimateBoxOfficeSaleResponse = {
            try await self.boxofficeBoxOfficeSaleCalculation.estimateBoxOfficeSale(outbound0)
        }
        let reply0 = try await step0()
        let outbound1 = Acme_Sponsorships_V1_CalculateSponsorRequest.with {
            $0.context = input.context
            $0.details = Acme_Sponsorships_V1_CalculateSponsorRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = input.details.destination.countryCode
                }
            }
        }
        let reply1 = try await self.sponsorshipsSponsorCalculation.calculateSponsor(outbound1)
        let outbound2 = Acme_Venues_V1_SummarizeVenuesRequest.with {
            $0.context = input.context
            $0.reason = input.reason
        }
        async let remote2 = self.venuesVenueQuery.summarizeVenues(outbound2)
        async let persisted2 = store.count(tenant: input.context.tenantID)
        let (reply2, count2) = try await (remote2, persisted2)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count2)])
        let outbound3 = Acme_Careplans_V1_CalculateCareGoalRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.email = input.refill.assignee.email
                }
                $0.comments = [
                    Acme_Careplans_V1_CareGoalComment.with {
                        $0.createdAt = input.refill.audit.createdAt
                    }
                ]
            }
            $0.context = input.context
        }
        let reply3 = try await self.simulateRefillStep3.execute(outbound3)
        return Acme_Prescriptions_V1_SimulateRefillResponse.with {
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply0.boxOfficeSale.audit.createdBy
                }
                $0.priority = input.refill.priority
                $0.refillID = input.refillID
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply1.sponsor.contact.email
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = Projection.firstValue(
                    [
                        reply0.result.details,
                        reply2.result.details,
                        reply3.result.details,
                    ], default: .init())
                $0.referenceIds = reply2.result.referenceIds
                $0.status = "ok"
            }
        }
    }
}
