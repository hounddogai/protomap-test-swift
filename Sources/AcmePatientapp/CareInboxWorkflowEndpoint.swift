import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Runs the long-lived workflow that takes a care inbox from start to finish.
final class CareInboxWorkflowEndpoint: Acme_Patientapp_V1_CareInboxWorkflowService.ServiceProtocol {
    private let store: any RecordRepository
    private let logger: Logger
    private let settings: Settings
    private let followUps = WorkQueue<Acme_Identity_V1_GetUserRequest>()
    private let appointmentsAppointmentWorkflow: Acme_Appointments_V1_AppointmentWorkflowService.Client<MeshTransport>
    private let careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>
    private let careplansCarePlanWorkflow: Acme_Careplans_V1_CarePlanWorkflowService.Client<MeshTransport>
    private let careplansVitalReporting: Acme_Careplans_V1_VitalReportingService.Client<MeshTransport>
    private let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    private let patientappPatientHomeWorkflow: Acme_Patientapp_V1_PatientHomeWorkflowService.Client<MeshTransport>
    private let patientsMedicalRecordReporting: Acme_Patients_V1_MedicalRecordReportingService.Client<MeshTransport>
    private let patientsPatientWorkflow: Acme_Patients_V1_PatientWorkflowService.Client<MeshTransport>
    private let prescriptionsRefillLifecycle: Acme_Prescriptions_V1_RefillLifecycleService.Client<MeshTransport>
    private let resumeCareInboxWorkflowStep1:
        any RPCPort<Acme_Patients_V1_SignalPatientWorkflowRequest, Acme_Patients_V1_SignalPatientWorkflowResponse>
    private let retryCareInboxWorkflowStep1:
        @Sendable (Acme_Prescriptions_V1_ScheduleRefillExpiryRequest) async throws ->
            Acme_Prescriptions_V1_ScheduleRefillExpiryResponse
    private let signalCareInboxWorkflowStep0:
        [String:
            @Sendable (Acme_Patientapp_V1_StartPatientHomeWorkflowRequest) async throws ->
            Acme_Patientapp_V1_StartPatientHomeWorkflowResponse]

    init(
        dependencies: any Dependencies,
        appointmentsAppointmentWorkflow: Acme_Appointments_V1_AppointmentWorkflowService.Client<MeshTransport>,
        careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>,
        careplansCarePlanWorkflow: Acme_Careplans_V1_CarePlanWorkflowService.Client<MeshTransport>,
        careplansVitalReporting: Acme_Careplans_V1_VitalReportingService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        patientappPatientHomeWorkflow: Acme_Patientapp_V1_PatientHomeWorkflowService.Client<MeshTransport>,
        patientsMedicalRecordReporting: Acme_Patients_V1_MedicalRecordReportingService.Client<MeshTransport>,
        patientsPatientWorkflow: Acme_Patients_V1_PatientWorkflowService.Client<MeshTransport>,
        prescriptionsRefillLifecycle: Acme_Prescriptions_V1_RefillLifecycleService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.appointmentsAppointmentWorkflow = appointmentsAppointmentWorkflow
        self.careplansCarePlan = careplansCarePlan
        self.careplansCarePlanWorkflow = careplansCarePlanWorkflow
        self.careplansVitalReporting = careplansVitalReporting
        self.identityUser = identityUser
        self.patientappPatientHomeWorkflow = patientappPatientHomeWorkflow
        self.patientsMedicalRecordReporting = patientsMedicalRecordReporting
        self.patientsPatientWorkflow = patientsPatientWorkflow
        self.prescriptionsRefillLifecycle = prescriptionsRefillLifecycle
        self.resumeCareInboxWorkflowStep1 = ClosurePort<
            Acme_Patients_V1_SignalPatientWorkflowRequest, Acme_Patients_V1_SignalPatientWorkflowResponse
        >({ request in try await patientsPatientWorkflow.signalPatientWorkflow(request) })
        self.retryCareInboxWorkflowStep1 = { request in
            try await prescriptionsRefillLifecycle.scheduleRefillExpiry(request)
        }
        self.signalCareInboxWorkflowStep0 = [
            "primary": { request in try await patientappPatientHomeWorkflow.startPatientHomeWorkflow(request) }
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

    /// Advances a care inbox.
    func advanceCareInboxWorkflow(
        request: ServerRequest<Acme_Patientapp_V1_AdvanceCareInboxWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_AdvanceCareInboxWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processAdvanceCareInboxWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Cancels a care inbox.
    func cancelCareInboxWorkflow(
        request: ServerRequest<Acme_Patientapp_V1_CancelCareInboxWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_CancelCareInboxWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCancelCareInboxWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists care inboxes a page at a time.
    func listCareInboxWorkflows(
        request: ServerRequest<Acme_Patientapp_V1_ListCareInboxWorkflowsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_ListCareInboxWorkflowsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListCareInboxWorkflows(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Pauses a care inbox.
    func pauseCareInboxWorkflow(
        request: ServerRequest<Acme_Patientapp_V1_PauseCareInboxWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_PauseCareInboxWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processPauseCareInboxWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Resumes a care inbox.
    func resumeCareInboxWorkflow(
        request: ServerRequest<Acme_Patientapp_V1_ResumeCareInboxWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_ResumeCareInboxWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processResumeCareInboxWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Retrys a care inbox.
    func retryCareInboxWorkflow(
        request: ServerRequest<Acme_Patientapp_V1_RetryCareInboxWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_RetryCareInboxWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRetryCareInboxWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Signals a care inbox.
    func signalCareInboxWorkflow(
        request: ServerRequest<Acme_Patientapp_V1_SignalCareInboxWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_SignalCareInboxWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSignalCareInboxWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Starts a care inbox.
    func startCareInboxWorkflow(
        request: ServerRequest<Acme_Patientapp_V1_StartCareInboxWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_StartCareInboxWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processStartCareInboxWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processAdvanceCareInboxWorkflow(_ input: Acme_Patientapp_V1_AdvanceCareInboxWorkflowRequest) async throws
        -> Acme_Patientapp_V1_AdvanceCareInboxWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.careInbox.audit.createdBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "audit", detail: input.careInbox.audit.createdBy
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "AdvanceCareInboxWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CareInboxRecord(input.careInbox, tenant: input.context.tenantID)
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
        let outbound0 = Acme_Patientapp_V1_CancelPatientHomeWorkflowRequest.with {
            $0.context = input.context
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.careInbox.counterparty.displayName
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = input.careInbox.audit.updatedAt
                }
            }
        }
        let json0 = try outbound0.jsonString()
        let decoded0 = try Acme_Patientapp_V1_CancelPatientHomeWorkflowRequest(jsonString: json0)
        let reply0 = try await self.patientappPatientHomeWorkflow.cancelPatientHomeWorkflow(decoded0)
        let outbound1 =
            Acme_Patientapp_V1_PausePatientHomeWorkflowRequest.forCareInboxWorkflowEndpointAdvanceCareInboxWorkflow1(
                input
            )
        let reply1 = try await self.patientappPatientHomeWorkflow.pausePatientHomeWorkflow(outbound1)
        let outbound2 = Acme_Appointments_V1_StartAppointmentWorkflowRequest.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.recipient = input.careInbox.billingAddress.recipient
                }
                $0.participants = [
                    Acme_Appointments_V1_AppointmentParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = input.details.notify.email
                            $0.phone = reply0.patientHome.requester.phone
                            $0.preferredChannel = input.details.notify.preferredChannel
                        }
                    }
                ]
            }
            $0.context = input.context
        }
        let reply2 = try await self.appointmentsAppointmentWorkflow.startAppointmentWorkflow(
            outbound2, metadata: ["x-acme-region": .string(settings.region)]
        )
        return Acme_Patientapp_V1_AdvanceCareInboxWorkflowResponse.with {
            $0.careInbox = Acme_Patientapp_V1_CareInbox.with {
                $0.careInboxID = input.careInboxID
                $0.notes = input.careInbox.notes
            }
            $0.outcome = Acme_Patientapp_V1_AdvanceCareInboxWorkflowResponse.Outcome.with {
                $0.effectiveAt = reply1.outcome.effectiveAt
                $0.status = Projection.firstValue(
                    [
                        reply0.outcome.status,
                        reply2.result.status,
                    ], default: .init())
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processCancelCareInboxWorkflow(_ input: Acme_Patientapp_V1_CancelCareInboxWorkflowRequest) async throws
        -> Acme_Patientapp_V1_CancelCareInboxWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.careInbox.audit.createdBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "audit", detail: input.careInbox.audit.createdBy
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "CancelCareInboxWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CareInboxRecord(input.careInbox, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Patientapp_V1_StartPatientHomeWorkflowRequest.with {
            $0.context = input.context
            $0.details = Acme_Patientapp_V1_StartPatientHomeWorkflowRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.notify.email
                    $0.phone = input.details.notify.phone
                }
            }
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.email = input.careInbox.counterparty.email
                }
            }
        }
        let reply0 = try await RPCOperations.call(outbound0) { request in
            try await self.patientappPatientHomeWorkflow.startPatientHomeWorkflow(request)
        }
        let outbound1 = Acme_Patientapp_V1_ResumePatientHomeWorkflowRequest.with {
            $0.context = Projection.read(input, at: \Acme_Patientapp_V1_CancelCareInboxWorkflowRequest.context)
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.name = Projection.read(
                        input, at: \Acme_Patientapp_V1_CancelCareInboxWorkflowRequest.details.notify.name)
                }
            }
        }
        let reply1 = try await self.patientappPatientHomeWorkflow.resumePatientHomeWorkflow(outbound1)
        let outbound2 = Acme_Patientapp_V1_SignalPatientHomeWorkflowRequest.with {
            $0.context = input.context
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.customer = Acme_Patients_V1_PatientRef.with {
                    $0.email = input.careInbox.counterparty.email
                }
            }
        }
        let step2: @Sendable () async throws -> Acme_Patientapp_V1_SignalPatientHomeWorkflowResponse = {
            try await self.patientappPatientHomeWorkflow.signalPatientHomeWorkflow(outbound2)
        }
        let reply2 = try await step2()
        var outbound3 = Acme_Patientapp_V1_CancelPatientHomeWorkflowRequest()
        outbound3.context = input.context
        outbound3.patientHome = Acme_Patientapp_V1_PatientHome.with {
            $0.requester = Acme_Common_V1_ContactInfo.with {
                $0.email = reply0.patientHome.requester.email
            }
        }
        let reply3 = try await self.patientappPatientHomeWorkflow.cancelPatientHomeWorkflow(outbound3)
        return Acme_Patientapp_V1_CancelCareInboxWorkflowResponse.with {
            $0.careInbox = Acme_Patientapp_V1_CareInbox.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply3.patientHome.audit.createdAt
                    $0.updatedBy = reply1.patientHome.audit.updatedBy
                }
                $0.careInboxID = input.careInboxID
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.email = Projection.firstValue(
                        [
                            reply2.patientHome.customer.email,
                            reply3.patientHome.customer.email,
                        ], default: .init())
                }
                $0.status = input.careInbox.status
            }
            $0.outcome = Acme_Patientapp_V1_CancelCareInboxWorkflowResponse.Outcome.with {
                $0.effectiveAt = reply0.outcome.effectiveAt
                $0.message = reply0.outcome.message
                $0.nextSteps = reply1.outcome.nextSteps
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply2.outcome.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processListCareInboxWorkflows(_ input: Acme_Patientapp_V1_ListCareInboxWorkflowsRequest) async throws
        -> Acme_Patientapp_V1_ListCareInboxWorkflowsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "audit", detail: input.filter.ownerID
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ListCareInboxWorkflows",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "ListCareInboxWorkflows", detail: input.context.traceID
        )
        return Acme_Patientapp_V1_ListCareInboxWorkflowsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processPauseCareInboxWorkflow(_ input: Acme_Patientapp_V1_PauseCareInboxWorkflowRequest) async throws
        -> Acme_Patientapp_V1_PauseCareInboxWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.careInbox.audit.createdBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "audit", detail: input.careInbox.audit.createdBy
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "PauseCareInboxWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CareInboxRecord(input.careInbox, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Patientapp_V1_StartPatientHomeWorkflowRequest.with {
            $0.context = input.context
            $0.details = Acme_Patientapp_V1_StartPatientHomeWorkflowRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.preferredChannel = input.details.notify.preferredChannel
                }
            }
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.careInbox.counterparty.displayName
                }
            }
        }
        let step0: @Sendable () async throws -> Acme_Patientapp_V1_StartPatientHomeWorkflowResponse = {
            try await self.patientappPatientHomeWorkflow.startPatientHomeWorkflow(outbound0)
        }
        let reply0 = try await step0()
        let outbound1 = Acme_Patientapp_V1_SignalPatientHomeWorkflowRequest.with {
            $0.context = input.context
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.customer = Acme_Patients_V1_PatientRef.with {
                    $0.email = input.careInbox.counterparty.email
                }
            }
        }
        let reply1 = try await self.patientappPatientHomeWorkflow.signalPatientHomeWorkflow(outbound1)
        return Acme_Patientapp_V1_PauseCareInboxWorkflowResponse.with {
            $0.careInbox = Acme_Patientapp_V1_CareInbox.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply1.patientHome.audit.updatedBy
                }
                $0.careInboxID = input.careInboxID
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.email = reply0.patientHome.assignee.email
                }
                $0.status = input.careInbox.status
            }
            $0.outcome = Acme_Patientapp_V1_PauseCareInboxWorkflowResponse.Outcome.with {
                $0.effectiveAt = reply1.outcome.effectiveAt
                $0.status = reply0.outcome.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processResumeCareInboxWorkflow(_ input: Acme_Patientapp_V1_ResumeCareInboxWorkflowRequest) async throws
        -> Acme_Patientapp_V1_ResumeCareInboxWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.careInbox.audit.createdBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "audit", detail: input.careInbox.audit.createdBy
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ResumeCareInboxWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CareInboxRecord(input.careInbox, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Patientapp_V1_CancelPatientHomeWorkflowRequest.with {
            $0.context = input.context
            $0.details = Acme_Patientapp_V1_CancelPatientHomeWorkflowRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.preferredChannel = input.details.notify.preferredChannel
                }
            }
        }
        async let remote0 = self.patientappPatientHomeWorkflow.cancelPatientHomeWorkflow(outbound0)
        async let persisted0 = store.count(tenant: input.context.tenantID)
        let (reply0, count0) = try await (remote0, persisted0)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count0)])
        let outbound1 = Acme_Patients_V1_SignalPatientWorkflowRequest.with {
            $0.context = input.context
            $0.details = Acme_Patients_V1_SignalPatientWorkflowRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.name = input.details.notify.name
                }
            }
        }
        let reply1 = try await self.resumeCareInboxWorkflowStep1.execute(outbound1)
        return Acme_Patientapp_V1_ResumeCareInboxWorkflowResponse.with {
            $0.careInbox = Acme_Patientapp_V1_CareInbox.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.recipient = reply1.patient.primaryAddress.recipient
                }
                $0.careInboxID = input.careInboxID
                $0.issuedAt = input.careInbox.issuedAt
            }
            $0.outcome = Acme_Patientapp_V1_ResumeCareInboxWorkflowResponse.Outcome.with {
                $0.status = reply1.outcome.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.outcome.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processRetryCareInboxWorkflow(_ input: Acme_Patientapp_V1_RetryCareInboxWorkflowRequest) async throws
        -> Acme_Patientapp_V1_RetryCareInboxWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.careInbox.audit.createdBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "audit", detail: input.careInbox.audit.createdBy
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "RetryCareInboxWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CareInboxRecord(input.careInbox, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Patientapp_V1_CancelPatientHomeWorkflowRequest.with {
            $0.context = input.context
            $0.details = Acme_Patientapp_V1_CancelPatientHomeWorkflowRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.preferredChannel = input.details.notify.preferredChannel
                }
            }
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = input.careInbox.audit.etag
                    $0.updatedBy = input.careInbox.audit.updatedBy
                }
            }
        }
        let port0 = RPCOperations.port { (request: Acme_Patientapp_V1_CancelPatientHomeWorkflowRequest) in
            try await self.patientappPatientHomeWorkflow.cancelPatientHomeWorkflow(request)
        }
        let reply0 = try await port0.execute(outbound0)
        let outbound1 = Acme_Prescriptions_V1_ScheduleRefillExpiryRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_ScheduleRefillExpiryRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.notify.email
                }
            }
        }
        let reply1 = try await self.retryCareInboxWorkflowStep1(outbound1)
        return Acme_Patientapp_V1_RetryCareInboxWorkflowResponse.with {
            $0.careInbox = Acme_Patientapp_V1_CareInbox.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply1.refill.audit.updatedAt
                }
                $0.careInboxID = input.careInboxID
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.patientID = reply0.patientHome.customer.patientID
                }
                $0.status = input.careInbox.status
            }
            $0.outcome = Acme_Patientapp_V1_RetryCareInboxWorkflowResponse.Outcome.with {
                $0.nextSteps = reply0.outcome.nextSteps + reply1.outcome.nextSteps
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processSignalCareInboxWorkflow(_ input: Acme_Patientapp_V1_SignalCareInboxWorkflowRequest) async throws
        -> Acme_Patientapp_V1_SignalCareInboxWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.careInbox.audit.createdBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "audit", detail: input.careInbox.audit.createdBy
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "SignalCareInboxWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CareInboxRecord(input.careInbox, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Patientapp_V1_StartPatientHomeWorkflowRequest.with {
            $0.context = input.context
            $0.details = Acme_Patientapp_V1_StartPatientHomeWorkflowRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.notify.email
                    $0.preferredChannel = input.details.notify.preferredChannel
                }
            }
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = input.careInbox.audit.updatedBy
                }
                $0.customer = Acme_Patients_V1_PatientRef.with {
                    $0.email = input.careInbox.counterparty.email
                }
            }
        }
        guard
            let execute0 = self.signalCareInboxWorkflowStep0[settings.region]
                ?? self.signalCareInboxWorkflowStep0["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply0 = try await execute0(outbound0)
        let selection1_3: String
        switch input.careInbox.settlement {
        case .bank(let bank):
            selection1_3 = bank.iban
        default: selection1_3 = .init()
        }
        let outbound1 = Acme_Careplans_V1_AdvanceCarePlanWorkflowRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply0.patientHome.audit.updatedBy
                }
                $0.bank = Acme_Careplans_V1_CarePlanBankSettlement.with {
                    $0.iban = selection1_3
                }
            }
            $0.context = input.context
            $0.details = Acme_Careplans_V1_AdvanceCarePlanWorkflowRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.careInbox.counterparty.email
                    $0.phone = reply0.patientHome.requester.phone
                }
            }
        }
        let reply1 = try await self.careplansCarePlanWorkflow.advanceCarePlanWorkflow(outbound1)
        let outbound2 = Acme_Careplans_V1_ListVitalReportsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Careplans_V1_ListVitalReportsRequest.Filter.with {
                $0.createdAfter = input.careInbox.audit.updatedAt
                $0.labels = reply0.patientHome.customFields
                $0.ownerID = reply1.outcome.referenceID
                $0.region = input.careInbox.billingAddress.region
            }
        }
        let reply2 = try await self.careplansVitalReporting.listVitalReports(outbound2)
        return Acme_Patientapp_V1_SignalCareInboxWorkflowResponse.with {
            $0.careInbox = Acme_Patientapp_V1_CareInbox.with {
                $0.careInboxID = input.careInboxID
                $0.total = input.careInbox.total
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = Projection.firstValue(
                    [
                        reply0.result.details,
                        reply2.result.details,
                    ], default: .init())
                $0.message = reply1.outcome.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processStartCareInboxWorkflow(_ input: Acme_Patientapp_V1_StartCareInboxWorkflowRequest) async throws
        -> Acme_Patientapp_V1_StartCareInboxWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.careInbox.audit.createdBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "audit", detail: input.careInbox.audit.createdBy
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "StartCareInboxWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CareInboxRecord(input.careInbox, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Patients_V1_CancelPatientWorkflowRequest.with {
            $0.context = input.context
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.name = input.details.notify.name
                }
            }
        }
        let envelope0 = try Google_Protobuf_Any(message: outbound0)
        let unpacked0 = try Acme_Patients_V1_CancelPatientWorkflowRequest(unpackingAny: envelope0)
        let reply0 = try await self.patientsPatientWorkflow.cancelPatientWorkflow(unpacked0)
        let outbound1 = Acme_Patients_V1_GenerateMedicalRecordReportRequest.with {
            $0.annotations = input.annotations
            $0.context = input.context
            $0.reason = input.reason
        }
        let json1 = try outbound1.jsonString()
        let decoded1 = try Acme_Patients_V1_GenerateMedicalRecordReportRequest(jsonString: json1)
        let reply1 = try await self.patientsMedicalRecordReporting.generateMedicalRecordReport(decoded1)
        return Acme_Patientapp_V1_StartCareInboxWorkflowResponse.with {
            $0.careInbox = Acme_Patientapp_V1_CareInbox.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply0.patient.audit.updatedBy
                }
                $0.billingAddress = input.careInbox.billingAddress
                $0.careInboxID = input.careInboxID
            }
            $0.outcome = Acme_Patientapp_V1_StartCareInboxWorkflowResponse.Outcome.with {
                $0.referenceID = reply0.outcome.referenceID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.status = "ok"
            }
        }
    }
}
