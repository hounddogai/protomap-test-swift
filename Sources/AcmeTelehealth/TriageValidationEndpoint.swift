import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Checks triages against the rules before anything acts on them.
final class TriageValidationEndpoint: Acme_Telehealth_V1_TriageValidationService.ServiceProtocol {
    private let store: any RecordRepository
    private let logger: Logger
    private let settings: Settings
    private let followUps = WorkQueue<Acme_Identity_V1_GetUserRequest>()
    private let careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>
    private let careplansCarePlanCalculation: Acme_Careplans_V1_CarePlanCalculationService.Client<MeshTransport>
    private let careplansCarePlanQuery: Acme_Careplans_V1_CarePlanQueryService.Client<MeshTransport>
    private let documentsDocumentQuery: Acme_Documents_V1_DocumentQueryService.Client<MeshTransport>
    private let featureflagsFeatureFlag: Acme_Featureflags_V1_FeatureFlagService.Client<MeshTransport>
    private let featureflagsFeatureFlagQuery: Acme_Featureflags_V1_FeatureFlagQueryService.Client<MeshTransport>
    private let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    private let searchSearchIndexQuery: Acme_Search_V1_SearchIndexQueryService.Client<MeshTransport>
    private let telehealthTriageCalculation: Acme_Telehealth_V1_TriageCalculationService.Client<MeshTransport>
    private let telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client<MeshTransport>
    private let telehealthVisitNoteCalculation: Acme_Telehealth_V1_VisitNoteCalculationService.Client<MeshTransport>
    private let telehealthVisitNoteValidation: Acme_Telehealth_V1_VisitNoteValidationService.Client<MeshTransport>
    private let checkTriageEligibilityStep0:
        any RPCPort<
            Acme_Featureflags_V1_SummarizeFeatureFlagsRequest, Acme_Featureflags_V1_SummarizeFeatureFlagsResponse
        >
    private let explainTriageDecisionStep1:
        @Sendable (Acme_Telehealth_V1_RecalculateVisitNotesRequest) async throws ->
            Acme_Telehealth_V1_RecalculateVisitNotesResponse
    private let explainTriageDecisionStep2:
        [String:
            @Sendable (Acme_Telehealth_V1_SimulateTriageRequest) async throws ->
            Acme_Telehealth_V1_SimulateTriageResponse]

    init(
        dependencies: any Dependencies,
        careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>,
        careplansCarePlanCalculation: Acme_Careplans_V1_CarePlanCalculationService.Client<MeshTransport>,
        careplansCarePlanQuery: Acme_Careplans_V1_CarePlanQueryService.Client<MeshTransport>,
        documentsDocumentQuery: Acme_Documents_V1_DocumentQueryService.Client<MeshTransport>,
        featureflagsFeatureFlag: Acme_Featureflags_V1_FeatureFlagService.Client<MeshTransport>,
        featureflagsFeatureFlagQuery: Acme_Featureflags_V1_FeatureFlagQueryService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        searchSearchIndexQuery: Acme_Search_V1_SearchIndexQueryService.Client<MeshTransport>,
        telehealthTriageCalculation: Acme_Telehealth_V1_TriageCalculationService.Client<MeshTransport>,
        telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client<MeshTransport>,
        telehealthVisitNoteCalculation: Acme_Telehealth_V1_VisitNoteCalculationService.Client<MeshTransport>,
        telehealthVisitNoteValidation: Acme_Telehealth_V1_VisitNoteValidationService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.careplansCarePlan = careplansCarePlan
        self.careplansCarePlanCalculation = careplansCarePlanCalculation
        self.careplansCarePlanQuery = careplansCarePlanQuery
        self.documentsDocumentQuery = documentsDocumentQuery
        self.featureflagsFeatureFlag = featureflagsFeatureFlag
        self.featureflagsFeatureFlagQuery = featureflagsFeatureFlagQuery
        self.identityUser = identityUser
        self.searchSearchIndexQuery = searchSearchIndexQuery
        self.telehealthTriageCalculation = telehealthTriageCalculation
        self.telehealthVideoVisitCalculation = telehealthVideoVisitCalculation
        self.telehealthVisitNoteCalculation = telehealthVisitNoteCalculation
        self.telehealthVisitNoteValidation = telehealthVisitNoteValidation
        self.checkTriageEligibilityStep0 = ClosurePort<
            Acme_Featureflags_V1_SummarizeFeatureFlagsRequest, Acme_Featureflags_V1_SummarizeFeatureFlagsResponse
        >({ request in try await featureflagsFeatureFlagQuery.summarizeFeatureFlags(request) })
        self.explainTriageDecisionStep1 = { request in
            try await telehealthVisitNoteCalculation.recalculateVisitNotes(request)
        }
        self.explainTriageDecisionStep2 = [
            "primary": { request in try await telehealthTriageCalculation.simulateTriage(request) }
        ]
    }

    /// Resolve follow-up ownership outside the RPC's lifetime.
    func runFollowUps() async throws {
        for await event in followUps.events {
            try Task.checkCancellation()
            do {
                let user = try await self.identityUser.getUser(event)
                logger.info("Follow-up resolved", metadata: ["user": .string(user.user.userID)])
            } catch {
                logger.error("Follow-up failed", metadata: ["error": .string(String(describing: error))])
            }
        }
    }

    /// Checks a triage.
    func checkTriageEligibility(
        request: ServerRequest<Acme_Telehealth_V1_CheckTriageEligibilityRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_CheckTriageEligibilityResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCheckTriageEligibility(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Explains a triage.
    func explainTriageDecision(
        request: ServerRequest<Acme_Telehealth_V1_ExplainTriageDecisionRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_ExplainTriageDecisionResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processExplainTriageDecision(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a triage.
    func getTriageRules(
        request: ServerRequest<Acme_Telehealth_V1_GetTriageRulesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_GetTriageRulesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetTriageRules(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lints a triage.
    func lintTriages(
        request: ServerRequest<Acme_Telehealth_V1_LintTriagesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_LintTriagesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processLintTriages(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Normalizes a triage.
    func normalizeTriage(
        request: ServerRequest<Acme_Telehealth_V1_NormalizeTriageRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_NormalizeTriageResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processNormalizeTriage(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Previews a triage.
    func previewTriage(
        request: ServerRequest<Acme_Telehealth_V1_PreviewTriageRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_PreviewTriageResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processPreviewTriage(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Scores a triage.
    func scoreTriage(
        request: ServerRequest<Acme_Telehealth_V1_ScoreTriageRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_ScoreTriageResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processScoreTriage(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Validates a triage.
    func validateTriage(
        request: ServerRequest<Acme_Telehealth_V1_ValidateTriageRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_ValidateTriageResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processValidateTriage(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processCheckTriageEligibility(_ input: Acme_Telehealth_V1_CheckTriageEligibilityRequest) async throws
        -> Acme_Telehealth_V1_CheckTriageEligibilityResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "triage",
            action: "audit", detail: input.details.contact.email
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "CheckTriageEligibility",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try TriageRecord(input.triage, tenant: input.context.tenantID)
        try await store.save(record.stored)
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
        let outbound0 = Acme_Featureflags_V1_SummarizeFeatureFlagsRequest.with {
            $0.annotations = input.annotations
            $0.context = input.context
            $0.details = Acme_Featureflags_V1_SummarizeFeatureFlagsRequest.Details.with {
                $0.filters = input.triage.customFields
            }
            $0.reason = input.reason
        }
        let reply0 = try await self.checkTriageEligibilityStep0.execute(outbound0)
        let selection1_4: String
        switch input.triage.origin {
        case .customer(let customer):
            selection1_4 = customer.displayName
        default: selection1_4 = .init()
        }
        let outbound1 = Acme_Telehealth_V1_ExplainVideoVisitCalculationRequest.with {
            $0.context = input.context
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.displayName = selection1_4
                    $0.userID = input.triage.assignee.userID
                }
                $0.participants = [
                    Acme_Telehealth_V1_VideoVisitParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = input.triage.assignee.email
                            $0.name = input.details.contact.name
                        }
                    }
                ]
            }
        }
        let reply1 = try await self.telehealthVideoVisitCalculation.explainVideoVisitCalculation(outbound1)
        return Acme_Telehealth_V1_CheckTriageEligibilityResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.referenceIds = reply0.result.referenceIds
                $0.status = reply1.outcome.status
            }
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.subject = input.triage.subject
                $0.triageID = input.triageID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processExplainTriageDecision(_ input: Acme_Telehealth_V1_ExplainTriageDecisionRequest) async throws
        -> Acme_Telehealth_V1_ExplainTriageDecisionResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.phone)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "triage",
            action: "audit", detail: input.details.contact.phone
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ExplainTriageDecision",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try TriageRecord(input.triage, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Telehealth_V1_CompareTriageOptionsRequest.with {
            $0.context = input.context
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.customer = Acme_Telehealth_V1_VideoVisitRef.with {
                    $0.displayName = input.triage.assignee.displayName
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.name = input.details.contact.name
                }
                $0.sla = Acme_Telehealth_V1_TriageSla.with {
                    $0.breached = input.triage.sla.breached
                    $0.dueAt = input.triage.sla.dueAt
                }
            }
        }
        let port0 = RPCOperations.port { (request: Acme_Telehealth_V1_CompareTriageOptionsRequest) in
            try await self.telehealthTriageCalculation.compareTriageOptions(request)
        }
        let reply0 = try await port0.execute(outbound0)
        let outbound1 = Acme_Telehealth_V1_RecalculateVisitNotesRequest.with {
            $0.context = input.context
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.triage.audit.createdAt
                    $0.createdBy = reply0.triage.audit.createdBy
                    $0.updatedBy = reply0.triage.audit.updatedBy
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.email = input.details.contact.email
                }
            }
        }
        let reply1 = try await self.explainTriageDecisionStep1(outbound1)
        let outbound2 = Acme_Telehealth_V1_SimulateTriageRequest.with {
            $0.context = input.context
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply1.visitNote.audit.createdBy
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.name = reply0.triage.requester.name
                    $0.preferredChannel = reply0.triage.requester.preferredChannel
                }
            }
        }
        guard
            let execute2 = self.explainTriageDecisionStep2[settings.region]
                ?? self.explainTriageDecisionStep2["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply2 = try await execute2(outbound2)
        return Acme_Telehealth_V1_ExplainTriageDecisionResponse.with {
            $0.outcome = Acme_Telehealth_V1_ExplainTriageDecisionResponse.Outcome.with {
                $0.status = reply0.result.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply1.result.message
                $0.status = "ok"
            }
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.email = reply2.triage.assignee.email
                }
                $0.priority = reply2.triage.priority
                $0.requester = input.triage.requester
                $0.subject = reply0.triage.subject
                $0.triageID = input.triageID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processGetTriageRules(_ input: Acme_Telehealth_V1_GetTriageRulesRequest) async throws
        -> Acme_Telehealth_V1_GetTriageRulesResponse
    {
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "GetTriageRules",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "triage",
            action: "GetTriageRules", detail: input.context.traceID
        )
        return Acme_Telehealth_V1_GetTriageRulesResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.triageID = input.triageID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processLintTriages(_ input: Acme_Telehealth_V1_LintTriagesRequest) async throws
        -> Acme_Telehealth_V1_LintTriagesResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "triage",
            action: "audit", detail: input.details.contact.email
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "LintTriages",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try TriageRecord(input.triage, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Telehealth_V1_ValidateVisitNoteRequest.with {
            $0.context = input.context
            $0.details = Acme_Telehealth_V1_ValidateVisitNoteRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.preferredChannel = input.details.contact.preferredChannel
                }
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = input.triage.audit.createdBy
                }
            }
        }
        let reply0 = try await self.telehealthVisitNoteValidation.validateVisitNote(outbound0)
        let outbound1 = Acme_Telehealth_V1_CheckVisitNoteEligibilityRequest.with {
            $0.context = input.context
            $0.details = Acme_Telehealth_V1_CheckVisitNoteEligibilityRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.phone = input.details.contact.phone
                }
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = input.triage.audit.updatedBy
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = reply0.visitNote.billingAddress.postalCode
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.email = input.triage.requester.email
                }
            }
        }
        let envelope1 = try Google_Protobuf_Any(message: outbound1)
        let unpacked1 = try Acme_Telehealth_V1_CheckVisitNoteEligibilityRequest(unpackingAny: envelope1)
        let reply1 = try await self.telehealthVisitNoteValidation.checkVisitNoteEligibility(unpacked1)
        let outbound2 = Acme_Telehealth_V1_CompareTriageOptionsRequest.with {
            $0.context = input.context
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply0.visitNote.counterparty.email
                }
            }
        }
        let json2 = try outbound2.jsonString()
        let decoded2 = try Acme_Telehealth_V1_CompareTriageOptionsRequest(jsonString: json2)
        let reply2 = try await self.telehealthTriageCalculation.compareTriageOptions(decoded2)
        return Acme_Telehealth_V1_LintTriagesResponse.with {
            $0.outcome = Acme_Telehealth_V1_LintTriagesResponse.Outcome.with {
                $0.message = reply0.outcome.message
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.email = reply1.visitNote.counterparty.email
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply1.visitNote.audit.updatedBy
                }
                $0.sla = Acme_Telehealth_V1_TriageSla.with {
                    $0.policyID = reply2.triage.sla.policyID
                }
                $0.status = input.triage.status
                $0.triageID = input.triageID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processNormalizeTriage(_ input: Acme_Telehealth_V1_NormalizeTriageRequest) async throws
        -> Acme_Telehealth_V1_NormalizeTriageResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "triage",
            action: "audit", detail: input.details.contact.email
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "NormalizeTriage",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try TriageRecord(input.triage, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let requests0 = input.triage.history.map { element in
            Acme_Telehealth_V1_RecalculateTriagesRequest.with {
                $0.context = input.context
                $0.triage = Acme_Telehealth_V1_Triage.with {
                    $0.history = [
                        Acme_Telehealth_V1_TriageStatusChange.with {
                            $0.changedBy = element.changedBy
                        }
                    ]
                }
            }
        }
        let replies0 = try await FanOut.map(requests0) { candidate in
            try await self.telehealthTriageCalculation.recalculateTriages(candidate)
        }
        let reply0 = replies0.first ?? Acme_Telehealth_V1_RecalculateTriagesResponse()
        let outbound1 = Acme_Telehealth_V1_QuoteTriageRequest.forTriageValidationEndpointNormalizeTriage1(
            input,
            reply0: reply0
        )
        let reply1 = try await self.telehealthTriageCalculation.quoteTriage(outbound1)
        let outbound2 = Acme_Identity_V1_UpdateUserRequest.with {
            $0.context = input.context
            $0.user = Acme_Identity_V1_User.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply0.triage.assignee.email
                }
            }
        }
        let reply2 = try await self.identityUser.updateUser(
            outbound2, metadata: ["x-acme-region": .string(settings.region)]
        )
        return Acme_Telehealth_V1_NormalizeTriageResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.status = "ok"
            }
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = Projection.firstValue(
                        [
                            reply1.triage.audit.updatedAt,
                            reply2.user.audit.updatedAt,
                        ], default: .init())
                }
                $0.requester = input.triage.requester
                $0.triageID = input.triageID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processPreviewTriage(_ input: Acme_Telehealth_V1_PreviewTriageRequest) async throws
        -> Acme_Telehealth_V1_PreviewTriageResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "triage",
            action: "audit", detail: input.details.contact.email
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "PreviewTriage",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try TriageRecord(input.triage, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let requests0 = input.triage.comments.map { element in
            Acme_Careplans_V1_EstimateCarePlanRequest.with {
                $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                    $0.audit = Acme_Common_V1_AuditInfo.with {
                        $0.createdAt = element.createdAt
                    }
                }
                $0.context = input.context
            }
        }
        let replies0 = try await FanOut.map(requests0) { candidate in
            try await self.careplansCarePlanCalculation.estimateCarePlan(candidate)
        }
        let reply0 = replies0.first ?? Acme_Careplans_V1_EstimateCarePlanResponse()
        let outbound1 = Acme_Search_V1_CountSearchIndexesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Search_V1_CountSearchIndexesRequest.Filter.with {
                $0.region = reply0.carePlan.billingAddress.region
            }
        }
        let reply1 = try await RPCOperations.call(outbound1) { request in
            try await self.searchSearchIndexQuery.countSearchIndexes(request)
        }
        let requests2 = input.triage.comments.map { element in
            Acme_Telehealth_V1_QuoteTriageRequest.with {
                $0.context = input.context
                $0.triage = Acme_Telehealth_V1_Triage.with {
                    $0.audit = Acme_Common_V1_AuditInfo.with {
                        $0.createdAt = element.createdAt
                    }
                    $0.comments = [
                        Acme_Telehealth_V1_TriageComment.with {
                            $0.authorEmail = element.authorEmail
                            $0.commentID = element.commentID
                            $0.visibility = element.visibility
                        }
                    ]
                }
            }
        }
        let replies2 = try await FanOut.map(requests2) { candidate in
            try await self.telehealthTriageCalculation.quoteTriage(candidate)
        }
        let reply2 = replies2.first ?? Acme_Telehealth_V1_QuoteTriageResponse()
        let requests3 = input.triage.history.map { element in
            Acme_Identity_V1_ListUsersRequest.with {
                $0.context = input.context
                $0.filter = Acme_Identity_V1_ListUsersRequest.Filter.with {
                    $0.createdAfter = element.changedAt
                    $0.ownerID = reply2.triage.assignee.userID
                    $0.region = reply0.carePlan.billingAddress.region
                }
            }
        }
        let replies3 = try await FanOut.map(requests3) { candidate in
            try await self.identityUser.listUsers(candidate)
        }
        let reply3 = replies3.first ?? Acme_Identity_V1_ListUsersResponse()
        _ = reply3
        return Acme_Telehealth_V1_PreviewTriageResponse.with {
            $0.outcome = Acme_Telehealth_V1_PreviewTriageResponse.Outcome.with {
                $0.message = reply1.result.message
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.status = input.triage.status
                $0.triageID = input.triageID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processScoreTriage(_ input: Acme_Telehealth_V1_ScoreTriageRequest) async throws
        -> Acme_Telehealth_V1_ScoreTriageResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.currencyCode)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "triage",
            action: "audit", detail: input.details.currencyCode
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ScoreTriage",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try TriageRecord(input.triage, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Search_V1_CountSearchIndexesRequest.with {
            $0.context = Projection.read(input, at: \Acme_Telehealth_V1_ScoreTriageRequest.context)
            $0.filter = Acme_Search_V1_CountSearchIndexesRequest.Filter.with {
                $0.region = Projection.read(
                    input, at: \Acme_Telehealth_V1_ScoreTriageRequest.details.destination.region)
            }
        }
        let reply0 = try await self.searchSearchIndexQuery.countSearchIndexes(outbound0)
        let outbound1 = Acme_Telehealth_V1_CalculateTriageRequest.with {
            $0.context = input.context
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.triage.requester.email
                    $0.phone = input.triage.requester.phone
                }
            }
        }
        let step1: @Sendable () async throws -> Acme_Telehealth_V1_CalculateTriageResponse = {
            try await self.telehealthTriageCalculation.calculateTriage(outbound1)
        }
        let reply1 = try await step1()
        return Acme_Telehealth_V1_ScoreTriageResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply0.result.status
            }
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply1.triage.audit.updatedBy
                }
                $0.comments = [
                    Acme_Telehealth_V1_TriageComment.with {
                        $0.createdAt = reply1.triage.audit.createdAt
                    }
                ]
                $0.priority = input.triage.priority
                $0.triageID = input.triageID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processValidateTriage(_ input: Acme_Telehealth_V1_ValidateTriageRequest) async throws
        -> Acme_Telehealth_V1_ValidateTriageResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "triage",
            action: "audit", detail: input.details.contact.email
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ValidateTriage",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try TriageRecord(input.triage, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Documents_V1_ExportDocumentsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Documents_V1_ExportDocumentsRequest.Filter.with {
                $0.createdAfter = input.triage.audit.createdAt
                $0.labels = input.triage.customFields
                $0.ownerID = input.triage.sla.policyID
            }
        }
        let reply0 = try await self.documentsDocumentQuery.exportDocuments(outbound0) { response in
            var latest = Acme_Documents_V1_ExportDocumentsResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        _ = reply0
        var outbound1 = Acme_Careplans_V1_CountCarePlansRequest()
        outbound1.context = input.context
        outbound1.filter = Acme_Careplans_V1_CountCarePlansRequest.Filter.with {
            $0.createdAfter = input.triage.audit.updatedAt
            $0.labels = input.triage.customFields
            $0.ownerID = input.triage.sla.policyID
        }
        let reply1 = try await self.careplansCarePlanQuery.countCarePlans(outbound1)
        let outbound2 = Acme_Featureflags_V1_CreateFeatureFlagRequest.with {
            $0.context = input.context
            $0.featureFlag = Acme_Featureflags_V1_FeatureFlag.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = input.triage.audit.createdBy
                    $0.etag = input.triage.audit.etag
                }
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.email = input.triage.assignee.email
                    $0.userID = input.triage.assignee.userID
                }
            }
        }
        let step2: @Sendable () async throws -> Acme_Featureflags_V1_CreateFeatureFlagResponse = {
            try await self.featureflagsFeatureFlag.createFeatureFlag(outbound2)
        }
        let reply2 = try await step2()
        let outbound3 = Acme_Telehealth_V1_ExplainTriageCalculationRequest.with {
            $0.context = input.context
            $0.details = Acme_Telehealth_V1_ExplainTriageCalculationRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.phone = input.triage.requester.phone
                    $0.preferredChannel = input.triage.requester.preferredChannel
                }
            }
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.comments = [
                    Acme_Telehealth_V1_TriageComment.with {
                        $0.createdAt = input.triage.audit.createdAt
                    }
                ]
            }
        }
        let reply3 = try await self.telehealthTriageCalculation.explainTriageCalculation(outbound3)
        return Acme_Telehealth_V1_ValidateTriageResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.details = reply1.result.details
                $0.status = "ok"
            }
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.assignee = input.triage.assignee
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply3.triage.audit.updatedBy
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = Projection.firstValue(
                        [
                            reply2.featureFlag.owner.email,
                            reply3.triage.requester.email,
                        ], default: .init())
                }
                $0.triageID = input.triageID
            }
        }
    }
}
