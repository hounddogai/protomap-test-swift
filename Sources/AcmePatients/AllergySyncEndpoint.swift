import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Keeps allergies in step with the systems of record in other regions.
final class AllergySyncEndpoint: Acme_Patients_V1_AllergySyncService.ServiceProtocol {
    private let store: any RecordRepository
    private let logger: Logger
    private let settings: Settings
    private let followUps = WorkQueue<Acme_Identity_V1_GetUserRequest>()
    private let careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>
    private let careplansVitalWorkflow: Acme_Careplans_V1_VitalWorkflowService.Client<MeshTransport>
    private let certificatesCertificate: Acme_Certificates_V1_CertificateService.Client<MeshTransport>
    private let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    private let metricsMetricSeries: Acme_Metrics_V1_MetricSeriesService.Client<MeshTransport>
    private let metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client<MeshTransport>
    private let patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>
    private let patientsMedicalRecordQuery: Acme_Patients_V1_MedicalRecordQueryService.Client<MeshTransport>
    private let patientsPatientCalculation: Acme_Patients_V1_PatientCalculationService.Client<MeshTransport>
    private let patientsPatientValidation: Acme_Patients_V1_PatientValidationService.Client<MeshTransport>
    private let prescriptionsPrescriptionApproval:
        Acme_Prescriptions_V1_PrescriptionApprovalService.Client<MeshTransport>
    private let prescriptionsRefillLifecycle: Acme_Prescriptions_V1_RefillLifecycleService.Client<MeshTransport>

    init(
        dependencies: any Dependencies,
        careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>,
        careplansVitalWorkflow: Acme_Careplans_V1_VitalWorkflowService.Client<MeshTransport>,
        certificatesCertificate: Acme_Certificates_V1_CertificateService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        metricsMetricSeries: Acme_Metrics_V1_MetricSeriesService.Client<MeshTransport>,
        metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client<MeshTransport>,
        patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>,
        patientsMedicalRecordQuery: Acme_Patients_V1_MedicalRecordQueryService.Client<MeshTransport>,
        patientsPatientCalculation: Acme_Patients_V1_PatientCalculationService.Client<MeshTransport>,
        patientsPatientValidation: Acme_Patients_V1_PatientValidationService.Client<MeshTransport>,
        prescriptionsPrescriptionApproval: Acme_Prescriptions_V1_PrescriptionApprovalService.Client<MeshTransport>,
        prescriptionsRefillLifecycle: Acme_Prescriptions_V1_RefillLifecycleService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.careplansCarePlan = careplansCarePlan
        self.careplansVitalWorkflow = careplansVitalWorkflow
        self.certificatesCertificate = certificatesCertificate
        self.identityUser = identityUser
        self.metricsMetricSeries = metricsMetricSeries
        self.metricsMetricSeriesValidation = metricsMetricSeriesValidation
        self.patientsMedicalRecordCalculation = patientsMedicalRecordCalculation
        self.patientsMedicalRecordQuery = patientsMedicalRecordQuery
        self.patientsPatientCalculation = patientsPatientCalculation
        self.patientsPatientValidation = patientsPatientValidation
        self.prescriptionsPrescriptionApproval = prescriptionsPrescriptionApproval
        self.prescriptionsRefillLifecycle = prescriptionsRefillLifecycle
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

    /// Returns an allergy.
    func getAllergySyncState(
        request: ServerRequest<Acme_Patients_V1_GetAllergySyncStateRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_GetAllergySyncStateResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetAllergySyncState(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists allergies a page at a time.
    func listAllergyConflicts(
        request: ServerRequest<Acme_Patients_V1_ListAllergyConflictsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_ListAllergyConflictsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListAllergyConflicts(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Pulls an allergy.
    func pullAllergies(
        request: ServerRequest<Acme_Patients_V1_PullAllergiesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_PullAllergiesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processPullAllergies(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Pushs an allergy.
    func pushAllergy(
        request: ServerRequest<Acme_Patients_V1_PushAllergyRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_PushAllergyResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processPushAllergy(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Reconciles an allergy.
    func reconcileAllergies(
        request: ServerRequest<Acme_Patients_V1_ReconcileAllergiesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_ReconcileAllergiesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processReconcileAllergies(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Resolves an allergy.
    func resolveAllergyConflict(
        request: ServerRequest<Acme_Patients_V1_ResolveAllergyConflictRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_ResolveAllergyConflictResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processResolveAllergyConflict(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Syncs an allergy.
    func syncAllergies(
        request: ServerRequest<Acme_Patients_V1_SyncAllergiesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_SyncAllergiesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSyncAllergies(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processGetAllergySyncState(_ input: Acme_Patients_V1_GetAllergySyncStateRequest) async throws
        -> Acme_Patients_V1_GetAllergySyncStateResponse
    {
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "GetAllergySyncState",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "GetAllergySyncState", detail: input.context.traceID
        )
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
                $0.attributes = input.context.baggage
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.context.deadline
                }
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.context.actor.email
                }
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.context.actor.userID
                }
            }
        }
        let envelope0 = try Google_Protobuf_Any(message: outbound0)
        let unpacked0 = try Acme_Patients_V1_RecalculatePatientsRequest(unpackingAny: envelope0)
        let reply0 = try await self.patientsPatientCalculation.recalculatePatients(unpacked0)
        return Acme_Patients_V1_GetAllergySyncStateResponse.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.allergyID = input.allergyID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.message = reply0.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processListAllergyConflicts(_ input: Acme_Patients_V1_ListAllergyConflictsRequest) async throws
        -> Acme_Patients_V1_ListAllergyConflictsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "audit", detail: input.filter.ownerID
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ListAllergyConflicts",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "ListAllergyConflicts", detail: input.context.traceID
        )
        return Acme_Patients_V1_ListAllergyConflictsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processPullAllergies(_ input: Acme_Patients_V1_PullAllergiesRequest) async throws
        -> Acme_Patients_V1_PullAllergiesResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.allergy.allergyID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "audit", detail: input.allergy.allergyID
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "PullAllergies",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try AllergyRecord(input.allergy, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Prescriptions_V1_ScheduleRefillExpiryRequest.with {
            $0.context = input.context
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.allergy.subject.displayName
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.allergy.subject.email
                }
            }
        }
        let json0 = try outbound0.jsonString()
        let decoded0 = try Acme_Prescriptions_V1_ScheduleRefillExpiryRequest(jsonString: json0)
        let reply0 = try await self.prescriptionsRefillLifecycle.scheduleRefillExpiry(decoded0)
        let requests1 = input.allergy.measurements.map { element in
            Acme_Careplans_V1_ResumeVitalWorkflowRequest.with {
                $0.context = input.context
                $0.vital = Acme_Careplans_V1_Vital.with {
                    $0.measurements = [
                        Acme_Careplans_V1_VitalMeasurement.with {
                            $0.metric = element.metric
                            $0.observedAt = element.observedAt
                            $0.unit = element.unit
                            $0.value = element.value
                        }
                    ]
                }
            }
        }
        let replies1 = try await FanOut.map(requests1) { candidate in
            try await self.careplansVitalWorkflow.resumeVitalWorkflow(candidate)
        }
        let reply1 = replies1.first ?? Acme_Careplans_V1_ResumeVitalWorkflowResponse()
        _ = reply1
        return Acme_Patients_V1_PullAllergiesResponse.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.allergyID = input.allergyID
                $0.source = input.allergy.source
            }
            $0.outcome = Acme_Patients_V1_PullAllergiesResponse.Outcome.with {
                $0.message = reply0.outcome.message
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.outcome.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processPushAllergy(_ input: Acme_Patients_V1_PushAllergyRequest) async throws
        -> Acme_Patients_V1_PushAllergyResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.allergy.allergyID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "audit", detail: input.allergy.allergyID
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "PushAllergy",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try AllergyRecord(input.allergy, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Patients_V1_ScorePatientRequest.forAllergySyncEndpointPushAllergy0(
            input
        )
        let reply0 = try await self.patientsPatientValidation.scorePatient(outbound0)
        let outbound1 = Acme_Certificates_V1_UpdateCertificateRequest.with {
            $0.certificate = Acme_Certificates_V1_Certificate.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply0.patient.audit.etag
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.locality = reply0.patient.primaryAddress.locality
                    $0.postalCode = reply0.patient.primaryAddress.postalCode
                }
            }
            $0.context = input.context
        }
        let reply1 = try await self.certificatesCertificate.updateCertificate(
            outbound1, metadata: ["x-acme-region": .string(settings.region)]
        )
        return Acme_Patients_V1_PushAllergyResponse.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.allergyID = input.allergyID
                $0.attributes = reply0.patient.attributes
                $0.correlationID = reply1.result.correlationID
                $0.occurredAt = input.allergy.occurredAt
            }
            $0.outcome = Acme_Patients_V1_PushAllergyResponse.Outcome.with {
                $0.message = Projection.firstValue(
                    [
                        reply0.result.message,
                        reply1.result.message,
                    ], default: .init())
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processReconcileAllergies(_ input: Acme_Patients_V1_ReconcileAllergiesRequest) async throws
        -> Acme_Patients_V1_ReconcileAllergiesResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.allergy.allergyID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "audit", detail: input.allergy.allergyID
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ReconcileAllergies",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try AllergyRecord(input.allergy, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let requests0 = input.allergy.measurements.map { element in
            Acme_Metrics_V1_UpdateMetricSeriesRequest.with {
                $0.context = input.context
                $0.metricSeries = Acme_Metrics_V1_MetricSeries.with {
                    $0.audit = Acme_Common_V1_AuditInfo.with {
                        $0.updatedAt = element.observedAt
                    }
                    $0.dimensions = Acme_Metrics_V1_MetricSeriesDimensions.with {
                        $0.unit = element.unit
                    }
                    $0.owner = Acme_Identity_V1_UserRef.with {
                        $0.displayName = input.allergy.subject.displayName
                        $0.email = input.allergy.subject.email
                    }
                }
            }
        }
        let replies0 = try await FanOut.map(requests0) { candidate in
            try await self.metricsMetricSeries.updateMetricSeries(candidate)
        }
        let reply0 = replies0.first ?? Acme_Metrics_V1_UpdateMetricSeriesResponse()
        _ = reply0
        return Acme_Patients_V1_ReconcileAllergiesResponse.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.allergyID = input.allergyID
                $0.source = input.allergy.source
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processResolveAllergyConflict(_ input: Acme_Patients_V1_ResolveAllergyConflictRequest) async throws
        -> Acme_Patients_V1_ResolveAllergyConflictResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.allergy.allergyID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "audit", detail: input.allergy.allergyID
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ResolveAllergyConflict",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try AllergyRecord(input.allergy, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Patients_V1_EstimateMedicalRecordRequest.with {
            $0.context = input.context
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = input.allergy.subject.displayName
                    $0.email = input.allergy.subject.email
                }
            }
        }
        let reply0 = try await RPCOperations.call(outbound0) { request in
            try await self.patientsMedicalRecordCalculation.estimateMedicalRecord(request)
        }
        let selection1_1: String
        switch reply0.medicalRecord.settlement {
        case .card(let card):
            selection1_1 = card.token
        default: selection1_1 = .init()
        }
        let outbound1 = Acme_Prescriptions_V1_DelegatePrescriptionApprovalRequest.with {
            $0.context = input.context
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.card = Acme_Prescriptions_V1_PrescriptionCardSettlement.with {
                    $0.token = selection1_1
                }
            }
        }
        let reply1 = try await self.prescriptionsPrescriptionApproval.delegatePrescriptionApproval(outbound1)
        return Acme_Patients_V1_ResolveAllergyConflictResponse.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.allergyID = input.allergyID
                $0.sequence = input.allergy.sequence
            }
            $0.outcome = Acme_Patients_V1_ResolveAllergyConflictResponse.Outcome.with {
                $0.status = reply1.outcome.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply0.result.status
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processSyncAllergies(_ input: Acme_Patients_V1_SyncAllergiesRequest) async throws
        -> Acme_Patients_V1_SyncAllergiesResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.allergy.allergyID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "audit", detail: input.allergy.allergyID
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "SyncAllergies",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try AllergyRecord(input.allergy, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Metrics_V1_ScoreMetricSeriesRequest.with {
            $0.annotations = input.annotations
            $0.context = Projection.read(input, at: \Acme_Patients_V1_SyncAllergiesRequest.context)
            $0.metricSeries = Acme_Metrics_V1_MetricSeries.with {
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.displayName = Projection.read(
                        input, at: \Acme_Patients_V1_SyncAllergiesRequest.allergy.subject.displayName)
                    $0.email = Projection.read(input, at: \Acme_Patients_V1_SyncAllergiesRequest.allergy.subject.email)
                }
            }
            $0.reason = Projection.read(input, at: \Acme_Patients_V1_SyncAllergiesRequest.reason)
        }
        let reply0 = try await self.metricsMetricSeriesValidation.scoreMetricSeries(outbound0)
        let outbound1 = Acme_Patients_V1_ExportMedicalRecordsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Patients_V1_ExportMedicalRecordsRequest.Filter.with {
                $0.createdAfter = reply0.metricSeries.audit.createdAt
                $0.ownerID = reply0.result.correlationID
                $0.region = reply0.metricSeries.address.region
            }
        }
        let reply1 = try await self.patientsMedicalRecordQuery.exportMedicalRecords(outbound1) { response in
            var latest = Acme_Patients_V1_ExportMedicalRecordsResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        _ = reply1
        return Acme_Patients_V1_SyncAllergiesResponse.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.allergyID = input.allergyID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = input.allergy.correlationID
                $0.message = reply0.result.message
                $0.status = "ok"
            }
        }
    }
}
