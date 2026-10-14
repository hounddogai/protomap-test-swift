import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Tells the people who follow a care inbox what changed.
final class CareInboxNotificationEndpoint: Acme_Patientapp_V1_CareInboxNotificationService.ServiceProtocol {
    private let store: any RecordRepository
    private let logger: Logger
    private let settings: Settings
    private let auditAuditEventQuery: Acme_Audit_V1_AuditEventQueryService.Client<MeshTransport>
    private let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    private let metricsMetricSeries: Acme_Metrics_V1_MetricSeriesService.Client<MeshTransport>
    private let notificationsNotification: Acme_Notifications_V1_NotificationService.Client<MeshTransport>
    private let patientappCareInboxIntegration: Acme_Patientapp_V1_CareInboxIntegrationService.Client<MeshTransport>
    private let patientappCareInboxWorkflow: Acme_Patientapp_V1_CareInboxWorkflowService.Client<MeshTransport>
    private let patientappPatientHomeIntegration: Acme_Patientapp_V1_PatientHomeIntegrationService.Client<MeshTransport>
    private let patientappPatientHomeNotification:
        Acme_Patientapp_V1_PatientHomeNotificationService.Client<MeshTransport>
    private let patientsMedicalRecordWorkflow: Acme_Patients_V1_MedicalRecordWorkflowService.Client<MeshTransport>
    private let patientsPatientSync: Acme_Patients_V1_PatientSyncService.Client<MeshTransport>
    private let patientsPatientWorkflow: Acme_Patients_V1_PatientWorkflowService.Client<MeshTransport>
    private let prescriptionsPrescriptionWorkflow:
        Acme_Prescriptions_V1_PrescriptionWorkflowService.Client<MeshTransport>
    private let searchSearchIndexValidation: Acme_Search_V1_SearchIndexValidationService.Client<MeshTransport>
    private let ticketingTicket: Acme_Ticketing_V1_TicketService.Client<MeshTransport>
    private let notifyCareInboxWatchersStep1:
        any RPCPort<
            Acme_Prescriptions_V1_RetryPrescriptionWorkflowRequest,
            Acme_Prescriptions_V1_RetryPrescriptionWorkflowResponse
        >
    private let sendCareInboxTestNoticeStep1:
        @Sendable (Acme_Search_V1_PreviewSearchIndexRequest) async throws -> Acme_Search_V1_PreviewSearchIndexResponse
    private let sendCareInboxTestNoticeStep2:
        [String:
            @Sendable (Acme_Patients_V1_SignalPatientWorkflowRequest) async throws ->
            Acme_Patients_V1_SignalPatientWorkflowResponse]

    init(
        dependencies: any Dependencies,
        auditAuditEventQuery: Acme_Audit_V1_AuditEventQueryService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        metricsMetricSeries: Acme_Metrics_V1_MetricSeriesService.Client<MeshTransport>,
        notificationsNotification: Acme_Notifications_V1_NotificationService.Client<MeshTransport>,
        patientappCareInboxIntegration: Acme_Patientapp_V1_CareInboxIntegrationService.Client<MeshTransport>,
        patientappCareInboxWorkflow: Acme_Patientapp_V1_CareInboxWorkflowService.Client<MeshTransport>,
        patientappPatientHomeIntegration: Acme_Patientapp_V1_PatientHomeIntegrationService.Client<MeshTransport>,
        patientappPatientHomeNotification: Acme_Patientapp_V1_PatientHomeNotificationService.Client<MeshTransport>,
        patientsMedicalRecordWorkflow: Acme_Patients_V1_MedicalRecordWorkflowService.Client<MeshTransport>,
        patientsPatientSync: Acme_Patients_V1_PatientSyncService.Client<MeshTransport>,
        patientsPatientWorkflow: Acme_Patients_V1_PatientWorkflowService.Client<MeshTransport>,
        prescriptionsPrescriptionWorkflow: Acme_Prescriptions_V1_PrescriptionWorkflowService.Client<MeshTransport>,
        searchSearchIndexValidation: Acme_Search_V1_SearchIndexValidationService.Client<MeshTransport>,
        ticketingTicket: Acme_Ticketing_V1_TicketService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.auditAuditEventQuery = auditAuditEventQuery
        self.identityUser = identityUser
        self.metricsMetricSeries = metricsMetricSeries
        self.notificationsNotification = notificationsNotification
        self.patientappCareInboxIntegration = patientappCareInboxIntegration
        self.patientappCareInboxWorkflow = patientappCareInboxWorkflow
        self.patientappPatientHomeIntegration = patientappPatientHomeIntegration
        self.patientappPatientHomeNotification = patientappPatientHomeNotification
        self.patientsMedicalRecordWorkflow = patientsMedicalRecordWorkflow
        self.patientsPatientSync = patientsPatientSync
        self.patientsPatientWorkflow = patientsPatientWorkflow
        self.prescriptionsPrescriptionWorkflow = prescriptionsPrescriptionWorkflow
        self.searchSearchIndexValidation = searchSearchIndexValidation
        self.ticketingTicket = ticketingTicket
        self.notifyCareInboxWatchersStep1 = ClosurePort<
            Acme_Prescriptions_V1_RetryPrescriptionWorkflowRequest,
            Acme_Prescriptions_V1_RetryPrescriptionWorkflowResponse
        >({ request in try await prescriptionsPrescriptionWorkflow.retryPrescriptionWorkflow(request) })
        self.sendCareInboxTestNoticeStep1 = { request in
            try await searchSearchIndexValidation.previewSearchIndex(request)
        }
        self.sendCareInboxTestNoticeStep2 = [
            "primary": { request in try await patientsPatientWorkflow.signalPatientWorkflow(request) }
        ]
    }

    /// Returns a care inbox.
    func getCareInboxPreferences(
        request: ServerRequest<Acme_Patientapp_V1_GetCareInboxPreferencesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_GetCareInboxPreferencesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetCareInboxPreferences(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists care inboxes a page at a time.
    func listCareInboxSubscriptions(
        request: ServerRequest<Acme_Patientapp_V1_ListCareInboxSubscriptionsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_ListCareInboxSubscriptionsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListCareInboxSubscriptions(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Notifys a care inbox.
    func notifyCareInboxWatchers(
        request: ServerRequest<Acme_Patientapp_V1_NotifyCareInboxWatchersRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_NotifyCareInboxWatchersResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processNotifyCareInboxWatchers(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Sends a care inbox.
    func sendCareInboxTestNotice(
        request: ServerRequest<Acme_Patientapp_V1_SendCareInboxTestNoticeRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_SendCareInboxTestNoticeResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSendCareInboxTestNotice(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Streams the changes of care inboxes as they happen.
    func streamCareInboxNotices(
        request: ServerRequest<Acme_Patientapp_V1_StreamCareInboxNoticesRequest>,
        context: ServerContext
    ) async throws -> StreamingServerResponse<Acme_Patientapp_V1_StreamCareInboxNoticesResponse> {
        return StreamingServerResponse { writer in
            try await CallerScope.$metadata.withValue(request.metadata) {
                let response = try await self.processStreamCareInboxNotices(request.message)
                try await writer.write(response)
                return [:]
            }
        }
    }

    /// Subscribes a care inbox.
    func subscribeCareInboxUpdates(
        request: ServerRequest<Acme_Patientapp_V1_SubscribeCareInboxUpdatesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_SubscribeCareInboxUpdatesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSubscribeCareInboxUpdates(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Unsubscribes a care inbox.
    func unsubscribeCareInboxUpdates(
        request: ServerRequest<Acme_Patientapp_V1_UnsubscribeCareInboxUpdatesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_UnsubscribeCareInboxUpdatesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processUnsubscribeCareInboxUpdates(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processGetCareInboxPreferences(_ input: Acme_Patientapp_V1_GetCareInboxPreferencesRequest) async throws
        -> Acme_Patientapp_V1_GetCareInboxPreferencesResponse
    {
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "GetCareInboxPreferences",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "GetCareInboxPreferences", detail: input.context.traceID
        )
        let importFrame = Acme_Patientapp_V1_IngestCareInboxEventsRequest.with {
            $0.context = input.context
        }
        _ = try await self.patientappCareInboxIntegration.ingestCareInboxEvents { writer in
            try await writer.write(importFrame)
        }
        let outbound0 = Acme_Metrics_V1_WatchMetricSeriesesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Metrics_V1_WatchMetricSeriesesRequest.Filter.with {
                $0.createdAfter = input.context.deadline
                $0.ownerID = input.careInboxID
            }
            $0.subscriber = Acme_Common_V1_ContactInfo.with {
                $0.email = input.context.actor.email
            }
        }
        let reply0 = try await self.metricsMetricSeries.watchMetricSerieses(outbound0) { response in
            var latest = Acme_Metrics_V1_WatchMetricSeriesesResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        _ = reply0
        return Acme_Patientapp_V1_GetCareInboxPreferencesResponse.with {
            $0.careInbox = Acme_Patientapp_V1_CareInbox.with {
                $0.careInboxID = input.careInboxID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processListCareInboxSubscriptions(_ input: Acme_Patientapp_V1_ListCareInboxSubscriptionsRequest) async throws
        -> Acme_Patientapp_V1_ListCareInboxSubscriptionsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "audit", detail: input.filter.ownerID
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ListCareInboxSubscriptions",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "ListCareInboxSubscriptions", detail: input.context.traceID
        )
        return Acme_Patientapp_V1_ListCareInboxSubscriptionsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processNotifyCareInboxWatchers(_ input: Acme_Patientapp_V1_NotifyCareInboxWatchersRequest) async throws
        -> Acme_Patientapp_V1_NotifyCareInboxWatchersResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.channel)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "audit", detail: input.details.channel
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "NotifyCareInboxWatchers",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "NotifyCareInboxWatchers", detail: input.context.traceID
        )
        let outbound0 = Acme_Patientapp_V1_CancelCareInboxWorkflowRequest.with {
            $0.context = input.context
            $0.details = Acme_Patientapp_V1_CancelCareInboxWorkflowRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.recipient.email
                }
            }
        }
        async let remote0 = self.patientappCareInboxWorkflow.cancelCareInboxWorkflow(outbound0)
        async let persisted0 = store.count(tenant: input.context.tenantID)
        let (reply0, count0) = try await (remote0, persisted0)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count0)])
        let outbound1 = Acme_Prescriptions_V1_RetryPrescriptionWorkflowRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_RetryPrescriptionWorkflowRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.recipient.email
                }
            }
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.locality = reply0.careInbox.billingAddress.locality
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.email = reply0.careInbox.counterparty.email
                }
            }
        }
        let reply1 = try await self.notifyCareInboxWatchersStep1.execute(outbound1)
        let selection2_2: String
        switch reply0.careInbox.settlement {
        case .card(let card):
            selection2_2 = card.holderName
        default: selection2_2 = .init()
        }
        let outbound2 = Acme_Ticketing_V1_UpdateTicketRequest.with {
            $0.context = input.context
            $0.ticket = Acme_Ticketing_V1_Ticket.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply1.prescription.audit.updatedAt
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.locality = reply0.careInbox.billingAddress.locality
                }
                $0.card = Acme_Ticketing_V1_TicketCardSettlement.with {
                    $0.holderName = selection2_2
                }
                $0.counterparty = Acme_Venues_V1_VenueRef.with {
                    $0.displayName = reply1.prescription.counterparty.displayName
                }
            }
        }
        let reply2 = try await self.ticketingTicket.updateTicket(outbound2)
        return Acme_Patientapp_V1_NotifyCareInboxWatchersResponse.with {
            $0.careInbox = Acme_Patientapp_V1_CareInbox.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply1.prescription.audit.updatedBy
                }
                $0.careInboxID = input.careInboxID
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = reply0.careInbox.counterparty.displayName
                    $0.email = input.details.recipient.email
                }
            }
            $0.outcome = Acme_Patientapp_V1_NotifyCareInboxWatchersResponse.Outcome.with {
                $0.message = Projection.firstValue(
                    [
                        reply0.result.message,
                        reply1.result.message,
                        reply2.result.message,
                    ], default: .init())
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processSendCareInboxTestNotice(_ input: Acme_Patientapp_V1_SendCareInboxTestNoticeRequest) async throws
        -> Acme_Patientapp_V1_SendCareInboxTestNoticeResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.channel)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "audit", detail: input.details.channel
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "SendCareInboxTestNotice",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "SendCareInboxTestNotice", detail: input.context.traceID
        )
        let outbound0 = Acme_Patientapp_V1_DisconnectCareInboxSourceRequest.with {
            $0.annotations = input.annotations
            $0.careInboxID = input.careInboxID
            $0.context = input.context
            $0.details = Acme_Patientapp_V1_DisconnectCareInboxSourceRequest.Details.with {
                $0.messageID = input.details.templateID
            }
            $0.reason = input.reason
        }
        let port0 = RPCOperations.port { (request: Acme_Patientapp_V1_DisconnectCareInboxSourceRequest) in
            try await self.patientappCareInboxIntegration.disconnectCareInboxSource(request)
        }
        let reply0 = try await port0.execute(outbound0)
        let outbound1 = Acme_Search_V1_PreviewSearchIndexRequest.with {
            $0.context = input.context
            $0.searchIndex = Acme_Search_V1_SearchIndex.with {
                $0.address = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = reply0.careInbox.billingAddress.countryCode
                    $0.lines = reply0.careInbox.billingAddress.lines
                    $0.recipient = reply0.careInbox.billingAddress.recipient
                }
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.email = input.details.recipient.email
                }
            }
        }
        let reply1 = try await self.sendCareInboxTestNoticeStep1(outbound1)
        let outbound2 = Acme_Patients_V1_SignalPatientWorkflowRequest.with {
            $0.context = input.context
            $0.details = Acme_Patients_V1_SignalPatientWorkflowRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply1.searchIndex.owner.email
                }
            }
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply1.searchIndex.audit.updatedBy
                }
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.phone = input.details.recipient.phone
                }
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = reply0.careInbox.billingAddress.postalCode
                }
            }
        }
        guard
            let execute2 = self.sendCareInboxTestNoticeStep2[settings.region]
                ?? self.sendCareInboxTestNoticeStep2["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply2 = try await execute2(outbound2)
        let outbound3 = Acme_Patientapp_V1_SubscribePatientHomeUpdatesRequest.with {
            $0.context = input.context
            $0.details = Acme_Patientapp_V1_SubscribePatientHomeUpdatesRequest.Details.with {
                $0.recipient = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply2.patient.relationshipManager.email
                    $0.name = reply2.patient.contact.name
                    $0.preferredChannel = input.details.recipient.preferredChannel
                }
                $0.templateID = input.details.templateID
            }
        }
        let reply3 = try await self.patientappPatientHomeNotification.subscribePatientHomeUpdates(outbound3)
        return Acme_Patientapp_V1_SendCareInboxTestNoticeResponse.with {
            $0.careInbox = Acme_Patientapp_V1_CareInbox.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = reply2.patient.primaryAddress.postalCode
                }
                $0.careInboxID = input.careInboxID
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.email = reply3.patientHome.requester.email
                }
            }
            $0.outcome = Acme_Patientapp_V1_SendCareInboxTestNoticeResponse.Outcome.with {
                $0.nextSteps = reply1.outcome.nextSteps
                $0.status = reply2.outcome.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.details = reply0.result.details
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processStreamCareInboxNotices(_ input: Acme_Patientapp_V1_StreamCareInboxNoticesRequest) async throws
        -> Acme_Patientapp_V1_StreamCareInboxNoticesResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "audit", detail: input.filter.ownerID
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "StreamCareInboxNotices",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "StreamCareInboxNotices", detail: input.context.traceID
        )
        let outbound0 = Acme_Patientapp_V1_ListCareInboxWorkflowsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Patientapp_V1_ListCareInboxWorkflowsRequest.Filter.with {
                $0.labels = input.filter.labels
                $0.region = input.filter.region
                $0.statuses = input.filter.statuses
            }
        }
        let envelope0 = try Google_Protobuf_Any(message: outbound0)
        let unpacked0 = try Acme_Patientapp_V1_ListCareInboxWorkflowsRequest(unpackingAny: envelope0)
        let reply0 = try await self.patientappCareInboxWorkflow.listCareInboxWorkflows(unpacked0)
        let outbound1 = Acme_Patientapp_V1_DisconnectCareInboxSourceRequest.with {
            $0.annotations = reply0.result.details
            $0.context = input.context
            $0.details = Acme_Patientapp_V1_DisconnectCareInboxSourceRequest.Details.with {
                $0.messageID = reply0.result.message
                $0.receivedAt = input.filter.createdAfter
            }
        }
        let json1 = try outbound1.jsonString()
        let decoded1 = try Acme_Patientapp_V1_DisconnectCareInboxSourceRequest(jsonString: json1)
        let reply1 = try await self.patientappCareInboxIntegration.disconnectCareInboxSource(decoded1)
        return Acme_Patientapp_V1_StreamCareInboxNoticesResponse.with {
            $0.careInbox = Acme_Patientapp_V1_CareInbox.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply1.careInbox.audit.createdAt
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.email = input.subscriber.email
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.result.message
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processSubscribeCareInboxUpdates(_ input: Acme_Patientapp_V1_SubscribeCareInboxUpdatesRequest) async throws
        -> Acme_Patientapp_V1_SubscribeCareInboxUpdatesResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.channel)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "audit", detail: input.details.channel
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "SubscribeCareInboxUpdates",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "SubscribeCareInboxUpdates", detail: input.context.traceID
        )
        let outbound0 = Acme_Patients_V1_StreamPatientChangesRequest.with {
            $0.change = Acme_Patients_V1_Patient.with {
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.email = input.details.recipient.email
                }
            }
            $0.context = input.context
        }
        let reply0 = try await self.patientsPatientSync.streamPatientChanges { writer in
            try await writer.write(outbound0)
        } onResponse: { response in
            var latest = Acme_Patients_V1_StreamPatientChangesResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        _ = reply0
        let outbound1 =
            Acme_Patients_V1_ListMedicalRecordWorkflowsRequest
            .forCareInboxNotificationEndpointSubscribeCareInboxUpdates1(
                input
            )
        let reply1 = try await self.patientsMedicalRecordWorkflow.listMedicalRecordWorkflows(outbound1)
        let outbound2 = Acme_Patientapp_V1_AcknowledgePatientHomeEventRequest.with {
            $0.annotations = input.annotations
            $0.context = input.context
            $0.reason = input.reason
        }
        let reply2 = try await self.patientappPatientHomeIntegration.acknowledgePatientHomeEvent(
            outbound2, metadata: ["x-acme-region": .string(settings.region)]
        )
        return Acme_Patientapp_V1_SubscribeCareInboxUpdatesResponse.with {
            $0.careInbox = Acme_Patientapp_V1_CareInbox.with {
                $0.careInboxID = input.careInboxID
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.email = input.details.recipient.email
                }
            }
            $0.outcome = Acme_Patientapp_V1_SubscribeCareInboxUpdatesResponse.Outcome.with {
                $0.message = reply2.outcome.message
                $0.status = reply1.result.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply1.result.details
                $0.status = reply2.outcome.status
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processUnsubscribeCareInboxUpdates(_ input: Acme_Patientapp_V1_UnsubscribeCareInboxUpdatesRequest) async throws
        -> Acme_Patientapp_V1_UnsubscribeCareInboxUpdatesResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.channel)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "audit", detail: input.details.channel
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "UnsubscribeCareInboxUpdates",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "UnsubscribeCareInboxUpdates", detail: input.context.traceID
        )
        let outbound0 = Acme_Notifications_V1_SearchNotificationsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Notifications_V1_SearchNotificationsRequest.Filter.with {
                $0.labels = input.details.variables
                $0.ownerID = input.details.templateID
            }
        }
        let reply0 = try await RPCOperations.call(outbound0) { request in
            try await self.notificationsNotification.searchNotifications(request)
        }
        let outbound1 = Acme_Audit_V1_CountAuditEventsRequest.with {
            $0.context = Projection.read(input, at: \Acme_Patientapp_V1_UnsubscribeCareInboxUpdatesRequest.context)
            $0.filter = Acme_Audit_V1_CountAuditEventsRequest.Filter.with {
                $0.createdAfter = Projection.read(
                    input, at: \Acme_Patientapp_V1_UnsubscribeCareInboxUpdatesRequest.context.deadline)
                $0.labels = reply0.result.details
                $0.ownerID = Projection.read(
                    reply0, at: \Acme_Notifications_V1_SearchNotificationsResponse.result.correlationID)
            }
        }
        let reply1 = try await self.auditAuditEventQuery.countAuditEvents(outbound1)
        let outbound2 = Acme_Patientapp_V1_TestCareInboxConnectionRequest.with {
            $0.annotations = input.annotations
            $0.context = input.context
        }
        let step2: @Sendable () async throws -> Acme_Patientapp_V1_TestCareInboxConnectionResponse = {
            try await self.patientappCareInboxIntegration.testCareInboxConnection(outbound2)
        }
        let reply2 = try await step2()
        return Acme_Patientapp_V1_UnsubscribeCareInboxUpdatesResponse.with {
            $0.careInbox = Acme_Patientapp_V1_CareInbox.with {
                $0.careInboxID = input.careInboxID
                $0.counterparty = reply2.careInbox.counterparty
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.details = reply2.result.details
                $0.message = reply0.result.message
                $0.referenceIds = reply1.result.referenceIds
                $0.status = "ok"
            }
        }
    }
}
