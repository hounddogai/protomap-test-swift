import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Routes providers through approval, with escalation and delegation.
final class ProviderApprovalEndpoint: Acme_Appointments_V1_ProviderApprovalService.ServiceProtocol {
    private let store: any RecordRepository
    private let logger: Logger
    private let settings: Settings
    private let appointmentsAppointmentQuery: Acme_Appointments_V1_AppointmentQueryService.Client<MeshTransport>
    private let appointmentsClinicSlotValidation: Acme_Appointments_V1_ClinicSlotValidationService.Client<MeshTransport>
    private let appointmentsProviderQuery: Acme_Appointments_V1_ProviderQueryService.Client<MeshTransport>
    private let appointmentsProviderValidation: Acme_Appointments_V1_ProviderValidationService.Client<MeshTransport>
    private let careplansCareGoalApproval: Acme_Careplans_V1_CareGoalApprovalService.Client<MeshTransport>
    private let careplansCarePlanApproval: Acme_Careplans_V1_CarePlanApprovalService.Client<MeshTransport>
    private let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    private let itsmIncident: Acme_Itsm_V1_IncidentService.Client<MeshTransport>
    private let ledgerLedgerAccount: Acme_Ledger_V1_LedgerAccountService.Client<MeshTransport>
    private let prescriptionsPrescriptionApproval:
        Acme_Prescriptions_V1_PrescriptionApprovalService.Client<MeshTransport>
    private let telehealthTriageApproval: Acme_Telehealth_V1_TriageApprovalService.Client<MeshTransport>
    private let telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client<MeshTransport>
    private let delegateProviderApprovalStep1:
        @Sendable (Acme_Careplans_V1_CommentCareGoalApprovalRequest) async throws ->
            Acme_Careplans_V1_CommentCareGoalApprovalResponse
    private let escalateProviderStep0:
        [String:
            @Sendable (Acme_Careplans_V1_CommentCarePlanApprovalRequest) async throws ->
            Acme_Careplans_V1_CommentCarePlanApprovalResponse]

    init(
        dependencies: any Dependencies,
        appointmentsAppointmentQuery: Acme_Appointments_V1_AppointmentQueryService.Client<MeshTransport>,
        appointmentsClinicSlotValidation: Acme_Appointments_V1_ClinicSlotValidationService.Client<MeshTransport>,
        appointmentsProviderQuery: Acme_Appointments_V1_ProviderQueryService.Client<MeshTransport>,
        appointmentsProviderValidation: Acme_Appointments_V1_ProviderValidationService.Client<MeshTransport>,
        careplansCareGoalApproval: Acme_Careplans_V1_CareGoalApprovalService.Client<MeshTransport>,
        careplansCarePlanApproval: Acme_Careplans_V1_CarePlanApprovalService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        itsmIncident: Acme_Itsm_V1_IncidentService.Client<MeshTransport>,
        ledgerLedgerAccount: Acme_Ledger_V1_LedgerAccountService.Client<MeshTransport>,
        prescriptionsPrescriptionApproval: Acme_Prescriptions_V1_PrescriptionApprovalService.Client<MeshTransport>,
        telehealthTriageApproval: Acme_Telehealth_V1_TriageApprovalService.Client<MeshTransport>,
        telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.appointmentsAppointmentQuery = appointmentsAppointmentQuery
        self.appointmentsClinicSlotValidation = appointmentsClinicSlotValidation
        self.appointmentsProviderQuery = appointmentsProviderQuery
        self.appointmentsProviderValidation = appointmentsProviderValidation
        self.careplansCareGoalApproval = careplansCareGoalApproval
        self.careplansCarePlanApproval = careplansCarePlanApproval
        self.identityUser = identityUser
        self.itsmIncident = itsmIncident
        self.ledgerLedgerAccount = ledgerLedgerAccount
        self.prescriptionsPrescriptionApproval = prescriptionsPrescriptionApproval
        self.telehealthTriageApproval = telehealthTriageApproval
        self.telehealthVideoVisit = telehealthVideoVisit
        self.delegateProviderApprovalStep1 = { request in
            try await careplansCareGoalApproval.commentCareGoalApproval(request)
        }
        self.escalateProviderStep0 = [
            "primary": { request in try await careplansCarePlanApproval.commentCarePlanApproval(request) }
        ]
    }

    /// Approves a provider.
    func approveProvider(
        request: ServerRequest<Acme_Appointments_V1_ApproveProviderRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_ApproveProviderResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processApproveProvider(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Delegates a provider.
    func delegateProviderApproval(
        request: ServerRequest<Acme_Appointments_V1_DelegateProviderApprovalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_DelegateProviderApprovalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processDelegateProviderApproval(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Escalates a provider.
    func escalateProvider(
        request: ServerRequest<Acme_Appointments_V1_EscalateProviderRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_EscalateProviderResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processEscalateProvider(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a provider.
    func getProviderApprovalStatus(
        request: ServerRequest<Acme_Appointments_V1_GetProviderApprovalStatusRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_GetProviderApprovalStatusResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetProviderApprovalStatus(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists providers a page at a time.
    func listPendingProviders(
        request: ServerRequest<Acme_Appointments_V1_ListPendingProvidersRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_ListPendingProvidersResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListPendingProviders(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Recalls a provider.
    func recallProvider(
        request: ServerRequest<Acme_Appointments_V1_RecallProviderRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_RecallProviderResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRecallProvider(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Submits a provider.
    func submitProvider(
        request: ServerRequest<Acme_Appointments_V1_SubmitProviderRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_SubmitProviderResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSubmitProvider(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processApproveProvider(_ input: Acme_Appointments_V1_ApproveProviderRequest) async throws
        -> Acme_Appointments_V1_ApproveProviderResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "provider",
            action: "audit", detail: input.details.approver.displayName
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ApproveProvider",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try ProviderRecord(input.provider, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let importFrame = Acme_Telehealth_V1_BatchCreateVideoVisitsRequest.with {
            $0.context = input.context
        }
        _ = try await self.telehealthVideoVisit.batchCreateVideoVisits { writer in
            try await writer.write(importFrame)
        }
        let outbound0 = Acme_Telehealth_V1_ListPendingTriagesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Telehealth_V1_ListPendingTriagesRequest.Filter.with {
                $0.region = input.provider.primaryAddress.region
            }
        }
        let port0 = RPCOperations.port { (request: Acme_Telehealth_V1_ListPendingTriagesRequest) in
            try await self.telehealthTriageApproval.listPendingTriages(request)
        }
        let reply0 = try await port0.execute(outbound0)
        return Acme_Appointments_V1_ApproveProviderResponse.with {
            $0.outcome = Acme_Appointments_V1_ApproveProviderResponse.Outcome.with {
                $0.message = reply0.result.message
            }
            $0.provider = Acme_Appointments_V1_Provider.with {
                $0.providerID = input.providerID
                $0.relationshipManager = input.provider.relationshipManager
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processDelegateProviderApproval(_ input: Acme_Appointments_V1_DelegateProviderApprovalRequest) async throws
        -> Acme_Appointments_V1_DelegateProviderApprovalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "provider",
            action: "audit", detail: input.details.approver.displayName
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "DelegateProviderApproval",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try ProviderRecord(input.provider, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let selection0_3: String
        switch input.provider.identityDocument {
        case .passport(let passport):
            selection0_3 = passport.number
        default: selection0_3 = .init()
        }
        let outbound0 = Acme_Appointments_V1_ScoreProviderRequest.with {
            $0.context = input.context
            $0.provider = Acme_Appointments_V1_Provider.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = input.provider.audit.createdBy
                }
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.preferredChannel = input.provider.contact.preferredChannel
                }
                $0.nationalID = Acme_Appointments_V1_ProviderNationalId.with {
                    $0.number = selection0_3
                }
            }
        }
        let reply0 = try await self.appointmentsProviderValidation.scoreProvider(outbound0)
        let outbound1 = Acme_Careplans_V1_CommentCareGoalApprovalRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply0.provider.audit.updatedAt
                }
                $0.customer = Acme_Patients_V1_PatientRef.with {
                    $0.email = input.provider.relationshipManager.email
                }
            }
            $0.context = input.context
        }
        let reply1 = try await self.delegateProviderApprovalStep1(outbound1)
        return Acme_Appointments_V1_DelegateProviderApprovalResponse.with {
            $0.outcome = Acme_Appointments_V1_DelegateProviderApprovalResponse.Outcome.with {
                $0.status = reply0.result.status
            }
            $0.provider = Acme_Appointments_V1_Provider.with {
                $0.attributes = input.provider.attributes
                $0.providerID = input.providerID
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply1.careGoal.customer.displayName
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply1.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processEscalateProvider(_ input: Acme_Appointments_V1_EscalateProviderRequest) async throws
        -> Acme_Appointments_V1_EscalateProviderResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "provider",
            action: "audit", detail: input.details.approver.displayName
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "EscalateProvider",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try ProviderRecord(input.provider, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Careplans_V1_CommentCarePlanApprovalRequest.with {
            $0.context = input.context
            $0.details = Acme_Careplans_V1_CommentCarePlanApprovalRequest.Details.with {
                $0.approver = Acme_Identity_V1_UserRef.with {
                    $0.email = input.provider.relationshipManager.email
                }
            }
        }
        guard let execute0 = self.escalateProviderStep0[settings.region] ?? self.escalateProviderStep0["primary"] else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply0 = try await execute0(outbound0)
        let outbound1 = Acme_Appointments_V1_ScoreClinicSlotRequest.with {
            $0.clinicSlot = Acme_Appointments_V1_ClinicSlot.with {
                $0.participants = [
                    Acme_Appointments_V1_ClinicSlotParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = input.details.approver.email
                            $0.phone = input.provider.contact.phone
                        }
                    }
                ]
            }
            $0.context = input.context
        }
        let reply1 = try await self.appointmentsClinicSlotValidation.scoreClinicSlot(outbound1)
        let outbound2 = Acme_Itsm_V1_CloneIncidentRequest.with {
            $0.context = input.context
            $0.incident = Acme_Itsm_V1_Incident.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply1.clinicSlot.audit.createdAt
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.approver.email
                }
            }
        }
        let envelope2 = try Google_Protobuf_Any(message: outbound2)
        let unpacked2 = try Acme_Itsm_V1_CloneIncidentRequest(unpackingAny: envelope2)
        let reply2 = try await self.itsmIncident.cloneIncident(unpacked2)
        return Acme_Appointments_V1_EscalateProviderResponse.with {
            $0.outcome = Acme_Appointments_V1_EscalateProviderResponse.Outcome.with {
                $0.message = reply0.result.message
            }
            $0.provider = Acme_Appointments_V1_Provider.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.name = reply2.incident.requester.name
                }
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.recipient = reply1.clinicSlot.location.recipient
                }
                $0.providerID = input.providerID
                $0.relationshipManager = input.provider.relationshipManager
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.message = reply0.outcome.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processGetProviderApprovalStatus(_ input: Acme_Appointments_V1_GetProviderApprovalStatusRequest) async throws
        -> Acme_Appointments_V1_GetProviderApprovalStatusResponse
    {
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "GetProviderApprovalStatus",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "provider",
            action: "GetProviderApprovalStatus", detail: input.context.traceID
        )
        let outbound0 = Acme_Prescriptions_V1_CommentPrescriptionApprovalRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_CommentPrescriptionApprovalRequest.Details.with {
                $0.approver = Acme_Identity_V1_UserRef.with {
                    $0.email = input.context.actor.email
                    $0.userID = input.context.actor.userID
                }
            }
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.context.deadline
                }
                $0.metadata = input.context.baggage
            }
        }
        let json0 = try outbound0.jsonString()
        let decoded0 = try Acme_Prescriptions_V1_CommentPrescriptionApprovalRequest(jsonString: json0)
        let reply0 = try await self.prescriptionsPrescriptionApproval.commentPrescriptionApproval(decoded0)
        return Acme_Appointments_V1_GetProviderApprovalStatusResponse.with {
            $0.provider = Acme_Appointments_V1_Provider.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply0.prescription.counterparty.email
                }
                $0.providerID = input.providerID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processListPendingProviders(_ input: Acme_Appointments_V1_ListPendingProvidersRequest) async throws
        -> Acme_Appointments_V1_ListPendingProvidersResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "provider",
            action: "audit", detail: input.filter.ownerID
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ListPendingProviders",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "provider",
            action: "ListPendingProviders", detail: input.context.traceID
        )
        return Acme_Appointments_V1_ListPendingProvidersResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processRecallProvider(_ input: Acme_Appointments_V1_RecallProviderRequest) async throws
        -> Acme_Appointments_V1_RecallProviderResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "provider",
            action: "audit", detail: input.details.approver.displayName
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "RecallProvider",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try ProviderRecord(input.provider, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Appointments_V1_NormalizeClinicSlotRequest.forProviderApprovalEndpointRecallProvider0(
            input
        )
        let reply0 = try await self.appointmentsClinicSlotValidation.normalizeClinicSlot(outbound0)
        let outbound1 = Acme_Appointments_V1_LookupProviderRequest.with {
            $0.context = input.context
            $0.providerID = input.provider.providerID
        }
        let reply1 = try await self.appointmentsProviderQuery.lookupProvider(
            outbound1, metadata: ["x-acme-region": .string(settings.region)]
        )
        return Acme_Appointments_V1_RecallProviderResponse.with {
            $0.provider = Acme_Appointments_V1_Provider.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply0.clinicSlot.audit.createdAt
                }
                $0.providerID = input.providerID
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.email = reply1.provider.relationshipManager.email
                }
                $0.status = input.provider.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.message = reply0.outcome.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processSubmitProvider(_ input: Acme_Appointments_V1_SubmitProviderRequest) async throws
        -> Acme_Appointments_V1_SubmitProviderResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "provider",
            action: "audit", detail: input.details.approver.displayName
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "SubmitProvider",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try ProviderRecord(input.provider, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Appointments_V1_SummarizeAppointmentsRequest.with {
            $0.annotations = input.annotations
            $0.context = input.context
            $0.reason = input.reason
        }
        let reply0 = try await RPCOperations.call(outbound0) { request in
            try await self.appointmentsAppointmentQuery.summarizeAppointments(request)
        }
        let outbound1 = Acme_Ledger_V1_CreateLedgerAccountRequest.with {
            $0.context = Projection.read(input, at: \Acme_Appointments_V1_SubmitProviderRequest.context)
            $0.ledgerAccount = Acme_Ledger_V1_LedgerAccount.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = Projection.read(
                        input, at: \Acme_Appointments_V1_SubmitProviderRequest.provider.relationshipManager.email)
                }
            }
        }
        let reply1 = try await self.ledgerLedgerAccount.createLedgerAccount(outbound1)
        let selection2_2: String
        switch input.provider.identityDocument {
        case .nationalID(let nationalID):
            selection2_2 = nationalID.issuingCountry
        default: selection2_2 = .init()
        }
        let outbound2 = Acme_Appointments_V1_PreviewProviderRequest.with {
            $0.context = input.context
            $0.provider = Acme_Appointments_V1_Provider.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.name = input.provider.contact.name
                }
                $0.passport = Acme_Appointments_V1_ProviderPassport.with {
                    $0.issuingCountry = selection2_2
                }
            }
        }
        let reply2 = try await self.appointmentsProviderValidation.previewProvider(outbound2)
        return Acme_Appointments_V1_SubmitProviderResponse.with {
            $0.provider = Acme_Appointments_V1_Provider.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply2.provider.contact.email
                    $0.name = input.provider.name
                }
                $0.providerID = input.providerID
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.userID = reply2.provider.relationshipManager.userID
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply1.result.message
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }
}
