import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Routes medical records through approval, with escalation and delegation.
final class MedicalRecordApprovalEndpoint: Acme_Patients_V1_MedicalRecordApprovalService.ServiceProtocol {
    private let store: any RecordRepository
    private let logger: Logger
    private let settings: Settings
    private let appointmentsClinicSlotApproval: Acme_Appointments_V1_ClinicSlotApprovalService.Client<MeshTransport>
    private let careplansVitalApproval: Acme_Careplans_V1_VitalApprovalService.Client<MeshTransport>
    private let featureflagsFeatureFlag: Acme_Featureflags_V1_FeatureFlagService.Client<MeshTransport>
    private let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    private let identityUserValidation: Acme_Identity_V1_UserValidationService.Client<MeshTransport>
    private let ledgerLedgerAccountValidation: Acme_Ledger_V1_LedgerAccountValidationService.Client<MeshTransport>
    private let metricsMetricSeriesQuery: Acme_Metrics_V1_MetricSeriesQueryService.Client<MeshTransport>
    private let notificationsNotificationValidation:
        Acme_Notifications_V1_NotificationValidationService.Client<MeshTransport>
    private let onboardingOnboardingPlanQuery: Acme_Onboarding_V1_OnboardingPlanQueryService.Client<MeshTransport>
    private let patientsAllergyImport: Acme_Patients_V1_AllergyImportService.Client<MeshTransport>
    private let patientsMedicalRecordLifecycle: Acme_Patients_V1_MedicalRecordLifecycleService.Client<MeshTransport>
    private let patientsMedicalRecordReporting: Acme_Patients_V1_MedicalRecordReportingService.Client<MeshTransport>
    private let patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client<MeshTransport>
    private let patientsPatientSync: Acme_Patients_V1_PatientSyncService.Client<MeshTransport>
    private let prescriptionsPrescription: Acme_Prescriptions_V1_PrescriptionService.Client<MeshTransport>
    private let prescriptionsRefillReporting: Acme_Prescriptions_V1_RefillReportingService.Client<MeshTransport>
    private let toursTourQuery: Acme_Tours_V1_TourQueryService.Client<MeshTransport>
    private let getMedicalRecordApprovalStatusStep1:
        any RPCPort<
            Acme_Patients_V1_DeleteMedicalRecordReportRequest, Acme_Patients_V1_DeleteMedicalRecordReportResponse
        >
    private let rejectMedicalRecordStep0:
        @Sendable (Acme_Patients_V1_ExpireMedicalRecordRequest) async throws ->
            Acme_Patients_V1_ExpireMedicalRecordResponse
    private let rejectMedicalRecordStep1:
        [String:
            @Sendable (Acme_Onboarding_V1_ResolveOnboardingPlansRequest) async throws ->
            Acme_Onboarding_V1_ResolveOnboardingPlansResponse]

    init(
        dependencies: any Dependencies,
        appointmentsClinicSlotApproval: Acme_Appointments_V1_ClinicSlotApprovalService.Client<MeshTransport>,
        careplansVitalApproval: Acme_Careplans_V1_VitalApprovalService.Client<MeshTransport>,
        featureflagsFeatureFlag: Acme_Featureflags_V1_FeatureFlagService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        identityUserValidation: Acme_Identity_V1_UserValidationService.Client<MeshTransport>,
        ledgerLedgerAccountValidation: Acme_Ledger_V1_LedgerAccountValidationService.Client<MeshTransport>,
        metricsMetricSeriesQuery: Acme_Metrics_V1_MetricSeriesQueryService.Client<MeshTransport>,
        notificationsNotificationValidation: Acme_Notifications_V1_NotificationValidationService.Client<MeshTransport>,
        onboardingOnboardingPlanQuery: Acme_Onboarding_V1_OnboardingPlanQueryService.Client<MeshTransport>,
        patientsAllergyImport: Acme_Patients_V1_AllergyImportService.Client<MeshTransport>,
        patientsMedicalRecordLifecycle: Acme_Patients_V1_MedicalRecordLifecycleService.Client<MeshTransport>,
        patientsMedicalRecordReporting: Acme_Patients_V1_MedicalRecordReportingService.Client<MeshTransport>,
        patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client<MeshTransport>,
        patientsPatientSync: Acme_Patients_V1_PatientSyncService.Client<MeshTransport>,
        prescriptionsPrescription: Acme_Prescriptions_V1_PrescriptionService.Client<MeshTransport>,
        prescriptionsRefillReporting: Acme_Prescriptions_V1_RefillReportingService.Client<MeshTransport>,
        toursTourQuery: Acme_Tours_V1_TourQueryService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.appointmentsClinicSlotApproval = appointmentsClinicSlotApproval
        self.careplansVitalApproval = careplansVitalApproval
        self.featureflagsFeatureFlag = featureflagsFeatureFlag
        self.identityUser = identityUser
        self.identityUserValidation = identityUserValidation
        self.ledgerLedgerAccountValidation = ledgerLedgerAccountValidation
        self.metricsMetricSeriesQuery = metricsMetricSeriesQuery
        self.notificationsNotificationValidation = notificationsNotificationValidation
        self.onboardingOnboardingPlanQuery = onboardingOnboardingPlanQuery
        self.patientsAllergyImport = patientsAllergyImport
        self.patientsMedicalRecordLifecycle = patientsMedicalRecordLifecycle
        self.patientsMedicalRecordReporting = patientsMedicalRecordReporting
        self.patientsPatientQuery = patientsPatientQuery
        self.patientsPatientSync = patientsPatientSync
        self.prescriptionsPrescription = prescriptionsPrescription
        self.prescriptionsRefillReporting = prescriptionsRefillReporting
        self.toursTourQuery = toursTourQuery
        self.getMedicalRecordApprovalStatusStep1 = ClosurePort<
            Acme_Patients_V1_DeleteMedicalRecordReportRequest, Acme_Patients_V1_DeleteMedicalRecordReportResponse
        >({ request in try await patientsMedicalRecordReporting.deleteMedicalRecordReport(request) })
        self.rejectMedicalRecordStep0 = { request in
            try await patientsMedicalRecordLifecycle.expireMedicalRecord(request)
        }
        self.rejectMedicalRecordStep1 = [
            "primary": { request in try await onboardingOnboardingPlanQuery.resolveOnboardingPlans(request) }
        ]
    }

    /// Approves a medical record.
    func approveMedicalRecord(
        request: ServerRequest<Acme_Patients_V1_ApproveMedicalRecordRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_ApproveMedicalRecordResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processApproveMedicalRecord(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Comments a medical record.
    func commentMedicalRecordApproval(
        request: ServerRequest<Acme_Patients_V1_CommentMedicalRecordApprovalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_CommentMedicalRecordApprovalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCommentMedicalRecordApproval(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Delegates a medical record.
    func delegateMedicalRecordApproval(
        request: ServerRequest<Acme_Patients_V1_DelegateMedicalRecordApprovalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_DelegateMedicalRecordApprovalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processDelegateMedicalRecordApproval(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Escalates a medical record.
    func escalateMedicalRecord(
        request: ServerRequest<Acme_Patients_V1_EscalateMedicalRecordRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_EscalateMedicalRecordResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processEscalateMedicalRecord(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a medical record.
    func getMedicalRecordApprovalStatus(
        request: ServerRequest<Acme_Patients_V1_GetMedicalRecordApprovalStatusRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_GetMedicalRecordApprovalStatusResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetMedicalRecordApprovalStatus(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists medical records a page at a time.
    func listPendingMedicalRecords(
        request: ServerRequest<Acme_Patients_V1_ListPendingMedicalRecordsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_ListPendingMedicalRecordsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListPendingMedicalRecords(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Recalls a medical record.
    func recallMedicalRecord(
        request: ServerRequest<Acme_Patients_V1_RecallMedicalRecordRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_RecallMedicalRecordResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRecallMedicalRecord(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Rejects a medical record.
    func rejectMedicalRecord(
        request: ServerRequest<Acme_Patients_V1_RejectMedicalRecordRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_RejectMedicalRecordResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRejectMedicalRecord(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Submits a medical record.
    func submitMedicalRecord(
        request: ServerRequest<Acme_Patients_V1_SubmitMedicalRecordRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_SubmitMedicalRecordResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSubmitMedicalRecord(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processApproveMedicalRecord(_ input: Acme_Patients_V1_ApproveMedicalRecordRequest) async throws
        -> Acme_Patients_V1_ApproveMedicalRecordResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "audit", detail: input.details.approver.displayName
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ApproveMedicalRecord",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicalRecordRecord(input.medicalRecord, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let importFrame = Acme_Prescriptions_V1_BatchCreatePrescriptionsRequest.with {
            $0.context = input.context
        }
        _ = try await self.prescriptionsPrescription.batchCreatePrescriptions { writer in
            try await writer.write(importFrame)
        }
        let outbound0 = Acme_Careplans_V1_CommentVitalApprovalRequest.with {
            $0.context = input.context
            $0.details = Acme_Careplans_V1_CommentVitalApprovalRequest.Details.with {
                $0.approver = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.medicalRecord.counterparty.displayName
                    $0.userID = input.details.approver.userID
                }
                $0.conditions = input.details.conditions
                $0.effectiveAt = input.details.effectiveAt
            }
        }
        let reply0 = try await self.careplansVitalApproval.commentVitalApproval(outbound0)
        let outbound1 = Acme_Notifications_V1_ExplainNotificationDecisionRequest.with {
            $0.context = input.context
            $0.notification = Acme_Notifications_V1_Notification.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.medicalRecord.counterparty.displayName
                    $0.email = input.medicalRecord.counterparty.email
                }
            }
        }
        let envelope1 = try Google_Protobuf_Any(message: outbound1)
        let unpacked1 = try Acme_Notifications_V1_ExplainNotificationDecisionRequest(unpackingAny: envelope1)
        let reply1 = try await self.notificationsNotificationValidation.explainNotificationDecision(unpacked1)
        let outbound2 = Acme_Featureflags_V1_BatchCreateFeatureFlagsRequest.with {
            $0.context = input.context
            $0.record = Acme_Featureflags_V1_FeatureFlag.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = input.medicalRecord.audit.updatedAt
                    $0.updatedBy = input.medicalRecord.audit.updatedBy
                }
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.medicalRecord.counterparty.displayName
                    $0.userID = input.details.approver.userID
                }
            }
        }
        let reply2 = try await self.featureflagsFeatureFlag.batchCreateFeatureFlags { writer in
            try await writer.write(outbound2)
        }
        _ = reply2
        return Acme_Patients_V1_ApproveMedicalRecordResponse.with {
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.issuedAt = input.medicalRecord.issuedAt
                $0.medicalRecordID = input.medicalRecordID
            }
            $0.outcome = Acme_Patients_V1_ApproveMedicalRecordResponse.Outcome.with {
                $0.referenceID = reply1.outcome.referenceID
                $0.status = reply0.outcome.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.status = reply0.outcome.status
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processCommentMedicalRecordApproval(_ input: Acme_Patients_V1_CommentMedicalRecordApprovalRequest) async throws
        -> Acme_Patients_V1_CommentMedicalRecordApprovalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "audit", detail: input.details.approver.displayName
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "CommentMedicalRecordApproval",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicalRecordRecord(input.medicalRecord, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Patients_V1_BrowsePatientsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Patients_V1_BrowsePatientsRequest.Filter.with {
                $0.region = input.medicalRecord.billingAddress.region
            }
        }
        let json0 = try outbound0.jsonString()
        let decoded0 = try Acme_Patients_V1_BrowsePatientsRequest(jsonString: json0)
        let reply0 = try await self.patientsPatientQuery.browsePatients(decoded0)
        let outbound1 =
            Acme_Featureflags_V1_CreateFeatureFlagRequest.forMedicalRecordApprovalEndpointCommentMedicalRecordApproval1(
                input
            )
        let reply1 = try await self.featureflagsFeatureFlag.createFeatureFlag(outbound1)
        return Acme_Patients_V1_CommentMedicalRecordApprovalResponse.with {
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.billingAddress = input.medicalRecord.billingAddress
                $0.lines = [
                    Acme_Patients_V1_MedicalRecordLine.with {
                        $0.amount = reply1.featureFlag.discount.amount
                    }
                ]
                $0.medicalRecordID = input.medicalRecordID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = Projection.firstValue(
                    [
                        reply0.result.correlationID,
                        reply1.result.correlationID,
                    ], default: .init())
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processDelegateMedicalRecordApproval(_ input: Acme_Patients_V1_DelegateMedicalRecordApprovalRequest)
        async throws -> Acme_Patients_V1_DelegateMedicalRecordApprovalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approverEmail)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "audit", detail: input.details.approverEmail
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "DelegateMedicalRecordApproval",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicalRecordRecord(input.medicalRecord, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Careplans_V1_SubmitVitalRequest.with {
            $0.context = input.context
            $0.details = Acme_Careplans_V1_SubmitVitalRequest.Details.with {
                $0.approver = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.details.approver.displayName
                }
            }
        }
        let reply0 = try await self.careplansVitalApproval.submitVital(
            outbound0, metadata: ["x-acme-region": .string(settings.region)]
        )
        let outbound1 = Acme_Tours_V1_FindToursRequest.with {
            $0.context = input.context
            $0.filter = Acme_Tours_V1_FindToursRequest.Filter.with {
                $0.createdAfter = input.medicalRecord.audit.updatedAt
                $0.labels = reply0.result.details
                $0.ownerID = input.details.approver.userID
                $0.region = input.medicalRecord.billingAddress.region
            }
        }
        let reply1 = try await RPCOperations.call(outbound1) { request in
            try await self.toursTourQuery.findTours(request)
        }
        let outbound2 = Acme_Prescriptions_V1_StreamRefillMetricsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Prescriptions_V1_StreamRefillMetricsRequest.Filter.with {
                $0.region = input.medicalRecord.billingAddress.region
            }
            $0.subscriber = Acme_Common_V1_ContactInfo.with {
                $0.email = input.details.approver.email
            }
        }
        let reply2 = try await self.prescriptionsRefillReporting.streamRefillMetrics(outbound2) { response in
            var latest = Acme_Prescriptions_V1_StreamRefillMetricsResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        _ = reply2
        let outbound3 = Acme_Appointments_V1_DelegateClinicSlotApprovalRequest.with {
            $0.clinicSlot = Acme_Appointments_V1_ClinicSlot.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = Projection.read(
                        input, at: \Acme_Patients_V1_DelegateMedicalRecordApprovalRequest.medicalRecord.audit.etag)
                }
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.displayName = Projection.read(
                        input, at: \Acme_Patients_V1_DelegateMedicalRecordApprovalRequest.details.approver.displayName)
                }
            }
            $0.context = Projection.read(input, at: \Acme_Patients_V1_DelegateMedicalRecordApprovalRequest.context)
        }
        let reply3 = try await self.appointmentsClinicSlotApproval.delegateClinicSlotApproval(outbound3)
        return Acme_Patients_V1_DelegateMedicalRecordApprovalResponse.with {
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.medicalRecordID = input.medicalRecordID
                $0.metadata = input.medicalRecord.metadata
            }
            $0.outcome = Acme_Patients_V1_DelegateMedicalRecordApprovalResponse.Outcome.with {
                $0.effectiveAt = reply0.outcome.effectiveAt
                $0.message = reply1.result.message
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply3.outcome.status
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processEscalateMedicalRecord(_ input: Acme_Patients_V1_EscalateMedicalRecordRequest) async throws
        -> Acme_Patients_V1_EscalateMedicalRecordResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.userID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "audit", detail: input.details.approver.userID
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "EscalateMedicalRecord",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicalRecordRecord(input.medicalRecord, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Patients_V1_RetryAllergyImportRequest.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = input.details.approver.displayName
                    $0.email = input.medicalRecord.counterparty.email
                    $0.patientID = input.medicalRecord.counterparty.patientID
                }
            }
            $0.context = input.context
            $0.details = Acme_Patients_V1_RetryAllergyImportRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.approver.email
                }
            }
        }
        let step0: @Sendable () async throws -> Acme_Patients_V1_RetryAllergyImportResponse = {
            try await self.patientsAllergyImport.retryAllergyImport(outbound0)
        }
        let reply0 = try await step0()
        var outbound1 = Acme_Patients_V1_SyncPatientsRequest()
        outbound1.context = input.context
        outbound1.patient = Acme_Patients_V1_Patient.with {
            $0.audit = Acme_Common_V1_AuditInfo.with {
                $0.updatedAt = input.medicalRecord.audit.updatedAt
            }
            $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                $0.countryCode = input.medicalRecord.billingAddress.countryCode
            }
            $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                $0.displayName = input.details.approver.displayName
            }
        }
        let reply1 = try await self.patientsPatientSync.syncPatients(outbound1)
        let outbound2 = Acme_Patients_V1_FindPatientsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Patients_V1_FindPatientsRequest.Filter.with {
                $0.createdAfter = reply1.patient.audit.updatedAt
                $0.labels = reply0.allergy.attributes
                $0.ownerID = reply1.patient.relationshipManager.userID
                $0.region = reply1.patient.primaryAddress.region
            }
        }
        let reply2 = try await RPCOperations.read {
            try await self.patientsPatientQuery.findPatients(outbound2)
        }
        let outbound3 = Acme_Metrics_V1_SummarizeMetricSeriesesRequest.with {
            $0.annotations = input.annotations
            $0.context = input.context
            $0.reason = input.reason
        }
        let reply3 = try await self.metricsMetricSeriesQuery.summarizeMetricSerieses(outbound3)
        return Acme_Patients_V1_EscalateMedicalRecordResponse.with {
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.billingAddress = input.medicalRecord.billingAddress
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.patientID = reply0.allergy.subject.patientID
                }
                $0.medicalRecordID = input.medicalRecordID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply3.result.correlationID
                $0.details = reply3.result.details
                $0.referenceIds = reply1.result.referenceIds + reply2.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processGetMedicalRecordApprovalStatus(_ input: Acme_Patients_V1_GetMedicalRecordApprovalStatusRequest)
        async throws -> Acme_Patients_V1_GetMedicalRecordApprovalStatusResponse
    {
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "GetMedicalRecordApprovalStatus",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "GetMedicalRecordApprovalStatus", detail: input.context.traceID
        )
        let outbound0 = Acme_Identity_V1_ScoreUserRequest.with {
            $0.context = input.context
            $0.user = Acme_Identity_V1_User.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.context.deadline
                }
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.context.actor.email
                }
                $0.userID = input.context.actor.userID
            }
        }
        async let remote0 = self.identityUserValidation.scoreUser(outbound0)
        async let persisted0 = store.count(tenant: input.context.tenantID)
        let (reply0, count0) = try await (remote0, persisted0)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count0)])
        let outbound1 = Acme_Patients_V1_DeleteMedicalRecordReportRequest.with {
            $0.context = input.context
            $0.etag = reply0.user.audit.etag
            $0.medicalRecordID = input.medicalRecordID
        }
        let reply1 = try await self.getMedicalRecordApprovalStatusStep1.execute(outbound1)
        return Acme_Patients_V1_GetMedicalRecordApprovalStatusResponse.with {
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.locality = reply0.user.primaryAddress.locality
                }
                $0.medicalRecordID = input.medicalRecordID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.referenceIds = reply0.result.referenceIds + reply1.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processListPendingMedicalRecords(_ input: Acme_Patients_V1_ListPendingMedicalRecordsRequest) async throws
        -> Acme_Patients_V1_ListPendingMedicalRecordsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "audit", detail: input.filter.ownerID
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ListPendingMedicalRecords",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "ListPendingMedicalRecords", detail: input.context.traceID
        )
        return Acme_Patients_V1_ListPendingMedicalRecordsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processRecallMedicalRecord(_ input: Acme_Patients_V1_RecallMedicalRecordRequest) async throws
        -> Acme_Patients_V1_RecallMedicalRecordResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "audit", detail: input.details.approver.displayName
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "RecallMedicalRecord",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicalRecordRecord(input.medicalRecord, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let selection0_1: String
        switch input.medicalRecord.settlement {
        case .card(let card):
            selection0_1 = card.holderName
        default: selection0_1 = .init()
        }
        let outbound0 = Acme_Ledger_V1_LintLedgerAccountsRequest.with {
            $0.context = input.context
            $0.ledgerAccount = Acme_Ledger_V1_LedgerAccount.with {
                $0.card = Acme_Ledger_V1_LedgerAccountCardFunding.with {
                    $0.holderName = selection0_1
                }
            }
        }
        let reply0 = try await self.ledgerLedgerAccountValidation.lintLedgerAccounts(outbound0)
        let outbound1 = Acme_Patients_V1_ListPatientConflictsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Patients_V1_ListPatientConflictsRequest.Filter.with {
                $0.createdAfter = input.medicalRecord.audit.createdAt
                $0.labels = reply0.ledgerAccount.labels
                $0.ownerID = reply0.outcome.referenceID
                $0.region = input.medicalRecord.billingAddress.region
            }
        }
        let port1 = RPCOperations.port { (request: Acme_Patients_V1_ListPatientConflictsRequest) in
            try await self.patientsPatientSync.listPatientConflicts(request)
        }
        let reply1 = try await port1.execute(outbound1)
        return Acme_Patients_V1_RecallMedicalRecordResponse.with {
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = reply0.ledgerAccount.holder.displayName
                }
                $0.issuedAt = input.medicalRecord.issuedAt
                $0.medicalRecordID = input.medicalRecordID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply1.result.details
                $0.message = reply0.result.message
                $0.status = reply1.result.status
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processRejectMedicalRecord(_ input: Acme_Patients_V1_RejectMedicalRecordRequest) async throws
        -> Acme_Patients_V1_RejectMedicalRecordResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "audit", detail: input.details.approver.displayName
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "RejectMedicalRecord",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicalRecordRecord(input.medicalRecord, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Patients_V1_ExpireMedicalRecordRequest.with {
            $0.context = input.context
            $0.details = Acme_Patients_V1_ExpireMedicalRecordRequest.Details.with {
                $0.newOwner = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.medicalRecord.counterparty.displayName
                    $0.email = input.medicalRecord.counterparty.email
                    $0.userID = input.details.approver.userID
                }
                $0.notifyContact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.approver.email
                }
            }
            $0.medicalRecordID = input.medicalRecordID
        }
        let reply0 = try await self.rejectMedicalRecordStep0(outbound0)
        let outbound1 = Acme_Onboarding_V1_ResolveOnboardingPlansRequest.with {
            $0.context = input.context
        }
        guard let execute1 = self.rejectMedicalRecordStep1[settings.region] ?? self.rejectMedicalRecordStep1["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply1 = try await execute1(outbound1)
        return Acme_Patients_V1_RejectMedicalRecordResponse.with {
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.billingAddress = input.medicalRecord.billingAddress
                $0.issuedAt = reply0.medicalRecord.issuedAt
                $0.medicalRecordID = input.medicalRecordID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processSubmitMedicalRecord(_ input: Acme_Patients_V1_SubmitMedicalRecordRequest) async throws
        -> Acme_Patients_V1_SubmitMedicalRecordResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.userID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "audit", detail: input.details.approver.userID
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "SubmitMedicalRecord",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicalRecordRecord(input.medicalRecord, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Careplans_V1_SubmitVitalRequest.with {
            $0.context = input.context
            $0.details = Acme_Careplans_V1_SubmitVitalRequest.Details.with {
                $0.approver = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.details.approver.displayName
                    $0.email = input.details.approver.email
                }
            }
        }
        let reply0 = try await self.careplansVitalApproval.submitVital(outbound0)
        return Acme_Patients_V1_SubmitMedicalRecordResponse.with {
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.counterparty = input.medicalRecord.counterparty
                $0.medicalRecordID = input.medicalRecordID
            }
            $0.outcome = Acme_Patients_V1_SubmitMedicalRecordResponse.Outcome.with {
                $0.referenceID = reply0.outcome.referenceID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.vital.correlationID
                $0.status = "ok"
            }
        }
    }
}
