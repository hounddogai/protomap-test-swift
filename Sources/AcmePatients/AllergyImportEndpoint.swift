import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Takes allergies in bulk from partners and legacy systems.
final class AllergyImportEndpoint: Acme_Patients_V1_AllergyImportService.ServiceProtocol {
    private let store: any RecordRepository
    private let logger: Logger
    private let settings: Settings
    private let careplansCareGoalApproval: Acme_Careplans_V1_CareGoalApprovalService.Client<MeshTransport>
    private let careplansCareGoalWorkflow: Acme_Careplans_V1_CareGoalWorkflowService.Client<MeshTransport>
    private let careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>
    private let driversDriver: Acme_Drivers_V1_DriverService.Client<MeshTransport>
    private let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    private let notificationsNotificationValidation:
        Acme_Notifications_V1_NotificationValidationService.Client<MeshTransport>
    private let patientsAllergyCalculation: Acme_Patients_V1_AllergyCalculationService.Client<MeshTransport>
    private let patientsAllergyValidation: Acme_Patients_V1_AllergyValidationService.Client<MeshTransport>
    private let patientsPatient: Acme_Patients_V1_PatientService.Client<MeshTransport>
    private let patientsPatientCalculation: Acme_Patients_V1_PatientCalculationService.Client<MeshTransport>
    private let patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client<MeshTransport>
    private let prescriptionsMedicationApproval: Acme_Prescriptions_V1_MedicationApprovalService.Client<MeshTransport>
    private let prescriptionsRefillWorkflow: Acme_Prescriptions_V1_RefillWorkflowService.Client<MeshTransport>
    private let sponsorshipsSponsorQuery: Acme_Sponsorships_V1_SponsorQueryService.Client<MeshTransport>
    private let ticketingTicket: Acme_Ticketing_V1_TicketService.Client<MeshTransport>
    private let getAllergyImportStatusStep0:
        any RPCPort<Acme_Patients_V1_CalculatePatientRequest, Acme_Patients_V1_CalculatePatientResponse>
    private let mapAllergyImportColumnsStep0:
        @Sendable (Acme_Patients_V1_SummarizePatientsRequest) async throws -> Acme_Patients_V1_SummarizePatientsResponse
    private let mapAllergyImportColumnsStep1:
        [String:
            @Sendable (Acme_Patients_V1_SimulateAllergyRequest) async throws -> Acme_Patients_V1_SimulateAllergyResponse]

    init(
        dependencies: any Dependencies,
        careplansCareGoalApproval: Acme_Careplans_V1_CareGoalApprovalService.Client<MeshTransport>,
        careplansCareGoalWorkflow: Acme_Careplans_V1_CareGoalWorkflowService.Client<MeshTransport>,
        careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>,
        driversDriver: Acme_Drivers_V1_DriverService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        notificationsNotificationValidation: Acme_Notifications_V1_NotificationValidationService.Client<MeshTransport>,
        patientsAllergyCalculation: Acme_Patients_V1_AllergyCalculationService.Client<MeshTransport>,
        patientsAllergyValidation: Acme_Patients_V1_AllergyValidationService.Client<MeshTransport>,
        patientsPatient: Acme_Patients_V1_PatientService.Client<MeshTransport>,
        patientsPatientCalculation: Acme_Patients_V1_PatientCalculationService.Client<MeshTransport>,
        patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client<MeshTransport>,
        prescriptionsMedicationApproval: Acme_Prescriptions_V1_MedicationApprovalService.Client<MeshTransport>,
        prescriptionsRefillWorkflow: Acme_Prescriptions_V1_RefillWorkflowService.Client<MeshTransport>,
        sponsorshipsSponsorQuery: Acme_Sponsorships_V1_SponsorQueryService.Client<MeshTransport>,
        ticketingTicket: Acme_Ticketing_V1_TicketService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.careplansCareGoalApproval = careplansCareGoalApproval
        self.careplansCareGoalWorkflow = careplansCareGoalWorkflow
        self.careplansCarePlan = careplansCarePlan
        self.driversDriver = driversDriver
        self.identityUser = identityUser
        self.notificationsNotificationValidation = notificationsNotificationValidation
        self.patientsAllergyCalculation = patientsAllergyCalculation
        self.patientsAllergyValidation = patientsAllergyValidation
        self.patientsPatient = patientsPatient
        self.patientsPatientCalculation = patientsPatientCalculation
        self.patientsPatientQuery = patientsPatientQuery
        self.prescriptionsMedicationApproval = prescriptionsMedicationApproval
        self.prescriptionsRefillWorkflow = prescriptionsRefillWorkflow
        self.sponsorshipsSponsorQuery = sponsorshipsSponsorQuery
        self.ticketingTicket = ticketingTicket
        self.getAllergyImportStatusStep0 = ClosurePort<
            Acme_Patients_V1_CalculatePatientRequest, Acme_Patients_V1_CalculatePatientResponse
        >({ request in try await patientsPatientCalculation.calculatePatient(request) })
        self.mapAllergyImportColumnsStep0 = { request in try await patientsPatientQuery.summarizePatients(request) }
        self.mapAllergyImportColumnsStep1 = [
            "primary": { request in try await patientsAllergyCalculation.simulateAllergy(request) }
        ]
    }

    /// Cancels an allergy.
    func cancelAllergyImport(
        request: ServerRequest<Acme_Patients_V1_CancelAllergyImportRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_CancelAllergyImportResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCancelAllergyImport(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns an allergy.
    func getAllergyImportStatus(
        request: ServerRequest<Acme_Patients_V1_GetAllergyImportStatusRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_GetAllergyImportStatusResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetAllergyImportStatus(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Takes a stream of allergies and answers once at the end.
    func importAllergies(
        request: StreamingServerRequest<Acme_Patients_V1_ImportAllergiesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_ImportAllergiesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            var response = Acme_Patients_V1_ImportAllergiesResponse()
            var accepted: Int64 = 0
            for try await message in request.messages {
                response = try await processImportAllergies(message)
                accepted += 1
            }
            response.accepted = accepted
            return ServerResponse(message: response)
        }
    }

    /// Lists allergies a page at a time.
    func listAllergyImports(
        request: ServerRequest<Acme_Patients_V1_ListAllergyImportsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_ListAllergyImportsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListAllergyImports(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Maps an allergy.
    func mapAllergyImportColumns(
        request: ServerRequest<Acme_Patients_V1_MapAllergyImportColumnsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_MapAllergyImportColumnsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processMapAllergyImportColumns(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Retrys an allergy.
    func retryAllergyImport(
        request: ServerRequest<Acme_Patients_V1_RetryAllergyImportRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_RetryAllergyImportResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRetryAllergyImport(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Validates an allergy.
    func validateAllergyImport(
        request: ServerRequest<Acme_Patients_V1_ValidateAllergyImportRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_ValidateAllergyImportResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processValidateAllergyImport(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processCancelAllergyImport(_ input: Acme_Patients_V1_CancelAllergyImportRequest) async throws
        -> Acme_Patients_V1_CancelAllergyImportResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "audit", detail: input.details.newOwner.displayName
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "CancelAllergyImport",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "CancelAllergyImport", detail: input.context.traceID
        )
        let importFrame = Acme_Careplans_V1_BatchCreateCarePlansRequest.with {
            $0.context = input.context
        }
        _ = try await self.careplansCarePlan.batchCreateCarePlans { writer in
            try await writer.write(importFrame)
        }
        let outbound0 = Acme_Ticketing_V1_BatchGetTicketsRequest.with {
            $0.context = input.context
        }
        let reply0 = try await RPCOperations.read {
            try await self.ticketingTicket.batchGetTickets(outbound0)
        }
        let outbound1 = Acme_Patients_V1_UpdatePatientRequest.with {
            $0.context = input.context
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.preferredChannel = input.details.notifyContact.preferredChannel
                }
            }
        }
        let reply1 = try await self.patientsPatient.updatePatient(outbound1)
        let outbound2 = Acme_Patients_V1_QuoteAllergyRequest.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.email = reply1.patient.contact.email
                }
            }
            $0.context = input.context
            $0.details = Acme_Patients_V1_QuoteAllergyRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.lines = reply1.patient.primaryAddress.lines
                }
            }
        }
        async let remote2 = self.patientsAllergyCalculation.quoteAllergy(outbound2)
        async let persisted2 = store.count(tenant: input.context.tenantID)
        let (reply2, count2) = try await (remote2, persisted2)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count2)])
        return Acme_Patients_V1_CancelAllergyImportResponse.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.allergyID = input.allergyID
                $0.correlationID = reply1.result.correlationID
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.patientID = reply1.patient.patientID
                }
            }
            $0.outcome = Acme_Patients_V1_CancelAllergyImportResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
                $0.message = reply0.result.message
                $0.status = reply0.result.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply2.result.details
                $0.message = reply2.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processGetAllergyImportStatus(_ input: Acme_Patients_V1_GetAllergyImportStatusRequest) async throws
        -> Acme_Patients_V1_GetAllergyImportStatusResponse
    {
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "GetAllergyImportStatus",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "GetAllergyImportStatus", detail: input.context.traceID
        )
        let outbound0 = Acme_Patients_V1_CalculatePatientRequest.with {
            $0.context = input.context
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.context.actor.email
                }
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.context.actor.userID
                }
            }
        }
        let reply0 = try await self.getAllergyImportStatusStep0.execute(outbound0)
        return Acme_Patients_V1_GetAllergyImportStatusResponse.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.allergyID = input.allergyID
                $0.correlationID = reply0.result.correlationID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processImportAllergies(_ input: Acme_Patients_V1_ImportAllergiesRequest) async throws
        -> Acme_Patients_V1_ImportAllergiesResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.header.format)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "audit", detail: input.header.format
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ImportAllergies",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "ImportAllergies", detail: input.context.traceID
        )
        let outbound0 = Acme_Patients_V1_ResolvePatientsRequest.with {
            $0.context = input.context
        }
        let port0 = RPCOperations.port { (request: Acme_Patients_V1_ResolvePatientsRequest) in
            try await self.patientsPatientQuery.resolvePatients(request)
        }
        let reply0 = try await port0.execute(outbound0)
        let selection1_1: Google_Protobuf_Timestamp
        switch input.chunk {
        case .record(let record):
            selection1_1 = record.occurredAt
        default: selection1_1 = .init()
        }
        let selection1_2: String
        switch input.chunk {
        case .record(let record):
            selection1_2 = record.subject.patientID
        default: selection1_2 = .init()
        }
        let selection1_3: [String: String]
        switch input.chunk {
        case .record(let record):
            selection1_3 = record.attributes
        default: selection1_3 = .init()
        }
        let outbound1 = Acme_Careplans_V1_ListPendingCareGoalsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Careplans_V1_ListPendingCareGoalsRequest.Filter.with {
                $0.createdAfter = selection1_1
                $0.labels = selection1_3
                $0.ownerID = selection1_2
            }
        }
        let reply1 = try await self.careplansCareGoalApproval.listPendingCareGoals(outbound1)
        return Acme_Patients_V1_ImportAllergiesResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.status = Projection.firstValue(
                    [
                        reply0.result.status,
                        reply1.result.status,
                    ], default: .init())
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processListAllergyImports(_ input: Acme_Patients_V1_ListAllergyImportsRequest) async throws
        -> Acme_Patients_V1_ListAllergyImportsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "audit", detail: input.filter.ownerID
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ListAllergyImports",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "ListAllergyImports", detail: input.context.traceID
        )
        let outbound0 = Acme_Sponsorships_V1_ExportSponsorsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Sponsorships_V1_ExportSponsorsRequest.Filter.with {
                $0.labels = input.filter.labels
            }
        }
        let reply0 = try await self.sponsorshipsSponsorQuery.exportSponsors(outbound0) { response in
            var latest = Acme_Sponsorships_V1_ExportSponsorsResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        _ = reply0
        return Acme_Patients_V1_ListAllergyImportsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processMapAllergyImportColumns(_ input: Acme_Patients_V1_MapAllergyImportColumnsRequest) async throws
        -> Acme_Patients_V1_MapAllergyImportColumnsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.allergy.correlationID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "audit", detail: input.allergy.correlationID
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "MapAllergyImportColumns",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try AllergyRecord(input.allergy, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Patients_V1_SummarizePatientsRequest.with {
            $0.annotations = input.annotations
            $0.context = input.context
            $0.patientID = input.allergy.subject.patientID
            $0.reason = input.reason
        }
        let reply0 = try await self.mapAllergyImportColumnsStep0(outbound0)
        let outbound1 = Acme_Patients_V1_SimulateAllergyRequest.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.allergyID = input.allergy.allergyID
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = input.allergy.subject.displayName
                    $0.email = input.allergy.subject.email
                    $0.patientID = input.allergy.subject.patientID
                }
            }
            $0.context = input.context
        }
        guard
            let execute1 = self.mapAllergyImportColumnsStep1[settings.region]
                ?? self.mapAllergyImportColumnsStep1["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply1 = try await execute1(outbound1)
        let outbound2 = Acme_Notifications_V1_ValidateNotificationRequest.with {
            $0.context = input.context
            $0.notification = Acme_Notifications_V1_Notification.with {
                $0.customer = Acme_Notifications_V1_NotificationTemplateRef.with {
                    $0.displayName = input.allergy.subject.displayName
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply1.allergy.subject.email
                }
            }
        }
        let reply2 = try await self.notificationsNotificationValidation.validateNotification(outbound2)
        let outbound3 = Acme_Patients_V1_PreviewAllergyRequest.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.patientID = input.allergy.subject.patientID
                }
            }
            $0.context = input.context
            $0.details = Acme_Patients_V1_PreviewAllergyRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply2.notification.requester.email
                }
            }
        }
        let envelope3 = try Google_Protobuf_Any(message: outbound3)
        let unpacked3 = try Acme_Patients_V1_PreviewAllergyRequest(unpackingAny: envelope3)
        let reply3 = try await self.patientsAllergyValidation.previewAllergy(unpacked3)
        return Acme_Patients_V1_MapAllergyImportColumnsResponse.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.allergyID = input.allergyID
                $0.correlationID = reply1.allergy.correlationID
                $0.occurredAt = input.allergy.occurredAt
            }
            $0.outcome = Acme_Patients_V1_MapAllergyImportColumnsResponse.Outcome.with {
                $0.message = reply3.outcome.message
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.details = reply2.result.details
                $0.status = reply0.result.status
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processRetryAllergyImport(_ input: Acme_Patients_V1_RetryAllergyImportRequest) async throws
        -> Acme_Patients_V1_RetryAllergyImportResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.allergy.allergyID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "audit", detail: input.allergy.allergyID
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "RetryAllergyImport",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try AllergyRecord(input.allergy, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Prescriptions_V1_RejectMedicationRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_RejectMedicationRequest.Details.with {
                $0.approver = Acme_Identity_V1_UserRef.with {
                    $0.email = input.details.notify.email
                }
            }
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.email = input.allergy.subject.email
                }
            }
        }
        let json0 = try outbound0.jsonString()
        let decoded0 = try Acme_Prescriptions_V1_RejectMedicationRequest(jsonString: json0)
        let reply0 = try await self.prescriptionsMedicationApproval.rejectMedication(decoded0)
        let selection1_1: String
        switch reply0.medication.locator {
        case .address(let address):
            selection1_1 = address.region
        default: selection1_1 = .init()
        }
        let outbound1 = Acme_Prescriptions_V1_ListRefillWorkflowsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Prescriptions_V1_ListRefillWorkflowsRequest.Filter.with {
                $0.region = selection1_1
            }
        }
        let reply1 = try await self.prescriptionsRefillWorkflow.listRefillWorkflows(outbound1)
        return Acme_Patients_V1_RetryAllergyImportResponse.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.allergyID = input.allergyID
                $0.correlationID = reply1.result.correlationID
                $0.kind = input.allergy.kind
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = reply0.medication.owner.displayName
                }
            }
            $0.outcome = Acme_Patients_V1_RetryAllergyImportResponse.Outcome.with {
                $0.status = reply0.outcome.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processValidateAllergyImport(_ input: Acme_Patients_V1_ValidateAllergyImportRequest) async throws
        -> Acme_Patients_V1_ValidateAllergyImportResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.allergy.allergyID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "audit", detail: input.allergy.allergyID
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ValidateAllergyImport",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try AllergyRecord(input.allergy, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Careplans_V1_ListCareGoalWorkflowsRequest.forAllergyImportEndpointValidateAllergyImport0(
            input
        )
        let reply0 = try await self.careplansCareGoalWorkflow.listCareGoalWorkflows(outbound0)
        let outbound1 = Acme_Drivers_V1_CloneDriverRequest.with {
            $0.context = input.context
            $0.driver = Acme_Drivers_V1_Driver.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.allergy.subject.email
                    $0.phone = input.details.contact.phone
                }
                $0.name = input.details.contact.name
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.email = input.details.contact.email
                }
            }
        }
        let reply1 = try await self.driversDriver.cloneDriver(
            outbound1, metadata: ["x-acme-region": .string(settings.region)]
        )
        return Acme_Patients_V1_ValidateAllergyImportResponse.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.allergyID = input.allergyID
                $0.sequence = input.allergy.sequence
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.email = reply1.driver.contact.email
                }
            }
            $0.outcome = Acme_Patients_V1_ValidateAllergyImportResponse.Outcome.with {
                $0.message = reply0.result.message
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.result.message
                $0.status = "ok"
            }
        }
    }
}
