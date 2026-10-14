import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Routes triages through approval, with escalation and delegation.
final class TriageApprovalEndpoint: Acme_Telehealth_V1_TriageApprovalService.ServiceProtocol {
    private let store: any RecordRepository
    private let logger: Logger
    private let settings: Settings
    private let careplansCarePlanQuery: Acme_Careplans_V1_CarePlanQueryService.Client<MeshTransport>
    private let careplansVitalApproval: Acme_Careplans_V1_VitalApprovalService.Client<MeshTransport>
    private let careplansVitalWorkflow: Acme_Careplans_V1_VitalWorkflowService.Client<MeshTransport>
    private let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    private let identityUserValidation: Acme_Identity_V1_UserValidationService.Client<MeshTransport>
    private let patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>
    private let patientsPatient: Acme_Patients_V1_PatientService.Client<MeshTransport>
    private let patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client<MeshTransport>
    private let telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client<MeshTransport>
    private let telehealthVisitNoteCalculation: Acme_Telehealth_V1_VisitNoteCalculationService.Client<MeshTransport>
    private let telehealthVisitNoteQuery: Acme_Telehealth_V1_VisitNoteQueryService.Client<MeshTransport>
    private let getTriageApprovalStatusStep1:
        any RPCPort<Acme_Telehealth_V1_SimulateVideoVisitRequest, Acme_Telehealth_V1_SimulateVideoVisitResponse>
    private let listPendingTriagesStep1:
        @Sendable (Acme_Identity_V1_ListUsersRequest) async throws -> Acme_Identity_V1_ListUsersResponse
    private let submitTriageStep0:
        [String: @Sendable (Acme_Patients_V1_FindPatientsRequest) async throws -> Acme_Patients_V1_FindPatientsResponse]

    init(
        dependencies: any Dependencies,
        careplansCarePlanQuery: Acme_Careplans_V1_CarePlanQueryService.Client<MeshTransport>,
        careplansVitalApproval: Acme_Careplans_V1_VitalApprovalService.Client<MeshTransport>,
        careplansVitalWorkflow: Acme_Careplans_V1_VitalWorkflowService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        identityUserValidation: Acme_Identity_V1_UserValidationService.Client<MeshTransport>,
        patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>,
        patientsPatient: Acme_Patients_V1_PatientService.Client<MeshTransport>,
        patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client<MeshTransport>,
        telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client<MeshTransport>,
        telehealthVisitNoteCalculation: Acme_Telehealth_V1_VisitNoteCalculationService.Client<MeshTransport>,
        telehealthVisitNoteQuery: Acme_Telehealth_V1_VisitNoteQueryService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.careplansCarePlanQuery = careplansCarePlanQuery
        self.careplansVitalApproval = careplansVitalApproval
        self.careplansVitalWorkflow = careplansVitalWorkflow
        self.identityUser = identityUser
        self.identityUserValidation = identityUserValidation
        self.patientsMedicalRecordCalculation = patientsMedicalRecordCalculation
        self.patientsPatient = patientsPatient
        self.patientsPatientQuery = patientsPatientQuery
        self.telehealthVideoVisitCalculation = telehealthVideoVisitCalculation
        self.telehealthVisitNoteCalculation = telehealthVisitNoteCalculation
        self.telehealthVisitNoteQuery = telehealthVisitNoteQuery
        self.getTriageApprovalStatusStep1 = ClosurePort<
            Acme_Telehealth_V1_SimulateVideoVisitRequest, Acme_Telehealth_V1_SimulateVideoVisitResponse
        >({ request in try await telehealthVideoVisitCalculation.simulateVideoVisit(request) })
        self.listPendingTriagesStep1 = { request in try await identityUser.listUsers(request) }
        self.submitTriageStep0 = ["primary": { request in try await patientsPatientQuery.findPatients(request) }]
    }

    /// Approves a triage.
    func approveTriage(
        request: ServerRequest<Acme_Telehealth_V1_ApproveTriageRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_ApproveTriageResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processApproveTriage(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Comments a triage.
    func commentTriageApproval(
        request: ServerRequest<Acme_Telehealth_V1_CommentTriageApprovalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_CommentTriageApprovalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCommentTriageApproval(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Delegates a triage.
    func delegateTriageApproval(
        request: ServerRequest<Acme_Telehealth_V1_DelegateTriageApprovalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_DelegateTriageApprovalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processDelegateTriageApproval(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a triage.
    func getTriageApprovalStatus(
        request: ServerRequest<Acme_Telehealth_V1_GetTriageApprovalStatusRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_GetTriageApprovalStatusResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetTriageApprovalStatus(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists triages a page at a time.
    func listPendingTriages(
        request: ServerRequest<Acme_Telehealth_V1_ListPendingTriagesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_ListPendingTriagesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListPendingTriages(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Submits a triage.
    func submitTriage(
        request: ServerRequest<Acme_Telehealth_V1_SubmitTriageRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_SubmitTriageResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSubmitTriage(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processApproveTriage(_ input: Acme_Telehealth_V1_ApproveTriageRequest) async throws
        -> Acme_Telehealth_V1_ApproveTriageResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "triage",
            action: "audit", detail: input.details.approver.displayName
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ApproveTriage",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try TriageRecord(input.triage, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let importFrame = Acme_Patients_V1_BatchCreatePatientsRequest.with {
            $0.context = input.context
        }
        _ = try await self.patientsPatient.batchCreatePatients { writer in
            try await writer.write(importFrame)
        }
        let outbound0 = Acme_Telehealth_V1_SummarizeVisitNotesRequest.with {
            $0.annotations = input.annotations
            $0.context = Projection.read(input, at: \Acme_Telehealth_V1_ApproveTriageRequest.context)
            $0.details = Acme_Telehealth_V1_SummarizeVisitNotesRequest.Details.with {
                $0.filters = input.triage.customFields
            }
            $0.reason = Projection.read(input, at: \Acme_Telehealth_V1_ApproveTriageRequest.reason)
        }
        let reply0 = try await self.telehealthVisitNoteQuery.summarizeVisitNotes(outbound0)
        return Acme_Telehealth_V1_ApproveTriageResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply0.result.status
            }
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.assignee = input.triage.assignee
                $0.triageID = input.triageID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processCommentTriageApproval(_ input: Acme_Telehealth_V1_CommentTriageApprovalRequest) async throws
        -> Acme_Telehealth_V1_CommentTriageApprovalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "triage",
            action: "audit", detail: input.details.approver.displayName
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "CommentTriageApproval",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try TriageRecord(input.triage, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let selection0_3: String
        switch input.triage.origin {
        case .customer(let customer):
            selection0_3 = customer.displayName
        default: selection0_3 = .init()
        }
        let outbound0 = Acme_Careplans_V1_PauseVitalWorkflowRequest.with {
            $0.context = input.context
            $0.details = Acme_Careplans_V1_PauseVitalWorkflowRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.triage.assignee.email
                    $0.name = input.triage.requester.name
                    $0.preferredChannel = input.triage.requester.preferredChannel
                }
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.subject = Acme_Appointments_V1_AppointmentRef.with {
                    $0.displayName = selection0_3
                }
            }
        }
        let reply0 = try await self.careplansVitalWorkflow.pauseVitalWorkflow(outbound0)
        let outbound1 = Acme_Careplans_V1_SummarizeCarePlansRequest.with {
            $0.annotations = input.annotations
            $0.context = input.context
            $0.reason = input.reason
        }
        let step1: @Sendable () async throws -> Acme_Careplans_V1_SummarizeCarePlansResponse = {
            try await self.careplansCarePlanQuery.summarizeCarePlans(outbound1)
        }
        let reply1 = try await step1()
        var outbound2 = Acme_Identity_V1_GetUserRulesRequest()
        outbound2.context = input.context
        outbound2.userID = input.details.approver.userID
        let reply2 = try await self.identityUserValidation.getUserRules(outbound2)
        return Acme_Telehealth_V1_CommentTriageApprovalResponse.with {
            $0.outcome = Acme_Telehealth_V1_CommentTriageApprovalResponse.Outcome.with {
                $0.message = reply1.result.message
                $0.status = reply2.result.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply1.result.message
                $0.status = reply0.result.status
            }
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.name = reply2.user.name
                }
                $0.status = input.triage.status
                $0.triageID = input.triageID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processDelegateTriageApproval(_ input: Acme_Telehealth_V1_DelegateTriageApprovalRequest) async throws
        -> Acme_Telehealth_V1_DelegateTriageApprovalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "triage",
            action: "audit", detail: input.details.approver.displayName
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "DelegateTriageApproval",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try TriageRecord(input.triage, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Patients_V1_CalculateMedicalRecordRequest.with {
            $0.context = input.context
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = input.triage.audit.createdBy
                    $0.updatedAt = input.triage.audit.updatedAt
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.email = input.details.approver.email
                }
            }
        }
        let step0: @Sendable () async throws -> Acme_Patients_V1_CalculateMedicalRecordResponse = {
            try await self.patientsMedicalRecordCalculation.calculateMedicalRecord(outbound0)
        }
        let reply0 = try await step0()
        let outbound1 = Acme_Telehealth_V1_CalculateVisitNoteRequest.with {
            $0.context = input.context
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply0.medicalRecord.audit.createdBy
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.lines = reply0.medicalRecord.billingAddress.lines
                }
            }
        }
        let reply1 = try await self.telehealthVisitNoteCalculation.calculateVisitNote(outbound1)
        return Acme_Telehealth_V1_DelegateTriageApprovalResponse.with {
            $0.outcome = Acme_Telehealth_V1_DelegateTriageApprovalResponse.Outcome.with {
                $0.message = reply0.result.message
                $0.status = reply1.result.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply1.visitNote.counterparty.displayName
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply0.medicalRecord.audit.updatedAt
                }
                $0.requester = input.triage.requester
                $0.triageID = input.triageID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processGetTriageApprovalStatus(_ input: Acme_Telehealth_V1_GetTriageApprovalStatusRequest) async throws
        -> Acme_Telehealth_V1_GetTriageApprovalStatusResponse
    {
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "GetTriageApprovalStatus",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "triage",
            action: "GetTriageApprovalStatus", detail: input.context.traceID
        )
        let outbound0 = Acme_Patients_V1_ResolvePatientsRequest.with {
            $0.context = input.context
        }
        async let remote0 = self.patientsPatientQuery.resolvePatients(outbound0)
        async let persisted0 = store.count(tenant: input.context.tenantID)
        let (reply0, count0) = try await (remote0, persisted0)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count0)])
        let outbound1 = Acme_Telehealth_V1_SimulateVideoVisitRequest.with {
            $0.context = input.context
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.context.actor.userID
                }
                $0.participants = [
                    Acme_Telehealth_V1_VideoVisitParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = input.context.actor.email
                        }
                    }
                ]
            }
        }
        let reply1 = try await self.getTriageApprovalStatusStep1.execute(outbound1)
        return Acme_Telehealth_V1_GetTriageApprovalStatusResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.status = reply0.result.status
            }
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.triageID = input.triageID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processListPendingTriages(_ input: Acme_Telehealth_V1_ListPendingTriagesRequest) async throws
        -> Acme_Telehealth_V1_ListPendingTriagesResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.query)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "triage",
            action: "audit", detail: input.filter.query
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ListPendingTriages",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "triage",
            action: "ListPendingTriages", detail: input.context.traceID
        )
        let outbound0 = Acme_Careplans_V1_CommentVitalApprovalRequest.with {
            $0.context = input.context
            $0.details = Acme_Careplans_V1_CommentVitalApprovalRequest.Details.with {
                $0.approver = Acme_Identity_V1_UserRef.with {
                    $0.email = input.context.actor.email
                    $0.userID = input.context.actor.userID
                }
            }
        }
        let port0 = RPCOperations.port { (request: Acme_Careplans_V1_CommentVitalApprovalRequest) in
            try await self.careplansVitalApproval.commentVitalApproval(request)
        }
        let reply0 = try await port0.execute(outbound0)
        let outbound1 = Acme_Identity_V1_ListUsersRequest.with {
            $0.context = input.context
            $0.filter = Acme_Identity_V1_ListUsersRequest.Filter.with {
                $0.ownerID = input.filter.ownerID
                $0.region = input.filter.region
            }
        }
        let reply1 = try await self.listPendingTriagesStep1(outbound1)
        return Acme_Telehealth_V1_ListPendingTriagesResponse.with {
            $0.pageInfo = Acme_Common_V1_PageInfo.with {
                $0.totalSize = reply1.pageInfo.totalSize
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.details = reply0.result.details
                $0.referenceIds = reply1.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processSubmitTriage(_ input: Acme_Telehealth_V1_SubmitTriageRequest) async throws
        -> Acme_Telehealth_V1_SubmitTriageResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "triage",
            action: "audit", detail: input.details.approver.displayName
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "SubmitTriage",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try TriageRecord(input.triage, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Patients_V1_FindPatientsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Patients_V1_FindPatientsRequest.Filter.with {
                $0.createdAfter = input.triage.audit.updatedAt
                $0.ownerID = input.details.approver.userID
            }
        }
        guard let execute0 = self.submitTriageStep0[settings.region] ?? self.submitTriageStep0["primary"] else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply0 = try await execute0(outbound0)
        return Acme_Telehealth_V1_SubmitTriageResponse.with {
            $0.outcome = Acme_Telehealth_V1_SubmitTriageResponse.Outcome.with {
                $0.message = reply0.result.message
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.assignee = input.triage.assignee
                $0.triageID = input.triageID
            }
        }
    }
}
