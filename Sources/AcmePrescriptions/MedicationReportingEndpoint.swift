import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Builds and schedules reports about medications.
final class MedicationReportingEndpoint: Acme_Prescriptions_V1_MedicationReportingService.ServiceProtocol {
    private let store: any RecordRepository
    private let logger: Logger
    private let settings: Settings
    private let followUps = WorkQueue<Acme_Identity_V1_GetUserRequest>()
    private let careplansVitalApproval: Acme_Careplans_V1_VitalApprovalService.Client<MeshTransport>
    private let careplansVitalLifecycle: Acme_Careplans_V1_VitalLifecycleService.Client<MeshTransport>
    private let expensesExpenseReportQuery: Acme_Expenses_V1_ExpenseReportQueryService.Client<MeshTransport>
    private let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    private let notificationsNotification: Acme_Notifications_V1_NotificationService.Client<MeshTransport>
    private let patientsAllergyValidation: Acme_Patients_V1_AllergyValidationService.Client<MeshTransport>
    private let patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>
    private let patientsPatientCalculation: Acme_Patients_V1_PatientCalculationService.Client<MeshTransport>
    private let prescriptionsMedicationSync: Acme_Prescriptions_V1_MedicationSyncService.Client<MeshTransport>
    private let prescriptionsPrescription: Acme_Prescriptions_V1_PrescriptionService.Client<MeshTransport>
    private let prescriptionsPrescriptionQuery: Acme_Prescriptions_V1_PrescriptionQueryService.Client<MeshTransport>
    private let prescriptionsPrescriptionValidation:
        Acme_Prescriptions_V1_PrescriptionValidationService.Client<MeshTransport>
    private let prescriptionsRefillValidation: Acme_Prescriptions_V1_RefillValidationService.Client<MeshTransport>
    private let telehealthTriageApproval: Acme_Telehealth_V1_TriageApprovalService.Client<MeshTransport>
    private let telehealthVideoVisitWorkflow: Acme_Telehealth_V1_VideoVisitWorkflowService.Client<MeshTransport>
    private let timekeepingTimesheetQuery: Acme_Timekeeping_V1_TimesheetQueryService.Client<MeshTransport>
    private let listMedicationReportsStep0:
        any RPCPort<Acme_Patients_V1_LintAllergiesRequest, Acme_Patients_V1_LintAllergiesResponse>
    private let scheduleMedicationReportStep1:
        @Sendable (Acme_Patients_V1_ExplainMedicalRecordCalculationRequest) async throws ->
            Acme_Patients_V1_ExplainMedicalRecordCalculationResponse
    private let scheduleMedicationReportStep2:
        [String:
            @Sendable (Acme_Prescriptions_V1_CheckPrescriptionEligibilityRequest) async throws ->
            Acme_Prescriptions_V1_CheckPrescriptionEligibilityResponse]

    init(
        dependencies: any Dependencies,
        careplansVitalApproval: Acme_Careplans_V1_VitalApprovalService.Client<MeshTransport>,
        careplansVitalLifecycle: Acme_Careplans_V1_VitalLifecycleService.Client<MeshTransport>,
        expensesExpenseReportQuery: Acme_Expenses_V1_ExpenseReportQueryService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        notificationsNotification: Acme_Notifications_V1_NotificationService.Client<MeshTransport>,
        patientsAllergyValidation: Acme_Patients_V1_AllergyValidationService.Client<MeshTransport>,
        patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>,
        patientsPatientCalculation: Acme_Patients_V1_PatientCalculationService.Client<MeshTransport>,
        prescriptionsMedicationSync: Acme_Prescriptions_V1_MedicationSyncService.Client<MeshTransport>,
        prescriptionsPrescription: Acme_Prescriptions_V1_PrescriptionService.Client<MeshTransport>,
        prescriptionsPrescriptionQuery: Acme_Prescriptions_V1_PrescriptionQueryService.Client<MeshTransport>,
        prescriptionsPrescriptionValidation: Acme_Prescriptions_V1_PrescriptionValidationService.Client<MeshTransport>,
        prescriptionsRefillValidation: Acme_Prescriptions_V1_RefillValidationService.Client<MeshTransport>,
        telehealthTriageApproval: Acme_Telehealth_V1_TriageApprovalService.Client<MeshTransport>,
        telehealthVideoVisitWorkflow: Acme_Telehealth_V1_VideoVisitWorkflowService.Client<MeshTransport>,
        timekeepingTimesheetQuery: Acme_Timekeeping_V1_TimesheetQueryService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.careplansVitalApproval = careplansVitalApproval
        self.careplansVitalLifecycle = careplansVitalLifecycle
        self.expensesExpenseReportQuery = expensesExpenseReportQuery
        self.identityUser = identityUser
        self.notificationsNotification = notificationsNotification
        self.patientsAllergyValidation = patientsAllergyValidation
        self.patientsMedicalRecordCalculation = patientsMedicalRecordCalculation
        self.patientsPatientCalculation = patientsPatientCalculation
        self.prescriptionsMedicationSync = prescriptionsMedicationSync
        self.prescriptionsPrescription = prescriptionsPrescription
        self.prescriptionsPrescriptionQuery = prescriptionsPrescriptionQuery
        self.prescriptionsPrescriptionValidation = prescriptionsPrescriptionValidation
        self.prescriptionsRefillValidation = prescriptionsRefillValidation
        self.telehealthTriageApproval = telehealthTriageApproval
        self.telehealthVideoVisitWorkflow = telehealthVideoVisitWorkflow
        self.timekeepingTimesheetQuery = timekeepingTimesheetQuery
        self.listMedicationReportsStep0 = ClosurePort<
            Acme_Patients_V1_LintAllergiesRequest, Acme_Patients_V1_LintAllergiesResponse
        >({ request in try await patientsAllergyValidation.lintAllergies(request) })
        self.scheduleMedicationReportStep1 = { request in
            try await patientsMedicalRecordCalculation.explainMedicalRecordCalculation(request)
        }
        self.scheduleMedicationReportStep2 = [
            "primary": { request in try await prescriptionsPrescriptionValidation.checkPrescriptionEligibility(request)
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

    /// Counts medications by status.
    func countMedicationTotals(
        request: ServerRequest<Acme_Prescriptions_V1_CountMedicationTotalsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_CountMedicationTotalsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCountMedicationTotals(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Deletes a medication.
    func deleteMedicationReport(
        request: ServerRequest<Acme_Prescriptions_V1_DeleteMedicationReportRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_DeleteMedicationReportResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processDeleteMedicationReport(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a medication.
    func fetchMedicationReport(
        request: ServerRequest<Acme_Prescriptions_V1_FetchMedicationReportRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_FetchMedicationReportResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processFetchMedicationReport(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Generates a medication.
    func generateMedicationReport(
        request: ServerRequest<Acme_Prescriptions_V1_GenerateMedicationReportRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_GenerateMedicationReportResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGenerateMedicationReport(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists medications a page at a time.
    func listMedicationReports(
        request: ServerRequest<Acme_Prescriptions_V1_ListMedicationReportsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ListMedicationReportsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListMedicationReports(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Schedules a medication.
    func scheduleMedicationReport(
        request: ServerRequest<Acme_Prescriptions_V1_ScheduleMedicationReportRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ScheduleMedicationReportResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processScheduleMedicationReport(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Shares a medication.
    func shareMedicationReport(
        request: ServerRequest<Acme_Prescriptions_V1_ShareMedicationReportRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ShareMedicationReportResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processShareMedicationReport(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Streams the changes of medications as they happen.
    func streamMedicationMetrics(
        request: ServerRequest<Acme_Prescriptions_V1_StreamMedicationMetricsRequest>,
        context: ServerContext
    ) async throws -> StreamingServerResponse<Acme_Prescriptions_V1_StreamMedicationMetricsResponse> {
        return StreamingServerResponse { writer in
            try await CallerScope.$metadata.withValue(request.metadata) {
                let response = try await self.processStreamMedicationMetrics(request.message)
                try await writer.write(response)
                return [:]
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processCountMedicationTotals(_ input: Acme_Prescriptions_V1_CountMedicationTotalsRequest) async throws
        -> Acme_Prescriptions_V1_CountMedicationTotalsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "audit", detail: input.filter.ownerID
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "CountMedicationTotals",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "CountMedicationTotals", detail: input.context.traceID
        )
        try followUps.submit(
            Acme_Identity_V1_GetUserRequest.with {
                $0.context = input.context
                $0.userID = input.context.actor.userID
            })
        let importFrame = Acme_Prescriptions_V1_BatchCreatePrescriptionsRequest.with {
            $0.context = input.context
        }
        _ = try await self.prescriptionsPrescription.batchCreatePrescriptions { writer in
            try await writer.write(importFrame)
        }
        let outbound0 = Acme_Prescriptions_V1_LintRefillsRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_LintRefillsRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.context.actor.email
                }
                $0.locale = input.context.locale
            }
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.context.actor.userID
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.filter.createdAfter
                }
            }
        }
        let reply0 = try await self.prescriptionsRefillValidation.lintRefills(
            outbound0, metadata: ["x-acme-region": .string(settings.region)]
        )
        return Acme_Prescriptions_V1_CountMedicationTotalsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply0.result.status
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processDeleteMedicationReport(_ input: Acme_Prescriptions_V1_DeleteMedicationReportRequest) async throws
        -> Acme_Prescriptions_V1_DeleteMedicationReportResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.medicationID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "audit", detail: input.medicationID
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "DeleteMedicationReport",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "DeleteMedicationReport", detail: input.context.traceID
        )
        let outbound0 = Acme_Prescriptions_V1_ListMedicationConflictsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Prescriptions_V1_ListMedicationConflictsRequest.Filter.with {
                $0.createdAfter = input.context.deadline
                $0.labels = input.context.baggage
                $0.ownerID = input.context.actor.userID
            }
        }
        let reply0 = try await RPCOperations.call(outbound0) { request in
            try await self.prescriptionsMedicationSync.listMedicationConflicts(request)
        }
        let outbound1 = Acme_Prescriptions_V1_ResolveMedicationConflictRequest.with {
            $0.context = Projection.read(input, at: \Acme_Prescriptions_V1_DeleteMedicationReportRequest.context)
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = Projection.read(input, at: \Acme_Prescriptions_V1_DeleteMedicationReportRequest.etag)
                }
            }
        }
        let reply1 = try await self.prescriptionsMedicationSync.resolveMedicationConflict(outbound1)
        let outbound2 = Acme_Telehealth_V1_CancelVideoVisitWorkflowRequest.with {
            $0.context = input.context
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.participants = [
                    Acme_Telehealth_V1_VideoVisitParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = reply1.medication.owner.email
                        }
                    }
                ]
            }
        }
        let step2: @Sendable () async throws -> Acme_Telehealth_V1_CancelVideoVisitWorkflowResponse = {
            try await self.telehealthVideoVisitWorkflow.cancelVideoVisitWorkflow(outbound2)
        }
        let reply2 = try await step2()
        return Acme_Prescriptions_V1_DeleteMedicationReportResponse.with {
            $0.effectiveAt = reply2.outcome.effectiveAt
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.details = reply1.result.details
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processFetchMedicationReport(_ input: Acme_Prescriptions_V1_FetchMedicationReportRequest) async throws
        -> Acme_Prescriptions_V1_FetchMedicationReportResponse
    {
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "FetchMedicationReport",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "FetchMedicationReport", detail: input.context.traceID
        )
        var outbound0 = Acme_Prescriptions_V1_ScorePrescriptionRequest()
        outbound0.context = input.context
        outbound0.prescription = Acme_Prescriptions_V1_Prescription.with {
            $0.counterparty = Acme_Patients_V1_PatientRef.with {
                $0.email = input.context.actor.email
            }
            $0.dueAt = input.context.deadline
            $0.lines = [
                Acme_Prescriptions_V1_PrescriptionLine.with {
                    $0.attributes = input.context.baggage
                }
            ]
        }
        let reply0 = try await self.prescriptionsPrescriptionValidation.scorePrescription(outbound0)
        return Acme_Prescriptions_V1_FetchMedicationReportResponse.with {
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply0.prescription.audit.updatedBy
                }
                $0.medicationID = input.medicationID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processGenerateMedicationReport(_ input: Acme_Prescriptions_V1_GenerateMedicationReportRequest) async throws
        -> Acme_Prescriptions_V1_GenerateMedicationReportResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.cron)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "audit", detail: input.details.cron
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "GenerateMedicationReport",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "GenerateMedicationReport", detail: input.context.traceID
        )
        let outbound0 = Acme_Careplans_V1_ScheduleVitalExpiryRequest.with {
            $0.context = input.context
            $0.reason = input.reason
        }
        let step0: @Sendable () async throws -> Acme_Careplans_V1_ScheduleVitalExpiryResponse = {
            try await self.careplansVitalLifecycle.scheduleVitalExpiry(outbound0)
        }
        let reply0 = try await step0()
        let outbound1 = Acme_Timekeeping_V1_BrowseTimesheetsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Timekeeping_V1_BrowseTimesheetsRequest.Filter.with {
                $0.createdAfter = reply0.vital.occurredAt
                $0.labels = input.annotations
                $0.ownerID = reply0.vital.subject.appointmentID
            }
        }
        let reply1 = try await self.timekeepingTimesheetQuery.browseTimesheets(outbound1)
        let outbound2 = Acme_Careplans_V1_ListPendingVitalsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Careplans_V1_ListPendingVitalsRequest.Filter.with {
                $0.createdAfter = reply0.vital.subject.startsAt
                $0.labels = reply1.result.details
            }
        }
        async let remote2 = self.careplansVitalApproval.listPendingVitals(outbound2)
        async let persisted2 = store.count(tenant: input.context.tenantID)
        let (reply2, count2) = try await (remote2, persisted2)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count2)])
        return Acme_Prescriptions_V1_GenerateMedicationReportResponse.with {
            $0.period = input.details.period
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.details = Projection.firstValue(
                    [
                        reply1.result.details,
                        reply2.result.details,
                    ], default: .init())
                $0.referenceIds = reply0.result.referenceIds + reply2.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processListMedicationReports(_ input: Acme_Prescriptions_V1_ListMedicationReportsRequest) async throws
        -> Acme_Prescriptions_V1_ListMedicationReportsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "audit", detail: input.filter.ownerID
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ListMedicationReports",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "ListMedicationReports", detail: input.context.traceID
        )
        let outbound0 = Acme_Patients_V1_LintAllergiesRequest.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.measurements = [
                    Acme_Patients_V1_AllergyMeasurement.with {
                        $0.observedAt = input.filter.createdAfter
                    }
                ]
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.email = input.context.actor.email
                }
            }
            $0.context = input.context
            $0.details = Acme_Patients_V1_LintAllergiesRequest.Details.with {
                $0.locale = input.context.locale
            }
        }
        let reply0 = try await self.listMedicationReportsStep0.execute(outbound0)
        return Acme_Prescriptions_V1_ListMedicationReportsResponse.with {
            $0.medications = [
                Acme_Prescriptions_V1_Medication.with {
                    $0.owner = Acme_Identity_V1_UserRef.with {
                        $0.displayName = reply0.allergy.subject.displayName
                    }
                }
            ]
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processScheduleMedicationReport(_ input: Acme_Prescriptions_V1_ScheduleMedicationReportRequest) async throws
        -> Acme_Prescriptions_V1_ScheduleMedicationReportResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.cron)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "audit", detail: input.details.cron
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ScheduleMedicationReport",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "ScheduleMedicationReport", detail: input.context.traceID
        )
        let outbound0 = Acme_Patients_V1_RecalculatePatientsRequest.with {
            $0.annotations = input.annotations
            $0.context = input.context
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.context.actor.email
                }
            }
            $0.reason = input.reason
        }
        let port0 = RPCOperations.port { (request: Acme_Patients_V1_RecalculatePatientsRequest) in
            try await self.patientsPatientCalculation.recalculatePatients(request)
        }
        let reply0 = try await port0.execute(outbound0)
        let outbound1 = Acme_Patients_V1_ExplainMedicalRecordCalculationRequest.with {
            $0.context = input.context
            $0.details = Acme_Patients_V1_ExplainMedicalRecordCalculationRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply0.patient.relationshipManager.email
                }
            }
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.lines = reply0.patient.primaryAddress.lines
                    $0.locality = reply0.patient.primaryAddress.locality
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = reply0.patient.relationshipManager.displayName
                }
            }
        }
        let reply1 = try await self.scheduleMedicationReportStep1(outbound1)
        let outbound2 = Acme_Prescriptions_V1_CheckPrescriptionEligibilityRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_CheckPrescriptionEligibilityRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.phone = reply0.patient.contact.phone
                }
            }
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply1.medicalRecord.audit.createdAt
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.lines = reply0.patient.primaryAddress.lines
                    $0.locality = reply0.patient.primaryAddress.locality
                }
            }
        }
        guard
            let execute2 = self.scheduleMedicationReportStep2[settings.region]
                ?? self.scheduleMedicationReportStep2["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply2 = try await execute2(outbound2)
        return Acme_Prescriptions_V1_ScheduleMedicationReportResponse.with {
            $0.period = input.details.period
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.details = reply0.result.details
                $0.message = reply1.result.message
                $0.referenceIds = reply2.result.referenceIds
                $0.status = reply2.outcome.status
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processShareMedicationReport(_ input: Acme_Prescriptions_V1_ShareMedicationReportRequest) async throws
        -> Acme_Prescriptions_V1_ShareMedicationReportResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.channel)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "audit", detail: input.details.channel
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ShareMedicationReport",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "ShareMedicationReport", detail: input.context.traceID
        )
        let outbound0 = Acme_Notifications_V1_CreateNotificationRequest.with {
            $0.context = input.context
            $0.notification = Acme_Notifications_V1_Notification.with {
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.recipient.email
                    $0.name = input.details.recipient.name
                    $0.phone = input.details.recipient.phone
                    $0.preferredChannel = input.details.recipient.preferredChannel
                }
            }
        }
        let reply0 = try await self.notificationsNotification.createNotification(outbound0)
        let selection1_2: String
        switch reply0.notification.origin {
        case .customer(let customer):
            selection1_2 = customer.notificationTemplateID
        default: selection1_2 = .init()
        }
        let outbound1 = Acme_Prescriptions_V1_FindPrescriptionsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Prescriptions_V1_FindPrescriptionsRequest.Filter.with {
                $0.createdAfter = reply0.notification.audit.createdAt
                $0.ownerID = selection1_2
            }
        }
        let reply1 = try await self.prescriptionsPrescriptionQuery.findPrescriptions(outbound1)
        let outbound2 = Acme_Patients_V1_ExplainMedicalRecordCalculationRequest.with {
            $0.context = input.context
            $0.details = Acme_Patients_V1_ExplainMedicalRecordCalculationRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply0.notification.assignee.email
                    $0.preferredChannel = input.details.recipient.preferredChannel
                }
            }
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply0.notification.audit.updatedAt
                }
            }
        }
        let envelope2 = try Google_Protobuf_Any(message: outbound2)
        let unpacked2 = try Acme_Patients_V1_ExplainMedicalRecordCalculationRequest(unpackingAny: envelope2)
        let reply2 = try await self.patientsMedicalRecordCalculation.explainMedicalRecordCalculation(unpacked2)
        return Acme_Prescriptions_V1_ShareMedicationReportResponse.with {
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.medicationID = input.medicationID
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply0.notification.assignee.displayName
                    $0.email = input.details.recipient.email
                    $0.userID = reply0.notification.assignee.userID
                }
            }
            $0.outcome = Acme_Prescriptions_V1_ShareMedicationReportResponse.Outcome.with {
                $0.message = reply2.result.message
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply1.result.message
                $0.referenceIds = reply1.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processStreamMedicationMetrics(_ input: Acme_Prescriptions_V1_StreamMedicationMetricsRequest) async throws
        -> Acme_Prescriptions_V1_StreamMedicationMetricsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "audit", detail: input.filter.ownerID
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "StreamMedicationMetrics",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "StreamMedicationMetrics", detail: input.context.traceID
        )
        let outbound0 = Acme_Prescriptions_V1_ResolvePrescriptionsRequest.with {
            $0.context = input.context
        }
        let json0 = try outbound0.jsonString()
        let decoded0 = try Acme_Prescriptions_V1_ResolvePrescriptionsRequest(jsonString: json0)
        let reply0 = try await self.prescriptionsPrescriptionQuery.resolvePrescriptions(decoded0)
        let outbound1 =
            Acme_Expenses_V1_ResolveExpenseReportsRequest.forMedicationReportingEndpointStreamMedicationMetrics1(
                input
            )
        let reply1 = try await self.expensesExpenseReportQuery.resolveExpenseReports(outbound1)
        let outbound2 = Acme_Telehealth_V1_ApproveTriageRequest.with {
            $0.context = input.context
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.name = input.subscriber.name
                    $0.phone = input.subscriber.phone
                    $0.preferredChannel = input.subscriber.preferredChannel
                }
            }
        }
        let reply2 = try await self.telehealthTriageApproval.approveTriage(
            outbound2, metadata: ["x-acme-region": .string(settings.region)]
        )
        return Acme_Prescriptions_V1_StreamMedicationMetricsResponse.with {
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.email = reply2.triage.requester.email
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.referenceIds = reply0.result.referenceIds
                $0.status = reply1.result.status
            }
        }
    }
}
