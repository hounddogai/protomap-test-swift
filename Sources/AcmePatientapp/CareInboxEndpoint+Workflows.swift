import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension CareInboxEndpoint {
    /// Returns several care inboxes at once.
    func batchGetCareInboxes(
        request: ServerRequest<Acme_Patientapp_V1_BatchGetCareInboxesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_BatchGetCareInboxesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processBatchGetCareInboxes(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Creates a care inbox.
    func createCareInbox(
        request: ServerRequest<Acme_Patientapp_V1_CreateCareInboxRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_CreateCareInboxResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCreateCareInbox(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Deletes a care inbox.
    func deleteCareInbox(
        request: ServerRequest<Acme_Patientapp_V1_DeleteCareInboxRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_DeleteCareInboxResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processDeleteCareInbox(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a care inbox.
    func getCareInbox(
        request: ServerRequest<Acme_Patientapp_V1_GetCareInboxRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_GetCareInboxResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetCareInbox(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists care inboxes a page at a time.
    func searchCareInboxes(
        request: ServerRequest<Acme_Patientapp_V1_SearchCareInboxesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_SearchCareInboxesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSearchCareInboxes(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Changes a care inbox.
    func updateCareInbox(
        request: ServerRequest<Acme_Patientapp_V1_UpdateCareInboxRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_UpdateCareInboxResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processUpdateCareInbox(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Streams the changes of care inboxes as they happen.
    func watchCareInboxes(
        request: ServerRequest<Acme_Patientapp_V1_WatchCareInboxesRequest>,
        context: ServerContext
    ) async throws -> StreamingServerResponse<Acme_Patientapp_V1_WatchCareInboxesResponse> {
        return StreamingServerResponse { writer in
            try await CallerScope.$metadata.withValue(request.metadata) {
                let response = try await self.processWatchCareInboxes(request.message)
                try await writer.write(response)
                return [:]
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processBatchGetCareInboxes(_ input: Acme_Patientapp_V1_BatchGetCareInboxesRequest) async throws
        -> Acme_Patientapp_V1_BatchGetCareInboxesResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "BatchGetCareInboxes",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "BatchGetCareInboxes", detail: input.context.traceID
        )
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        let archive = Data(try input.context.jsonString().utf8)
        let restoredContext = try Acme_Common_V1_RequestContext(
            jsonString: String(decoding: archive, as: UTF8.self)
        )
        _ = try await self.patientsPatientSync.pullPatients(
            Acme_Patients_V1_PullPatientsRequest.with {
                $0.context = restoredContext
                $0.details = Acme_Patients_V1_PullPatientsRequest.Details.with {
                    $0.payload = archive
                }
            })
        let outbound0 = Acme_Telehealth_V1_ListPendingTriagesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Telehealth_V1_ListPendingTriagesRequest.Filter.with {
                $0.createdAfter = input.context.deadline
            }
        }
        let reply0 = try await self.telehealthTriageApproval.listPendingTriages(
            outbound0, metadata: ["x-acme-region": .string(settings.region)]
        )
        let outbound1 = Acme_Concessions_V1_UpdateConcessionStandRequest.with {
            $0.concessionStand = Acme_Concessions_V1_ConcessionStand.with {
                $0.components = [
                    "primary": Acme_Concessions_V1_ConcessionStandComponent.with {
                        $0.componentID = reply0.result.correlationID
                    }
                ]
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.email = input.context.actor.email
                    $0.userID = input.context.actor.userID
                }
                $0.specs = reply0.result.details
            }
            $0.context = input.context
        }
        let reply1 = try await RPCOperations.call(outbound1) { request in
            try await self.concessionsConcessionStand.updateConcessionStand(request)
        }
        return Acme_Patientapp_V1_BatchGetCareInboxesResponse.with {
            $0.careInboxes = [
                Acme_Patientapp_V1_CareInbox.with {
                    $0.audit = Acme_Common_V1_AuditInfo.with {
                        $0.createdAt = reply1.concessionStand.audit.createdAt
                    }
                }
            ]
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processCreateCareInbox(_ input: Acme_Patientapp_V1_CreateCareInboxRequest) async throws
        -> Acme_Patientapp_V1_CreateCareInboxResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.careInbox.audit.createdBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "audit", detail: input.careInbox.audit.createdBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "CreateCareInbox",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CareInboxRecord(input.careInbox, tenant: input.context.tenantID)
        try await store.save(record.stored)
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        let outbound0 = Acme_Metrics_V1_PreviewMetricSeriesRequest.with {
            $0.context = Projection.read(input, at: \Acme_Patientapp_V1_CreateCareInboxRequest.context)
            $0.metricSeries = Acme_Metrics_V1_MetricSeries.with {
                $0.address = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = Projection.read(
                        input, at: \Acme_Patientapp_V1_CreateCareInboxRequest.careInbox.billingAddress.countryCode)
                    $0.lines = input.careInbox.billingAddress.lines
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = Projection.read(
                        input, at: \Acme_Patientapp_V1_CreateCareInboxRequest.careInbox.audit.updatedAt)
                    $0.updatedBy = Projection.read(
                        input, at: \Acme_Patientapp_V1_CreateCareInboxRequest.careInbox.audit.updatedBy)
                }
            }
        }
        let reply0 = try await self.metricsMetricSeriesValidation.previewMetricSeries(outbound0)
        let outbound1 = Acme_Metrics_V1_LintMetricSeriesesRequest.with {
            $0.context = input.context
            $0.metricSeries = Acme_Metrics_V1_MetricSeries.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = input.careInbox.audit.updatedBy
                }
                $0.components = [
                    "primary": Acme_Metrics_V1_MetricSeriesComponent.with {
                        $0.quantity = reply0.metricSeries.components["primary", default: .init()].quantity
                    }
                ]
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.userID = reply0.metricSeries.owner.userID
                }
            }
        }
        let step1: @Sendable () async throws -> Acme_Metrics_V1_LintMetricSeriesesResponse = {
            try await self.metricsMetricSeriesValidation.lintMetricSerieses(outbound1)
        }
        let reply1 = try await step1()
        let requests2 = input.careInbox.lines.map { element in
            Acme_Telehealth_V1_RetryVisitNoteWorkflowRequest.with {
                $0.context = input.context
                $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                    $0.lines = [
                        Acme_Telehealth_V1_VisitNoteLine.with {
                            $0.tax = Acme_Telehealth_V1_VisitNoteLineTax.with {
                                $0.exemptions = element.tax.exemptions
                            }
                        }
                    ]
                }
            }
        }
        let replies2 = try await FanOut.map(requests2) { candidate in
            try await self.telehealthVisitNoteWorkflow.retryVisitNoteWorkflow(candidate)
        }
        let reply2 = replies2.first ?? Acme_Telehealth_V1_RetryVisitNoteWorkflowResponse()
        _ = reply2
        let selection3_1: String
        switch reply0.metricSeries.locator {
        case .address(let address):
            selection3_1 = address.region
        default: selection3_1 = .init()
        }
        let selection3_2: String
        switch input.careInbox.settlement {
        case .bank(let bank):
            selection3_2 = bank.bic
        default: selection3_2 = .init()
        }
        let outbound3 = Acme_Patientapp_V1_AdvanceCareInboxWorkflowRequest.with {
            $0.careInbox = Acme_Patientapp_V1_CareInbox.with {
                $0.bank = Acme_Patientapp_V1_CareInboxBankSettlement.with {
                    $0.bic = selection3_2
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = selection3_1
                }
                $0.lines = [
                    Acme_Patientapp_V1_CareInboxLine.with {
                        $0.description_p = reply1.metricSeries.components["primary", default: .init()].description_p
                    }
                ]
            }
            $0.context = input.context
        }
        let reply3 = try await self.patientappCareInboxWorkflow.advanceCareInboxWorkflow(outbound3)
        return Acme_Patientapp_V1_CreateCareInboxResponse.with {
            $0.careInbox = Acme_Patientapp_V1_CareInbox.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply1.metricSeries.audit.updatedBy
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.locality = reply3.careInbox.billingAddress.locality
                    $0.region = reply0.metricSeries.address.region
                }
                $0.counterparty = input.careInbox.counterparty
                $0.status = reply3.careInbox.status
                $0.total = input.careInbox.total
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processDeleteCareInbox(_ input: Acme_Patientapp_V1_DeleteCareInboxRequest) async throws
        -> Acme_Patientapp_V1_DeleteCareInboxResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.etag)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "audit", detail: input.etag
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "DeleteCareInbox",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "DeleteCareInbox", detail: input.context.traceID
        )
        var outbound0 = Acme_Patientapp_V1_ResumeCareInboxWorkflowRequest()
        outbound0.careInboxID = input.careInboxID
        outbound0.context = input.context
        let reply0 = try await self.patientappCareInboxWorkflow.resumeCareInboxWorkflow(outbound0)
        let outbound1 = Acme_Patients_V1_SubmitAllergyRequest.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.correlationID = reply0.result.correlationID
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = reply0.careInbox.counterparty.displayName
                    $0.email = reply0.careInbox.counterparty.email
                    $0.patientID = reply0.careInbox.counterparty.patientID
                }
            }
            $0.context = input.context
        }
        let step1: @Sendable () async throws -> Acme_Patients_V1_SubmitAllergyResponse = {
            try await self.patientsAllergyApproval.submitAllergy(outbound1)
        }
        let reply1 = try await step1()
        let outbound2 = Acme_Patientapp_V1_StreamCareInboxNoticesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Patientapp_V1_StreamCareInboxNoticesRequest.Filter.with {
                $0.createdAfter = reply0.careInbox.audit.createdAt
                $0.region = reply0.careInbox.billingAddress.region
            }
            $0.subscriber = Acme_Common_V1_ContactInfo.with {
                $0.email = reply0.careInbox.counterparty.email
            }
        }
        let reply2 = try await self.patientappCareInboxNotification.streamCareInboxNotices(outbound2) { response in
            var latest = Acme_Patientapp_V1_StreamCareInboxNoticesResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        _ = reply2
        let outbound3 = Acme_Patientapp_V1_SuggestPatientHomesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Patientapp_V1_SuggestPatientHomesRequest.Filter.with {
                $0.region = reply0.careInbox.billingAddress.region
            }
        }
        let reply3 = try await self.patientappPatientHomeQuery.suggestPatientHomes(outbound3)
        return Acme_Patientapp_V1_DeleteCareInboxResponse.with {
            $0.effectiveAt = reply1.outcome.effectiveAt
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply1.result.referenceIds + reply3.result.referenceIds
                $0.status = Projection.firstValue(
                    [
                        reply0.result.status,
                        reply3.result.status,
                    ], default: .init())
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processGetCareInbox(_ input: Acme_Patientapp_V1_GetCareInboxRequest) async throws
        -> Acme_Patientapp_V1_GetCareInboxResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "GetCareInbox",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "GetCareInbox", detail: input.context.traceID
        )
        return Acme_Patientapp_V1_GetCareInboxResponse.with {
            $0.careInbox = Acme_Patientapp_V1_CareInbox.with {
                $0.careInboxID = input.careInboxID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processSearchCareInboxes(_ input: Acme_Patientapp_V1_SearchCareInboxesRequest) async throws
        -> Acme_Patientapp_V1_SearchCareInboxesResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SearchCareInboxes",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "SearchCareInboxes", detail: input.context.traceID
        )
        let outbound0 = Acme_Patientapp_V1_CancelCareInboxWorkflowRequest.with {
            $0.careInbox = Acme_Patientapp_V1_CareInbox.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.email = input.context.actor.email
                }
            }
            $0.context = input.context
        }
        async let remote0 = self.patientappCareInboxWorkflow.cancelCareInboxWorkflow(outbound0)
        async let persisted0 = store.count(tenant: input.context.tenantID)
        let (reply0, count0) = try await (remote0, persisted0)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count0)])
        return Acme_Patientapp_V1_SearchCareInboxesResponse.with {
            $0.careInboxes = [
                Acme_Patientapp_V1_CareInbox.with {
                    $0.dueAt = reply0.careInbox.dueAt
                }
            ]
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processUpdateCareInbox(_ input: Acme_Patientapp_V1_UpdateCareInboxRequest) async throws
        -> Acme_Patientapp_V1_UpdateCareInboxResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.careInbox.audit.createdBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "audit", detail: input.careInbox.audit.createdBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "UpdateCareInbox",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CareInboxRecord(input.careInbox, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Prescriptions_V1_ReconcilePrescriptionsRequest.with {
            $0.context = input.context
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = input.careInbox.audit.updatedBy
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = input.careInbox.counterparty.displayName
                }
            }
        }
        let reply0 = try await self.updateCareInboxStep0.execute(outbound0)
        let outbound1 = Acme_Careplans_V1_ResumeCarePlanWorkflowRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply0.prescription.audit.etag
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = reply0.prescription.billingAddress.region
                }
            }
            $0.context = input.context
        }
        let port1 = RPCOperations.port { (request: Acme_Careplans_V1_ResumeCarePlanWorkflowRequest) in
            try await self.careplansCarePlanWorkflow.resumeCarePlanWorkflow(request)
        }
        let reply1 = try await port1.execute(outbound1)
        let outbound2 = Acme_Patientapp_V1_AdvancePatientHomeWorkflowRequest.with {
            $0.context = input.context
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply1.carePlan.counterparty.displayName
                    $0.email = input.careInbox.counterparty.email
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply1.carePlan.audit.createdAt
                }
            }
        }
        let reply2 = try await self.updateCareInboxStep2(outbound2)
        let outbound3 = Acme_Patientapp_V1_SendCareInboxTestNoticeRequest.with {
            $0.context = input.context
            $0.details = Acme_Patientapp_V1_SendCareInboxTestNoticeRequest.Details.with {
                $0.recipient = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.careInbox.counterparty.email
                }
            }
        }
        guard let execute3 = self.updateCareInboxStep3[settings.region] ?? self.updateCareInboxStep3["primary"] else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply3 = try await execute3(outbound3)
        return Acme_Patientapp_V1_UpdateCareInboxResponse.with {
            $0.careInbox = Acme_Patientapp_V1_CareInbox.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply2.patientHome.audit.updatedAt
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.locality = reply0.prescription.billingAddress.locality
                }
                $0.careInboxID = input.careInbox.careInboxID
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = reply1.carePlan.counterparty.displayName
                }
                $0.issuedAt = reply3.careInbox.issuedAt
                $0.total = input.careInbox.total
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply0.outcome.status
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processWatchCareInboxes(_ input: Acme_Patientapp_V1_WatchCareInboxesRequest) async throws
        -> Acme_Patientapp_V1_WatchCareInboxesResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.query)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "audit", detail: input.filter.query
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "WatchCareInboxes",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "WatchCareInboxes", detail: input.context.traceID
        )
        let outbound0 = Acme_Patientapp_V1_StreamCareInboxNoticesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Patientapp_V1_StreamCareInboxNoticesRequest.Filter.with {
                $0.createdAfter = input.filter.createdAfter
                $0.ownerID = input.filter.ownerID
            }
            $0.subscriber = Acme_Common_V1_ContactInfo.with {
                $0.phone = input.subscriber.phone
            }
        }
        let reply0 = try await self.patientappCareInboxNotification.streamCareInboxNotices(outbound0) { response in
            var latest = Acme_Patientapp_V1_StreamCareInboxNoticesResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        _ = reply0
        let outbound1 = Acme_Patientapp_V1_DisconnectCareInboxSourceRequest.with {
            $0.context = input.context
            $0.details = Acme_Patientapp_V1_DisconnectCareInboxSourceRequest.Details.with {
                $0.messageID = input.filter.ownerID
                $0.receivedAt = input.filter.createdAfter
            }
        }
        let reply1 = try await self.patientappCareInboxIntegration.disconnectCareInboxSource(outbound1)
        let outbound2 = Acme_Telehealth_V1_DelegateTriageApprovalRequest.with {
            $0.context = input.context
            $0.details = Acme_Telehealth_V1_DelegateTriageApprovalRequest.Details.with {
                $0.approver = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply1.careInbox.counterparty.displayName
                }
            }
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.comments = [
                    Acme_Telehealth_V1_TriageComment.with {
                        $0.createdAt = reply1.careInbox.audit.createdAt
                    }
                ]
            }
        }
        let envelope2 = try Google_Protobuf_Any(message: outbound2)
        let unpacked2 = try Acme_Telehealth_V1_DelegateTriageApprovalRequest(unpackingAny: envelope2)
        let reply2 = try await self.telehealthTriageApproval.delegateTriageApproval(unpacked2)
        return Acme_Patientapp_V1_WatchCareInboxesResponse.with {
            $0.careInbox = Acme_Patientapp_V1_CareInbox.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.email = input.subscriber.email
                }
                $0.dueAt = reply2.triage.sla.dueAt
                $0.issuedAt = reply1.careInbox.issuedAt
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply1.result.status
            }
        }
    }
}
