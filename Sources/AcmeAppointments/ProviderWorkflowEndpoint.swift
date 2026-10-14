import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Runs the long-lived workflow that takes a provider from start to finish.
final class ProviderWorkflowEndpoint: Acme_Appointments_V1_ProviderWorkflowService.ServiceProtocol {
    private let store: any RecordRepository
    private let logger: Logger
    private let settings: Settings
    private let followUps = WorkQueue<Acme_Identity_V1_GetUserRequest>()
    private let appointmentsAppointment: Acme_Appointments_V1_AppointmentService.Client<MeshTransport>
    private let appointmentsAppointmentApproval: Acme_Appointments_V1_AppointmentApprovalService.Client<MeshTransport>
    private let appointmentsAppointmentQuery: Acme_Appointments_V1_AppointmentQueryService.Client<MeshTransport>
    private let appointmentsAppointmentWorkflow: Acme_Appointments_V1_AppointmentWorkflowService.Client<MeshTransport>
    private let appointmentsClinicSlotApproval: Acme_Appointments_V1_ClinicSlotApprovalService.Client<MeshTransport>
    private let appointmentsClinicSlotCalculation:
        Acme_Appointments_V1_ClinicSlotCalculationService.Client<MeshTransport>
    private let appointmentsClinicSlotValidation: Acme_Appointments_V1_ClinicSlotValidationService.Client<MeshTransport>
    private let appointmentsProviderApproval: Acme_Appointments_V1_ProviderApprovalService.Client<MeshTransport>
    private let auditAuditEvent: Acme_Audit_V1_AuditEventService.Client<MeshTransport>
    private let careplansCarePlanWorkflow: Acme_Careplans_V1_CarePlanWorkflowService.Client<MeshTransport>
    private let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    private let notificationsNotificationQuery: Acme_Notifications_V1_NotificationQueryService.Client<MeshTransport>
    private let prescriptionsPrescription: Acme_Prescriptions_V1_PrescriptionService.Client<MeshTransport>
    private let prescriptionsPrescriptionReporting:
        Acme_Prescriptions_V1_PrescriptionReportingService.Client<MeshTransport>
    private let searchSearchIndexValidation: Acme_Search_V1_SearchIndexValidationService.Client<MeshTransport>
    private let sponsorshipsSponsorCalculation: Acme_Sponsorships_V1_SponsorCalculationService.Client<MeshTransport>
    private let cancelProviderWorkflowStep1:
        any RPCPort<Acme_Appointments_V1_UpdateAppointmentRequest, Acme_Appointments_V1_UpdateAppointmentResponse>
    private let inspectProviderWorkflowStep0:
        @Sendable (Acme_Appointments_V1_RejectClinicSlotRequest) async throws ->
            Acme_Appointments_V1_RejectClinicSlotResponse
    private let inspectProviderWorkflowStep1:
        [String:
            @Sendable (Acme_Search_V1_ScoreSearchIndexRequest) async throws -> Acme_Search_V1_ScoreSearchIndexResponse]

    init(
        dependencies: any Dependencies,
        appointmentsAppointment: Acme_Appointments_V1_AppointmentService.Client<MeshTransport>,
        appointmentsAppointmentApproval: Acme_Appointments_V1_AppointmentApprovalService.Client<MeshTransport>,
        appointmentsAppointmentQuery: Acme_Appointments_V1_AppointmentQueryService.Client<MeshTransport>,
        appointmentsAppointmentWorkflow: Acme_Appointments_V1_AppointmentWorkflowService.Client<MeshTransport>,
        appointmentsClinicSlotApproval: Acme_Appointments_V1_ClinicSlotApprovalService.Client<MeshTransport>,
        appointmentsClinicSlotCalculation: Acme_Appointments_V1_ClinicSlotCalculationService.Client<MeshTransport>,
        appointmentsClinicSlotValidation: Acme_Appointments_V1_ClinicSlotValidationService.Client<MeshTransport>,
        appointmentsProviderApproval: Acme_Appointments_V1_ProviderApprovalService.Client<MeshTransport>,
        auditAuditEvent: Acme_Audit_V1_AuditEventService.Client<MeshTransport>,
        careplansCarePlanWorkflow: Acme_Careplans_V1_CarePlanWorkflowService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        notificationsNotificationQuery: Acme_Notifications_V1_NotificationQueryService.Client<MeshTransport>,
        prescriptionsPrescription: Acme_Prescriptions_V1_PrescriptionService.Client<MeshTransport>,
        prescriptionsPrescriptionReporting: Acme_Prescriptions_V1_PrescriptionReportingService.Client<MeshTransport>,
        searchSearchIndexValidation: Acme_Search_V1_SearchIndexValidationService.Client<MeshTransport>,
        sponsorshipsSponsorCalculation: Acme_Sponsorships_V1_SponsorCalculationService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.appointmentsAppointment = appointmentsAppointment
        self.appointmentsAppointmentApproval = appointmentsAppointmentApproval
        self.appointmentsAppointmentQuery = appointmentsAppointmentQuery
        self.appointmentsAppointmentWorkflow = appointmentsAppointmentWorkflow
        self.appointmentsClinicSlotApproval = appointmentsClinicSlotApproval
        self.appointmentsClinicSlotCalculation = appointmentsClinicSlotCalculation
        self.appointmentsClinicSlotValidation = appointmentsClinicSlotValidation
        self.appointmentsProviderApproval = appointmentsProviderApproval
        self.auditAuditEvent = auditAuditEvent
        self.careplansCarePlanWorkflow = careplansCarePlanWorkflow
        self.identityUser = identityUser
        self.notificationsNotificationQuery = notificationsNotificationQuery
        self.prescriptionsPrescription = prescriptionsPrescription
        self.prescriptionsPrescriptionReporting = prescriptionsPrescriptionReporting
        self.searchSearchIndexValidation = searchSearchIndexValidation
        self.sponsorshipsSponsorCalculation = sponsorshipsSponsorCalculation
        self.cancelProviderWorkflowStep1 = ClosurePort<
            Acme_Appointments_V1_UpdateAppointmentRequest, Acme_Appointments_V1_UpdateAppointmentResponse
        >({ request in try await appointmentsAppointment.updateAppointment(request) })
        self.inspectProviderWorkflowStep0 = { request in
            try await appointmentsClinicSlotApproval.rejectClinicSlot(request)
        }
        self.inspectProviderWorkflowStep1 = [
            "primary": { request in try await searchSearchIndexValidation.scoreSearchIndex(request) }
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

    /// Advances a provider.
    func advanceProviderWorkflow(
        request: ServerRequest<Acme_Appointments_V1_AdvanceProviderWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_AdvanceProviderWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processAdvanceProviderWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Cancels a provider.
    func cancelProviderWorkflow(
        request: ServerRequest<Acme_Appointments_V1_CancelProviderWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_CancelProviderWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCancelProviderWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a provider.
    func inspectProviderWorkflow(
        request: ServerRequest<Acme_Appointments_V1_InspectProviderWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_InspectProviderWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processInspectProviderWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists providers a page at a time.
    func listProviderWorkflows(
        request: ServerRequest<Acme_Appointments_V1_ListProviderWorkflowsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_ListProviderWorkflowsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListProviderWorkflows(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Pauses a provider.
    func pauseProviderWorkflow(
        request: ServerRequest<Acme_Appointments_V1_PauseProviderWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_PauseProviderWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processPauseProviderWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Resumes a provider.
    func resumeProviderWorkflow(
        request: ServerRequest<Acme_Appointments_V1_ResumeProviderWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_ResumeProviderWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processResumeProviderWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Retrys a provider.
    func retryProviderWorkflow(
        request: ServerRequest<Acme_Appointments_V1_RetryProviderWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_RetryProviderWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRetryProviderWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Signals a provider.
    func signalProviderWorkflow(
        request: ServerRequest<Acme_Appointments_V1_SignalProviderWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_SignalProviderWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSignalProviderWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Starts a provider.
    func startProviderWorkflow(
        request: ServerRequest<Acme_Appointments_V1_StartProviderWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_StartProviderWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processStartProviderWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processAdvanceProviderWorkflow(_ input: Acme_Appointments_V1_AdvanceProviderWorkflowRequest) async throws
        -> Acme_Appointments_V1_AdvanceProviderWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "provider",
            action: "audit", detail: input.details.initiatedBy
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "AdvanceProviderWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try ProviderRecord(input.provider, tenant: input.context.tenantID)
        try await store.save(record.stored)
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
        let outbound0 = Acme_Careplans_V1_StartCarePlanWorkflowRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = input.provider.primaryAddress.postalCode
                }
            }
            $0.context = input.context
            $0.details = Acme_Careplans_V1_StartCarePlanWorkflowRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.provider.contact.email
                    $0.preferredChannel = input.details.notify.preferredChannel
                }
            }
        }
        let reply0 = try await self.careplansCarePlanWorkflow.startCarePlanWorkflow(outbound0)
        return Acme_Appointments_V1_AdvanceProviderWorkflowResponse.with {
            $0.provider = Acme_Appointments_V1_Provider.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply0.carePlan.audit.updatedAt
                }
                $0.providerID = input.providerID
                $0.status = input.provider.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply0.result.status
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processCancelProviderWorkflow(_ input: Acme_Appointments_V1_CancelProviderWorkflowRequest) async throws
        -> Acme_Appointments_V1_CancelProviderWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "provider",
            action: "audit", detail: input.details.initiatedBy
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "CancelProviderWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try ProviderRecord(input.provider, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Appointments_V1_ResumeAppointmentWorkflowRequest.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = input.provider.audit.updatedAt
                }
                $0.participants = [
                    Acme_Appointments_V1_AppointmentParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.name = input.provider.contact.name
                            $0.preferredChannel = input.provider.contact.preferredChannel
                        }
                    }
                ]
            }
            $0.context = input.context
        }
        async let remote0 = self.appointmentsAppointmentWorkflow.resumeAppointmentWorkflow(outbound0)
        async let persisted0 = store.count(tenant: input.context.tenantID)
        let (reply0, count0) = try await (remote0, persisted0)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count0)])
        let outbound1 = Acme_Appointments_V1_UpdateAppointmentRequest.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply0.appointment.audit.updatedBy
                }
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.provider.primaryAddress.region
                }
                $0.participants = [
                    Acme_Appointments_V1_AppointmentParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.name = input.provider.contact.name
                            $0.preferredChannel = input.provider.contact.preferredChannel
                        }
                    }
                ]
            }
            $0.context = input.context
        }
        let reply1 = try await self.cancelProviderWorkflowStep1.execute(outbound1)
        let outbound2 = Acme_Appointments_V1_CountAppointmentsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Appointments_V1_CountAppointmentsRequest.Filter.with {
                $0.region = reply0.appointment.location.region
            }
        }
        let port2 = RPCOperations.port { (request: Acme_Appointments_V1_CountAppointmentsRequest) in
            try await self.appointmentsAppointmentQuery.countAppointments(request)
        }
        let reply2 = try await port2.execute(outbound2)
        return Acme_Appointments_V1_CancelProviderWorkflowResponse.with {
            $0.outcome = Acme_Appointments_V1_CancelProviderWorkflowResponse.Outcome.with {
                $0.message = Projection.firstValue(
                    [
                        reply1.result.message,
                        reply2.result.message,
                    ], default: .init())
            }
            $0.provider = Acme_Appointments_V1_Provider.with {
                $0.name = input.provider.name
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = reply0.appointment.location.postalCode
                }
                $0.providerID = input.providerID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processInspectProviderWorkflow(_ input: Acme_Appointments_V1_InspectProviderWorkflowRequest) async throws
        -> Acme_Appointments_V1_InspectProviderWorkflowResponse
    {
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "InspectProviderWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "provider",
            action: "InspectProviderWorkflow", detail: input.context.traceID
        )
        let outbound0 = Acme_Appointments_V1_RejectClinicSlotRequest.with {
            $0.clinicSlot = Acme_Appointments_V1_ClinicSlot.with {
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.email = input.context.actor.email
                }
            }
            $0.context = input.context
            $0.details = Acme_Appointments_V1_RejectClinicSlotRequest.Details.with {
                $0.approver = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.context.actor.userID
                }
            }
        }
        let reply0 = try await self.inspectProviderWorkflowStep0(outbound0)
        let outbound1 = Acme_Search_V1_ScoreSearchIndexRequest.with {
            $0.context = input.context
            $0.details = Acme_Search_V1_ScoreSearchIndexRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.recipient = reply0.clinicSlot.location.recipient
                }
            }
            $0.searchIndex = Acme_Search_V1_SearchIndex.with {
                $0.address = Acme_Common_V1_PostalAddress.with {
                    $0.locality = reply0.clinicSlot.location.locality
                    $0.region = reply0.clinicSlot.location.region
                }
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.userID = reply0.clinicSlot.organizer.userID
                }
            }
        }
        guard
            let execute1 = self.inspectProviderWorkflowStep1[settings.region]
                ?? self.inspectProviderWorkflowStep1["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply1 = try await execute1(outbound1)
        return Acme_Appointments_V1_InspectProviderWorkflowResponse.with {
            $0.provider = Acme_Appointments_V1_Provider.with {
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = reply1.searchIndex.address.postalCode
                }
                $0.providerID = input.providerID
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.email = reply0.clinicSlot.organizer.email
                    $0.userID = reply1.searchIndex.owner.userID
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processListProviderWorkflows(_ input: Acme_Appointments_V1_ListProviderWorkflowsRequest) async throws
        -> Acme_Appointments_V1_ListProviderWorkflowsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "provider",
            action: "audit", detail: input.filter.ownerID
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ListProviderWorkflows",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "provider",
            action: "ListProviderWorkflows", detail: input.context.traceID
        )
        return Acme_Appointments_V1_ListProviderWorkflowsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processPauseProviderWorkflow(_ input: Acme_Appointments_V1_PauseProviderWorkflowRequest) async throws
        -> Acme_Appointments_V1_PauseProviderWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "provider",
            action: "audit", detail: input.details.initiatedBy
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "PauseProviderWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try ProviderRecord(input.provider, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Sponsorships_V1_CompareSponsorOptionsRequest.with {
            $0.context = input.context
            $0.sponsor = Acme_Sponsorships_V1_Sponsor.with {
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.recipient = input.provider.primaryAddress.recipient
                }
            }
        }
        let reply0 = try await self.sponsorshipsSponsorCalculation.compareSponsorOptions(outbound0)
        let outbound1 = Acme_Prescriptions_V1_StreamPrescriptionMetricsRequest.with {
            $0.context = input.context
            $0.subscriber = Acme_Common_V1_ContactInfo.with {
                $0.name = input.details.notify.name
                $0.preferredChannel = input.provider.contact.preferredChannel
            }
        }
        let reply1 = try await self.prescriptionsPrescriptionReporting.streamPrescriptionMetrics(outbound1) {
            response in
            var latest = Acme_Prescriptions_V1_StreamPrescriptionMetricsResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        _ = reply1
        return Acme_Appointments_V1_PauseProviderWorkflowResponse.with {
            $0.provider = Acme_Appointments_V1_Provider.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.preferredChannel = reply0.sponsor.contact.preferredChannel
                }
                $0.primaryAddress = input.provider.primaryAddress
                $0.providerID = input.providerID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processResumeProviderWorkflow(_ input: Acme_Appointments_V1_ResumeProviderWorkflowRequest) async throws
        -> Acme_Appointments_V1_ResumeProviderWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "provider",
            action: "audit", detail: input.details.initiatedBy
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ResumeProviderWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try ProviderRecord(input.provider, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Search_V1_ScoreSearchIndexRequest.with {
            $0.context = input.context
            $0.details = Acme_Search_V1_ScoreSearchIndexRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.recipient = input.provider.primaryAddress.recipient
                }
            }
            $0.searchIndex = Acme_Search_V1_SearchIndex.with {
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.email = input.details.notify.email
                }
            }
        }
        let envelope0 = try Google_Protobuf_Any(message: outbound0)
        let unpacked0 = try Acme_Search_V1_ScoreSearchIndexRequest(unpackingAny: envelope0)
        let reply0 = try await self.searchSearchIndexValidation.scoreSearchIndex(unpacked0)
        let outbound1 = Acme_Appointments_V1_RecalculateClinicSlotsRequest.with {
            $0.clinicSlot = Acme_Appointments_V1_ClinicSlot.with {
                $0.participants = [
                    Acme_Appointments_V1_ClinicSlotParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.preferredChannel = input.provider.contact.preferredChannel
                        }
                    }
                ]
            }
            $0.context = input.context
            $0.details = Acme_Appointments_V1_RecalculateClinicSlotsRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.provider.primaryAddress.region
                }
            }
        }
        let json1 = try outbound1.jsonString()
        let decoded1 = try Acme_Appointments_V1_RecalculateClinicSlotsRequest(jsonString: json1)
        let reply1 = try await self.appointmentsClinicSlotCalculation.recalculateClinicSlots(decoded1)
        let outbound2 =
            Acme_Notifications_V1_ResolveNotificationsRequest.forProviderWorkflowEndpointResumeProviderWorkflow2(
                input
            )
        let reply2 = try await self.notificationsNotificationQuery.resolveNotifications(outbound2)
        return Acme_Appointments_V1_ResumeProviderWorkflowResponse.with {
            $0.outcome = Acme_Appointments_V1_ResumeProviderWorkflowResponse.Outcome.with {
                $0.status = reply2.result.status
            }
            $0.provider = Acme_Appointments_V1_Provider.with {
                $0.name = input.provider.name
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = reply1.clinicSlot.location.countryCode
                }
                $0.providerID = input.providerID
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.email = reply0.searchIndex.owner.email
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply2.result.status
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processRetryProviderWorkflow(_ input: Acme_Appointments_V1_RetryProviderWorkflowRequest) async throws
        -> Acme_Appointments_V1_RetryProviderWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "provider",
            action: "audit", detail: input.details.initiatedBy
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "RetryProviderWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try ProviderRecord(input.provider, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Appointments_V1_CloneAppointmentRequest.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = input.provider.primaryAddress.postalCode
                }
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.email = input.details.notify.email
                }
                $0.participants = [
                    Acme_Appointments_V1_AppointmentParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.name = input.provider.contact.name
                        }
                    }
                ]
            }
            $0.context = input.context
        }
        let reply0 = try await self.appointmentsAppointment.cloneAppointment(
            outbound0, metadata: ["x-acme-region": .string(settings.region)]
        )
        let outbound1 = Acme_Appointments_V1_CommentClinicSlotApprovalRequest.with {
            $0.clinicSlot = Acme_Appointments_V1_ClinicSlot.with {
                $0.participants = [
                    Acme_Appointments_V1_ClinicSlotParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = reply0.appointment.organizer.email
                            $0.name = input.details.notify.name
                            $0.phone = input.provider.contact.phone
                        }
                    }
                ]
            }
            $0.context = input.context
        }
        let reply1 = try await RPCOperations.call(outbound1) { request in
            try await self.appointmentsClinicSlotApproval.commentClinicSlotApproval(request)
        }
        let outbound2 = Acme_Appointments_V1_NormalizeClinicSlotRequest.with {
            $0.clinicSlot = Acme_Appointments_V1_ClinicSlot.with {
                $0.participants = [
                    Acme_Appointments_V1_ClinicSlotParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.name = Projection.read(
                                input, at: \Acme_Appointments_V1_RetryProviderWorkflowRequest.details.notify.name)
                            $0.phone = Projection.read(
                                input, at: \Acme_Appointments_V1_RetryProviderWorkflowRequest.provider.contact.phone)
                        }
                    }
                ]
            }
            $0.context = Projection.read(input, at: \Acme_Appointments_V1_RetryProviderWorkflowRequest.context)
        }
        let reply2 = try await self.appointmentsClinicSlotValidation.normalizeClinicSlot(outbound2)
        let outbound3 = Acme_Audit_V1_CreateAuditEventRequest.with {
            $0.auditEvent = Acme_Audit_V1_AuditEvent.with {
                $0.subject = Acme_Audit_V1_AuditTrailRef.with {
                    $0.displayName = reply2.clinicSlot.organizer.displayName
                }
            }
            $0.context = input.context
        }
        let step3: @Sendable () async throws -> Acme_Audit_V1_CreateAuditEventResponse = {
            try await self.auditAuditEvent.createAuditEvent(outbound3)
        }
        let reply3 = try await step3()
        return Acme_Appointments_V1_RetryProviderWorkflowResponse.with {
            $0.outcome = Acme_Appointments_V1_RetryProviderWorkflowResponse.Outcome.with {
                $0.message = Projection.firstValue(
                    [
                        reply0.result.message,
                        reply2.outcome.message,
                        reply3.result.message,
                    ], default: .init())
            }
            $0.provider = Acme_Appointments_V1_Provider.with {
                $0.attributes = input.provider.attributes
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply1.clinicSlot.audit.createdBy
                }
                $0.providerID = input.providerID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processSignalProviderWorkflow(_ input: Acme_Appointments_V1_SignalProviderWorkflowRequest) async throws
        -> Acme_Appointments_V1_SignalProviderWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "provider",
            action: "audit", detail: input.details.initiatedBy
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "SignalProviderWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try ProviderRecord(input.provider, tenant: input.context.tenantID)
        try await store.save(record.stored)
        var outbound0 = Acme_Appointments_V1_RecallProviderRequest()
        outbound0.context = input.context
        outbound0.details = Acme_Appointments_V1_RecallProviderRequest.Details.with {
            $0.approver = Acme_Identity_V1_UserRef.with {
                $0.email = input.provider.contact.email
            }
        }
        outbound0.provider = Acme_Appointments_V1_Provider.with {
            $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                $0.displayName = input.provider.relationshipManager.displayName
            }
        }
        let reply0 = try await self.appointmentsProviderApproval.recallProvider(outbound0)
        return Acme_Appointments_V1_SignalProviderWorkflowResponse.with {
            $0.provider = Acme_Appointments_V1_Provider.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.name = input.provider.name
                }
                $0.providerID = input.providerID
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.email = reply0.provider.contact.email
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processStartProviderWorkflow(_ input: Acme_Appointments_V1_StartProviderWorkflowRequest) async throws
        -> Acme_Appointments_V1_StartProviderWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "provider",
            action: "audit", detail: input.details.initiatedBy
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "StartProviderWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try ProviderRecord(input.provider, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Appointments_V1_SubmitAppointmentRequest.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.participants = [
                    Acme_Appointments_V1_AppointmentParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.name = input.provider.contact.name
                            $0.preferredChannel = input.provider.contact.preferredChannel
                        }
                    }
                ]
            }
            $0.context = input.context
        }
        let step0: @Sendable () async throws -> Acme_Appointments_V1_SubmitAppointmentResponse = {
            try await self.appointmentsAppointmentApproval.submitAppointment(outbound0)
        }
        let reply0 = try await step0()
        return Acme_Appointments_V1_StartProviderWorkflowResponse.with {
            $0.provider = Acme_Appointments_V1_Provider.with {
                $0.providerID = input.providerID
                $0.status = input.provider.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply0.result.status
            }
        }
    }
}
