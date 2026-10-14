import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Checks vitals against the rules before anything acts on them.
final class VitalValidationEndpoint: Acme_Careplans_V1_VitalValidationService.ServiceProtocol {
    private let store: any RecordRepository
    private let logger: Logger
    private let settings: Settings
    private let followUps = WorkQueue<Acme_Identity_V1_GetUserRequest>()
    private let auditAuditEvent: Acme_Audit_V1_AuditEventService.Client<MeshTransport>
    private let boxofficeBoxOfficeSaleCalculation:
        Acme_Boxoffice_V1_BoxOfficeSaleCalculationService.Client<MeshTransport>
    private let careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>
    private let careplansCareGoalValidation: Acme_Careplans_V1_CareGoalValidationService.Client<MeshTransport>
    private let careplansCarePlanCalculation: Acme_Careplans_V1_CarePlanCalculationService.Client<MeshTransport>
    private let careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client<MeshTransport>
    private let featureflagsFeatureFlagValidation:
        Acme_Featureflags_V1_FeatureFlagValidationService.Client<MeshTransport>
    private let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    private let identityUserValidation: Acme_Identity_V1_UserValidationService.Client<MeshTransport>
    private let notificationsNotification: Acme_Notifications_V1_NotificationService.Client<MeshTransport>
    private let sponsorshipsSponsorCalculation: Acme_Sponsorships_V1_SponsorCalculationService.Client<MeshTransport>
    private let normalizeVitalStep1:
        any RPCPort<Acme_Featureflags_V1_PreviewFeatureFlagRequest, Acme_Featureflags_V1_PreviewFeatureFlagResponse>
    private let scoreVitalStep0:
        @Sendable (Acme_Careplans_V1_SimulateCareGoalRequest) async throws -> Acme_Careplans_V1_SimulateCareGoalResponse
    private let validateVitalStep0:
        [String:
            @Sendable (Acme_Careplans_V1_ExplainCareGoalCalculationRequest) async throws ->
            Acme_Careplans_V1_ExplainCareGoalCalculationResponse]

    init(
        dependencies: any Dependencies,
        auditAuditEvent: Acme_Audit_V1_AuditEventService.Client<MeshTransport>,
        boxofficeBoxOfficeSaleCalculation: Acme_Boxoffice_V1_BoxOfficeSaleCalculationService.Client<MeshTransport>,
        careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>,
        careplansCareGoalValidation: Acme_Careplans_V1_CareGoalValidationService.Client<MeshTransport>,
        careplansCarePlanCalculation: Acme_Careplans_V1_CarePlanCalculationService.Client<MeshTransport>,
        careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client<MeshTransport>,
        featureflagsFeatureFlagValidation: Acme_Featureflags_V1_FeatureFlagValidationService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        identityUserValidation: Acme_Identity_V1_UserValidationService.Client<MeshTransport>,
        notificationsNotification: Acme_Notifications_V1_NotificationService.Client<MeshTransport>,
        sponsorshipsSponsorCalculation: Acme_Sponsorships_V1_SponsorCalculationService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.auditAuditEvent = auditAuditEvent
        self.boxofficeBoxOfficeSaleCalculation = boxofficeBoxOfficeSaleCalculation
        self.careplansCareGoalCalculation = careplansCareGoalCalculation
        self.careplansCareGoalValidation = careplansCareGoalValidation
        self.careplansCarePlanCalculation = careplansCarePlanCalculation
        self.careplansCarePlanValidation = careplansCarePlanValidation
        self.featureflagsFeatureFlagValidation = featureflagsFeatureFlagValidation
        self.identityUser = identityUser
        self.identityUserValidation = identityUserValidation
        self.notificationsNotification = notificationsNotification
        self.sponsorshipsSponsorCalculation = sponsorshipsSponsorCalculation
        self.normalizeVitalStep1 = ClosurePort<
            Acme_Featureflags_V1_PreviewFeatureFlagRequest, Acme_Featureflags_V1_PreviewFeatureFlagResponse
        >({ request in try await featureflagsFeatureFlagValidation.previewFeatureFlag(request) })
        self.scoreVitalStep0 = { request in try await careplansCareGoalCalculation.simulateCareGoal(request) }
        self.validateVitalStep0 = [
            "primary": { request in try await careplansCareGoalCalculation.explainCareGoalCalculation(request) }
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

    /// Checks a vital.
    func checkVitalEligibility(
        request: ServerRequest<Acme_Careplans_V1_CheckVitalEligibilityRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_CheckVitalEligibilityResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCheckVitalEligibility(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Explains a vital.
    func explainVitalDecision(
        request: ServerRequest<Acme_Careplans_V1_ExplainVitalDecisionRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_ExplainVitalDecisionResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processExplainVitalDecision(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a vital.
    func getVitalRules(
        request: ServerRequest<Acme_Careplans_V1_GetVitalRulesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_GetVitalRulesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetVitalRules(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lints a vital.
    func lintVitals(
        request: ServerRequest<Acme_Careplans_V1_LintVitalsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_LintVitalsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processLintVitals(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Normalizes a vital.
    func normalizeVital(
        request: ServerRequest<Acme_Careplans_V1_NormalizeVitalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_NormalizeVitalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processNormalizeVital(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Previews a vital.
    func previewVital(
        request: ServerRequest<Acme_Careplans_V1_PreviewVitalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_PreviewVitalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processPreviewVital(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Scores a vital.
    func scoreVital(
        request: ServerRequest<Acme_Careplans_V1_ScoreVitalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_ScoreVitalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processScoreVital(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Validates a vital.
    func validateVital(
        request: ServerRequest<Acme_Careplans_V1_ValidateVitalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_ValidateVitalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processValidateVital(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processCheckVitalEligibility(_ input: Acme_Careplans_V1_CheckVitalEligibilityRequest) async throws
        -> Acme_Careplans_V1_CheckVitalEligibilityResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.locale)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "audit", detail: input.details.locale
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "CheckVitalEligibility",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VitalRecord(input.vital, tenant: input.context.tenantID)
        try await store.save(record.stored)
        try followUps.submit(
            Acme_Identity_V1_GetUserRequest.with {
                $0.context = input.context
                $0.userID = input.context.actor.userID
            })
        let outbound0 = Acme_Careplans_V1_RecalculateCarePlansRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.counterparty = Acme_Appointments_V1_AppointmentRef.with {
                    $0.displayName = input.vital.subject.displayName
                    $0.startsAt = input.vital.subject.startsAt
                }
            }
            $0.context = input.context
        }
        let json0 = try outbound0.jsonString()
        let decoded0 = try Acme_Careplans_V1_RecalculateCarePlansRequest(jsonString: json0)
        let reply0 = try await self.careplansCarePlanCalculation.recalculateCarePlans(decoded0)
        let outbound1 = Acme_Careplans_V1_EstimateCareGoalRequest.forVitalValidationEndpointCheckVitalEligibility1(
            input,
            reply0: reply0
        )
        let reply1 = try await self.careplansCareGoalCalculation.estimateCareGoal(outbound1)
        let outbound2 = Acme_Careplans_V1_ExplainCarePlanCalculationRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply1.careGoal.audit.etag
                }
            }
            $0.context = input.context
            $0.details = Acme_Careplans_V1_ExplainCarePlanCalculationRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.preferredChannel = input.details.contact.preferredChannel
                }
            }
        }
        let reply2 = try await self.careplansCarePlanCalculation.explainCarePlanCalculation(
            outbound2, metadata: ["x-acme-region": .string(settings.region)]
        )
        let outbound3 = Acme_Careplans_V1_CheckCarePlanEligibilityRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.recipient = reply0.carePlan.billingAddress.recipient
                }
            }
            $0.context = input.context
            $0.details = Acme_Careplans_V1_CheckCarePlanEligibilityRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.contact.email
                    $0.phone = input.details.contact.phone
                }
            }
        }
        let reply3 = try await RPCOperations.call(outbound3) { request in
            try await self.careplansCarePlanValidation.checkCarePlanEligibility(request)
        }
        return Acme_Careplans_V1_CheckVitalEligibilityResponse.with {
            $0.outcome = Acme_Careplans_V1_CheckVitalEligibilityResponse.Outcome.with {
                $0.message = reply1.result.message
                $0.status = reply3.result.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.result.message
                $0.status = Projection.firstValue(
                    [
                        reply0.result.status,
                        reply3.result.status,
                    ], default: .init())
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.correlationID = reply2.result.correlationID
                $0.occurredAt = input.vital.occurredAt
                $0.vitalID = input.vitalID
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processExplainVitalDecision(_ input: Acme_Careplans_V1_ExplainVitalDecisionRequest) async throws
        -> Acme_Careplans_V1_ExplainVitalDecisionResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "audit", detail: input.details.contact.email
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ExplainVitalDecision",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VitalRecord(input.vital, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let requests0 = input.vital.measurements.map { element in
            Acme_Boxoffice_V1_CompareBoxOfficeSaleOptionsRequest.with {
                $0.boxOfficeSale = Acme_Boxoffice_V1_BoxOfficeSale.with {
                    $0.audit = Acme_Common_V1_AuditInfo.with {
                        $0.updatedAt = element.observedAt
                    }
                }
                $0.context = input.context
            }
        }
        let replies0 = try await FanOut.map(requests0) { candidate in
            try await self.boxofficeBoxOfficeSaleCalculation.compareBoxOfficeSaleOptions(candidate)
        }
        let reply0 = replies0.first ?? Acme_Boxoffice_V1_CompareBoxOfficeSaleOptionsResponse()
        let selection1_1: String
        switch reply0.boxOfficeSale.settlement {
        case .bank(let bank):
            selection1_1 = bank.accountHolder
        default: selection1_1 = .init()
        }
        let outbound1 = Acme_Careplans_V1_NormalizeCarePlanRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.bank = Acme_Careplans_V1_CarePlanBankSettlement.with {
                    $0.accountHolder = selection1_1
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.lines = reply0.boxOfficeSale.billingAddress.lines
                }
            }
            $0.context = input.context
        }
        let reply1 = try await self.careplansCarePlanValidation.normalizeCarePlan(outbound1)
        let selection2_2: String
        switch reply1.carePlan.settlement {
        case .bank(let bank):
            selection2_2 = bank.accountHolder
        default: selection2_2 = .init()
        }
        let outbound2 = Acme_Careplans_V1_CalculateCarePlanRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.bank = Acme_Careplans_V1_CarePlanBankSettlement.with {
                    $0.accountHolder = selection2_2
                }
            }
            $0.context = input.context
            $0.details = Acme_Careplans_V1_CalculateCarePlanRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = reply1.carePlan.billingAddress.countryCode
                    $0.postalCode = reply1.carePlan.billingAddress.postalCode
                    $0.recipient = reply0.boxOfficeSale.billingAddress.recipient
                }
            }
        }
        let reply2 = try await self.careplansCarePlanCalculation.calculateCarePlan(outbound2)
        let outbound3 = Acme_Notifications_V1_CloneNotificationRequest.with {
            $0.context = Projection.read(input, at: \Acme_Careplans_V1_ExplainVitalDecisionRequest.context)
            $0.notification = Acme_Notifications_V1_Notification.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = Projection.read(
                        reply2, at: \Acme_Careplans_V1_CalculateCarePlanResponse.carePlan.audit.updatedAt)
                    $0.updatedBy = Projection.read(
                        reply1, at: \Acme_Careplans_V1_NormalizeCarePlanResponse.carePlan.audit.updatedBy)
                }
                $0.comments = [
                    Acme_Notifications_V1_NotificationComment.with {
                        $0.createdAt = Projection.read(
                            reply1, at: \Acme_Careplans_V1_NormalizeCarePlanResponse.carePlan.audit.createdAt)
                    }
                ]
            }
        }
        let reply3 = try await self.notificationsNotification.cloneNotification(outbound3)
        return Acme_Careplans_V1_ExplainVitalDecisionResponse.with {
            $0.outcome = Acme_Careplans_V1_ExplainVitalDecisionResponse.Outcome.with {
                $0.status = reply1.result.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply3.result.correlationID
                $0.message = Projection.firstValue(
                    [
                        reply1.outcome.message,
                        reply3.result.message,
                    ], default: .init())
                $0.status = "ok"
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.attributes = input.vital.attributes
                $0.subject = Acme_Appointments_V1_AppointmentRef.with {
                    $0.startsAt = reply2.carePlan.counterparty.startsAt
                }
                $0.vitalID = input.vitalID
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processGetVitalRules(_ input: Acme_Careplans_V1_GetVitalRulesRequest) async throws
        -> Acme_Careplans_V1_GetVitalRulesResponse
    {
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "GetVitalRules",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "GetVitalRules", detail: input.context.traceID
        )
        let outbound0 = Acme_Featureflags_V1_NormalizeFeatureFlagRequest.with {
            $0.context = input.context
            $0.featureFlag = Acme_Featureflags_V1_FeatureFlag.with {
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.context.actor.userID
                }
            }
        }
        let step0: @Sendable () async throws -> Acme_Featureflags_V1_NormalizeFeatureFlagResponse = {
            try await self.featureflagsFeatureFlagValidation.normalizeFeatureFlag(outbound0)
        }
        let reply0 = try await step0()
        return Acme_Careplans_V1_GetVitalRulesResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.correlationID = reply0.result.correlationID
                $0.vitalID = input.vitalID
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processLintVitals(_ input: Acme_Careplans_V1_LintVitalsRequest) async throws
        -> Acme_Careplans_V1_LintVitalsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.preferredChannel)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "audit", detail: input.details.contact.preferredChannel
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "LintVitals",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VitalRecord(input.vital, tenant: input.context.tenantID)
        try await store.save(record.stored)
        var outbound0 = Acme_Careplans_V1_EstimateCarePlanRequest()
        outbound0.carePlan = Acme_Careplans_V1_CarePlan.with {
            $0.counterparty = Acme_Appointments_V1_AppointmentRef.with {
                $0.appointmentID = input.vital.subject.appointmentID
                $0.startsAt = input.vital.subject.startsAt
            }
        }
        outbound0.context = input.context
        let reply0 = try await self.careplansCarePlanCalculation.estimateCarePlan(outbound0)
        let outbound1 = Acme_Careplans_V1_CheckCareGoalEligibilityRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.customer = Acme_Patients_V1_PatientRef.with {
                    $0.email = input.details.contact.email
                }
            }
            $0.context = input.context
            $0.details = Acme_Careplans_V1_CheckCareGoalEligibilityRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.phone = input.details.contact.phone
                }
            }
        }
        let step1: @Sendable () async throws -> Acme_Careplans_V1_CheckCareGoalEligibilityResponse = {
            try await self.careplansCareGoalValidation.checkCareGoalEligibility(outbound1)
        }
        let reply1 = try await step1()
        let outbound2 = Acme_Sponsorships_V1_CompareSponsorOptionsRequest.with {
            $0.context = input.context
            $0.details = Acme_Sponsorships_V1_CompareSponsorOptionsRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.region = reply0.carePlan.billingAddress.region
                }
            }
            $0.sponsor = Acme_Sponsorships_V1_Sponsor.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply0.carePlan.audit.createdBy
                }
            }
        }
        let reply2 = try await self.sponsorshipsSponsorCalculation.compareSponsorOptions(outbound2)
        return Acme_Careplans_V1_LintVitalsResponse.with {
            $0.outcome = Acme_Careplans_V1_LintVitalsResponse.Outcome.with {
                $0.message = reply1.outcome.message
                $0.status = reply2.result.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.attributes = reply2.sponsor.attributes
                $0.occurredAt = input.vital.occurredAt
                $0.vitalID = input.vitalID
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processNormalizeVital(_ input: Acme_Careplans_V1_NormalizeVitalRequest) async throws
        -> Acme_Careplans_V1_NormalizeVitalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.phone)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "audit", detail: input.details.contact.phone
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "NormalizeVital",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VitalRecord(input.vital, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Identity_V1_ExplainUserDecisionRequest.with {
            $0.context = input.context
            $0.details = Acme_Identity_V1_ExplainUserDecisionRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.name = input.details.contact.name
                }
            }
            $0.user = Acme_Identity_V1_User.with {
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.vital.subject.displayName
                    $0.email = input.details.contact.email
                }
            }
        }
        async let remote0 = self.identityUserValidation.explainUserDecision(outbound0)
        async let persisted0 = store.count(tenant: input.context.tenantID)
        let (reply0, count0) = try await (remote0, persisted0)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count0)])
        let outbound1 = Acme_Featureflags_V1_PreviewFeatureFlagRequest.with {
            $0.context = input.context
            $0.details = Acme_Featureflags_V1_PreviewFeatureFlagRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.preferredChannel = input.details.contact.preferredChannel
                }
            }
        }
        let reply1 = try await self.normalizeVitalStep1.execute(outbound1)
        return Acme_Careplans_V1_NormalizeVitalResponse.with {
            $0.outcome = Acme_Careplans_V1_NormalizeVitalResponse.Outcome.with {
                $0.nextSteps = reply0.outcome.nextSteps
                $0.status = reply1.outcome.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = input.vital.correlationID
                $0.status = "ok"
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.attributes = reply0.user.attributes
                $0.subject = Acme_Appointments_V1_AppointmentRef.with {
                    $0.displayName = reply1.featureFlag.owner.displayName
                }
                $0.vitalID = input.vitalID
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processPreviewVital(_ input: Acme_Careplans_V1_PreviewVitalRequest) async throws
        -> Acme_Careplans_V1_PreviewVitalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.phone)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "audit", detail: input.details.contact.phone
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "PreviewVital",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VitalRecord(input.vital, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Careplans_V1_CheckCarePlanEligibilityRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.counterparty = Acme_Appointments_V1_AppointmentRef.with {
                    $0.appointmentID = input.vital.subject.appointmentID
                    $0.startsAt = input.vital.subject.startsAt
                }
            }
            $0.context = input.context
            $0.details = Acme_Careplans_V1_CheckCarePlanEligibilityRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.contact.email
                }
            }
        }
        let port0 = RPCOperations.port { (request: Acme_Careplans_V1_CheckCarePlanEligibilityRequest) in
            try await self.careplansCarePlanValidation.checkCarePlanEligibility(request)
        }
        let reply0 = try await port0.execute(outbound0)
        return Acme_Careplans_V1_PreviewVitalResponse.with {
            $0.outcome = Acme_Careplans_V1_PreviewVitalResponse.Outcome.with {
                $0.status = reply0.result.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.sequence = input.vital.sequence
                $0.subject = Acme_Appointments_V1_AppointmentRef.with {
                    $0.startsAt = reply0.carePlan.counterparty.startsAt
                }
                $0.vitalID = input.vitalID
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processScoreVital(_ input: Acme_Careplans_V1_ScoreVitalRequest) async throws
        -> Acme_Careplans_V1_ScoreVitalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.currencyCode)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "audit", detail: input.details.currencyCode
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ScoreVital",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VitalRecord(input.vital, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Careplans_V1_SimulateCareGoalRequest.with {
            $0.context = input.context
            $0.details = Acme_Careplans_V1_SimulateCareGoalRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = input.details.destination.countryCode
                    $0.lines = input.details.destination.lines
                    $0.locality = input.details.destination.locality
                    $0.postalCode = input.details.destination.postalCode
                }
            }
        }
        let reply0 = try await self.scoreVitalStep0(outbound0)
        let selection1_2: String
        switch reply0.careGoal.origin {
        case .customer(let customer):
            selection1_2 = customer.displayName
        default: selection1_2 = .init()
        }
        let outbound1 = Acme_Careplans_V1_LintCarePlansRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.lines = input.details.destination.lines
                }
                $0.counterparty = Acme_Appointments_V1_AppointmentRef.with {
                    $0.displayName = selection1_2
                }
            }
            $0.context = input.context
        }
        let reply1 = try await self.careplansCarePlanValidation.lintCarePlans(outbound1)
        return Acme_Careplans_V1_ScoreVitalResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.message = reply1.result.message
                $0.status = "ok"
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.occurredAt = input.vital.occurredAt
                $0.vitalID = input.vitalID
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processValidateVital(_ input: Acme_Careplans_V1_ValidateVitalRequest) async throws
        -> Acme_Careplans_V1_ValidateVitalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "audit", detail: input.details.contact.email
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ValidateVital",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VitalRecord(input.vital, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Careplans_V1_ExplainCareGoalCalculationRequest.with {
            $0.context = input.context
            $0.details = Acme_Careplans_V1_ExplainCareGoalCalculationRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.phone = input.details.contact.phone
                }
            }
        }
        guard let execute0 = self.validateVitalStep0[settings.region] ?? self.validateVitalStep0["primary"] else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply0 = try await execute0(outbound0)
        let requests1 = input.vital.measurements.map { element in
            Acme_Careplans_V1_QuoteCarePlanRequest.with {
                $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                    $0.audit = Acme_Common_V1_AuditInfo.with {
                        $0.createdBy = reply0.careGoal.audit.createdBy
                        $0.updatedAt = element.observedAt
                    }
                    $0.counterparty = Acme_Appointments_V1_AppointmentRef.with {
                        $0.displayName = input.vital.subject.displayName
                        $0.startsAt = input.vital.subject.startsAt
                    }
                }
                $0.context = input.context
            }
        }
        let replies1 = try await FanOut.map(requests1) { candidate in
            try await self.careplansCarePlanCalculation.quoteCarePlan(candidate)
        }
        let reply1 = replies1.first ?? Acme_Careplans_V1_QuoteCarePlanResponse()
        let outbound2 = Acme_Careplans_V1_CompareCarePlanOptionsRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply1.carePlan.audit.updatedBy
                }
            }
            $0.context = input.context
        }
        let reply2 = try await self.careplansCarePlanCalculation.compareCarePlanOptions(outbound2)
        let requests3 = input.vital.measurements.map { element in
            Acme_Audit_V1_CreateAuditEventRequest.with {
                $0.auditEvent = Acme_Audit_V1_AuditEvent.with {
                    $0.measurements = [
                        Acme_Audit_V1_AuditEventMeasurement.with {
                            $0.metric = element.metric
                        }
                    ]
                }
                $0.context = input.context
            }
        }
        let replies3 = try await FanOut.map(requests3) { candidate in
            try await self.auditAuditEvent.createAuditEvent(candidate)
        }
        let reply3 = replies3.first ?? Acme_Audit_V1_CreateAuditEventResponse()
        _ = reply3
        return Acme_Careplans_V1_ValidateVitalResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.sequence = input.vital.sequence
                $0.subject = Acme_Appointments_V1_AppointmentRef.with {
                    $0.displayName = Projection.firstValue(
                        [
                            reply0.careGoal.assignee.displayName,
                            reply2.carePlan.counterparty.displayName,
                        ], default: .init())
                }
                $0.vitalID = input.vitalID
            }
        }
    }
}
