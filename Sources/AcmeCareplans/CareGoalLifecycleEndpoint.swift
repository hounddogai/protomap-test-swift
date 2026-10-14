import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Moves a care goal between the states of its lifecycle.
final class CareGoalLifecycleEndpoint: Acme_Careplans_V1_CareGoalLifecycleService.ServiceProtocol {
    private let store: any RecordRepository
    private let logger: Logger
    private let settings: Settings
    private let auditAuditEventQuery: Acme_Audit_V1_AuditEventQueryService.Client<MeshTransport>
    private let careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>
    private let careplansCarePlanCalculation: Acme_Careplans_V1_CarePlanCalculationService.Client<MeshTransport>
    private let careplansVitalCalculation: Acme_Careplans_V1_VitalCalculationService.Client<MeshTransport>
    private let careplansVitalReporting: Acme_Careplans_V1_VitalReportingService.Client<MeshTransport>
    private let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    private let metricsMetricSeries: Acme_Metrics_V1_MetricSeriesService.Client<MeshTransport>
    private let searchSearchIndex: Acme_Search_V1_SearchIndexService.Client<MeshTransport>
    private let telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client<MeshTransport>
    private let telehealthVisitNoteCalculation: Acme_Telehealth_V1_VisitNoteCalculationService.Client<MeshTransport>
    private let telehealthVisitNoteQuery: Acme_Telehealth_V1_VisitNoteQueryService.Client<MeshTransport>
    private let expireCareGoalStep0:
        @Sendable (Acme_Careplans_V1_RecalculateCarePlansRequest) async throws ->
            Acme_Careplans_V1_RecalculateCarePlansResponse
    private let expireCareGoalStep1:
        [String:
            @Sendable (Acme_Audit_V1_SuggestAuditEventsRequest) async throws -> Acme_Audit_V1_SuggestAuditEventsResponse]

    init(
        dependencies: any Dependencies,
        auditAuditEventQuery: Acme_Audit_V1_AuditEventQueryService.Client<MeshTransport>,
        careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>,
        careplansCarePlanCalculation: Acme_Careplans_V1_CarePlanCalculationService.Client<MeshTransport>,
        careplansVitalCalculation: Acme_Careplans_V1_VitalCalculationService.Client<MeshTransport>,
        careplansVitalReporting: Acme_Careplans_V1_VitalReportingService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        metricsMetricSeries: Acme_Metrics_V1_MetricSeriesService.Client<MeshTransport>,
        searchSearchIndex: Acme_Search_V1_SearchIndexService.Client<MeshTransport>,
        telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client<MeshTransport>,
        telehealthVisitNoteCalculation: Acme_Telehealth_V1_VisitNoteCalculationService.Client<MeshTransport>,
        telehealthVisitNoteQuery: Acme_Telehealth_V1_VisitNoteQueryService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.auditAuditEventQuery = auditAuditEventQuery
        self.careplansCareGoalCalculation = careplansCareGoalCalculation
        self.careplansCarePlanCalculation = careplansCarePlanCalculation
        self.careplansVitalCalculation = careplansVitalCalculation
        self.careplansVitalReporting = careplansVitalReporting
        self.identityUser = identityUser
        self.metricsMetricSeries = metricsMetricSeries
        self.searchSearchIndex = searchSearchIndex
        self.telehealthVideoVisit = telehealthVideoVisit
        self.telehealthVisitNoteCalculation = telehealthVisitNoteCalculation
        self.telehealthVisitNoteQuery = telehealthVisitNoteQuery
        self.expireCareGoalStep0 = { request in try await careplansCarePlanCalculation.recalculateCarePlans(request) }
        self.expireCareGoalStep1 = [
            "primary": { request in try await auditAuditEventQuery.suggestAuditEvents(request) }
        ]
    }

    /// Activates a care goal.
    func activateCareGoal(
        request: ServerRequest<Acme_Careplans_V1_ActivateCareGoalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_ActivateCareGoalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processActivateCareGoal(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Expires a care goal.
    func expireCareGoal(
        request: ServerRequest<Acme_Careplans_V1_ExpireCareGoalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_ExpireCareGoalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processExpireCareGoal(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a care goal.
    func getCareGoalLifecycle(
        request: ServerRequest<Acme_Careplans_V1_GetCareGoalLifecycleRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_GetCareGoalLifecycleResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetCareGoalLifecycle(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Reinstates a care goal.
    func reinstateCareGoal(
        request: ServerRequest<Acme_Careplans_V1_ReinstateCareGoalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_ReinstateCareGoalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processReinstateCareGoal(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Renews a care goal.
    func renewCareGoal(
        request: ServerRequest<Acme_Careplans_V1_RenewCareGoalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_RenewCareGoalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRenewCareGoal(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Suspends a care goal.
    func suspendCareGoal(
        request: ServerRequest<Acme_Careplans_V1_SuspendCareGoalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_SuspendCareGoalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSuspendCareGoal(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Terminates a care goal.
    func terminateCareGoal(
        request: ServerRequest<Acme_Careplans_V1_TerminateCareGoalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_TerminateCareGoalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processTerminateCareGoal(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processActivateCareGoal(_ input: Acme_Careplans_V1_ActivateCareGoalRequest) async throws
        -> Acme_Careplans_V1_ActivateCareGoalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "audit", detail: input.details.newOwner.displayName
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ActivateCareGoal",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "ActivateCareGoal", detail: input.context.traceID
        )
        let importFrame = Acme_Telehealth_V1_BatchCreateVideoVisitsRequest.with {
            $0.context = input.context
        }
        _ = try await self.telehealthVideoVisit.batchCreateVideoVisits { writer in
            try await writer.write(importFrame)
        }
        let outbound0 = Acme_Telehealth_V1_CountVisitNotesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Telehealth_V1_CountVisitNotesRequest.Filter.with {
                $0.createdAfter = input.details.effectiveAt
                $0.labels = input.annotations
                $0.ownerID = input.careGoalID
            }
        }
        let port0 = RPCOperations.port { (request: Acme_Telehealth_V1_CountVisitNotesRequest) in
            try await self.telehealthVisitNoteQuery.countVisitNotes(request)
        }
        let reply0 = try await port0.execute(outbound0)
        return Acme_Careplans_V1_ActivateCareGoalResponse.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.careGoalID = input.careGoalID
            }
            $0.outcome = Acme_Careplans_V1_ActivateCareGoalResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processExpireCareGoal(_ input: Acme_Careplans_V1_ExpireCareGoalRequest) async throws
        -> Acme_Careplans_V1_ExpireCareGoalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "audit", detail: input.details.newOwner.email
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ExpireCareGoal",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "ExpireCareGoal", detail: input.context.traceID
        )
        let outbound0 = Acme_Careplans_V1_RecalculateCarePlansRequest.with {
            $0.annotations = input.annotations
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = input.details.effectiveAt
                }
                $0.counterparty = Acme_Appointments_V1_AppointmentRef.with {
                    $0.displayName = input.details.newOwner.displayName
                }
            }
            $0.context = input.context
            $0.reason = input.reason
        }
        let reply0 = try await self.expireCareGoalStep0(outbound0)
        let outbound1 = Acme_Audit_V1_SuggestAuditEventsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Audit_V1_SuggestAuditEventsRequest.Filter.with {
                $0.createdAfter = reply0.carePlan.counterparty.startsAt
                $0.labels = reply0.carePlan.metadata
                $0.ownerID = reply0.result.correlationID
                $0.region = reply0.carePlan.billingAddress.region
            }
        }
        guard let execute1 = self.expireCareGoalStep1[settings.region] ?? self.expireCareGoalStep1["primary"] else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply1 = try await execute1(outbound1)
        return Acme_Careplans_V1_ExpireCareGoalResponse.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply0.carePlan.audit.updatedBy
                }
                $0.careGoalID = input.careGoalID
            }
            $0.outcome = Acme_Careplans_V1_ExpireCareGoalResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
                $0.status = reply1.result.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply0.result.status
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processGetCareGoalLifecycle(_ input: Acme_Careplans_V1_GetCareGoalLifecycleRequest) async throws
        -> Acme_Careplans_V1_GetCareGoalLifecycleResponse
    {
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "GetCareGoalLifecycle",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "GetCareGoalLifecycle", detail: input.context.traceID
        )
        return Acme_Careplans_V1_GetCareGoalLifecycleResponse.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.careGoalID = input.careGoalID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processReinstateCareGoal(_ input: Acme_Careplans_V1_ReinstateCareGoalRequest) async throws
        -> Acme_Careplans_V1_ReinstateCareGoalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "audit", detail: input.details.newOwner.email
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ReinstateCareGoal",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "ReinstateCareGoal", detail: input.context.traceID
        )
        let outbound0 = Acme_Careplans_V1_QuoteVitalRequest.with {
            $0.context = input.context
            $0.reason = input.reason
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.subject = Acme_Appointments_V1_AppointmentRef.with {
                    $0.displayName = input.details.newOwner.displayName
                }
            }
        }
        let reply0 = try await self.careplansVitalCalculation.quoteVital(outbound0)
        let outbound1 = Acme_Careplans_V1_ListVitalReportsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Careplans_V1_ListVitalReportsRequest.Filter.with {
                $0.createdAfter = input.details.effectiveAt
                $0.labels = reply0.result.details
                $0.ownerID = input.details.newOwner.userID
            }
        }
        let envelope1 = try Google_Protobuf_Any(message: outbound1)
        let unpacked1 = try Acme_Careplans_V1_ListVitalReportsRequest(unpackingAny: envelope1)
        let reply1 = try await self.careplansVitalReporting.listVitalReports(unpacked1)
        return Acme_Careplans_V1_ReinstateCareGoalResponse.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.careGoalID = input.careGoalID
            }
            $0.outcome = Acme_Careplans_V1_ReinstateCareGoalResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.result.message
                $0.status = reply1.result.status
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processRenewCareGoal(_ input: Acme_Careplans_V1_RenewCareGoalRequest) async throws
        -> Acme_Careplans_V1_RenewCareGoalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "audit", detail: input.details.newOwner.displayName
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "RenewCareGoal",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "RenewCareGoal", detail: input.context.traceID
        )
        let outbound0 = Acme_Careplans_V1_GenerateVitalReportRequest.with {
            $0.annotations = input.annotations
            $0.context = input.context
            $0.details = Acme_Careplans_V1_GenerateVitalReportRequest.Details.with {
                $0.filters = input.context.baggage
            }
            $0.reason = input.reason
        }
        let json0 = try outbound0.jsonString()
        let decoded0 = try Acme_Careplans_V1_GenerateVitalReportRequest(jsonString: json0)
        let reply0 = try await self.careplansVitalReporting.generateVitalReport(decoded0)
        let outbound1 =
            Acme_Telehealth_V1_ExplainVisitNoteCalculationRequest.forCareGoalLifecycleEndpointRenewCareGoal1(
                input
            )
        let reply1 = try await self.telehealthVisitNoteCalculation.explainVisitNoteCalculation(outbound1)
        return Acme_Careplans_V1_RenewCareGoalResponse.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply1.visitNote.counterparty.displayName
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply1.visitNote.audit.createdAt
                }
                $0.careGoalID = input.careGoalID
            }
            $0.outcome = Acme_Careplans_V1_RenewCareGoalResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
                $0.status = reply0.result.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processSuspendCareGoal(_ input: Acme_Careplans_V1_SuspendCareGoalRequest) async throws
        -> Acme_Careplans_V1_SuspendCareGoalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "audit", detail: input.details.newOwner.displayName
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "SuspendCareGoal",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "SuspendCareGoal", detail: input.context.traceID
        )
        let outbound0 = Acme_Search_V1_UpdateSearchIndexRequest.with {
            $0.context = input.context
            $0.searchIndex = Acme_Search_V1_SearchIndex.with {
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.email = input.details.newOwner.email
                    $0.userID = input.details.newOwner.userID
                }
            }
        }
        let reply0 = try await self.searchSearchIndex.updateSearchIndex(
            outbound0, metadata: ["x-acme-region": .string(settings.region)]
        )
        let selection1_1: String
        switch reply0.searchIndex.locator {
        case .address(let address):
            selection1_1 = address.region
        default: selection1_1 = .init()
        }
        let outbound1 = Acme_Metrics_V1_ListMetricSeriesesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Metrics_V1_ListMetricSeriesesRequest.Filter.with {
                $0.createdAfter = reply0.searchIndex.audit.updatedAt
                $0.region = selection1_1
            }
        }
        let reply1 = try await self.metricsMetricSeries.listMetricSerieses(outbound1)
        return Acme_Careplans_V1_SuspendCareGoalResponse.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply0.searchIndex.audit.etag
                }
                $0.careGoalID = input.careGoalID
            }
            $0.outcome = Acme_Careplans_V1_SuspendCareGoalResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
                $0.status = Projection.firstValue(
                    [
                        reply0.result.status,
                        reply1.result.status,
                    ], default: .init())
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processTerminateCareGoal(_ input: Acme_Careplans_V1_TerminateCareGoalRequest) async throws
        -> Acme_Careplans_V1_TerminateCareGoalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "audit", detail: input.details.newOwner.displayName
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "TerminateCareGoal",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "TerminateCareGoal", detail: input.context.traceID
        )
        let outbound0 = Acme_Careplans_V1_SimulateCareGoalRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.customer = Acme_Patients_V1_PatientRef.with {
                    $0.email = input.details.notifyContact.email
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.preferredChannel = input.details.notifyContact.preferredChannel
                }
            }
            $0.context = input.context
        }
        let reply0 = try await RPCOperations.call(outbound0) { request in
            try await self.careplansCareGoalCalculation.simulateCareGoal(request)
        }
        let outbound1 = Acme_Careplans_V1_CalculateVitalRequest.with {
            $0.context = Projection.read(input, at: \Acme_Careplans_V1_TerminateCareGoalRequest.context)
            $0.details = Acme_Careplans_V1_CalculateVitalRequest.Details.with {
                $0.currencyCode = Projection.read(
                    reply0, at: \Acme_Careplans_V1_SimulateCareGoalResponse.breakdown.currencyCode)
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.correlationID = Projection.read(
                    reply0, at: \Acme_Careplans_V1_SimulateCareGoalResponse.result.correlationID)
                $0.subject = Acme_Appointments_V1_AppointmentRef.with {
                    $0.displayName = Projection.read(
                        reply0, at: \Acme_Careplans_V1_SimulateCareGoalResponse.careGoal.assignee.displayName)
                }
            }
        }
        let reply1 = try await self.careplansVitalCalculation.calculateVital(outbound1)
        return Acme_Careplans_V1_TerminateCareGoalResponse.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.careGoalID = input.careGoalID
            }
            $0.outcome = Acme_Careplans_V1_TerminateCareGoalResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
                $0.message = reply0.result.message
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply1.result.details
                $0.message = reply1.result.message
                $0.status = "ok"
            }
        }
    }
}
