import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Checks visit notes against the rules before anything acts on them.
final class VisitNoteValidationEndpoint: Acme_Telehealth_V1_VisitNoteValidationService.ServiceProtocol {
    private let store: any RecordRepository
    private let logger: Logger
    private let settings: Settings
    private let followUps = WorkQueue<Acme_Identity_V1_GetUserRequest>()
    private let authorizationAccessPolicy: Acme_Authorization_V1_AccessPolicyService.Client<MeshTransport>
    private let authorizationAccessPolicyValidation:
        Acme_Authorization_V1_AccessPolicyValidationService.Client<MeshTransport>
    private let careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>
    private let careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client<MeshTransport>
    private let featureflagsFeatureFlag: Acme_Featureflags_V1_FeatureFlagService.Client<MeshTransport>
    private let featureflagsFeatureFlagValidation:
        Acme_Featureflags_V1_FeatureFlagValidationService.Client<MeshTransport>
    private let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    private let sponsorshipsSponsorCalculation: Acme_Sponsorships_V1_SponsorCalculationService.Client<MeshTransport>
    private let telehealthTriageCalculation: Acme_Telehealth_V1_TriageCalculationService.Client<MeshTransport>
    private let telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client<MeshTransport>
    private let telehealthVideoVisitValidation: Acme_Telehealth_V1_VideoVisitValidationService.Client<MeshTransport>
    private let telehealthVisitNoteCalculation: Acme_Telehealth_V1_VisitNoteCalculationService.Client<MeshTransport>
    private let validateVisitNoteStep1:
        any RPCPort<Acme_Sponsorships_V1_EstimateSponsorRequest, Acme_Sponsorships_V1_EstimateSponsorResponse>

    init(
        dependencies: any Dependencies,
        authorizationAccessPolicy: Acme_Authorization_V1_AccessPolicyService.Client<MeshTransport>,
        authorizationAccessPolicyValidation: Acme_Authorization_V1_AccessPolicyValidationService.Client<MeshTransport>,
        careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>,
        careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client<MeshTransport>,
        featureflagsFeatureFlag: Acme_Featureflags_V1_FeatureFlagService.Client<MeshTransport>,
        featureflagsFeatureFlagValidation: Acme_Featureflags_V1_FeatureFlagValidationService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        sponsorshipsSponsorCalculation: Acme_Sponsorships_V1_SponsorCalculationService.Client<MeshTransport>,
        telehealthTriageCalculation: Acme_Telehealth_V1_TriageCalculationService.Client<MeshTransport>,
        telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client<MeshTransport>,
        telehealthVideoVisitValidation: Acme_Telehealth_V1_VideoVisitValidationService.Client<MeshTransport>,
        telehealthVisitNoteCalculation: Acme_Telehealth_V1_VisitNoteCalculationService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.authorizationAccessPolicy = authorizationAccessPolicy
        self.authorizationAccessPolicyValidation = authorizationAccessPolicyValidation
        self.careplansCarePlan = careplansCarePlan
        self.careplansCarePlanValidation = careplansCarePlanValidation
        self.featureflagsFeatureFlag = featureflagsFeatureFlag
        self.featureflagsFeatureFlagValidation = featureflagsFeatureFlagValidation
        self.identityUser = identityUser
        self.sponsorshipsSponsorCalculation = sponsorshipsSponsorCalculation
        self.telehealthTriageCalculation = telehealthTriageCalculation
        self.telehealthVideoVisitCalculation = telehealthVideoVisitCalculation
        self.telehealthVideoVisitValidation = telehealthVideoVisitValidation
        self.telehealthVisitNoteCalculation = telehealthVisitNoteCalculation
        self.validateVisitNoteStep1 = ClosurePort<
            Acme_Sponsorships_V1_EstimateSponsorRequest, Acme_Sponsorships_V1_EstimateSponsorResponse
        >({ request in try await sponsorshipsSponsorCalculation.estimateSponsor(request) })
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

    /// Checks a visit note.
    func checkVisitNoteEligibility(
        request: ServerRequest<Acme_Telehealth_V1_CheckVisitNoteEligibilityRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_CheckVisitNoteEligibilityResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCheckVisitNoteEligibility(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Explains a visit note.
    func explainVisitNoteDecision(
        request: ServerRequest<Acme_Telehealth_V1_ExplainVisitNoteDecisionRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_ExplainVisitNoteDecisionResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processExplainVisitNoteDecision(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a visit note.
    func getVisitNoteRules(
        request: ServerRequest<Acme_Telehealth_V1_GetVisitNoteRulesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_GetVisitNoteRulesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetVisitNoteRules(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lints a visit note.
    func lintVisitNotes(
        request: ServerRequest<Acme_Telehealth_V1_LintVisitNotesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_LintVisitNotesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processLintVisitNotes(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Normalizes a visit note.
    func normalizeVisitNote(
        request: ServerRequest<Acme_Telehealth_V1_NormalizeVisitNoteRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_NormalizeVisitNoteResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processNormalizeVisitNote(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Previews a visit note.
    func previewVisitNote(
        request: ServerRequest<Acme_Telehealth_V1_PreviewVisitNoteRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_PreviewVisitNoteResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processPreviewVisitNote(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Scores a visit note.
    func scoreVisitNote(
        request: ServerRequest<Acme_Telehealth_V1_ScoreVisitNoteRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_ScoreVisitNoteResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processScoreVisitNote(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Validates a visit note.
    func validateVisitNote(
        request: ServerRequest<Acme_Telehealth_V1_ValidateVisitNoteRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_ValidateVisitNoteResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processValidateVisitNote(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processCheckVisitNoteEligibility(_ input: Acme_Telehealth_V1_CheckVisitNoteEligibilityRequest) async throws
        -> Acme_Telehealth_V1_CheckVisitNoteEligibilityResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.phone)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "audit", detail: input.details.contact.phone
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "CheckVisitNoteEligibility",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VisitNoteRecord(input.visitNote, tenant: input.context.tenantID)
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
        let requests0 = input.visitNote.attachments.map { element in
            Acme_Careplans_V1_ExplainCarePlanDecisionRequest.with {
                $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                    $0.attachments = [
                        Acme_Careplans_V1_CarePlanAttachment.with {
                            $0.checksum = element.checksum
                            $0.contentType = element.contentType
                            $0.uri = element.uri
                        }
                    ]
                }
                $0.context = input.context
            }
        }
        let replies0 = try await FanOut.map(requests0) { candidate in
            try await self.careplansCarePlanValidation.explainCarePlanDecision(candidate)
        }
        let reply0 = replies0.first ?? Acme_Careplans_V1_ExplainCarePlanDecisionResponse()
        let outbound1 = Acme_Telehealth_V1_SimulateTriageRequest.with {
            $0.context = input.context
            $0.details = Acme_Telehealth_V1_SimulateTriageRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = input.visitNote.billingAddress.postalCode
                    $0.region = reply0.carePlan.billingAddress.region
                }
            }
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = input.visitNote.audit.updatedBy
                }
            }
        }
        let envelope1 = try Google_Protobuf_Any(message: outbound1)
        let unpacked1 = try Acme_Telehealth_V1_SimulateTriageRequest(unpackingAny: envelope1)
        let reply1 = try await self.telehealthTriageCalculation.simulateTriage(unpacked1)
        let outbound2 = Acme_Telehealth_V1_EstimateTriageRequest.with {
            $0.context = input.context
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.contact.email
                }
            }
        }
        let json2 = try outbound2.jsonString()
        let decoded2 = try Acme_Telehealth_V1_EstimateTriageRequest(jsonString: json2)
        let reply2 = try await self.telehealthTriageCalculation.estimateTriage(decoded2)
        return Acme_Telehealth_V1_CheckVisitNoteEligibilityResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply2.result.correlationID
                $0.referenceIds = reply1.result.referenceIds
                $0.status = reply2.result.status
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.dueAt = reply1.triage.sla.dueAt
                $0.notes = input.visitNote.notes
                $0.visitNoteID = input.visitNoteID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processExplainVisitNoteDecision(_ input: Acme_Telehealth_V1_ExplainVisitNoteDecisionRequest) async throws
        -> Acme_Telehealth_V1_ExplainVisitNoteDecisionResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "audit", detail: input.details.contact.email
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ExplainVisitNoteDecision",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VisitNoteRecord(input.visitNote, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 =
            Acme_Telehealth_V1_CalculateTriageRequest.forVisitNoteValidationEndpointExplainVisitNoteDecision0(
                input
            )
        let reply0 = try await self.telehealthTriageCalculation.calculateTriage(outbound0)
        let outbound1 = Acme_Telehealth_V1_ExplainTriageCalculationRequest.with {
            $0.context = input.context
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.name = reply0.triage.requester.name
                }
            }
        }
        let reply1 = try await self.telehealthTriageCalculation.explainTriageCalculation(
            outbound1, metadata: ["x-acme-region": .string(settings.region)]
        )
        return Acme_Telehealth_V1_ExplainVisitNoteDecisionResponse.with {
            $0.outcome = Acme_Telehealth_V1_ExplainVisitNoteDecisionResponse.Outcome.with {
                $0.status = reply0.result.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = reply1.triage.assignee.displayName
                }
                $0.total = input.visitNote.total
                $0.visitNoteID = input.visitNoteID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processGetVisitNoteRules(_ input: Acme_Telehealth_V1_GetVisitNoteRulesRequest) async throws
        -> Acme_Telehealth_V1_GetVisitNoteRulesResponse
    {
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "GetVisitNoteRules",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "GetVisitNoteRules", detail: input.context.traceID
        )
        let outbound0 = Acme_Featureflags_V1_ListFeatureFlagsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Featureflags_V1_ListFeatureFlagsRequest.Filter.with {
                $0.createdAfter = input.context.deadline
                $0.labels = input.context.baggage
                $0.ownerID = input.visitNoteID
            }
        }
        let reply0 = try await RPCOperations.call(outbound0) { request in
            try await self.featureflagsFeatureFlag.listFeatureFlags(request)
        }
        return Acme_Telehealth_V1_GetVisitNoteRulesResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.status = "ok"
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.visitNoteID = input.visitNoteID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processLintVisitNotes(_ input: Acme_Telehealth_V1_LintVisitNotesRequest) async throws
        -> Acme_Telehealth_V1_LintVisitNotesResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "audit", detail: input.details.contact.email
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "LintVisitNotes",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VisitNoteRecord(input.visitNote, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Telehealth_V1_ExplainVideoVisitDecisionRequest.with {
            $0.context = Projection.read(input, at: \Acme_Telehealth_V1_LintVisitNotesRequest.context)
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.locality = Projection.read(
                        input, at: \Acme_Telehealth_V1_LintVisitNotesRequest.visitNote.billingAddress.locality)
                }
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.email = Projection.read(
                        input, at: \Acme_Telehealth_V1_LintVisitNotesRequest.visitNote.counterparty.email)
                }
                $0.participants = [
                    Acme_Telehealth_V1_VideoVisitParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.phone = Projection.read(
                                input, at: \Acme_Telehealth_V1_LintVisitNotesRequest.details.contact.phone)
                        }
                    }
                ]
            }
        }
        let reply0 = try await self.telehealthVideoVisitValidation.explainVideoVisitDecision(outbound0)
        let requests1 = input.visitNote.attachments.map { element in
            Acme_Telehealth_V1_RecalculateVisitNotesRequest.with {
                $0.context = input.context
                $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                    $0.attachments = [
                        Acme_Telehealth_V1_VisitNoteAttachment.with {
                            $0.contentType = element.contentType
                        }
                    ]
                }
            }
        }
        let replies1 = try await FanOut.map(requests1) { candidate in
            try await self.telehealthVisitNoteCalculation.recalculateVisitNotes(candidate)
        }
        let reply1 = replies1.first ?? Acme_Telehealth_V1_RecalculateVisitNotesResponse()
        _ = reply1
        return Acme_Telehealth_V1_LintVisitNotesResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply0.videoVisit.audit.updatedAt
                    $0.updatedBy = reply0.videoVisit.audit.updatedBy
                }
                $0.counterparty = input.visitNote.counterparty
                $0.visitNoteID = input.visitNoteID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processNormalizeVisitNote(_ input: Acme_Telehealth_V1_NormalizeVisitNoteRequest) async throws
        -> Acme_Telehealth_V1_NormalizeVisitNoteResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "audit", detail: input.details.contact.email
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "NormalizeVisitNote",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VisitNoteRecord(input.visitNote, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Featureflags_V1_PreviewFeatureFlagRequest.with {
            $0.context = input.context
            $0.featureFlag = Acme_Featureflags_V1_FeatureFlag.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = input.visitNote.audit.etag
                }
            }
        }
        let step0: @Sendable () async throws -> Acme_Featureflags_V1_PreviewFeatureFlagResponse = {
            try await self.featureflagsFeatureFlagValidation.previewFeatureFlag(outbound0)
        }
        let reply0 = try await step0()
        var outbound1 = Acme_Telehealth_V1_CompareVisitNoteOptionsRequest()
        outbound1.context = input.context
        outbound1.visitNote = Acme_Telehealth_V1_VisitNote.with {
            $0.audit = Acme_Common_V1_AuditInfo.with {
                $0.etag = input.visitNote.audit.etag
            }
        }
        let reply1 = try await self.telehealthVisitNoteCalculation.compareVisitNoteOptions(outbound1)
        return Acme_Telehealth_V1_NormalizeVisitNoteResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply1.result.referenceIds
                $0.status = reply0.result.status
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.patientID = reply1.visitNote.counterparty.patientID
                }
                $0.lines = [
                    Acme_Telehealth_V1_VisitNoteLine.with {
                        $0.amount = reply0.featureFlag.discount.amount
                    }
                ]
                $0.notes = input.visitNote.notes
                $0.visitNoteID = input.visitNoteID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processPreviewVisitNote(_ input: Acme_Telehealth_V1_PreviewVisitNoteRequest) async throws
        -> Acme_Telehealth_V1_PreviewVisitNoteResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "audit", detail: input.details.contact.email
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "PreviewVisitNote",
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
                            $0.phone = input.details.contact.phone
                        }
                    }
                ]
            }
        }
        let step0: @Sendable () async throws -> Acme_Telehealth_V1_RecalculateVideoVisitsResponse = {
            try await self.telehealthVideoVisitCalculation.recalculateVideoVisits(outbound0)
        }
        let reply0 = try await step0()
        let outbound1 = Acme_Telehealth_V1_ExplainTriageCalculationRequest.with {
            $0.context = input.context
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.email = input.visitNote.counterparty.email
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = input.visitNote.audit.etag
                }
            }
        }
        let reply1 = try await self.telehealthTriageCalculation.explainTriageCalculation(outbound1)
        return Acme_Telehealth_V1_PreviewVisitNoteResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.status = "ok"
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply1.triage.audit.updatedAt
                }
                $0.counterparty = input.visitNote.counterparty
                $0.visitNoteID = input.visitNoteID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processScoreVisitNote(_ input: Acme_Telehealth_V1_ScoreVisitNoteRequest) async throws
        -> Acme_Telehealth_V1_ScoreVisitNoteResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.currencyCode)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "audit", detail: input.details.currencyCode
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ScoreVisitNote",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VisitNoteRecord(input.visitNote, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Telehealth_V1_QuoteTriageRequest.with {
            $0.context = input.context
            $0.details = Acme_Telehealth_V1_QuoteTriageRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.recipient = input.details.destination.recipient
                }
            }
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = input.visitNote.audit.createdBy
                }
                $0.customer = Acme_Telehealth_V1_VideoVisitRef.with {
                    $0.displayName = input.visitNote.counterparty.displayName
                }
            }
        }
        async let remote0 = self.telehealthTriageCalculation.quoteTriage(outbound0)
        async let persisted0 = store.count(tenant: input.context.tenantID)
        let (reply0, count0) = try await (remote0, persisted0)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count0)])
        return Acme_Telehealth_V1_ScoreVisitNoteResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.status = "ok"
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.billingAddress = input.visitNote.billingAddress
                $0.dueAt = reply0.triage.sla.dueAt
                $0.visitNoteID = input.visitNoteID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processValidateVisitNote(_ input: Acme_Telehealth_V1_ValidateVisitNoteRequest) async throws
        -> Acme_Telehealth_V1_ValidateVisitNoteResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "audit", detail: input.details.contact.email
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ValidateVisitNote",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VisitNoteRecord(input.visitNote, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let requests0 = input.visitNote.lines.map { element in
            Acme_Authorization_V1_CheckAccessPolicyEligibilityRequest.with {
                $0.accessPolicy = Acme_Authorization_V1_AccessPolicy.with {
                    $0.description_p = element.description_p
                    $0.discount = Acme_Authorization_V1_AccessPolicyDiscountAction.with {
                        $0.amount = element.tax.amount
                    }
                }
                $0.context = input.context
            }
        }
        let replies0 = try await FanOut.map(requests0) { candidate in
            try await self.authorizationAccessPolicyValidation.checkAccessPolicyEligibility(candidate)
        }
        let reply0 = replies0.first ?? Acme_Authorization_V1_CheckAccessPolicyEligibilityResponse()
        let outbound1 = Acme_Sponsorships_V1_EstimateSponsorRequest.with {
            $0.context = input.context
            $0.sponsor = Acme_Sponsorships_V1_Sponsor.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = input.visitNote.audit.createdBy
                    $0.updatedBy = reply0.accessPolicy.audit.updatedBy
                }
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = input.visitNote.billingAddress.countryCode
                    $0.recipient = input.visitNote.billingAddress.recipient
                }
            }
        }
        let reply1 = try await self.validateVisitNoteStep1.execute(outbound1)
        let requests2 = input.visitNote.lines.map { element in
            Acme_Authorization_V1_CreateAccessPolicyRequest.with {
                $0.accessPolicy = Acme_Authorization_V1_AccessPolicy.with {
                    $0.audit = Acme_Common_V1_AuditInfo.with {
                        $0.updatedBy = reply0.accessPolicy.audit.updatedBy
                    }
                    $0.description_p = element.description_p
                    $0.discount = Acme_Authorization_V1_AccessPolicyDiscountAction.with {
                        $0.amount = element.tax.amount
                    }
                    $0.owner = Acme_Identity_V1_UserRef.with {
                        $0.email = reply0.accessPolicy.owner.email
                    }
                }
                $0.context = input.context
            }
        }
        let replies2 = try await FanOut.map(requests2) { candidate in
            try await self.authorizationAccessPolicy.createAccessPolicy(candidate)
        }
        let reply2 = replies2.first ?? Acme_Authorization_V1_CreateAccessPolicyResponse()
        let selection3_1: String
        switch reply0.accessPolicy.action {
        case .block(let block):
            selection3_1 = block.reason
        default: selection3_1 = .init()
        }
        let outbound3 = Acme_Featureflags_V1_CreateFeatureFlagRequest.with {
            $0.context = input.context
            $0.featureFlag = Acme_Featureflags_V1_FeatureFlag.with {
                $0.block = Acme_Featureflags_V1_FeatureFlagBlockAction.with {
                    $0.reason = selection3_1
                }
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.visitNote.counterparty.displayName
                    $0.userID = reply2.accessPolicy.owner.userID
                }
            }
        }
        let reply3 = try await self.featureflagsFeatureFlag.createFeatureFlag(outbound3)
        return Acme_Telehealth_V1_ValidateVisitNoteResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply3.featureFlag.audit.updatedAt
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = reply1.sponsor.primaryAddress.countryCode
                }
                $0.dueAt = input.visitNote.dueAt
                $0.total = reply1.breakdown.total
                $0.visitNoteID = input.visitNoteID
            }
        }
    }
}
