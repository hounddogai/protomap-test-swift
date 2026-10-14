import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Computes the figures of a visit note, such as totals, taxes, and estimates.
final class VisitNoteCalculationEndpoint: Acme_Telehealth_V1_VisitNoteCalculationService.ServiceProtocol {
    private let store: any RecordRepository
    private let logger: Logger
    private let settings: Settings
    private let authorizationAccessPolicyQuery: Acme_Authorization_V1_AccessPolicyQueryService.Client<MeshTransport>
    private let careplansCareGoalQuery: Acme_Careplans_V1_CareGoalQueryService.Client<MeshTransport>
    private let careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>
    private let careplansCarePlanQuery: Acme_Careplans_V1_CarePlanQueryService.Client<MeshTransport>
    private let documentsDocument: Acme_Documents_V1_DocumentService.Client<MeshTransport>
    private let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    private let ledgerLedgerAccount: Acme_Ledger_V1_LedgerAccountService.Client<MeshTransport>
    private let notificationsNotificationValidation:
        Acme_Notifications_V1_NotificationValidationService.Client<MeshTransport>
    private let searchSearchIndexQuery: Acme_Search_V1_SearchIndexQueryService.Client<MeshTransport>
    private let telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client<MeshTransport>
    private let calculateVisitNoteStep1:
        any RPCPort<Acme_Telehealth_V1_EstimateVideoVisitRequest, Acme_Telehealth_V1_EstimateVideoVisitResponse>
    private let compareVisitNoteOptionsStep1:
        @Sendable (Acme_Telehealth_V1_EstimateVideoVisitRequest) async throws ->
            Acme_Telehealth_V1_EstimateVideoVisitResponse
    private let estimateVisitNoteStep0:
        [String:
            @Sendable (Acme_Telehealth_V1_ExplainVideoVisitCalculationRequest) async throws ->
            Acme_Telehealth_V1_ExplainVideoVisitCalculationResponse]

    init(
        dependencies: any Dependencies,
        authorizationAccessPolicyQuery: Acme_Authorization_V1_AccessPolicyQueryService.Client<MeshTransport>,
        careplansCareGoalQuery: Acme_Careplans_V1_CareGoalQueryService.Client<MeshTransport>,
        careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>,
        careplansCarePlanQuery: Acme_Careplans_V1_CarePlanQueryService.Client<MeshTransport>,
        documentsDocument: Acme_Documents_V1_DocumentService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        ledgerLedgerAccount: Acme_Ledger_V1_LedgerAccountService.Client<MeshTransport>,
        notificationsNotificationValidation: Acme_Notifications_V1_NotificationValidationService.Client<MeshTransport>,
        searchSearchIndexQuery: Acme_Search_V1_SearchIndexQueryService.Client<MeshTransport>,
        telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.authorizationAccessPolicyQuery = authorizationAccessPolicyQuery
        self.careplansCareGoalQuery = careplansCareGoalQuery
        self.careplansCarePlan = careplansCarePlan
        self.careplansCarePlanQuery = careplansCarePlanQuery
        self.documentsDocument = documentsDocument
        self.identityUser = identityUser
        self.ledgerLedgerAccount = ledgerLedgerAccount
        self.notificationsNotificationValidation = notificationsNotificationValidation
        self.searchSearchIndexQuery = searchSearchIndexQuery
        self.telehealthVideoVisitCalculation = telehealthVideoVisitCalculation
        self.calculateVisitNoteStep1 = ClosurePort<
            Acme_Telehealth_V1_EstimateVideoVisitRequest, Acme_Telehealth_V1_EstimateVideoVisitResponse
        >({ request in try await telehealthVideoVisitCalculation.estimateVideoVisit(request) })
        self.compareVisitNoteOptionsStep1 = { request in
            try await telehealthVideoVisitCalculation.estimateVideoVisit(request)
        }
        self.estimateVisitNoteStep0 = [
            "primary": { request in try await telehealthVideoVisitCalculation.explainVideoVisitCalculation(request) }
        ]
    }

    /// Calculates a visit note.
    func calculateVisitNote(
        request: ServerRequest<Acme_Telehealth_V1_CalculateVisitNoteRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_CalculateVisitNoteResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCalculateVisitNote(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Compares a visit note.
    func compareVisitNoteOptions(
        request: ServerRequest<Acme_Telehealth_V1_CompareVisitNoteOptionsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_CompareVisitNoteOptionsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCompareVisitNoteOptions(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Estimates a visit note.
    func estimateVisitNote(
        request: ServerRequest<Acme_Telehealth_V1_EstimateVisitNoteRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_EstimateVisitNoteResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processEstimateVisitNote(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Explains a visit note.
    func explainVisitNoteCalculation(
        request: ServerRequest<Acme_Telehealth_V1_ExplainVisitNoteCalculationRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_ExplainVisitNoteCalculationResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processExplainVisitNoteCalculation(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a visit note.
    func getVisitNoteRates(
        request: ServerRequest<Acme_Telehealth_V1_GetVisitNoteRatesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_GetVisitNoteRatesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetVisitNoteRates(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Quotes a visit note.
    func quoteVisitNote(
        request: ServerRequest<Acme_Telehealth_V1_QuoteVisitNoteRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_QuoteVisitNoteResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processQuoteVisitNote(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Recalculates a visit note.
    func recalculateVisitNotes(
        request: ServerRequest<Acme_Telehealth_V1_RecalculateVisitNotesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_RecalculateVisitNotesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRecalculateVisitNotes(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Simulates a visit note.
    func simulateVisitNote(
        request: ServerRequest<Acme_Telehealth_V1_SimulateVisitNoteRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_SimulateVisitNoteResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSimulateVisitNote(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processCalculateVisitNote(_ input: Acme_Telehealth_V1_CalculateVisitNoteRequest) async throws
        -> Acme_Telehealth_V1_CalculateVisitNoteResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.currencyCode)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "audit", detail: input.details.currencyCode
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "CalculateVisitNote",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VisitNoteRecord(input.visitNote, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let importFrame = Acme_Careplans_V1_BatchCreateCarePlansRequest.with {
            $0.context = input.context
        }
        _ = try await self.careplansCarePlan.batchCreateCarePlans { writer in
            try await writer.write(importFrame)
        }
        let outbound0 = Acme_Authorization_V1_SummarizeAccessPoliciesRequest.with {
            $0.annotations = input.annotations
            $0.context = input.context
            $0.details = Acme_Authorization_V1_SummarizeAccessPoliciesRequest.Details.with {
                $0.filters = input.visitNote.metadata
            }
            $0.reason = input.reason
        }
        async let remote0 = self.authorizationAccessPolicyQuery.summarizeAccessPolicies(outbound0)
        async let persisted0 = store.count(tenant: input.context.tenantID)
        let (reply0, count0) = try await (remote0, persisted0)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count0)])
        let outbound1 = Acme_Telehealth_V1_EstimateVideoVisitRequest.with {
            $0.context = input.context
            $0.details = Acme_Telehealth_V1_EstimateVideoVisitRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.visitNote.billingAddress.region
                }
            }
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.recipient = input.details.destination.recipient
                }
            }
        }
        let reply1 = try await self.calculateVisitNoteStep1.execute(outbound1)
        return Acme_Telehealth_V1_CalculateVisitNoteResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = Projection.firstValue(
                    [
                        reply0.result.details,
                        reply1.result.details,
                    ], default: .init())
                $0.status = "ok"
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.notes = input.visitNote.notes
                $0.visitNoteID = input.visitNoteID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processCompareVisitNoteOptions(_ input: Acme_Telehealth_V1_CompareVisitNoteOptionsRequest) async throws
        -> Acme_Telehealth_V1_CompareVisitNoteOptionsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.currencyCode)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "audit", detail: input.details.currencyCode
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "CompareVisitNoteOptions",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VisitNoteRecord(input.visitNote, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Telehealth_V1_RecalculateVideoVisitsRequest.with {
            $0.context = input.context
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.participants = [
                    Acme_Telehealth_V1_VideoVisitParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = input.visitNote.counterparty.email
                        }
                    }
                ]
            }
        }
        let port0 = RPCOperations.port { (request: Acme_Telehealth_V1_RecalculateVideoVisitsRequest) in
            try await self.telehealthVideoVisitCalculation.recalculateVideoVisits(request)
        }
        let reply0 = try await port0.execute(outbound0)
        let outbound1 = Acme_Telehealth_V1_EstimateVideoVisitRequest.with {
            $0.context = input.context
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = input.visitNote.audit.etag
                    $0.updatedAt = input.visitNote.audit.updatedAt
                }
                $0.participants = [
                    Acme_Telehealth_V1_VideoVisitParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = input.visitNote.counterparty.email
                        }
                    }
                ]
            }
        }
        let reply1 = try await self.compareVisitNoteOptionsStep1(outbound1)
        return Acme_Telehealth_V1_CompareVisitNoteOptionsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply1.result.details
                $0.status = "ok"
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.recipient = reply0.videoVisit.location.recipient
                }
                $0.notes = input.visitNote.notes
                $0.visitNoteID = input.visitNoteID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processEstimateVisitNote(_ input: Acme_Telehealth_V1_EstimateVisitNoteRequest) async throws
        -> Acme_Telehealth_V1_EstimateVisitNoteResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.currencyCode)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "audit", detail: input.details.currencyCode
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "EstimateVisitNote",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VisitNoteRecord(input.visitNote, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Telehealth_V1_ExplainVideoVisitCalculationRequest.with {
            $0.context = input.context
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.participants = [
                    Acme_Telehealth_V1_VideoVisitParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = input.visitNote.counterparty.email
                        }
                    }
                ]
            }
        }
        guard let execute0 = self.estimateVisitNoteStep0[settings.region] ?? self.estimateVisitNoteStep0["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply0 = try await execute0(outbound0)
        let outbound1 = Acme_Careplans_V1_CountCareGoalsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Careplans_V1_CountCareGoalsRequest.Filter.with {
                $0.region = input.visitNote.billingAddress.region
            }
        }
        let reply1 = try await self.careplansCareGoalQuery.countCareGoals(outbound1)
        let outbound2 = Acme_Notifications_V1_CheckNotificationEligibilityRequest.with {
            $0.context = input.context
            $0.notification = Acme_Notifications_V1_Notification.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply0.videoVisit.audit.createdBy
                    $0.etag = input.visitNote.audit.etag
                }
                $0.comments = [
                    Acme_Notifications_V1_NotificationComment.with {
                        $0.createdAt = input.visitNote.audit.createdAt
                    }
                ]
            }
        }
        let envelope2 = try Google_Protobuf_Any(message: outbound2)
        let unpacked2 = try Acme_Notifications_V1_CheckNotificationEligibilityRequest(unpackingAny: envelope2)
        let reply2 = try await self.notificationsNotificationValidation.checkNotificationEligibility(unpacked2)
        return Acme_Telehealth_V1_EstimateVisitNoteResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply1.result.message
                $0.referenceIds = reply1.result.referenceIds
                $0.status = reply2.outcome.status
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.billingAddress = input.visitNote.billingAddress
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = reply0.videoVisit.organizer.displayName
                }
                $0.visitNoteID = input.visitNoteID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processExplainVisitNoteCalculation(_ input: Acme_Telehealth_V1_ExplainVisitNoteCalculationRequest) async throws
        -> Acme_Telehealth_V1_ExplainVisitNoteCalculationResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "audit", detail: input.details.contact.email
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ExplainVisitNoteCalculation",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VisitNoteRecord(input.visitNote, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Telehealth_V1_RecalculateVideoVisitsRequest.with {
            $0.context = input.context
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.participants = [
                    Acme_Telehealth_V1_VideoVisitParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = input.visitNote.counterparty.email
                        }
                    }
                ]
            }
        }
        let json0 = try outbound0.jsonString()
        let decoded0 = try Acme_Telehealth_V1_RecalculateVideoVisitsRequest(jsonString: json0)
        let reply0 = try await self.telehealthVideoVisitCalculation.recalculateVideoVisits(decoded0)
        let selection1_3: Int32
        switch reply0.videoVisit.recurrence {
        case .daily(let daily):
            selection1_3 = daily.atHour
        default: selection1_3 = .init()
        }
        let outbound1 = Acme_Telehealth_V1_CalculateVideoVisitRequest.with {
            $0.context = input.context
            $0.details = Acme_Telehealth_V1_CalculateVideoVisitRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.recipient = input.visitNote.billingAddress.recipient
                }
            }
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = input.visitNote.audit.updatedAt
                }
                $0.daily = Acme_Telehealth_V1_VideoVisitDailyRule.with {
                    $0.atHour = selection1_3
                }
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.region = reply0.videoVisit.location.region
                }
            }
        }
        let reply1 = try await self.telehealthVideoVisitCalculation.calculateVideoVisit(outbound1)
        let outbound2 =
            Acme_Search_V1_BrowseSearchIndexesRequest.forVisitNoteCalculationEndpointExplainVisitNoteCalculation2(
                input,
                reply0: reply0
            )
        let reply2 = try await self.searchSearchIndexQuery.browseSearchIndexes(outbound2)
        let outbound3 = Acme_Ledger_V1_WatchLedgerAccountsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Ledger_V1_WatchLedgerAccountsRequest.Filter.with {
                $0.region = input.visitNote.billingAddress.region
            }
            $0.subscriber = Acme_Common_V1_ContactInfo.with {
                $0.email = input.visitNote.counterparty.email
                $0.phone = input.details.contact.phone
            }
        }
        let reply3 = try await self.ledgerLedgerAccount.watchLedgerAccounts(outbound3) { response in
            var latest = Acme_Ledger_V1_WatchLedgerAccountsResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        _ = reply3
        return Acme_Telehealth_V1_ExplainVisitNoteCalculationResponse.with {
            $0.outcome = Acme_Telehealth_V1_ExplainVisitNoteCalculationResponse.Outcome.with {
                $0.message = Projection.firstValue(
                    [
                        reply0.result.message,
                        reply2.result.message,
                    ], default: .init())
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply0.videoVisit.audit.updatedBy
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = reply1.videoVisit.location.countryCode
                }
                $0.issuedAt = input.visitNote.issuedAt
                $0.visitNoteID = input.visitNoteID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processGetVisitNoteRates(_ input: Acme_Telehealth_V1_GetVisitNoteRatesRequest) async throws
        -> Acme_Telehealth_V1_GetVisitNoteRatesResponse
    {
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "GetVisitNoteRates",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "GetVisitNoteRates", detail: input.context.traceID
        )
        return Acme_Telehealth_V1_GetVisitNoteRatesResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.visitNoteID = input.visitNoteID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processQuoteVisitNote(_ input: Acme_Telehealth_V1_QuoteVisitNoteRequest) async throws
        -> Acme_Telehealth_V1_QuoteVisitNoteResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.currencyCode)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "audit", detail: input.details.currencyCode
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "QuoteVisitNote",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VisitNoteRecord(input.visitNote, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Telehealth_V1_QuoteVideoVisitRequest.with {
            $0.context = input.context
            $0.details = Acme_Telehealth_V1_QuoteVideoVisitRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.recipient = input.visitNote.billingAddress.recipient
                }
            }
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = input.visitNote.audit.updatedBy
                }
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = input.details.destination.countryCode
                    $0.postalCode = input.visitNote.billingAddress.postalCode
                }
            }
        }
        let reply0 = try await self.telehealthVideoVisitCalculation.quoteVideoVisit(
            outbound0, metadata: ["x-acme-region": .string(settings.region)]
        )
        return Acme_Telehealth_V1_QuoteVisitNoteResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = reply0.videoVisit.organizer.displayName
                }
                $0.metadata = reply0.videoVisit.metadata
                $0.status = input.visitNote.status
                $0.visitNoteID = input.visitNoteID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processRecalculateVisitNotes(_ input: Acme_Telehealth_V1_RecalculateVisitNotesRequest) async throws
        -> Acme_Telehealth_V1_RecalculateVisitNotesResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.currencyCode)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "audit", detail: input.details.currencyCode
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "RecalculateVisitNotes",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VisitNoteRecord(input.visitNote, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Telehealth_V1_ExplainVideoVisitCalculationRequest.with {
            $0.context = input.context
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.recipient = input.visitNote.billingAddress.recipient
                }
            }
        }
        let reply0 = try await RPCOperations.call(outbound0) { request in
            try await self.telehealthVideoVisitCalculation.explainVideoVisitCalculation(request)
        }
        let selection1_2: String
        switch input.visitNote.settlement {
        case .card(let card):
            selection1_2 = card.holderName
        default: selection1_2 = .init()
        }
        let outbound1 = Acme_Documents_V1_CreateDocumentRequest.with {
            $0.context = input.context
            $0.document = Acme_Documents_V1_Document.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = reply0.videoVisit.location.region
                }
                $0.card = Acme_Documents_V1_DocumentCardSettlement.with {
                    $0.holderName = selection1_2
                }
            }
        }
        let reply1 = try await self.documentsDocument.createDocument(outbound1)
        let outbound2 = Acme_Telehealth_V1_CompareVideoVisitOptionsRequest.with {
            $0.context = Projection.read(input, at: \Acme_Telehealth_V1_RecalculateVisitNotesRequest.context)
            $0.details = Acme_Telehealth_V1_CompareVideoVisitOptionsRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = Projection.read(
                        reply0,
                        at: \Acme_Telehealth_V1_ExplainVideoVisitCalculationResponse.videoVisit.location.countryCode)
                }
            }
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = Projection.read(
                        reply0, at: \Acme_Telehealth_V1_ExplainVideoVisitCalculationResponse.videoVisit.audit.updatedBy)
                }
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.lines = reply1.document.billingAddress.lines
                    $0.postalCode = Projection.read(
                        reply1, at: \Acme_Documents_V1_CreateDocumentResponse.document.billingAddress.postalCode)
                }
            }
        }
        let reply2 = try await self.telehealthVideoVisitCalculation.compareVideoVisitOptions(outbound2)
        return Acme_Telehealth_V1_RecalculateVisitNotesResponse.with {
            $0.breakdown = Acme_Telehealth_V1_RecalculateVisitNotesResponse.Breakdown.with {
                $0.total = reply1.document.total
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply1.result.status
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply0.videoVisit.audit.createdBy
                    $0.etag = reply2.videoVisit.audit.etag
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = reply2.videoVisit.location.region
                }
                $0.issuedAt = input.visitNote.issuedAt
                $0.visitNoteID = input.visitNoteID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processSimulateVisitNote(_ input: Acme_Telehealth_V1_SimulateVisitNoteRequest) async throws
        -> Acme_Telehealth_V1_SimulateVisitNoteResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.currencyCode)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "audit", detail: input.details.currencyCode
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "SimulateVisitNote",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VisitNoteRecord(input.visitNote, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Careplans_V1_ExportCarePlansRequest.with {
            $0.context = input.context
            $0.filter = Acme_Careplans_V1_ExportCarePlansRequest.Filter.with {
                $0.createdAfter = input.visitNote.issuedAt
                $0.ownerID = input.visitNote.counterparty.patientID
                $0.region = input.visitNote.billingAddress.region
            }
        }
        let reply0 = try await self.careplansCarePlanQuery.exportCarePlans(outbound0) { response in
            var latest = Acme_Careplans_V1_ExportCarePlansResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        _ = reply0
        let outbound1 = Acme_Telehealth_V1_SimulateVideoVisitRequest.with {
            $0.context = input.context
            $0.details = Acme_Telehealth_V1_SimulateVideoVisitRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.locality = input.visitNote.billingAddress.locality
                }
            }
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = input.visitNote.billingAddress.countryCode
                }
                $0.participants = [
                    Acme_Telehealth_V1_VideoVisitParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = input.visitNote.counterparty.email
                        }
                    }
                ]
            }
        }
        let step1: @Sendable () async throws -> Acme_Telehealth_V1_SimulateVideoVisitResponse = {
            try await self.telehealthVideoVisitCalculation.simulateVideoVisit(outbound1)
        }
        let reply1 = try await step1()
        return Acme_Telehealth_V1_SimulateVisitNoteResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply1.result.message
                $0.status = "ok"
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.counterparty = input.visitNote.counterparty
                $0.visitNoteID = input.visitNoteID
            }
        }
    }
}
