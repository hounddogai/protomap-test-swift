import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension PatientHomeGatewayEndpoint {
    /// Execute the patientapp workflow and project its upstream replies.
    func processComposePatientHomePage(_ input: Acme_Patientapp_V1_ComposePatientHomePageRequest) async throws
        -> Acme_Patientapp_V1_ComposePatientHomePageResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.device)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "audit", detail: input.details.device
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ComposePatientHomePage",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PatientHomeRecord(input.patientHome, tenant: input.context.tenantID)
        try await store.save(record.stored)
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        let importFrame = Acme_Patientapp_V1_RelayPatientHomeMessagesRequest.with {
            $0.context = input.context
        }
        _ = try await self.patientappPatientHomeIntegration.relayPatientHomeMessages { writer in
            try await writer.write(importFrame)
        } onResponse: { response in
            var latest = Acme_Patientapp_V1_RelayPatientHomeMessagesResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        let selection0_2: String
        switch input.patientHome.origin {
        case .customer(let customer):
            selection0_2 = customer.patientID
        default: selection0_2 = .init()
        }
        let outbound0 = Acme_Patientapp_V1_FindCareInboxesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Patientapp_V1_FindCareInboxesRequest.Filter.with {
                $0.createdAfter = input.patientHome.sla.dueAt
                $0.labels = input.details.clientHints
                $0.ownerID = selection0_2
            }
        }
        let reply0 = try await self.patientappCareInboxQuery.findCareInboxes(outbound0)
        let selection1_1: String
        switch input.patientHome.origin {
        case .customer(let customer):
            selection1_1 = customer.email
        default: selection1_1 = .init()
        }
        let outbound1 = Acme_Patientapp_V1_RetryPatientHomeWorkflowRequest.with {
            $0.context = input.context
            $0.details = Acme_Patientapp_V1_RetryPatientHomeWorkflowRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.email = selection1_1
                }
            }
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.name = input.patientHome.requester.name
                    $0.preferredChannel = input.patientHome.requester.preferredChannel
                }
                $0.sla = Acme_Patientapp_V1_PatientHomeSla.with {
                    $0.breached = input.patientHome.sla.breached
                }
            }
        }
        let reply1 = try await self.patientappPatientHomeWorkflow.retryPatientHomeWorkflow(outbound1)
        let outbound2 =
            Acme_Patients_V1_RetryAllergyWorkflowRequest.forPatientHomeGatewayEndpointComposePatientHomePage2(
                input,
                reply1: reply1
            )
        let reply2 = try await self.patientsAllergyWorkflow.retryAllergyWorkflow(outbound2)
        return Acme_Patientapp_V1_ComposePatientHomePageResponse.with {
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.email = reply2.allergy.subject.email
                }
                $0.patientHomeID = input.patientHomeID
                $0.subject = input.patientHome.subject
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.details = reply0.result.details
                $0.message = reply1.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processFetchPatientHomeView(_ input: Acme_Patientapp_V1_FetchPatientHomeViewRequest) async throws
        -> Acme_Patientapp_V1_FetchPatientHomeViewResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.device)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "audit", detail: input.details.device
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "FetchPatientHomeView",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PatientHomeRecord(input.patientHome, tenant: input.context.tenantID)
        try await store.save(record.stored)
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        let outbound0 = Acme_Patientapp_V1_StartPatientHomeWorkflowRequest.with {
            $0.context = input.context
            $0.details = Acme_Patientapp_V1_StartPatientHomeWorkflowRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.preferredChannel = input.patientHome.requester.preferredChannel
                }
            }
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = input.patientHome.audit.createdBy
                }
                $0.customer = Acme_Patients_V1_PatientRef.with {
                    $0.email = input.patientHome.assignee.email
                }
            }
        }
        let reply0 = try await self.patientappPatientHomeWorkflow.startPatientHomeWorkflow(
            outbound0, metadata: ["x-acme-region": .string(settings.region)]
        )
        let outbound1 = Acme_Notifications_V1_SummarizeNotificationsRequest.with {
            $0.annotations = input.annotations
            $0.context = input.context
            $0.reason = input.reason
        }
        let reply1 = try await RPCOperations.call(outbound1) { request in
            try await self.notificationsNotificationQuery.summarizeNotifications(request)
        }
        let requests2 = input.patientHome.comments.map { element in
            Acme_Itsm_V1_SearchIncidentsRequest.with {
                $0.context = input.context
                $0.filter = Acme_Itsm_V1_SearchIncidentsRequest.Filter.with {
                    $0.createdAfter = element.createdAt
                    $0.labels = reply1.result.details
                    $0.ownerID = element.commentID
                }
            }
        }
        let replies2 = try await FanOut.map(requests2) { candidate in
            try await self.itsmIncident.searchIncidents(candidate)
        }
        let reply2 = replies2.first ?? Acme_Itsm_V1_SearchIncidentsResponse()
        _ = reply2
        let selection3_1: String
        switch reply0.patientHome.origin {
        case .customer(let customer):
            selection3_1 = customer.displayName
        default: selection3_1 = .init()
        }
        let outbound3 = Acme_Patientapp_V1_ClonePatientHomeRequest.with {
            $0.context = input.context
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.userID = reply0.patientHome.assignee.userID
                }
                $0.customer = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = selection3_1
                    $0.email = reply0.patientHome.assignee.email
                }
            }
        }
        let reply3 = try await self.patientappPatientHome.clonePatientHome(outbound3)
        return Acme_Patientapp_V1_FetchPatientHomeViewResponse.with {
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.patientHomeID = input.patientHomeID
                $0.requester = input.patientHome.requester
                $0.status = reply0.patientHome.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.message = reply3.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processGetPatientHomeSummary(_ input: Acme_Patientapp_V1_GetPatientHomeSummaryRequest) async throws
        -> Acme_Patientapp_V1_GetPatientHomeSummaryResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "GetPatientHomeSummary",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "GetPatientHomeSummary", detail: input.context.traceID
        )
        let outbound0 = Acme_Patients_V1_CancelPatientWorkflowRequest.with {
            $0.context = Projection.read(input, at: \Acme_Patientapp_V1_GetPatientHomeSummaryRequest.context)
            $0.details = Acme_Patients_V1_CancelPatientWorkflowRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.email = Projection.read(
                        input, at: \Acme_Patientapp_V1_GetPatientHomeSummaryRequest.context.actor.email)
                }
            }
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.passport = Acme_Patients_V1_PatientPassport.with {
                    $0.expiresAt = Projection.read(
                        input, at: \Acme_Patientapp_V1_GetPatientHomeSummaryRequest.context.deadline)
                }
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.userID = Projection.read(
                        input, at: \Acme_Patientapp_V1_GetPatientHomeSummaryRequest.context.actor.userID)
                }
                $0.segments = input.context.actor.roles
            }
        }
        let reply0 = try await self.patientsPatientWorkflow.cancelPatientWorkflow(outbound0)
        return Acme_Patientapp_V1_GetPatientHomeSummaryResponse.with {
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.patientHomeID = input.patientHomeID
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.name = reply0.patient.contact.name
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processRefreshPatientHome(_ input: Acme_Patientapp_V1_RefreshPatientHomeRequest) async throws
        -> Acme_Patientapp_V1_RefreshPatientHomeResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.device)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "audit", detail: input.details.device
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "RefreshPatientHome",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PatientHomeRecord(input.patientHome, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Patientapp_V1_SuggestCareInboxesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Patientapp_V1_SuggestCareInboxesRequest.Filter.with {
                $0.createdAfter = input.patientHome.audit.updatedAt
            }
        }
        let step0: @Sendable () async throws -> Acme_Patientapp_V1_SuggestCareInboxesResponse = {
            try await self.patientappCareInboxQuery.suggestCareInboxes(outbound0)
        }
        let reply0 = try await step0()
        var outbound1 = Acme_Patientapp_V1_DisconnectPatientHomeSourceRequest()
        outbound1.annotations = input.annotations
        outbound1.context = input.context
        outbound1.patientHomeID = input.patientHome.patientHomeID
        outbound1.reason = input.reason
        let reply1 = try await self.patientappPatientHomeIntegration.disconnectPatientHomeSource(outbound1)
        return Acme_Patientapp_V1_RefreshPatientHomeResponse.with {
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.comments = [
                    Acme_Patientapp_V1_PatientHomeComment.with {
                        $0.createdAt = reply1.patientHome.audit.createdAt
                    }
                ]
                $0.patientHomeID = input.patientHomeID
                $0.subject = input.patientHome.subject
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.status = reply0.result.status
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processSearchPatientHomeCatalog(_ input: Acme_Patientapp_V1_SearchPatientHomeCatalogRequest) async throws
        -> Acme_Patientapp_V1_SearchPatientHomeCatalogResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SearchPatientHomeCatalog",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "SearchPatientHomeCatalog", detail: input.context.traceID
        )
        return Acme_Patientapp_V1_SearchPatientHomeCatalogResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processStartPatientHomeCheckout(_ input: Acme_Patientapp_V1_StartPatientHomeCheckoutRequest) async throws
        -> Acme_Patientapp_V1_StartPatientHomeCheckoutResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "audit", detail: input.details.initiatedBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "StartPatientHomeCheckout",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PatientHomeRecord(input.patientHome, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Patientapp_V1_ReplayPatientHomeEventsRequest.with {
            $0.context = input.context
            $0.patientHomeID = input.patientHome.patientHomeID
        }
        let step0: @Sendable () async throws -> Acme_Patientapp_V1_ReplayPatientHomeEventsResponse = {
            try await self.patientappPatientHomeIntegration.replayPatientHomeEvents(outbound0)
        }
        let reply0 = try await step0()
        let selection1_2: String
        switch reply0.patientHome.origin {
        case .customer(let customer):
            selection1_2 = customer.email
        default: selection1_2 = .init()
        }
        let outbound1 = Acme_Metrics_V1_ScoreMetricSeriesRequest.with {
            $0.context = input.context
            $0.metricSeries = Acme_Metrics_V1_MetricSeries.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.patientHome.audit.createdAt
                }
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.email = selection1_2
                    $0.userID = reply0.patientHome.assignee.userID
                }
            }
        }
        let reply1 = try await self.metricsMetricSeriesValidation.scoreMetricSeries(outbound1)
        let requests2 = input.patientHome.history.map { element in
            Acme_Notifications_V1_NormalizeNotificationRequest.with {
                $0.context = input.context
                $0.notification = Acme_Notifications_V1_Notification.with {
                    $0.history = [
                        Acme_Notifications_V1_NotificationStatusChange.with {
                            $0.changedBy = element.changedBy
                            $0.toStatus = element.toStatus
                        }
                    ]
                }
            }
        }
        let replies2 = try await FanOut.map(requests2) { candidate in
            try await self.notificationsNotificationValidation.normalizeNotification(candidate)
        }
        let reply2 = replies2.first ?? Acme_Notifications_V1_NormalizeNotificationResponse()
        _ = reply2
        return Acme_Patientapp_V1_StartPatientHomeCheckoutResponse.with {
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.assignee = reply0.patientHome.assignee
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply1.metricSeries.audit.etag
                }
                $0.comments = [
                    Acme_Patientapp_V1_PatientHomeComment.with {
                        $0.createdAt = reply1.metricSeries.audit.createdAt
                    }
                ]
                $0.patientHomeID = input.patientHomeID
                $0.requester = input.patientHome.requester
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processSubmitPatientHomeForm(_ input: Acme_Patientapp_V1_SubmitPatientHomeFormRequest) async throws
        -> Acme_Patientapp_V1_SubmitPatientHomeFormResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.device)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "audit", detail: input.details.device
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SubmitPatientHomeForm",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PatientHomeRecord(input.patientHome, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let requests0 = input.patientHome.comments.map { element in
            Acme_Venues_V1_NormalizeVenueRequest.with {
                $0.context = input.context
                $0.venue = Acme_Venues_V1_Venue.with {
                    $0.audit = Acme_Common_V1_AuditInfo.with {
                        $0.createdAt = element.createdAt
                    }
                    $0.owner = Acme_Identity_V1_UserRef.with {
                        $0.email = element.authorEmail
                    }
                }
            }
        }
        let replies0 = try await FanOut.map(requests0) { candidate in
            try await self.venuesVenueValidation.normalizeVenue(candidate)
        }
        let reply0 = replies0.first ?? Acme_Venues_V1_NormalizeVenueResponse()
        _ = reply0
        let requests1 = input.patientHome.comments.map { element in
            Acme_Venues_V1_CheckVenueEligibilityRequest.with {
                $0.context = input.context
                $0.details = Acme_Venues_V1_CheckVenueEligibilityRequest.Details.with {
                    $0.contact = Acme_Common_V1_ContactInfo.with {
                        $0.email = element.authorEmail
                    }
                }
            }
        }
        let replies1 = try await FanOut.map(requests1) { candidate in
            try await self.venuesVenueValidation.checkVenueEligibility(candidate)
        }
        let reply1 = replies1.first ?? Acme_Venues_V1_CheckVenueEligibilityResponse()
        _ = reply1
        let requests2 = input.patientHome.comments.map { element in
            Acme_Careplans_V1_AdvanceCareGoalWorkflowRequest.with {
                $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                    $0.comments = [
                        Acme_Careplans_V1_CareGoalComment.with {
                            $0.visibility = element.visibility
                        }
                    ]
                }
                $0.context = input.context
            }
        }
        let replies2 = try await FanOut.map(requests2) { candidate in
            try await self.careplansCareGoalWorkflow.advanceCareGoalWorkflow(candidate)
        }
        let reply2 = replies2.first ?? Acme_Careplans_V1_AdvanceCareGoalWorkflowResponse()
        _ = reply2
        return Acme_Patientapp_V1_SubmitPatientHomeFormResponse.with {
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.patientHomeID = input.patientHomeID
                $0.subject = input.patientHome.subject
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processTrackPatientHome(_ input: Acme_Patientapp_V1_TrackPatientHomeRequest) async throws
        -> Acme_Patientapp_V1_TrackPatientHomeResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.device)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "audit", detail: input.details.device
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "TrackPatientHome",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PatientHomeRecord(input.patientHome, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Prescriptions_V1_AdvanceRefillWorkflowRequest.with {
            $0.context = input.context
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = input.patientHome.audit.etag
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.patientHome.assignee.email
                    $0.preferredChannel = input.patientHome.requester.preferredChannel
                }
                $0.sla = Acme_Prescriptions_V1_RefillSla.with {
                    $0.pausedFor = input.patientHome.sla.pausedFor
                }
            }
        }
        let reply0 = try await self.prescriptionsRefillWorkflow.advanceRefillWorkflow(outbound0)
        let outbound1 = Acme_Patientapp_V1_ExportCareInboxesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Patientapp_V1_ExportCareInboxesRequest.Filter.with {
                $0.createdAfter = reply0.outcome.effectiveAt
                $0.labels = reply0.result.details
                $0.ownerID = reply0.refill.customer.prescriptionID
            }
        }
        let reply1 = try await self.patientappCareInboxQuery.exportCareInboxes(outbound1) { response in
            var latest = Acme_Patientapp_V1_ExportCareInboxesResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        _ = reply1
        let outbound2 = Acme_Sponsorships_V1_SuggestSponsorsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Sponsorships_V1_SuggestSponsorsRequest.Filter.with {
                $0.createdAfter = reply0.refill.audit.updatedAt
            }
        }
        async let remote2 = self.sponsorshipsSponsorQuery.suggestSponsors(outbound2)
        async let persisted2 = store.count(tenant: input.context.tenantID)
        let (reply2, count2) = try await (remote2, persisted2)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count2)])
        return Acme_Patientapp_V1_TrackPatientHomeResponse.with {
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply0.refill.assignee.displayName
                }
                $0.patientHomeID = input.patientHomeID
                $0.priority = input.patientHome.priority
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply2.result.correlationID
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processUploadPatientHomeAttachments(_ input: Acme_Patientapp_V1_UploadPatientHomeAttachmentsRequest)
        async throws -> Acme_Patientapp_V1_UploadPatientHomeAttachmentsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.header.format)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "audit", detail: input.header.format
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "UploadPatientHomeAttachments",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "UploadPatientHomeAttachments", detail: input.context.traceID
        )
        let selection0_1: String
        switch input.chunk {
        case .record(let record):
            selection0_1 = record.requester.phone
        default: selection0_1 = .init()
        }
        let selection0_2: Acme_Common_V1_PersonName
        switch input.chunk {
        case .record(let record):
            selection0_2 = record.requester.name
        default: selection0_2 = .init()
        }
        let selection0_3: String
        switch input.chunk {
        case .record(let record):
            selection0_3 = record.assignee.displayName
        default: selection0_3 = .init()
        }
        let outbound0 = Acme_Patientapp_V1_RetryPatientHomeWorkflowRequest.with {
            $0.context = input.context
            $0.details = Acme_Patientapp_V1_RetryPatientHomeWorkflowRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.name = selection0_2
                }
            }
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.displayName = selection0_3
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.phone = selection0_1
                }
            }
        }
        let reply0 = try await self.patientappPatientHomeWorkflow.retryPatientHomeWorkflow(outbound0)
        let selection1_1: String
        switch input.chunk {
        case .record(let record):
            selection1_1 = record.customer.email
        default: selection1_1 = .init()
        }
        let selection1_2: String
        switch input.chunk {
        case .record(let record):
            selection1_2 = record.audit.updatedBy
        default: selection1_2 = .init()
        }
        let selection1_3: String
        switch reply0.patientHome.origin {
        case .customer(let customer):
            selection1_3 = customer.email
        default: selection1_3 = .init()
        }
        let selection1_4: Acme_Common_V1_PersonName
        switch input.chunk {
        case .header(let header):
            selection1_4 = header.submittedBy.name
        default: selection1_4 = .init()
        }
        let outbound1 = Acme_Patientapp_V1_StartPatientHomeWorkflowRequest.with {
            $0.context = input.context
            $0.details = Acme_Patientapp_V1_StartPatientHomeWorkflowRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.email = selection1_1
                    $0.name = selection1_4
                }
            }
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.email = selection1_3
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = selection1_2
                }
            }
        }
        let reply1 = try await self.patientappPatientHomeWorkflow.startPatientHomeWorkflow(outbound1)
        let outbound2 = Acme_Patientapp_V1_AcknowledgePatientHomeEventRequest.with {
            $0.context = input.context
            $0.patientHomeID = reply1.patientHome.patientHomeID
        }
        let reply2 = try await self.uploadPatientHomeAttachmentsStep2.execute(outbound2)
        return Acme_Patientapp_V1_UploadPatientHomeAttachmentsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = Projection.firstValue(
                    [
                        reply0.result.correlationID,
                        reply1.result.correlationID,
                    ], default: .init())
                $0.message = reply2.result.message
                $0.referenceIds = reply1.result.referenceIds
                $0.status = "ok"
            }
        }
    }
}
