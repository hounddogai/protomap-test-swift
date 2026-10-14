import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Manages prescriptions: creates, reads, changes, and lists them.
final class PrescriptionEndpoint: Acme_Prescriptions_V1_PrescriptionService.ServiceProtocol {
    private let store: any RecordRepository
    private let logger: Logger
    private let settings: Settings
    private let auditAuditEvent: Acme_Audit_V1_AuditEventService.Client<MeshTransport>
    private let authorizationAccessPolicyQuery: Acme_Authorization_V1_AccessPolicyQueryService.Client<MeshTransport>
    private let boxofficeBoxOfficeSale: Acme_Boxoffice_V1_BoxOfficeSaleService.Client<MeshTransport>
    private let careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client<MeshTransport>
    private let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    private let identityUserQuery: Acme_Identity_V1_UserQueryService.Client<MeshTransport>
    private let identityUserValidation: Acme_Identity_V1_UserValidationService.Client<MeshTransport>
    private let prescriptionsMedicationCalculation:
        Acme_Prescriptions_V1_MedicationCalculationService.Client<MeshTransport>
    private let prescriptionsMedicationValidation:
        Acme_Prescriptions_V1_MedicationValidationService.Client<MeshTransport>
    private let prescriptionsPrescriptionCalculation:
        Acme_Prescriptions_V1_PrescriptionCalculationService.Client<MeshTransport>
    private let prescriptionsPrescriptionValidation:
        Acme_Prescriptions_V1_PrescriptionValidationService.Client<MeshTransport>
    private let prescriptionsRefillCalculation: Acme_Prescriptions_V1_RefillCalculationService.Client<MeshTransport>
    private let prescriptionsRefillValidation: Acme_Prescriptions_V1_RefillValidationService.Client<MeshTransport>
    private let searchSearchIndex: Acme_Search_V1_SearchIndexService.Client<MeshTransport>
    private let sponsorshipsSponsorQuery: Acme_Sponsorships_V1_SponsorQueryService.Client<MeshTransport>
    private let telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client<MeshTransport>
    private let watchPrescriptionsStep1:
        any RPCPort<Acme_Identity_V1_BrowseUsersRequest, Acme_Identity_V1_BrowseUsersResponse>
    private let watchPrescriptionsStep3:
        @Sendable (Acme_Identity_V1_CheckUserEligibilityRequest) async throws ->
            Acme_Identity_V1_CheckUserEligibilityResponse

    init(
        dependencies: any Dependencies,
        auditAuditEvent: Acme_Audit_V1_AuditEventService.Client<MeshTransport>,
        authorizationAccessPolicyQuery: Acme_Authorization_V1_AccessPolicyQueryService.Client<MeshTransport>,
        boxofficeBoxOfficeSale: Acme_Boxoffice_V1_BoxOfficeSaleService.Client<MeshTransport>,
        careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        identityUserQuery: Acme_Identity_V1_UserQueryService.Client<MeshTransport>,
        identityUserValidation: Acme_Identity_V1_UserValidationService.Client<MeshTransport>,
        prescriptionsMedicationCalculation: Acme_Prescriptions_V1_MedicationCalculationService.Client<MeshTransport>,
        prescriptionsMedicationValidation: Acme_Prescriptions_V1_MedicationValidationService.Client<MeshTransport>,
        prescriptionsPrescriptionCalculation: Acme_Prescriptions_V1_PrescriptionCalculationService.Client<
            MeshTransport
        >,
        prescriptionsPrescriptionValidation: Acme_Prescriptions_V1_PrescriptionValidationService.Client<MeshTransport>,
        prescriptionsRefillCalculation: Acme_Prescriptions_V1_RefillCalculationService.Client<MeshTransport>,
        prescriptionsRefillValidation: Acme_Prescriptions_V1_RefillValidationService.Client<MeshTransport>,
        searchSearchIndex: Acme_Search_V1_SearchIndexService.Client<MeshTransport>,
        sponsorshipsSponsorQuery: Acme_Sponsorships_V1_SponsorQueryService.Client<MeshTransport>,
        telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.auditAuditEvent = auditAuditEvent
        self.authorizationAccessPolicyQuery = authorizationAccessPolicyQuery
        self.boxofficeBoxOfficeSale = boxofficeBoxOfficeSale
        self.careplansCarePlanValidation = careplansCarePlanValidation
        self.identityUser = identityUser
        self.identityUserQuery = identityUserQuery
        self.identityUserValidation = identityUserValidation
        self.prescriptionsMedicationCalculation = prescriptionsMedicationCalculation
        self.prescriptionsMedicationValidation = prescriptionsMedicationValidation
        self.prescriptionsPrescriptionCalculation = prescriptionsPrescriptionCalculation
        self.prescriptionsPrescriptionValidation = prescriptionsPrescriptionValidation
        self.prescriptionsRefillCalculation = prescriptionsRefillCalculation
        self.prescriptionsRefillValidation = prescriptionsRefillValidation
        self.searchSearchIndex = searchSearchIndex
        self.sponsorshipsSponsorQuery = sponsorshipsSponsorQuery
        self.telehealthVideoVisit = telehealthVideoVisit
        self.watchPrescriptionsStep1 = ClosurePort<
            Acme_Identity_V1_BrowseUsersRequest, Acme_Identity_V1_BrowseUsersResponse
        >({ request in try await identityUserQuery.browseUsers(request) })
        self.watchPrescriptionsStep3 = { request in try await identityUserValidation.checkUserEligibility(request) }
    }

    /// Takes a stream of prescriptions and answers once at the end.
    func batchCreatePrescriptions(
        request: StreamingServerRequest<Acme_Prescriptions_V1_BatchCreatePrescriptionsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_BatchCreatePrescriptionsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            var response = Acme_Prescriptions_V1_BatchCreatePrescriptionsResponse()
            var accepted: Int64 = 0
            for try await message in request.messages {
                response = try await processBatchCreatePrescriptions(message)
                accepted += 1
            }
            response.accepted = accepted
            return ServerResponse(message: response)
        }
    }

    /// Returns several prescriptions at once.
    func batchGetPrescriptions(
        request: ServerRequest<Acme_Prescriptions_V1_BatchGetPrescriptionsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_BatchGetPrescriptionsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processBatchGetPrescriptions(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Creates a prescription.
    func createPrescription(
        request: ServerRequest<Acme_Prescriptions_V1_CreatePrescriptionRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_CreatePrescriptionResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCreatePrescription(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Deletes a prescription.
    func deletePrescription(
        request: ServerRequest<Acme_Prescriptions_V1_DeletePrescriptionRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_DeletePrescriptionResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processDeletePrescription(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a prescription.
    func getPrescription(
        request: ServerRequest<Acme_Prescriptions_V1_GetPrescriptionRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_GetPrescriptionResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetPrescription(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists prescriptions a page at a time.
    func listPrescriptions(
        request: ServerRequest<Acme_Prescriptions_V1_ListPrescriptionsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ListPrescriptionsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListPrescriptions(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Changes a prescription.
    func updatePrescription(
        request: ServerRequest<Acme_Prescriptions_V1_UpdatePrescriptionRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_UpdatePrescriptionResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processUpdatePrescription(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Streams the changes of prescriptions as they happen.
    func watchPrescriptions(
        request: ServerRequest<Acme_Prescriptions_V1_WatchPrescriptionsRequest>,
        context: ServerContext
    ) async throws -> StreamingServerResponse<Acme_Prescriptions_V1_WatchPrescriptionsResponse> {
        return StreamingServerResponse { writer in
            try await CallerScope.$metadata.withValue(request.metadata) {
                let response = try await self.processWatchPrescriptions(request.message)
                try await writer.write(response)
                return [:]
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processBatchCreatePrescriptions(_ input: Acme_Prescriptions_V1_BatchCreatePrescriptionsRequest) async throws
        -> Acme_Prescriptions_V1_BatchCreatePrescriptionsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.header.format)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "audit", detail: input.header.format
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "BatchCreatePrescriptions",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "BatchCreatePrescriptions", detail: input.context.traceID
        )
        let importFrame = Acme_Telehealth_V1_BatchCreateVideoVisitsRequest.with {
            $0.context = input.context
        }
        _ = try await self.telehealthVideoVisit.batchCreateVideoVisits { writer in
            try await writer.write(importFrame)
        }
        let requests0 = input.record.lines.map { element in
            Acme_Prescriptions_V1_ValidateMedicationRequest.with {
                $0.context = input.context
                $0.medication = Acme_Prescriptions_V1_Medication.with {
                    $0.components = [
                        "primary": Acme_Prescriptions_V1_MedicationComponent.with {
                            $0.quantity = element.quantity
                        }
                    ]
                }
            }
        }
        let replies0 = try await FanOut.map(requests0) { candidate in
            try await self.prescriptionsMedicationValidation.validateMedication(candidate)
        }
        let reply0 = replies0.first ?? Acme_Prescriptions_V1_ValidateMedicationResponse()
        let selection1_4: String
        switch input.chunk {
        case .record(let record):
            selection1_4 = record.audit.updatedBy
        default: selection1_4 = .init()
        }
        let outbound1 = Acme_Prescriptions_V1_ExplainRefillDecisionRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_ExplainRefillDecisionRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply0.medication.owner.email
                }
            }
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply0.medication.owner.displayName
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply0.medication.audit.updatedAt
                    $0.updatedBy = selection1_4
                }
            }
        }
        let reply1 = try await self.prescriptionsRefillValidation.explainRefillDecision(outbound1)
        let selection2_2: String
        switch input.chunk {
        case .record(let record):
            selection2_2 = record.counterparty.email
        default: selection2_2 = .init()
        }
        let outbound2 = Acme_Prescriptions_V1_NormalizeRefillRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_NormalizeRefillRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = selection2_2
                }
            }
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.email = reply1.refill.assignee.email
                    $0.userID = reply0.medication.owner.userID
                }
                $0.sla = Acme_Prescriptions_V1_RefillSla.with {
                    $0.breached = reply1.refill.sla.breached
                }
            }
        }
        let reply2 = try await self.prescriptionsRefillValidation.normalizeRefill(outbound2)
        let selection3_2: String
        switch input.chunk {
        case .record(let record):
            selection3_2 = record.card.holderName
        default: selection3_2 = .init()
        }
        let selection3_3: Google_Protobuf_Timestamp
        switch input.chunk {
        case .record(let record):
            selection3_3 = record.audit.createdAt
        default: selection3_3 = .init()
        }
        let selection3_4: String
        switch input.chunk {
        case .record(let record):
            selection3_4 = record.card.token
        default: selection3_4 = .init()
        }
        let outbound3 = Acme_Prescriptions_V1_ScorePrescriptionRequest.with {
            $0.context = input.context
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = selection3_3
                }
                $0.card = Acme_Prescriptions_V1_PrescriptionCardSettlement.with {
                    $0.holderName = selection3_2
                    $0.token = selection3_4
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.email = reply2.refill.assignee.email
                }
            }
        }
        let reply3 = try await self.prescriptionsPrescriptionValidation.scorePrescription(outbound3)
        return Acme_Prescriptions_V1_BatchCreatePrescriptionsResponse.with {
            $0.rejections = [
                Acme_Prescriptions_V1_BatchCreatePrescriptionsResponse.Rejection.with {
                    $0.prescriptionID = reply2.refill.customer.prescriptionID
                }
            ]
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply1.result.details
                $0.message = Projection.firstValue(
                    [
                        reply1.result.message,
                        reply3.result.message,
                    ], default: .init())
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processBatchGetPrescriptions(_ input: Acme_Prescriptions_V1_BatchGetPrescriptionsRequest) async throws
        -> Acme_Prescriptions_V1_BatchGetPrescriptionsResponse
    {
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "BatchGetPrescriptions",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "BatchGetPrescriptions", detail: input.context.traceID
        )
        let outbound0 = Acme_Sponsorships_V1_SuggestSponsorsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Sponsorships_V1_SuggestSponsorsRequest.Filter.with {
                $0.createdAfter = input.context.deadline
                $0.labels = input.context.baggage
                $0.ownerID = input.context.actor.userID
            }
        }
        let reply0 = try await self.sponsorshipsSponsorQuery.suggestSponsors(
            outbound0, metadata: ["x-acme-region": .string(settings.region)]
        )
        return Acme_Prescriptions_V1_BatchGetPrescriptionsResponse.with {
            $0.pageInfo = Acme_Common_V1_PageInfo.with {
                $0.totalSize = reply0.pageInfo.totalSize
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processCreatePrescription(_ input: Acme_Prescriptions_V1_CreatePrescriptionRequest) async throws
        -> Acme_Prescriptions_V1_CreatePrescriptionResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.prescription.audit.createdBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "audit", detail: input.prescription.audit.createdBy
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "CreatePrescription",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PrescriptionRecord(input.prescription, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let selection0_2: String
        switch input.prescription.settlement {
        case .bank(let bank):
            selection0_2 = bank.accountHolder
        default: selection0_2 = .init()
        }
        let outbound0 = Acme_Careplans_V1_PreviewCarePlanRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.bank = Acme_Careplans_V1_CarePlanBankSettlement.with {
                    $0.accountHolder = selection0_2
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = input.prescription.billingAddress.postalCode
                }
                $0.counterparty = Acme_Appointments_V1_AppointmentRef.with {
                    $0.displayName = input.prescription.counterparty.displayName
                }
            }
            $0.context = input.context
        }
        let reply0 = try await self.careplansCarePlanValidation.previewCarePlan(outbound0)
        let outbound1 = Acme_Prescriptions_V1_GetPrescriptionRulesRequest.with {
            $0.context = input.context
            $0.prescriptionID = input.prescription.prescriptionID
        }
        let reply1 = try await RPCOperations.call(outbound1) { request in
            try await self.prescriptionsPrescriptionValidation.getPrescriptionRules(request)
        }
        return Acme_Prescriptions_V1_CreatePrescriptionResponse.with {
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = reply0.carePlan.billingAddress.countryCode
                }
                $0.status = input.prescription.status
                $0.total = input.prescription.total
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.referenceIds = reply1.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processDeletePrescription(_ input: Acme_Prescriptions_V1_DeletePrescriptionRequest) async throws
        -> Acme_Prescriptions_V1_DeletePrescriptionResponse
    {
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "DeletePrescription",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "DeletePrescription", detail: input.context.traceID
        )
        let outbound0 = Acme_Authorization_V1_BrowseAccessPoliciesRequest.with {
            $0.context = Projection.read(input, at: \Acme_Prescriptions_V1_DeletePrescriptionRequest.context)
            $0.filter = Acme_Authorization_V1_BrowseAccessPoliciesRequest.Filter.with {
                $0.createdAfter = Projection.read(
                    input, at: \Acme_Prescriptions_V1_DeletePrescriptionRequest.context.deadline)
                $0.ownerID = Projection.read(input, at: \Acme_Prescriptions_V1_DeletePrescriptionRequest.prescriptionID)
            }
        }
        let reply0 = try await self.authorizationAccessPolicyQuery.browseAccessPolicies(outbound0)
        let outbound1 = Acme_Prescriptions_V1_SimulateRefillRequest.with {
            $0.context = input.context
            $0.reason = input.reason
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.email = input.context.actor.email
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = input.etag
                }
                $0.customer = Acme_Prescriptions_V1_PrescriptionRef.with {
                    $0.prescriptionID = input.prescriptionID
                }
            }
        }
        let step1: @Sendable () async throws -> Acme_Prescriptions_V1_SimulateRefillResponse = {
            try await self.prescriptionsRefillCalculation.simulateRefill(outbound1)
        }
        let reply1 = try await step1()
        return Acme_Prescriptions_V1_DeletePrescriptionResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.status = reply1.result.status
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processGetPrescription(_ input: Acme_Prescriptions_V1_GetPrescriptionRequest) async throws
        -> Acme_Prescriptions_V1_GetPrescriptionResponse
    {
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "GetPrescription",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "GetPrescription", detail: input.context.traceID
        )
        return Acme_Prescriptions_V1_GetPrescriptionResponse.with {
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.prescriptionID = input.prescriptionID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processListPrescriptions(_ input: Acme_Prescriptions_V1_ListPrescriptionsRequest) async throws
        -> Acme_Prescriptions_V1_ListPrescriptionsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "audit", detail: input.filter.ownerID
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ListPrescriptions",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "ListPrescriptions", detail: input.context.traceID
        )
        var outbound0 = Acme_Prescriptions_V1_NormalizeMedicationRequest()
        outbound0.context = input.context
        outbound0.medication = Acme_Prescriptions_V1_Medication.with {
            $0.address = Acme_Common_V1_PostalAddress.with {
                $0.region = input.filter.region
            }
        }
        let reply0 = try await self.prescriptionsMedicationValidation.normalizeMedication(outbound0)
        return Acme_Prescriptions_V1_ListPrescriptionsResponse.with {
            $0.prescriptions = [
                Acme_Prescriptions_V1_Prescription.with {
                    $0.audit = Acme_Common_V1_AuditInfo.with {
                        $0.updatedAt = reply0.medication.audit.updatedAt
                    }
                    $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                        $0.region = reply0.medication.address.region
                    }
                }
            ]
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processUpdatePrescription(_ input: Acme_Prescriptions_V1_UpdatePrescriptionRequest) async throws
        -> Acme_Prescriptions_V1_UpdatePrescriptionResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.prescription.audit.createdBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "audit", detail: input.prescription.audit.createdBy
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "UpdatePrescription",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PrescriptionRecord(input.prescription, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Audit_V1_UpdateAuditEventRequest.with {
            $0.auditEvent = Acme_Audit_V1_AuditEvent.with {
                $0.subject = Acme_Audit_V1_AuditTrailRef.with {
                    $0.displayName = input.prescription.counterparty.displayName
                }
            }
            $0.context = input.context
        }
        let step0: @Sendable () async throws -> Acme_Audit_V1_UpdateAuditEventResponse = {
            try await self.auditAuditEvent.updateAuditEvent(outbound0)
        }
        let reply0 = try await step0()
        let selection1_1: String
        switch input.prescription.settlement {
        case .card(let card):
            selection1_1 = card.token
        default: selection1_1 = .init()
        }
        let selection1_2: String
        switch input.prescription.settlement {
        case .card(let card):
            selection1_2 = card.holderName
        default: selection1_2 = .init()
        }
        let outbound1 = Acme_Boxoffice_V1_CloneBoxOfficeSaleRequest.with {
            $0.boxOfficeSale = Acme_Boxoffice_V1_BoxOfficeSale.with {
                $0.card = Acme_Boxoffice_V1_BoxOfficeSaleCardSettlement.with {
                    $0.holderName = selection1_2
                    $0.token = selection1_1
                }
            }
            $0.context = input.context
        }
        let reply1 = try await self.boxofficeBoxOfficeSale.cloneBoxOfficeSale(outbound1)
        let outbound2 = Acme_Search_V1_SearchSearchIndexesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Search_V1_SearchSearchIndexesRequest.Filter.with {
                $0.createdAfter = reply1.boxOfficeSale.audit.createdAt
                $0.labels = reply0.result.details
                $0.ownerID = input.prescription.counterparty.patientID
                $0.region = input.prescription.billingAddress.region
            }
        }
        let reply2 = try await self.searchSearchIndex.searchSearchIndexes(outbound2)
        let selection3_1: String
        switch input.prescription.settlement {
        case .bank(let bank):
            selection3_1 = bank.bic
        default: selection3_1 = .init()
        }
        let selection3_2: String
        switch input.prescription.settlement {
        case .bank(let bank):
            selection3_2 = bank.accountHolder
        default: selection3_2 = .init()
        }
        let outbound3 = Acme_Careplans_V1_NormalizeCarePlanRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.bank = Acme_Careplans_V1_CarePlanBankSettlement.with {
                    $0.accountHolder = selection3_2
                    $0.bic = selection3_1
                }
            }
            $0.context = input.context
        }
        let reply3 = try await self.careplansCarePlanValidation.normalizeCarePlan(outbound3)
        return Acme_Prescriptions_V1_UpdatePrescriptionResponse.with {
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply3.carePlan.audit.createdAt
                }
                $0.billingAddress = input.prescription.billingAddress
                $0.metadata = input.prescription.metadata
                $0.number = reply1.boxOfficeSale.number
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = Projection.firstValue(
                    [
                        reply0.auditEvent.correlationID,
                        reply2.result.correlationID,
                    ], default: .init())
                $0.details = reply2.result.details
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processWatchPrescriptions(_ input: Acme_Prescriptions_V1_WatchPrescriptionsRequest) async throws
        -> Acme_Prescriptions_V1_WatchPrescriptionsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.subscriber.phone)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "audit", detail: input.subscriber.phone
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "WatchPrescriptions",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "WatchPrescriptions", detail: input.context.traceID
        )
        let outbound0 = Acme_Prescriptions_V1_ComparePrescriptionOptionsRequest.with {
            $0.context = input.context
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = input.filter.createdAfter
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.email = input.subscriber.email
                }
                $0.dueAt = input.since
            }
        }
        async let remote0 = self.prescriptionsPrescriptionCalculation.comparePrescriptionOptions(outbound0)
        async let persisted0 = store.count(tenant: input.context.tenantID)
        let (reply0, count0) = try await (remote0, persisted0)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count0)])
        let outbound1 = Acme_Identity_V1_BrowseUsersRequest.with {
            $0.context = input.context
            $0.filter = Acme_Identity_V1_BrowseUsersRequest.Filter.with {
                $0.labels = input.filter.labels
                $0.ownerID = input.filter.ownerID
                $0.query = input.filter.query
                $0.region = reply0.prescription.billingAddress.region
            }
        }
        let reply1 = try await self.watchPrescriptionsStep1.execute(outbound1)
        let outbound2 = Acme_Prescriptions_V1_RecalculateMedicationsRequest.with {
            $0.context = input.context
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.address = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = reply0.prescription.billingAddress.countryCode
                    $0.lines = reply0.prescription.billingAddress.lines
                    $0.postalCode = reply0.prescription.billingAddress.postalCode
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply0.prescription.audit.createdBy
                }
            }
        }
        let port2 = RPCOperations.port { (request: Acme_Prescriptions_V1_RecalculateMedicationsRequest) in
            try await self.prescriptionsMedicationCalculation.recalculateMedications(request)
        }
        let reply2 = try await port2.execute(outbound2)
        let outbound3 = Acme_Identity_V1_CheckUserEligibilityRequest.with {
            $0.context = input.context
            $0.user = Acme_Identity_V1_User.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply2.medication.audit.createdAt
                    $0.createdBy = reply2.medication.audit.createdBy
                }
            }
        }
        let reply3 = try await self.watchPrescriptionsStep3(outbound3)
        return Acme_Prescriptions_V1_WatchPrescriptionsResponse.with {
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply2.medication.audit.createdAt
                    $0.createdBy = reply0.prescription.audit.createdBy
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = reply3.user.primaryAddress.postalCode
                    $0.recipient = reply3.user.primaryAddress.recipient
                    $0.region = input.filter.region
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = reply0.prescription.counterparty.displayName
                    $0.email = input.subscriber.email
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply1.result.message
                $0.status = "ok"
            }
        }
    }
}
