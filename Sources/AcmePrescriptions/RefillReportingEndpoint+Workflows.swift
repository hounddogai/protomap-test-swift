import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension RefillReportingEndpoint {
    /// Deletes a refill.
    func deleteRefillReport(
        request: ServerRequest<Acme_Prescriptions_V1_DeleteRefillReportRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_DeleteRefillReportResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processDeleteRefillReport(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a refill.
    func fetchRefillReport(
        request: ServerRequest<Acme_Prescriptions_V1_FetchRefillReportRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_FetchRefillReportResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processFetchRefillReport(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Generates a refill.
    func generateRefillReport(
        request: ServerRequest<Acme_Prescriptions_V1_GenerateRefillReportRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_GenerateRefillReportResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGenerateRefillReport(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists refills a page at a time.
    func listRefillReports(
        request: ServerRequest<Acme_Prescriptions_V1_ListRefillReportsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ListRefillReportsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListRefillReports(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Schedules a refill.
    func scheduleRefillReport(
        request: ServerRequest<Acme_Prescriptions_V1_ScheduleRefillReportRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ScheduleRefillReportResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processScheduleRefillReport(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Shares a refill.
    func shareRefillReport(
        request: ServerRequest<Acme_Prescriptions_V1_ShareRefillReportRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ShareRefillReportResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processShareRefillReport(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Streams the changes of refills as they happen.
    func streamRefillMetrics(
        request: ServerRequest<Acme_Prescriptions_V1_StreamRefillMetricsRequest>,
        context: ServerContext
    ) async throws -> StreamingServerResponse<Acme_Prescriptions_V1_StreamRefillMetricsResponse> {
        return StreamingServerResponse { writer in
            try await CallerScope.$metadata.withValue(request.metadata) {
                let response = try await self.processStreamRefillMetrics(request.message)
                try await writer.write(response)
                return [:]
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processDeleteRefillReport(_ input: Acme_Prescriptions_V1_DeleteRefillReportRequest) async throws
        -> Acme_Prescriptions_V1_DeleteRefillReportResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "DeleteRefillReport",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "DeleteRefillReport", detail: input.context.traceID
        )
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        let archive = Data(try input.context.jsonString().utf8)
        let restoredContext = try Acme_Common_V1_RequestContext(
            jsonString: String(decoding: archive, as: UTF8.self)
        )
        _ = try await self.prescriptionsPrescriptionSync.reconcilePrescriptions(
            Acme_Prescriptions_V1_ReconcilePrescriptionsRequest.with {
                $0.context = restoredContext
                $0.details = Acme_Prescriptions_V1_ReconcilePrescriptionsRequest.Details.with {
                    $0.payload = archive
                }
            })
        let outbound0 = Acme_Prescriptions_V1_ListMedicationConflictsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Prescriptions_V1_ListMedicationConflictsRequest.Filter.with {
                $0.createdAfter = input.context.deadline
                $0.ownerID = input.refillID
            }
        }
        guard let execute0 = self.deleteRefillReportStep0[settings.region] ?? self.deleteRefillReportStep0["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply0 = try await execute0(outbound0)
        let outbound1 = Acme_Telehealth_V1_CancelTriageWorkflowRequest.with {
            $0.context = input.context
            $0.reason = input.reason
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = input.etag
                }
            }
        }
        let reply1 = try await self.telehealthTriageWorkflow.cancelTriageWorkflow(outbound1)
        return Acme_Prescriptions_V1_DeleteRefillReportResponse.with {
            $0.effectiveAt = reply1.outcome.effectiveAt
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = Projection.firstValue(
                    [
                        reply0.result.details,
                        reply1.result.details,
                    ], default: .init())
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processFetchRefillReport(_ input: Acme_Prescriptions_V1_FetchRefillReportRequest) async throws
        -> Acme_Prescriptions_V1_FetchRefillReportResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "FetchRefillReport",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "FetchRefillReport", detail: input.context.traceID
        )
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        let outbound0 = Acme_Prescriptions_V1_PushMedicationRequest.with {
            $0.context = input.context
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.context.deadline
                }
                $0.components = [
                    "primary": Acme_Prescriptions_V1_MedicationComponent.with {
                        $0.componentID = input.refillID
                    }
                ]
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.email = input.context.actor.email
                    $0.userID = input.context.actor.userID
                }
            }
        }
        let envelope0 = try Google_Protobuf_Any(message: outbound0)
        let unpacked0 = try Acme_Prescriptions_V1_PushMedicationRequest(unpackingAny: envelope0)
        let reply0 = try await self.prescriptionsMedicationSync.pushMedication(unpacked0)
        return Acme_Prescriptions_V1_FetchRefillReportResponse.with {
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply0.medication.audit.updatedAt
                }
                $0.refillID = input.refillID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processGenerateRefillReport(_ input: Acme_Prescriptions_V1_GenerateRefillReportRequest) async throws
        -> Acme_Prescriptions_V1_GenerateRefillReportResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.cron)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "audit", detail: input.details.cron
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "GenerateRefillReport",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "GenerateRefillReport", detail: input.context.traceID
        )
        let outbound0 = Acme_Prescriptions_V1_ExplainMedicationDecisionRequest.with {
            $0.context = input.context
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.context.actor.userID
                }
            }
            $0.reason = input.reason
        }
        let json0 = try outbound0.jsonString()
        let decoded0 = try Acme_Prescriptions_V1_ExplainMedicationDecisionRequest(jsonString: json0)
        let reply0 = try await self.prescriptionsMedicationValidation.explainMedicationDecision(decoded0)
        let outbound1 =
            Acme_Prescriptions_V1_GetRefillImportStatusRequest.forRefillReportingEndpointGenerateRefillReport1(
                input
            )
        let reply1 = try await self.prescriptionsRefillImport.getRefillImportStatus(outbound1)
        return Acme_Prescriptions_V1_GenerateRefillReportResponse.with {
            $0.period = input.details.period
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.details = reply1.result.details
                $0.message = reply1.result.message
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processListRefillReports(_ input: Acme_Prescriptions_V1_ListRefillReportsRequest) async throws
        -> Acme_Prescriptions_V1_ListRefillReportsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ListRefillReports",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "ListRefillReports", detail: input.context.traceID
        )
        let outbound0 = Acme_Notifications_V1_CloneNotificationRequest.with {
            $0.context = input.context
            $0.notification = Acme_Notifications_V1_Notification.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.context.actor.userID
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.context.actor.email
                }
            }
        }
        let reply0 = try await self.notificationsNotification.cloneNotification(
            outbound0, metadata: ["x-acme-region": .string(settings.region)]
        )
        return Acme_Prescriptions_V1_ListRefillReportsResponse.with {
            $0.refills = [
                Acme_Prescriptions_V1_Refill.with {
                    $0.priority = reply0.notification.priority
                }
            ]
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processScheduleRefillReport(_ input: Acme_Prescriptions_V1_ScheduleRefillReportRequest) async throws
        -> Acme_Prescriptions_V1_ScheduleRefillReportResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.cron)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "audit", detail: input.details.cron
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ScheduleRefillReport",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "ScheduleRefillReport", detail: input.context.traceID
        )
        let outbound0 = Acme_Prescriptions_V1_StreamPrescriptionMetricsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Prescriptions_V1_StreamPrescriptionMetricsRequest.Filter.with {
                $0.createdAfter = input.context.deadline
                $0.labels = input.annotations
                $0.ownerID = input.refillID
            }
            $0.subscriber = Acme_Common_V1_ContactInfo.with {
                $0.email = input.context.actor.email
            }
        }
        let reply0 = try await self.prescriptionsPrescriptionReporting.streamPrescriptionMetrics(outbound0) {
            response in
            var latest = Acme_Prescriptions_V1_StreamPrescriptionMetricsResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        _ = reply0
        let outbound1 = Acme_Prescriptions_V1_CalculateMedicationRequest.with {
            $0.annotations = input.annotations
            $0.context = input.context
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.email = input.context.actor.email
                    $0.userID = input.context.actor.userID
                }
            }
            $0.reason = input.reason
        }
        let reply1 = try await RPCOperations.call(outbound1) { request in
            try await self.prescriptionsMedicationCalculation.calculateMedication(request)
        }
        return Acme_Prescriptions_V1_ScheduleRefillReportResponse.with {
            $0.period = input.details.period
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply1.result.status
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processShareRefillReport(_ input: Acme_Prescriptions_V1_ShareRefillReportRequest) async throws
        -> Acme_Prescriptions_V1_ShareRefillReportResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.channel)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "audit", detail: input.details.channel
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ShareRefillReport",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "ShareRefillReport", detail: input.context.traceID
        )
        let outbound0 = Acme_Careplans_V1_SubmitCareGoalRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = Projection.read(
                        input, at: \Acme_Prescriptions_V1_ShareRefillReportRequest.details.recipient.email)
                    $0.name = Projection.read(
                        input, at: \Acme_Prescriptions_V1_ShareRefillReportRequest.details.recipient.name)
                    $0.phone = Projection.read(
                        input, at: \Acme_Prescriptions_V1_ShareRefillReportRequest.details.recipient.phone)
                }
            }
            $0.context = Projection.read(input, at: \Acme_Prescriptions_V1_ShareRefillReportRequest.context)
        }
        let reply0 = try await self.careplansCareGoalApproval.submitCareGoal(outbound0)
        return Acme_Prescriptions_V1_ShareRefillReportResponse.with {
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.email = input.details.recipient.email
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply0.careGoal.audit.createdBy
                }
                $0.refillID = input.refillID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply0.outcome.status
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processStreamRefillMetrics(_ input: Acme_Prescriptions_V1_StreamRefillMetricsRequest) async throws
        -> Acme_Prescriptions_V1_StreamRefillMetricsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "StreamRefillMetrics",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "StreamRefillMetrics", detail: input.context.traceID
        )
        let outbound0 = Acme_Prescriptions_V1_MapRefillImportColumnsRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_MapRefillImportColumnsRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.subscriber.email
                }
            }
        }
        let step0: @Sendable () async throws -> Acme_Prescriptions_V1_MapRefillImportColumnsResponse = {
            try await self.prescriptionsRefillImport.mapRefillImportColumns(outbound0)
        }
        let reply0 = try await step0()
        return Acme_Prescriptions_V1_StreamRefillMetricsResponse.with {
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply0.refill.audit.updatedAt
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.subscriber.email
                    $0.name = input.subscriber.name
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }
}
