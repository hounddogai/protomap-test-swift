import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Keeps refills in step with the systems of record in other regions.
final class RefillSyncEndpoint: Acme_Prescriptions_V1_RefillSyncService.ServiceProtocol {
    private let store: any RecordRepository
    private let logger: Logger
    private let settings: Settings
    private let followUps = WorkQueue<Acme_Identity_V1_GetUserRequest>()
    private let careplansCareGoalApproval: Acme_Careplans_V1_CareGoalApprovalService.Client<MeshTransport>
    private let careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>
    private let careplansVitalReporting: Acme_Careplans_V1_VitalReportingService.Client<MeshTransport>
    private let catalogProductQuery: Acme_Catalog_V1_ProductQueryService.Client<MeshTransport>
    private let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    private let patientsPatient: Acme_Patients_V1_PatientService.Client<MeshTransport>
    private let patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client<MeshTransport>
    private let prescriptionsPrescriptionValidation:
        Acme_Prescriptions_V1_PrescriptionValidationService.Client<MeshTransport>
    private let prescriptionsRefillImport: Acme_Prescriptions_V1_RefillImportService.Client<MeshTransport>
    private let telehealthVideoVisitApproval: Acme_Telehealth_V1_VideoVisitApprovalService.Client<MeshTransport>
    private let telehealthVisitNoteLifecycle: Acme_Telehealth_V1_VisitNoteLifecycleService.Client<MeshTransport>
    private let pushRefillStep1:
        any RPCPort<
            Acme_Telehealth_V1_ScheduleVisitNoteExpiryRequest, Acme_Telehealth_V1_ScheduleVisitNoteExpiryResponse
        >
    private let reconcileRefillsStep2:
        @Sendable (Acme_Patients_V1_ListPatientsRequest) async throws -> Acme_Patients_V1_ListPatientsResponse
    private let reconcileRefillsStep3:
        [String:
            @Sendable (Acme_Prescriptions_V1_ScorePrescriptionRequest) async throws ->
            Acme_Prescriptions_V1_ScorePrescriptionResponse]

    init(
        dependencies: any Dependencies,
        careplansCareGoalApproval: Acme_Careplans_V1_CareGoalApprovalService.Client<MeshTransport>,
        careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>,
        careplansVitalReporting: Acme_Careplans_V1_VitalReportingService.Client<MeshTransport>,
        catalogProductQuery: Acme_Catalog_V1_ProductQueryService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        patientsPatient: Acme_Patients_V1_PatientService.Client<MeshTransport>,
        patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client<MeshTransport>,
        prescriptionsPrescriptionValidation: Acme_Prescriptions_V1_PrescriptionValidationService.Client<MeshTransport>,
        prescriptionsRefillImport: Acme_Prescriptions_V1_RefillImportService.Client<MeshTransport>,
        telehealthVideoVisitApproval: Acme_Telehealth_V1_VideoVisitApprovalService.Client<MeshTransport>,
        telehealthVisitNoteLifecycle: Acme_Telehealth_V1_VisitNoteLifecycleService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.careplansCareGoalApproval = careplansCareGoalApproval
        self.careplansCarePlan = careplansCarePlan
        self.careplansVitalReporting = careplansVitalReporting
        self.catalogProductQuery = catalogProductQuery
        self.identityUser = identityUser
        self.patientsPatient = patientsPatient
        self.patientsPatientQuery = patientsPatientQuery
        self.prescriptionsPrescriptionValidation = prescriptionsPrescriptionValidation
        self.prescriptionsRefillImport = prescriptionsRefillImport
        self.telehealthVideoVisitApproval = telehealthVideoVisitApproval
        self.telehealthVisitNoteLifecycle = telehealthVisitNoteLifecycle
        self.pushRefillStep1 = ClosurePort<
            Acme_Telehealth_V1_ScheduleVisitNoteExpiryRequest, Acme_Telehealth_V1_ScheduleVisitNoteExpiryResponse
        >({ request in try await telehealthVisitNoteLifecycle.scheduleVisitNoteExpiry(request) })
        self.reconcileRefillsStep2 = { request in try await patientsPatient.listPatients(request) }
        self.reconcileRefillsStep3 = [
            "primary": { request in try await prescriptionsPrescriptionValidation.scorePrescription(request) }
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

    /// Returns a refill.
    func getRefillSyncState(
        request: ServerRequest<Acme_Prescriptions_V1_GetRefillSyncStateRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_GetRefillSyncStateResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetRefillSyncState(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists refills a page at a time.
    func listRefillConflicts(
        request: ServerRequest<Acme_Prescriptions_V1_ListRefillConflictsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ListRefillConflictsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListRefillConflicts(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Pushs a refill.
    func pushRefill(
        request: ServerRequest<Acme_Prescriptions_V1_PushRefillRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_PushRefillResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processPushRefill(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Reconciles a refill.
    func reconcileRefills(
        request: ServerRequest<Acme_Prescriptions_V1_ReconcileRefillsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ReconcileRefillsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processReconcileRefills(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Resolves a refill.
    func resolveRefillConflict(
        request: ServerRequest<Acme_Prescriptions_V1_ResolveRefillConflictRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ResolveRefillConflictResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processResolveRefillConflict(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Syncs a refill.
    func syncRefills(
        request: ServerRequest<Acme_Prescriptions_V1_SyncRefillsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_SyncRefillsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSyncRefills(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processGetRefillSyncState(_ input: Acme_Prescriptions_V1_GetRefillSyncStateRequest) async throws
        -> Acme_Prescriptions_V1_GetRefillSyncStateResponse
    {
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "GetRefillSyncState",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "GetRefillSyncState", detail: input.context.traceID
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
        var outbound0 = Acme_Patients_V1_CreatePatientRequest()
        outbound0.context = input.context
        outbound0.patient = Acme_Patients_V1_Patient.with {
            $0.audit = Acme_Common_V1_AuditInfo.with {
                $0.updatedAt = input.context.deadline
            }
            $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                $0.email = input.context.actor.email
                $0.userID = input.context.actor.userID
            }
            $0.segments = input.context.actor.roles
        }
        let reply0 = try await self.patientsPatient.createPatient(outbound0)
        return Acme_Prescriptions_V1_GetRefillSyncStateResponse.with {
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.refillID = input.refillID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply0.result.status
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processListRefillConflicts(_ input: Acme_Prescriptions_V1_ListRefillConflictsRequest) async throws
        -> Acme_Prescriptions_V1_ListRefillConflictsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "audit", detail: input.filter.ownerID
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ListRefillConflicts",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "ListRefillConflicts", detail: input.context.traceID
        )
        let outbound0 = Acme_Catalog_V1_BrowseProductsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Catalog_V1_BrowseProductsRequest.Filter.with {
                $0.labels = input.filter.labels
                $0.query = input.filter.query
            }
            $0.orderBy = input.orderBy
            $0.page = Acme_Common_V1_PageRequest.with {
                $0.pageSize = input.page.pageSize
            }
        }
        let reply0 = try await RPCOperations.read {
            try await self.catalogProductQuery.browseProducts(outbound0)
        }
        let outbound1 = Acme_Telehealth_V1_ListPendingVideoVisitsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Telehealth_V1_ListPendingVideoVisitsRequest.Filter.with {
                $0.region = input.filter.region
            }
            $0.page = Acme_Common_V1_PageRequest.with {
                $0.pageSize = input.page.pageSize
            }
        }
        let reply1 = try await self.telehealthVideoVisitApproval.listPendingVideoVisits(outbound1)
        return Acme_Prescriptions_V1_ListRefillConflictsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.message = reply0.result.message
                $0.status = reply1.result.status
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processPushRefill(_ input: Acme_Prescriptions_V1_PushRefillRequest) async throws
        -> Acme_Prescriptions_V1_PushRefillResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.checksum)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "audit", detail: input.details.checksum
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "PushRefill",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try RefillRecord(input.refill, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Careplans_V1_ScheduleVitalReportRequest.with {
            $0.annotations = input.annotations
            $0.context = input.context
        }
        async let remote0 = self.careplansVitalReporting.scheduleVitalReport(outbound0)
        async let persisted0 = store.count(tenant: input.context.tenantID)
        let (reply0, count0) = try await (remote0, persisted0)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count0)])
        let outbound1 = Acme_Telehealth_V1_ScheduleVisitNoteExpiryRequest.with {
            $0.context = input.context
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = input.refill.audit.createdBy
                }
            }
        }
        let reply1 = try await self.pushRefillStep1.execute(outbound1)
        return Acme_Prescriptions_V1_PushRefillResponse.with {
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.assignee = input.refill.assignee
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply1.visitNote.audit.updatedBy
                }
                $0.comments = [
                    Acme_Prescriptions_V1_RefillComment.with {
                        $0.createdAt = reply1.visitNote.audit.createdAt
                    }
                ]
                $0.refillID = input.refillID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.status = reply0.result.status
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processReconcileRefills(_ input: Acme_Prescriptions_V1_ReconcileRefillsRequest) async throws
        -> Acme_Prescriptions_V1_ReconcileRefillsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.checksum)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "audit", detail: input.details.checksum
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ReconcileRefills",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try RefillRecord(input.refill, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let requests0 = input.refill.history.map { element in
            Acme_Prescriptions_V1_ValidatePrescriptionRequest.with {
                $0.context = input.context
                $0.details = Acme_Prescriptions_V1_ValidatePrescriptionRequest.Details.with {
                    $0.contact = Acme_Common_V1_ContactInfo.with {
                        $0.name = input.refill.requester.name
                    }
                }
                $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                    $0.audit = Acme_Common_V1_AuditInfo.with {
                        $0.updatedAt = element.changedAt
                    }
                    $0.counterparty = Acme_Patients_V1_PatientRef.with {
                        $0.displayName = input.refill.customer.displayName
                    }
                    $0.prescriptionID = input.refill.customer.prescriptionID
                }
            }
        }
        let replies0 = try await FanOut.map(requests0) { candidate in
            try await self.prescriptionsPrescriptionValidation.validatePrescription(candidate)
        }
        let reply0 = replies0.first ?? Acme_Prescriptions_V1_ValidatePrescriptionResponse()
        let outbound1 = Acme_Prescriptions_V1_ListRefillImportsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Prescriptions_V1_ListRefillImportsRequest.Filter.with {
                $0.region = reply0.prescription.billingAddress.region
            }
        }
        let port1 = RPCOperations.port { (request: Acme_Prescriptions_V1_ListRefillImportsRequest) in
            try await self.prescriptionsRefillImport.listRefillImports(request)
        }
        let reply1 = try await port1.execute(outbound1)
        let outbound2 = Acme_Patients_V1_ListPatientsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Patients_V1_ListPatientsRequest.Filter.with {
                $0.createdAfter = reply0.prescription.issuedAt
                $0.labels = reply0.prescription.metadata
                $0.ownerID = input.refill.refillID
                $0.region = reply0.prescription.billingAddress.region
            }
        }
        let reply2 = try await self.reconcileRefillsStep2(outbound2)
        let outbound3 = Acme_Prescriptions_V1_ScorePrescriptionRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_ScorePrescriptionRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = reply0.prescription.billingAddress.countryCode
                }
            }
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply0.prescription.audit.updatedBy
                }
            }
        }
        guard let execute3 = self.reconcileRefillsStep3[settings.region] ?? self.reconcileRefillsStep3["primary"] else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply3 = try await execute3(outbound3)
        return Acme_Prescriptions_V1_ReconcileRefillsResponse.with {
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply3.prescription.audit.createdBy
                }
                $0.priority = input.refill.priority
                $0.refillID = input.refillID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply1.result.details
                $0.message = reply2.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processResolveRefillConflict(_ input: Acme_Prescriptions_V1_ResolveRefillConflictRequest) async throws
        -> Acme_Prescriptions_V1_ResolveRefillConflictResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.checksum)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "audit", detail: input.details.checksum
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ResolveRefillConflict",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try RefillRecord(input.refill, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let requests0 = input.refill.history.map { element in
            Acme_Careplans_V1_RejectCareGoalRequest.with {
                $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                    $0.history = [
                        Acme_Careplans_V1_CareGoalStatusChange.with {
                            $0.changedAt = element.changedAt
                        }
                    ]
                }
                $0.context = input.context
            }
        }
        let replies0 = try await FanOut.map(requests0) { candidate in
            try await self.careplansCareGoalApproval.rejectCareGoal(candidate)
        }
        let reply0 = replies0.first ?? Acme_Careplans_V1_RejectCareGoalResponse()
        _ = reply0
        return Acme_Prescriptions_V1_ResolveRefillConflictResponse.with {
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.customFields = input.refill.customFields
                $0.refillID = input.refillID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processSyncRefills(_ input: Acme_Prescriptions_V1_SyncRefillsRequest) async throws
        -> Acme_Prescriptions_V1_SyncRefillsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.checksum)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "audit", detail: input.details.checksum
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "SyncRefills",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try RefillRecord(input.refill, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Patients_V1_BrowsePatientsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Patients_V1_BrowsePatientsRequest.Filter.with {
                $0.createdAfter = input.refill.sla.dueAt
                $0.labels = input.annotations
                $0.ownerID = input.refill.refillID
            }
        }
        let reply0 = try await self.patientsPatientQuery.browsePatients(outbound0)
        let requests1 = input.refill.comments.map { element in
            Acme_Telehealth_V1_DelegateVideoVisitApprovalRequest.with {
                $0.context = input.context
                $0.details = Acme_Telehealth_V1_DelegateVideoVisitApprovalRequest.Details.with {
                    $0.approver = Acme_Identity_V1_UserRef.with {
                        $0.email = element.authorEmail
                    }
                }
                $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                    $0.audit = Acme_Common_V1_AuditInfo.with {
                        $0.createdAt = element.createdAt
                    }
                }
            }
        }
        let replies1 = try await FanOut.map(requests1) { candidate in
            try await self.telehealthVideoVisitApproval.delegateVideoVisitApproval(candidate)
        }
        let reply1 = replies1.first ?? Acme_Telehealth_V1_DelegateVideoVisitApprovalResponse()
        _ = reply1
        return Acme_Prescriptions_V1_SyncRefillsResponse.with {
            $0.outcome = Acme_Prescriptions_V1_SyncRefillsResponse.Outcome.with {
                $0.message = reply0.result.message
            }
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.refillID = input.refillID
                $0.status = input.refill.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.status = "ok"
            }
        }
    }
}
