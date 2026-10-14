import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Computes the figures of a video visit, such as totals, taxes, and estimates.
final class VideoVisitCalculationEndpoint: Acme_Telehealth_V1_VideoVisitCalculationService.ServiceProtocol {
    private let store: any RecordRepository
    private let logger: Logger
    private let settings: Settings
    private let authorizationAccessPolicyValidation:
        Acme_Authorization_V1_AccessPolicyValidationService.Client<MeshTransport>
    private let boxofficeBoxOfficeSale: Acme_Boxoffice_V1_BoxOfficeSaleService.Client<MeshTransport>
    private let careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>
    private let careplansCarePlanQuery: Acme_Careplans_V1_CarePlanQueryService.Client<MeshTransport>
    private let concessionsConcessionStandCalculation:
        Acme_Concessions_V1_ConcessionStandCalculationService.Client<MeshTransport>
    private let featureflagsFeatureFlag: Acme_Featureflags_V1_FeatureFlagService.Client<MeshTransport>
    private let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    private let ledgerLedgerAccountValidation: Acme_Ledger_V1_LedgerAccountValidationService.Client<MeshTransport>
    private let metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client<MeshTransport>
    private let notificationsNotification: Acme_Notifications_V1_NotificationService.Client<MeshTransport>
    private let toursTour: Acme_Tours_V1_TourService.Client<MeshTransport>
    private let calculateVideoVisitStep0:
        [String:
            @Sendable (Acme_Careplans_V1_SuggestCarePlansRequest) async throws ->
            Acme_Careplans_V1_SuggestCarePlansResponse]

    init(
        dependencies: any Dependencies,
        authorizationAccessPolicyValidation: Acme_Authorization_V1_AccessPolicyValidationService.Client<MeshTransport>,
        boxofficeBoxOfficeSale: Acme_Boxoffice_V1_BoxOfficeSaleService.Client<MeshTransport>,
        careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>,
        careplansCarePlanQuery: Acme_Careplans_V1_CarePlanQueryService.Client<MeshTransport>,
        concessionsConcessionStandCalculation: Acme_Concessions_V1_ConcessionStandCalculationService.Client<
            MeshTransport
        >,
        featureflagsFeatureFlag: Acme_Featureflags_V1_FeatureFlagService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        ledgerLedgerAccountValidation: Acme_Ledger_V1_LedgerAccountValidationService.Client<MeshTransport>,
        metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client<MeshTransport>,
        notificationsNotification: Acme_Notifications_V1_NotificationService.Client<MeshTransport>,
        toursTour: Acme_Tours_V1_TourService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.authorizationAccessPolicyValidation = authorizationAccessPolicyValidation
        self.boxofficeBoxOfficeSale = boxofficeBoxOfficeSale
        self.careplansCarePlan = careplansCarePlan
        self.careplansCarePlanQuery = careplansCarePlanQuery
        self.concessionsConcessionStandCalculation = concessionsConcessionStandCalculation
        self.featureflagsFeatureFlag = featureflagsFeatureFlag
        self.identityUser = identityUser
        self.ledgerLedgerAccountValidation = ledgerLedgerAccountValidation
        self.metricsMetricSeriesValidation = metricsMetricSeriesValidation
        self.notificationsNotification = notificationsNotification
        self.toursTour = toursTour
        self.calculateVideoVisitStep0 = [
            "primary": { request in try await careplansCarePlanQuery.suggestCarePlans(request) }
        ]
    }

    /// Calculates a video visit.
    func calculateVideoVisit(
        request: ServerRequest<Acme_Telehealth_V1_CalculateVideoVisitRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_CalculateVideoVisitResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCalculateVideoVisit(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Compares a video visit.
    func compareVideoVisitOptions(
        request: ServerRequest<Acme_Telehealth_V1_CompareVideoVisitOptionsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_CompareVideoVisitOptionsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCompareVideoVisitOptions(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Estimates a video visit.
    func estimateVideoVisit(
        request: ServerRequest<Acme_Telehealth_V1_EstimateVideoVisitRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_EstimateVideoVisitResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processEstimateVideoVisit(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Explains a video visit.
    func explainVideoVisitCalculation(
        request: ServerRequest<Acme_Telehealth_V1_ExplainVideoVisitCalculationRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_ExplainVideoVisitCalculationResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processExplainVideoVisitCalculation(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a video visit.
    func getVideoVisitRates(
        request: ServerRequest<Acme_Telehealth_V1_GetVideoVisitRatesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_GetVideoVisitRatesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetVideoVisitRates(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Quotes a video visit.
    func quoteVideoVisit(
        request: ServerRequest<Acme_Telehealth_V1_QuoteVideoVisitRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_QuoteVideoVisitResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processQuoteVideoVisit(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Recalculates a video visit.
    func recalculateVideoVisits(
        request: ServerRequest<Acme_Telehealth_V1_RecalculateVideoVisitsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_RecalculateVideoVisitsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRecalculateVideoVisits(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Simulates a video visit.
    func simulateVideoVisit(
        request: ServerRequest<Acme_Telehealth_V1_SimulateVideoVisitRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_SimulateVideoVisitResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSimulateVideoVisit(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processCalculateVideoVisit(_ input: Acme_Telehealth_V1_CalculateVideoVisitRequest) async throws
        -> Acme_Telehealth_V1_CalculateVideoVisitResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.currencyCode)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "audit", detail: input.details.currencyCode
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "CalculateVideoVisit",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VideoVisitRecord(input.videoVisit, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let importFrame = Acme_Careplans_V1_BatchCreateCarePlansRequest.with {
            $0.context = input.context
        }
        _ = try await self.careplansCarePlan.batchCreateCarePlans { writer in
            try await writer.write(importFrame)
        }
        let outbound0 = Acme_Careplans_V1_SuggestCarePlansRequest.with {
            $0.context = input.context
            $0.filter = Acme_Careplans_V1_SuggestCarePlansRequest.Filter.with {
                $0.createdAfter = input.videoVisit.audit.updatedAt
                $0.labels = input.videoVisit.metadata
                $0.ownerID = input.videoVisit.organizer.userID
                $0.region = input.details.destination.region
            }
        }
        guard let execute0 = self.calculateVideoVisitStep0[settings.region] ?? self.calculateVideoVisitStep0["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply0 = try await execute0(outbound0)
        let requests1 = input.videoVisit.participants.map { element in
            Acme_Authorization_V1_CheckAccessPolicyEligibilityRequest.with {
                $0.accessPolicy = Acme_Authorization_V1_AccessPolicy.with {
                    $0.owner = Acme_Identity_V1_UserRef.with {
                        $0.email = element.contact.email
                    }
                }
                $0.context = input.context
                $0.details = Acme_Authorization_V1_CheckAccessPolicyEligibilityRequest.Details.with {
                    $0.contact = Acme_Common_V1_ContactInfo.with {
                        $0.name = element.contact.name
                        $0.phone = element.contact.phone
                        $0.preferredChannel = element.contact.preferredChannel
                    }
                }
            }
        }
        let replies1 = try await FanOut.map(requests1) { candidate in
            try await self.authorizationAccessPolicyValidation.checkAccessPolicyEligibility(candidate)
        }
        let reply1 = replies1.first ?? Acme_Authorization_V1_CheckAccessPolicyEligibilityResponse()
        let requests2 = input.videoVisit.participants.map { element in
            Acme_Tours_V1_SearchToursRequest.with {
                $0.context = input.context
                $0.filter = Acme_Tours_V1_SearchToursRequest.Filter.with {
                    $0.createdAfter = input.videoVisit.audit.updatedAt
                    $0.labels = reply1.result.details
                    $0.ownerID = element.participantID
                    $0.region = input.videoVisit.location.region
                }
            }
        }
        let replies2 = try await FanOut.map(requests2) { candidate in
            try await self.toursTour.searchTours(candidate)
        }
        let reply2 = replies2.first ?? Acme_Tours_V1_SearchToursResponse()
        _ = reply2
        return Acme_Telehealth_V1_CalculateVideoVisitResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply0.result.referenceIds
                $0.status = reply0.result.status
            }
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.organizer = input.videoVisit.organizer
                $0.videoVisitID = input.videoVisitID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processCompareVideoVisitOptions(_ input: Acme_Telehealth_V1_CompareVideoVisitOptionsRequest) async throws
        -> Acme_Telehealth_V1_CompareVideoVisitOptionsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.currencyCode)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "audit", detail: input.details.currencyCode
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "CompareVideoVisitOptions",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VideoVisitRecord(input.videoVisit, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let requests0 = input.videoVisit.participants.map { element in
            Acme_Concessions_V1_SimulateConcessionStandRequest.with {
                $0.concessionStand = Acme_Concessions_V1_ConcessionStand.with {
                    $0.address = Acme_Common_V1_PostalAddress.with {
                        $0.postalCode = input.videoVisit.location.postalCode
                        $0.recipient = input.videoVisit.location.recipient
                        $0.region = input.details.destination.region
                    }
                    $0.owner = Acme_Identity_V1_UserRef.with {
                        $0.email = element.contact.email
                    }
                }
                $0.context = input.context
            }
        }
        let replies0 = try await FanOut.map(requests0) { candidate in
            try await self.concessionsConcessionStandCalculation.simulateConcessionStand(candidate)
        }
        let reply0 = replies0.first ?? Acme_Concessions_V1_SimulateConcessionStandResponse()
        _ = reply0
        return Acme_Telehealth_V1_CompareVideoVisitOptionsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.metadata = input.videoVisit.metadata
                $0.videoVisitID = input.videoVisitID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processEstimateVideoVisit(_ input: Acme_Telehealth_V1_EstimateVideoVisitRequest) async throws
        -> Acme_Telehealth_V1_EstimateVideoVisitResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.destination.countryCode)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "audit", detail: input.details.destination.countryCode
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "EstimateVideoVisit",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VideoVisitRecord(input.videoVisit, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Featureflags_V1_CloneFeatureFlagRequest.with {
            $0.context = input.context
            $0.featureFlag = Acme_Featureflags_V1_FeatureFlag.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.videoVisit.audit.createdAt
                    $0.updatedAt = input.videoVisit.audit.updatedAt
                    $0.updatedBy = input.videoVisit.audit.updatedBy
                }
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.videoVisit.organizer.displayName
                }
            }
        }
        let reply0 = try await self.featureflagsFeatureFlag.cloneFeatureFlag(outbound0)
        let outbound1 = Acme_Metrics_V1_LintMetricSeriesesRequest.with {
            $0.context = input.context
            $0.details = Acme_Metrics_V1_LintMetricSeriesesRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply0.featureFlag.owner.email
                }
            }
            $0.metricSeries = Acme_Metrics_V1_MetricSeries.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = input.videoVisit.audit.etag
                }
            }
        }
        let envelope1 = try Google_Protobuf_Any(message: outbound1)
        let unpacked1 = try Acme_Metrics_V1_LintMetricSeriesesRequest(unpackingAny: envelope1)
        let reply1 = try await self.metricsMetricSeriesValidation.lintMetricSerieses(unpacked1)
        return Acme_Telehealth_V1_EstimateVideoVisitResponse.with {
            $0.breakdown = Acme_Telehealth_V1_EstimateVideoVisitResponse.Breakdown.with {
                $0.currencyCode = input.details.currencyCode
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.status = "ok"
            }
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = reply1.metricSeries.address.postalCode
                }
                $0.videoVisitID = input.videoVisitID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processExplainVideoVisitCalculation(_ input: Acme_Telehealth_V1_ExplainVideoVisitCalculationRequest)
        async throws -> Acme_Telehealth_V1_ExplainVideoVisitCalculationResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.phone)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "audit", detail: input.details.contact.phone
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ExplainVideoVisitCalculation",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VideoVisitRecord(input.videoVisit, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Ledger_V1_ValidateLedgerAccountRequest.with {
            $0.context = input.context
            $0.ledgerAccount = Acme_Ledger_V1_LedgerAccount.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.videoVisit.audit.createdAt
                }
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.contact.email
                    $0.name = input.details.contact.name
                }
                $0.holder = Acme_Ledger_V1_PostingBatchRef.with {
                    $0.displayName = input.videoVisit.organizer.displayName
                }
            }
        }
        let json0 = try outbound0.jsonString()
        let decoded0 = try Acme_Ledger_V1_ValidateLedgerAccountRequest(jsonString: json0)
        let reply0 = try await self.ledgerLedgerAccountValidation.validateLedgerAccount(decoded0)
        return Acme_Telehealth_V1_ExplainVideoVisitCalculationResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.location = input.videoVisit.location
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply0.ledgerAccount.holder.displayName
                }
                $0.participants = [
                    Acme_Telehealth_V1_VideoVisitParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = reply0.ledgerAccount.contact.email
                        }
                    }
                ]
                $0.videoVisitID = input.videoVisitID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processGetVideoVisitRates(_ input: Acme_Telehealth_V1_GetVideoVisitRatesRequest) async throws
        -> Acme_Telehealth_V1_GetVideoVisitRatesResponse
    {
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "GetVideoVisitRates",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "GetVideoVisitRates", detail: input.context.traceID
        )
        let outbound0 = Acme_Ledger_V1_PreviewLedgerAccountRequest.forVideoVisitCalculationEndpointGetVideoVisitRates0(
            input
        )
        let reply0 = try await self.ledgerLedgerAccountValidation.previewLedgerAccount(outbound0)
        return Acme_Telehealth_V1_GetVideoVisitRatesResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.participants = [
                    Acme_Telehealth_V1_VideoVisitParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.name = reply0.ledgerAccount.contact.name
                        }
                    }
                ]
                $0.videoVisitID = input.videoVisitID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processQuoteVideoVisit(_ input: Acme_Telehealth_V1_QuoteVideoVisitRequest) async throws
        -> Acme_Telehealth_V1_QuoteVideoVisitResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.currencyCode)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "audit", detail: input.details.currencyCode
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "QuoteVideoVisit",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VideoVisitRecord(input.videoVisit, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Careplans_V1_SuggestCarePlansRequest.with {
            $0.context = input.context
            $0.filter = Acme_Careplans_V1_SuggestCarePlansRequest.Filter.with {
                $0.createdAfter = input.videoVisit.audit.createdAt
                $0.labels = input.videoVisit.metadata
                $0.region = input.details.destination.region
            }
        }
        let reply0 = try await self.careplansCarePlanQuery.suggestCarePlans(
            outbound0, metadata: ["x-acme-region": .string(settings.region)]
        )
        return Acme_Telehealth_V1_QuoteVideoVisitResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.result.message
                $0.status = reply0.result.status
            }
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.videoVisitID = input.videoVisitID
                $0.window = input.videoVisit.window
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processRecalculateVideoVisits(_ input: Acme_Telehealth_V1_RecalculateVideoVisitsRequest) async throws
        -> Acme_Telehealth_V1_RecalculateVideoVisitsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.currencyCode)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "audit", detail: input.details.currencyCode
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "RecalculateVideoVisits",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VideoVisitRecord(input.videoVisit, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Featureflags_V1_ListFeatureFlagsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Featureflags_V1_ListFeatureFlagsRequest.Filter.with {
                $0.createdAfter = input.videoVisit.audit.createdAt
                $0.region = input.videoVisit.location.region
            }
        }
        let reply0 = try await RPCOperations.call(outbound0) { request in
            try await self.featureflagsFeatureFlag.listFeatureFlags(request)
        }
        let outbound1 = Acme_Boxoffice_V1_WatchBoxOfficeSalesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Boxoffice_V1_WatchBoxOfficeSalesRequest.Filter.with {
                $0.region = input.details.destination.region
            }
        }
        let reply1 = try await self.boxofficeBoxOfficeSale.watchBoxOfficeSales(outbound1) { response in
            var latest = Acme_Boxoffice_V1_WatchBoxOfficeSalesResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        _ = reply1
        let outbound2 = Acme_Careplans_V1_WatchCarePlansRequest.with {
            $0.context = input.context
            $0.filter = Acme_Careplans_V1_WatchCarePlansRequest.Filter.with {
                $0.region = input.videoVisit.location.region
            }
        }
        let reply2 = try await self.careplansCarePlan.watchCarePlans(outbound2) { response in
            var latest = Acme_Careplans_V1_WatchCarePlansResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        _ = reply2
        let requests3 = input.videoVisit.participants.map { element in
            Acme_Ledger_V1_ValidateLedgerAccountRequest.with {
                $0.context = input.context
                $0.details = Acme_Ledger_V1_ValidateLedgerAccountRequest.Details.with {
                    $0.contact = Acme_Common_V1_ContactInfo.with {
                        $0.email = element.contact.email
                        $0.phone = element.contact.phone
                    }
                }
            }
        }
        let replies3 = try await FanOut.map(requests3) { candidate in
            try await self.ledgerLedgerAccountValidation.validateLedgerAccount(candidate)
        }
        let reply3 = replies3.first ?? Acme_Ledger_V1_ValidateLedgerAccountResponse()
        _ = reply3
        return Acme_Telehealth_V1_RecalculateVideoVisitsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.result.message
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.status = input.videoVisit.status
                $0.videoVisitID = input.videoVisitID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processSimulateVideoVisit(_ input: Acme_Telehealth_V1_SimulateVideoVisitRequest) async throws
        -> Acme_Telehealth_V1_SimulateVideoVisitResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.currencyCode)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "audit", detail: input.details.currencyCode
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "SimulateVideoVisit",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VideoVisitRecord(input.videoVisit, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Notifications_V1_BatchGetNotificationsRequest.with {
            $0.context = Projection.read(input, at: \Acme_Telehealth_V1_SimulateVideoVisitRequest.context)
        }
        let reply0 = try await self.notificationsNotification.batchGetNotifications(outbound0)
        return Acme_Telehealth_V1_SimulateVideoVisitResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply0.result.status
            }
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.videoVisitID = input.videoVisitID
                $0.window = input.videoVisit.window
            }
        }
    }
}
