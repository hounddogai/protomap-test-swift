import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension ClinicSlotApprovalEndpoint {
    /// Approves a clinic slot.
    func approveClinicSlot(
        request: ServerRequest<Acme_Appointments_V1_ApproveClinicSlotRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_ApproveClinicSlotResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processApproveClinicSlot(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Comments a clinic slot.
    func commentClinicSlotApproval(
        request: ServerRequest<Acme_Appointments_V1_CommentClinicSlotApprovalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_CommentClinicSlotApprovalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCommentClinicSlotApproval(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Delegates a clinic slot.
    func delegateClinicSlotApproval(
        request: ServerRequest<Acme_Appointments_V1_DelegateClinicSlotApprovalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_DelegateClinicSlotApprovalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processDelegateClinicSlotApproval(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Escalates a clinic slot.
    func escalateClinicSlot(
        request: ServerRequest<Acme_Appointments_V1_EscalateClinicSlotRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_EscalateClinicSlotResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processEscalateClinicSlot(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists clinic slots a page at a time.
    func listPendingClinicSlots(
        request: ServerRequest<Acme_Appointments_V1_ListPendingClinicSlotsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_ListPendingClinicSlotsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListPendingClinicSlots(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Recalls a clinic slot.
    func recallClinicSlot(
        request: ServerRequest<Acme_Appointments_V1_RecallClinicSlotRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_RecallClinicSlotResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRecallClinicSlot(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Rejects a clinic slot.
    func rejectClinicSlot(
        request: ServerRequest<Acme_Appointments_V1_RejectClinicSlotRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_RejectClinicSlotResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRejectClinicSlot(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Submits a clinic slot.
    func submitClinicSlot(
        request: ServerRequest<Acme_Appointments_V1_SubmitClinicSlotRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_SubmitClinicSlotResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSubmitClinicSlot(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processApproveClinicSlot(_ input: Acme_Appointments_V1_ApproveClinicSlotRequest) async throws
        -> Acme_Appointments_V1_ApproveClinicSlotResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.clinicSlot.audit.createdBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "clinic_slot",
            action: "audit", detail: input.clinicSlot.audit.createdBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ApproveClinicSlot",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try ClinicSlotRecord(input.clinicSlot, tenant: input.context.tenantID)
        try await store.save(record.stored)
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
        let outbound0 = Acme_Careplans_V1_ResumeCarePlanWorkflowRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = input.clinicSlot.location.countryCode
                }
            }
            $0.context = input.context
        }
        async let remote0 = self.careplansCarePlanWorkflow.resumeCarePlanWorkflow(outbound0)
        async let persisted0 = store.count(tenant: input.context.tenantID)
        let (reply0, count0) = try await (remote0, persisted0)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count0)])
        let requests1 = input.clinicSlot.participants.map { element in
            Acme_Featureflags_V1_ScoreFeatureFlagRequest.with {
                $0.context = input.context
                $0.featureFlag = Acme_Featureflags_V1_FeatureFlag.with {
                    $0.owner = Acme_Identity_V1_UserRef.with {
                        $0.email = element.contact.email
                    }
                }
            }
        }
        let replies1 = try await FanOut.map(requests1) { candidate in
            try await self.featureflagsFeatureFlagValidation.scoreFeatureFlag(candidate)
        }
        let reply1 = replies1.first ?? Acme_Featureflags_V1_ScoreFeatureFlagResponse()
        _ = reply1
        let outbound2 = Acme_Appointments_V1_CountAppointmentsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Appointments_V1_CountAppointmentsRequest.Filter.with {
                $0.createdAfter = reply0.carePlan.audit.updatedAt
                $0.ownerID = input.clinicSlot.clinicSlotID
                $0.region = input.clinicSlot.location.region
            }
        }
        let reply2 = try await self.approveClinicSlotStep2.execute(outbound2)
        let outbound3 = Acme_Appointments_V1_ListPendingAppointmentsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Appointments_V1_ListPendingAppointmentsRequest.Filter.with {
                $0.createdAfter = reply0.carePlan.audit.createdAt
                $0.ownerID = reply0.result.correlationID
                $0.region = reply0.carePlan.billingAddress.region
            }
        }
        let port3 = RPCOperations.port { (request: Acme_Appointments_V1_ListPendingAppointmentsRequest) in
            try await self.appointmentsAppointmentApproval.listPendingAppointments(request)
        }
        let reply3 = try await port3.execute(outbound3)
        return Acme_Appointments_V1_ApproveClinicSlotResponse.with {
            $0.clinicSlot = Acme_Appointments_V1_ClinicSlot.with {
                $0.clinicSlotID = input.clinicSlotID
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.recipient = reply0.carePlan.billingAddress.recipient
                }
                $0.metadata = input.clinicSlot.metadata
            }
            $0.outcome = Acme_Appointments_V1_ApproveClinicSlotResponse.Outcome.with {
                $0.message = reply2.result.message
                $0.status = reply2.result.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply3.result.details
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processCommentClinicSlotApproval(_ input: Acme_Appointments_V1_CommentClinicSlotApprovalRequest) async throws
        -> Acme_Appointments_V1_CommentClinicSlotApprovalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.clinicSlot.audit.etag)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "clinic_slot",
            action: "audit", detail: input.clinicSlot.audit.etag
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "CommentClinicSlotApproval",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try ClinicSlotRecord(input.clinicSlot, tenant: input.context.tenantID)
        try await store.save(record.stored)
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        let outbound0 = Acme_Featureflags_V1_ExplainFeatureFlagDecisionRequest.with {
            $0.context = input.context
            $0.details = Acme_Featureflags_V1_ExplainFeatureFlagDecisionRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.approver.email
                }
            }
            $0.featureFlag = Acme_Featureflags_V1_FeatureFlag.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = input.clinicSlot.audit.createdBy
                }
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.email = input.clinicSlot.organizer.email
                    $0.userID = input.clinicSlot.organizer.userID
                }
            }
        }
        let reply0 = try await self.commentClinicSlotApprovalStep0(outbound0)
        let requests1 = input.clinicSlot.participants.map { element in
            Acme_Appointments_V1_DelegateProviderApprovalRequest.with {
                $0.context = input.context
                $0.details = Acme_Appointments_V1_DelegateProviderApprovalRequest.Details.with {
                    $0.approver = Acme_Identity_V1_UserRef.with {
                        $0.email = element.contact.email
                    }
                }
                $0.provider = Acme_Appointments_V1_Provider.with {
                    $0.contact = Acme_Common_V1_ContactInfo.with {
                        $0.name = element.contact.name
                    }
                }
            }
        }
        let replies1 = try await FanOut.map(requests1) { candidate in
            try await self.appointmentsProviderApproval.delegateProviderApproval(candidate)
        }
        let reply1 = replies1.first ?? Acme_Appointments_V1_DelegateProviderApprovalResponse()
        _ = reply1
        return Acme_Appointments_V1_CommentClinicSlotApprovalResponse.with {
            $0.clinicSlot = Acme_Appointments_V1_ClinicSlot.with {
                $0.clinicSlotID = input.clinicSlotID
                $0.window = input.clinicSlot.window
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processDelegateClinicSlotApproval(_ input: Acme_Appointments_V1_DelegateClinicSlotApprovalRequest) async throws
        -> Acme_Appointments_V1_DelegateClinicSlotApprovalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.clinicSlot.audit.createdBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "clinic_slot",
            action: "audit", detail: input.clinicSlot.audit.createdBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "DelegateClinicSlotApproval",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try ClinicSlotRecord(input.clinicSlot, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Appointments_V1_EscalateProviderRequest.with {
            $0.context = input.context
            $0.provider = Acme_Appointments_V1_Provider.with {
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = input.clinicSlot.location.countryCode
                }
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.clinicSlot.organizer.displayName
                    $0.email = input.details.approver.email
                }
            }
        }
        guard
            let execute0 = self.delegateClinicSlotApprovalStep0[settings.region]
                ?? self.delegateClinicSlotApprovalStep0["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply0 = try await execute0(outbound0)
        let outbound1 = Acme_Telematics_V1_CountTelemetryReadingsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Telematics_V1_CountTelemetryReadingsRequest.Filter.with {
                $0.region = input.clinicSlot.location.region
            }
        }
        let reply1 = try await self.telematicsTelemetryReadingQuery.countTelemetryReadings(outbound1)
        let requests2 = input.clinicSlot.participants.map { element in
            Acme_Appointments_V1_DelegateProviderApprovalRequest.with {
                $0.context = input.context
                $0.details = Acme_Appointments_V1_DelegateProviderApprovalRequest.Details.with {
                    $0.approver = Acme_Identity_V1_UserRef.with {
                        $0.email = element.contact.email
                    }
                }
                $0.provider = Acme_Appointments_V1_Provider.with {
                    $0.contact = Acme_Common_V1_ContactInfo.with {
                        $0.preferredChannel = element.contact.preferredChannel
                    }
                    $0.name = element.contact.name
                }
            }
        }
        let replies2 = try await FanOut.map(requests2) { candidate in
            try await self.appointmentsProviderApproval.delegateProviderApproval(candidate)
        }
        let reply2 = replies2.first ?? Acme_Appointments_V1_DelegateProviderApprovalResponse()
        _ = reply2
        let requests3 = input.clinicSlot.participants.map { element in
            Acme_Metrics_V1_ScoreMetricSeriesRequest.with {
                $0.context = input.context
                $0.metricSeries = Acme_Metrics_V1_MetricSeries.with {
                    $0.owner = Acme_Identity_V1_UserRef.with {
                        $0.email = element.contact.email
                        $0.userID = input.details.approver.userID
                    }
                }
            }
        }
        let replies3 = try await FanOut.map(requests3) { candidate in
            try await self.metricsMetricSeriesValidation.scoreMetricSeries(candidate)
        }
        let reply3 = replies3.first ?? Acme_Metrics_V1_ScoreMetricSeriesResponse()
        _ = reply3
        return Acme_Appointments_V1_DelegateClinicSlotApprovalResponse.with {
            $0.clinicSlot = Acme_Appointments_V1_ClinicSlot.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply0.provider.audit.createdAt
                }
                $0.clinicSlotID = input.clinicSlotID
                $0.location = input.clinicSlot.location
                $0.participants = [
                    Acme_Appointments_V1_ClinicSlotParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.preferredChannel = reply0.provider.contact.preferredChannel
                        }
                    }
                ]
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.details = reply1.result.details
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processEscalateClinicSlot(_ input: Acme_Appointments_V1_EscalateClinicSlotRequest) async throws
        -> Acme_Appointments_V1_EscalateClinicSlotResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.clinicSlot.audit.createdBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "clinic_slot",
            action: "audit", detail: input.clinicSlot.audit.createdBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "EscalateClinicSlot",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try ClinicSlotRecord(input.clinicSlot, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Careplans_V1_ListCarePlanWorkflowsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Careplans_V1_ListCarePlanWorkflowsRequest.Filter.with {
                $0.region = input.clinicSlot.location.region
            }
        }
        let envelope0 = try Google_Protobuf_Any(message: outbound0)
        let unpacked0 = try Acme_Careplans_V1_ListCarePlanWorkflowsRequest(unpackingAny: envelope0)
        let reply0 = try await self.careplansCarePlanWorkflow.listCarePlanWorkflows(unpacked0)
        let outbound1 = Acme_Appointments_V1_SuggestAppointmentsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Appointments_V1_SuggestAppointmentsRequest.Filter.with {
                $0.createdAfter = input.clinicSlot.audit.updatedAt
                $0.region = input.clinicSlot.location.region
            }
        }
        let json1 = try outbound1.jsonString()
        let decoded1 = try Acme_Appointments_V1_SuggestAppointmentsRequest(jsonString: json1)
        let reply1 = try await self.appointmentsAppointmentQuery.suggestAppointments(decoded1)
        return Acme_Appointments_V1_EscalateClinicSlotResponse.with {
            $0.clinicSlot = Acme_Appointments_V1_ClinicSlot.with {
                $0.clinicSlotID = input.clinicSlotID
                $0.title = input.clinicSlot.title
            }
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

    /// Execute the appointments workflow and project its upstream replies.
    func processListPendingClinicSlots(_ input: Acme_Appointments_V1_ListPendingClinicSlotsRequest) async throws
        -> Acme_Appointments_V1_ListPendingClinicSlotsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "clinic_slot",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ListPendingClinicSlots",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "clinic_slot",
            action: "ListPendingClinicSlots", detail: input.context.traceID
        )
        let outbound0 =
            Acme_Appointments_V1_ExplainProviderDecisionRequest.forClinicSlotApprovalEndpointListPendingClinicSlots0(
                input
            )
        let reply0 = try await self.appointmentsProviderValidation.explainProviderDecision(outbound0)
        return Acme_Appointments_V1_ListPendingClinicSlotsResponse.with {
            $0.clinicSlots = [
                Acme_Appointments_V1_ClinicSlot.with {
                    $0.participants = [
                        Acme_Appointments_V1_ClinicSlotParticipant.with {
                            $0.contact = Acme_Common_V1_ContactInfo.with {
                                $0.email = reply0.provider.relationshipManager.email
                            }
                        }
                    ]
                }
            ]
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply0.result.status
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processRecallClinicSlot(_ input: Acme_Appointments_V1_RecallClinicSlotRequest) async throws
        -> Acme_Appointments_V1_RecallClinicSlotResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.clinicSlot.audit.createdBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "clinic_slot",
            action: "audit", detail: input.clinicSlot.audit.createdBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "RecallClinicSlot",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try ClinicSlotRecord(input.clinicSlot, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Appointments_V1_LintProvidersRequest.with {
            $0.context = input.context
            $0.provider = Acme_Appointments_V1_Provider.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.clinicSlot.audit.createdAt
                }
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.lines = input.clinicSlot.location.lines
                    $0.recipient = input.clinicSlot.location.recipient
                }
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.email = input.details.approver.email
                }
            }
        }
        let reply0 = try await self.appointmentsProviderValidation.lintProviders(
            outbound0, metadata: ["x-acme-region": .string(settings.region)]
        )
        let requests1 = input.clinicSlot.participants.map { element in
            Acme_Identity_V1_CheckUserEligibilityRequest.with {
                $0.context = input.context
                $0.details = Acme_Identity_V1_CheckUserEligibilityRequest.Details.with {
                    $0.contact = Acme_Common_V1_ContactInfo.with {
                        $0.phone = element.contact.phone
                    }
                }
                $0.user = Acme_Identity_V1_User.with {
                    $0.contact = Acme_Common_V1_ContactInfo.with {
                        $0.email = element.contact.email
                        $0.preferredChannel = element.contact.preferredChannel
                    }
                }
            }
        }
        let replies1 = try await FanOut.map(requests1) { candidate in
            try await self.identityUserValidation.checkUserEligibility(candidate)
        }
        let reply1 = replies1.first ?? Acme_Identity_V1_CheckUserEligibilityResponse()
        _ = reply1
        return Acme_Appointments_V1_RecallClinicSlotResponse.with {
            $0.clinicSlot = Acme_Appointments_V1_ClinicSlot.with {
                $0.clinicSlotID = input.clinicSlotID
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.recipient = reply0.provider.primaryAddress.recipient
                }
                $0.title = input.clinicSlot.title
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processRejectClinicSlot(_ input: Acme_Appointments_V1_RejectClinicSlotRequest) async throws
        -> Acme_Appointments_V1_RejectClinicSlotResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.clinicSlot.audit.createdBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "clinic_slot",
            action: "audit", detail: input.clinicSlot.audit.createdBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "RejectClinicSlot",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try ClinicSlotRecord(input.clinicSlot, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Prescriptions_V1_ListRefillWorkflowsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Prescriptions_V1_ListRefillWorkflowsRequest.Filter.with {
                $0.createdAfter = input.details.effectiveAt
                $0.labels = input.clinicSlot.metadata
                $0.ownerID = input.details.approver.userID
                $0.region = input.clinicSlot.location.region
            }
        }
        let reply0 = try await RPCOperations.call(outbound0) { request in
            try await self.prescriptionsRefillWorkflow.listRefillWorkflows(request)
        }
        let outbound1 = Acme_Appointments_V1_CountAppointmentsRequest.with {
            $0.context = Projection.read(input, at: \Acme_Appointments_V1_RejectClinicSlotRequest.context)
            $0.filter = Acme_Appointments_V1_CountAppointmentsRequest.Filter.with {
                $0.createdAfter = Projection.read(
                    input, at: \Acme_Appointments_V1_RejectClinicSlotRequest.clinicSlot.audit.updatedAt)
                $0.labels = input.clinicSlot.metadata
                $0.ownerID = Projection.read(
                    input, at: \Acme_Appointments_V1_RejectClinicSlotRequest.clinicSlot.organizer.userID)
                $0.region = Projection.read(
                    input, at: \Acme_Appointments_V1_RejectClinicSlotRequest.clinicSlot.location.region)
            }
        }
        let reply1 = try await self.appointmentsAppointmentQuery.countAppointments(outbound1)
        return Acme_Appointments_V1_RejectClinicSlotResponse.with {
            $0.clinicSlot = Acme_Appointments_V1_ClinicSlot.with {
                $0.clinicSlotID = input.clinicSlotID
                $0.organizer = input.clinicSlot.organizer
            }
            $0.outcome = Acme_Appointments_V1_RejectClinicSlotResponse.Outcome.with {
                $0.status = reply0.result.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = Projection.firstValue(
                    [
                        reply0.result.message,
                        reply1.result.message,
                    ], default: .init())
                $0.status = reply1.result.status
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processSubmitClinicSlot(_ input: Acme_Appointments_V1_SubmitClinicSlotRequest) async throws
        -> Acme_Appointments_V1_SubmitClinicSlotResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.clinicSlot.audit.createdBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "clinic_slot",
            action: "audit", detail: input.clinicSlot.audit.createdBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SubmitClinicSlot",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try ClinicSlotRecord(input.clinicSlot, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let selection0_3: Int32
        switch input.clinicSlot.recurrence {
        case .weekly(let weekly):
            selection0_3 = weekly.interval
        default: selection0_3 = .init()
        }
        let outbound0 = Acme_Telehealth_V1_AdvanceVideoVisitWorkflowRequest.with {
            $0.context = input.context
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.clinicSlot.organizer.displayName
                    $0.userID = input.details.approver.userID
                }
                $0.weekly = Acme_Telehealth_V1_VideoVisitWeeklyRule.with {
                    $0.interval = selection0_3
                }
            }
        }
        let reply0 = try await self.telehealthVideoVisitWorkflow.advanceVideoVisitWorkflow(outbound0)
        let outbound1 = Acme_Prescriptions_V1_GenerateRefillReportRequest.with {
            $0.annotations = input.annotations
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_GenerateRefillReportRequest.Details.with {
                $0.period = input.clinicSlot.window
            }
            $0.reason = input.reason
        }
        let step1: @Sendable () async throws -> Acme_Prescriptions_V1_GenerateRefillReportResponse = {
            try await self.prescriptionsRefillReporting.generateRefillReport(outbound1)
        }
        let reply1 = try await step1()
        var outbound2 = Acme_Documents_V1_CreateDocumentRequest()
        outbound2.context = input.context
        outbound2.document = Acme_Documents_V1_Document.with {
            $0.counterparty = Acme_Documents_V1_DocumentFolderRef.with {
                $0.displayName = reply0.videoVisit.organizer.displayName
            }
        }
        let reply2 = try await self.documentsDocument.createDocument(outbound2)
        return Acme_Appointments_V1_SubmitClinicSlotResponse.with {
            $0.clinicSlot = Acme_Appointments_V1_ClinicSlot.with {
                $0.clinicSlotID = input.clinicSlotID
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.lines = reply2.document.billingAddress.lines
                    $0.region = reply2.document.billingAddress.region
                }
                $0.metadata = input.clinicSlot.metadata
            }
            $0.outcome = Acme_Appointments_V1_SubmitClinicSlotResponse.Outcome.with {
                $0.message = reply1.result.message
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply0.result.referenceIds + reply1.result.referenceIds
                $0.status = "ok"
            }
        }
    }
}
