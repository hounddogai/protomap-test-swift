import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Runs the long-lived workflow that takes a prescription from start to finish.
final class PrescriptionWorkflowEndpoint: Acme_Prescriptions_V1_PrescriptionWorkflowService.ServiceProtocol {
    private let store: any RecordRepository
    private let logger: Logger
    private let settings: Settings
    private let followUps = WorkQueue<Acme_Identity_V1_GetUserRequest>()
    private let careplansCareGoalApproval: Acme_Careplans_V1_CareGoalApprovalService.Client<MeshTransport>
    private let featureflagsFeatureFlag: Acme_Featureflags_V1_FeatureFlagService.Client<MeshTransport>
    private let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    private let onboardingOnboardingPlanQuery: Acme_Onboarding_V1_OnboardingPlanQueryService.Client<MeshTransport>
    private let patientsMedicalRecordQuery: Acme_Patients_V1_MedicalRecordQueryService.Client<MeshTransport>
    private let patientsPatientValidation: Acme_Patients_V1_PatientValidationService.Client<MeshTransport>
    private let prescriptionsMedicationApproval: Acme_Prescriptions_V1_MedicationApprovalService.Client<MeshTransport>
    private let prescriptionsMedicationQuery: Acme_Prescriptions_V1_MedicationQueryService.Client<MeshTransport>
    private let prescriptionsMedicationSync: Acme_Prescriptions_V1_MedicationSyncService.Client<MeshTransport>
    private let prescriptionsPrescriptionApproval:
        Acme_Prescriptions_V1_PrescriptionApprovalService.Client<MeshTransport>
    private let prescriptionsPrescriptionReporting:
        Acme_Prescriptions_V1_PrescriptionReportingService.Client<MeshTransport>
    private let prescriptionsRefillReporting: Acme_Prescriptions_V1_RefillReportingService.Client<MeshTransport>
    private let prescriptionsRefillSync: Acme_Prescriptions_V1_RefillSyncService.Client<MeshTransport>
    private let prescriptionsRefillValidation: Acme_Prescriptions_V1_RefillValidationService.Client<MeshTransport>
    private let telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client<MeshTransport>
    private let telehealthVisitNoteApproval: Acme_Telehealth_V1_VisitNoteApprovalService.Client<MeshTransport>
    private let telehealthVisitNoteWorkflow: Acme_Telehealth_V1_VisitNoteWorkflowService.Client<MeshTransport>
    private let retryPrescriptionWorkflowStep2:
        any RPCPort<Acme_Prescriptions_V1_SubmitPrescriptionRequest, Acme_Prescriptions_V1_SubmitPrescriptionResponse>
    private let signalPrescriptionWorkflowStep0:
        @Sendable (Acme_Prescriptions_V1_CheckRefillEligibilityRequest) async throws ->
            Acme_Prescriptions_V1_CheckRefillEligibilityResponse
    private let signalPrescriptionWorkflowStep1:
        [String:
            @Sendable (Acme_Prescriptions_V1_ShareRefillReportRequest) async throws ->
            Acme_Prescriptions_V1_ShareRefillReportResponse]

    init(
        dependencies: any Dependencies,
        careplansCareGoalApproval: Acme_Careplans_V1_CareGoalApprovalService.Client<MeshTransport>,
        featureflagsFeatureFlag: Acme_Featureflags_V1_FeatureFlagService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        onboardingOnboardingPlanQuery: Acme_Onboarding_V1_OnboardingPlanQueryService.Client<MeshTransport>,
        patientsMedicalRecordQuery: Acme_Patients_V1_MedicalRecordQueryService.Client<MeshTransport>,
        patientsPatientValidation: Acme_Patients_V1_PatientValidationService.Client<MeshTransport>,
        prescriptionsMedicationApproval: Acme_Prescriptions_V1_MedicationApprovalService.Client<MeshTransport>,
        prescriptionsMedicationQuery: Acme_Prescriptions_V1_MedicationQueryService.Client<MeshTransport>,
        prescriptionsMedicationSync: Acme_Prescriptions_V1_MedicationSyncService.Client<MeshTransport>,
        prescriptionsPrescriptionApproval: Acme_Prescriptions_V1_PrescriptionApprovalService.Client<MeshTransport>,
        prescriptionsPrescriptionReporting: Acme_Prescriptions_V1_PrescriptionReportingService.Client<MeshTransport>,
        prescriptionsRefillReporting: Acme_Prescriptions_V1_RefillReportingService.Client<MeshTransport>,
        prescriptionsRefillSync: Acme_Prescriptions_V1_RefillSyncService.Client<MeshTransport>,
        prescriptionsRefillValidation: Acme_Prescriptions_V1_RefillValidationService.Client<MeshTransport>,
        telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client<MeshTransport>,
        telehealthVisitNoteApproval: Acme_Telehealth_V1_VisitNoteApprovalService.Client<MeshTransport>,
        telehealthVisitNoteWorkflow: Acme_Telehealth_V1_VisitNoteWorkflowService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.careplansCareGoalApproval = careplansCareGoalApproval
        self.featureflagsFeatureFlag = featureflagsFeatureFlag
        self.identityUser = identityUser
        self.onboardingOnboardingPlanQuery = onboardingOnboardingPlanQuery
        self.patientsMedicalRecordQuery = patientsMedicalRecordQuery
        self.patientsPatientValidation = patientsPatientValidation
        self.prescriptionsMedicationApproval = prescriptionsMedicationApproval
        self.prescriptionsMedicationQuery = prescriptionsMedicationQuery
        self.prescriptionsMedicationSync = prescriptionsMedicationSync
        self.prescriptionsPrescriptionApproval = prescriptionsPrescriptionApproval
        self.prescriptionsPrescriptionReporting = prescriptionsPrescriptionReporting
        self.prescriptionsRefillReporting = prescriptionsRefillReporting
        self.prescriptionsRefillSync = prescriptionsRefillSync
        self.prescriptionsRefillValidation = prescriptionsRefillValidation
        self.telehealthVideoVisit = telehealthVideoVisit
        self.telehealthVisitNoteApproval = telehealthVisitNoteApproval
        self.telehealthVisitNoteWorkflow = telehealthVisitNoteWorkflow
        self.retryPrescriptionWorkflowStep2 = ClosurePort<
            Acme_Prescriptions_V1_SubmitPrescriptionRequest, Acme_Prescriptions_V1_SubmitPrescriptionResponse
        >({ request in try await prescriptionsPrescriptionApproval.submitPrescription(request) })
        self.signalPrescriptionWorkflowStep0 = { request in
            try await prescriptionsRefillValidation.checkRefillEligibility(request)
        }
        self.signalPrescriptionWorkflowStep1 = [
            "primary": { request in try await prescriptionsRefillReporting.shareRefillReport(request) }
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

    /// Advances a prescription.
    func advancePrescriptionWorkflow(
        request: ServerRequest<Acme_Prescriptions_V1_AdvancePrescriptionWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_AdvancePrescriptionWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processAdvancePrescriptionWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a prescription.
    func inspectPrescriptionWorkflow(
        request: ServerRequest<Acme_Prescriptions_V1_InspectPrescriptionWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_InspectPrescriptionWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processInspectPrescriptionWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists prescriptions a page at a time.
    func listPrescriptionWorkflows(
        request: ServerRequest<Acme_Prescriptions_V1_ListPrescriptionWorkflowsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ListPrescriptionWorkflowsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListPrescriptionWorkflows(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Pauses a prescription.
    func pausePrescriptionWorkflow(
        request: ServerRequest<Acme_Prescriptions_V1_PausePrescriptionWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_PausePrescriptionWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processPausePrescriptionWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Resumes a prescription.
    func resumePrescriptionWorkflow(
        request: ServerRequest<Acme_Prescriptions_V1_ResumePrescriptionWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ResumePrescriptionWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processResumePrescriptionWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Retrys a prescription.
    func retryPrescriptionWorkflow(
        request: ServerRequest<Acme_Prescriptions_V1_RetryPrescriptionWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_RetryPrescriptionWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRetryPrescriptionWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Signals a prescription.
    func signalPrescriptionWorkflow(
        request: ServerRequest<Acme_Prescriptions_V1_SignalPrescriptionWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_SignalPrescriptionWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSignalPrescriptionWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Starts a prescription.
    func startPrescriptionWorkflow(
        request: ServerRequest<Acme_Prescriptions_V1_StartPrescriptionWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_StartPrescriptionWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processStartPrescriptionWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processAdvancePrescriptionWorkflow(_ input: Acme_Prescriptions_V1_AdvancePrescriptionWorkflowRequest)
        async throws -> Acme_Prescriptions_V1_AdvancePrescriptionWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "audit", detail: input.details.initiatedBy
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "AdvancePrescriptionWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PrescriptionRecord(input.prescription, tenant: input.context.tenantID)
        try await store.save(record.stored)
        try followUps.submit(
            Acme_Identity_V1_GetUserRequest.with {
                $0.context = input.context
                $0.userID = input.context.actor.userID
            })
        let importFrame = Acme_Telehealth_V1_BatchCreateVideoVisitsRequest.with {
            $0.context = input.context
        }
        _ = try await self.telehealthVideoVisit.batchCreateVideoVisits { writer in
            try await writer.write(importFrame)
        }
        let outbound0 = Acme_Prescriptions_V1_ResolveMedicationConflictRequest.with {
            $0.context = input.context
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.address = Acme_Common_V1_PostalAddress.with {
                    $0.lines = input.prescription.billingAddress.lines
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = input.prescription.audit.etag
                    $0.updatedBy = input.prescription.audit.updatedBy
                }
            }
        }
        let json0 = try outbound0.jsonString()
        let decoded0 = try Acme_Prescriptions_V1_ResolveMedicationConflictRequest(jsonString: json0)
        let reply0 = try await self.prescriptionsMedicationSync.resolveMedicationConflict(decoded0)
        let outbound1 =
            Acme_Prescriptions_V1_SuggestMedicationsRequest.forPrescriptionWorkflowEndpointAdvancePrescriptionWorkflow1(
                input,
                reply0: reply0
            )
        let reply1 = try await self.prescriptionsMedicationQuery.suggestMedications(outbound1)
        let outbound2 = Acme_Featureflags_V1_CreateFeatureFlagRequest.with {
            $0.context = input.context
            $0.featureFlag = Acme_Featureflags_V1_FeatureFlag.with {
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.email = input.prescription.counterparty.email
                }
            }
        }
        let reply2 = try await self.featureflagsFeatureFlag.createFeatureFlag(
            outbound2, metadata: ["x-acme-region": .string(settings.region)]
        )
        return Acme_Prescriptions_V1_AdvancePrescriptionWorkflowResponse.with {
            $0.outcome = Acme_Prescriptions_V1_AdvancePrescriptionWorkflowResponse.Outcome.with {
                $0.status = reply0.outcome.status
            }
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply2.featureFlag.audit.etag
                }
                $0.notes = input.prescription.notes
                $0.prescriptionID = input.prescriptionID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.message = Projection.firstValue(
                    [
                        reply0.result.message,
                        reply1.result.message,
                    ], default: .init())
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processInspectPrescriptionWorkflow(_ input: Acme_Prescriptions_V1_InspectPrescriptionWorkflowRequest)
        async throws -> Acme_Prescriptions_V1_InspectPrescriptionWorkflowResponse
    {
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "InspectPrescriptionWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "InspectPrescriptionWorkflow", detail: input.context.traceID
        )
        let outbound0 = Acme_Onboarding_V1_ResolveOnboardingPlansRequest.with {
            $0.context = input.context
        }
        let reply0 = try await RPCOperations.call(outbound0) { request in
            try await self.onboardingOnboardingPlanQuery.resolveOnboardingPlans(request)
        }
        return Acme_Prescriptions_V1_InspectPrescriptionWorkflowResponse.with {
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.prescriptionID = input.prescriptionID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply0.result.referenceIds
                $0.status = reply0.result.status
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processListPrescriptionWorkflows(_ input: Acme_Prescriptions_V1_ListPrescriptionWorkflowsRequest) async throws
        -> Acme_Prescriptions_V1_ListPrescriptionWorkflowsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "audit", detail: input.filter.ownerID
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ListPrescriptionWorkflows",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "ListPrescriptionWorkflows", detail: input.context.traceID
        )
        let outbound0 = Acme_Telehealth_V1_StartVisitNoteWorkflowRequest.with {
            $0.annotations = input.filter.labels
            $0.context = Projection.read(input, at: \Acme_Prescriptions_V1_ListPrescriptionWorkflowsRequest.context)
            $0.details = Acme_Telehealth_V1_StartVisitNoteWorkflowRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.email = Projection.read(
                        input, at: \Acme_Prescriptions_V1_ListPrescriptionWorkflowsRequest.context.actor.email)
                }
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = Projection.read(
                        input, at: \Acme_Prescriptions_V1_ListPrescriptionWorkflowsRequest.filter.region)
                }
                $0.dueAt = Projection.read(
                    input, at: \Acme_Prescriptions_V1_ListPrescriptionWorkflowsRequest.filter.createdAfter)
            }
        }
        let reply0 = try await self.telehealthVisitNoteWorkflow.startVisitNoteWorkflow(outbound0)
        return Acme_Prescriptions_V1_ListPrescriptionWorkflowsResponse.with {
            $0.prescriptions = [
                Acme_Prescriptions_V1_Prescription.with {
                    $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                        $0.postalCode = reply0.visitNote.billingAddress.postalCode
                    }
                }
            ]
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processPausePrescriptionWorkflow(_ input: Acme_Prescriptions_V1_PausePrescriptionWorkflowRequest) async throws
        -> Acme_Prescriptions_V1_PausePrescriptionWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "audit", detail: input.details.initiatedBy
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "PausePrescriptionWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PrescriptionRecord(input.prescription, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Prescriptions_V1_GeneratePrescriptionReportRequest.with {
            $0.annotations = input.annotations
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_GeneratePrescriptionReportRequest.Details.with {
                $0.filters = input.details.parameters
            }
            $0.prescriptionID = input.prescription.prescriptionID
            $0.reason = input.reason
        }
        let step0: @Sendable () async throws -> Acme_Prescriptions_V1_GeneratePrescriptionReportResponse = {
            try await self.prescriptionsPrescriptionReporting.generatePrescriptionReport(outbound0)
        }
        let reply0 = try await step0()
        let selection1_2: String
        switch input.prescription.settlement {
        case .bank(let bank):
            selection1_2 = bank.accountHolder
        default: selection1_2 = .init()
        }
        let outbound1 = Acme_Telehealth_V1_ApproveVisitNoteRequest.with {
            $0.context = input.context
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.bank = Acme_Telehealth_V1_VisitNoteBankSettlement.with {
                    $0.accountHolder = selection1_2
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.lines = input.prescription.billingAddress.lines
                }
            }
        }
        let reply1 = try await self.telehealthVisitNoteApproval.approveVisitNote(outbound1)
        return Acme_Prescriptions_V1_PausePrescriptionWorkflowResponse.with {
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply1.visitNote.audit.etag
                }
                $0.dueAt = input.prescription.dueAt
                $0.prescriptionID = input.prescriptionID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processResumePrescriptionWorkflow(_ input: Acme_Prescriptions_V1_ResumePrescriptionWorkflowRequest)
        async throws -> Acme_Prescriptions_V1_ResumePrescriptionWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "audit", detail: input.details.initiatedBy
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ResumePrescriptionWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PrescriptionRecord(input.prescription, tenant: input.context.tenantID)
        try await store.save(record.stored)
        var outbound0 = Acme_Careplans_V1_ApproveCareGoalRequest()
        outbound0.careGoal = Acme_Careplans_V1_CareGoal.with {
            $0.assignee = Acme_Identity_V1_UserRef.with {
                $0.displayName = input.prescription.counterparty.displayName
                $0.email = input.details.notify.email
            }
            $0.audit = Acme_Common_V1_AuditInfo.with {
                $0.updatedAt = input.prescription.audit.updatedAt
            }
        }
        outbound0.context = input.context
        let reply0 = try await self.careplansCareGoalApproval.approveCareGoal(outbound0)
        let outbound1 = Acme_Prescriptions_V1_ListRefillConflictsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Prescriptions_V1_ListRefillConflictsRequest.Filter.with {
                $0.region = input.prescription.billingAddress.region
            }
        }
        let reply1 = try await RPCOperations.read {
            try await self.prescriptionsRefillSync.listRefillConflicts(outbound1)
        }
        let selection2_1: String
        switch reply0.careGoal.origin {
        case .customer(let customer):
            selection2_1 = customer.displayName
        default: selection2_1 = .init()
        }
        let outbound2 = Acme_Prescriptions_V1_ResolveMedicationConflictRequest.with {
            $0.context = input.context
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.displayName = selection2_1
                }
            }
        }
        let reply2 = try await self.prescriptionsMedicationSync.resolveMedicationConflict(outbound2)
        return Acme_Prescriptions_V1_ResumePrescriptionWorkflowResponse.with {
            $0.outcome = Acme_Prescriptions_V1_ResumePrescriptionWorkflowResponse.Outcome.with {
                $0.nextSteps = reply2.outcome.nextSteps
                $0.status = reply1.result.status
            }
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.email = reply0.careGoal.customer.email
                }
                $0.notes = input.prescription.notes
                $0.prescriptionID = input.prescriptionID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processRetryPrescriptionWorkflow(_ input: Acme_Prescriptions_V1_RetryPrescriptionWorkflowRequest) async throws
        -> Acme_Prescriptions_V1_RetryPrescriptionWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "audit", detail: input.details.initiatedBy
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "RetryPrescriptionWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PrescriptionRecord(input.prescription, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Featureflags_V1_ListFeatureFlagsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Featureflags_V1_ListFeatureFlagsRequest.Filter.with {
                $0.createdAfter = input.prescription.dueAt
                $0.labels = input.details.parameters
                $0.ownerID = input.prescription.counterparty.patientID
                $0.region = input.prescription.billingAddress.region
            }
        }
        let reply0 = try await self.featureflagsFeatureFlag.listFeatureFlags(outbound0)
        let outbound1 = Acme_Patients_V1_PreviewPatientRequest.with {
            $0.context = input.context
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.prescription.audit.createdAt
                }
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.preferredChannel = input.details.notify.preferredChannel
                }
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.locality = input.prescription.billingAddress.locality
                }
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.email = input.details.notify.email
                }
            }
        }
        async let remote1 = self.patientsPatientValidation.previewPatient(outbound1)
        async let persisted1 = store.count(tenant: input.context.tenantID)
        let (reply1, count1) = try await (remote1, persisted1)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count1)])
        let outbound2 = Acme_Prescriptions_V1_SubmitPrescriptionRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_SubmitPrescriptionRequest.Details.with {
                $0.approver = Acme_Identity_V1_UserRef.with {
                    $0.email = input.prescription.counterparty.email
                }
            }
        }
        let reply2 = try await self.retryPrescriptionWorkflowStep2.execute(outbound2)
        let outbound3 = Acme_Prescriptions_V1_RejectMedicationRequest.with {
            $0.context = input.context
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = input.prescription.audit.updatedBy
                }
            }
        }
        let port3 = RPCOperations.port { (request: Acme_Prescriptions_V1_RejectMedicationRequest) in
            try await self.prescriptionsMedicationApproval.rejectMedication(request)
        }
        let reply3 = try await port3.execute(outbound3)
        return Acme_Prescriptions_V1_RetryPrescriptionWorkflowResponse.with {
            $0.outcome = Acme_Prescriptions_V1_RetryPrescriptionWorkflowResponse.Outcome.with {
                $0.status = reply2.outcome.status
            }
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply1.patient.audit.createdAt
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.lines = reply3.medication.address.lines
                }
                $0.counterparty = reply2.prescription.counterparty
                $0.metadata = input.prescription.metadata
                $0.prescriptionID = input.prescriptionID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = Projection.firstValue(
                    [
                        reply0.result.correlationID,
                        reply3.result.correlationID,
                    ], default: .init())
                $0.status = Projection.firstValue(
                    [
                        reply0.result.status,
                        reply1.result.status,
                    ], default: .init())
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processSignalPrescriptionWorkflow(_ input: Acme_Prescriptions_V1_SignalPrescriptionWorkflowRequest)
        async throws -> Acme_Prescriptions_V1_SignalPrescriptionWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "audit", detail: input.details.initiatedBy
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "SignalPrescriptionWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PrescriptionRecord(input.prescription, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Prescriptions_V1_CheckRefillEligibilityRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_CheckRefillEligibilityRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.phone = input.details.notify.phone
                }
            }
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.prescription.counterparty.displayName
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.prescription.counterparty.email
                }
            }
        }
        let reply0 = try await self.signalPrescriptionWorkflowStep0(outbound0)
        let outbound1 = Acme_Prescriptions_V1_ShareRefillReportRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_ShareRefillReportRequest.Details.with {
                $0.recipient = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.notify.email
                    $0.name = input.details.notify.name
                    $0.phone = input.details.notify.phone
                    $0.preferredChannel = reply0.refill.requester.preferredChannel
                }
            }
        }
        guard
            let execute1 = self.signalPrescriptionWorkflowStep1[settings.region]
                ?? self.signalPrescriptionWorkflowStep1["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply1 = try await execute1(outbound1)
        let outbound2 = Acme_Patients_V1_SummarizeMedicalRecordsRequest.with {
            $0.annotations = input.annotations
            $0.context = input.context
            $0.reason = input.reason
        }
        let reply2 = try await self.patientsMedicalRecordQuery.summarizeMedicalRecords(outbound2)
        return Acme_Prescriptions_V1_SignalPrescriptionWorkflowResponse.with {
            $0.outcome = Acme_Prescriptions_V1_SignalPrescriptionWorkflowResponse.Outcome.with {
                $0.message = reply2.result.message
            }
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = reply0.refill.customer.displayName
                    $0.email = reply1.refill.requester.email
                }
                $0.notes = input.prescription.notes
                $0.prescriptionID = input.prescriptionID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply2.result.correlationID
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processStartPrescriptionWorkflow(_ input: Acme_Prescriptions_V1_StartPrescriptionWorkflowRequest) async throws
        -> Acme_Prescriptions_V1_StartPrescriptionWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "audit", detail: input.details.initiatedBy
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "StartPrescriptionWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PrescriptionRecord(input.prescription, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Onboarding_V1_FindOnboardingPlansRequest.with {
            $0.context = input.context
            $0.filter = Acme_Onboarding_V1_FindOnboardingPlansRequest.Filter.with {
                $0.createdAfter = input.prescription.audit.updatedAt
                $0.ownerID = input.prescription.counterparty.patientID
                $0.region = input.prescription.billingAddress.region
            }
        }
        let envelope0 = try Google_Protobuf_Any(message: outbound0)
        let unpacked0 = try Acme_Onboarding_V1_FindOnboardingPlansRequest(unpackingAny: envelope0)
        let reply0 = try await self.onboardingOnboardingPlanQuery.findOnboardingPlans(unpacked0)
        return Acme_Prescriptions_V1_StartPrescriptionWorkflowResponse.with {
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.counterparty = input.prescription.counterparty
                $0.prescriptionID = input.prescriptionID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply0.result.status
            }
        }
    }
}
