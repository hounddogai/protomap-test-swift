import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Builds and schedules reports about patients.
final class PatientReportingEndpoint: Acme_Patients_V1_PatientReportingService.ServiceProtocol {
    private let store: any RecordRepository
    private let logger: Logger
    private let settings: Settings
    private let accountingChartOfAccounts: Acme_Accounting_V1_ChartOfAccountsService.Client<MeshTransport>
    private let auditAuditEventValidation: Acme_Audit_V1_AuditEventValidationService.Client<MeshTransport>
    private let careplansCareGoalWorkflow: Acme_Careplans_V1_CareGoalWorkflowService.Client<MeshTransport>
    private let contentArticleQuery: Acme_Content_V1_ArticleQueryService.Client<MeshTransport>
    private let documentsDocumentQuery: Acme_Documents_V1_DocumentQueryService.Client<MeshTransport>
    private let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    private let patientsAllergyImport: Acme_Patients_V1_AllergyImportService.Client<MeshTransport>
    private let patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>
    private let patientsMedicalRecordSync: Acme_Patients_V1_MedicalRecordSyncService.Client<MeshTransport>
    private let patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client<MeshTransport>
    private let patientsPatientSync: Acme_Patients_V1_PatientSyncService.Client<MeshTransport>
    private let patientsPatientValidation: Acme_Patients_V1_PatientValidationService.Client<MeshTransport>
    private let prescriptionsPrescription: Acme_Prescriptions_V1_PrescriptionService.Client<MeshTransport>
    private let prescriptionsRefillApproval: Acme_Prescriptions_V1_RefillApprovalService.Client<MeshTransport>
    private let telehealthVideoVisitWorkflow: Acme_Telehealth_V1_VideoVisitWorkflowService.Client<MeshTransport>
    private let deletePatientReportStep2:
        any RPCPort<Acme_Audit_V1_ValidateAuditEventRequest, Acme_Audit_V1_ValidateAuditEventResponse>
    private let fetchPatientReportStep0:
        @Sendable (Acme_Patients_V1_GetPatientRulesRequest) async throws -> Acme_Patients_V1_GetPatientRulesResponse
    private let generatePatientReportStep0:
        [String:
            @Sendable (Acme_Careplans_V1_ListCareGoalWorkflowsRequest) async throws ->
            Acme_Careplans_V1_ListCareGoalWorkflowsResponse]

    init(
        dependencies: any Dependencies,
        accountingChartOfAccounts: Acme_Accounting_V1_ChartOfAccountsService.Client<MeshTransport>,
        auditAuditEventValidation: Acme_Audit_V1_AuditEventValidationService.Client<MeshTransport>,
        careplansCareGoalWorkflow: Acme_Careplans_V1_CareGoalWorkflowService.Client<MeshTransport>,
        contentArticleQuery: Acme_Content_V1_ArticleQueryService.Client<MeshTransport>,
        documentsDocumentQuery: Acme_Documents_V1_DocumentQueryService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        patientsAllergyImport: Acme_Patients_V1_AllergyImportService.Client<MeshTransport>,
        patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>,
        patientsMedicalRecordSync: Acme_Patients_V1_MedicalRecordSyncService.Client<MeshTransport>,
        patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client<MeshTransport>,
        patientsPatientSync: Acme_Patients_V1_PatientSyncService.Client<MeshTransport>,
        patientsPatientValidation: Acme_Patients_V1_PatientValidationService.Client<MeshTransport>,
        prescriptionsPrescription: Acme_Prescriptions_V1_PrescriptionService.Client<MeshTransport>,
        prescriptionsRefillApproval: Acme_Prescriptions_V1_RefillApprovalService.Client<MeshTransport>,
        telehealthVideoVisitWorkflow: Acme_Telehealth_V1_VideoVisitWorkflowService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.accountingChartOfAccounts = accountingChartOfAccounts
        self.auditAuditEventValidation = auditAuditEventValidation
        self.careplansCareGoalWorkflow = careplansCareGoalWorkflow
        self.contentArticleQuery = contentArticleQuery
        self.documentsDocumentQuery = documentsDocumentQuery
        self.identityUser = identityUser
        self.patientsAllergyImport = patientsAllergyImport
        self.patientsMedicalRecordCalculation = patientsMedicalRecordCalculation
        self.patientsMedicalRecordSync = patientsMedicalRecordSync
        self.patientsPatientQuery = patientsPatientQuery
        self.patientsPatientSync = patientsPatientSync
        self.patientsPatientValidation = patientsPatientValidation
        self.prescriptionsPrescription = prescriptionsPrescription
        self.prescriptionsRefillApproval = prescriptionsRefillApproval
        self.telehealthVideoVisitWorkflow = telehealthVideoVisitWorkflow
        self.deletePatientReportStep2 = ClosurePort<
            Acme_Audit_V1_ValidateAuditEventRequest, Acme_Audit_V1_ValidateAuditEventResponse
        >({ request in try await auditAuditEventValidation.validateAuditEvent(request) })
        self.fetchPatientReportStep0 = { request in try await patientsPatientValidation.getPatientRules(request) }
        self.generatePatientReportStep0 = [
            "primary": { request in try await careplansCareGoalWorkflow.listCareGoalWorkflows(request) }
        ]
    }

    /// Counts patients by status.
    func countPatientTotals(
        request: ServerRequest<Acme_Patients_V1_CountPatientTotalsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_CountPatientTotalsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCountPatientTotals(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Deletes a patient.
    func deletePatientReport(
        request: ServerRequest<Acme_Patients_V1_DeletePatientReportRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_DeletePatientReportResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processDeletePatientReport(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a patient.
    func fetchPatientReport(
        request: ServerRequest<Acme_Patients_V1_FetchPatientReportRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_FetchPatientReportResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processFetchPatientReport(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Generates a patient.
    func generatePatientReport(
        request: ServerRequest<Acme_Patients_V1_GeneratePatientReportRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_GeneratePatientReportResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGeneratePatientReport(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists patients a page at a time.
    func listPatientReports(
        request: ServerRequest<Acme_Patients_V1_ListPatientReportsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_ListPatientReportsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListPatientReports(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Schedules a patient.
    func schedulePatientReport(
        request: ServerRequest<Acme_Patients_V1_SchedulePatientReportRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_SchedulePatientReportResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSchedulePatientReport(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Shares a patient.
    func sharePatientReport(
        request: ServerRequest<Acme_Patients_V1_SharePatientReportRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_SharePatientReportResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSharePatientReport(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Streams the changes of patients as they happen.
    func streamPatientMetrics(
        request: ServerRequest<Acme_Patients_V1_StreamPatientMetricsRequest>,
        context: ServerContext
    ) async throws -> StreamingServerResponse<Acme_Patients_V1_StreamPatientMetricsResponse> {
        return StreamingServerResponse { writer in
            try await CallerScope.$metadata.withValue(request.metadata) {
                let response = try await self.processStreamPatientMetrics(request.message)
                try await writer.write(response)
                return [:]
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processCountPatientTotals(_ input: Acme_Patients_V1_CountPatientTotalsRequest) async throws
        -> Acme_Patients_V1_CountPatientTotalsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "audit", detail: input.filter.ownerID
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "CountPatientTotals",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "CountPatientTotals", detail: input.context.traceID
        )
        let importFrame = Acme_Prescriptions_V1_BatchCreatePrescriptionsRequest.with {
            $0.context = input.context
        }
        _ = try await self.prescriptionsPrescription.batchCreatePrescriptions { writer in
            try await writer.write(importFrame)
        }
        return Acme_Patients_V1_CountPatientTotalsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processDeletePatientReport(_ input: Acme_Patients_V1_DeletePatientReportRequest) async throws
        -> Acme_Patients_V1_DeletePatientReportResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.patientID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "audit", detail: input.patientID
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "DeletePatientReport",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "DeletePatientReport", detail: input.context.traceID
        )
        let outbound0 = Acme_Content_V1_ResolveArticlesRequest.with {
            $0.context = input.context
        }
        let reply0 = try await self.contentArticleQuery.resolveArticles(outbound0)
        let outbound1 = Acme_Documents_V1_CountDocumentsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Documents_V1_CountDocumentsRequest.Filter.with {
                $0.ownerID = reply0.result.correlationID
            }
        }
        async let remote1 = self.documentsDocumentQuery.countDocuments(outbound1)
        async let persisted1 = store.count(tenant: input.context.tenantID)
        let (reply1, count1) = try await (remote1, persisted1)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count1)])
        let outbound2 = Acme_Audit_V1_ValidateAuditEventRequest.with {
            $0.auditEvent = Acme_Audit_V1_AuditEvent.with {
                $0.correlationID = reply1.result.correlationID
            }
            $0.context = input.context
            $0.details = Acme_Audit_V1_ValidateAuditEventRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.context.actor.email
                }
            }
            $0.reason = input.reason
        }
        let reply2 = try await self.deletePatientReportStep2.execute(outbound2)
        let outbound3 = Acme_Patients_V1_EstimateMedicalRecordRequest.with {
            $0.context = input.context
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = input.etag
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = reply2.auditEvent.subject.displayName
                }
                $0.lines = [
                    Acme_Patients_V1_MedicalRecordLine.with {
                        $0.attributes = reply2.auditEvent.attributes
                    }
                ]
                $0.number = reply2.auditEvent.subject.number
            }
        }
        let port3 = RPCOperations.port { (request: Acme_Patients_V1_EstimateMedicalRecordRequest) in
            try await self.patientsMedicalRecordCalculation.estimateMedicalRecord(request)
        }
        let reply3 = try await port3.execute(outbound3)
        return Acme_Patients_V1_DeletePatientReportResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply1.result.details
                $0.message = Projection.firstValue(
                    [
                        reply2.result.message,
                        reply3.result.message,
                    ], default: .init())
                $0.referenceIds = reply0.result.referenceIds
                $0.status = reply3.result.status
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processFetchPatientReport(_ input: Acme_Patients_V1_FetchPatientReportRequest) async throws
        -> Acme_Patients_V1_FetchPatientReportResponse
    {
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "FetchPatientReport",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "FetchPatientReport", detail: input.context.traceID
        )
        let outbound0 = Acme_Patients_V1_GetPatientRulesRequest.with {
            $0.context = input.context
            $0.patientID = input.patientID
        }
        let reply0 = try await self.fetchPatientReportStep0(outbound0)
        return Acme_Patients_V1_FetchPatientReportResponse.with {
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply0.patient.audit.etag
                }
                $0.name = reply0.patient.name
                $0.patientID = input.patientID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processGeneratePatientReport(_ input: Acme_Patients_V1_GeneratePatientReportRequest) async throws
        -> Acme_Patients_V1_GeneratePatientReportResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.cron)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "audit", detail: input.details.cron
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "GeneratePatientReport",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "GeneratePatientReport", detail: input.context.traceID
        )
        let outbound0 = Acme_Careplans_V1_ListCareGoalWorkflowsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Careplans_V1_ListCareGoalWorkflowsRequest.Filter.with {
                $0.createdAfter = input.context.deadline
                $0.labels = input.details.filters
                $0.ownerID = input.patientID
            }
        }
        guard
            let execute0 = self.generatePatientReportStep0[settings.region]
                ?? self.generatePatientReportStep0["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply0 = try await execute0(outbound0)
        let outbound1 = Acme_Patients_V1_SummarizePatientsRequest.with {
            $0.context = input.context
            $0.details = Acme_Patients_V1_SummarizePatientsRequest.Details.with {
                $0.format = input.details.format
            }
        }
        let reply1 = try await self.patientsPatientQuery.summarizePatients(outbound1)
        return Acme_Patients_V1_GeneratePatientReportResponse.with {
            $0.period = input.details.period
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.details = reply0.result.details
                $0.status = "ok"
            }
            $0.summary = reply1.summary
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processListPatientReports(_ input: Acme_Patients_V1_ListPatientReportsRequest) async throws
        -> Acme_Patients_V1_ListPatientReportsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "audit", detail: input.filter.ownerID
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ListPatientReports",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "ListPatientReports", detail: input.context.traceID
        )
        let outbound0 = Acme_Prescriptions_V1_DelegateRefillApprovalRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_DelegateRefillApprovalRequest.Details.with {
                $0.approver = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.context.actor.userID
                }
            }
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.comments = [
                    Acme_Prescriptions_V1_RefillComment.with {
                        $0.createdAt = input.filter.createdAfter
                    }
                ]
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.context.actor.email
                }
            }
        }
        let envelope0 = try Google_Protobuf_Any(message: outbound0)
        let unpacked0 = try Acme_Prescriptions_V1_DelegateRefillApprovalRequest(unpackingAny: envelope0)
        let reply0 = try await self.prescriptionsRefillApproval.delegateRefillApproval(unpacked0)
        let outbound1 = Acme_Telehealth_V1_CancelVideoVisitWorkflowRequest.with {
            $0.context = input.context
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.participants = [
                    Acme_Telehealth_V1_VideoVisitParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = reply0.refill.assignee.email
                            $0.preferredChannel = reply0.refill.requester.preferredChannel
                        }
                    }
                ]
            }
        }
        let json1 = try outbound1.jsonString()
        let decoded1 = try Acme_Telehealth_V1_CancelVideoVisitWorkflowRequest(jsonString: json1)
        let reply1 = try await self.telehealthVideoVisitWorkflow.cancelVideoVisitWorkflow(decoded1)
        return Acme_Patients_V1_ListPatientReportsResponse.with {
            $0.patients = [
                Acme_Patients_V1_Patient.with {
                    $0.audit = Acme_Common_V1_AuditInfo.with {
                        $0.updatedAt = Projection.firstValue(
                            [
                                reply0.refill.audit.updatedAt,
                                reply1.videoVisit.audit.updatedAt,
                            ], default: .init())
                    }
                    $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                        $0.userID = reply1.videoVisit.organizer.userID
                    }
                }
            ]
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processSchedulePatientReport(_ input: Acme_Patients_V1_SchedulePatientReportRequest) async throws
        -> Acme_Patients_V1_SchedulePatientReportResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.cron)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "audit", detail: input.details.cron
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "SchedulePatientReport",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "SchedulePatientReport", detail: input.context.traceID
        )
        let outbound0 =
            Acme_Accounting_V1_CreateChartOfAccountsRequest.forPatientReportingEndpointSchedulePatientReport0(
                input
            )
        let reply0 = try await self.accountingChartOfAccounts.createChartOfAccounts(outbound0)
        let outbound1 = Acme_Patients_V1_ReconcilePatientsRequest.with {
            $0.context = input.context
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply0.chartOfAccounts.audit.etag
                }
            }
        }
        let reply1 = try await self.patientsPatientSync.reconcilePatients(
            outbound1, metadata: ["x-acme-region": .string(settings.region)]
        )
        return Acme_Patients_V1_SchedulePatientReportResponse.with {
            $0.period = input.details.period
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = Projection.firstValue(
                    [
                        reply0.result.details,
                        reply1.result.details,
                    ], default: .init())
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processSharePatientReport(_ input: Acme_Patients_V1_SharePatientReportRequest) async throws
        -> Acme_Patients_V1_SharePatientReportResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.channel)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "audit", detail: input.details.channel
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "SharePatientReport",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "SharePatientReport", detail: input.context.traceID
        )
        let outbound0 = Acme_Patients_V1_SyncMedicalRecordsRequest.with {
            $0.context = input.context
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.email = input.details.recipient.email
                }
            }
        }
        let reply0 = try await RPCOperations.call(outbound0) { request in
            try await self.patientsMedicalRecordSync.syncMedicalRecords(request)
        }
        let outbound1 = Acme_Patients_V1_ListAllergyImportsRequest.with {
            $0.context = Projection.read(input, at: \Acme_Patients_V1_SharePatientReportRequest.context)
            $0.filter = Acme_Patients_V1_ListAllergyImportsRequest.Filter.with {
                $0.createdAfter = Projection.read(
                    reply0, at: \Acme_Patients_V1_SyncMedicalRecordsResponse.medicalRecord.audit.updatedAt)
                $0.ownerID = Projection.read(
                    reply0, at: \Acme_Patients_V1_SyncMedicalRecordsResponse.medicalRecord.counterparty.patientID)
                $0.region = Projection.read(
                    reply0, at: \Acme_Patients_V1_SyncMedicalRecordsResponse.medicalRecord.billingAddress.region)
            }
        }
        let reply1 = try await self.patientsAllergyImport.listAllergyImports(outbound1)
        let outbound2 = Acme_Patients_V1_ValidatePatientRequest.with {
            $0.context = input.context
            $0.details = Acme_Patients_V1_ValidatePatientRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.preferredChannel = input.details.recipient.preferredChannel
                }
            }
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = reply0.medicalRecord.billingAddress.postalCode
                }
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.email = input.details.recipient.email
                }
            }
        }
        let step2: @Sendable () async throws -> Acme_Patients_V1_ValidatePatientResponse = {
            try await self.patientsPatientValidation.validatePatient(outbound2)
        }
        let reply2 = try await step2()
        return Acme_Patients_V1_SharePatientReportResponse.with {
            $0.outcome = Acme_Patients_V1_SharePatientReportResponse.Outcome.with {
                $0.message = reply1.result.message
            }
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply2.patient.audit.createdBy
                }
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.phone = input.details.recipient.phone
                }
                $0.patientID = input.patientID
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.email = reply2.patient.contact.email
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processStreamPatientMetrics(_ input: Acme_Patients_V1_StreamPatientMetricsRequest) async throws
        -> Acme_Patients_V1_StreamPatientMetricsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "audit", detail: input.filter.ownerID
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "StreamPatientMetrics",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "StreamPatientMetrics", detail: input.context.traceID
        )
        var outbound0 = Acme_Patients_V1_CheckPatientEligibilityRequest()
        outbound0.context = input.context
        outbound0.details = Acme_Patients_V1_CheckPatientEligibilityRequest.Details.with {
            $0.contact = Acme_Common_V1_ContactInfo.with {
                $0.phone = input.subscriber.phone
            }
        }
        outbound0.patient = Acme_Patients_V1_Patient.with {
            $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                $0.email = input.subscriber.email
            }
        }
        let reply0 = try await self.patientsPatientValidation.checkPatientEligibility(outbound0)
        return Acme_Patients_V1_StreamPatientMetricsResponse.with {
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.subscriber.email
                }
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
                $0.segments = reply0.patient.segments
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.result.message
                $0.status = "ok"
            }
        }
    }
}
