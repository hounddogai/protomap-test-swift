import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Routes appointments through approval, with escalation and delegation.
final class AppointmentApprovalEndpoint: Acme_Appointments_V1_AppointmentApprovalService.ServiceProtocol {
    private let store: any RecordRepository
    private let logger: Logger
    private let settings: Settings
    private let followUps = WorkQueue<Acme_Identity_V1_GetUserRequest>()
    private let appointmentsAppointment: Acme_Appointments_V1_AppointmentService.Client<MeshTransport>
    private let appointmentsAppointmentQuery: Acme_Appointments_V1_AppointmentQueryService.Client<MeshTransport>
    private let appointmentsProviderQuery: Acme_Appointments_V1_ProviderQueryService.Client<MeshTransport>
    private let authorizationAccessPolicy: Acme_Authorization_V1_AccessPolicyService.Client<MeshTransport>
    private let careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>
    private let careplansVitalLifecycle: Acme_Careplans_V1_VitalLifecycleService.Client<MeshTransport>
    private let featureflagsFeatureFlag: Acme_Featureflags_V1_FeatureFlagService.Client<MeshTransport>
    private let featureflagsFeatureFlagValidation:
        Acme_Featureflags_V1_FeatureFlagValidationService.Client<MeshTransport>
    private let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    private let prescriptionsPrescriptionReporting:
        Acme_Prescriptions_V1_PrescriptionReportingService.Client<MeshTransport>
    private let prescriptionsRefillWorkflow: Acme_Prescriptions_V1_RefillWorkflowService.Client<MeshTransport>
    private let ratelimitingRateLimitCalculation: Acme_Ratelimiting_V1_RateLimitCalculationService.Client<MeshTransport>
    private let telehealthVideoVisitApproval: Acme_Telehealth_V1_VideoVisitApprovalService.Client<MeshTransport>
    private let escalateAppointmentStep0:
        any RPCPort<Acme_Featureflags_V1_ValidateFeatureFlagRequest, Acme_Featureflags_V1_ValidateFeatureFlagResponse>
    private let escalateAppointmentStep2:
        @Sendable (Acme_Appointments_V1_CountProvidersRequest) async throws ->
            Acme_Appointments_V1_CountProvidersResponse
    private let escalateAppointmentStep3:
        [String:
            @Sendable (Acme_Appointments_V1_GetAppointmentRequest) async throws ->
            Acme_Appointments_V1_GetAppointmentResponse]

    init(
        dependencies: any Dependencies,
        appointmentsAppointment: Acme_Appointments_V1_AppointmentService.Client<MeshTransport>,
        appointmentsAppointmentQuery: Acme_Appointments_V1_AppointmentQueryService.Client<MeshTransport>,
        appointmentsProviderQuery: Acme_Appointments_V1_ProviderQueryService.Client<MeshTransport>,
        authorizationAccessPolicy: Acme_Authorization_V1_AccessPolicyService.Client<MeshTransport>,
        careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>,
        careplansVitalLifecycle: Acme_Careplans_V1_VitalLifecycleService.Client<MeshTransport>,
        featureflagsFeatureFlag: Acme_Featureflags_V1_FeatureFlagService.Client<MeshTransport>,
        featureflagsFeatureFlagValidation: Acme_Featureflags_V1_FeatureFlagValidationService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        prescriptionsPrescriptionReporting: Acme_Prescriptions_V1_PrescriptionReportingService.Client<MeshTransport>,
        prescriptionsRefillWorkflow: Acme_Prescriptions_V1_RefillWorkflowService.Client<MeshTransport>,
        ratelimitingRateLimitCalculation: Acme_Ratelimiting_V1_RateLimitCalculationService.Client<MeshTransport>,
        telehealthVideoVisitApproval: Acme_Telehealth_V1_VideoVisitApprovalService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.appointmentsAppointment = appointmentsAppointment
        self.appointmentsAppointmentQuery = appointmentsAppointmentQuery
        self.appointmentsProviderQuery = appointmentsProviderQuery
        self.authorizationAccessPolicy = authorizationAccessPolicy
        self.careplansCarePlan = careplansCarePlan
        self.careplansVitalLifecycle = careplansVitalLifecycle
        self.featureflagsFeatureFlag = featureflagsFeatureFlag
        self.featureflagsFeatureFlagValidation = featureflagsFeatureFlagValidation
        self.identityUser = identityUser
        self.prescriptionsPrescriptionReporting = prescriptionsPrescriptionReporting
        self.prescriptionsRefillWorkflow = prescriptionsRefillWorkflow
        self.ratelimitingRateLimitCalculation = ratelimitingRateLimitCalculation
        self.telehealthVideoVisitApproval = telehealthVideoVisitApproval
        self.escalateAppointmentStep0 = ClosurePort<
            Acme_Featureflags_V1_ValidateFeatureFlagRequest, Acme_Featureflags_V1_ValidateFeatureFlagResponse
        >({ request in try await featureflagsFeatureFlagValidation.validateFeatureFlag(request) })
        self.escalateAppointmentStep2 = { request in try await appointmentsProviderQuery.countProviders(request) }
        self.escalateAppointmentStep3 = [
            "primary": { request in try await appointmentsAppointment.getAppointment(request) }
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

    /// Approves an appointment.
    func approveAppointment(
        request: ServerRequest<Acme_Appointments_V1_ApproveAppointmentRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_ApproveAppointmentResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processApproveAppointment(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Comments an appointment.
    func commentAppointmentApproval(
        request: ServerRequest<Acme_Appointments_V1_CommentAppointmentApprovalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_CommentAppointmentApprovalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCommentAppointmentApproval(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Delegates an appointment.
    func delegateAppointmentApproval(
        request: ServerRequest<Acme_Appointments_V1_DelegateAppointmentApprovalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_DelegateAppointmentApprovalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processDelegateAppointmentApproval(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Escalates an appointment.
    func escalateAppointment(
        request: ServerRequest<Acme_Appointments_V1_EscalateAppointmentRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_EscalateAppointmentResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processEscalateAppointment(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns an appointment.
    func getAppointmentApprovalStatus(
        request: ServerRequest<Acme_Appointments_V1_GetAppointmentApprovalStatusRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_GetAppointmentApprovalStatusResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetAppointmentApprovalStatus(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists appointments a page at a time.
    func listPendingAppointments(
        request: ServerRequest<Acme_Appointments_V1_ListPendingAppointmentsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_ListPendingAppointmentsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListPendingAppointments(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Rejects an appointment.
    func rejectAppointment(
        request: ServerRequest<Acme_Appointments_V1_RejectAppointmentRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_RejectAppointmentResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRejectAppointment(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Submits an appointment.
    func submitAppointment(
        request: ServerRequest<Acme_Appointments_V1_SubmitAppointmentRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_SubmitAppointmentResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSubmitAppointment(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processApproveAppointment(_ input: Acme_Appointments_V1_ApproveAppointmentRequest) async throws
        -> Acme_Appointments_V1_ApproveAppointmentResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.appointment.audit.createdBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "appointment",
            action: "audit", detail: input.appointment.audit.createdBy
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ApproveAppointment",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try AppointmentRecord(input.appointment, tenant: input.context.tenantID)
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
        let outbound0 = Acme_Careplans_V1_ScheduleVitalExpiryRequest.with {
            $0.context = input.context
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.subject = Acme_Appointments_V1_AppointmentRef.with {
                    $0.appointmentID = input.appointment.appointmentID
                    $0.displayName = input.appointment.organizer.displayName
                }
            }
        }
        let reply0 = try await self.careplansVitalLifecycle.scheduleVitalExpiry(outbound0)
        return Acme_Appointments_V1_ApproveAppointmentResponse.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.appointmentID = reply0.vital.subject.appointmentID
                $0.location = input.appointment.location
                $0.window = input.appointment.window
            }
            $0.outcome = Acme_Appointments_V1_ApproveAppointmentResponse.Outcome.with {
                $0.nextSteps = reply0.outcome.nextSteps
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processCommentAppointmentApproval(_ input: Acme_Appointments_V1_CommentAppointmentApprovalRequest) async throws
        -> Acme_Appointments_V1_CommentAppointmentApprovalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.appointment.appointmentID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "appointment",
            action: "audit", detail: input.appointment.appointmentID
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "CommentAppointmentApproval",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try AppointmentRecord(input.appointment, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let requests0 = input.appointment.participants.map { element in
            Acme_Appointments_V1_SuggestAppointmentsRequest.with {
                $0.context = input.context
                $0.filter = Acme_Appointments_V1_SuggestAppointmentsRequest.Filter.with {
                    $0.ownerID = element.participantID
                    $0.region = input.appointment.location.region
                }
            }
        }
        let replies0 = try await FanOut.map(requests0) { candidate in
            try await self.appointmentsAppointmentQuery.suggestAppointments(candidate)
        }
        let reply0 = replies0.first ?? Acme_Appointments_V1_SuggestAppointmentsResponse()
        _ = reply0
        return Acme_Appointments_V1_CommentAppointmentApprovalResponse.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.appointmentID = input.appointmentID
                $0.organizer = input.appointment.organizer
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processDelegateAppointmentApproval(_ input: Acme_Appointments_V1_DelegateAppointmentApprovalRequest)
        async throws -> Acme_Appointments_V1_DelegateAppointmentApprovalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.appointment.appointmentID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "appointment",
            action: "audit", detail: input.appointment.appointmentID
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "DelegateAppointmentApproval",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try AppointmentRecord(input.appointment, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Authorization_V1_ListAccessPoliciesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Authorization_V1_ListAccessPoliciesRequest.Filter.with {
                $0.createdAfter = input.appointment.audit.updatedAt
                $0.region = input.appointment.location.region
            }
        }
        async let remote0 = self.authorizationAccessPolicy.listAccessPolicies(outbound0)
        async let persisted0 = store.count(tenant: input.context.tenantID)
        let (reply0, count0) = try await (remote0, persisted0)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count0)])
        return Acme_Appointments_V1_DelegateAppointmentApprovalResponse.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.appointmentID = input.appointmentID
                $0.status = input.appointment.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processEscalateAppointment(_ input: Acme_Appointments_V1_EscalateAppointmentRequest) async throws
        -> Acme_Appointments_V1_EscalateAppointmentResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.appointment.audit.createdBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "appointment",
            action: "audit", detail: input.appointment.audit.createdBy
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "EscalateAppointment",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try AppointmentRecord(input.appointment, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Featureflags_V1_ValidateFeatureFlagRequest.with {
            $0.context = input.context
            $0.featureFlag = Acme_Featureflags_V1_FeatureFlag.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = input.appointment.audit.etag
                }
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.email = input.appointment.organizer.email
                    $0.userID = input.details.approver.userID
                }
            }
        }
        let reply0 = try await self.escalateAppointmentStep0.execute(outbound0)
        let outbound1 = Acme_Featureflags_V1_ListFeatureFlagsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Featureflags_V1_ListFeatureFlagsRequest.Filter.with {
                $0.createdAfter = input.appointment.audit.createdAt
                $0.region = input.appointment.location.region
            }
        }
        let port1 = RPCOperations.port { (request: Acme_Featureflags_V1_ListFeatureFlagsRequest) in
            try await self.featureflagsFeatureFlag.listFeatureFlags(request)
        }
        let reply1 = try await port1.execute(outbound1)
        let outbound2 = Acme_Appointments_V1_CountProvidersRequest.with {
            $0.context = input.context
            $0.filter = Acme_Appointments_V1_CountProvidersRequest.Filter.with {
                $0.region = input.appointment.location.region
            }
        }
        let reply2 = try await self.escalateAppointmentStep2(outbound2)
        let outbound3 = Acme_Appointments_V1_GetAppointmentRequest.with {
            $0.appointmentID = input.appointment.appointmentID
            $0.context = input.context
        }
        guard let execute3 = self.escalateAppointmentStep3[settings.region] ?? self.escalateAppointmentStep3["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply3 = try await execute3(outbound3)
        return Acme_Appointments_V1_EscalateAppointmentResponse.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.appointmentID = input.appointmentID
                $0.location = reply3.appointment.location
                $0.status = input.appointment.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply2.result.correlationID
                $0.message = reply0.outcome.message
                $0.status = reply1.result.status
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processGetAppointmentApprovalStatus(_ input: Acme_Appointments_V1_GetAppointmentApprovalStatusRequest)
        async throws -> Acme_Appointments_V1_GetAppointmentApprovalStatusResponse
    {
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "GetAppointmentApprovalStatus",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "appointment",
            action: "GetAppointmentApprovalStatus", detail: input.context.traceID
        )
        let outbound0 = Acme_Ratelimiting_V1_EstimateRateLimitRequest.with {
            $0.context = input.context
            $0.rateLimit = Acme_Ratelimiting_V1_RateLimit.with {
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.context.actor.userID
                }
            }
        }
        let reply0 = try await self.ratelimitingRateLimitCalculation.estimateRateLimit(outbound0)
        return Acme_Appointments_V1_GetAppointmentApprovalStatusResponse.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.appointmentID = input.appointmentID
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply0.rateLimit.audit.createdAt
                    $0.createdBy = reply0.rateLimit.audit.createdBy
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processListPendingAppointments(_ input: Acme_Appointments_V1_ListPendingAppointmentsRequest) async throws
        -> Acme_Appointments_V1_ListPendingAppointmentsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "appointment",
            action: "audit", detail: input.filter.ownerID
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ListPendingAppointments",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "appointment",
            action: "ListPendingAppointments", detail: input.context.traceID
        )
        let outbound0 = Acme_Prescriptions_V1_ListPrescriptionReportsRequest.with {
            $0.context = input.context
            $0.page = Acme_Common_V1_PageRequest.with {
                $0.pageSize = input.page.pageSize
            }
        }
        let envelope0 = try Google_Protobuf_Any(message: outbound0)
        let unpacked0 = try Acme_Prescriptions_V1_ListPrescriptionReportsRequest(unpackingAny: envelope0)
        let reply0 = try await self.prescriptionsPrescriptionReporting.listPrescriptionReports(unpacked0)
        let outbound1 = Acme_Telehealth_V1_CommentVideoVisitApprovalRequest.with {
            $0.context = input.context
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
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
        let json1 = try outbound1.jsonString()
        let decoded1 = try Acme_Telehealth_V1_CommentVideoVisitApprovalRequest(jsonString: json1)
        let reply1 = try await self.telehealthVideoVisitApproval.commentVideoVisitApproval(decoded1)
        return Acme_Appointments_V1_ListPendingAppointmentsResponse.with {
            $0.appointments = [
                Acme_Appointments_V1_Appointment.with {
                    $0.location = reply1.videoVisit.location
                }
            ]
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

    /// Execute the appointments workflow and project its upstream replies.
    func processRejectAppointment(_ input: Acme_Appointments_V1_RejectAppointmentRequest) async throws
        -> Acme_Appointments_V1_RejectAppointmentResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.appointment.appointmentID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "appointment",
            action: "audit", detail: input.appointment.appointmentID
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "RejectAppointment",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try AppointmentRecord(input.appointment, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let requests0 = input.appointment.participants.map { element in
            Acme_Prescriptions_V1_SignalRefillWorkflowRequest.with {
                $0.context = input.context
                $0.details = Acme_Prescriptions_V1_SignalRefillWorkflowRequest.Details.with {
                    $0.notify = Acme_Common_V1_ContactInfo.with {
                        $0.phone = element.contact.phone
                    }
                }
            }
        }
        let replies0 = try await FanOut.map(requests0) { candidate in
            try await self.prescriptionsRefillWorkflow.signalRefillWorkflow(candidate)
        }
        let reply0 = replies0.first ?? Acme_Prescriptions_V1_SignalRefillWorkflowResponse()
        _ = reply0
        return Acme_Appointments_V1_RejectAppointmentResponse.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.appointmentID = input.appointmentID
                $0.title = input.appointment.title
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processSubmitAppointment(_ input: Acme_Appointments_V1_SubmitAppointmentRequest) async throws
        -> Acme_Appointments_V1_SubmitAppointmentResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.appointment.audit.createdBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "appointment",
            action: "audit", detail: input.appointment.audit.createdBy
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "SubmitAppointment",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try AppointmentRecord(input.appointment, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Appointments_V1_BrowseProvidersRequest.forAppointmentApprovalEndpointSubmitAppointment0(
            input
        )
        let reply0 = try await self.appointmentsProviderQuery.browseProviders(outbound0)
        let outbound1 = Acme_Appointments_V1_LookupAppointmentRequest.with {
            $0.appointmentID = input.appointment.appointmentID
            $0.context = input.context
        }
        let reply1 = try await self.appointmentsAppointmentQuery.lookupAppointment(
            outbound1, metadata: ["x-acme-region": .string(settings.region)]
        )
        return Acme_Appointments_V1_SubmitAppointmentResponse.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.appointmentID = input.appointmentID
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.lines = reply1.appointment.location.lines
                    $0.region = reply1.appointment.location.region
                }
                $0.metadata = input.appointment.metadata
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }
}
