import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Computes the figures of a vital, such as totals, taxes, and estimates.
final class VitalCalculationEndpoint: Acme_Careplans_V1_VitalCalculationService.ServiceProtocol {
    private let store: any RecordRepository
    private let logger: Logger
    private let settings: Settings
    private let careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>
    private let careplansCarePlanCalculation: Acme_Careplans_V1_CarePlanCalculationService.Client<MeshTransport>
    private let careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client<MeshTransport>
    private let documentsDocumentValidation: Acme_Documents_V1_DocumentValidationService.Client<MeshTransport>
    private let featureflagsFeatureFlag: Acme_Featureflags_V1_FeatureFlagService.Client<MeshTransport>
    private let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    private let searchSearchIndexQuery: Acme_Search_V1_SearchIndexQueryService.Client<MeshTransport>
    private let seatingSeatMap: Acme_Seating_V1_SeatMapService.Client<MeshTransport>
    private let sponsorshipsSponsor: Acme_Sponsorships_V1_SponsorService.Client<MeshTransport>
    private let toursTour: Acme_Tours_V1_TourService.Client<MeshTransport>
    private let compareVitalOptionsStep2:
        any RPCPort<Acme_Documents_V1_ValidateDocumentRequest, Acme_Documents_V1_ValidateDocumentResponse>
    private let estimateVitalStep1:
        @Sendable (Acme_Careplans_V1_CalculateCarePlanRequest) async throws ->
            Acme_Careplans_V1_CalculateCarePlanResponse
    private let estimateVitalStep2:
        [String:
            @Sendable (Acme_Search_V1_FindSearchIndexesRequest) async throws -> Acme_Search_V1_FindSearchIndexesResponse]

    init(
        dependencies: any Dependencies,
        careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>,
        careplansCarePlanCalculation: Acme_Careplans_V1_CarePlanCalculationService.Client<MeshTransport>,
        careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client<MeshTransport>,
        documentsDocumentValidation: Acme_Documents_V1_DocumentValidationService.Client<MeshTransport>,
        featureflagsFeatureFlag: Acme_Featureflags_V1_FeatureFlagService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        searchSearchIndexQuery: Acme_Search_V1_SearchIndexQueryService.Client<MeshTransport>,
        seatingSeatMap: Acme_Seating_V1_SeatMapService.Client<MeshTransport>,
        sponsorshipsSponsor: Acme_Sponsorships_V1_SponsorService.Client<MeshTransport>,
        toursTour: Acme_Tours_V1_TourService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.careplansCareGoalCalculation = careplansCareGoalCalculation
        self.careplansCarePlanCalculation = careplansCarePlanCalculation
        self.careplansCarePlanValidation = careplansCarePlanValidation
        self.documentsDocumentValidation = documentsDocumentValidation
        self.featureflagsFeatureFlag = featureflagsFeatureFlag
        self.identityUser = identityUser
        self.searchSearchIndexQuery = searchSearchIndexQuery
        self.seatingSeatMap = seatingSeatMap
        self.sponsorshipsSponsor = sponsorshipsSponsor
        self.toursTour = toursTour
        self.compareVitalOptionsStep2 = ClosurePort<
            Acme_Documents_V1_ValidateDocumentRequest, Acme_Documents_V1_ValidateDocumentResponse
        >({ request in try await documentsDocumentValidation.validateDocument(request) })
        self.estimateVitalStep1 = { request in try await careplansCarePlanCalculation.calculateCarePlan(request) }
        self.estimateVitalStep2 = [
            "primary": { request in try await searchSearchIndexQuery.findSearchIndexes(request) }
        ]
    }

    /// Calculates a vital.
    func calculateVital(
        request: ServerRequest<Acme_Careplans_V1_CalculateVitalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_CalculateVitalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCalculateVital(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Compares a vital.
    func compareVitalOptions(
        request: ServerRequest<Acme_Careplans_V1_CompareVitalOptionsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_CompareVitalOptionsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCompareVitalOptions(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Estimates a vital.
    func estimateVital(
        request: ServerRequest<Acme_Careplans_V1_EstimateVitalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_EstimateVitalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processEstimateVital(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Explains a vital.
    func explainVitalCalculation(
        request: ServerRequest<Acme_Careplans_V1_ExplainVitalCalculationRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_ExplainVitalCalculationResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processExplainVitalCalculation(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a vital.
    func getVitalRates(
        request: ServerRequest<Acme_Careplans_V1_GetVitalRatesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_GetVitalRatesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetVitalRates(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Quotes a vital.
    func quoteVital(
        request: ServerRequest<Acme_Careplans_V1_QuoteVitalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_QuoteVitalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processQuoteVital(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Recalculates a vital.
    func recalculateVitals(
        request: ServerRequest<Acme_Careplans_V1_RecalculateVitalsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_RecalculateVitalsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRecalculateVitals(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Simulates a vital.
    func simulateVital(
        request: ServerRequest<Acme_Careplans_V1_SimulateVitalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_SimulateVitalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSimulateVital(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processCalculateVital(_ input: Acme_Careplans_V1_CalculateVitalRequest) async throws
        -> Acme_Careplans_V1_CalculateVitalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.currencyCode)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "audit", detail: input.details.currencyCode
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "CalculateVital",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VitalRecord(input.vital, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Careplans_V1_SimulateCarePlanRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.details.destination.region
                }
            }
            $0.context = input.context
            $0.details = Acme_Careplans_V1_SimulateCarePlanRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.lines = input.details.destination.lines
                    $0.locality = input.details.destination.locality
                    $0.recipient = input.details.destination.recipient
                }
            }
        }
        let reply0 = try await self.careplansCarePlanCalculation.simulateCarePlan(outbound0)
        return Acme_Careplans_V1_CalculateVitalResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = input.vital.correlationID
                $0.details = reply0.result.details
                $0.status = "ok"
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.vitalID = input.vitalID
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processCompareVitalOptions(_ input: Acme_Careplans_V1_CompareVitalOptionsRequest) async throws
        -> Acme_Careplans_V1_CompareVitalOptionsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.currencyCode)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "audit", detail: input.details.currencyCode
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "CompareVitalOptions",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VitalRecord(input.vital, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Careplans_V1_LintCarePlansRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.locality = input.details.destination.locality
                }
            }
            $0.context = input.context
        }
        async let remote0 = self.careplansCarePlanValidation.lintCarePlans(outbound0)
        async let persisted0 = store.count(tenant: input.context.tenantID)
        let (reply0, count0) = try await (remote0, persisted0)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count0)])
        let requests1 = input.vital.measurements.map { element in
            Acme_Careplans_V1_QuoteCareGoalRequest.with {
                $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                    $0.comments = [
                        Acme_Careplans_V1_CareGoalComment.with {
                            $0.createdAt = element.observedAt
                        }
                    ]
                }
                $0.context = input.context
                $0.details = Acme_Careplans_V1_QuoteCareGoalRequest.Details.with {
                    $0.destination = Acme_Common_V1_PostalAddress.with {
                        $0.lines = reply0.carePlan.billingAddress.lines
                        $0.region = reply0.carePlan.billingAddress.region
                    }
                }
            }
        }
        let replies1 = try await FanOut.map(requests1) { candidate in
            try await self.careplansCareGoalCalculation.quoteCareGoal(candidate)
        }
        let reply1 = replies1.first ?? Acme_Careplans_V1_QuoteCareGoalResponse()
        let outbound2 = Acme_Documents_V1_ValidateDocumentRequest.with {
            $0.context = input.context
            $0.document = Acme_Documents_V1_Document.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply1.careGoal.audit.createdBy
                }
                $0.counterparty = Acme_Documents_V1_DocumentFolderRef.with {
                    $0.displayName = reply1.careGoal.assignee.displayName
                }
            }
        }
        let reply2 = try await self.compareVitalOptionsStep2.execute(outbound2)
        return Acme_Careplans_V1_CompareVitalOptionsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = Projection.firstValue(
                    [
                        reply0.outcome.status,
                        reply2.result.status,
                    ], default: .init())
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.kind = input.vital.kind
                $0.vitalID = input.vitalID
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processEstimateVital(_ input: Acme_Careplans_V1_EstimateVitalRequest) async throws
        -> Acme_Careplans_V1_EstimateVitalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.currencyCode)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "audit", detail: input.details.currencyCode
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "EstimateVital",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VitalRecord(input.vital, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Featureflags_V1_BatchGetFeatureFlagsRequest.with {
            $0.context = input.context
        }
        let port0 = RPCOperations.port { (request: Acme_Featureflags_V1_BatchGetFeatureFlagsRequest) in
            try await self.featureflagsFeatureFlag.batchGetFeatureFlags(request)
        }
        let reply0 = try await port0.execute(outbound0)
        let outbound1 = Acme_Careplans_V1_CalculateCarePlanRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.counterparty = Acme_Appointments_V1_AppointmentRef.with {
                    $0.startsAt = input.vital.subject.startsAt
                }
            }
            $0.context = input.context
        }
        let reply1 = try await self.estimateVitalStep1(outbound1)
        let outbound2 = Acme_Search_V1_FindSearchIndexesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Search_V1_FindSearchIndexesRequest.Filter.with {
                $0.createdAfter = input.vital.subject.startsAt
                $0.labels = reply0.result.details
                $0.ownerID = reply1.carePlan.counterparty.appointmentID
                $0.region = reply1.carePlan.billingAddress.region
            }
        }
        guard let execute2 = self.estimateVitalStep2[settings.region] ?? self.estimateVitalStep2["primary"] else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply2 = try await execute2(outbound2)
        return Acme_Careplans_V1_EstimateVitalResponse.with {
            $0.breakdown = Acme_Careplans_V1_EstimateVitalResponse.Breakdown.with {
                $0.currencyCode = reply1.breakdown.currencyCode
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.message = reply2.result.message
                $0.status = "ok"
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.correlationID = reply0.result.correlationID
                $0.source = input.vital.source
                $0.vitalID = input.vitalID
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processExplainVitalCalculation(_ input: Acme_Careplans_V1_ExplainVitalCalculationRequest) async throws
        -> Acme_Careplans_V1_ExplainVitalCalculationResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "audit", detail: input.details.contact.email
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ExplainVitalCalculation",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VitalRecord(input.vital, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Seating_V1_ListSeatMapsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Seating_V1_ListSeatMapsRequest.Filter.with {
                $0.createdAfter = input.vital.subject.startsAt
                $0.labels = input.annotations
                $0.ownerID = input.vital.correlationID
            }
        }
        let reply0 = try await self.seatingSeatMap.listSeatMaps(outbound0)
        let requests1 = input.vital.measurements.map { element in
            Acme_Careplans_V1_PreviewCarePlanRequest.with {
                $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                    $0.counterparty = Acme_Appointments_V1_AppointmentRef.with {
                        $0.startsAt = element.observedAt
                    }
                    $0.lines = [
                        Acme_Careplans_V1_CarePlanLine.with {
                            $0.attributes = input.vital.attributes
                        }
                    ]
                }
                $0.context = input.context
                $0.details = Acme_Careplans_V1_PreviewCarePlanRequest.Details.with {
                    $0.contact = Acme_Common_V1_ContactInfo.with {
                        $0.name = input.details.contact.name
                    }
                }
            }
        }
        let replies1 = try await FanOut.map(requests1) { candidate in
            try await self.careplansCarePlanValidation.previewCarePlan(candidate)
        }
        let reply1 = replies1.first ?? Acme_Careplans_V1_PreviewCarePlanResponse()
        let selection2_2: String
        switch reply1.carePlan.settlement {
        case .card(let card):
            selection2_2 = card.network
        default: selection2_2 = .init()
        }
        let outbound2 = Acme_Careplans_V1_ExplainCarePlanCalculationRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = reply1.carePlan.billingAddress.region
                }
                $0.card = Acme_Careplans_V1_CarePlanCardSettlement.with {
                    $0.network = selection2_2
                }
            }
            $0.context = input.context
        }
        let reply2 = try await self.careplansCarePlanCalculation.explainCarePlanCalculation(outbound2)
        return Acme_Careplans_V1_ExplainVitalCalculationResponse.with {
            $0.outcome = Acme_Careplans_V1_ExplainVitalCalculationResponse.Outcome.with {
                $0.message = reply0.result.message
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.message = reply2.result.message
                $0.status = "ok"
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.sequence = input.vital.sequence
                $0.vitalID = input.vitalID
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processGetVitalRates(_ input: Acme_Careplans_V1_GetVitalRatesRequest) async throws
        -> Acme_Careplans_V1_GetVitalRatesResponse
    {
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "GetVitalRates",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "GetVitalRates", detail: input.context.traceID
        )
        let outbound0 = Acme_Careplans_V1_CalculateCarePlanRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = input.context.deadline
                }
            }
            $0.context = input.context
        }
        let envelope0 = try Google_Protobuf_Any(message: outbound0)
        let unpacked0 = try Acme_Careplans_V1_CalculateCarePlanRequest(unpackingAny: envelope0)
        let reply0 = try await self.careplansCarePlanCalculation.calculateCarePlan(unpacked0)
        let selection1_2: String
        switch reply0.carePlan.settlement {
        case .card(let card):
            selection1_2 = card.last4
        default: selection1_2 = .init()
        }
        let outbound1 = Acme_Careplans_V1_SimulateCarePlanRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.recipient = reply0.carePlan.billingAddress.recipient
                }
                $0.card = Acme_Careplans_V1_CarePlanCardSettlement.with {
                    $0.last4 = selection1_2
                }
            }
            $0.context = input.context
        }
        let reply1 = try await self.careplansCarePlanCalculation.simulateCarePlan(outbound1)
        return Acme_Careplans_V1_GetVitalRatesResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply1.result.message
                $0.status = "ok"
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.subject = Acme_Appointments_V1_AppointmentRef.with {
                    $0.startsAt = reply0.carePlan.counterparty.startsAt
                }
                $0.vitalID = input.vitalID
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processQuoteVital(_ input: Acme_Careplans_V1_QuoteVitalRequest) async throws
        -> Acme_Careplans_V1_QuoteVitalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.currencyCode)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "audit", detail: input.details.currencyCode
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "QuoteVital",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VitalRecord(input.vital, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Careplans_V1_EstimateCarePlanRequest.with {
            $0.context = input.context
            $0.details = Acme_Careplans_V1_EstimateCarePlanRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.locality = input.details.destination.locality
                }
            }
        }
        let json0 = try outbound0.jsonString()
        let decoded0 = try Acme_Careplans_V1_EstimateCarePlanRequest(jsonString: json0)
        let reply0 = try await self.careplansCarePlanCalculation.estimateCarePlan(decoded0)
        let outbound1 = Acme_Careplans_V1_SimulateCarePlanRequest.forVitalCalculationEndpointQuoteVital1(
            input
        )
        let reply1 = try await self.careplansCarePlanCalculation.simulateCarePlan(outbound1)
        return Acme_Careplans_V1_QuoteVitalResponse.with {
            $0.breakdown = Acme_Careplans_V1_QuoteVitalResponse.Breakdown.with {
                $0.total = Projection.firstValue(
                    [
                        reply0.carePlan.total,
                        reply1.breakdown.total,
                    ], default: .init())
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply1.result.referenceIds
                $0.status = "ok"
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.correlationID = input.vital.correlationID
                $0.vitalID = input.vitalID
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processRecalculateVitals(_ input: Acme_Careplans_V1_RecalculateVitalsRequest) async throws
        -> Acme_Careplans_V1_RecalculateVitalsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.destination.countryCode)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "audit", detail: input.details.destination.countryCode
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "RecalculateVitals",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VitalRecord(input.vital, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Tours_V1_WatchToursRequest.with {
            $0.context = input.context
            $0.filter = Acme_Tours_V1_WatchToursRequest.Filter.with {
                $0.createdAfter = input.vital.subject.startsAt
                $0.region = input.details.destination.region
            }
            $0.subscriber = Acme_Common_V1_ContactInfo.with {
                $0.email = input.context.actor.email
            }
        }
        let reply0 = try await self.toursTour.watchTours(outbound0) { response in
            var latest = Acme_Tours_V1_WatchToursResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        _ = reply0
        let outbound1 = Acme_Featureflags_V1_CreateFeatureFlagRequest.with {
            $0.context = input.context
            $0.featureFlag = Acme_Featureflags_V1_FeatureFlag.with {
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.vital.subject.displayName
                }
            }
        }
        let reply1 = try await self.featureflagsFeatureFlag.createFeatureFlag(
            outbound1, metadata: ["x-acme-region": .string(settings.region)]
        )
        return Acme_Careplans_V1_RecalculateVitalsResponse.with {
            $0.breakdown = Acme_Careplans_V1_RecalculateVitalsResponse.Breakdown.with {
                $0.currencyCode = input.details.currencyCode
                $0.lines = [
                    Acme_Careplans_V1_RecalculateVitalsResponse.Breakdown.Line.with {
                        $0.amount = reply1.featureFlag.discount.amount
                    }
                ]
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply1.result.referenceIds
                $0.status = "ok"
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.vitalID = input.vitalID
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processSimulateVital(_ input: Acme_Careplans_V1_SimulateVitalRequest) async throws
        -> Acme_Careplans_V1_SimulateVitalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.currencyCode)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "audit", detail: input.details.currencyCode
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "SimulateVital",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VitalRecord(input.vital, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Sponsorships_V1_WatchSponsorsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Sponsorships_V1_WatchSponsorsRequest.Filter.with {
                $0.region = input.details.destination.region
            }
        }
        let reply0 = try await self.sponsorshipsSponsor.watchSponsors(outbound0) { response in
            var latest = Acme_Sponsorships_V1_WatchSponsorsResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        _ = reply0
        return Acme_Careplans_V1_SimulateVitalResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.correlationID = input.vital.correlationID
                $0.vitalID = input.vitalID
            }
        }
    }
}
