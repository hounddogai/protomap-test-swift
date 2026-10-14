import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Computes the figures of a clinic slot, such as totals, taxes, and estimates.
final class ClinicSlotCalculationEndpoint: Acme_Appointments_V1_ClinicSlotCalculationService.ServiceProtocol {
    private let store: any RecordRepository
    private let logger: Logger
    private let settings: Settings
    private let followUps = WorkQueue<Acme_Identity_V1_GetUserRequest>()
    private let appointmentsAppointmentValidation:
        Acme_Appointments_V1_AppointmentValidationService.Client<MeshTransport>
    private let broadcastsBroadcast: Acme_Broadcasts_V1_BroadcastService.Client<MeshTransport>
    private let careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>
    private let careplansCareGoalValidation: Acme_Careplans_V1_CareGoalValidationService.Client<MeshTransport>
    private let careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>
    private let concessionsConcessionStandCalculation:
        Acme_Concessions_V1_ConcessionStandCalculationService.Client<MeshTransport>
    private let documentsDocumentQuery: Acme_Documents_V1_DocumentQueryService.Client<MeshTransport>
    private let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    private let prescriptionsMedicationValidation:
        Acme_Prescriptions_V1_MedicationValidationService.Client<MeshTransport>
    private let telehealthVisitNoteValidation: Acme_Telehealth_V1_VisitNoteValidationService.Client<MeshTransport>
    private let explainClinicSlotCalculationStep0:
        any RPCPort<Acme_Appointments_V1_ValidateAppointmentRequest, Acme_Appointments_V1_ValidateAppointmentResponse>
    private let recalculateClinicSlotsStep1:
        @Sendable (Acme_Telehealth_V1_PreviewVisitNoteRequest) async throws ->
            Acme_Telehealth_V1_PreviewVisitNoteResponse
    private let recalculateClinicSlotsStep2:
        [String:
            @Sendable (Acme_Documents_V1_SuggestDocumentsRequest) async throws ->
            Acme_Documents_V1_SuggestDocumentsResponse]

    init(
        dependencies: any Dependencies,
        appointmentsAppointmentValidation: Acme_Appointments_V1_AppointmentValidationService.Client<MeshTransport>,
        broadcastsBroadcast: Acme_Broadcasts_V1_BroadcastService.Client<MeshTransport>,
        careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>,
        careplansCareGoalValidation: Acme_Careplans_V1_CareGoalValidationService.Client<MeshTransport>,
        careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>,
        concessionsConcessionStandCalculation: Acme_Concessions_V1_ConcessionStandCalculationService.Client<
            MeshTransport
        >,
        documentsDocumentQuery: Acme_Documents_V1_DocumentQueryService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        prescriptionsMedicationValidation: Acme_Prescriptions_V1_MedicationValidationService.Client<MeshTransport>,
        telehealthVisitNoteValidation: Acme_Telehealth_V1_VisitNoteValidationService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.appointmentsAppointmentValidation = appointmentsAppointmentValidation
        self.broadcastsBroadcast = broadcastsBroadcast
        self.careplansCareGoalCalculation = careplansCareGoalCalculation
        self.careplansCareGoalValidation = careplansCareGoalValidation
        self.careplansCarePlan = careplansCarePlan
        self.concessionsConcessionStandCalculation = concessionsConcessionStandCalculation
        self.documentsDocumentQuery = documentsDocumentQuery
        self.identityUser = identityUser
        self.prescriptionsMedicationValidation = prescriptionsMedicationValidation
        self.telehealthVisitNoteValidation = telehealthVisitNoteValidation
        self.explainClinicSlotCalculationStep0 = ClosurePort<
            Acme_Appointments_V1_ValidateAppointmentRequest, Acme_Appointments_V1_ValidateAppointmentResponse
        >({ request in try await appointmentsAppointmentValidation.validateAppointment(request) })
        self.recalculateClinicSlotsStep1 = { request in
            try await telehealthVisitNoteValidation.previewVisitNote(request)
        }
        self.recalculateClinicSlotsStep2 = [
            "primary": { request in try await documentsDocumentQuery.suggestDocuments(request) }
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

    /// Calculates a clinic slot.
    func calculateClinicSlot(
        request: ServerRequest<Acme_Appointments_V1_CalculateClinicSlotRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_CalculateClinicSlotResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCalculateClinicSlot(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Estimates a clinic slot.
    func estimateClinicSlot(
        request: ServerRequest<Acme_Appointments_V1_EstimateClinicSlotRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_EstimateClinicSlotResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processEstimateClinicSlot(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Explains a clinic slot.
    func explainClinicSlotCalculation(
        request: ServerRequest<Acme_Appointments_V1_ExplainClinicSlotCalculationRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_ExplainClinicSlotCalculationResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processExplainClinicSlotCalculation(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Quotes a clinic slot.
    func quoteClinicSlot(
        request: ServerRequest<Acme_Appointments_V1_QuoteClinicSlotRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_QuoteClinicSlotResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processQuoteClinicSlot(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Recalculates a clinic slot.
    func recalculateClinicSlots(
        request: ServerRequest<Acme_Appointments_V1_RecalculateClinicSlotsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_RecalculateClinicSlotsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRecalculateClinicSlots(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Simulates a clinic slot.
    func simulateClinicSlot(
        request: ServerRequest<Acme_Appointments_V1_SimulateClinicSlotRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_SimulateClinicSlotResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSimulateClinicSlot(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processCalculateClinicSlot(_ input: Acme_Appointments_V1_CalculateClinicSlotRequest) async throws
        -> Acme_Appointments_V1_CalculateClinicSlotResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.clinicSlot.audit.createdBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "clinic_slot",
            action: "audit", detail: input.clinicSlot.audit.createdBy
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "CalculateClinicSlot",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try ClinicSlotRecord(input.clinicSlot, tenant: input.context.tenantID)
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
        let selection0_1: [String]
        switch input.clinicSlot.recurrence {
        case .weekly(let weekly):
            selection0_1 = weekly.days
        default: selection0_1 = .init()
        }
        let outbound0 = Acme_Appointments_V1_ExplainAppointmentDecisionRequest.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.clinicSlot.organizer.userID
                }
                $0.weekly = Acme_Appointments_V1_AppointmentWeeklyRule.with {
                    $0.days = selection0_1
                }
            }
            $0.context = input.context
        }
        let reply0 = try await self.appointmentsAppointmentValidation.explainAppointmentDecision(outbound0)
        let outbound1 = Acme_Prescriptions_V1_PreviewMedicationRequest.with {
            $0.context = input.context
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.address = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = input.clinicSlot.location.countryCode
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply0.appointment.audit.createdBy
                }
            }
        }
        let step1: @Sendable () async throws -> Acme_Prescriptions_V1_PreviewMedicationResponse = {
            try await self.prescriptionsMedicationValidation.previewMedication(outbound1)
        }
        let reply1 = try await step1()
        let outbound2 = Acme_Appointments_V1_ScoreAppointmentRequest.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.participants = [
                    Acme_Appointments_V1_AppointmentParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = reply0.appointment.organizer.email
                        }
                    }
                ]
            }
            $0.context = input.context
        }
        let reply2 = try await self.appointmentsAppointmentValidation.scoreAppointment(outbound2)
        let requests3 = input.clinicSlot.participants.map { element in
            Acme_Careplans_V1_RecalculateCareGoalsRequest.with {
                $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                    $0.assignee = Acme_Identity_V1_UserRef.with {
                        $0.email = element.contact.email
                    }
                    $0.requester = Acme_Common_V1_ContactInfo.with {
                        $0.name = element.contact.name
                        $0.phone = element.contact.phone
                    }
                }
                $0.context = input.context
            }
        }
        let replies3 = try await FanOut.map(requests3) { candidate in
            try await self.careplansCareGoalCalculation.recalculateCareGoals(candidate)
        }
        let reply3 = replies3.first ?? Acme_Careplans_V1_RecalculateCareGoalsResponse()
        _ = reply3
        return Acme_Appointments_V1_CalculateClinicSlotResponse.with {
            $0.clinicSlot = Acme_Appointments_V1_ClinicSlot.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply1.medication.audit.etag
                }
                $0.clinicSlotID = input.clinicSlotID
                $0.location = reply2.appointment.location
                $0.organizer = reply0.appointment.organizer
                $0.participants = [
                    Acme_Appointments_V1_ClinicSlotParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = reply2.appointment.organizer.email
                        }
                    }
                ]
                $0.window = input.clinicSlot.window
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processEstimateClinicSlot(_ input: Acme_Appointments_V1_EstimateClinicSlotRequest) async throws
        -> Acme_Appointments_V1_EstimateClinicSlotResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.clinicSlot.audit.etag)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "clinic_slot",
            action: "audit", detail: input.clinicSlot.audit.etag
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "EstimateClinicSlot",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try ClinicSlotRecord(input.clinicSlot, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Concessions_V1_ExplainConcessionStandCalculationRequest.with {
            $0.concessionStand = Acme_Concessions_V1_ConcessionStand.with {
                $0.address = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.clinicSlot.location.region
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = input.clinicSlot.audit.createdBy
                }
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.clinicSlot.organizer.userID
                }
            }
            $0.context = input.context
        }
        async let remote0 = self.concessionsConcessionStandCalculation.explainConcessionStandCalculation(outbound0)
        async let persisted0 = store.count(tenant: input.context.tenantID)
        let (reply0, count0) = try await (remote0, persisted0)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count0)])
        return Acme_Appointments_V1_EstimateClinicSlotResponse.with {
            $0.breakdown = Acme_Appointments_V1_EstimateClinicSlotResponse.Breakdown.with {
                $0.currencyCode = input.details.currencyCode
            }
            $0.clinicSlot = Acme_Appointments_V1_ClinicSlot.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply0.concessionStand.audit.createdBy
                }
                $0.clinicSlotID = input.clinicSlotID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processExplainClinicSlotCalculation(_ input: Acme_Appointments_V1_ExplainClinicSlotCalculationRequest)
        async throws -> Acme_Appointments_V1_ExplainClinicSlotCalculationResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.clinicSlot.audit.createdBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "clinic_slot",
            action: "audit", detail: input.clinicSlot.audit.createdBy
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ExplainClinicSlotCalculation",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try ClinicSlotRecord(input.clinicSlot, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Appointments_V1_ValidateAppointmentRequest.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.participants = [
                    Acme_Appointments_V1_AppointmentParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.phone = input.details.contact.phone
                        }
                    }
                ]
            }
            $0.context = input.context
        }
        let reply0 = try await self.explainClinicSlotCalculationStep0.execute(outbound0)
        return Acme_Appointments_V1_ExplainClinicSlotCalculationResponse.with {
            $0.clinicSlot = Acme_Appointments_V1_ClinicSlot.with {
                $0.clinicSlotID = input.clinicSlotID
                $0.status = input.clinicSlot.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processQuoteClinicSlot(_ input: Acme_Appointments_V1_QuoteClinicSlotRequest) async throws
        -> Acme_Appointments_V1_QuoteClinicSlotResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.clinicSlot.audit.createdBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "clinic_slot",
            action: "audit", detail: input.clinicSlot.audit.createdBy
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "QuoteClinicSlot",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try ClinicSlotRecord(input.clinicSlot, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Appointments_V1_PreviewAppointmentRequest.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = input.details.destination.countryCode
                }
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.clinicSlot.organizer.userID
                }
            }
            $0.context = input.context
        }
        let port0 = RPCOperations.port { (request: Acme_Appointments_V1_PreviewAppointmentRequest) in
            try await self.appointmentsAppointmentValidation.previewAppointment(request)
        }
        let reply0 = try await port0.execute(outbound0)
        return Acme_Appointments_V1_QuoteClinicSlotResponse.with {
            $0.breakdown = Acme_Appointments_V1_QuoteClinicSlotResponse.Breakdown.with {
                $0.currencyCode = input.details.currencyCode
            }
            $0.clinicSlot = Acme_Appointments_V1_ClinicSlot.with {
                $0.clinicSlotID = input.clinicSlotID
                $0.organizer = reply0.appointment.organizer
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processRecalculateClinicSlots(_ input: Acme_Appointments_V1_RecalculateClinicSlotsRequest) async throws
        -> Acme_Appointments_V1_RecalculateClinicSlotsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.clinicSlot.audit.updatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "clinic_slot",
            action: "audit", detail: input.clinicSlot.audit.updatedBy
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "RecalculateClinicSlots",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try ClinicSlotRecord(input.clinicSlot, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let selection0_1: Int32
        switch input.clinicSlot.recurrence {
        case .daily(let daily):
            selection0_1 = daily.atHour
        default: selection0_1 = .init()
        }
        let outbound0 = Acme_Appointments_V1_LintAppointmentsRequest.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = input.clinicSlot.audit.createdBy
                }
                $0.daily = Acme_Appointments_V1_AppointmentDailyRule.with {
                    $0.atHour = selection0_1
                }
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = input.clinicSlot.location.countryCode
                    $0.recipient = input.details.destination.recipient
                }
            }
            $0.context = input.context
        }
        let reply0 = try await self.appointmentsAppointmentValidation.lintAppointments(outbound0)
        let outbound1 = Acme_Telehealth_V1_PreviewVisitNoteRequest.with {
            $0.context = input.context
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = input.clinicSlot.audit.etag
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.recipient = input.clinicSlot.location.recipient
                    $0.region = reply0.appointment.location.region
                }
            }
        }
        let reply1 = try await self.recalculateClinicSlotsStep1(outbound1)
        let outbound2 = Acme_Documents_V1_SuggestDocumentsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Documents_V1_SuggestDocumentsRequest.Filter.with {
                $0.createdAfter = reply1.visitNote.audit.createdAt
                $0.ownerID = input.clinicSlot.organizer.userID
                $0.region = reply0.appointment.location.region
            }
        }
        guard
            let execute2 = self.recalculateClinicSlotsStep2[settings.region]
                ?? self.recalculateClinicSlotsStep2["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply2 = try await execute2(outbound2)
        let outbound3 = Acme_Appointments_V1_ScoreAppointmentRequest.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.clinicSlot.organizer.displayName
                }
                $0.participants = [
                    Acme_Appointments_V1_AppointmentParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = reply0.appointment.organizer.email
                        }
                    }
                ]
            }
            $0.context = input.context
            $0.details = Acme_Appointments_V1_ScoreAppointmentRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.recipient = input.details.destination.recipient
                }
            }
        }
        let reply3 = try await self.appointmentsAppointmentValidation.scoreAppointment(outbound3)
        return Acme_Appointments_V1_RecalculateClinicSlotsResponse.with {
            $0.breakdown = Acme_Appointments_V1_RecalculateClinicSlotsResponse.Breakdown.with {
                $0.currencyCode = reply3.breakdown.currencyCode
            }
            $0.clinicSlot = Acme_Appointments_V1_ClinicSlot.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply1.visitNote.audit.createdBy
                    $0.updatedBy = reply0.appointment.audit.updatedBy
                }
                $0.clinicSlotID = input.clinicSlotID
                $0.window = input.clinicSlot.window
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply2.result.correlationID
                $0.status = reply1.result.status
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processSimulateClinicSlot(_ input: Acme_Appointments_V1_SimulateClinicSlotRequest) async throws
        -> Acme_Appointments_V1_SimulateClinicSlotResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.clinicSlot.audit.etag)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "clinic_slot",
            action: "audit", detail: input.clinicSlot.audit.etag
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "SimulateClinicSlot",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try ClinicSlotRecord(input.clinicSlot, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Telehealth_V1_ValidateVisitNoteRequest.with {
            $0.context = input.context
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = input.clinicSlot.audit.createdBy
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.locality = input.clinicSlot.location.locality
                    $0.postalCode = input.clinicSlot.location.postalCode
                    $0.region = input.clinicSlot.location.region
                }
            }
        }
        let envelope0 = try Google_Protobuf_Any(message: outbound0)
        let unpacked0 = try Acme_Telehealth_V1_ValidateVisitNoteRequest(unpackingAny: envelope0)
        let reply0 = try await self.telehealthVisitNoteValidation.validateVisitNote(unpacked0)
        let outbound1 = Acme_Appointments_V1_CheckAppointmentEligibilityRequest.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.participants = [
                    Acme_Appointments_V1_AppointmentParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = reply0.visitNote.counterparty.email
                        }
                    }
                ]
            }
            $0.context = input.context
        }
        let json1 = try outbound1.jsonString()
        let decoded1 = try Acme_Appointments_V1_CheckAppointmentEligibilityRequest(jsonString: json1)
        let reply1 = try await self.appointmentsAppointmentValidation.checkAppointmentEligibility(decoded1)
        let outbound2 = Acme_Broadcasts_V1_BatchCreateBroadcastsRequest.with {
            $0.context = input.context
            $0.record = Acme_Broadcasts_V1_Broadcast.with {
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = input.clinicSlot.location.countryCode
                }
                $0.participants = [
                    Acme_Broadcasts_V1_BroadcastParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = reply1.appointment.organizer.email
                        }
                    }
                ]
            }
        }
        let reply2 = try await self.broadcastsBroadcast.batchCreateBroadcasts { writer in
            try await writer.write(outbound2)
        }
        _ = reply2
        let outbound3 = Acme_Careplans_V1_NormalizeCareGoalRequest.forClinicSlotCalculationEndpointSimulateClinicSlot3(
            input,
            reply0: reply0,
            reply1: reply1
        )
        let reply3 = try await self.careplansCareGoalValidation.normalizeCareGoal(outbound3)
        return Acme_Appointments_V1_SimulateClinicSlotResponse.with {
            $0.clinicSlot = Acme_Appointments_V1_ClinicSlot.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply3.careGoal.audit.updatedBy
                }
                $0.clinicSlotID = input.clinicSlotID
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = reply1.appointment.location.countryCode
                    $0.locality = reply1.appointment.location.locality
                }
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.displayName = Projection.firstValue(
                        [
                            reply0.visitNote.counterparty.displayName,
                            reply3.careGoal.assignee.displayName,
                        ], default: .init())
                }
                $0.window = input.clinicSlot.window
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.status = "ok"
            }
        }
    }
}
