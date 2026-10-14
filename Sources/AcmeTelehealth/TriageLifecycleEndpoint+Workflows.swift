import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension TriageLifecycleEndpoint {
    /// Activates a triage.
    func activateTriage(
        request: ServerRequest<Acme_Telehealth_V1_ActivateTriageRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_ActivateTriageResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processActivateTriage(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Expires a triage.
    func expireTriage(
        request: ServerRequest<Acme_Telehealth_V1_ExpireTriageRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_ExpireTriageResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processExpireTriage(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a triage.
    func getTriageLifecycle(
        request: ServerRequest<Acme_Telehealth_V1_GetTriageLifecycleRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_GetTriageLifecycleResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetTriageLifecycle(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Reinstates a triage.
    func reinstateTriage(
        request: ServerRequest<Acme_Telehealth_V1_ReinstateTriageRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_ReinstateTriageResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processReinstateTriage(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Renews a triage.
    func renewTriage(
        request: ServerRequest<Acme_Telehealth_V1_RenewTriageRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_RenewTriageResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRenewTriage(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Schedules a triage.
    func scheduleTriageExpiry(
        request: ServerRequest<Acme_Telehealth_V1_ScheduleTriageExpiryRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_ScheduleTriageExpiryResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processScheduleTriageExpiry(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Suspends a triage.
    func suspendTriage(
        request: ServerRequest<Acme_Telehealth_V1_SuspendTriageRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_SuspendTriageResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSuspendTriage(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Terminates a triage.
    func terminateTriage(
        request: ServerRequest<Acme_Telehealth_V1_TerminateTriageRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_TerminateTriageResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processTerminateTriage(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processActivateTriage(_ input: Acme_Telehealth_V1_ActivateTriageRequest) async throws
        -> Acme_Telehealth_V1_ActivateTriageResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "triage",
            action: "audit", detail: input.details.newOwner.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ActivateTriage",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "triage",
            action: "ActivateTriage", detail: input.context.traceID
        )
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        let importFrame = Acme_Telehealth_V1_BatchCreateVideoVisitsRequest.with {
            $0.context = input.context
        }
        _ = try await self.telehealthVideoVisit.batchCreateVideoVisits { writer in
            try await writer.write(importFrame)
        }
        let outbound0 = Acme_Configuration_V1_SearchConfigSetsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Configuration_V1_SearchConfigSetsRequest.Filter.with {
                $0.createdAfter = input.details.effectiveAt
            }
        }
        async let remote0 = self.configurationConfigSet.searchConfigSets(outbound0)
        async let persisted0 = store.count(tenant: input.context.tenantID)
        let (reply0, count0) = try await (remote0, persisted0)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count0)])
        let outbound1 = Acme_Venues_V1_CountVenuesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Venues_V1_CountVenuesRequest.Filter.with {
                $0.createdAfter = input.details.effectiveAt
            }
        }
        let reply1 = try await self.activateTriageStep1.execute(outbound1)
        let outbound2 = Acme_Patients_V1_CreatePatientRequest.with {
            $0.context = input.context
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.newOwner.email
                    $0.name = input.details.notifyContact.name
                }
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.email = input.details.notifyContact.email
                }
            }
        }
        let port2 = RPCOperations.port { (request: Acme_Patients_V1_CreatePatientRequest) in
            try await self.patientsPatient.createPatient(request)
        }
        let reply2 = try await port2.execute(outbound2)
        let outbound3 = Acme_Telehealth_V1_NormalizeVisitNoteRequest.with {
            $0.context = input.context
            $0.details = Acme_Telehealth_V1_NormalizeVisitNoteRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.name = input.details.notifyContact.name
                }
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply2.patient.audit.updatedAt
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = reply2.patient.primaryAddress.region
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.email = input.details.notifyContact.email
                }
            }
        }
        let reply3 = try await self.activateTriageStep3(outbound3)
        return Acme_Telehealth_V1_ActivateTriageResponse.with {
            $0.outcome = Acme_Telehealth_V1_ActivateTriageResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
                $0.message = Projection.firstValue(
                    [
                        reply1.result.message,
                        reply3.result.message,
                    ], default: .init())
                $0.status = reply0.result.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply1.result.status
            }
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.name = reply2.patient.contact.name
                }
                $0.triageID = input.triageID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processExpireTriage(_ input: Acme_Telehealth_V1_ExpireTriageRequest) async throws
        -> Acme_Telehealth_V1_ExpireTriageResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "triage",
            action: "audit", detail: input.details.newOwner.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ExpireTriage",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "triage",
            action: "ExpireTriage", detail: input.context.traceID
        )
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        let outbound0 = Acme_Notifications_V1_PreviewNotificationRequest.with {
            $0.context = input.context
            $0.notification = Acme_Notifications_V1_Notification.with {
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.phone = input.details.notifyContact.phone
                }
            }
        }
        guard let execute0 = self.expireTriageStep0[settings.region] ?? self.expireTriageStep0["primary"] else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply0 = try await execute0(outbound0)
        let outbound1 = Acme_Authorization_V1_CheckAccessPolicyEligibilityRequest.with {
            $0.accessPolicy = Acme_Authorization_V1_AccessPolicy.with {
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.email = input.details.newOwner.email
                }
            }
            $0.context = input.context
        }
        let reply1 = try await self.authorizationAccessPolicyValidation.checkAccessPolicyEligibility(outbound1)
        let outbound2 = Acme_Metrics_V1_ValidateMetricSeriesRequest.with {
            $0.context = input.context
            $0.details = Acme_Metrics_V1_ValidateMetricSeriesRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply0.notification.assignee.email
                }
            }
            $0.metricSeries = Acme_Metrics_V1_MetricSeries.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply1.accessPolicy.audit.createdAt
                    $0.createdBy = reply0.notification.audit.createdBy
                }
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.email = reply0.notification.requester.email
                }
            }
        }
        let envelope2 = try Google_Protobuf_Any(message: outbound2)
        let unpacked2 = try Acme_Metrics_V1_ValidateMetricSeriesRequest(unpackingAny: envelope2)
        let reply2 = try await self.metricsMetricSeriesValidation.validateMetricSeries(unpacked2)
        let outbound3 = Acme_Telehealth_V1_PreviewTriageRequest.with {
            $0.context = input.context
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply1.accessPolicy.audit.createdAt
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.preferredChannel = input.details.notifyContact.preferredChannel
                }
            }
        }
        let json3 = try outbound3.jsonString()
        let decoded3 = try Acme_Telehealth_V1_PreviewTriageRequest(jsonString: json3)
        let reply3 = try await self.telehealthTriageValidation.previewTriage(decoded3)
        return Acme_Telehealth_V1_ExpireTriageResponse.with {
            $0.outcome = Acme_Telehealth_V1_ExpireTriageResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
                $0.status = Projection.firstValue(
                    [
                        reply0.outcome.status,
                        reply3.outcome.status,
                    ], default: .init())
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.outcome.message
                $0.status = "ok"
            }
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply1.accessPolicy.audit.etag
                }
                $0.comments = [
                    Acme_Telehealth_V1_TriageComment.with {
                        $0.createdAt = reply2.metricSeries.audit.createdAt
                    }
                ]
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply1.accessPolicy.owner.email
                }
                $0.triageID = input.triageID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processGetTriageLifecycle(_ input: Acme_Telehealth_V1_GetTriageLifecycleRequest) async throws
        -> Acme_Telehealth_V1_GetTriageLifecycleResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "GetTriageLifecycle",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "triage",
            action: "GetTriageLifecycle", detail: input.context.traceID
        )
        let outbound0 = Acme_Telehealth_V1_RecalculateVideoVisitsRequest.forTriageLifecycleEndpointGetTriageLifecycle0(
            input
        )
        let reply0 = try await self.telehealthVideoVisitCalculation.recalculateVideoVisits(outbound0)
        let outbound1 = Acme_Telehealth_V1_CompareVisitNoteOptionsRequest.with {
            $0.context = input.context
            $0.details = Acme_Telehealth_V1_CompareVisitNoteOptionsRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.locality = reply0.videoVisit.location.locality
                    $0.postalCode = reply0.videoVisit.location.postalCode
                }
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply0.videoVisit.audit.updatedBy
                }
            }
        }
        let reply1 = try await self.telehealthVisitNoteCalculation.compareVisitNoteOptions(
            outbound1, metadata: ["x-acme-region": .string(settings.region)]
        )
        return Acme_Telehealth_V1_GetTriageLifecycleResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply1.result.status
            }
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.email = reply1.visitNote.counterparty.email
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply0.videoVisit.audit.updatedAt
                    $0.updatedBy = reply0.videoVisit.audit.updatedBy
                }
                $0.triageID = input.triageID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processReinstateTriage(_ input: Acme_Telehealth_V1_ReinstateTriageRequest) async throws
        -> Acme_Telehealth_V1_ReinstateTriageResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "triage",
            action: "audit", detail: input.details.newOwner.email
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ReinstateTriage",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "triage",
            action: "ReinstateTriage", detail: input.context.traceID
        )
        let outbound0 = Acme_Telehealth_V1_ValidateVideoVisitRequest.with {
            $0.context = input.context
            $0.details = Acme_Telehealth_V1_ValidateVideoVisitRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.phone = input.details.notifyContact.phone
                    $0.preferredChannel = input.details.notifyContact.preferredChannel
                }
            }
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.details.newOwner.displayName
                }
            }
        }
        let reply0 = try await RPCOperations.call(outbound0) { request in
            try await self.telehealthVideoVisitValidation.validateVideoVisit(request)
        }
        let outbound1 = Acme_Telehealth_V1_CompareTriageOptionsRequest.with {
            $0.context = Projection.read(input, at: \Acme_Telehealth_V1_ReinstateTriageRequest.context)
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.customer = Acme_Telehealth_V1_VideoVisitRef.with {
                    $0.displayName = Projection.read(
                        input, at: \Acme_Telehealth_V1_ReinstateTriageRequest.details.newOwner.displayName)
                }
            }
        }
        let reply1 = try await self.telehealthTriageCalculation.compareTriageOptions(outbound1)
        return Acme_Telehealth_V1_ReinstateTriageResponse.with {
            $0.outcome = Acme_Telehealth_V1_ReinstateTriageResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.status = "ok"
            }
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply0.videoVisit.audit.createdAt
                }
                $0.triageID = input.triageID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processRenewTriage(_ input: Acme_Telehealth_V1_RenewTriageRequest) async throws
        -> Acme_Telehealth_V1_RenewTriageResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "triage",
            action: "audit", detail: input.details.newOwner.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "RenewTriage",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "triage",
            action: "RenewTriage", detail: input.context.traceID
        )
        let outbound0 = Acme_Metrics_V1_SuggestMetricSeriesesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Metrics_V1_SuggestMetricSeriesesRequest.Filter.with {
                $0.createdAfter = input.details.effectiveAt
                $0.labels = input.annotations
                $0.ownerID = input.details.newOwner.userID
            }
        }
        let step0: @Sendable () async throws -> Acme_Metrics_V1_SuggestMetricSeriesesResponse = {
            try await self.metricsMetricSeriesQuery.suggestMetricSerieses(outbound0)
        }
        let reply0 = try await step0()
        let outbound1 = Acme_Telehealth_V1_WatchVideoVisitsRequest.with {
            $0.context = input.context
            $0.subscriber = Acme_Common_V1_ContactInfo.with {
                $0.email = input.details.newOwner.email
                $0.name = input.details.notifyContact.name
                $0.phone = input.details.notifyContact.phone
                $0.preferredChannel = input.details.notifyContact.preferredChannel
            }
        }
        let reply1 = try await self.telehealthVideoVisit.watchVideoVisits(outbound1) { response in
            var latest = Acme_Telehealth_V1_WatchVideoVisitsResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        _ = reply1
        var outbound2 = Acme_Audit_V1_NormalizeAuditEventRequest()
        outbound2.context = input.context
        outbound2.details = Acme_Audit_V1_NormalizeAuditEventRequest.Details.with {
            $0.contact = Acme_Common_V1_ContactInfo.with {
                $0.name = input.details.notifyContact.name
                $0.preferredChannel = input.details.notifyContact.preferredChannel
            }
        }
        let reply2 = try await self.auditAuditEventValidation.normalizeAuditEvent(outbound2)
        let outbound3 = Acme_Collections_V1_WatchCollectionCasesRequest.with {
            $0.context = input.context
            $0.subscriber = Acme_Common_V1_ContactInfo.with {
                $0.email = input.details.notifyContact.email
                $0.name = input.details.notifyContact.name
                $0.phone = input.details.notifyContact.phone
                $0.preferredChannel = input.details.notifyContact.preferredChannel
            }
        }
        let reply3 = try await self.collectionsCollectionCase.watchCollectionCases(outbound3) { response in
            var latest = Acme_Collections_V1_WatchCollectionCasesResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        _ = reply3
        return Acme_Telehealth_V1_RenewTriageResponse.with {
            $0.outcome = Acme_Telehealth_V1_RenewTriageResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
                $0.message = Projection.firstValue(
                    [
                        reply0.result.message,
                        reply2.outcome.message,
                    ], default: .init())
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.triageID = input.triageID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processScheduleTriageExpiry(_ input: Acme_Telehealth_V1_ScheduleTriageExpiryRequest) async throws
        -> Acme_Telehealth_V1_ScheduleTriageExpiryResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "triage",
            action: "audit", detail: input.details.initiatedBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ScheduleTriageExpiry",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try TriageRecord(input.triage, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let selection0_1: String
        switch input.triage.origin {
        case .customer(let customer):
            selection0_1 = customer.displayName
        default: selection0_1 = .init()
        }
        let selection0_2: Google_Protobuf_Timestamp
        switch input.triage.origin {
        case .customer(let customer):
            selection0_2 = customer.startsAt
        default: selection0_2 = .init()
        }
        let outbound0 = Acme_Careplans_V1_SubmitCarePlanRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.counterparty = Acme_Appointments_V1_AppointmentRef.with {
                    $0.startsAt = selection0_2
                }
            }
            $0.context = input.context
            $0.details = Acme_Careplans_V1_SubmitCarePlanRequest.Details.with {
                $0.approver = Acme_Identity_V1_UserRef.with {
                    $0.displayName = selection0_1
                }
            }
        }
        let reply0 = try await self.careplansCarePlanApproval.submitCarePlan(outbound0)
        let outbound1 = Acme_Patients_V1_BatchCreatePatientsRequest.with {
            $0.context = input.context
            $0.record = Acme_Patients_V1_Patient.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.triage.audit.createdAt
                    $0.updatedBy = input.triage.audit.updatedBy
                }
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.name = input.details.notify.name
                }
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = reply0.carePlan.billingAddress.postalCode
                }
            }
        }
        let reply1 = try await self.patientsPatient.batchCreatePatients { writer in
            try await writer.write(outbound1)
        }
        _ = reply1
        return Acme_Telehealth_V1_ScheduleTriageExpiryResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply0.carePlan.audit.updatedAt
                }
                $0.priority = input.triage.priority
                $0.triageID = input.triageID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processSuspendTriage(_ input: Acme_Telehealth_V1_SuspendTriageRequest) async throws
        -> Acme_Telehealth_V1_SuspendTriageResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.userID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "triage",
            action: "audit", detail: input.details.newOwner.userID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SuspendTriage",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "triage",
            action: "SuspendTriage", detail: input.context.traceID
        )
        let outbound0 = Acme_Patients_V1_PreviewAllergyRequest.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = input.details.newOwner.displayName
                }
            }
            $0.context = input.context
            $0.details = Acme_Patients_V1_PreviewAllergyRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.newOwner.email
                }
            }
        }
        let step0: @Sendable () async throws -> Acme_Patients_V1_PreviewAllergyResponse = {
            try await self.patientsAllergyValidation.previewAllergy(outbound0)
        }
        let reply0 = try await step0()
        let outbound1 = Acme_Telehealth_V1_LintTriagesRequest.with {
            $0.context = input.context
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.name = input.details.notifyContact.name
                }
            }
        }
        let reply1 = try await self.telehealthTriageValidation.lintTriages(outbound1)
        return Acme_Telehealth_V1_SuspendTriageResponse.with {
            $0.outcome = Acme_Telehealth_V1_SuspendTriageResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
                $0.referenceID = reply0.outcome.referenceID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.sla = Acme_Telehealth_V1_TriageSla.with {
                    $0.dueAt = reply1.triage.sla.dueAt
                }
                $0.triageID = input.triageID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processTerminateTriage(_ input: Acme_Telehealth_V1_TerminateTriageRequest) async throws
        -> Acme_Telehealth_V1_TerminateTriageResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "triage",
            action: "audit", detail: input.details.newOwner.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "TerminateTriage",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "triage",
            action: "TerminateTriage", detail: input.context.traceID
        )
        let outbound0 = Acme_Identity_V1_LookupUserRequest.with {
            $0.context = input.context
            $0.userID = input.details.newOwner.userID
        }
        async let remote0 = self.identityUserQuery.lookupUser(outbound0)
        async let persisted0 = store.count(tenant: input.context.tenantID)
        let (reply0, count0) = try await (remote0, persisted0)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count0)])
        return Acme_Telehealth_V1_TerminateTriageResponse.with {
            $0.outcome = Acme_Telehealth_V1_TerminateTriageResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.email = reply0.user.contact.email
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.name = reply0.user.contact.name
                }
                $0.triageID = input.triageID
            }
        }
    }
}
