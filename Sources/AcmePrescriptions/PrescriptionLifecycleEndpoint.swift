import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Moves a prescription between the states of its lifecycle.
final class PrescriptionLifecycleEndpoint: Acme_Prescriptions_V1_PrescriptionLifecycleService.ServiceProtocol {
    private let store: any RecordRepository
    private let logger: Logger
    private let settings: Settings
    private let followUps = WorkQueue<Acme_Identity_V1_GetUserRequest>()
    private let auditAuditEventQuery: Acme_Audit_V1_AuditEventQueryService.Client<MeshTransport>
    private let careplansVitalReporting: Acme_Careplans_V1_VitalReportingService.Client<MeshTransport>
    private let complianceComplianceCase: Acme_Compliance_V1_ComplianceCaseService.Client<MeshTransport>
    private let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    private let metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client<MeshTransport>
    private let patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>
    private let patientsMedicalRecordQuery: Acme_Patients_V1_MedicalRecordQueryService.Client<MeshTransport>
    private let patientsMedicalRecordValidation: Acme_Patients_V1_MedicalRecordValidationService.Client<MeshTransport>
    private let prescriptionsMedicationCalculation:
        Acme_Prescriptions_V1_MedicationCalculationService.Client<MeshTransport>
    private let prescriptionsMedicationQuery: Acme_Prescriptions_V1_MedicationQueryService.Client<MeshTransport>
    private let prescriptionsMedicationSync: Acme_Prescriptions_V1_MedicationSyncService.Client<MeshTransport>
    private let prescriptionsPrescriptionQuery: Acme_Prescriptions_V1_PrescriptionQueryService.Client<MeshTransport>
    private let prescriptionsRefillCalculation: Acme_Prescriptions_V1_RefillCalculationService.Client<MeshTransport>
    private let prescriptionsRefillImport: Acme_Prescriptions_V1_RefillImportService.Client<MeshTransport>
    private let prescriptionsRefillSync: Acme_Prescriptions_V1_RefillSyncService.Client<MeshTransport>
    private let searchSearchIndexValidation: Acme_Search_V1_SearchIndexValidationService.Client<MeshTransport>
    private let telehealthTriageApproval: Acme_Telehealth_V1_TriageApprovalService.Client<MeshTransport>
    private let telehealthVideoVisitWorkflow: Acme_Telehealth_V1_VideoVisitWorkflowService.Client<MeshTransport>
    private let activatePrescriptionStep2:
        any RPCPort<
            Acme_Patients_V1_ExplainMedicalRecordCalculationRequest,
            Acme_Patients_V1_ExplainMedicalRecordCalculationResponse
        >
    private let expirePrescriptionStep0:
        @Sendable (Acme_Prescriptions_V1_CalculateMedicationRequest) async throws ->
            Acme_Prescriptions_V1_CalculateMedicationResponse
    private let expirePrescriptionStep1:
        [String:
            @Sendable (Acme_Prescriptions_V1_ResolveRefillConflictRequest) async throws ->
            Acme_Prescriptions_V1_ResolveRefillConflictResponse]

    init(
        dependencies: any Dependencies,
        auditAuditEventQuery: Acme_Audit_V1_AuditEventQueryService.Client<MeshTransport>,
        careplansVitalReporting: Acme_Careplans_V1_VitalReportingService.Client<MeshTransport>,
        complianceComplianceCase: Acme_Compliance_V1_ComplianceCaseService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client<MeshTransport>,
        patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>,
        patientsMedicalRecordQuery: Acme_Patients_V1_MedicalRecordQueryService.Client<MeshTransport>,
        patientsMedicalRecordValidation: Acme_Patients_V1_MedicalRecordValidationService.Client<MeshTransport>,
        prescriptionsMedicationCalculation: Acme_Prescriptions_V1_MedicationCalculationService.Client<MeshTransport>,
        prescriptionsMedicationQuery: Acme_Prescriptions_V1_MedicationQueryService.Client<MeshTransport>,
        prescriptionsMedicationSync: Acme_Prescriptions_V1_MedicationSyncService.Client<MeshTransport>,
        prescriptionsPrescriptionQuery: Acme_Prescriptions_V1_PrescriptionQueryService.Client<MeshTransport>,
        prescriptionsRefillCalculation: Acme_Prescriptions_V1_RefillCalculationService.Client<MeshTransport>,
        prescriptionsRefillImport: Acme_Prescriptions_V1_RefillImportService.Client<MeshTransport>,
        prescriptionsRefillSync: Acme_Prescriptions_V1_RefillSyncService.Client<MeshTransport>,
        searchSearchIndexValidation: Acme_Search_V1_SearchIndexValidationService.Client<MeshTransport>,
        telehealthTriageApproval: Acme_Telehealth_V1_TriageApprovalService.Client<MeshTransport>,
        telehealthVideoVisitWorkflow: Acme_Telehealth_V1_VideoVisitWorkflowService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.auditAuditEventQuery = auditAuditEventQuery
        self.careplansVitalReporting = careplansVitalReporting
        self.complianceComplianceCase = complianceComplianceCase
        self.identityUser = identityUser
        self.metricsMetricSeriesValidation = metricsMetricSeriesValidation
        self.patientsMedicalRecordCalculation = patientsMedicalRecordCalculation
        self.patientsMedicalRecordQuery = patientsMedicalRecordQuery
        self.patientsMedicalRecordValidation = patientsMedicalRecordValidation
        self.prescriptionsMedicationCalculation = prescriptionsMedicationCalculation
        self.prescriptionsMedicationQuery = prescriptionsMedicationQuery
        self.prescriptionsMedicationSync = prescriptionsMedicationSync
        self.prescriptionsPrescriptionQuery = prescriptionsPrescriptionQuery
        self.prescriptionsRefillCalculation = prescriptionsRefillCalculation
        self.prescriptionsRefillImport = prescriptionsRefillImport
        self.prescriptionsRefillSync = prescriptionsRefillSync
        self.searchSearchIndexValidation = searchSearchIndexValidation
        self.telehealthTriageApproval = telehealthTriageApproval
        self.telehealthVideoVisitWorkflow = telehealthVideoVisitWorkflow
        self.activatePrescriptionStep2 = ClosurePort<
            Acme_Patients_V1_ExplainMedicalRecordCalculationRequest,
            Acme_Patients_V1_ExplainMedicalRecordCalculationResponse
        >({ request in try await patientsMedicalRecordCalculation.explainMedicalRecordCalculation(request) })
        self.expirePrescriptionStep0 = { request in
            try await prescriptionsMedicationCalculation.calculateMedication(request)
        }
        self.expirePrescriptionStep1 = [
            "primary": { request in try await prescriptionsRefillSync.resolveRefillConflict(request) }
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

    /// Activates a prescription.
    func activatePrescription(
        request: ServerRequest<Acme_Prescriptions_V1_ActivatePrescriptionRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ActivatePrescriptionResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processActivatePrescription(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Expires a prescription.
    func expirePrescription(
        request: ServerRequest<Acme_Prescriptions_V1_ExpirePrescriptionRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ExpirePrescriptionResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processExpirePrescription(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Reinstates a prescription.
    func reinstatePrescription(
        request: ServerRequest<Acme_Prescriptions_V1_ReinstatePrescriptionRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ReinstatePrescriptionResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processReinstatePrescription(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Renews a prescription.
    func renewPrescription(
        request: ServerRequest<Acme_Prescriptions_V1_RenewPrescriptionRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_RenewPrescriptionResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRenewPrescription(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Schedules a prescription.
    func schedulePrescriptionExpiry(
        request: ServerRequest<Acme_Prescriptions_V1_SchedulePrescriptionExpiryRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_SchedulePrescriptionExpiryResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSchedulePrescriptionExpiry(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Suspends a prescription.
    func suspendPrescription(
        request: ServerRequest<Acme_Prescriptions_V1_SuspendPrescriptionRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_SuspendPrescriptionResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSuspendPrescription(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Terminates a prescription.
    func terminatePrescription(
        request: ServerRequest<Acme_Prescriptions_V1_TerminatePrescriptionRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_TerminatePrescriptionResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processTerminatePrescription(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processActivatePrescription(_ input: Acme_Prescriptions_V1_ActivatePrescriptionRequest) async throws
        -> Acme_Prescriptions_V1_ActivatePrescriptionResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "audit", detail: input.details.newOwner.email
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ActivatePrescription",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "ActivatePrescription", detail: input.context.traceID
        )
        try followUps.submit(
            Acme_Identity_V1_GetUserRequest.with {
                $0.context = input.context
                $0.userID = input.context.actor.userID
            })
        let importFrame = Acme_Prescriptions_V1_ImportRefillsRequest.with {
            $0.context = input.context
        }
        _ = try await self.prescriptionsRefillImport.importRefills { writer in
            try await writer.write(importFrame)
        }
        let outbound0 = Acme_Patients_V1_ScoreMedicalRecordRequest.with {
            $0.context = input.context
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = input.details.newOwner.displayName
                }
            }
        }
        let reply0 = try await self.patientsMedicalRecordValidation.scoreMedicalRecord(outbound0)
        let outbound1 = Acme_Prescriptions_V1_ExplainRefillCalculationRequest.with {
            $0.context = input.context
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply0.medicalRecord.counterparty.displayName
                }
                $0.customer = Acme_Prescriptions_V1_PrescriptionRef.with {
                    $0.displayName = input.details.newOwner.displayName
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply0.medicalRecord.counterparty.email
                    $0.preferredChannel = input.details.notifyContact.preferredChannel
                }
            }
        }
        async let remote1 = self.prescriptionsRefillCalculation.explainRefillCalculation(outbound1)
        async let persisted1 = store.count(tenant: input.context.tenantID)
        let (reply1, count1) = try await (remote1, persisted1)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count1)])
        let outbound2 = Acme_Patients_V1_ExplainMedicalRecordCalculationRequest.with {
            $0.context = input.context
            $0.details = Acme_Patients_V1_ExplainMedicalRecordCalculationRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.preferredChannel = input.details.notifyContact.preferredChannel
                }
            }
        }
        let reply2 = try await self.activatePrescriptionStep2.execute(outbound2)
        let outbound3 = Acme_Telehealth_V1_ListPendingTriagesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Telehealth_V1_ListPendingTriagesRequest.Filter.with {
                $0.createdAfter = reply2.medicalRecord.audit.updatedAt
                $0.region = reply2.medicalRecord.billingAddress.region
            }
        }
        let port3 = RPCOperations.port { (request: Acme_Telehealth_V1_ListPendingTriagesRequest) in
            try await self.telehealthTriageApproval.listPendingTriages(request)
        }
        let reply3 = try await port3.execute(outbound3)
        return Acme_Prescriptions_V1_ActivatePrescriptionResponse.with {
            $0.outcome = Acme_Prescriptions_V1_ActivatePrescriptionResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
                $0.message = reply3.result.message
            }
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = Projection.firstValue(
                        [
                            reply1.refill.customer.displayName,
                            reply2.medicalRecord.counterparty.displayName,
                        ], default: .init())
                    $0.email = reply0.medicalRecord.counterparty.email
                }
                $0.number = reply2.medicalRecord.number
                $0.prescriptionID = input.prescriptionID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply1.result.message
                $0.referenceIds = reply3.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processExpirePrescription(_ input: Acme_Prescriptions_V1_ExpirePrescriptionRequest) async throws
        -> Acme_Prescriptions_V1_ExpirePrescriptionResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "audit", detail: input.details.newOwner.displayName
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ExpirePrescription",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "ExpirePrescription", detail: input.context.traceID
        )
        let outbound0 = Acme_Prescriptions_V1_CalculateMedicationRequest.with {
            $0.context = input.context
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.email = input.details.newOwner.email
                    $0.userID = input.details.newOwner.userID
                }
            }
        }
        let reply0 = try await self.expirePrescriptionStep0(outbound0)
        let outbound1 = Acme_Prescriptions_V1_ResolveRefillConflictRequest.with {
            $0.context = input.context
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.email = input.details.newOwner.email
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply0.medication.audit.createdBy
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.phone = input.details.notifyContact.phone
                }
            }
        }
        guard let execute1 = self.expirePrescriptionStep1[settings.region] ?? self.expirePrescriptionStep1["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply1 = try await execute1(outbound1)
        return Acme_Prescriptions_V1_ExpirePrescriptionResponse.with {
            $0.outcome = Acme_Prescriptions_V1_ExpirePrescriptionResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
                $0.message = reply1.result.message
            }
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply1.refill.audit.createdBy
                }
                $0.prescriptionID = input.prescriptionID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processReinstatePrescription(_ input: Acme_Prescriptions_V1_ReinstatePrescriptionRequest) async throws
        -> Acme_Prescriptions_V1_ReinstatePrescriptionResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "audit", detail: input.details.newOwner.displayName
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ReinstatePrescription",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "ReinstatePrescription", detail: input.context.traceID
        )
        let outbound0 = Acme_Prescriptions_V1_SyncMedicationsRequest.with {
            $0.context = input.context
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.details.newOwner.userID
                }
            }
        }
        let reply0 = try await self.prescriptionsMedicationSync.syncMedications(outbound0)
        let outbound1 = Acme_Careplans_V1_ScheduleVitalReportRequest.with {
            $0.annotations = input.annotations
            $0.context = input.context
            $0.details = Acme_Careplans_V1_ScheduleVitalReportRequest.Details.with {
                $0.filters = reply0.result.details
            }
            $0.reason = input.reason
        }
        let envelope1 = try Google_Protobuf_Any(message: outbound1)
        let unpacked1 = try Acme_Careplans_V1_ScheduleVitalReportRequest(unpackingAny: envelope1)
        let reply1 = try await self.careplansVitalReporting.scheduleVitalReport(unpacked1)
        let outbound2 = Acme_Compliance_V1_BatchGetComplianceCasesRequest.with {
            $0.context = input.context
        }
        let json2 = try outbound2.jsonString()
        let decoded2 = try Acme_Compliance_V1_BatchGetComplianceCasesRequest(jsonString: json2)
        let reply2 = try await self.complianceComplianceCase.batchGetComplianceCases(decoded2)
        return Acme_Prescriptions_V1_ReinstatePrescriptionResponse.with {
            $0.outcome = Acme_Prescriptions_V1_ReinstatePrescriptionResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
            }
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.prescriptionID = input.prescriptionID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply2.result.details
                $0.message = reply2.result.message
                $0.status = Projection.firstValue(
                    [
                        reply0.result.status,
                        reply1.result.status,
                    ], default: .init())
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processRenewPrescription(_ input: Acme_Prescriptions_V1_RenewPrescriptionRequest) async throws
        -> Acme_Prescriptions_V1_RenewPrescriptionResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "audit", detail: input.details.newOwner.displayName
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "RenewPrescription",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "RenewPrescription", detail: input.context.traceID
        )
        let outbound0 =
            Acme_Prescriptions_V1_ResolvePrescriptionsRequest.forPrescriptionLifecycleEndpointRenewPrescription0(
                input
            )
        let reply0 = try await self.prescriptionsPrescriptionQuery.resolvePrescriptions(outbound0)
        let outbound1 = Acme_Prescriptions_V1_CountPrescriptionsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Prescriptions_V1_CountPrescriptionsRequest.Filter.with {
                $0.createdAfter = input.details.effectiveAt
                $0.labels = input.annotations
                $0.ownerID = input.details.newOwner.userID
            }
        }
        let reply1 = try await self.prescriptionsPrescriptionQuery.countPrescriptions(
            outbound1, metadata: ["x-acme-region": .string(settings.region)]
        )
        return Acme_Prescriptions_V1_RenewPrescriptionResponse.with {
            $0.outcome = Acme_Prescriptions_V1_RenewPrescriptionResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
                $0.message = reply0.result.message
            }
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.prescriptionID = input.prescriptionID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.referenceIds = reply1.result.referenceIds
                $0.status = reply1.result.status
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processSchedulePrescriptionExpiry(_ input: Acme_Prescriptions_V1_SchedulePrescriptionExpiryRequest)
        async throws -> Acme_Prescriptions_V1_SchedulePrescriptionExpiryResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "audit", detail: input.details.initiatedBy
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "SchedulePrescriptionExpiry",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PrescriptionRecord(input.prescription, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Patients_V1_SummarizeMedicalRecordsRequest.with {
            $0.context = input.context
            $0.reason = input.reason
        }
        let reply0 = try await RPCOperations.call(outbound0) { request in
            try await self.patientsMedicalRecordQuery.summarizeMedicalRecords(request)
        }
        let outbound1 = Acme_Metrics_V1_CheckMetricSeriesEligibilityRequest.with {
            $0.context = Projection.read(input, at: \Acme_Prescriptions_V1_SchedulePrescriptionExpiryRequest.context)
            $0.metricSeries = Acme_Metrics_V1_MetricSeries.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = Projection.read(
                        input, at: \Acme_Prescriptions_V1_SchedulePrescriptionExpiryRequest.prescription.audit.updatedBy
                    )
                }
            }
        }
        let reply1 = try await self.metricsMetricSeriesValidation.checkMetricSeriesEligibility(outbound1)
        let selection2_1: String
        switch reply1.metricSeries.locator {
        case .address(let address):
            selection2_1 = address.region
        default: selection2_1 = .init()
        }
        let outbound2 = Acme_Audit_V1_SuggestAuditEventsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Audit_V1_SuggestAuditEventsRequest.Filter.with {
                $0.createdAfter = input.prescription.audit.createdAt
                $0.labels = input.prescription.metadata
                $0.ownerID = reply1.metricSeries.components["primary", default: .init()].componentID
                $0.region = selection2_1
            }
        }
        let reply2 = try await self.auditAuditEventQuery.suggestAuditEvents(outbound2)
        let outbound3 = Acme_Search_V1_PreviewSearchIndexRequest.with {
            $0.context = input.context
            $0.details = Acme_Search_V1_PreviewSearchIndexRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.phone = input.details.notify.phone
                }
            }
            $0.searchIndex = Acme_Search_V1_SearchIndex.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply1.metricSeries.audit.createdBy
                }
            }
        }
        let step3: @Sendable () async throws -> Acme_Search_V1_PreviewSearchIndexResponse = {
            try await self.searchSearchIndexValidation.previewSearchIndex(outbound3)
        }
        let reply3 = try await step3()
        return Acme_Prescriptions_V1_SchedulePrescriptionExpiryResponse.with {
            $0.outcome = Acme_Prescriptions_V1_SchedulePrescriptionExpiryResponse.Outcome.with {
                $0.message = reply1.result.message
                $0.referenceID = reply3.outcome.referenceID
            }
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply1.metricSeries.audit.etag
                }
                $0.issuedAt = input.prescription.issuedAt
                $0.prescriptionID = input.prescriptionID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.message = reply2.result.message
                $0.referenceIds = reply2.result.referenceIds + reply3.result.referenceIds
                $0.status = reply0.result.status
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processSuspendPrescription(_ input: Acme_Prescriptions_V1_SuspendPrescriptionRequest) async throws
        -> Acme_Prescriptions_V1_SuspendPrescriptionResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "audit", detail: input.details.newOwner.displayName
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "SuspendPrescription",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "SuspendPrescription", detail: input.context.traceID
        )
        var outbound0 = Acme_Telehealth_V1_ListPendingTriagesRequest()
        outbound0.context = input.context
        outbound0.filter = Acme_Telehealth_V1_ListPendingTriagesRequest.Filter.with {
            $0.createdAfter = input.details.effectiveAt
            $0.labels = input.annotations
            $0.ownerID = input.details.newOwner.userID
        }
        let reply0 = try await self.telehealthTriageApproval.listPendingTriages(outbound0)
        let outbound1 = Acme_Telehealth_V1_StartVideoVisitWorkflowRequest.with {
            $0.context = input.context
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.participants = [
                    Acme_Telehealth_V1_VideoVisitParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = input.details.newOwner.email
                            $0.name = input.details.notifyContact.name
                        }
                    }
                ]
            }
        }
        let step1: @Sendable () async throws -> Acme_Telehealth_V1_StartVideoVisitWorkflowResponse = {
            try await self.telehealthVideoVisitWorkflow.startVideoVisitWorkflow(outbound1)
        }
        let reply1 = try await step1()
        return Acme_Prescriptions_V1_SuspendPrescriptionResponse.with {
            $0.outcome = Acme_Prescriptions_V1_SuspendPrescriptionResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
            }
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply1.videoVisit.audit.updatedAt
                }
                $0.prescriptionID = input.prescriptionID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processTerminatePrescription(_ input: Acme_Prescriptions_V1_TerminatePrescriptionRequest) async throws
        -> Acme_Prescriptions_V1_TerminatePrescriptionResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "audit", detail: input.details.newOwner.displayName
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "TerminatePrescription",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "TerminatePrescription", detail: input.context.traceID
        )
        let outbound0 = Acme_Prescriptions_V1_SuggestMedicationsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Prescriptions_V1_SuggestMedicationsRequest.Filter.with {
                $0.createdAfter = input.details.effectiveAt
                $0.labels = input.annotations
            }
        }
        let reply0 = try await self.prescriptionsMedicationQuery.suggestMedications(outbound0)
        let outbound1 = Acme_Search_V1_LintSearchIndexesRequest.with {
            $0.context = input.context
            $0.details = Acme_Search_V1_LintSearchIndexesRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.notifyContact.email
                }
            }
            $0.searchIndex = Acme_Search_V1_SearchIndex.with {
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.email = input.details.newOwner.email
                    $0.userID = input.details.newOwner.userID
                }
            }
        }
        async let remote1 = self.searchSearchIndexValidation.lintSearchIndexes(outbound1)
        async let persisted1 = store.count(tenant: input.context.tenantID)
        let (reply1, count1) = try await (remote1, persisted1)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count1)])
        return Acme_Prescriptions_V1_TerminatePrescriptionResponse.with {
            $0.outcome = Acme_Prescriptions_V1_TerminatePrescriptionResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
            }
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.lines = reply1.searchIndex.address.lines
                }
                $0.lines = [
                    Acme_Prescriptions_V1_PrescriptionLine.with {
                        $0.quantity = reply1.searchIndex.components["primary", default: .init()].quantity
                    }
                ]
                $0.prescriptionID = input.prescriptionID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }
}
