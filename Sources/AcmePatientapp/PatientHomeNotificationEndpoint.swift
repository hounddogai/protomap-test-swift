import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Tells the people who follow a patient home what changed.
final class PatientHomeNotificationEndpoint: Acme_Patientapp_V1_PatientHomeNotificationService.ServiceProtocol {
    private let store: any RecordRepository
    private let logger: Logger
    private let settings: Settings
    private let appointmentsClinicSlotWorkflow: Acme_Appointments_V1_ClinicSlotWorkflowService.Client<MeshTransport>
    private let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    private let notificationsNotificationQuery: Acme_Notifications_V1_NotificationQueryService.Client<MeshTransport>
    private let patientappCareInboxIntegration: Acme_Patientapp_V1_CareInboxIntegrationService.Client<MeshTransport>
    private let patientappCareInboxWorkflow: Acme_Patientapp_V1_CareInboxWorkflowService.Client<MeshTransport>
    private let patientappPatientHomeIntegration: Acme_Patientapp_V1_PatientHomeIntegrationService.Client<MeshTransport>
    private let patientappPatientHomeWorkflow: Acme_Patientapp_V1_PatientHomeWorkflowService.Client<MeshTransport>
    private let patientsAllergyImport: Acme_Patients_V1_AllergyImportService.Client<MeshTransport>
    private let patientsPatientApproval: Acme_Patients_V1_PatientApprovalService.Client<MeshTransport>
    private let patientsPatientSync: Acme_Patients_V1_PatientSyncService.Client<MeshTransport>
    private let patientsPatientWorkflow: Acme_Patients_V1_PatientWorkflowService.Client<MeshTransport>
    private let recruitingJobOpening: Acme_Recruiting_V1_JobOpeningService.Client<MeshTransport>
    private let searchSearchIndex: Acme_Search_V1_SearchIndexService.Client<MeshTransport>
    private let telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client<MeshTransport>
    private let telehealthVideoVisitWorkflow: Acme_Telehealth_V1_VideoVisitWorkflowService.Client<MeshTransport>
    private let notifyPatientHomeWatchersStep0:
        any RPCPort<Acme_Patientapp_V1_PauseCareInboxWorkflowRequest, Acme_Patientapp_V1_PauseCareInboxWorkflowResponse>
    private let sendPatientHomeTestNoticeStep0:
        @Sendable (Acme_Patients_V1_ValidateAllergyImportRequest) async throws ->
            Acme_Patients_V1_ValidateAllergyImportResponse
    private let sendPatientHomeTestNoticeStep1:
        [String:
            @Sendable (Acme_Patientapp_V1_ResumePatientHomeWorkflowRequest) async throws ->
            Acme_Patientapp_V1_ResumePatientHomeWorkflowResponse]

    init(
        dependencies: any Dependencies,
        appointmentsClinicSlotWorkflow: Acme_Appointments_V1_ClinicSlotWorkflowService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        notificationsNotificationQuery: Acme_Notifications_V1_NotificationQueryService.Client<MeshTransport>,
        patientappCareInboxIntegration: Acme_Patientapp_V1_CareInboxIntegrationService.Client<MeshTransport>,
        patientappCareInboxWorkflow: Acme_Patientapp_V1_CareInboxWorkflowService.Client<MeshTransport>,
        patientappPatientHomeIntegration: Acme_Patientapp_V1_PatientHomeIntegrationService.Client<MeshTransport>,
        patientappPatientHomeWorkflow: Acme_Patientapp_V1_PatientHomeWorkflowService.Client<MeshTransport>,
        patientsAllergyImport: Acme_Patients_V1_AllergyImportService.Client<MeshTransport>,
        patientsPatientApproval: Acme_Patients_V1_PatientApprovalService.Client<MeshTransport>,
        patientsPatientSync: Acme_Patients_V1_PatientSyncService.Client<MeshTransport>,
        patientsPatientWorkflow: Acme_Patients_V1_PatientWorkflowService.Client<MeshTransport>,
        recruitingJobOpening: Acme_Recruiting_V1_JobOpeningService.Client<MeshTransport>,
        searchSearchIndex: Acme_Search_V1_SearchIndexService.Client<MeshTransport>,
        telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client<MeshTransport>,
        telehealthVideoVisitWorkflow: Acme_Telehealth_V1_VideoVisitWorkflowService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.appointmentsClinicSlotWorkflow = appointmentsClinicSlotWorkflow
        self.identityUser = identityUser
        self.notificationsNotificationQuery = notificationsNotificationQuery
        self.patientappCareInboxIntegration = patientappCareInboxIntegration
        self.patientappCareInboxWorkflow = patientappCareInboxWorkflow
        self.patientappPatientHomeIntegration = patientappPatientHomeIntegration
        self.patientappPatientHomeWorkflow = patientappPatientHomeWorkflow
        self.patientsAllergyImport = patientsAllergyImport
        self.patientsPatientApproval = patientsPatientApproval
        self.patientsPatientSync = patientsPatientSync
        self.patientsPatientWorkflow = patientsPatientWorkflow
        self.recruitingJobOpening = recruitingJobOpening
        self.searchSearchIndex = searchSearchIndex
        self.telehealthVideoVisit = telehealthVideoVisit
        self.telehealthVideoVisitWorkflow = telehealthVideoVisitWorkflow
        self.notifyPatientHomeWatchersStep0 = ClosurePort<
            Acme_Patientapp_V1_PauseCareInboxWorkflowRequest, Acme_Patientapp_V1_PauseCareInboxWorkflowResponse
        >({ request in try await patientappCareInboxWorkflow.pauseCareInboxWorkflow(request) })
        self.sendPatientHomeTestNoticeStep0 = { request in
            try await patientsAllergyImport.validateAllergyImport(request)
        }
        self.sendPatientHomeTestNoticeStep1 = [
            "primary": { request in try await patientappPatientHomeWorkflow.resumePatientHomeWorkflow(request) }
        ]
    }

    /// Returns a patient home.
    func getPatientHomePreferences(
        request: ServerRequest<Acme_Patientapp_V1_GetPatientHomePreferencesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_GetPatientHomePreferencesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetPatientHomePreferences(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists patient homes a page at a time.
    func listPatientHomeSubscriptions(
        request: ServerRequest<Acme_Patientapp_V1_ListPatientHomeSubscriptionsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_ListPatientHomeSubscriptionsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListPatientHomeSubscriptions(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Notifys a patient home.
    func notifyPatientHomeWatchers(
        request: ServerRequest<Acme_Patientapp_V1_NotifyPatientHomeWatchersRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_NotifyPatientHomeWatchersResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processNotifyPatientHomeWatchers(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Sends a patient home.
    func sendPatientHomeTestNotice(
        request: ServerRequest<Acme_Patientapp_V1_SendPatientHomeTestNoticeRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_SendPatientHomeTestNoticeResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSendPatientHomeTestNotice(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Streams the changes of patient homes as they happen.
    func streamPatientHomeNotices(
        request: ServerRequest<Acme_Patientapp_V1_StreamPatientHomeNoticesRequest>,
        context: ServerContext
    ) async throws -> StreamingServerResponse<Acme_Patientapp_V1_StreamPatientHomeNoticesResponse> {
        return StreamingServerResponse { writer in
            try await CallerScope.$metadata.withValue(request.metadata) {
                let response = try await self.processStreamPatientHomeNotices(request.message)
                try await writer.write(response)
                return [:]
            }
        }
    }

    /// Subscribes a patient home.
    func subscribePatientHomeUpdates(
        request: ServerRequest<Acme_Patientapp_V1_SubscribePatientHomeUpdatesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_SubscribePatientHomeUpdatesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSubscribePatientHomeUpdates(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Unsubscribes a patient home.
    func unsubscribePatientHomeUpdates(
        request: ServerRequest<Acme_Patientapp_V1_UnsubscribePatientHomeUpdatesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_UnsubscribePatientHomeUpdatesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processUnsubscribePatientHomeUpdates(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processGetPatientHomePreferences(_ input: Acme_Patientapp_V1_GetPatientHomePreferencesRequest) async throws
        -> Acme_Patientapp_V1_GetPatientHomePreferencesResponse
    {
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "GetPatientHomePreferences",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "GetPatientHomePreferences", detail: input.context.traceID
        )
        let importFrame = Acme_Telehealth_V1_BatchCreateVideoVisitsRequest.with {
            $0.context = input.context
        }
        _ = try await self.telehealthVideoVisit.batchCreateVideoVisits { writer in
            try await writer.write(importFrame)
        }
        let outbound0 = Acme_Patientapp_V1_ReplayCareInboxEventsRequest.with {
            $0.annotations = input.context.baggage
            $0.context = input.context
            $0.details = Acme_Patientapp_V1_ReplayCareInboxEventsRequest.Details.with {
                $0.messageID = input.patientHomeID
                $0.receivedAt = input.context.deadline
            }
        }
        let step0: @Sendable () async throws -> Acme_Patientapp_V1_ReplayCareInboxEventsResponse = {
            try await self.patientappCareInboxIntegration.replayCareInboxEvents(outbound0)
        }
        let reply0 = try await step0()
        let outbound1 = Acme_Patientapp_V1_StartPatientHomeWorkflowRequest.with {
            $0.context = input.context
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply0.careInbox.counterparty.displayName
                }
                $0.customer = Acme_Patients_V1_PatientRef.with {
                    $0.patientID = reply0.careInbox.counterparty.patientID
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply0.careInbox.counterparty.email
                }
                $0.sla = Acme_Patientapp_V1_PatientHomeSla.with {
                    $0.dueAt = reply0.careInbox.dueAt
                }
            }
        }
        let reply1 = try await self.patientappPatientHomeWorkflow.startPatientHomeWorkflow(outbound1)
        return Acme_Patientapp_V1_GetPatientHomePreferencesResponse.with {
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.patientHomeID = reply1.patientHome.patientHomeID
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply1.patientHome.requester.email
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processListPatientHomeSubscriptions(_ input: Acme_Patientapp_V1_ListPatientHomeSubscriptionsRequest)
        async throws -> Acme_Patientapp_V1_ListPatientHomeSubscriptionsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "audit", detail: input.filter.ownerID
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ListPatientHomeSubscriptions",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "ListPatientHomeSubscriptions", detail: input.context.traceID
        )
        let outbound0 = Acme_Notifications_V1_SummarizeNotificationsRequest.with {
            $0.annotations = input.context.baggage
            $0.context = input.context
            $0.details = Acme_Notifications_V1_SummarizeNotificationsRequest.Details.with {
                $0.filters = input.filter.labels
            }
        }
        async let remote0 = self.notificationsNotificationQuery.summarizeNotifications(outbound0)
        async let persisted0 = store.count(tenant: input.context.tenantID)
        let (reply0, count0) = try await (remote0, persisted0)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count0)])
        return Acme_Patientapp_V1_ListPatientHomeSubscriptionsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.message = reply0.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processNotifyPatientHomeWatchers(_ input: Acme_Patientapp_V1_NotifyPatientHomeWatchersRequest) async throws
        -> Acme_Patientapp_V1_NotifyPatientHomeWatchersResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.channel)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "audit", detail: input.details.channel
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "NotifyPatientHomeWatchers",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "NotifyPatientHomeWatchers", detail: input.context.traceID
        )
        let outbound0 = Acme_Patientapp_V1_PauseCareInboxWorkflowRequest.with {
            $0.context = input.context
            $0.details = Acme_Patientapp_V1_PauseCareInboxWorkflowRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.recipient.email
                    $0.preferredChannel = input.details.recipient.preferredChannel
                }
            }
        }
        let reply0 = try await self.notifyPatientHomeWatchersStep0.execute(outbound0)
        let outbound1 = Acme_Telehealth_V1_ListVideoVisitWorkflowsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Telehealth_V1_ListVideoVisitWorkflowsRequest.Filter.with {
                $0.createdAfter = reply0.careInbox.audit.createdAt
                $0.region = reply0.careInbox.billingAddress.region
            }
        }
        let port1 = RPCOperations.port { (request: Acme_Telehealth_V1_ListVideoVisitWorkflowsRequest) in
            try await self.telehealthVideoVisitWorkflow.listVideoVisitWorkflows(request)
        }
        let reply1 = try await port1.execute(outbound1)
        return Acme_Patientapp_V1_NotifyPatientHomeWatchersResponse.with {
            $0.outcome = Acme_Patientapp_V1_NotifyPatientHomeWatchersResponse.Outcome.with {
                $0.status = reply1.result.status
            }
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.patientHomeID = input.patientHomeID
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.name = input.details.recipient.name
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.message = reply1.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processSendPatientHomeTestNotice(_ input: Acme_Patientapp_V1_SendPatientHomeTestNoticeRequest) async throws
        -> Acme_Patientapp_V1_SendPatientHomeTestNoticeResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.channel)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "audit", detail: input.details.channel
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "SendPatientHomeTestNotice",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "SendPatientHomeTestNotice", detail: input.context.traceID
        )
        let outbound0 = Acme_Patients_V1_ValidateAllergyImportRequest.with {
            $0.context = input.context
            $0.details = Acme_Patients_V1_ValidateAllergyImportRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.phone = input.details.recipient.phone
                    $0.preferredChannel = input.details.recipient.preferredChannel
                }
            }
        }
        let reply0 = try await self.sendPatientHomeTestNoticeStep0(outbound0)
        let outbound1 = Acme_Patientapp_V1_ResumePatientHomeWorkflowRequest.with {
            $0.context = input.context
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.customer = Acme_Patients_V1_PatientRef.with {
                    $0.patientID = reply0.allergy.subject.patientID
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.name = input.details.recipient.name
                }
            }
        }
        guard
            let execute1 = self.sendPatientHomeTestNoticeStep1[settings.region]
                ?? self.sendPatientHomeTestNoticeStep1["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply1 = try await execute1(outbound1)
        let selection2_3: String
        switch reply1.patientHome.origin {
        case .customer(let customer):
            selection2_3 = customer.email
        default: selection2_3 = .init()
        }
        let outbound2 = Acme_Patients_V1_ReconcilePatientsRequest.with {
            $0.context = input.context
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply1.patientHome.audit.createdAt
                }
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply1.patientHome.requester.email
                }
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.email = selection2_3
                }
            }
        }
        let reply2 = try await self.patientsPatientSync.reconcilePatients(outbound2)
        return Acme_Patientapp_V1_SendPatientHomeTestNoticeResponse.with {
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply2.patient.relationshipManager.displayName
                    $0.email = input.details.recipient.email
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply1.patientHome.audit.updatedBy
                }
                $0.comments = [
                    Acme_Patientapp_V1_PatientHomeComment.with {
                        $0.createdAt = reply2.patient.audit.createdAt
                    }
                ]
                $0.customFields = reply1.patientHome.customFields
                $0.patientHomeID = input.patientHomeID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.outcome.message
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processStreamPatientHomeNotices(_ input: Acme_Patientapp_V1_StreamPatientHomeNoticesRequest) async throws
        -> Acme_Patientapp_V1_StreamPatientHomeNoticesResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "audit", detail: input.filter.ownerID
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "StreamPatientHomeNotices",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "StreamPatientHomeNotices", detail: input.context.traceID
        )
        let outbound0 = Acme_Patientapp_V1_DisconnectPatientHomeSourceRequest.with {
            $0.context = input.context
            $0.details = Acme_Patientapp_V1_DisconnectPatientHomeSourceRequest.Details.with {
                $0.receivedAt = input.since
            }
        }
        let reply0 = try await self.patientappPatientHomeIntegration.disconnectPatientHomeSource(outbound0)
        let outbound1 = Acme_Patientapp_V1_TestCareInboxConnectionRequest.with {
            $0.context = input.context
            $0.details = Acme_Patientapp_V1_TestCareInboxConnectionRequest.Details.with {
                $0.messageID = reply0.outcome.message
            }
        }
        let envelope1 = try Google_Protobuf_Any(message: outbound1)
        let unpacked1 = try Acme_Patientapp_V1_TestCareInboxConnectionRequest(unpackingAny: envelope1)
        let reply1 = try await self.patientappCareInboxIntegration.testCareInboxConnection(unpacked1)
        let outbound2 = Acme_Patientapp_V1_ConnectCareInboxSourceRequest.with {
            $0.careInboxID = reply1.careInbox.careInboxID
            $0.context = input.context
            $0.details = Acme_Patientapp_V1_ConnectCareInboxSourceRequest.Details.with {
                $0.messageID = reply0.outcome.message
            }
        }
        let json2 = try outbound2.jsonString()
        let decoded2 = try Acme_Patientapp_V1_ConnectCareInboxSourceRequest(jsonString: json2)
        let reply2 = try await self.patientappCareInboxIntegration.connectCareInboxSource(decoded2)
        return Acme_Patientapp_V1_StreamPatientHomeNoticesResponse.with {
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply1.careInbox.counterparty.displayName
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply2.careInbox.audit.updatedAt
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply0.patientHome.requester.email
                    $0.phone = input.subscriber.phone
                    $0.preferredChannel = input.subscriber.preferredChannel
                }
                $0.status = reply0.patientHome.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply2.outcome.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processSubscribePatientHomeUpdates(_ input: Acme_Patientapp_V1_SubscribePatientHomeUpdatesRequest) async throws
        -> Acme_Patientapp_V1_SubscribePatientHomeUpdatesResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.channel)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "audit", detail: input.details.channel
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "SubscribePatientHomeUpdates",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "SubscribePatientHomeUpdates", detail: input.context.traceID
        )
        let outbound0 =
            Acme_Appointments_V1_AdvanceClinicSlotWorkflowRequest
            .forPatientHomeNotificationEndpointSubscribePatientHomeUpdates0(
                input
            )
        let reply0 = try await self.appointmentsClinicSlotWorkflow.advanceClinicSlotWorkflow(outbound0)
        let outbound1 = Acme_Patients_V1_ApprovePatientRequest.with {
            $0.context = input.context
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.lines = reply0.clinicSlot.location.lines
                }
            }
        }
        let reply1 = try await self.patientsPatientApproval.approvePatient(
            outbound1, metadata: ["x-acme-region": .string(settings.region)]
        )
        let outbound2 = Acme_Patientapp_V1_StartCareInboxWorkflowRequest.with {
            $0.careInbox = Acme_Patientapp_V1_CareInbox.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply1.patient.audit.updatedBy
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.lines = reply1.patient.primaryAddress.lines
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.email = input.details.recipient.email
                }
            }
            $0.context = input.context
            $0.details = Acme_Patientapp_V1_StartCareInboxWorkflowRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.preferredChannel = input.details.recipient.preferredChannel
                }
            }
        }
        let reply2 = try await RPCOperations.call(outbound2) { request in
            try await self.patientappCareInboxWorkflow.startCareInboxWorkflow(request)
        }
        let outbound3 = Acme_Search_V1_UpdateSearchIndexRequest.with {
            $0.context = Projection.read(input, at: \Acme_Patientapp_V1_SubscribePatientHomeUpdatesRequest.context)
            $0.searchIndex = Acme_Search_V1_SearchIndex.with {
                $0.address = Acme_Common_V1_PostalAddress.with {
                    $0.recipient = Projection.read(
                        reply2,
                        at: \Acme_Patientapp_V1_StartCareInboxWorkflowResponse.careInbox.billingAddress.recipient)
                    $0.region = Projection.read(
                        reply1, at: \Acme_Patients_V1_ApprovePatientResponse.patient.primaryAddress.region)
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = Projection.read(
                        reply1, at: \Acme_Patients_V1_ApprovePatientResponse.patient.audit.createdBy)
                    $0.etag = Projection.read(
                        reply2, at: \Acme_Patientapp_V1_StartCareInboxWorkflowResponse.careInbox.audit.etag)
                }
            }
        }
        let reply3 = try await self.searchSearchIndex.updateSearchIndex(outbound3)
        return Acme_Patientapp_V1_SubscribePatientHomeUpdatesResponse.with {
            $0.outcome = Acme_Patientapp_V1_SubscribePatientHomeUpdatesResponse.Outcome.with {
                $0.effectiveAt = reply0.outcome.effectiveAt
            }
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply3.searchIndex.owner.displayName
                    $0.email = input.details.recipient.email
                }
                $0.comments = [
                    Acme_Patientapp_V1_PatientHomeComment.with {
                        $0.createdAt = reply0.clinicSlot.audit.createdAt
                    }
                ]
                $0.patientHomeID = input.patientHomeID
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply1.patient.contact.email
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply1.result.referenceIds + reply2.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processUnsubscribePatientHomeUpdates(_ input: Acme_Patientapp_V1_UnsubscribePatientHomeUpdatesRequest)
        async throws -> Acme_Patientapp_V1_UnsubscribePatientHomeUpdatesResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.channel)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "audit", detail: input.details.channel
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "UnsubscribePatientHomeUpdates",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "UnsubscribePatientHomeUpdates", detail: input.context.traceID
        )
        let outbound0 = Acme_Patientapp_V1_PausePatientHomeWorkflowRequest.with {
            $0.context = input.context
            $0.details = Acme_Patientapp_V1_PausePatientHomeWorkflowRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.recipient.email
                    $0.phone = input.details.recipient.phone
                }
            }
        }
        let step0: @Sendable () async throws -> Acme_Patientapp_V1_PausePatientHomeWorkflowResponse = {
            try await self.patientappPatientHomeWorkflow.pausePatientHomeWorkflow(outbound0)
        }
        let reply0 = try await step0()
        var outbound1 = Acme_Patients_V1_AdvancePatientWorkflowRequest()
        outbound1.context = input.context
        outbound1.patient = Acme_Patients_V1_Patient.with {
            $0.contact = Acme_Common_V1_ContactInfo.with {
                $0.phone = input.details.recipient.phone
            }
        }
        let reply1 = try await self.patientsPatientWorkflow.advancePatientWorkflow(outbound1)
        let outbound2 = Acme_Recruiting_V1_ListJobOpeningsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Recruiting_V1_ListJobOpeningsRequest.Filter.with {
                $0.region = reply1.patient.primaryAddress.region
            }
        }
        let reply2 = try await RPCOperations.read {
            try await self.recruitingJobOpening.listJobOpenings(outbound2)
        }
        return Acme_Patientapp_V1_UnsubscribePatientHomeUpdatesResponse.with {
            $0.outcome = Acme_Patientapp_V1_UnsubscribePatientHomeUpdatesResponse.Outcome.with {
                $0.message = Projection.firstValue(
                    [
                        reply1.result.message,
                        reply2.result.message,
                    ], default: .init())
                $0.nextSteps = reply0.outcome.nextSteps
                $0.referenceID = reply0.outcome.referenceID
            }
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.patientHomeID = input.patientHomeID
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.preferredChannel = input.details.recipient.preferredChannel
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply2.result.correlationID
                $0.status = "ok"
            }
        }
    }
}
