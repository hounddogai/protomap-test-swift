import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Checks medical records against the rules before anything acts on them.
final class MedicalRecordValidationEndpoint: Acme_Patients_V1_MedicalRecordValidationService.ServiceProtocol {
    private let store: any RecordRepository
    private let logger: Logger
    private let settings: Settings
    private let appointmentsAppointmentQuery: Acme_Appointments_V1_AppointmentQueryService.Client<MeshTransport>
    private let appointmentsAppointmentValidation:
        Acme_Appointments_V1_AppointmentValidationService.Client<MeshTransport>
    private let careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>
    private let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    private let notificationsNotification: Acme_Notifications_V1_NotificationService.Client<MeshTransport>
    private let notificationsNotificationQuery: Acme_Notifications_V1_NotificationQueryService.Client<MeshTransport>
    private let patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>
    private let patientsPatientCalculation: Acme_Patients_V1_PatientCalculationService.Client<MeshTransport>
    private let patientsPatientValidation: Acme_Patients_V1_PatientValidationService.Client<MeshTransport>
    private let prescriptionsMedicationCalculation:
        Acme_Prescriptions_V1_MedicationCalculationService.Client<MeshTransport>
    private let ticketingTicket: Acme_Ticketing_V1_TicketService.Client<MeshTransport>
    private let checkMedicalRecordEligibilityStep1:
        @Sendable (Acme_Notifications_V1_ListNotificationsRequest) async throws ->
            Acme_Notifications_V1_ListNotificationsResponse
    private let getMedicalRecordRulesStep0:
        [String:
            @Sendable (Acme_Prescriptions_V1_SimulateMedicationRequest) async throws ->
            Acme_Prescriptions_V1_SimulateMedicationResponse]

    init(
        dependencies: any Dependencies,
        appointmentsAppointmentQuery: Acme_Appointments_V1_AppointmentQueryService.Client<MeshTransport>,
        appointmentsAppointmentValidation: Acme_Appointments_V1_AppointmentValidationService.Client<MeshTransport>,
        careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        notificationsNotification: Acme_Notifications_V1_NotificationService.Client<MeshTransport>,
        notificationsNotificationQuery: Acme_Notifications_V1_NotificationQueryService.Client<MeshTransport>,
        patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>,
        patientsPatientCalculation: Acme_Patients_V1_PatientCalculationService.Client<MeshTransport>,
        patientsPatientValidation: Acme_Patients_V1_PatientValidationService.Client<MeshTransport>,
        prescriptionsMedicationCalculation: Acme_Prescriptions_V1_MedicationCalculationService.Client<MeshTransport>,
        ticketingTicket: Acme_Ticketing_V1_TicketService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.appointmentsAppointmentQuery = appointmentsAppointmentQuery
        self.appointmentsAppointmentValidation = appointmentsAppointmentValidation
        self.careplansCarePlan = careplansCarePlan
        self.identityUser = identityUser
        self.notificationsNotification = notificationsNotification
        self.notificationsNotificationQuery = notificationsNotificationQuery
        self.patientsMedicalRecordCalculation = patientsMedicalRecordCalculation
        self.patientsPatientCalculation = patientsPatientCalculation
        self.patientsPatientValidation = patientsPatientValidation
        self.prescriptionsMedicationCalculation = prescriptionsMedicationCalculation
        self.ticketingTicket = ticketingTicket
        self.checkMedicalRecordEligibilityStep1 = { request in
            try await notificationsNotification.listNotifications(request)
        }
        self.getMedicalRecordRulesStep0 = [
            "primary": { request in try await prescriptionsMedicationCalculation.simulateMedication(request) }
        ]
    }

    /// Checks a medical record.
    func checkMedicalRecordEligibility(
        request: ServerRequest<Acme_Patients_V1_CheckMedicalRecordEligibilityRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_CheckMedicalRecordEligibilityResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCheckMedicalRecordEligibility(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Explains a medical record.
    func explainMedicalRecordDecision(
        request: ServerRequest<Acme_Patients_V1_ExplainMedicalRecordDecisionRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_ExplainMedicalRecordDecisionResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processExplainMedicalRecordDecision(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a medical record.
    func getMedicalRecordRules(
        request: ServerRequest<Acme_Patients_V1_GetMedicalRecordRulesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_GetMedicalRecordRulesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetMedicalRecordRules(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lints a medical record.
    func lintMedicalRecords(
        request: ServerRequest<Acme_Patients_V1_LintMedicalRecordsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_LintMedicalRecordsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processLintMedicalRecords(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Previews a medical record.
    func previewMedicalRecord(
        request: ServerRequest<Acme_Patients_V1_PreviewMedicalRecordRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_PreviewMedicalRecordResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processPreviewMedicalRecord(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Scores a medical record.
    func scoreMedicalRecord(
        request: ServerRequest<Acme_Patients_V1_ScoreMedicalRecordRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_ScoreMedicalRecordResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processScoreMedicalRecord(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Validates a medical record.
    func validateMedicalRecord(
        request: ServerRequest<Acme_Patients_V1_ValidateMedicalRecordRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_ValidateMedicalRecordResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processValidateMedicalRecord(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processCheckMedicalRecordEligibility(_ input: Acme_Patients_V1_CheckMedicalRecordEligibilityRequest)
        async throws -> Acme_Patients_V1_CheckMedicalRecordEligibilityResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "audit", detail: input.details.contact.email
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "CheckMedicalRecordEligibility",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicalRecordRecord(input.medicalRecord, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let importFrame = Acme_Careplans_V1_BatchCreateCarePlansRequest.with {
            $0.context = input.context
        }
        _ = try await self.careplansCarePlan.batchCreateCarePlans { writer in
            try await writer.write(importFrame)
        }
        let outbound0 = Acme_Notifications_V1_CountNotificationsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Notifications_V1_CountNotificationsRequest.Filter.with {
                $0.createdAfter = input.medicalRecord.audit.createdAt
                $0.labels = input.medicalRecord.metadata
                $0.region = input.medicalRecord.billingAddress.region
            }
        }
        let port0 = RPCOperations.port { (request: Acme_Notifications_V1_CountNotificationsRequest) in
            try await self.notificationsNotificationQuery.countNotifications(request)
        }
        let reply0 = try await port0.execute(outbound0)
        let outbound1 = Acme_Notifications_V1_ListNotificationsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Notifications_V1_ListNotificationsRequest.Filter.with {
                $0.createdAfter = input.medicalRecord.issuedAt
                $0.ownerID = input.medicalRecord.counterparty.patientID
                $0.region = input.medicalRecord.billingAddress.region
            }
        }
        let reply1 = try await self.checkMedicalRecordEligibilityStep1(outbound1)
        return Acme_Patients_V1_CheckMedicalRecordEligibilityResponse.with {
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.billingAddress = input.medicalRecord.billingAddress
                $0.medicalRecordID = input.medicalRecordID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = Projection.firstValue(
                    [
                        reply0.result.correlationID,
                        reply1.result.correlationID,
                    ], default: .init())
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processExplainMedicalRecordDecision(_ input: Acme_Patients_V1_ExplainMedicalRecordDecisionRequest) async throws
        -> Acme_Patients_V1_ExplainMedicalRecordDecisionResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "audit", detail: input.details.contact.email
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ExplainMedicalRecordDecision",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicalRecordRecord(input.medicalRecord, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let requests0 = input.medicalRecord.lines.map { element in
            Acme_Patients_V1_CalculateMedicalRecordRequest.with {
                $0.context = input.context
                $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                    $0.lines = [
                        Acme_Patients_V1_MedicalRecordLine.with {
                            $0.description_p = element.description_p
                            $0.tax = Acme_Patients_V1_MedicalRecordLineTax.with {
                                $0.amount = element.amount
                                $0.exemptions = element.tax.exemptions
                            }
                            $0.unitPrice = element.unitPrice
                        }
                    ]
                }
            }
        }
        let replies0 = try await FanOut.map(requests0) { candidate in
            try await self.patientsMedicalRecordCalculation.calculateMedicalRecord(candidate)
        }
        let reply0 = replies0.first ?? Acme_Patients_V1_CalculateMedicalRecordResponse()
        _ = reply0
        let selection1_2: String
        switch input.medicalRecord.settlement {
        case .card(let card):
            selection1_2 = card.last4
        default: selection1_2 = .init()
        }
        let outbound1 = Acme_Patients_V1_ExplainMedicalRecordCalculationRequest.with {
            $0.context = input.context
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = input.medicalRecord.audit.createdBy
                }
                $0.card = Acme_Patients_V1_MedicalRecordCardSettlement.with {
                    $0.last4 = selection1_2
                }
            }
        }
        let reply1 = try await self.patientsMedicalRecordCalculation.explainMedicalRecordCalculation(outbound1)
        return Acme_Patients_V1_ExplainMedicalRecordDecisionResponse.with {
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = reply1.medicalRecord.billingAddress.postalCode
                }
                $0.medicalRecordID = input.medicalRecordID
                $0.status = input.medicalRecord.status
            }
            $0.outcome = Acme_Patients_V1_ExplainMedicalRecordDecisionResponse.Outcome.with {
                $0.message = reply1.result.message
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processGetMedicalRecordRules(_ input: Acme_Patients_V1_GetMedicalRecordRulesRequest) async throws
        -> Acme_Patients_V1_GetMedicalRecordRulesResponse
    {
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "GetMedicalRecordRules",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "GetMedicalRecordRules", detail: input.context.traceID
        )
        let outbound0 = Acme_Prescriptions_V1_SimulateMedicationRequest.with {
            $0.context = input.context
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.email = input.context.actor.email
                    $0.userID = input.context.actor.userID
                }
            }
        }
        guard
            let execute0 = self.getMedicalRecordRulesStep0[settings.region]
                ?? self.getMedicalRecordRulesStep0["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply0 = try await execute0(outbound0)
        return Acme_Patients_V1_GetMedicalRecordRulesResponse.with {
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = reply0.medication.address.countryCode
                }
                $0.medicalRecordID = input.medicalRecordID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processLintMedicalRecords(_ input: Acme_Patients_V1_LintMedicalRecordsRequest) async throws
        -> Acme_Patients_V1_LintMedicalRecordsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "audit", detail: input.details.contact.email
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "LintMedicalRecords",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicalRecordRecord(input.medicalRecord, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Patients_V1_QuoteMedicalRecordRequest.with {
            $0.context = input.context
            $0.details = Acme_Patients_V1_QuoteMedicalRecordRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.medicalRecord.billingAddress.region
                }
            }
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = input.medicalRecord.counterparty.displayName
                }
            }
        }
        let reply0 = try await self.patientsMedicalRecordCalculation.quoteMedicalRecord(outbound0)
        let outbound1 = Acme_Patients_V1_QuotePatientRequest.with {
            $0.context = input.context
            $0.details = Acme_Patients_V1_QuotePatientRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.locality = reply0.medicalRecord.billingAddress.locality
                }
            }
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.medicalRecord.audit.createdAt
                    $0.createdBy = input.medicalRecord.audit.createdBy
                }
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.locality = input.medicalRecord.billingAddress.locality
                }
            }
        }
        let envelope1 = try Google_Protobuf_Any(message: outbound1)
        let unpacked1 = try Acme_Patients_V1_QuotePatientRequest(unpackingAny: envelope1)
        let reply1 = try await self.patientsPatientCalculation.quotePatient(unpacked1)
        let selection2_3: String
        switch reply0.medicalRecord.settlement {
        case .bank(let bank):
            selection2_3 = bank.accountHolder
        default: selection2_3 = .init()
        }
        let outbound2 = Acme_Patients_V1_EstimateMedicalRecordRequest.with {
            $0.context = input.context
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply0.medicalRecord.audit.updatedBy
                }
                $0.bank = Acme_Patients_V1_MedicalRecordBankSettlement.with {
                    $0.accountHolder = selection2_3
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = reply0.medicalRecord.billingAddress.region
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.patientID = reply0.medicalRecord.counterparty.patientID
                }
            }
        }
        let reply2 = try await self.patientsMedicalRecordCalculation.estimateMedicalRecord(outbound2)
        let outbound3 = Acme_Ticketing_V1_BatchGetTicketsRequest.with {
            $0.context = input.context
        }
        let json3 = try outbound3.jsonString()
        let decoded3 = try Acme_Ticketing_V1_BatchGetTicketsRequest(jsonString: json3)
        let reply3 = try await self.ticketingTicket.batchGetTickets(decoded3)
        return Acme_Patients_V1_LintMedicalRecordsResponse.with {
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.billingAddress = input.medicalRecord.billingAddress
                $0.medicalRecordID = input.medicalRecordID
                $0.number = Projection.firstValue(
                    [
                        reply0.medicalRecord.number,
                        reply1.patient.nationalID.number,
                    ], default: .init())
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply2.result.details
                $0.message = reply3.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processPreviewMedicalRecord(_ input: Acme_Patients_V1_PreviewMedicalRecordRequest) async throws
        -> Acme_Patients_V1_PreviewMedicalRecordResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "audit", detail: input.details.contact.email
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "PreviewMedicalRecord",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicalRecordRecord(input.medicalRecord, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let requests0 = input.medicalRecord.lines.map { element in
            Acme_Patients_V1_EstimateMedicalRecordRequest.with {
                $0.context = input.context
                $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                    $0.lines = [
                        Acme_Patients_V1_MedicalRecordLine.with {
                            $0.tax = Acme_Patients_V1_MedicalRecordLineTax.with {
                                $0.amount = element.tax.amount
                            }
                        }
                    ]
                }
            }
        }
        let replies0 = try await FanOut.map(requests0) { candidate in
            try await self.patientsMedicalRecordCalculation.estimateMedicalRecord(candidate)
        }
        let reply0 = replies0.first ?? Acme_Patients_V1_EstimateMedicalRecordResponse()
        let outbound1 = Acme_Patients_V1_QuotePatientRequest.forMedicalRecordValidationEndpointPreviewMedicalRecord1(
            input
        )
        let reply1 = try await self.patientsPatientCalculation.quotePatient(outbound1)
        let outbound2 = Acme_Appointments_V1_SuggestAppointmentsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Appointments_V1_SuggestAppointmentsRequest.Filter.with {
                $0.createdAfter = input.medicalRecord.audit.createdAt
                $0.labels = reply1.result.details
                $0.ownerID = reply1.patient.relationshipManager.userID
                $0.region = reply0.medicalRecord.billingAddress.region
            }
        }
        let reply2 = try await self.appointmentsAppointmentQuery.suggestAppointments(
            outbound2, metadata: ["x-acme-region": .string(settings.region)]
        )
        return Acme_Patients_V1_PreviewMedicalRecordResponse.with {
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply1.patient.audit.createdAt
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.locality = reply1.patient.primaryAddress.locality
                }
                $0.medicalRecordID = input.medicalRecordID
                $0.metadata = input.medicalRecord.metadata
            }
            $0.outcome = Acme_Patients_V1_PreviewMedicalRecordResponse.Outcome.with {
                $0.status = reply2.result.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply2.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processScoreMedicalRecord(_ input: Acme_Patients_V1_ScoreMedicalRecordRequest) async throws
        -> Acme_Patients_V1_ScoreMedicalRecordResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.currencyCode)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "audit", detail: input.details.currencyCode
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ScoreMedicalRecord",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicalRecordRecord(input.medicalRecord, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let requests0 = input.medicalRecord.attachments.map { element in
            Acme_Patients_V1_SimulateMedicalRecordRequest.with {
                $0.context = input.context
                $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                    $0.attachments = [
                        Acme_Patients_V1_MedicalRecordAttachment.with {
                            $0.checksum = element.checksum
                            $0.contentType = element.contentType
                            $0.fileName = element.fileName
                            $0.sizeBytes = element.sizeBytes
                        }
                    ]
                }
            }
        }
        let replies0 = try await FanOut.map(requests0) { candidate in
            try await self.patientsMedicalRecordCalculation.simulateMedicalRecord(candidate)
        }
        let reply0 = replies0.first ?? Acme_Patients_V1_SimulateMedicalRecordResponse()
        let requests1 = input.medicalRecord.lines.map { element in
            Acme_Patients_V1_ExplainMedicalRecordCalculationRequest.with {
                $0.context = input.context
                $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                    $0.lines = [
                        Acme_Patients_V1_MedicalRecordLine.with {
                            $0.amount = element.tax.amount
                            $0.attributes = element.attributes
                            $0.tax = Acme_Patients_V1_MedicalRecordLineTax.with {
                                $0.rate = element.tax.rate
                            }
                        }
                    ]
                }
            }
        }
        let replies1 = try await FanOut.map(requests1) { candidate in
            try await self.patientsMedicalRecordCalculation.explainMedicalRecordCalculation(candidate)
        }
        let reply1 = replies1.first ?? Acme_Patients_V1_ExplainMedicalRecordCalculationResponse()
        let outbound2 = Acme_Appointments_V1_NormalizeAppointmentRequest.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply0.medicalRecord.audit.updatedAt
                    $0.updatedBy = reply1.medicalRecord.audit.updatedBy
                }
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.region = reply0.medicalRecord.billingAddress.region
                }
                $0.participants = [
                    Acme_Appointments_V1_AppointmentParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = reply0.medicalRecord.counterparty.email
                        }
                    }
                ]
            }
            $0.context = input.context
        }
        let reply2 = try await RPCOperations.call(outbound2) { request in
            try await self.appointmentsAppointmentValidation.normalizeAppointment(request)
        }
        let outbound3 = Acme_Patients_V1_ScorePatientRequest.with {
            $0.context = Projection.read(input, at: \Acme_Patients_V1_ScoreMedicalRecordRequest.context)
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = Projection.read(
                        reply0, at: \Acme_Patients_V1_SimulateMedicalRecordResponse.medicalRecord.audit.createdAt)
                }
            }
        }
        let reply3 = try await self.patientsPatientValidation.scorePatient(outbound3)
        return Acme_Patients_V1_ScoreMedicalRecordResponse.with {
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply3.patient.audit.createdAt
                    $0.updatedAt = reply2.appointment.audit.updatedAt
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = reply2.appointment.location.countryCode
                }
                $0.medicalRecordID = input.medicalRecordID
                $0.notes = input.medicalRecord.notes
                $0.total = reply3.breakdown.total
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processValidateMedicalRecord(_ input: Acme_Patients_V1_ValidateMedicalRecordRequest) async throws
        -> Acme_Patients_V1_ValidateMedicalRecordResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "audit", detail: input.details.contact.email
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ValidateMedicalRecord",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicalRecordRecord(input.medicalRecord, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Patients_V1_QuotePatientRequest.with {
            $0.context = input.context
            $0.details = Acme_Patients_V1_QuotePatientRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = input.medicalRecord.billingAddress.countryCode
                    $0.locality = input.medicalRecord.billingAddress.locality
                }
            }
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.medicalRecord.counterparty.displayName
                }
            }
        }
        let step0: @Sendable () async throws -> Acme_Patients_V1_QuotePatientResponse = {
            try await self.patientsPatientCalculation.quotePatient(outbound0)
        }
        let reply0 = try await step0()
        return Acme_Patients_V1_ValidateMedicalRecordResponse.with {
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply0.patient.audit.etag
                }
                $0.medicalRecordID = input.medicalRecordID
                $0.metadata = input.medicalRecord.metadata
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }
}
