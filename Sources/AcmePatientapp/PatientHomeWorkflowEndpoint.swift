import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Runs the long-lived workflow that takes a patient home from start to finish.
final class PatientHomeWorkflowEndpoint: Acme_Patientapp_V1_PatientHomeWorkflowService.ServiceProtocol {
    private let store: any RecordRepository
    private let logger: Logger
    private let settings: Settings
    private let followUps = WorkQueue<Acme_Identity_V1_GetUserRequest>()
    private let appointmentsAppointmentApproval: Acme_Appointments_V1_AppointmentApprovalService.Client<MeshTransport>
    private let appointmentsClinicSlotApproval: Acme_Appointments_V1_ClinicSlotApprovalService.Client<MeshTransport>
    private let audiencesAudience: Acme_Audiences_V1_AudienceService.Client<MeshTransport>
    private let auditAuditEventQuery: Acme_Audit_V1_AuditEventQueryService.Client<MeshTransport>
    private let careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>
    private let fulfillmentFulfillmentQuery: Acme_Fulfillment_V1_FulfillmentQueryService.Client<MeshTransport>
    private let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    private let identityUserQuery: Acme_Identity_V1_UserQueryService.Client<MeshTransport>
    private let ledgerLedgerAccount: Acme_Ledger_V1_LedgerAccountService.Client<MeshTransport>
    private let licensingSoftwareLicenseQuery: Acme_Licensing_V1_SoftwareLicenseQueryService.Client<MeshTransport>
    private let patientsAllergyApproval: Acme_Patients_V1_AllergyApprovalService.Client<MeshTransport>
    private let patientsMedicalRecordApproval: Acme_Patients_V1_MedicalRecordApprovalService.Client<MeshTransport>
    private let patientsMedicalRecordValidation: Acme_Patients_V1_MedicalRecordValidationService.Client<MeshTransport>
    private let patientsMedicalRecordWorkflow: Acme_Patients_V1_MedicalRecordWorkflowService.Client<MeshTransport>
    private let patientsPatientReporting: Acme_Patients_V1_PatientReportingService.Client<MeshTransport>
    private let patientsPatientWorkflow: Acme_Patients_V1_PatientWorkflowService.Client<MeshTransport>
    private let prescriptionsMedicationSync: Acme_Prescriptions_V1_MedicationSyncService.Client<MeshTransport>
    private let prescriptionsPrescriptionLifecycle:
        Acme_Prescriptions_V1_PrescriptionLifecycleService.Client<MeshTransport>
    private let prescriptionsRefillSync: Acme_Prescriptions_V1_RefillSyncService.Client<MeshTransport>
    private let telehealthVisitNoteApproval: Acme_Telehealth_V1_VisitNoteApprovalService.Client<MeshTransport>

    init(
        dependencies: any Dependencies,
        appointmentsAppointmentApproval: Acme_Appointments_V1_AppointmentApprovalService.Client<MeshTransport>,
        appointmentsClinicSlotApproval: Acme_Appointments_V1_ClinicSlotApprovalService.Client<MeshTransport>,
        audiencesAudience: Acme_Audiences_V1_AudienceService.Client<MeshTransport>,
        auditAuditEventQuery: Acme_Audit_V1_AuditEventQueryService.Client<MeshTransport>,
        careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>,
        fulfillmentFulfillmentQuery: Acme_Fulfillment_V1_FulfillmentQueryService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        identityUserQuery: Acme_Identity_V1_UserQueryService.Client<MeshTransport>,
        ledgerLedgerAccount: Acme_Ledger_V1_LedgerAccountService.Client<MeshTransport>,
        licensingSoftwareLicenseQuery: Acme_Licensing_V1_SoftwareLicenseQueryService.Client<MeshTransport>,
        patientsAllergyApproval: Acme_Patients_V1_AllergyApprovalService.Client<MeshTransport>,
        patientsMedicalRecordApproval: Acme_Patients_V1_MedicalRecordApprovalService.Client<MeshTransport>,
        patientsMedicalRecordValidation: Acme_Patients_V1_MedicalRecordValidationService.Client<MeshTransport>,
        patientsMedicalRecordWorkflow: Acme_Patients_V1_MedicalRecordWorkflowService.Client<MeshTransport>,
        patientsPatientReporting: Acme_Patients_V1_PatientReportingService.Client<MeshTransport>,
        patientsPatientWorkflow: Acme_Patients_V1_PatientWorkflowService.Client<MeshTransport>,
        prescriptionsMedicationSync: Acme_Prescriptions_V1_MedicationSyncService.Client<MeshTransport>,
        prescriptionsPrescriptionLifecycle: Acme_Prescriptions_V1_PrescriptionLifecycleService.Client<MeshTransport>,
        prescriptionsRefillSync: Acme_Prescriptions_V1_RefillSyncService.Client<MeshTransport>,
        telehealthVisitNoteApproval: Acme_Telehealth_V1_VisitNoteApprovalService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.appointmentsAppointmentApproval = appointmentsAppointmentApproval
        self.appointmentsClinicSlotApproval = appointmentsClinicSlotApproval
        self.audiencesAudience = audiencesAudience
        self.auditAuditEventQuery = auditAuditEventQuery
        self.careplansCarePlan = careplansCarePlan
        self.fulfillmentFulfillmentQuery = fulfillmentFulfillmentQuery
        self.identityUser = identityUser
        self.identityUserQuery = identityUserQuery
        self.ledgerLedgerAccount = ledgerLedgerAccount
        self.licensingSoftwareLicenseQuery = licensingSoftwareLicenseQuery
        self.patientsAllergyApproval = patientsAllergyApproval
        self.patientsMedicalRecordApproval = patientsMedicalRecordApproval
        self.patientsMedicalRecordValidation = patientsMedicalRecordValidation
        self.patientsMedicalRecordWorkflow = patientsMedicalRecordWorkflow
        self.patientsPatientReporting = patientsPatientReporting
        self.patientsPatientWorkflow = patientsPatientWorkflow
        self.prescriptionsMedicationSync = prescriptionsMedicationSync
        self.prescriptionsPrescriptionLifecycle = prescriptionsPrescriptionLifecycle
        self.prescriptionsRefillSync = prescriptionsRefillSync
        self.telehealthVisitNoteApproval = telehealthVisitNoteApproval
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

    /// Advances a patient home.
    func advancePatientHomeWorkflow(
        request: ServerRequest<Acme_Patientapp_V1_AdvancePatientHomeWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_AdvancePatientHomeWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processAdvancePatientHomeWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Cancels a patient home.
    func cancelPatientHomeWorkflow(
        request: ServerRequest<Acme_Patientapp_V1_CancelPatientHomeWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_CancelPatientHomeWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCancelPatientHomeWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a patient home.
    func inspectPatientHomeWorkflow(
        request: ServerRequest<Acme_Patientapp_V1_InspectPatientHomeWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_InspectPatientHomeWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processInspectPatientHomeWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists patient homes a page at a time.
    func listPatientHomeWorkflows(
        request: ServerRequest<Acme_Patientapp_V1_ListPatientHomeWorkflowsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_ListPatientHomeWorkflowsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListPatientHomeWorkflows(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Pauses a patient home.
    func pausePatientHomeWorkflow(
        request: ServerRequest<Acme_Patientapp_V1_PausePatientHomeWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_PausePatientHomeWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processPausePatientHomeWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Resumes a patient home.
    func resumePatientHomeWorkflow(
        request: ServerRequest<Acme_Patientapp_V1_ResumePatientHomeWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_ResumePatientHomeWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processResumePatientHomeWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Retrys a patient home.
    func retryPatientHomeWorkflow(
        request: ServerRequest<Acme_Patientapp_V1_RetryPatientHomeWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_RetryPatientHomeWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRetryPatientHomeWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Signals a patient home.
    func signalPatientHomeWorkflow(
        request: ServerRequest<Acme_Patientapp_V1_SignalPatientHomeWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_SignalPatientHomeWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSignalPatientHomeWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Starts a patient home.
    func startPatientHomeWorkflow(
        request: ServerRequest<Acme_Patientapp_V1_StartPatientHomeWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_StartPatientHomeWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processStartPatientHomeWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processAdvancePatientHomeWorkflow(_ input: Acme_Patientapp_V1_AdvancePatientHomeWorkflowRequest) async throws
        -> Acme_Patientapp_V1_AdvancePatientHomeWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "audit", detail: input.details.initiatedBy
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "AdvancePatientHomeWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PatientHomeRecord(input.patientHome, tenant: input.context.tenantID)
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
        let selection0_2: String
        switch input.patientHome.origin {
        case .customer(let customer):
            selection0_2 = customer.patientID
        default: selection0_2 = .init()
        }
        let outbound0 = Acme_Patients_V1_ListMedicalRecordWorkflowsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Patients_V1_ListMedicalRecordWorkflowsRequest.Filter.with {
                $0.createdAfter = input.patientHome.sla.dueAt
                $0.labels = input.annotations
                $0.ownerID = selection0_2
            }
        }
        let reply0 = try await self.patientsMedicalRecordWorkflow.listMedicalRecordWorkflows(outbound0)
        let outbound1 = Acme_Audit_V1_ResolveAuditEventsRequest.with {
            $0.context = input.context
        }
        let reply1 = try await self.auditAuditEventQuery.resolveAuditEvents(outbound1)
        return Acme_Patientapp_V1_AdvancePatientHomeWorkflowResponse.with {
            $0.outcome = Acme_Patientapp_V1_AdvancePatientHomeWorkflowResponse.Outcome.with {
                $0.message = reply0.result.message
                $0.status = reply1.result.status
            }
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.customFields = input.patientHome.customFields
                $0.patientHomeID = input.patientHomeID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply1.result.details
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processCancelPatientHomeWorkflow(_ input: Acme_Patientapp_V1_CancelPatientHomeWorkflowRequest) async throws
        -> Acme_Patientapp_V1_CancelPatientHomeWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "audit", detail: input.details.initiatedBy
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "CancelPatientHomeWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PatientHomeRecord(input.patientHome, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let selection0_2: String
        switch input.patientHome.origin {
        case .customer(let customer):
            selection0_2 = customer.email
        default: selection0_2 = .init()
        }
        let selection0_3: String
        switch input.patientHome.origin {
        case .customer(let customer):
            selection0_3 = customer.displayName
        default: selection0_3 = .init()
        }
        let outbound0 = Acme_Appointments_V1_ApproveAppointmentRequest.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.participants = [
                    Acme_Appointments_V1_AppointmentParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = selection0_2
                            $0.name = input.details.notify.name
                            $0.phone = input.details.notify.phone
                        }
                    }
                ]
            }
            $0.context = input.context
            $0.details = Acme_Appointments_V1_ApproveAppointmentRequest.Details.with {
                $0.approver = Acme_Identity_V1_UserRef.with {
                    $0.displayName = selection0_3
                }
            }
        }
        let reply0 = try await self.appointmentsAppointmentApproval.approveAppointment(outbound0)
        let selection1_3: String
        switch input.patientHome.origin {
        case .customer(let customer):
            selection1_3 = customer.patientID
        default: selection1_3 = .init()
        }
        let outbound1 = Acme_Patients_V1_ListPatientReportsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Patients_V1_ListPatientReportsRequest.Filter.with {
                $0.createdAfter = reply0.appointment.audit.createdAt
                $0.labels = input.patientHome.customFields
                $0.ownerID = selection1_3
                $0.region = reply0.appointment.location.region
            }
        }
        let reply1 = try await self.patientsPatientReporting.listPatientReports(outbound1)
        return Acme_Patientapp_V1_CancelPatientHomeWorkflowResponse.with {
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.assignee = input.patientHome.assignee
                $0.comments = [
                    Acme_Patientapp_V1_PatientHomeComment.with {
                        $0.createdAt = reply0.appointment.audit.createdAt
                    }
                ]
                $0.patientHomeID = input.patientHomeID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = Projection.firstValue(
                    [
                        reply0.result.message,
                        reply1.result.message,
                    ], default: .init())
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processInspectPatientHomeWorkflow(_ input: Acme_Patientapp_V1_InspectPatientHomeWorkflowRequest) async throws
        -> Acme_Patientapp_V1_InspectPatientHomeWorkflowResponse
    {
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "InspectPatientHomeWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "InspectPatientHomeWorkflow", detail: input.context.traceID
        )
        let outbound0 = Acme_Audiences_V1_BatchGetAudiencesRequest.with {
            $0.context = input.context
        }
        let envelope0 = try Google_Protobuf_Any(message: outbound0)
        let unpacked0 = try Acme_Audiences_V1_BatchGetAudiencesRequest(unpackingAny: envelope0)
        let reply0 = try await self.audiencesAudience.batchGetAudiences(unpacked0)
        let outbound1 = Acme_Identity_V1_CountUsersRequest.with {
            $0.context = input.context
            $0.filter = Acme_Identity_V1_CountUsersRequest.Filter.with {
                $0.createdAfter = input.context.deadline
                $0.labels = reply0.result.details
                $0.ownerID = input.patientHomeID
            }
        }
        let json1 = try outbound1.jsonString()
        let decoded1 = try Acme_Identity_V1_CountUsersRequest(jsonString: json1)
        let reply1 = try await self.identityUserQuery.countUsers(decoded1)
        return Acme_Patientapp_V1_InspectPatientHomeWorkflowResponse.with {
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.patientHomeID = input.patientHomeID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.referenceIds = reply0.result.referenceIds
                $0.status = reply0.result.status
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processListPatientHomeWorkflows(_ input: Acme_Patientapp_V1_ListPatientHomeWorkflowsRequest) async throws
        -> Acme_Patientapp_V1_ListPatientHomeWorkflowsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.query)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "audit", detail: input.filter.query
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ListPatientHomeWorkflows",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "ListPatientHomeWorkflows", detail: input.context.traceID
        )
        let outbound0 = Acme_Identity_V1_ResolveUsersRequest.forPatientHomeWorkflowEndpointListPatientHomeWorkflows0(
            input
        )
        let reply0 = try await self.identityUserQuery.resolveUsers(outbound0)
        let outbound1 = Acme_Ledger_V1_CloneLedgerAccountRequest.with {
            $0.context = input.context
            $0.ledgerAccount = Acme_Ledger_V1_LedgerAccount.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.filter.createdAfter
                }
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.context.actor.email
                }
                $0.externalAccountID = input.filter.ownerID
                $0.labels = input.filter.labels
            }
        }
        let reply1 = try await self.ledgerLedgerAccount.cloneLedgerAccount(
            outbound1, metadata: ["x-acme-region": .string(settings.region)]
        )
        return Acme_Patientapp_V1_ListPatientHomeWorkflowsResponse.with {
            $0.patientHomes = [
                Acme_Patientapp_V1_PatientHome.with {
                    $0.audit = Acme_Common_V1_AuditInfo.with {
                        $0.updatedBy = reply1.ledgerAccount.audit.updatedBy
                    }
                }
            ]
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply0.result.status
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processPausePatientHomeWorkflow(_ input: Acme_Patientapp_V1_PausePatientHomeWorkflowRequest) async throws
        -> Acme_Patientapp_V1_PausePatientHomeWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "audit", detail: input.details.initiatedBy
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "PausePatientHomeWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PatientHomeRecord(input.patientHome, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let requests0 = input.patientHome.history.map { element in
            Acme_Fulfillment_V1_BrowseFulfillmentsRequest.with {
                $0.context = input.context
                $0.filter = Acme_Fulfillment_V1_BrowseFulfillmentsRequest.Filter.with {
                    $0.createdAfter = element.changedAt
                    $0.ownerID = input.patientHome.assignee.userID
                }
            }
        }
        let replies0 = try await FanOut.map(requests0) { candidate in
            try await self.fulfillmentFulfillmentQuery.browseFulfillments(candidate)
        }
        let reply0 = replies0.first ?? Acme_Fulfillment_V1_BrowseFulfillmentsResponse()
        let outbound1 = Acme_Identity_V1_LookupUserRequest.with {
            $0.context = input.context
            $0.userID = input.patientHome.assignee.userID
        }
        let reply1 = try await RPCOperations.call(outbound1) { request in
            try await self.identityUserQuery.lookupUser(request)
        }
        let outbound2 = Acme_Licensing_V1_FindSoftwareLicensesRequest.with {
            $0.context = Projection.read(input, at: \Acme_Patientapp_V1_PausePatientHomeWorkflowRequest.context)
            $0.filter = Acme_Licensing_V1_FindSoftwareLicensesRequest.Filter.with {
                $0.createdAfter = Projection.read(reply1, at: \Acme_Identity_V1_LookupUserResponse.user.audit.updatedAt)
                $0.ownerID = Projection.read(
                    reply0, at: \Acme_Fulfillment_V1_BrowseFulfillmentsResponse.result.correlationID)
                $0.region = Projection.read(reply1, at: \Acme_Identity_V1_LookupUserResponse.user.primaryAddress.region)
            }
        }
        let reply2 = try await self.licensingSoftwareLicenseQuery.findSoftwareLicenses(outbound2)
        return Acme_Patientapp_V1_PausePatientHomeWorkflowResponse.with {
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.customFields = input.patientHome.customFields
                $0.patientHomeID = input.patientHomeID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply2.result.correlationID
                $0.message = reply1.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processResumePatientHomeWorkflow(_ input: Acme_Patientapp_V1_ResumePatientHomeWorkflowRequest) async throws
        -> Acme_Patientapp_V1_ResumePatientHomeWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "audit", detail: input.details.initiatedBy
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ResumePatientHomeWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PatientHomeRecord(input.patientHome, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let selection0_2: String
        switch input.patientHome.origin {
        case .customer(let customer):
            selection0_2 = customer.patientID
        default: selection0_2 = .init()
        }
        let outbound0 = Acme_Prescriptions_V1_ListMedicationConflictsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Prescriptions_V1_ListMedicationConflictsRequest.Filter.with {
                $0.createdAfter = input.patientHome.audit.updatedAt
                $0.labels = input.patientHome.customFields
                $0.ownerID = selection0_2
            }
        }
        let reply0 = try await self.prescriptionsMedicationSync.listMedicationConflicts(outbound0)
        let selection1_2: String
        switch input.patientHome.origin {
        case .customer(let customer):
            selection1_2 = customer.patientID
        default: selection1_2 = .init()
        }
        let outbound1 = Acme_Prescriptions_V1_SchedulePrescriptionExpiryRequest.with {
            $0.context = input.context
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = input.patientHome.audit.etag
                    $0.updatedBy = input.patientHome.audit.updatedBy
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.email = input.patientHome.assignee.email
                    $0.patientID = selection1_2
                }
            }
        }
        let reply1 = try await self.prescriptionsPrescriptionLifecycle.schedulePrescriptionExpiry(outbound1)
        let requests2 = input.patientHome.comments.map { element in
            Acme_Prescriptions_V1_PushRefillRequest.with {
                $0.context = input.context
                $0.refill = Acme_Prescriptions_V1_Refill.with {
                    $0.comments = [
                        Acme_Prescriptions_V1_RefillComment.with {
                            $0.authorEmail = element.authorEmail
                            $0.body = element.body
                            $0.commentID = element.commentID
                            $0.createdAt = element.createdAt
                        }
                    ]
                }
            }
        }
        let replies2 = try await FanOut.map(requests2) { candidate in
            try await self.prescriptionsRefillSync.pushRefill(candidate)
        }
        let reply2 = replies2.first ?? Acme_Prescriptions_V1_PushRefillResponse()
        _ = reply2
        return Acme_Patientapp_V1_ResumePatientHomeWorkflowResponse.with {
            $0.outcome = Acme_Patientapp_V1_ResumePatientHomeWorkflowResponse.Outcome.with {
                $0.status = reply1.outcome.status
            }
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.assignee = input.patientHome.assignee
                $0.patientHomeID = input.patientHomeID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.referenceIds = reply0.result.referenceIds
                $0.status = reply1.outcome.status
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processRetryPatientHomeWorkflow(_ input: Acme_Patientapp_V1_RetryPatientHomeWorkflowRequest) async throws
        -> Acme_Patientapp_V1_RetryPatientHomeWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "audit", detail: input.details.initiatedBy
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "RetryPatientHomeWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PatientHomeRecord(input.patientHome, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Telehealth_V1_RejectVisitNoteRequest.with {
            $0.context = input.context
            $0.details = Acme_Telehealth_V1_RejectVisitNoteRequest.Details.with {
                $0.approver = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.patientHome.assignee.displayName
                }
            }
        }
        let step0: @Sendable () async throws -> Acme_Telehealth_V1_RejectVisitNoteResponse = {
            try await self.telehealthVisitNoteApproval.rejectVisitNote(outbound0)
        }
        let reply0 = try await step0()
        let selection1_2: String
        switch reply0.visitNote.settlement {
        case .bank(let bank):
            selection1_2 = bank.accountHolder
        default: selection1_2 = .init()
        }
        let outbound1 = Acme_Patients_V1_RetryMedicalRecordWorkflowRequest.with {
            $0.context = input.context
            $0.details = Acme_Patients_V1_RetryMedicalRecordWorkflowRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.name = input.patientHome.requester.name
                }
            }
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply0.visitNote.audit.createdBy
                }
                $0.bank = Acme_Patients_V1_MedicalRecordBankSettlement.with {
                    $0.accountHolder = selection1_2
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.lines = reply0.visitNote.billingAddress.lines
                }
            }
        }
        let reply1 = try await self.patientsMedicalRecordWorkflow.retryMedicalRecordWorkflow(outbound1)
        return Acme_Patientapp_V1_RetryPatientHomeWorkflowResponse.with {
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply0.visitNote.audit.updatedBy
                }
                $0.patientHomeID = input.patientHomeID
                $0.priority = input.patientHome.priority
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply1.outcome.message
                $0.referenceIds = reply1.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processSignalPatientHomeWorkflow(_ input: Acme_Patientapp_V1_SignalPatientHomeWorkflowRequest) async throws
        -> Acme_Patientapp_V1_SignalPatientHomeWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "audit", detail: input.details.initiatedBy
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "SignalPatientHomeWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PatientHomeRecord(input.patientHome, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let requests0 = input.patientHome.comments.map { element in
            Acme_Patients_V1_RecallMedicalRecordRequest.with {
                $0.context = input.context
                $0.details = Acme_Patients_V1_RecallMedicalRecordRequest.Details.with {
                    $0.approver = Acme_Identity_V1_UserRef.with {
                        $0.displayName = input.patientHome.customer.displayName
                        $0.email = element.authorEmail
                    }
                    $0.comment = element.commentID
                }
                $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                    $0.audit = Acme_Common_V1_AuditInfo.with {
                        $0.createdAt = element.createdAt
                    }
                }
            }
        }
        let replies0 = try await FanOut.map(requests0) { candidate in
            try await self.patientsMedicalRecordApproval.recallMedicalRecord(candidate)
        }
        let reply0 = replies0.first ?? Acme_Patients_V1_RecallMedicalRecordResponse()
        var outbound1 = Acme_Appointments_V1_CommentClinicSlotApprovalRequest()
        outbound1.clinicSlot = Acme_Appointments_V1_ClinicSlot.with {
            $0.audit = Acme_Common_V1_AuditInfo.with {
                $0.createdBy = reply0.medicalRecord.audit.createdBy
            }
            $0.participants = [
                Acme_Appointments_V1_ClinicSlotParticipant.with {
                    $0.contact = Acme_Common_V1_ContactInfo.with {
                        $0.email = reply0.medicalRecord.counterparty.email
                    }
                }
            ]
        }
        outbound1.context = input.context
        let reply1 = try await self.appointmentsClinicSlotApproval.commentClinicSlotApproval(outbound1)
        let outbound2 = Acme_Patients_V1_ApproveMedicalRecordRequest.with {
            $0.context = input.context
            $0.details = Acme_Patients_V1_ApproveMedicalRecordRequest.Details.with {
                $0.approver = Acme_Identity_V1_UserRef.with {
                    $0.email = reply1.clinicSlot.organizer.email
                }
            }
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = reply0.medicalRecord.billingAddress.countryCode
                    $0.locality = reply1.clinicSlot.location.locality
                }
            }
        }
        let step2: @Sendable () async throws -> Acme_Patients_V1_ApproveMedicalRecordResponse = {
            try await self.patientsMedicalRecordApproval.approveMedicalRecord(outbound2)
        }
        let reply2 = try await step2()
        return Acme_Patientapp_V1_SignalPatientHomeWorkflowResponse.with {
            $0.outcome = Acme_Patientapp_V1_SignalPatientHomeWorkflowResponse.Outcome.with {
                $0.message = reply2.result.message
            }
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply2.medicalRecord.counterparty.displayName
                }
                $0.comments = [
                    Acme_Patientapp_V1_PatientHomeComment.with {
                        $0.createdAt = reply1.clinicSlot.audit.createdAt
                    }
                ]
                $0.patientHomeID = input.patientHomeID
                $0.subject = input.patientHome.subject
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processStartPatientHomeWorkflow(_ input: Acme_Patientapp_V1_StartPatientHomeWorkflowRequest) async throws
        -> Acme_Patientapp_V1_StartPatientHomeWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "audit", detail: input.details.initiatedBy
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "StartPatientHomeWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PatientHomeRecord(input.patientHome, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let selection0_2: String
        switch input.patientHome.origin {
        case .customer(let customer):
            selection0_2 = customer.displayName
        default: selection0_2 = .init()
        }
        let selection0_4: String
        switch input.patientHome.origin {
        case .customer(let customer):
            selection0_4 = customer.patientID
        default: selection0_4 = .init()
        }
        let outbound0 = Acme_Patients_V1_SubmitAllergyRequest.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = input.patientHome.assignee.displayName
                    $0.patientID = selection0_4
                }
            }
            $0.context = input.context
            $0.details = Acme_Patients_V1_SubmitAllergyRequest.Details.with {
                $0.approver = Acme_Identity_V1_UserRef.with {
                    $0.displayName = selection0_2
                    $0.email = input.patientHome.assignee.email
                }
            }
        }
        let reply0 = try await self.patientsAllergyApproval.submitAllergy(outbound0)
        let outbound1 = Acme_Patients_V1_StartPatientWorkflowRequest.with {
            $0.context = input.context
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.patientHome.audit.createdAt
                    $0.updatedAt = input.patientHome.audit.updatedAt
                }
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.patientHome.requester.email
                }
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply0.allergy.subject.displayName
                }
            }
        }
        let reply1 = try await self.patientsPatientWorkflow.startPatientWorkflow(outbound1)
        let outbound2 = Acme_Patients_V1_PreviewMedicalRecordRequest.with {
            $0.context = input.context
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply1.patient.audit.updatedAt
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = input.patientHome.assignee.displayName
                    $0.email = reply1.patient.relationshipManager.email
                }
            }
        }
        async let remote2 = self.patientsMedicalRecordValidation.previewMedicalRecord(outbound2)
        async let persisted2 = store.count(tenant: input.context.tenantID)
        let (reply2, count2) = try await (remote2, persisted2)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count2)])
        return Acme_Patientapp_V1_StartPatientHomeWorkflowResponse.with {
            $0.outcome = Acme_Patientapp_V1_StartPatientHomeWorkflowResponse.Outcome.with {
                $0.message = reply2.result.message
                $0.status = reply1.outcome.status
            }
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.patientHomeID = input.patientHomeID
                $0.status = input.patientHome.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply1.result.message
                $0.status = reply0.outcome.status
            }
        }
    }
}
