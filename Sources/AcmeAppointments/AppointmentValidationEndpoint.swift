import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Checks appointments against the rules before anything acts on them.
final class AppointmentValidationEndpoint: Acme_Appointments_V1_AppointmentValidationService.ServiceProtocol {
    private let store: any RecordRepository
    private let logger: Logger
    private let settings: Settings
    private let auditAuditEventQuery: Acme_Audit_V1_AuditEventQueryService.Client<MeshTransport>
    private let authorizationAccessPolicy: Acme_Authorization_V1_AccessPolicyService.Client<MeshTransport>
    private let authorizationAccessPolicyQuery: Acme_Authorization_V1_AccessPolicyQueryService.Client<MeshTransport>
    private let authorizationAccessPolicyValidation:
        Acme_Authorization_V1_AccessPolicyValidationService.Client<MeshTransport>
    private let careplansCareGoalQuery: Acme_Careplans_V1_CareGoalQueryService.Client<MeshTransport>
    private let careplansCareGoalValidation: Acme_Careplans_V1_CareGoalValidationService.Client<MeshTransport>
    private let careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>
    private let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    private let ledgerLedgerAccount: Acme_Ledger_V1_LedgerAccountService.Client<MeshTransport>
    private let ledgerLedgerAccountQuery: Acme_Ledger_V1_LedgerAccountQueryService.Client<MeshTransport>
    private let prescriptionsPrescriptionQuery: Acme_Prescriptions_V1_PrescriptionQueryService.Client<MeshTransport>
    private let telehealthTriageValidation: Acme_Telehealth_V1_TriageValidationService.Client<MeshTransport>
    private let telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client<MeshTransport>
    private let telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client<MeshTransport>
    private let telehealthVisitNoteQuery: Acme_Telehealth_V1_VisitNoteQueryService.Client<MeshTransport>
    private let getAppointmentRulesStep0:
        any RPCPort<Acme_Ledger_V1_ListLedgerAccountsRequest, Acme_Ledger_V1_ListLedgerAccountsResponse>
    private let normalizeAppointmentStep0:
        @Sendable (Acme_Authorization_V1_NormalizeAccessPolicyRequest) async throws ->
            Acme_Authorization_V1_NormalizeAccessPolicyResponse
    private let previewAppointmentStep0:
        [String:
            @Sendable (Acme_Audit_V1_ResolveAuditEventsRequest) async throws -> Acme_Audit_V1_ResolveAuditEventsResponse]

    init(
        dependencies: any Dependencies,
        auditAuditEventQuery: Acme_Audit_V1_AuditEventQueryService.Client<MeshTransport>,
        authorizationAccessPolicy: Acme_Authorization_V1_AccessPolicyService.Client<MeshTransport>,
        authorizationAccessPolicyQuery: Acme_Authorization_V1_AccessPolicyQueryService.Client<MeshTransport>,
        authorizationAccessPolicyValidation: Acme_Authorization_V1_AccessPolicyValidationService.Client<MeshTransport>,
        careplansCareGoalQuery: Acme_Careplans_V1_CareGoalQueryService.Client<MeshTransport>,
        careplansCareGoalValidation: Acme_Careplans_V1_CareGoalValidationService.Client<MeshTransport>,
        careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        ledgerLedgerAccount: Acme_Ledger_V1_LedgerAccountService.Client<MeshTransport>,
        ledgerLedgerAccountQuery: Acme_Ledger_V1_LedgerAccountQueryService.Client<MeshTransport>,
        prescriptionsPrescriptionQuery: Acme_Prescriptions_V1_PrescriptionQueryService.Client<MeshTransport>,
        telehealthTriageValidation: Acme_Telehealth_V1_TriageValidationService.Client<MeshTransport>,
        telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client<MeshTransport>,
        telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client<MeshTransport>,
        telehealthVisitNoteQuery: Acme_Telehealth_V1_VisitNoteQueryService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.auditAuditEventQuery = auditAuditEventQuery
        self.authorizationAccessPolicy = authorizationAccessPolicy
        self.authorizationAccessPolicyQuery = authorizationAccessPolicyQuery
        self.authorizationAccessPolicyValidation = authorizationAccessPolicyValidation
        self.careplansCareGoalQuery = careplansCareGoalQuery
        self.careplansCareGoalValidation = careplansCareGoalValidation
        self.careplansCarePlan = careplansCarePlan
        self.identityUser = identityUser
        self.ledgerLedgerAccount = ledgerLedgerAccount
        self.ledgerLedgerAccountQuery = ledgerLedgerAccountQuery
        self.prescriptionsPrescriptionQuery = prescriptionsPrescriptionQuery
        self.telehealthTriageValidation = telehealthTriageValidation
        self.telehealthVideoVisit = telehealthVideoVisit
        self.telehealthVideoVisitCalculation = telehealthVideoVisitCalculation
        self.telehealthVisitNoteQuery = telehealthVisitNoteQuery
        self.getAppointmentRulesStep0 = ClosurePort<
            Acme_Ledger_V1_ListLedgerAccountsRequest, Acme_Ledger_V1_ListLedgerAccountsResponse
        >({ request in try await ledgerLedgerAccount.listLedgerAccounts(request) })
        self.normalizeAppointmentStep0 = { request in
            try await authorizationAccessPolicyValidation.normalizeAccessPolicy(request)
        }
        self.previewAppointmentStep0 = [
            "primary": { request in try await auditAuditEventQuery.resolveAuditEvents(request) }
        ]
    }

    /// Checks an appointment.
    func checkAppointmentEligibility(
        request: ServerRequest<Acme_Appointments_V1_CheckAppointmentEligibilityRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_CheckAppointmentEligibilityResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCheckAppointmentEligibility(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Explains an appointment.
    func explainAppointmentDecision(
        request: ServerRequest<Acme_Appointments_V1_ExplainAppointmentDecisionRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_ExplainAppointmentDecisionResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processExplainAppointmentDecision(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns an appointment.
    func getAppointmentRules(
        request: ServerRequest<Acme_Appointments_V1_GetAppointmentRulesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_GetAppointmentRulesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetAppointmentRules(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lints an appointment.
    func lintAppointments(
        request: ServerRequest<Acme_Appointments_V1_LintAppointmentsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_LintAppointmentsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processLintAppointments(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Normalizes an appointment.
    func normalizeAppointment(
        request: ServerRequest<Acme_Appointments_V1_NormalizeAppointmentRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_NormalizeAppointmentResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processNormalizeAppointment(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Previews an appointment.
    func previewAppointment(
        request: ServerRequest<Acme_Appointments_V1_PreviewAppointmentRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_PreviewAppointmentResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processPreviewAppointment(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Scores an appointment.
    func scoreAppointment(
        request: ServerRequest<Acme_Appointments_V1_ScoreAppointmentRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_ScoreAppointmentResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processScoreAppointment(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Validates an appointment.
    func validateAppointment(
        request: ServerRequest<Acme_Appointments_V1_ValidateAppointmentRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_ValidateAppointmentResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processValidateAppointment(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processCheckAppointmentEligibility(_ input: Acme_Appointments_V1_CheckAppointmentEligibilityRequest)
        async throws -> Acme_Appointments_V1_CheckAppointmentEligibilityResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.appointment.appointmentID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "appointment",
            action: "audit", detail: input.appointment.appointmentID
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "CheckAppointmentEligibility",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try AppointmentRecord(input.appointment, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let importFrame = Acme_Careplans_V1_BatchCreateCarePlansRequest.with {
            $0.context = input.context
        }
        _ = try await self.careplansCarePlan.batchCreateCarePlans { writer in
            try await writer.write(importFrame)
        }
        var outbound0 = Acme_Telehealth_V1_NormalizeTriageRequest()
        outbound0.context = input.context
        outbound0.details = Acme_Telehealth_V1_NormalizeTriageRequest.Details.with {
            $0.contact = Acme_Common_V1_ContactInfo.with {
                $0.name = input.details.contact.name
            }
        }
        outbound0.triage = Acme_Telehealth_V1_Triage.with {
            $0.customer = Acme_Telehealth_V1_VideoVisitRef.with {
                $0.displayName = input.appointment.organizer.displayName
            }
            $0.requester = Acme_Common_V1_ContactInfo.with {
                $0.email = input.appointment.organizer.email
            }
        }
        let reply0 = try await self.telehealthTriageValidation.normalizeTriage(outbound0)
        let requests1 = input.appointment.participants.map { element in
            Acme_Telehealth_V1_BrowseVisitNotesRequest.with {
                $0.context = input.context
                $0.filter = Acme_Telehealth_V1_BrowseVisitNotesRequest.Filter.with {
                    $0.createdAfter = reply0.triage.sla.dueAt
                    $0.labels = reply0.result.details
                    $0.ownerID = element.participantID
                    $0.region = input.appointment.location.region
                }
            }
        }
        let replies1 = try await FanOut.map(requests1) { candidate in
            try await self.telehealthVisitNoteQuery.browseVisitNotes(candidate)
        }
        let reply1 = replies1.first ?? Acme_Telehealth_V1_BrowseVisitNotesResponse()
        _ = reply1
        let outbound2 = Acme_Careplans_V1_ExplainCareGoalDecisionRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.appointment.organizer.displayName
                    $0.email = input.details.contact.email
                }
            }
            $0.context = input.context
        }
        let step2: @Sendable () async throws -> Acme_Careplans_V1_ExplainCareGoalDecisionResponse = {
            try await self.careplansCareGoalValidation.explainCareGoalDecision(outbound2)
        }
        let reply2 = try await step2()
        return Acme_Appointments_V1_CheckAppointmentEligibilityResponse.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.appointmentID = input.appointmentID
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply2.careGoal.audit.createdBy
                }
                $0.metadata = input.appointment.metadata
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply0.triage.customer.displayName
                }
            }
            $0.outcome = Acme_Appointments_V1_CheckAppointmentEligibilityResponse.Outcome.with {
                $0.effectiveAt = reply0.outcome.effectiveAt
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processExplainAppointmentDecision(_ input: Acme_Appointments_V1_ExplainAppointmentDecisionRequest) async throws
        -> Acme_Appointments_V1_ExplainAppointmentDecisionResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.appointment.appointmentID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "appointment",
            action: "audit", detail: input.appointment.appointmentID
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ExplainAppointmentDecision",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try AppointmentRecord(input.appointment, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Telehealth_V1_PreviewTriageRequest.with {
            $0.context = input.context
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.name = input.details.contact.name
                }
            }
        }
        let reply0 = try await self.telehealthTriageValidation.previewTriage(outbound0)
        let outbound1 = Acme_Authorization_V1_UpdateAccessPolicyRequest.with {
            $0.accessPolicy = Acme_Authorization_V1_AccessPolicy.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply0.triage.audit.createdAt
                }
            }
            $0.context = input.context
        }
        async let remote1 = self.authorizationAccessPolicy.updateAccessPolicy(outbound1)
        async let persisted1 = store.count(tenant: input.context.tenantID)
        let (reply1, count1) = try await (remote1, persisted1)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count1)])
        let outbound2 = Acme_Telehealth_V1_WatchVideoVisitsRequest.with {
            $0.context = input.context
            $0.subscriber = Acme_Common_V1_ContactInfo.with {
                $0.email = input.appointment.organizer.email
            }
        }
        let reply2 = try await self.telehealthVideoVisit.watchVideoVisits(outbound2) { response in
            var latest = Acme_Telehealth_V1_WatchVideoVisitsResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        _ = reply2
        let requests3 = input.appointment.participants.map { element in
            Acme_Telehealth_V1_SuggestVisitNotesRequest.with {
                $0.context = input.context
                $0.filter = Acme_Telehealth_V1_SuggestVisitNotesRequest.Filter.with {
                    $0.createdAfter = reply1.accessPolicy.audit.createdAt
                    $0.ownerID = element.participantID
                    $0.region = input.appointment.location.region
                }
            }
        }
        let replies3 = try await FanOut.map(requests3) { candidate in
            try await self.telehealthVisitNoteQuery.suggestVisitNotes(candidate)
        }
        let reply3 = replies3.first ?? Acme_Telehealth_V1_SuggestVisitNotesResponse()
        _ = reply3
        return Acme_Appointments_V1_ExplainAppointmentDecisionResponse.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.appointmentID = input.appointmentID
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply0.triage.audit.updatedAt
                }
                $0.location = input.appointment.location
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply1.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processGetAppointmentRules(_ input: Acme_Appointments_V1_GetAppointmentRulesRequest) async throws
        -> Acme_Appointments_V1_GetAppointmentRulesResponse
    {
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "GetAppointmentRules",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "appointment",
            action: "GetAppointmentRules", detail: input.context.traceID
        )
        let outbound0 = Acme_Ledger_V1_ListLedgerAccountsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Ledger_V1_ListLedgerAccountsRequest.Filter.with {
                $0.createdAfter = input.context.deadline
                $0.labels = input.context.baggage
                $0.ownerID = input.appointmentID
            }
        }
        let reply0 = try await self.getAppointmentRulesStep0.execute(outbound0)
        return Acme_Appointments_V1_GetAppointmentRulesResponse.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.appointmentID = input.appointmentID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.result.message
                $0.status = reply0.result.status
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processLintAppointments(_ input: Acme_Appointments_V1_LintAppointmentsRequest) async throws
        -> Acme_Appointments_V1_LintAppointmentsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.appointment.appointmentID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "appointment",
            action: "audit", detail: input.appointment.appointmentID
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "LintAppointments",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try AppointmentRecord(input.appointment, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Careplans_V1_ExportCareGoalsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Careplans_V1_ExportCareGoalsRequest.Filter.with {
                $0.createdAfter = input.appointment.audit.updatedAt
                $0.ownerID = input.appointment.organizer.userID
                $0.region = input.appointment.location.region
            }
        }
        let reply0 = try await self.careplansCareGoalQuery.exportCareGoals(outbound0) { response in
            var latest = Acme_Careplans_V1_ExportCareGoalsResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        _ = reply0
        let outbound1 = Acme_Authorization_V1_FindAccessPoliciesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Authorization_V1_FindAccessPoliciesRequest.Filter.with {
                $0.createdAfter = input.appointment.audit.createdAt
                $0.ownerID = input.appointment.organizer.userID
                $0.region = input.appointment.location.region
            }
        }
        let port1 = RPCOperations.port { (request: Acme_Authorization_V1_FindAccessPoliciesRequest) in
            try await self.authorizationAccessPolicyQuery.findAccessPolicies(request)
        }
        let reply1 = try await port1.execute(outbound1)
        return Acme_Appointments_V1_LintAppointmentsResponse.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.appointmentID = input.appointmentID
                $0.location = input.appointment.location
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply1.result.details
                $0.message = reply1.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processNormalizeAppointment(_ input: Acme_Appointments_V1_NormalizeAppointmentRequest) async throws
        -> Acme_Appointments_V1_NormalizeAppointmentResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.appointment.appointmentID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "appointment",
            action: "audit", detail: input.appointment.appointmentID
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "NormalizeAppointment",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try AppointmentRecord(input.appointment, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Authorization_V1_NormalizeAccessPolicyRequest.with {
            $0.context = input.context
            $0.details = Acme_Authorization_V1_NormalizeAccessPolicyRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.appointment.organizer.email
                }
            }
        }
        let reply0 = try await self.normalizeAppointmentStep0(outbound0)
        return Acme_Appointments_V1_NormalizeAppointmentResponse.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.appointmentID = input.appointmentID
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply0.accessPolicy.audit.updatedAt
                }
                $0.metadata = input.appointment.metadata
            }
            $0.outcome = Acme_Appointments_V1_NormalizeAppointmentResponse.Outcome.with {
                $0.message = reply0.outcome.message
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processPreviewAppointment(_ input: Acme_Appointments_V1_PreviewAppointmentRequest) async throws
        -> Acme_Appointments_V1_PreviewAppointmentResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.appointment.appointmentID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "appointment",
            action: "audit", detail: input.appointment.appointmentID
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "PreviewAppointment",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try AppointmentRecord(input.appointment, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Audit_V1_ResolveAuditEventsRequest.with {
            $0.context = input.context
        }
        guard let execute0 = self.previewAppointmentStep0[settings.region] ?? self.previewAppointmentStep0["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply0 = try await execute0(outbound0)
        let requests1 = input.appointment.participants.map { element in
            Acme_Authorization_V1_ExplainAccessPolicyDecisionRequest.with {
                $0.accessPolicy = Acme_Authorization_V1_AccessPolicy.with {
                    $0.owner = Acme_Identity_V1_UserRef.with {
                        $0.email = element.contact.email
                    }
                }
                $0.context = input.context
                $0.details = Acme_Authorization_V1_ExplainAccessPolicyDecisionRequest.Details.with {
                    $0.contact = Acme_Common_V1_ContactInfo.with {
                        $0.phone = element.contact.phone
                        $0.preferredChannel = element.contact.preferredChannel
                    }
                }
            }
        }
        let replies1 = try await FanOut.map(requests1) { candidate in
            try await self.authorizationAccessPolicyValidation.explainAccessPolicyDecision(candidate)
        }
        let reply1 = replies1.first ?? Acme_Authorization_V1_ExplainAccessPolicyDecisionResponse()
        _ = reply1
        return Acme_Appointments_V1_PreviewAppointmentResponse.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.appointmentID = input.appointmentID
                $0.window = input.appointment.window
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processScoreAppointment(_ input: Acme_Appointments_V1_ScoreAppointmentRequest) async throws
        -> Acme_Appointments_V1_ScoreAppointmentResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.appointment.appointmentID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "appointment",
            action: "audit", detail: input.appointment.appointmentID
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ScoreAppointment",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try AppointmentRecord(input.appointment, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let requests0 = input.appointment.participants.map { element in
            Acme_Telehealth_V1_SimulateVideoVisitRequest.with {
                $0.context = input.context
                $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                    $0.participants = [
                        Acme_Telehealth_V1_VideoVisitParticipant.with {
                            $0.contact = Acme_Common_V1_ContactInfo.with {
                                $0.email = element.contact.email
                                $0.phone = element.contact.phone
                            }
                        }
                    ]
                }
            }
        }
        let replies0 = try await FanOut.map(requests0) { candidate in
            try await self.telehealthVideoVisitCalculation.simulateVideoVisit(candidate)
        }
        let reply0 = replies0.first ?? Acme_Telehealth_V1_SimulateVideoVisitResponse()
        _ = reply0
        let outbound1 = Acme_Authorization_V1_WatchAccessPoliciesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Authorization_V1_WatchAccessPoliciesRequest.Filter.with {
                $0.region = input.details.destination.region
            }
        }
        let reply1 = try await self.authorizationAccessPolicy.watchAccessPolicies(outbound1) { response in
            var latest = Acme_Authorization_V1_WatchAccessPoliciesResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        _ = reply1
        return Acme_Appointments_V1_ScoreAppointmentResponse.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.appointmentID = input.appointmentID
                $0.status = input.appointment.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processValidateAppointment(_ input: Acme_Appointments_V1_ValidateAppointmentRequest) async throws
        -> Acme_Appointments_V1_ValidateAppointmentResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.appointment.appointmentID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "appointment",
            action: "audit", detail: input.appointment.appointmentID
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ValidateAppointment",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try AppointmentRecord(input.appointment, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Prescriptions_V1_ResolvePrescriptionsRequest.with {
            $0.context = input.context
        }
        let reply0 = try await self.prescriptionsPrescriptionQuery.resolvePrescriptions(outbound0)
        let outbound1 = Acme_Ledger_V1_SummarizeLedgerAccountsRequest.with {
            $0.annotations = input.annotations
            $0.context = input.context
        }
        let envelope1 = try Google_Protobuf_Any(message: outbound1)
        let unpacked1 = try Acme_Ledger_V1_SummarizeLedgerAccountsRequest(unpackingAny: envelope1)
        let reply1 = try await self.ledgerLedgerAccountQuery.summarizeLedgerAccounts(unpacked1)
        return Acme_Appointments_V1_ValidateAppointmentResponse.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.appointmentID = input.appointmentID
                $0.organizer = input.appointment.organizer
            }
            $0.outcome = Acme_Appointments_V1_ValidateAppointmentResponse.Outcome.with {
                $0.message = reply0.result.message
                $0.status = Projection.firstValue(
                    [
                        reply0.result.status,
                        reply1.result.status,
                    ], default: .init())
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply1.result.message
                $0.status = "ok"
            }
        }
    }
}
