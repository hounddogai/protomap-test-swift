import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Runs the long-lived workflow that takes a medication from start to finish.
final class MedicationWorkflowEndpoint: Acme_Prescriptions_V1_MedicationWorkflowService.ServiceProtocol {
    private let store: any RecordRepository
    private let logger: Logger
    private let settings: Settings
    private let auditAuditEvent: Acme_Audit_V1_AuditEventService.Client<MeshTransport>
    private let authorizationAccessPolicyValidation:
        Acme_Authorization_V1_AccessPolicyValidationService.Client<MeshTransport>
    private let careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>
    private let careplansCarePlanApproval: Acme_Careplans_V1_CarePlanApprovalService.Client<MeshTransport>
    private let careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client<MeshTransport>
    private let featureflagsFeatureFlag: Acme_Featureflags_V1_FeatureFlagService.Client<MeshTransport>
    private let featureflagsFeatureFlagQuery: Acme_Featureflags_V1_FeatureFlagQueryService.Client<MeshTransport>
    private let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    private let identityUserQuery: Acme_Identity_V1_UserQueryService.Client<MeshTransport>
    private let metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client<MeshTransport>
    private let patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>
    private let patientsMedicalRecordQuery: Acme_Patients_V1_MedicalRecordQueryService.Client<MeshTransport>
    private let prescriptionsMedicationApproval: Acme_Prescriptions_V1_MedicationApprovalService.Client<MeshTransport>
    private let prescriptionsPrescriptionApproval:
        Acme_Prescriptions_V1_PrescriptionApprovalService.Client<MeshTransport>
    private let prescriptionsPrescriptionQuery: Acme_Prescriptions_V1_PrescriptionQueryService.Client<MeshTransport>
    private let prescriptionsPrescriptionReporting:
        Acme_Prescriptions_V1_PrescriptionReportingService.Client<MeshTransport>
    private let prescriptionsPrescriptionSync: Acme_Prescriptions_V1_PrescriptionSyncService.Client<MeshTransport>
    private let telehealthVideoVisitApproval: Acme_Telehealth_V1_VideoVisitApprovalService.Client<MeshTransport>
    private let telehealthVisitNoteWorkflow: Acme_Telehealth_V1_VisitNoteWorkflowService.Client<MeshTransport>
    private let listMedicationWorkflowsStep0:
        any RPCPort<Acme_Patients_V1_CalculateMedicalRecordRequest, Acme_Patients_V1_CalculateMedicalRecordResponse>
    private let resumeMedicationWorkflowStep0:
        @Sendable (Acme_Prescriptions_V1_RecallPrescriptionRequest) async throws ->
            Acme_Prescriptions_V1_RecallPrescriptionResponse
    private let resumeMedicationWorkflowStep1:
        [String:
            @Sendable (Acme_Authorization_V1_PreviewAccessPolicyRequest) async throws ->
            Acme_Authorization_V1_PreviewAccessPolicyResponse]

    init(
        dependencies: any Dependencies,
        auditAuditEvent: Acme_Audit_V1_AuditEventService.Client<MeshTransport>,
        authorizationAccessPolicyValidation: Acme_Authorization_V1_AccessPolicyValidationService.Client<MeshTransport>,
        careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>,
        careplansCarePlanApproval: Acme_Careplans_V1_CarePlanApprovalService.Client<MeshTransport>,
        careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client<MeshTransport>,
        featureflagsFeatureFlag: Acme_Featureflags_V1_FeatureFlagService.Client<MeshTransport>,
        featureflagsFeatureFlagQuery: Acme_Featureflags_V1_FeatureFlagQueryService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        identityUserQuery: Acme_Identity_V1_UserQueryService.Client<MeshTransport>,
        metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client<MeshTransport>,
        patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>,
        patientsMedicalRecordQuery: Acme_Patients_V1_MedicalRecordQueryService.Client<MeshTransport>,
        prescriptionsMedicationApproval: Acme_Prescriptions_V1_MedicationApprovalService.Client<MeshTransport>,
        prescriptionsPrescriptionApproval: Acme_Prescriptions_V1_PrescriptionApprovalService.Client<MeshTransport>,
        prescriptionsPrescriptionQuery: Acme_Prescriptions_V1_PrescriptionQueryService.Client<MeshTransport>,
        prescriptionsPrescriptionReporting: Acme_Prescriptions_V1_PrescriptionReportingService.Client<MeshTransport>,
        prescriptionsPrescriptionSync: Acme_Prescriptions_V1_PrescriptionSyncService.Client<MeshTransport>,
        telehealthVideoVisitApproval: Acme_Telehealth_V1_VideoVisitApprovalService.Client<MeshTransport>,
        telehealthVisitNoteWorkflow: Acme_Telehealth_V1_VisitNoteWorkflowService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.auditAuditEvent = auditAuditEvent
        self.authorizationAccessPolicyValidation = authorizationAccessPolicyValidation
        self.careplansCarePlan = careplansCarePlan
        self.careplansCarePlanApproval = careplansCarePlanApproval
        self.careplansCarePlanValidation = careplansCarePlanValidation
        self.featureflagsFeatureFlag = featureflagsFeatureFlag
        self.featureflagsFeatureFlagQuery = featureflagsFeatureFlagQuery
        self.identityUser = identityUser
        self.identityUserQuery = identityUserQuery
        self.metricsMetricSeriesValidation = metricsMetricSeriesValidation
        self.patientsMedicalRecordCalculation = patientsMedicalRecordCalculation
        self.patientsMedicalRecordQuery = patientsMedicalRecordQuery
        self.prescriptionsMedicationApproval = prescriptionsMedicationApproval
        self.prescriptionsPrescriptionApproval = prescriptionsPrescriptionApproval
        self.prescriptionsPrescriptionQuery = prescriptionsPrescriptionQuery
        self.prescriptionsPrescriptionReporting = prescriptionsPrescriptionReporting
        self.prescriptionsPrescriptionSync = prescriptionsPrescriptionSync
        self.telehealthVideoVisitApproval = telehealthVideoVisitApproval
        self.telehealthVisitNoteWorkflow = telehealthVisitNoteWorkflow
        self.listMedicationWorkflowsStep0 = ClosurePort<
            Acme_Patients_V1_CalculateMedicalRecordRequest, Acme_Patients_V1_CalculateMedicalRecordResponse
        >({ request in try await patientsMedicalRecordCalculation.calculateMedicalRecord(request) })
        self.resumeMedicationWorkflowStep0 = { request in
            try await prescriptionsPrescriptionApproval.recallPrescription(request)
        }
        self.resumeMedicationWorkflowStep1 = [
            "primary": { request in try await authorizationAccessPolicyValidation.previewAccessPolicy(request) }
        ]
    }

    /// Advances a medication.
    func advanceMedicationWorkflow(
        request: ServerRequest<Acme_Prescriptions_V1_AdvanceMedicationWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_AdvanceMedicationWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processAdvanceMedicationWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Cancels a medication.
    func cancelMedicationWorkflow(
        request: ServerRequest<Acme_Prescriptions_V1_CancelMedicationWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_CancelMedicationWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCancelMedicationWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a medication.
    func inspectMedicationWorkflow(
        request: ServerRequest<Acme_Prescriptions_V1_InspectMedicationWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_InspectMedicationWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processInspectMedicationWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists medications a page at a time.
    func listMedicationWorkflows(
        request: ServerRequest<Acme_Prescriptions_V1_ListMedicationWorkflowsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ListMedicationWorkflowsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListMedicationWorkflows(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Pauses a medication.
    func pauseMedicationWorkflow(
        request: ServerRequest<Acme_Prescriptions_V1_PauseMedicationWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_PauseMedicationWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processPauseMedicationWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Resumes a medication.
    func resumeMedicationWorkflow(
        request: ServerRequest<Acme_Prescriptions_V1_ResumeMedicationWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ResumeMedicationWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processResumeMedicationWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Retrys a medication.
    func retryMedicationWorkflow(
        request: ServerRequest<Acme_Prescriptions_V1_RetryMedicationWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_RetryMedicationWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRetryMedicationWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Signals a medication.
    func signalMedicationWorkflow(
        request: ServerRequest<Acme_Prescriptions_V1_SignalMedicationWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_SignalMedicationWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSignalMedicationWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Starts a medication.
    func startMedicationWorkflow(
        request: ServerRequest<Acme_Prescriptions_V1_StartMedicationWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_StartMedicationWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processStartMedicationWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processAdvanceMedicationWorkflow(_ input: Acme_Prescriptions_V1_AdvanceMedicationWorkflowRequest) async throws
        -> Acme_Prescriptions_V1_AdvanceMedicationWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "audit", detail: input.details.initiatedBy
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "AdvanceMedicationWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicationRecord(input.medication, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let importFrame = Acme_Careplans_V1_BatchCreateCarePlansRequest.with {
            $0.context = input.context
        }
        _ = try await self.careplansCarePlan.batchCreateCarePlans { writer in
            try await writer.write(importFrame)
        }
        let outbound0 = Acme_Telehealth_V1_RejectVideoVisitRequest.with {
            $0.context = input.context
            $0.details = Acme_Telehealth_V1_RejectVideoVisitRequest.Details.with {
                $0.approver = Acme_Identity_V1_UserRef.with {
                    $0.email = input.details.notify.email
                }
            }
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.medication.audit.createdAt
                }
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.email = input.medication.owner.email
                }
                $0.participants = [
                    Acme_Telehealth_V1_VideoVisitParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.phone = input.details.notify.phone
                        }
                    }
                ]
            }
        }
        let step0: @Sendable () async throws -> Acme_Telehealth_V1_RejectVideoVisitResponse = {
            try await self.telehealthVideoVisitApproval.rejectVideoVisit(outbound0)
        }
        let reply0 = try await step0()
        var outbound1 = Acme_Audit_V1_ListAuditEventsRequest()
        outbound1.context = input.context
        outbound1.filter = Acme_Audit_V1_ListAuditEventsRequest.Filter.with {
            $0.createdAfter = reply0.videoVisit.audit.createdAt
            $0.region = reply0.videoVisit.location.region
        }
        let reply1 = try await self.auditAuditEvent.listAuditEvents(outbound1)
        let outbound2 = Acme_Metrics_V1_ExplainMetricSeriesDecisionRequest.with {
            $0.context = input.context
            $0.metricSeries = Acme_Metrics_V1_MetricSeries.with {
                $0.address = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = reply0.videoVisit.location.postalCode
                }
            }
        }
        let step2: @Sendable () async throws -> Acme_Metrics_V1_ExplainMetricSeriesDecisionResponse = {
            try await self.metricsMetricSeriesValidation.explainMetricSeriesDecision(outbound2)
        }
        let reply2 = try await step2()
        let outbound3 = Acme_Identity_V1_LookupUserRequest.with {
            $0.context = input.context
            $0.userID = input.medication.owner.userID
        }
        let reply3 = try await self.identityUserQuery.lookupUser(outbound3)
        return Acme_Prescriptions_V1_AdvanceMedicationWorkflowResponse.with {
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply3.user.audit.etag
                }
                $0.code = input.medication.code
                $0.medicationID = input.medicationID
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply0.videoVisit.organizer.displayName
                }
            }
            $0.outcome = Acme_Prescriptions_V1_AdvanceMedicationWorkflowResponse.Outcome.with {
                $0.status = reply2.outcome.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply0.result.referenceIds
                $0.status = Projection.firstValue(
                    [
                        reply1.result.status,
                        reply3.result.status,
                    ], default: .init())
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processCancelMedicationWorkflow(_ input: Acme_Prescriptions_V1_CancelMedicationWorkflowRequest) async throws
        -> Acme_Prescriptions_V1_CancelMedicationWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "audit", detail: input.details.initiatedBy
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "CancelMedicationWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicationRecord(input.medication, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let selection0_2: String
        switch input.medication.locator {
        case .address(let address):
            selection0_2 = address.region
        default: selection0_2 = .init()
        }
        let outbound0 = Acme_Telehealth_V1_AdvanceVisitNoteWorkflowRequest.with {
            $0.context = input.context
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = selection0_2
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = input.medication.owner.displayName
                }
            }
        }
        let reply0 = try await self.telehealthVisitNoteWorkflow.advanceVisitNoteWorkflow(outbound0)
        let selection1_3: String
        switch reply0.visitNote.settlement {
        case .card(let card):
            selection1_3 = card.holderName
        default: selection1_3 = .init()
        }
        let outbound1 = Acme_Careplans_V1_ValidateCarePlanRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply0.visitNote.audit.createdAt
                    $0.etag = input.medication.audit.etag
                }
                $0.card = Acme_Careplans_V1_CarePlanCardSettlement.with {
                    $0.holderName = selection1_3
                }
            }
            $0.context = input.context
            $0.details = Acme_Careplans_V1_ValidateCarePlanRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply0.visitNote.counterparty.email
                }
            }
        }
        let reply1 = try await self.careplansCarePlanValidation.validateCarePlan(outbound1)
        let outbound2 = Acme_Prescriptions_V1_StreamPrescriptionMetricsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Prescriptions_V1_StreamPrescriptionMetricsRequest.Filter.with {
                $0.region = input.medication.address.region
            }
            $0.subscriber = Acme_Common_V1_ContactInfo.with {
                $0.email = input.medication.owner.email
                $0.name = input.details.notify.name
                $0.preferredChannel = input.details.notify.preferredChannel
            }
        }
        let reply2 = try await self.prescriptionsPrescriptionReporting.streamPrescriptionMetrics(outbound2) {
            response in
            var latest = Acme_Prescriptions_V1_StreamPrescriptionMetricsResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        _ = reply2
        return Acme_Prescriptions_V1_CancelMedicationWorkflowResponse.with {
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.code = input.medication.code
                $0.medicationID = input.medicationID
            }
            $0.outcome = Acme_Prescriptions_V1_CancelMedicationWorkflowResponse.Outcome.with {
                $0.effectiveAt = reply0.outcome.effectiveAt
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply1.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processInspectMedicationWorkflow(_ input: Acme_Prescriptions_V1_InspectMedicationWorkflowRequest) async throws
        -> Acme_Prescriptions_V1_InspectMedicationWorkflowResponse
    {
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "InspectMedicationWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "InspectMedicationWorkflow", detail: input.context.traceID
        )
        let outbound0 = Acme_Featureflags_V1_CloneFeatureFlagRequest.with {
            $0.context = input.context
            $0.featureFlag = Acme_Featureflags_V1_FeatureFlag.with {
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.context.actor.userID
                }
            }
        }
        async let remote0 = self.featureflagsFeatureFlag.cloneFeatureFlag(outbound0)
        async let persisted0 = store.count(tenant: input.context.tenantID)
        let (reply0, count0) = try await (remote0, persisted0)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count0)])
        return Acme_Prescriptions_V1_InspectMedicationWorkflowResponse.with {
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.medicationID = input.medicationID
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.email = reply0.featureFlag.owner.email
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processListMedicationWorkflows(_ input: Acme_Prescriptions_V1_ListMedicationWorkflowsRequest) async throws
        -> Acme_Prescriptions_V1_ListMedicationWorkflowsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "audit", detail: input.filter.ownerID
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ListMedicationWorkflows",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "ListMedicationWorkflows", detail: input.context.traceID
        )
        let outbound0 = Acme_Patients_V1_CalculateMedicalRecordRequest.with {
            $0.context = input.context
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.email = input.context.actor.email
                }
                $0.dueAt = input.filter.createdAfter
                $0.lines = [
                    Acme_Patients_V1_MedicalRecordLine.with {
                        $0.attributes = input.filter.labels
                    }
                ]
            }
        }
        let reply0 = try await self.listMedicationWorkflowsStep0.execute(outbound0)
        return Acme_Prescriptions_V1_ListMedicationWorkflowsResponse.with {
            $0.medications = [
                Acme_Prescriptions_V1_Medication.with {
                    $0.audit = Acme_Common_V1_AuditInfo.with {
                        $0.createdBy = reply0.medicalRecord.audit.createdBy
                    }
                    $0.owner = Acme_Identity_V1_UserRef.with {
                        $0.displayName = reply0.medicalRecord.counterparty.displayName
                    }
                }
            ]
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processPauseMedicationWorkflow(_ input: Acme_Prescriptions_V1_PauseMedicationWorkflowRequest) async throws
        -> Acme_Prescriptions_V1_PauseMedicationWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "audit", detail: input.details.initiatedBy
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "PauseMedicationWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicationRecord(input.medication, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Prescriptions_V1_GetMedicationApprovalStatusRequest.with {
            $0.context = input.context
            $0.medicationID = input.medicationID
        }
        let port0 = RPCOperations.port { (request: Acme_Prescriptions_V1_GetMedicationApprovalStatusRequest) in
            try await self.prescriptionsMedicationApproval.getMedicationApprovalStatus(request)
        }
        let reply0 = try await port0.execute(outbound0)
        let selection1_2: [String]
        switch input.medication.locator {
        case .address(let address):
            selection1_2 = address.lines
        default: selection1_2 = .init()
        }
        let selection1_3: String
        switch reply0.medication.locator {
        case .address(let address):
            selection1_3 = address.region
        default: selection1_3 = .init()
        }
        let selection1_4: String
        switch input.medication.locator {
        case .address(let address):
            selection1_4 = address.locality
        default: selection1_4 = .init()
        }
        let outbound1 = Acme_Careplans_V1_RejectCarePlanRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = input.medication.audit.updatedBy
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.lines = selection1_2
                    $0.locality = selection1_4
                    $0.region = selection1_3
                }
            }
            $0.context = input.context
        }
        let reply1 = try await self.careplansCarePlanApproval.rejectCarePlan(outbound1)
        return Acme_Prescriptions_V1_PauseMedicationWorkflowResponse.with {
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.medicationID = input.medicationID
                $0.owner = input.medication.owner
                $0.status = reply0.medication.status
            }
            $0.outcome = Acme_Prescriptions_V1_PauseMedicationWorkflowResponse.Outcome.with {
                $0.message = reply1.result.message
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply1.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processResumeMedicationWorkflow(_ input: Acme_Prescriptions_V1_ResumeMedicationWorkflowRequest) async throws
        -> Acme_Prescriptions_V1_ResumeMedicationWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "audit", detail: input.details.initiatedBy
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ResumeMedicationWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicationRecord(input.medication, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Prescriptions_V1_RecallPrescriptionRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_RecallPrescriptionRequest.Details.with {
                $0.approver = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.medication.owner.displayName
                }
            }
        }
        let reply0 = try await self.resumeMedicationWorkflowStep0(outbound0)
        let outbound1 = Acme_Authorization_V1_PreviewAccessPolicyRequest.with {
            $0.accessPolicy = Acme_Authorization_V1_AccessPolicy.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply0.prescription.audit.createdBy
                    $0.updatedBy = reply0.prescription.audit.updatedBy
                }
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.medication.owner.userID
                }
            }
            $0.context = input.context
        }
        guard
            let execute1 = self.resumeMedicationWorkflowStep1[settings.region]
                ?? self.resumeMedicationWorkflowStep1["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply1 = try await execute1(outbound1)
        return Acme_Prescriptions_V1_ResumeMedicationWorkflowResponse.with {
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.capacity = input.medication.capacity
                $0.medicationID = input.medicationID
            }
            $0.outcome = Acme_Prescriptions_V1_ResumeMedicationWorkflowResponse.Outcome.with {
                $0.message = reply1.outcome.message
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processRetryMedicationWorkflow(_ input: Acme_Prescriptions_V1_RetryMedicationWorkflowRequest) async throws
        -> Acme_Prescriptions_V1_RetryMedicationWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "audit", detail: input.details.initiatedBy
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "RetryMedicationWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicationRecord(input.medication, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Prescriptions_V1_ExportPrescriptionsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Prescriptions_V1_ExportPrescriptionsRequest.Filter.with {
                $0.ownerID = input.medication.owner.userID
                $0.region = input.medication.address.region
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
        let selection1_2: String
        switch input.medication.locator {
        case .address(let address):
            selection1_2 = address.postalCode
        default: selection1_2 = .init()
        }
        let outbound1 = Acme_Prescriptions_V1_ResolvePrescriptionConflictRequest.with {
            $0.context = input.context
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = selection1_2
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.email = input.medication.owner.email
                }
            }
        }
        let reply1 = try await self.prescriptionsPrescriptionSync.resolvePrescriptionConflict(outbound1)
        return Acme_Prescriptions_V1_RetryMedicationWorkflowResponse.with {
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply1.prescription.audit.createdAt
                }
                $0.code = input.medication.code
                $0.medicationID = input.medicationID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processSignalMedicationWorkflow(_ input: Acme_Prescriptions_V1_SignalMedicationWorkflowRequest) async throws
        -> Acme_Prescriptions_V1_SignalMedicationWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "audit", detail: input.details.initiatedBy
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "SignalMedicationWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicationRecord(input.medication, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Featureflags_V1_ExportFeatureFlagsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Featureflags_V1_ExportFeatureFlagsRequest.Filter.with {
                $0.createdAfter = input.medication.audit.updatedAt
                $0.labels = input.medication.specs
                $0.region = input.medication.address.region
            }
        }
        let reply0 = try await self.featureflagsFeatureFlagQuery.exportFeatureFlags(outbound0) { response in
            var latest = Acme_Featureflags_V1_ExportFeatureFlagsResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        _ = reply0
        return Acme_Prescriptions_V1_SignalMedicationWorkflowResponse.with {
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.medicationID = input.medicationID
                $0.specs = input.medication.specs
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processStartMedicationWorkflow(_ input: Acme_Prescriptions_V1_StartMedicationWorkflowRequest) async throws
        -> Acme_Prescriptions_V1_StartMedicationWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "audit", detail: input.details.initiatedBy
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "StartMedicationWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicationRecord(input.medication, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let selection0_1: String
        switch input.medication.locator {
        case .address(let address):
            selection0_1 = address.region
        default: selection0_1 = .init()
        }
        let outbound0 = Acme_Patients_V1_BrowseMedicalRecordsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Patients_V1_BrowseMedicalRecordsRequest.Filter.with {
                $0.createdAfter = input.medication.audit.createdAt
                $0.region = selection0_1
            }
        }
        let reply0 = try await self.patientsMedicalRecordQuery.browseMedicalRecords(outbound0)
        return Acme_Prescriptions_V1_StartMedicationWorkflowResponse.with {
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.medicationID = input.medicationID
                $0.specs = input.medication.specs
            }
            $0.outcome = Acme_Prescriptions_V1_StartMedicationWorkflowResponse.Outcome.with {
                $0.status = reply0.result.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }
}
