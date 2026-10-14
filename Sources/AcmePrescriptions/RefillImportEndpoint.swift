import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Takes refills in bulk from partners and legacy systems.
final class RefillImportEndpoint: Acme_Prescriptions_V1_RefillImportService.ServiceProtocol {
    private let store: any RecordRepository
    private let logger: Logger
    private let settings: Settings
    private let authorizationAccessPolicy: Acme_Authorization_V1_AccessPolicyService.Client<MeshTransport>
    private let careplansCareGoalApproval: Acme_Careplans_V1_CareGoalApprovalService.Client<MeshTransport>
    private let documentsDocumentQuery: Acme_Documents_V1_DocumentQueryService.Client<MeshTransport>
    private let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    private let ledgerLedgerAccountValidation: Acme_Ledger_V1_LedgerAccountValidationService.Client<MeshTransport>
    private let patientsPatient: Acme_Patients_V1_PatientService.Client<MeshTransport>
    private let patientsPatientCalculation: Acme_Patients_V1_PatientCalculationService.Client<MeshTransport>
    private let patientsPatientValidation: Acme_Patients_V1_PatientValidationService.Client<MeshTransport>
    private let prescriptionsPrescription: Acme_Prescriptions_V1_PrescriptionService.Client<MeshTransport>
    private let prescriptionsPrescriptionQuery: Acme_Prescriptions_V1_PrescriptionQueryService.Client<MeshTransport>
    private let prescriptionsRefillValidation: Acme_Prescriptions_V1_RefillValidationService.Client<MeshTransport>
    private let telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client<MeshTransport>
    private let telehealthVideoVisitWorkflow: Acme_Telehealth_V1_VideoVisitWorkflowService.Client<MeshTransport>
    private let venuesVenueValidation: Acme_Venues_V1_VenueValidationService.Client<MeshTransport>
    private let listRefillImportsStep0:
        @Sendable (Acme_Ledger_V1_ScoreLedgerAccountRequest) async throws -> Acme_Ledger_V1_ScoreLedgerAccountResponse
    private let mapRefillImportColumnsStep0:
        [String:
            @Sendable (Acme_Documents_V1_SuggestDocumentsRequest) async throws ->
            Acme_Documents_V1_SuggestDocumentsResponse]

    init(
        dependencies: any Dependencies,
        authorizationAccessPolicy: Acme_Authorization_V1_AccessPolicyService.Client<MeshTransport>,
        careplansCareGoalApproval: Acme_Careplans_V1_CareGoalApprovalService.Client<MeshTransport>,
        documentsDocumentQuery: Acme_Documents_V1_DocumentQueryService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        ledgerLedgerAccountValidation: Acme_Ledger_V1_LedgerAccountValidationService.Client<MeshTransport>,
        patientsPatient: Acme_Patients_V1_PatientService.Client<MeshTransport>,
        patientsPatientCalculation: Acme_Patients_V1_PatientCalculationService.Client<MeshTransport>,
        patientsPatientValidation: Acme_Patients_V1_PatientValidationService.Client<MeshTransport>,
        prescriptionsPrescription: Acme_Prescriptions_V1_PrescriptionService.Client<MeshTransport>,
        prescriptionsPrescriptionQuery: Acme_Prescriptions_V1_PrescriptionQueryService.Client<MeshTransport>,
        prescriptionsRefillValidation: Acme_Prescriptions_V1_RefillValidationService.Client<MeshTransport>,
        telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client<MeshTransport>,
        telehealthVideoVisitWorkflow: Acme_Telehealth_V1_VideoVisitWorkflowService.Client<MeshTransport>,
        venuesVenueValidation: Acme_Venues_V1_VenueValidationService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.authorizationAccessPolicy = authorizationAccessPolicy
        self.careplansCareGoalApproval = careplansCareGoalApproval
        self.documentsDocumentQuery = documentsDocumentQuery
        self.identityUser = identityUser
        self.ledgerLedgerAccountValidation = ledgerLedgerAccountValidation
        self.patientsPatient = patientsPatient
        self.patientsPatientCalculation = patientsPatientCalculation
        self.patientsPatientValidation = patientsPatientValidation
        self.prescriptionsPrescription = prescriptionsPrescription
        self.prescriptionsPrescriptionQuery = prescriptionsPrescriptionQuery
        self.prescriptionsRefillValidation = prescriptionsRefillValidation
        self.telehealthVideoVisit = telehealthVideoVisit
        self.telehealthVideoVisitWorkflow = telehealthVideoVisitWorkflow
        self.venuesVenueValidation = venuesVenueValidation
        self.listRefillImportsStep0 = { request in try await ledgerLedgerAccountValidation.scoreLedgerAccount(request) }
        self.mapRefillImportColumnsStep0 = [
            "primary": { request in try await documentsDocumentQuery.suggestDocuments(request) }
        ]
    }

    /// Cancels a refill.
    func cancelRefillImport(
        request: ServerRequest<Acme_Prescriptions_V1_CancelRefillImportRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_CancelRefillImportResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCancelRefillImport(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a refill.
    func getRefillImportStatus(
        request: ServerRequest<Acme_Prescriptions_V1_GetRefillImportStatusRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_GetRefillImportStatusResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetRefillImportStatus(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Takes a stream of refills and answers once at the end.
    func importRefills(
        request: StreamingServerRequest<Acme_Prescriptions_V1_ImportRefillsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ImportRefillsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            var response = Acme_Prescriptions_V1_ImportRefillsResponse()
            var accepted: Int64 = 0
            for try await message in request.messages {
                response = try await processImportRefills(message)
                accepted += 1
            }
            response.accepted = accepted
            return ServerResponse(message: response)
        }
    }

    /// Lists refills a page at a time.
    func listRefillImports(
        request: ServerRequest<Acme_Prescriptions_V1_ListRefillImportsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ListRefillImportsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListRefillImports(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Maps a refill.
    func mapRefillImportColumns(
        request: ServerRequest<Acme_Prescriptions_V1_MapRefillImportColumnsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_MapRefillImportColumnsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processMapRefillImportColumns(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Retrys a refill.
    func retryRefillImport(
        request: ServerRequest<Acme_Prescriptions_V1_RetryRefillImportRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_RetryRefillImportResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRetryRefillImport(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Validates a refill.
    func validateRefillImport(
        request: ServerRequest<Acme_Prescriptions_V1_ValidateRefillImportRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ValidateRefillImportResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processValidateRefillImport(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processCancelRefillImport(_ input: Acme_Prescriptions_V1_CancelRefillImportRequest) async throws
        -> Acme_Prescriptions_V1_CancelRefillImportResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "audit", detail: input.details.newOwner.displayName
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "CancelRefillImport",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "CancelRefillImport", detail: input.context.traceID
        )
        let importFrame = Acme_Telehealth_V1_BatchCreateVideoVisitsRequest.with {
            $0.context = input.context
        }
        _ = try await self.telehealthVideoVisit.batchCreateVideoVisits { writer in
            try await writer.write(importFrame)
        }
        let outbound0 = Acme_Prescriptions_V1_ExportPrescriptionsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Prescriptions_V1_ExportPrescriptionsRequest.Filter.with {
                $0.createdAfter = input.details.effectiveAt
                $0.labels = input.annotations
                $0.ownerID = input.refillID
            }
        }
        let reply0 = try await self.prescriptionsPrescriptionQuery.exportPrescriptions(outbound0) { response in
            var latest = Acme_Prescriptions_V1_ExportPrescriptionsResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        _ = reply0
        let outbound1 = Acme_Patients_V1_ExplainPatientDecisionRequest.with {
            $0.context = input.context
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.phone = input.details.notifyContact.phone
                }
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.details.newOwner.userID
                }
            }
        }
        let port1 = RPCOperations.port { (request: Acme_Patients_V1_ExplainPatientDecisionRequest) in
            try await self.patientsPatientValidation.explainPatientDecision(request)
        }
        let reply1 = try await port1.execute(outbound1)
        return Acme_Prescriptions_V1_CancelRefillImportResponse.with {
            $0.outcome = Acme_Prescriptions_V1_CancelRefillImportResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
            }
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.refillID = input.refillID
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.phone = reply1.patient.contact.phone
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply1.outcome.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processGetRefillImportStatus(_ input: Acme_Prescriptions_V1_GetRefillImportStatusRequest) async throws
        -> Acme_Prescriptions_V1_GetRefillImportStatusResponse
    {
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "GetRefillImportStatus",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "GetRefillImportStatus", detail: input.context.traceID
        )
        return Acme_Prescriptions_V1_GetRefillImportStatusResponse.with {
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.refillID = input.refillID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processImportRefills(_ input: Acme_Prescriptions_V1_ImportRefillsRequest) async throws
        -> Acme_Prescriptions_V1_ImportRefillsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.header.format)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "audit", detail: input.header.format
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ImportRefills",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "ImportRefills", detail: input.context.traceID
        )
        let selection0_1: String
        switch input.chunk {
        case .record(let record):
            selection0_1 = record.assignee.userID
        default: selection0_1 = .init()
        }
        let outbound0 = Acme_Careplans_V1_RejectCareGoalRequest.with {
            $0.context = input.context
            $0.details = Acme_Careplans_V1_RejectCareGoalRequest.Details.with {
                $0.approver = Acme_Identity_V1_UserRef.with {
                    $0.userID = selection0_1
                }
            }
        }
        let reply0 = try await self.careplansCareGoalApproval.rejectCareGoal(outbound0)
        let selection1_1: String
        switch input.chunk {
        case .header(let header):
            selection1_1 = header.submittedBy.email
        default: selection1_1 = .init()
        }
        let selection1_2: String
        switch reply0.careGoal.origin {
        case .customer(let customer):
            selection1_2 = customer.displayName
        default: selection1_2 = .init()
        }
        let outbound1 = Acme_Patients_V1_EstimatePatientRequest.with {
            $0.context = input.context
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply0.careGoal.requester.email
                }
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.displayName = selection1_2
                    $0.email = selection1_1
                }
            }
        }
        let reply1 = try await self.patientsPatientCalculation.estimatePatient(outbound1)
        return Acme_Prescriptions_V1_ImportRefillsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply1.result.details
                $0.referenceIds = reply0.result.referenceIds + reply1.result.referenceIds
                $0.status = reply0.outcome.status
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processListRefillImports(_ input: Acme_Prescriptions_V1_ListRefillImportsRequest) async throws
        -> Acme_Prescriptions_V1_ListRefillImportsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "audit", detail: input.filter.ownerID
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ListRefillImports",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "ListRefillImports", detail: input.context.traceID
        )
        let outbound0 = Acme_Ledger_V1_ScoreLedgerAccountRequest.with {
            $0.context = input.context
            $0.details = Acme_Ledger_V1_ScoreLedgerAccountRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
            }
            $0.ledgerAccount = Acme_Ledger_V1_LedgerAccount.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.context.actor.email
                }
                $0.labels = input.filter.labels
            }
        }
        let reply0 = try await self.listRefillImportsStep0(outbound0)
        return Acme_Prescriptions_V1_ListRefillImportsResponse.with {
            $0.refills = [
                Acme_Prescriptions_V1_Refill.with {
                    $0.assignee = Acme_Identity_V1_UserRef.with {
                        $0.email = reply0.ledgerAccount.contact.email
                    }
                }
            ]
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processMapRefillImportColumns(_ input: Acme_Prescriptions_V1_MapRefillImportColumnsRequest) async throws
        -> Acme_Prescriptions_V1_MapRefillImportColumnsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "audit", detail: input.details.contact.email
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "MapRefillImportColumns",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try RefillRecord(input.refill, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Documents_V1_SuggestDocumentsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Documents_V1_SuggestDocumentsRequest.Filter.with {
                $0.createdAfter = input.refill.audit.createdAt
                $0.labels = input.refill.customFields
                $0.ownerID = input.refill.refillID
            }
        }
        guard
            let execute0 = self.mapRefillImportColumnsStep0[settings.region]
                ?? self.mapRefillImportColumnsStep0["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply0 = try await execute0(outbound0)
        let outbound1 = Acme_Telehealth_V1_StartVideoVisitWorkflowRequest.with {
            $0.context = input.context
            $0.details = Acme_Telehealth_V1_StartVideoVisitWorkflowRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.preferredChannel = input.details.contact.preferredChannel
                }
            }
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.refill.assignee.userID
                }
                $0.participants = [
                    Acme_Telehealth_V1_VideoVisitParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.name = input.refill.requester.name
                            $0.phone = input.details.contact.phone
                        }
                    }
                ]
            }
        }
        let reply1 = try await self.telehealthVideoVisitWorkflow.startVideoVisitWorkflow(outbound1)
        let outbound2 = Acme_Patients_V1_SearchPatientsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Patients_V1_SearchPatientsRequest.Filter.with {
                $0.region = reply1.videoVisit.location.region
            }
        }
        let envelope2 = try Google_Protobuf_Any(message: outbound2)
        let unpacked2 = try Acme_Patients_V1_SearchPatientsRequest(unpackingAny: envelope2)
        let reply2 = try await self.patientsPatient.searchPatients(unpacked2)
        let outbound3 = Acme_Patients_V1_ExplainPatientCalculationRequest.with {
            $0.context = input.context
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.name = input.details.contact.name
                    $0.phone = input.details.contact.phone
                    $0.preferredChannel = input.refill.requester.preferredChannel
                }
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.email = reply1.videoVisit.organizer.email
                }
            }
        }
        let json3 = try outbound3.jsonString()
        let decoded3 = try Acme_Patients_V1_ExplainPatientCalculationRequest(jsonString: json3)
        let reply3 = try await self.patientsPatientCalculation.explainPatientCalculation(decoded3)
        return Acme_Prescriptions_V1_MapRefillImportColumnsResponse.with {
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply1.videoVisit.audit.etag
                }
                $0.refillID = input.refillID
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply3.patient.relationshipManager.email
                }
                $0.subject = input.refill.subject
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply2.result.details
                $0.message = reply1.result.message
                $0.status = reply0.result.status
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processRetryRefillImport(_ input: Acme_Prescriptions_V1_RetryRefillImportRequest) async throws
        -> Acme_Prescriptions_V1_RetryRefillImportResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "audit", detail: input.details.initiatedBy
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "RetryRefillImport",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try RefillRecord(input.refill, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Authorization_V1_BatchCreateAccessPoliciesRequest.with {
            $0.context = input.context
            $0.record = Acme_Authorization_V1_AccessPolicy.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = input.refill.audit.createdBy
                    $0.updatedBy = input.refill.audit.updatedBy
                }
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.email = input.refill.assignee.email
                    $0.userID = input.refill.assignee.userID
                }
            }
        }
        let reply0 = try await self.authorizationAccessPolicy.batchCreateAccessPolicies { writer in
            try await writer.write(outbound0)
        }
        _ = reply0
        let selection1_2: String
        switch input.refill.origin {
        case .customer(let customer):
            selection1_2 = customer.displayName
        default: selection1_2 = .init()
        }
        let outbound1 = Acme_Prescriptions_V1_ScoreRefillRequest.with {
            $0.context = input.context
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.customer = Acme_Prescriptions_V1_PrescriptionRef.with {
                    $0.displayName = selection1_2
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.name = input.refill.requester.name
                }
            }
        }
        let reply1 = try await self.prescriptionsRefillValidation.scoreRefill(outbound1)
        let requests2 = input.refill.comments.map { element in
            Acme_Patients_V1_QuotePatientRequest.with {
                $0.context = input.context
                $0.patient = Acme_Patients_V1_Patient.with {
                    $0.audit = Acme_Common_V1_AuditInfo.with {
                        $0.createdAt = element.createdAt
                    }
                    $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                        $0.email = element.authorEmail
                    }
                }
            }
        }
        let replies2 = try await FanOut.map(requests2) { candidate in
            try await self.patientsPatientCalculation.quotePatient(candidate)
        }
        let reply2 = replies2.first ?? Acme_Patients_V1_QuotePatientResponse()
        _ = reply2
        return Acme_Prescriptions_V1_RetryRefillImportResponse.with {
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.assignee = reply1.refill.assignee
                $0.refillID = input.refillID
                $0.status = input.refill.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processValidateRefillImport(_ input: Acme_Prescriptions_V1_ValidateRefillImportRequest) async throws
        -> Acme_Prescriptions_V1_ValidateRefillImportResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.phone)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "audit", detail: input.details.contact.phone
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ValidateRefillImport",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try RefillRecord(input.refill, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let selection0_1: String
        switch input.refill.origin {
        case .customer(let customer):
            selection0_1 = customer.displayName
        default: selection0_1 = .init()
        }
        let outbound0 = Acme_Venues_V1_ExplainVenueDecisionRequest.with {
            $0.context = input.context
            $0.venue = Acme_Venues_V1_Venue.with {
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.displayName = selection0_1
                    $0.email = input.details.contact.email
                }
            }
        }
        let reply0 = try await self.venuesVenueValidation.explainVenueDecision(outbound0)
        let selection1_1: String
        switch reply0.venue.locator {
        case .address(let address):
            selection1_1 = address.postalCode
        default: selection1_1 = .init()
        }
        let outbound1 = Acme_Prescriptions_V1_CreatePrescriptionRequest.with {
            $0.context = input.context
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = selection1_1
                }
                $0.lines = [
                    Acme_Prescriptions_V1_PrescriptionLine.with {
                        $0.description_p = reply0.venue.components["primary", default: .init()].description_p
                    }
                ]
            }
        }
        let reply1 = try await self.prescriptionsPrescription.createPrescription(outbound1)
        return Acme_Prescriptions_V1_ValidateRefillImportResponse.with {
            $0.outcome = Acme_Prescriptions_V1_ValidateRefillImportResponse.Outcome.with {
                $0.status = reply0.outcome.status
            }
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.assignee = input.refill.assignee
                $0.comments = [
                    Acme_Prescriptions_V1_RefillComment.with {
                        $0.createdAt = reply1.prescription.audit.createdAt
                    }
                ]
                $0.refillID = input.refillID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }
}
