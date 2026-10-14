import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Runs the long-lived workflow that takes a care goal from start to finish.
final class CareGoalWorkflowEndpoint: Acme_Careplans_V1_CareGoalWorkflowService.ServiceProtocol {
    private let store: any RecordRepository
    private let logger: Logger
    private let settings: Settings
    private let followUps = WorkQueue<Acme_Identity_V1_GetUserRequest>()
    private let appointmentsAppointment: Acme_Appointments_V1_AppointmentService.Client<MeshTransport>
    private let authorizationAccessPolicyValidation:
        Acme_Authorization_V1_AccessPolicyValidationService.Client<MeshTransport>
    private let careplansCareGoalApproval: Acme_Careplans_V1_CareGoalApprovalService.Client<MeshTransport>
    private let careplansCareGoalLifecycle: Acme_Careplans_V1_CareGoalLifecycleService.Client<MeshTransport>
    private let careplansCarePlanApproval: Acme_Careplans_V1_CarePlanApprovalService.Client<MeshTransport>
    private let careplansVitalCalculation: Acme_Careplans_V1_VitalCalculationService.Client<MeshTransport>
    private let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    private let identityUserValidation: Acme_Identity_V1_UserValidationService.Client<MeshTransport>
    private let ledgerLedgerAccountQuery: Acme_Ledger_V1_LedgerAccountQueryService.Client<MeshTransport>
    private let lendingLoanApplicationCalculation:
        Acme_Lending_V1_LoanApplicationCalculationService.Client<MeshTransport>
    private let metricsMetricSeries: Acme_Metrics_V1_MetricSeriesService.Client<MeshTransport>
    private let notificationsNotificationValidation:
        Acme_Notifications_V1_NotificationValidationService.Client<MeshTransport>
    private let patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>
    private let prescriptionsPrescription: Acme_Prescriptions_V1_PrescriptionService.Client<MeshTransport>
    private let searchSearchIndexQuery: Acme_Search_V1_SearchIndexQueryService.Client<MeshTransport>
    private let telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client<MeshTransport>
    private let telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client<MeshTransport>
    private let venuesVenueQuery: Acme_Venues_V1_VenueQueryService.Client<MeshTransport>
    private let retryCareGoalWorkflowStep0:
        any RPCPort<Acme_Notifications_V1_PreviewNotificationRequest, Acme_Notifications_V1_PreviewNotificationResponse>
    private let signalCareGoalWorkflowStep0:
        @Sendable (Acme_Ledger_V1_CountLedgerAccountsRequest) async throws -> Acme_Ledger_V1_CountLedgerAccountsResponse
    private let startCareGoalWorkflowStep0:
        [String:
            @Sendable (Acme_Careplans_V1_RecallCareGoalRequest) async throws -> Acme_Careplans_V1_RecallCareGoalResponse]

    init(
        dependencies: any Dependencies,
        appointmentsAppointment: Acme_Appointments_V1_AppointmentService.Client<MeshTransport>,
        authorizationAccessPolicyValidation: Acme_Authorization_V1_AccessPolicyValidationService.Client<MeshTransport>,
        careplansCareGoalApproval: Acme_Careplans_V1_CareGoalApprovalService.Client<MeshTransport>,
        careplansCareGoalLifecycle: Acme_Careplans_V1_CareGoalLifecycleService.Client<MeshTransport>,
        careplansCarePlanApproval: Acme_Careplans_V1_CarePlanApprovalService.Client<MeshTransport>,
        careplansVitalCalculation: Acme_Careplans_V1_VitalCalculationService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        identityUserValidation: Acme_Identity_V1_UserValidationService.Client<MeshTransport>,
        ledgerLedgerAccountQuery: Acme_Ledger_V1_LedgerAccountQueryService.Client<MeshTransport>,
        lendingLoanApplicationCalculation: Acme_Lending_V1_LoanApplicationCalculationService.Client<MeshTransport>,
        metricsMetricSeries: Acme_Metrics_V1_MetricSeriesService.Client<MeshTransport>,
        notificationsNotificationValidation: Acme_Notifications_V1_NotificationValidationService.Client<MeshTransport>,
        patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>,
        prescriptionsPrescription: Acme_Prescriptions_V1_PrescriptionService.Client<MeshTransport>,
        searchSearchIndexQuery: Acme_Search_V1_SearchIndexQueryService.Client<MeshTransport>,
        telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client<MeshTransport>,
        telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client<MeshTransport>,
        venuesVenueQuery: Acme_Venues_V1_VenueQueryService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.appointmentsAppointment = appointmentsAppointment
        self.authorizationAccessPolicyValidation = authorizationAccessPolicyValidation
        self.careplansCareGoalApproval = careplansCareGoalApproval
        self.careplansCareGoalLifecycle = careplansCareGoalLifecycle
        self.careplansCarePlanApproval = careplansCarePlanApproval
        self.careplansVitalCalculation = careplansVitalCalculation
        self.identityUser = identityUser
        self.identityUserValidation = identityUserValidation
        self.ledgerLedgerAccountQuery = ledgerLedgerAccountQuery
        self.lendingLoanApplicationCalculation = lendingLoanApplicationCalculation
        self.metricsMetricSeries = metricsMetricSeries
        self.notificationsNotificationValidation = notificationsNotificationValidation
        self.patientsMedicalRecordCalculation = patientsMedicalRecordCalculation
        self.prescriptionsPrescription = prescriptionsPrescription
        self.searchSearchIndexQuery = searchSearchIndexQuery
        self.telehealthVideoVisit = telehealthVideoVisit
        self.telehealthVideoVisitCalculation = telehealthVideoVisitCalculation
        self.venuesVenueQuery = venuesVenueQuery
        self.retryCareGoalWorkflowStep0 = ClosurePort<
            Acme_Notifications_V1_PreviewNotificationRequest, Acme_Notifications_V1_PreviewNotificationResponse
        >({ request in try await notificationsNotificationValidation.previewNotification(request) })
        self.signalCareGoalWorkflowStep0 = { request in try await ledgerLedgerAccountQuery.countLedgerAccounts(request)
        }
        self.startCareGoalWorkflowStep0 = [
            "primary": { request in try await careplansCareGoalApproval.recallCareGoal(request) }
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

    /// Advances a care goal.
    func advanceCareGoalWorkflow(
        request: ServerRequest<Acme_Careplans_V1_AdvanceCareGoalWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_AdvanceCareGoalWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processAdvanceCareGoalWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Cancels a care goal.
    func cancelCareGoalWorkflow(
        request: ServerRequest<Acme_Careplans_V1_CancelCareGoalWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_CancelCareGoalWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCancelCareGoalWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a care goal.
    func inspectCareGoalWorkflow(
        request: ServerRequest<Acme_Careplans_V1_InspectCareGoalWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_InspectCareGoalWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processInspectCareGoalWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists care goals a page at a time.
    func listCareGoalWorkflows(
        request: ServerRequest<Acme_Careplans_V1_ListCareGoalWorkflowsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_ListCareGoalWorkflowsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListCareGoalWorkflows(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Pauses a care goal.
    func pauseCareGoalWorkflow(
        request: ServerRequest<Acme_Careplans_V1_PauseCareGoalWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_PauseCareGoalWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processPauseCareGoalWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Resumes a care goal.
    func resumeCareGoalWorkflow(
        request: ServerRequest<Acme_Careplans_V1_ResumeCareGoalWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_ResumeCareGoalWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processResumeCareGoalWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Retrys a care goal.
    func retryCareGoalWorkflow(
        request: ServerRequest<Acme_Careplans_V1_RetryCareGoalWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_RetryCareGoalWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRetryCareGoalWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Signals a care goal.
    func signalCareGoalWorkflow(
        request: ServerRequest<Acme_Careplans_V1_SignalCareGoalWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_SignalCareGoalWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSignalCareGoalWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Starts a care goal.
    func startCareGoalWorkflow(
        request: ServerRequest<Acme_Careplans_V1_StartCareGoalWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_StartCareGoalWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processStartCareGoalWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processAdvanceCareGoalWorkflow(_ input: Acme_Careplans_V1_AdvanceCareGoalWorkflowRequest) async throws
        -> Acme_Careplans_V1_AdvanceCareGoalWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.careGoal.assignee.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "audit", detail: input.careGoal.assignee.displayName
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "AdvanceCareGoalWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CareGoalRecord(input.careGoal, tenant: input.context.tenantID)
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
        let requests0 = input.careGoal.comments.map { element in
            Acme_Patients_V1_QuoteMedicalRecordRequest.with {
                $0.context = input.context
                $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                    $0.audit = Acme_Common_V1_AuditInfo.with {
                        $0.createdAt = element.createdAt
                    }
                }
            }
        }
        let replies0 = try await FanOut.map(requests0) { candidate in
            try await self.patientsMedicalRecordCalculation.quoteMedicalRecord(candidate)
        }
        let reply0 = replies0.first ?? Acme_Patients_V1_QuoteMedicalRecordResponse()
        let selection1_4: String
        switch input.careGoal.origin {
        case .customer(let customer):
            selection1_4 = customer.displayName
        default: selection1_4 = .init()
        }
        let outbound1 = Acme_Telehealth_V1_ExplainVideoVisitCalculationRequest.with {
            $0.context = input.context
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.displayName = selection1_4
                    $0.email = input.details.notify.email
                }
                $0.participants = [
                    Acme_Telehealth_V1_VideoVisitParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = reply0.medicalRecord.counterparty.email
                            $0.phone = input.details.notify.phone
                        }
                    }
                ]
            }
        }
        let reply1 = try await self.telehealthVideoVisitCalculation.explainVideoVisitCalculation(outbound1)
        return Acme_Careplans_V1_AdvanceCareGoalWorkflowResponse.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.careGoalID = input.careGoalID
                $0.comments = [
                    Acme_Careplans_V1_CareGoalComment.with {
                        $0.createdAt = reply1.videoVisit.audit.createdAt
                    }
                ]
                $0.customFields = input.careGoal.customFields
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply1.videoVisit.organizer.email
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processCancelCareGoalWorkflow(_ input: Acme_Careplans_V1_CancelCareGoalWorkflowRequest) async throws
        -> Acme_Careplans_V1_CancelCareGoalWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.careGoal.assignee.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "audit", detail: input.careGoal.assignee.displayName
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "CancelCareGoalWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CareGoalRecord(input.careGoal, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Venues_V1_FindVenuesRequest.with {
            $0.context = Projection.read(input, at: \Acme_Careplans_V1_CancelCareGoalWorkflowRequest.context)
            $0.filter = Acme_Venues_V1_FindVenuesRequest.Filter.with {
                $0.createdAfter = Projection.read(
                    input, at: \Acme_Careplans_V1_CancelCareGoalWorkflowRequest.careGoal.audit.createdAt)
                $0.labels = input.careGoal.customFields
                $0.ownerID = Projection.read(
                    input, at: \Acme_Careplans_V1_CancelCareGoalWorkflowRequest.careGoal.sla.policyID)
            }
        }
        let reply0 = try await self.venuesVenueQuery.findVenues(outbound0)
        let outbound1 = Acme_Lending_V1_CalculateLoanApplicationRequest.with {
            $0.context = input.context
            $0.loanApplication = Acme_Lending_V1_LoanApplication.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = input.careGoal.audit.updatedAt
                }
                $0.counterparty = Acme_Customers_V1_CustomerRef.with {
                    $0.email = input.careGoal.requester.email
                }
            }
        }
        let step1: @Sendable () async throws -> Acme_Lending_V1_CalculateLoanApplicationResponse = {
            try await self.lendingLoanApplicationCalculation.calculateLoanApplication(outbound1)
        }
        let reply1 = try await step1()
        let requests2 = input.careGoal.comments.map { element in
            Acme_Identity_V1_ScoreUserRequest.with {
                $0.context = input.context
                $0.user = Acme_Identity_V1_User.with {
                    $0.audit = Acme_Common_V1_AuditInfo.with {
                        $0.createdAt = element.createdAt
                    }
                }
            }
        }
        let replies2 = try await FanOut.map(requests2) { candidate in
            try await self.identityUserValidation.scoreUser(candidate)
        }
        let reply2 = replies2.first ?? Acme_Identity_V1_ScoreUserResponse()
        _ = reply2
        var outbound3 = Acme_Careplans_V1_ApproveCarePlanRequest()
        outbound3.carePlan = Acme_Careplans_V1_CarePlan.with {
            $0.audit = Acme_Common_V1_AuditInfo.with {
                $0.updatedBy = reply1.loanApplication.audit.updatedBy
            }
        }
        outbound3.context = input.context
        let reply3 = try await self.careplansCarePlanApproval.approveCarePlan(outbound3)
        return Acme_Careplans_V1_CancelCareGoalWorkflowResponse.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.email = reply1.loanApplication.counterparty.email
                }
                $0.careGoalID = input.careGoalID
                $0.status = input.careGoal.status
            }
            $0.outcome = Acme_Careplans_V1_CancelCareGoalWorkflowResponse.Outcome.with {
                $0.status = reply3.outcome.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.result.message
                $0.referenceIds = reply0.result.referenceIds + reply1.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processInspectCareGoalWorkflow(_ input: Acme_Careplans_V1_InspectCareGoalWorkflowRequest) async throws
        -> Acme_Careplans_V1_InspectCareGoalWorkflowResponse
    {
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "InspectCareGoalWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "InspectCareGoalWorkflow", detail: input.context.traceID
        )
        let outbound0 = Acme_Telehealth_V1_UpdateVideoVisitRequest.with {
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
        let step0: @Sendable () async throws -> Acme_Telehealth_V1_UpdateVideoVisitResponse = {
            try await self.telehealthVideoVisit.updateVideoVisit(outbound0)
        }
        let reply0 = try await step0()
        return Acme_Careplans_V1_InspectCareGoalWorkflowResponse.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.careGoalID = input.careGoalID
                $0.comments = [
                    Acme_Careplans_V1_CareGoalComment.with {
                        $0.createdAt = reply0.videoVisit.audit.createdAt
                    }
                ]
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply0.result.status
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processListCareGoalWorkflows(_ input: Acme_Careplans_V1_ListCareGoalWorkflowsRequest) async throws
        -> Acme_Careplans_V1_ListCareGoalWorkflowsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "audit", detail: input.filter.ownerID
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ListCareGoalWorkflows",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "ListCareGoalWorkflows", detail: input.context.traceID
        )
        return Acme_Careplans_V1_ListCareGoalWorkflowsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processPauseCareGoalWorkflow(_ input: Acme_Careplans_V1_PauseCareGoalWorkflowRequest) async throws
        -> Acme_Careplans_V1_PauseCareGoalWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.careGoal.assignee.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "audit", detail: input.careGoal.assignee.displayName
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "PauseCareGoalWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CareGoalRecord(input.careGoal, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let selection0_1: String
        switch input.careGoal.origin {
        case .customer(let customer):
            selection0_1 = customer.email
        default: selection0_1 = .init()
        }
        let selection0_2: String
        switch input.careGoal.origin {
        case .customer(let customer):
            selection0_2 = customer.displayName
        default: selection0_2 = .init()
        }
        let outbound0 = Acme_Metrics_V1_UpdateMetricSeriesRequest.with {
            $0.context = input.context
            $0.metricSeries = Acme_Metrics_V1_MetricSeries.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = input.careGoal.audit.etag
                    $0.updatedAt = input.careGoal.audit.updatedAt
                }
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.displayName = selection0_2
                    $0.email = selection0_1
                }
            }
        }
        let reply0 = try await self.metricsMetricSeries.updateMetricSeries(outbound0)
        let outbound1 = Acme_Appointments_V1_UpdateAppointmentRequest.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.participants = [
                    Acme_Appointments_V1_AppointmentParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = input.careGoal.requester.email
                        }
                    }
                ]
            }
            $0.context = input.context
        }
        let reply1 = try await self.appointmentsAppointment.updateAppointment(outbound1)
        return Acme_Careplans_V1_PauseCareGoalWorkflowResponse.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.careGoalID = input.careGoalID
                $0.subject = input.careGoal.subject
                $0.tags = reply0.metricSeries.tags
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processResumeCareGoalWorkflow(_ input: Acme_Careplans_V1_ResumeCareGoalWorkflowRequest) async throws
        -> Acme_Careplans_V1_ResumeCareGoalWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.careGoal.assignee.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "audit", detail: input.careGoal.assignee.displayName
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ResumeCareGoalWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CareGoalRecord(input.careGoal, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Authorization_V1_PreviewAccessPolicyRequest.with {
            $0.accessPolicy = Acme_Authorization_V1_AccessPolicy.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = input.careGoal.audit.etag
                }
            }
            $0.context = input.context
        }
        async let remote0 = self.authorizationAccessPolicyValidation.previewAccessPolicy(outbound0)
        async let persisted0 = store.count(tenant: input.context.tenantID)
        let (reply0, count0) = try await (remote0, persisted0)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count0)])
        let requests1 = input.careGoal.history.map { element in
            Acme_Careplans_V1_EstimateVitalRequest.with {
                $0.context = input.context
                $0.reason = reply0.accessPolicy.block.reason
                $0.vital = Acme_Careplans_V1_Vital.with {
                    $0.occurredAt = element.changedAt
                }
            }
        }
        let replies1 = try await FanOut.map(requests1) { candidate in
            try await self.careplansVitalCalculation.estimateVital(candidate)
        }
        let reply1 = replies1.first ?? Acme_Careplans_V1_EstimateVitalResponse()
        _ = reply1
        return Acme_Careplans_V1_ResumeCareGoalWorkflowResponse.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.careGoalID = input.careGoalID
                $0.customFields = input.careGoal.customFields
                $0.priority = reply0.accessPolicy.priority
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processRetryCareGoalWorkflow(_ input: Acme_Careplans_V1_RetryCareGoalWorkflowRequest) async throws
        -> Acme_Careplans_V1_RetryCareGoalWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.careGoal.assignee.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "audit", detail: input.careGoal.assignee.displayName
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "RetryCareGoalWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CareGoalRecord(input.careGoal, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Notifications_V1_PreviewNotificationRequest.with {
            $0.context = input.context
            $0.details = Acme_Notifications_V1_PreviewNotificationRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.name = input.careGoal.requester.name
                }
            }
            $0.notification = Acme_Notifications_V1_Notification.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.email = input.details.notify.email
                }
            }
        }
        let reply0 = try await self.retryCareGoalWorkflowStep0.execute(outbound0)
        let outbound1 = Acme_Careplans_V1_RenewCareGoalRequest.with {
            $0.careGoalID = input.careGoalID
            $0.context = input.context
            $0.details = Acme_Careplans_V1_RenewCareGoalRequest.Details.with {
                $0.newOwner = Acme_Identity_V1_UserRef.with {
                    $0.email = input.careGoal.assignee.email
                }
                $0.notifyContact = Acme_Common_V1_ContactInfo.with {
                    $0.name = reply0.notification.requester.name
                }
            }
        }
        let port1 = RPCOperations.port { (request: Acme_Careplans_V1_RenewCareGoalRequest) in
            try await self.careplansCareGoalLifecycle.renewCareGoal(request)
        }
        let reply1 = try await port1.execute(outbound1)
        return Acme_Careplans_V1_RetryCareGoalWorkflowResponse.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.careGoalID = input.careGoalID
                $0.priority = reply1.careGoal.priority
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.name = reply0.notification.requester.name
                }
                $0.sla = Acme_Careplans_V1_CareGoalSla.with {
                    $0.pausedFor = reply0.notification.sla.pausedFor
                }
                $0.status = input.careGoal.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processSignalCareGoalWorkflow(_ input: Acme_Careplans_V1_SignalCareGoalWorkflowRequest) async throws
        -> Acme_Careplans_V1_SignalCareGoalWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.careGoal.assignee.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "audit", detail: input.careGoal.assignee.displayName
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "SignalCareGoalWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CareGoalRecord(input.careGoal, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Ledger_V1_CountLedgerAccountsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Ledger_V1_CountLedgerAccountsRequest.Filter.with {
                $0.createdAfter = input.careGoal.audit.createdAt
                $0.labels = input.careGoal.customFields
                $0.ownerID = input.careGoal.careGoalID
            }
        }
        let reply0 = try await self.signalCareGoalWorkflowStep0(outbound0)
        return Acme_Careplans_V1_SignalCareGoalWorkflowResponse.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.careGoalID = input.careGoalID
                $0.subject = input.careGoal.subject
            }
            $0.outcome = Acme_Careplans_V1_SignalCareGoalWorkflowResponse.Outcome.with {
                $0.status = reply0.result.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processStartCareGoalWorkflow(_ input: Acme_Careplans_V1_StartCareGoalWorkflowRequest) async throws
        -> Acme_Careplans_V1_StartCareGoalWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.careGoal.assignee.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "audit", detail: input.careGoal.assignee.displayName
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "StartCareGoalWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CareGoalRecord(input.careGoal, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Careplans_V1_RecallCareGoalRequest.with {
            $0.context = input.context
            $0.details = Acme_Careplans_V1_RecallCareGoalRequest.Details.with {
                $0.approver = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.careGoal.assignee.userID
                }
            }
        }
        guard
            let execute0 = self.startCareGoalWorkflowStep0[settings.region]
                ?? self.startCareGoalWorkflowStep0["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply0 = try await execute0(outbound0)
        let outbound1 = Acme_Search_V1_BrowseSearchIndexesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Search_V1_BrowseSearchIndexesRequest.Filter.with {
                $0.createdAfter = input.careGoal.sla.dueAt
                $0.labels = input.details.parameters
                $0.ownerID = reply0.careGoal.assignee.userID
            }
        }
        let reply1 = try await self.searchSearchIndexQuery.browseSearchIndexes(outbound1)
        return Acme_Careplans_V1_StartCareGoalWorkflowResponse.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.careGoalID = input.careGoalID
                $0.status = input.careGoal.status
                $0.subject = reply0.careGoal.subject
            }
            $0.outcome = Acme_Careplans_V1_StartCareGoalWorkflowResponse.Outcome.with {
                $0.message = reply1.result.message
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply1.result.referenceIds
                $0.status = "ok"
            }
        }
    }
}
