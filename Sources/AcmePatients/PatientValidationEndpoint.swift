import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Checks patients against the rules before anything acts on them.
final class PatientValidationEndpoint: Acme_Patients_V1_PatientValidationService.ServiceProtocol {
    private let store: any RecordRepository
    private let logger: Logger
    private let settings: Settings
    private let followUps = WorkQueue<Acme_Identity_V1_GetUserRequest>()
    private let appointmentsAppointment: Acme_Appointments_V1_AppointmentService.Client<MeshTransport>
    private let careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>
    private let careplansCarePlanCalculation: Acme_Careplans_V1_CarePlanCalculationService.Client<MeshTransport>
    private let documentsDocument: Acme_Documents_V1_DocumentService.Client<MeshTransport>
    private let featureflagsFeatureFlag: Acme_Featureflags_V1_FeatureFlagService.Client<MeshTransport>
    private let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    private let ledgerLedgerAccount: Acme_Ledger_V1_LedgerAccountService.Client<MeshTransport>
    private let patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>
    private let patientsPatientCalculation: Acme_Patients_V1_PatientCalculationService.Client<MeshTransport>
    private let prescriptionsMedicationQuery: Acme_Prescriptions_V1_MedicationQueryService.Client<MeshTransport>
    private let prescriptionsMedicationValidation:
        Acme_Prescriptions_V1_MedicationValidationService.Client<MeshTransport>
    private let telehealthTriageCalculation: Acme_Telehealth_V1_TriageCalculationService.Client<MeshTransport>
    private let previewPatientStep2:
        any RPCPort<Acme_Patients_V1_QuoteMedicalRecordRequest, Acme_Patients_V1_QuoteMedicalRecordResponse>
    private let scorePatientStep0:
        @Sendable (Acme_Patients_V1_ExplainMedicalRecordCalculationRequest) async throws ->
            Acme_Patients_V1_ExplainMedicalRecordCalculationResponse
    private let validatePatientStep0:
        [String:
            @Sendable (Acme_Patients_V1_ExplainMedicalRecordCalculationRequest) async throws ->
            Acme_Patients_V1_ExplainMedicalRecordCalculationResponse]

    init(
        dependencies: any Dependencies,
        appointmentsAppointment: Acme_Appointments_V1_AppointmentService.Client<MeshTransport>,
        careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>,
        careplansCarePlanCalculation: Acme_Careplans_V1_CarePlanCalculationService.Client<MeshTransport>,
        documentsDocument: Acme_Documents_V1_DocumentService.Client<MeshTransport>,
        featureflagsFeatureFlag: Acme_Featureflags_V1_FeatureFlagService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        ledgerLedgerAccount: Acme_Ledger_V1_LedgerAccountService.Client<MeshTransport>,
        patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>,
        patientsPatientCalculation: Acme_Patients_V1_PatientCalculationService.Client<MeshTransport>,
        prescriptionsMedicationQuery: Acme_Prescriptions_V1_MedicationQueryService.Client<MeshTransport>,
        prescriptionsMedicationValidation: Acme_Prescriptions_V1_MedicationValidationService.Client<MeshTransport>,
        telehealthTriageCalculation: Acme_Telehealth_V1_TriageCalculationService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.appointmentsAppointment = appointmentsAppointment
        self.careplansCarePlan = careplansCarePlan
        self.careplansCarePlanCalculation = careplansCarePlanCalculation
        self.documentsDocument = documentsDocument
        self.featureflagsFeatureFlag = featureflagsFeatureFlag
        self.identityUser = identityUser
        self.ledgerLedgerAccount = ledgerLedgerAccount
        self.patientsMedicalRecordCalculation = patientsMedicalRecordCalculation
        self.patientsPatientCalculation = patientsPatientCalculation
        self.prescriptionsMedicationQuery = prescriptionsMedicationQuery
        self.prescriptionsMedicationValidation = prescriptionsMedicationValidation
        self.telehealthTriageCalculation = telehealthTriageCalculation
        self.previewPatientStep2 = ClosurePort<
            Acme_Patients_V1_QuoteMedicalRecordRequest, Acme_Patients_V1_QuoteMedicalRecordResponse
        >({ request in try await patientsMedicalRecordCalculation.quoteMedicalRecord(request) })
        self.scorePatientStep0 = { request in
            try await patientsMedicalRecordCalculation.explainMedicalRecordCalculation(request)
        }
        self.validatePatientStep0 = [
            "primary": { request in try await patientsMedicalRecordCalculation.explainMedicalRecordCalculation(request)
            }
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

    /// Checks a patient.
    func checkPatientEligibility(
        request: ServerRequest<Acme_Patients_V1_CheckPatientEligibilityRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_CheckPatientEligibilityResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCheckPatientEligibility(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Explains a patient.
    func explainPatientDecision(
        request: ServerRequest<Acme_Patients_V1_ExplainPatientDecisionRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_ExplainPatientDecisionResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processExplainPatientDecision(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a patient.
    func getPatientRules(
        request: ServerRequest<Acme_Patients_V1_GetPatientRulesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_GetPatientRulesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetPatientRules(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lints a patient.
    func lintPatients(
        request: ServerRequest<Acme_Patients_V1_LintPatientsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_LintPatientsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processLintPatients(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Normalizes a patient.
    func normalizePatient(
        request: ServerRequest<Acme_Patients_V1_NormalizePatientRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_NormalizePatientResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processNormalizePatient(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Previews a patient.
    func previewPatient(
        request: ServerRequest<Acme_Patients_V1_PreviewPatientRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_PreviewPatientResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processPreviewPatient(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Scores a patient.
    func scorePatient(
        request: ServerRequest<Acme_Patients_V1_ScorePatientRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_ScorePatientResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processScorePatient(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Validates a patient.
    func validatePatient(
        request: ServerRequest<Acme_Patients_V1_ValidatePatientRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_ValidatePatientResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processValidatePatient(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processCheckPatientEligibility(_ input: Acme_Patients_V1_CheckPatientEligibilityRequest) async throws
        -> Acme_Patients_V1_CheckPatientEligibilityResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "audit", detail: input.details.contact.email
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "CheckPatientEligibility",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PatientRecord(input.patient, tenant: input.context.tenantID)
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
        let outbound0 = Acme_Patients_V1_RecalculatePatientsRequest.with {
            $0.context = input.context
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.preferredChannel = input.patient.contact.preferredChannel
                }
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = input.patient.primaryAddress.countryCode
                }
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.patient.relationshipManager.userID
                }
            }
        }
        let reply0 = try await self.patientsPatientCalculation.recalculatePatients(
            outbound0, metadata: ["x-acme-region": .string(settings.region)]
        )
        let outbound1 = Acme_Featureflags_V1_ListFeatureFlagsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Featureflags_V1_ListFeatureFlagsRequest.Filter.with {
                $0.createdAfter = input.patient.audit.updatedAt
                $0.ownerID = reply0.patient.patientID
                $0.region = reply0.patient.primaryAddress.region
            }
        }
        let reply1 = try await RPCOperations.call(outbound1) { request in
            try await self.featureflagsFeatureFlag.listFeatureFlags(request)
        }
        return Acme_Patients_V1_CheckPatientEligibilityResponse.with {
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.attributes = reply0.patient.attributes
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply0.patient.audit.updatedAt
                }
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.name = input.patient.name
                }
                $0.patientID = input.patientID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.message = reply1.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processExplainPatientDecision(_ input: Acme_Patients_V1_ExplainPatientDecisionRequest) async throws
        -> Acme_Patients_V1_ExplainPatientDecisionResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "audit", detail: input.details.contact.email
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ExplainPatientDecision",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PatientRecord(input.patient, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Telehealth_V1_CompareTriageOptionsRequest.with {
            $0.context = Projection.read(input, at: \Acme_Patients_V1_ExplainPatientDecisionRequest.context)
            $0.details = Acme_Telehealth_V1_CompareTriageOptionsRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.region = Projection.read(
                        input, at: \Acme_Patients_V1_ExplainPatientDecisionRequest.patient.primaryAddress.region)
                }
            }
        }
        let reply0 = try await self.telehealthTriageCalculation.compareTriageOptions(outbound0)
        return Acme_Patients_V1_ExplainPatientDecisionResponse.with {
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.attributes = input.patient.attributes
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.name = reply0.triage.requester.name
                }
                $0.patientID = input.patientID
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.userID = reply0.triage.assignee.userID
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processGetPatientRules(_ input: Acme_Patients_V1_GetPatientRulesRequest) async throws
        -> Acme_Patients_V1_GetPatientRulesResponse
    {
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "GetPatientRules",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "GetPatientRules", detail: input.context.traceID
        )
        let outbound0 = Acme_Patients_V1_EstimateMedicalRecordRequest.with {
            $0.context = input.context
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.email = input.context.actor.email
                    $0.patientID = input.patientID
                }
            }
        }
        let step0: @Sendable () async throws -> Acme_Patients_V1_EstimateMedicalRecordResponse = {
            try await self.patientsMedicalRecordCalculation.estimateMedicalRecord(outbound0)
        }
        let reply0 = try await step0()
        return Acme_Patients_V1_GetPatientRulesResponse.with {
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.patientID = input.patientID
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = reply0.medicalRecord.billingAddress.postalCode
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processLintPatients(_ input: Acme_Patients_V1_LintPatientsRequest) async throws
        -> Acme_Patients_V1_LintPatientsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "audit", detail: input.details.contact.email
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "LintPatients",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PatientRecord(input.patient, tenant: input.context.tenantID)
        try await store.save(record.stored)
        var outbound0 = Acme_Patients_V1_QuoteMedicalRecordRequest()
        outbound0.context = input.context
        outbound0.details = Acme_Patients_V1_QuoteMedicalRecordRequest.Details.with {
            $0.destination = Acme_Common_V1_PostalAddress.with {
                $0.countryCode = input.patient.primaryAddress.countryCode
            }
        }
        outbound0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
            $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                $0.locality = input.patient.primaryAddress.locality
                $0.postalCode = input.patient.primaryAddress.postalCode
            }
        }
        let reply0 = try await self.patientsMedicalRecordCalculation.quoteMedicalRecord(outbound0)
        return Acme_Patients_V1_LintPatientsResponse.with {
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.patientID = input.patientID
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.email = reply0.medicalRecord.counterparty.email
                }
                $0.status = input.patient.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processNormalizePatient(_ input: Acme_Patients_V1_NormalizePatientRequest) async throws
        -> Acme_Patients_V1_NormalizePatientResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "audit", detail: input.details.contact.email
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "NormalizePatient",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PatientRecord(input.patient, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Prescriptions_V1_NormalizeMedicationRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_NormalizeMedicationRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.name = input.patient.contact.name
                    $0.phone = input.patient.contact.phone
                }
            }
        }
        let step0: @Sendable () async throws -> Acme_Prescriptions_V1_NormalizeMedicationResponse = {
            try await self.prescriptionsMedicationValidation.normalizeMedication(outbound0)
        }
        let reply0 = try await step0()
        let selection1_1: String
        switch reply0.medication.locator {
        case .address(let address):
            selection1_1 = address.postalCode
        default: selection1_1 = .init()
        }
        let outbound1 = Acme_Documents_V1_CreateDocumentRequest.with {
            $0.context = input.context
            $0.document = Acme_Documents_V1_Document.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = selection1_1
                }
            }
        }
        let reply1 = try await self.documentsDocument.createDocument(outbound1)
        let selection2_1: String
        switch reply0.medication.locator {
        case .address(let address):
            selection2_1 = address.region
        default: selection2_1 = .init()
        }
        let outbound2 = Acme_Prescriptions_V1_FindMedicationsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Prescriptions_V1_FindMedicationsRequest.Filter.with {
                $0.createdAfter = reply1.document.audit.updatedAt
                $0.ownerID = input.patient.relationshipManager.userID
                $0.region = selection2_1
            }
        }
        let reply2 = try await self.prescriptionsMedicationQuery.findMedications(outbound2)
        let selection3_2: String
        switch reply1.document.settlement {
        case .bank(let bank):
            selection3_2 = bank.iban
        default: selection3_2 = .init()
        }
        let selection3_4: String
        switch reply0.medication.locator {
        case .address(let address):
            selection3_4 = address.region
        default: selection3_4 = .init()
        }
        let outbound3 = Acme_Patients_V1_CompareMedicalRecordOptionsRequest.with {
            $0.context = input.context
            $0.details = Acme_Patients_V1_CompareMedicalRecordOptionsRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = reply1.document.billingAddress.postalCode
                }
            }
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = input.patient.audit.updatedAt
                }
                $0.bank = Acme_Patients_V1_MedicalRecordBankSettlement.with {
                    $0.iban = selection3_2
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = selection3_4
                }
            }
        }
        let reply3 = try await self.patientsMedicalRecordCalculation.compareMedicalRecordOptions(outbound3)
        return Acme_Patients_V1_NormalizePatientResponse.with {
            $0.outcome = Acme_Patients_V1_NormalizePatientResponse.Outcome.with {
                $0.status = reply2.result.status
            }
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply1.document.audit.updatedBy
                }
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply0.medication.owner.email
                }
                $0.patientID = input.patientID
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = reply1.document.billingAddress.countryCode
                }
                $0.status = input.patient.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply3.result.correlationID
                $0.message = reply2.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processPreviewPatient(_ input: Acme_Patients_V1_PreviewPatientRequest) async throws
        -> Acme_Patients_V1_PreviewPatientResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.preferredChannel)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "audit", detail: input.details.contact.preferredChannel
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "PreviewPatient",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PatientRecord(input.patient, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Careplans_V1_ListCarePlansRequest.with {
            $0.context = input.context
            $0.filter = Acme_Careplans_V1_ListCarePlansRequest.Filter.with {
                $0.region = input.patient.primaryAddress.region
            }
        }
        let reply0 = try await self.careplansCarePlan.listCarePlans(outbound0)
        let outbound1 = Acme_Appointments_V1_CreateAppointmentRequest.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.participants = [
                    Acme_Appointments_V1_AppointmentParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = input.details.contact.email
                            $0.phone = input.details.contact.phone
                        }
                    }
                ]
            }
            $0.context = input.context
        }
        async let remote1 = self.appointmentsAppointment.createAppointment(outbound1)
        async let persisted1 = store.count(tenant: input.context.tenantID)
        let (reply1, count1) = try await (remote1, persisted1)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count1)])
        let outbound2 = Acme_Patients_V1_QuoteMedicalRecordRequest.with {
            $0.context = input.context
            $0.details = Acme_Patients_V1_QuoteMedicalRecordRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.patient.primaryAddress.region
                }
            }
        }
        let reply2 = try await self.previewPatientStep2.execute(outbound2)
        let outbound3 = Acme_Ledger_V1_CloneLedgerAccountRequest.with {
            $0.context = input.context
            $0.ledgerAccount = Acme_Ledger_V1_LedgerAccount.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply2.medicalRecord.audit.createdAt
                    $0.createdBy = reply1.appointment.audit.createdBy
                    $0.etag = reply1.appointment.audit.etag
                }
                $0.holder = Acme_Ledger_V1_PostingBatchRef.with {
                    $0.displayName = reply2.medicalRecord.counterparty.displayName
                }
            }
        }
        let port3 = RPCOperations.port { (request: Acme_Ledger_V1_CloneLedgerAccountRequest) in
            try await self.ledgerLedgerAccount.cloneLedgerAccount(request)
        }
        let reply3 = try await port3.execute(outbound3)
        return Acme_Patients_V1_PreviewPatientResponse.with {
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply3.ledgerAccount.audit.updatedBy
                }
                $0.patientID = input.patientID
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.lines = reply1.appointment.location.lines
                }
                $0.status = input.patient.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply2.result.correlationID
                $0.message = reply0.result.message
                $0.referenceIds = reply3.result.referenceIds
                $0.status = reply1.result.status
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processScorePatient(_ input: Acme_Patients_V1_ScorePatientRequest) async throws
        -> Acme_Patients_V1_ScorePatientResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.currencyCode)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "audit", detail: input.details.currencyCode
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ScorePatient",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PatientRecord(input.patient, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Patients_V1_ExplainMedicalRecordCalculationRequest.with {
            $0.context = input.context
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = input.details.destination.countryCode
                }
            }
        }
        let reply0 = try await self.scorePatientStep0(outbound0)
        return Acme_Patients_V1_ScorePatientResponse.with {
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.patientID = input.patientID
                $0.relationshipManager = input.patient.relationshipManager
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply0.result.status
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processValidatePatient(_ input: Acme_Patients_V1_ValidatePatientRequest) async throws
        -> Acme_Patients_V1_ValidatePatientResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.phone)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "audit", detail: input.details.contact.phone
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ValidatePatient",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PatientRecord(input.patient, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Patients_V1_ExplainMedicalRecordCalculationRequest.with {
            $0.context = input.context
            $0.details = Acme_Patients_V1_ExplainMedicalRecordCalculationRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.contact.email
                }
            }
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.lines = input.patient.primaryAddress.lines
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.email = input.patient.relationshipManager.email
                }
            }
        }
        guard let execute0 = self.validatePatientStep0[settings.region] ?? self.validatePatientStep0["primary"] else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply0 = try await execute0(outbound0)
        let outbound1 = Acme_Careplans_V1_SimulateCarePlanRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = input.patient.audit.etag
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.locality = input.patient.primaryAddress.locality
                    $0.recipient = input.patient.primaryAddress.recipient
                }
            }
            $0.context = input.context
            $0.details = Acme_Careplans_V1_SimulateCarePlanRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.recipient = reply0.medicalRecord.billingAddress.recipient
                }
            }
        }
        let reply1 = try await self.careplansCarePlanCalculation.simulateCarePlan(outbound1)
        return Acme_Patients_V1_ValidatePatientResponse.with {
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.patientID = input.patientID
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = reply0.medicalRecord.billingAddress.countryCode
                    $0.locality = reply1.carePlan.billingAddress.locality
                }
                $0.relationshipManager = input.patient.relationshipManager
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }
}
