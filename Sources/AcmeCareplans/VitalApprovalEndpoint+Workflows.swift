import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension VitalApprovalEndpoint {
    /// Approves a vital.
    func approveVital(
        request: ServerRequest<Acme_Careplans_V1_ApproveVitalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_ApproveVitalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processApproveVital(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Comments a vital.
    func commentVitalApproval(
        request: ServerRequest<Acme_Careplans_V1_CommentVitalApprovalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_CommentVitalApprovalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCommentVitalApproval(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Delegates a vital.
    func delegateVitalApproval(
        request: ServerRequest<Acme_Careplans_V1_DelegateVitalApprovalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_DelegateVitalApprovalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processDelegateVitalApproval(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Escalates a vital.
    func escalateVital(
        request: ServerRequest<Acme_Careplans_V1_EscalateVitalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_EscalateVitalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processEscalateVital(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a vital.
    func getVitalApprovalStatus(
        request: ServerRequest<Acme_Careplans_V1_GetVitalApprovalStatusRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_GetVitalApprovalStatusResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetVitalApprovalStatus(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists vitals a page at a time.
    func listPendingVitals(
        request: ServerRequest<Acme_Careplans_V1_ListPendingVitalsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_ListPendingVitalsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListPendingVitals(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Recalls a vital.
    func recallVital(
        request: ServerRequest<Acme_Careplans_V1_RecallVitalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_RecallVitalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRecallVital(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Rejects a vital.
    func rejectVital(
        request: ServerRequest<Acme_Careplans_V1_RejectVitalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_RejectVitalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRejectVital(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Submits a vital.
    func submitVital(
        request: ServerRequest<Acme_Careplans_V1_SubmitVitalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_SubmitVitalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSubmitVital(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processApproveVital(_ input: Acme_Careplans_V1_ApproveVitalRequest) async throws
        -> Acme_Careplans_V1_ApproveVitalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "audit", detail: input.details.approver.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ApproveVital",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VitalRecord(input.vital, tenant: input.context.tenantID)
        try await store.save(record.stored)
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
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
        let outbound0 = Acme_Careplans_V1_QuoteCarePlanRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.counterparty = Acme_Appointments_V1_AppointmentRef.with {
                    $0.appointmentID = input.vital.subject.appointmentID
                    $0.displayName = input.vital.subject.displayName
                    $0.startsAt = input.vital.subject.startsAt
                }
                $0.lines = [
                    Acme_Careplans_V1_CarePlanLine.with {
                        $0.attributes = input.vital.attributes
                    }
                ]
            }
            $0.context = input.context
        }
        let reply0 = try await self.approveVitalStep0.execute(outbound0)
        let outbound1 = Acme_Careplans_V1_RejectCareGoalRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.details.approver.userID
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply0.carePlan.audit.updatedBy
                }
                $0.customer = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = input.vital.subject.displayName
                }
            }
            $0.context = input.context
            $0.details = Acme_Careplans_V1_RejectCareGoalRequest.Details.with {
                $0.approver = Acme_Identity_V1_UserRef.with {
                    $0.email = input.details.approver.email
                }
            }
        }
        let port1 = RPCOperations.port { (request: Acme_Careplans_V1_RejectCareGoalRequest) in
            try await self.careplansCareGoalApproval.rejectCareGoal(request)
        }
        let reply1 = try await port1.execute(outbound1)
        let selection2_1: String
        switch reply0.carePlan.settlement {
        case .bank(let bank):
            selection2_1 = bank.bic
        default: selection2_1 = .init()
        }
        let outbound2 = Acme_Careplans_V1_ApproveCarePlanRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.bank = Acme_Careplans_V1_CarePlanBankSettlement.with {
                    $0.bic = selection2_1
                }
            }
            $0.context = input.context
            $0.details = Acme_Careplans_V1_ApproveCarePlanRequest.Details.with {
                $0.approver = Acme_Identity_V1_UserRef.with {
                    $0.email = reply1.careGoal.assignee.email
                }
            }
        }
        let reply2 = try await self.careplansCarePlanApproval.approveCarePlan(outbound2)
        return Acme_Careplans_V1_ApproveVitalResponse.with {
            $0.outcome = Acme_Careplans_V1_ApproveVitalResponse.Outcome.with {
                $0.referenceID = Projection.firstValue(
                    [
                        reply1.outcome.referenceID,
                        reply2.outcome.referenceID,
                    ], default: .init())
                $0.status = reply1.result.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply0.result.status
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.kind = input.vital.kind
                $0.vitalID = input.vitalID
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processCommentVitalApproval(_ input: Acme_Careplans_V1_CommentVitalApprovalRequest) async throws
        -> Acme_Careplans_V1_CommentVitalApprovalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.userID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "audit", detail: input.details.approver.userID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "CommentVitalApproval",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VitalRecord(input.vital, tenant: input.context.tenantID)
        try await store.save(record.stored)
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        let outbound0 = Acme_Careplans_V1_DelegateCarePlanApprovalRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.counterparty = Acme_Appointments_V1_AppointmentRef.with {
                    $0.appointmentID = input.vital.subject.appointmentID
                    $0.displayName = input.details.approver.displayName
                    $0.startsAt = input.vital.subject.startsAt
                }
            }
            $0.context = input.context
            $0.details = Acme_Careplans_V1_DelegateCarePlanApprovalRequest.Details.with {
                $0.approver = Acme_Identity_V1_UserRef.with {
                    $0.email = input.details.approver.email
                }
            }
        }
        let reply0 = try await self.commentVitalApprovalStep0(outbound0)
        let outbound1 = Acme_Metrics_V1_NormalizeMetricSeriesRequest.with {
            $0.context = input.context
            $0.metricSeries = Acme_Metrics_V1_MetricSeries.with {
                $0.address = Acme_Common_V1_PostalAddress.with {
                    $0.lines = reply0.carePlan.billingAddress.lines
                }
            }
        }
        guard
            let execute1 = self.commentVitalApprovalStep1[settings.region] ?? self.commentVitalApprovalStep1["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply1 = try await execute1(outbound1)
        let requests2 = input.vital.measurements.map { element in
            Acme_Notifications_V1_SearchNotificationsRequest.with {
                $0.context = input.context
                $0.filter = Acme_Notifications_V1_SearchNotificationsRequest.Filter.with {
                    $0.createdAfter = element.observedAt
                    $0.labels = reply1.metricSeries.specs
                    $0.ownerID = input.vital.subject.appointmentID
                    $0.region = reply1.metricSeries.address.region
                }
            }
        }
        let replies2 = try await FanOut.map(requests2) { candidate in
            try await self.notificationsNotification.searchNotifications(candidate)
        }
        let reply2 = replies2.first ?? Acme_Notifications_V1_SearchNotificationsResponse()
        let outbound3 = Acme_Telematics_V1_ExplainTelemetryReadingCalculationRequest.with {
            $0.context = input.context
            $0.telemetryReading = Acme_Telematics_V1_TelemetryReading.with {
                $0.correlationID = reply2.result.correlationID
                $0.kind = input.vital.kind
                $0.measurements = [
                    Acme_Telematics_V1_TelemetryReadingMeasurement.with {
                        $0.unit = reply1.metricSeries.dimensions.unit
                    }
                ]
                $0.subject = Acme_Telematics_V1_GeoFenceRef.with {
                    $0.displayName = reply0.carePlan.counterparty.displayName
                }
            }
        }
        let reply3 = try await self.telematicsTelemetryReadingCalculation.explainTelemetryReadingCalculation(outbound3)
        return Acme_Careplans_V1_CommentVitalApprovalResponse.with {
            $0.outcome = Acme_Careplans_V1_CommentVitalApprovalResponse.Outcome.with {
                $0.status = reply1.outcome.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.kind = input.vital.kind
                $0.occurredAt = reply3.telemetryReading.occurredAt
                $0.subject = Acme_Appointments_V1_AppointmentRef.with {
                    $0.displayName = reply0.carePlan.counterparty.displayName
                    $0.startsAt = reply0.carePlan.counterparty.startsAt
                }
                $0.vitalID = input.vitalID
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processDelegateVitalApproval(_ input: Acme_Careplans_V1_DelegateVitalApprovalRequest) async throws
        -> Acme_Careplans_V1_DelegateVitalApprovalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "audit", detail: input.details.approver.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "DelegateVitalApproval",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VitalRecord(input.vital, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Patients_V1_RecalculatePatientsRequest.with {
            $0.context = input.context
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.details.approver.userID
                }
            }
        }
        let envelope0 = try Google_Protobuf_Any(message: outbound0)
        let unpacked0 = try Acme_Patients_V1_RecalculatePatientsRequest(unpackingAny: envelope0)
        let reply0 = try await self.patientsPatientCalculation.recalculatePatients(unpacked0)
        return Acme_Careplans_V1_DelegateVitalApprovalResponse.with {
            $0.outcome = Acme_Careplans_V1_DelegateVitalApprovalResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.correlationID = reply0.result.correlationID
                $0.vitalID = input.vitalID
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processEscalateVital(_ input: Acme_Careplans_V1_EscalateVitalRequest) async throws
        -> Acme_Careplans_V1_EscalateVitalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "audit", detail: input.details.approver.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "EscalateVital",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VitalRecord(input.vital, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let requests0 = input.vital.measurements.map { element in
            Acme_Appointments_V1_ListAppointmentsRequest.with {
                $0.context = input.context
                $0.filter = Acme_Appointments_V1_ListAppointmentsRequest.Filter.with {
                    $0.createdAfter = element.observedAt
                    $0.labels = input.annotations
                    $0.ownerID = input.vital.subject.appointmentID
                }
            }
        }
        let replies0 = try await FanOut.map(requests0) { candidate in
            try await self.appointmentsAppointment.listAppointments(candidate)
        }
        let reply0 = replies0.first ?? Acme_Appointments_V1_ListAppointmentsResponse()
        _ = reply0
        let outbound1 = Acme_Careplans_V1_CompareCareGoalOptionsRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.vital.subject.displayName
                }
            }
            $0.context = input.context
        }
        let json1 = try outbound1.jsonString()
        let decoded1 = try Acme_Careplans_V1_CompareCareGoalOptionsRequest(jsonString: json1)
        let reply1 = try await self.careplansCareGoalCalculation.compareCareGoalOptions(decoded1)
        return Acme_Careplans_V1_EscalateVitalResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply1.result.referenceIds
                $0.status = "ok"
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.correlationID = input.vital.correlationID
                $0.subject = Acme_Appointments_V1_AppointmentRef.with {
                    $0.displayName = reply1.careGoal.assignee.displayName
                }
                $0.vitalID = input.vitalID
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processGetVitalApprovalStatus(_ input: Acme_Careplans_V1_GetVitalApprovalStatusRequest) async throws
        -> Acme_Careplans_V1_GetVitalApprovalStatusResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "GetVitalApprovalStatus",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "GetVitalApprovalStatus", detail: input.context.traceID
        )
        let outbound0 = Acme_Prescriptions_V1_FindPrescriptionsRequest.forVitalApprovalEndpointGetVitalApprovalStatus0(
            input
        )
        let reply0 = try await self.prescriptionsPrescriptionQuery.findPrescriptions(outbound0)
        let outbound1 = Acme_Careplans_V1_CompareVitalOptionsRequest.with {
            $0.context = input.context
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.attributes = reply0.result.details
                $0.correlationID = reply0.result.correlationID
                $0.occurredAt = input.context.deadline
                $0.vitalID = input.vitalID
            }
        }
        let reply1 = try await self.careplansVitalCalculation.compareVitalOptions(
            outbound1, metadata: ["x-acme-region": .string(settings.region)]
        )
        return Acme_Careplans_V1_GetVitalApprovalStatusResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply0.result.status
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.correlationID = reply1.result.correlationID
                $0.vitalID = input.vitalID
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processListPendingVitals(_ input: Acme_Careplans_V1_ListPendingVitalsRequest) async throws
        -> Acme_Careplans_V1_ListPendingVitalsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.query)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "audit", detail: input.filter.query
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ListPendingVitals",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "ListPendingVitals", detail: input.context.traceID
        )
        let outbound0 = Acme_Careplans_V1_ApproveCareGoalRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.externalReference = input.filter.ownerID
                $0.history = [
                    Acme_Careplans_V1_CareGoalStatusChange.with {
                        $0.changedAt = input.filter.createdAfter
                    }
                ]
            }
            $0.context = input.context
            $0.details = Acme_Careplans_V1_ApproveCareGoalRequest.Details.with {
                $0.approver = Acme_Identity_V1_UserRef.with {
                    $0.email = input.context.actor.email
                    $0.userID = input.context.actor.userID
                }
            }
        }
        let reply0 = try await RPCOperations.call(outbound0) { request in
            try await self.careplansCareGoalApproval.approveCareGoal(request)
        }
        return Acme_Careplans_V1_ListPendingVitalsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.vitals = [
                Acme_Careplans_V1_Vital.with {
                    $0.correlationID = reply0.result.correlationID
                    $0.subject = Acme_Appointments_V1_AppointmentRef.with {
                        $0.displayName = reply0.careGoal.assignee.displayName
                    }
                }
            ]
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processRecallVital(_ input: Acme_Careplans_V1_RecallVitalRequest) async throws
        -> Acme_Careplans_V1_RecallVitalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "audit", detail: input.details.approver.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "RecallVital",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VitalRecord(input.vital, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Careplans_V1_StartCarePlanWorkflowRequest.with {
            $0.annotations = input.annotations
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.counterparty = Acme_Appointments_V1_AppointmentRef.with {
                    $0.appointmentID = Projection.read(
                        input, at: \Acme_Careplans_V1_RecallVitalRequest.vital.subject.appointmentID)
                    $0.displayName = Projection.read(
                        input, at: \Acme_Careplans_V1_RecallVitalRequest.vital.subject.displayName)
                }
                $0.lines = [
                    Acme_Careplans_V1_CarePlanLine.with {
                        $0.attributes = input.vital.attributes
                    }
                ]
            }
            $0.context = Projection.read(input, at: \Acme_Careplans_V1_RecallVitalRequest.context)
        }
        let reply0 = try await self.careplansCarePlanWorkflow.startCarePlanWorkflow(outbound0)
        let requests1 = input.vital.measurements.map { element in
            Acme_Prescriptions_V1_QuoteRefillRequest.with {
                $0.context = input.context
                $0.details = Acme_Prescriptions_V1_QuoteRefillRequest.Details.with {
                    $0.destination = Acme_Common_V1_PostalAddress.with {
                        $0.countryCode = reply0.carePlan.billingAddress.countryCode
                        $0.recipient = reply0.carePlan.billingAddress.recipient
                    }
                }
                $0.refill = Acme_Prescriptions_V1_Refill.with {
                    $0.audit = Acme_Common_V1_AuditInfo.with {
                        $0.updatedAt = reply0.carePlan.audit.updatedAt
                    }
                    $0.comments = [
                        Acme_Prescriptions_V1_RefillComment.with {
                            $0.createdAt = element.observedAt
                        }
                    ]
                }
            }
        }
        let replies1 = try await FanOut.map(requests1) { candidate in
            try await self.prescriptionsRefillCalculation.quoteRefill(candidate)
        }
        let reply1 = replies1.first ?? Acme_Prescriptions_V1_QuoteRefillResponse()
        _ = reply1
        let requests2 = input.vital.measurements.map { element in
            Acme_Featureflags_V1_CountFeatureFlagsRequest.with {
                $0.context = input.context
                $0.filter = Acme_Featureflags_V1_CountFeatureFlagsRequest.Filter.with {
                    $0.createdAfter = element.observedAt
                }
            }
        }
        let replies2 = try await FanOut.map(requests2) { candidate in
            try await self.featureflagsFeatureFlagQuery.countFeatureFlags(candidate)
        }
        let reply2 = replies2.first ?? Acme_Featureflags_V1_CountFeatureFlagsResponse()
        _ = reply2
        return Acme_Careplans_V1_RecallVitalResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.source = input.vital.source
                $0.subject = Acme_Appointments_V1_AppointmentRef.with {
                    $0.appointmentID = reply0.carePlan.counterparty.appointmentID
                    $0.displayName = reply0.carePlan.counterparty.displayName
                }
                $0.vitalID = input.vitalID
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processRejectVital(_ input: Acme_Careplans_V1_RejectVitalRequest) async throws
        -> Acme_Careplans_V1_RejectVitalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.comment)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "audit", detail: input.details.comment
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "RejectVital",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VitalRecord(input.vital, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Prescriptions_V1_ExplainMedicationCalculationRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_ExplainMedicationCalculationRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.approverEmail
                }
            }
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.details.approver.displayName
                    $0.email = input.details.approver.email
                    $0.userID = input.details.approver.userID
                }
            }
        }
        let step0: @Sendable () async throws -> Acme_Prescriptions_V1_ExplainMedicationCalculationResponse = {
            try await self.prescriptionsMedicationCalculation.explainMedicationCalculation(outbound0)
        }
        let reply0 = try await step0()
        var outbound1 = Acme_Careplans_V1_ShareVitalReportRequest()
        outbound1.context = input.context
        outbound1.details = Acme_Careplans_V1_ShareVitalReportRequest.Details.with {
            $0.recipient = Acme_Common_V1_ContactInfo.with {
                $0.email = input.details.approver.email
            }
        }
        let reply1 = try await self.careplansVitalReporting.shareVitalReport(outbound1)
        return Acme_Careplans_V1_RejectVitalResponse.with {
            $0.outcome = Acme_Careplans_V1_RejectVitalResponse.Outcome.with {
                $0.referenceID = reply0.outcome.referenceID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.result.message
                $0.status = "ok"
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.kind = input.vital.kind
                $0.occurredAt = reply1.vital.occurredAt
                $0.vitalID = input.vitalID
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processSubmitVital(_ input: Acme_Careplans_V1_SubmitVitalRequest) async throws
        -> Acme_Careplans_V1_SubmitVitalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "audit", detail: input.details.approver.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SubmitVital",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VitalRecord(input.vital, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Identity_V1_WatchUsersRequest.with {
            $0.context = input.context
            $0.filter = Acme_Identity_V1_WatchUsersRequest.Filter.with {
                $0.createdAfter = input.details.effectiveAt
                $0.ownerID = input.vital.subject.appointmentID
            }
            $0.subscriber = Acme_Common_V1_ContactInfo.with {
                $0.email = input.details.approver.email
            }
        }
        let reply0 = try await self.identityUser.watchUsers(outbound0) { response in
            var latest = Acme_Identity_V1_WatchUsersResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        _ = reply0
        let outbound1 = Acme_Careplans_V1_ListPendingCarePlansRequest.with {
            $0.context = input.context
            $0.filter = Acme_Careplans_V1_ListPendingCarePlansRequest.Filter.with {
                $0.createdAfter = input.vital.subject.startsAt
                $0.labels = input.annotations
                $0.ownerID = input.vital.subject.appointmentID
            }
        }
        let reply1 = try await RPCOperations.read {
            try await self.careplansCarePlanApproval.listPendingCarePlans(outbound1)
        }
        return Acme_Careplans_V1_SubmitVitalResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.status = "ok"
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.correlationID = reply1.result.correlationID
                $0.sequence = input.vital.sequence
                $0.vitalID = input.vitalID
            }
        }
    }
}
