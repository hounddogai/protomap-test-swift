import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension VitalWorkflowEndpoint {
    /// Execute the careplans workflow and project its upstream replies.
    func processAdvanceVitalWorkflow(_ input: Acme_Careplans_V1_AdvanceVitalWorkflowRequest) async throws
        -> Acme_Careplans_V1_AdvanceVitalWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "audit", detail: input.details.initiatedBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "AdvanceVitalWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VitalRecord(input.vital, tenant: input.context.tenantID)
        try await store.save(record.stored)
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        let importFrame = Acme_Telehealth_V1_BatchCreateVideoVisitsRequest.with {
            $0.context = input.context
        }
        _ = try await self.telehealthVideoVisit.batchCreateVideoVisits { writer in
            try await writer.write(importFrame)
        }
        let outbound0 = Acme_Careplans_V1_ExplainVitalCalculationRequest.with {
            $0.context = input.context
            $0.details = Acme_Careplans_V1_ExplainVitalCalculationRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.notify.email
                    $0.preferredChannel = input.details.notify.preferredChannel
                }
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.source = input.vital.source
                $0.subject = Acme_Appointments_V1_AppointmentRef.with {
                    $0.displayName = input.vital.subject.displayName
                }
            }
        }
        let envelope0 = try Google_Protobuf_Any(message: outbound0)
        let unpacked0 = try Acme_Careplans_V1_ExplainVitalCalculationRequest(unpackingAny: envelope0)
        let reply0 = try await self.careplansVitalCalculation.explainVitalCalculation(unpacked0)
        let outbound1 = Acme_Patients_V1_ResolvePatientsRequest.with {
            $0.context = input.context
        }
        let json1 = try outbound1.jsonString()
        let decoded1 = try Acme_Patients_V1_ResolvePatientsRequest(jsonString: json1)
        let reply1 = try await self.patientsPatientQuery.resolvePatients(decoded1)
        return Acme_Careplans_V1_AdvanceVitalWorkflowResponse.with {
            $0.outcome = Acme_Careplans_V1_AdvanceVitalWorkflowResponse.Outcome.with {
                $0.message = reply1.result.message
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.outcome.message
                $0.status = "ok"
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.correlationID = reply1.result.correlationID
                $0.occurredAt = input.vital.occurredAt
                $0.subject = input.vital.subject
                $0.vitalID = reply0.vital.vitalID
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processCancelVitalWorkflow(_ input: Acme_Careplans_V1_CancelVitalWorkflowRequest) async throws
        -> Acme_Careplans_V1_CancelVitalWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "audit", detail: input.details.initiatedBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "CancelVitalWorkflow",
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
        let outbound0 = Acme_Careplans_V1_StartCarePlanWorkflowRequest.forVitalWorkflowEndpointCancelVitalWorkflow0(
            input
        )
        let reply0 = try await self.careplansCarePlanWorkflow.startCarePlanWorkflow(outbound0)
        let outbound1 = Acme_Identity_V1_LookupUserRequest.with {
            $0.context = input.context
            $0.userID = input.context.actor.userID
        }
        let reply1 = try await self.identityUserQuery.lookupUser(
            outbound1, metadata: ["x-acme-region": .string(settings.region)]
        )
        let selection2_1: String
        switch reply0.carePlan.settlement {
        case .card(let card):
            selection2_1 = card.last4
        default: selection2_1 = .init()
        }
        let outbound2 = Acme_Careplans_V1_SubmitCarePlanRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply0.carePlan.audit.updatedBy
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = reply0.carePlan.billingAddress.region
                }
                $0.card = Acme_Careplans_V1_CarePlanCardSettlement.with {
                    $0.last4 = selection2_1
                }
            }
            $0.context = input.context
            $0.details = Acme_Careplans_V1_SubmitCarePlanRequest.Details.with {
                $0.approver = Acme_Identity_V1_UserRef.with {
                    $0.email = reply1.user.contact.email
                }
            }
        }
        let reply2 = try await self.careplansCarePlanApproval.submitCarePlan(outbound2)
        return Acme_Careplans_V1_CancelVitalWorkflowResponse.with {
            $0.outcome = Acme_Careplans_V1_CancelVitalWorkflowResponse.Outcome.with {
                $0.message = reply1.result.message
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply2.result.message
                $0.status = reply0.result.status
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.kind = input.vital.kind
                $0.subject = Acme_Appointments_V1_AppointmentRef.with {
                    $0.appointmentID = reply0.carePlan.counterparty.appointmentID
                    $0.displayName = reply1.user.relationshipManager.displayName
                }
                $0.vitalID = input.vitalID
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processInspectVitalWorkflow(_ input: Acme_Careplans_V1_InspectVitalWorkflowRequest) async throws
        -> Acme_Careplans_V1_InspectVitalWorkflowResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "InspectVitalWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "InspectVitalWorkflow", detail: input.context.traceID
        )
        let outbound0 = Acme_Budgeting_V1_FindBudgetsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Budgeting_V1_FindBudgetsRequest.Filter.with {
                $0.createdAfter = input.context.deadline
                $0.labels = input.context.baggage
                $0.ownerID = input.vitalID
            }
        }
        let reply0 = try await RPCOperations.call(outbound0) { request in
            try await self.budgetingBudgetQuery.findBudgets(request)
        }
        return Acme_Careplans_V1_InspectVitalWorkflowResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.status = "ok"
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.vitalID = input.vitalID
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processListVitalWorkflows(_ input: Acme_Careplans_V1_ListVitalWorkflowsRequest) async throws
        -> Acme_Careplans_V1_ListVitalWorkflowsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ListVitalWorkflows",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "ListVitalWorkflows", detail: input.context.traceID
        )
        let outbound0 = Acme_Prescriptions_V1_EstimateRefillRequest.with {
            $0.context = Projection.read(input, at: \Acme_Careplans_V1_ListVitalWorkflowsRequest.context)
            $0.details = Acme_Prescriptions_V1_EstimateRefillRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.region = Projection.read(input, at: \Acme_Careplans_V1_ListVitalWorkflowsRequest.filter.region)
                }
            }
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.email = Projection.read(
                        input, at: \Acme_Careplans_V1_ListVitalWorkflowsRequest.context.actor.email)
                    $0.userID = Projection.read(
                        input, at: \Acme_Careplans_V1_ListVitalWorkflowsRequest.context.actor.userID)
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = Projection.read(
                        input, at: \Acme_Careplans_V1_ListVitalWorkflowsRequest.filter.createdAfter)
                }
            }
        }
        let reply0 = try await self.prescriptionsRefillCalculation.estimateRefill(outbound0)
        let outbound1 = Acme_Patients_V1_CalculatePatientRequest.with {
            $0.context = input.context
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply0.refill.audit.createdBy
                }
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply0.refill.assignee.displayName
                    $0.email = reply0.refill.assignee.email
                }
            }
        }
        let step1: @Sendable () async throws -> Acme_Patients_V1_CalculatePatientResponse = {
            try await self.patientsPatientCalculation.calculatePatient(outbound1)
        }
        let reply1 = try await step1()
        return Acme_Careplans_V1_ListVitalWorkflowsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.details = reply0.result.details
                $0.status = "ok"
            }
            $0.vitals = [
                Acme_Careplans_V1_Vital.with {
                    $0.attributes = reply1.patient.attributes
                    $0.correlationID = reply0.result.correlationID
                }
            ]
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processPauseVitalWorkflow(_ input: Acme_Careplans_V1_PauseVitalWorkflowRequest) async throws
        -> Acme_Careplans_V1_PauseVitalWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "audit", detail: input.details.initiatedBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "PauseVitalWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VitalRecord(input.vital, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let requests0 = input.vital.measurements.map { element in
            Acme_Telehealth_V1_EstimateTriageRequest.with {
                $0.context = input.context
                $0.triage = Acme_Telehealth_V1_Triage.with {
                    $0.customer = Acme_Telehealth_V1_VideoVisitRef.with {
                        $0.startsAt = element.observedAt
                    }
                    $0.requester = Acme_Common_V1_ContactInfo.with {
                        $0.email = input.details.notify.email
                        $0.phone = input.details.notify.phone
                    }
                }
            }
        }
        let replies0 = try await FanOut.map(requests0) { candidate in
            try await self.telehealthTriageCalculation.estimateTriage(candidate)
        }
        let reply0 = replies0.first ?? Acme_Telehealth_V1_EstimateTriageResponse()
        _ = reply0
        return Acme_Careplans_V1_PauseVitalWorkflowResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.attributes = input.vital.attributes
                $0.vitalID = input.vitalID
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processResumeVitalWorkflow(_ input: Acme_Careplans_V1_ResumeVitalWorkflowRequest) async throws
        -> Acme_Careplans_V1_ResumeVitalWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "audit", detail: input.details.initiatedBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ResumeVitalWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VitalRecord(input.vital, tenant: input.context.tenantID)
        try await store.save(record.stored)
        var outbound0 = Acme_Careplans_V1_RenewVitalRequest()
        outbound0.context = input.context
        outbound0.details = Acme_Careplans_V1_RenewVitalRequest.Details.with {
            $0.notifyContact = Acme_Common_V1_ContactInfo.with {
                $0.preferredChannel = input.details.notify.preferredChannel
            }
        }
        outbound0.vitalID = input.vital.vitalID
        let reply0 = try await self.careplansVitalLifecycle.renewVital(outbound0)
        return Acme_Careplans_V1_ResumeVitalWorkflowResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.kind = input.vital.kind
                $0.occurredAt = reply0.vital.occurredAt
                $0.vitalID = input.vitalID
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processRetryVitalWorkflow(_ input: Acme_Careplans_V1_RetryVitalWorkflowRequest) async throws
        -> Acme_Careplans_V1_RetryVitalWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "audit", detail: input.details.initiatedBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "RetryVitalWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VitalRecord(input.vital, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Careplans_V1_SignalCarePlanWorkflowRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.counterparty = Acme_Appointments_V1_AppointmentRef.with {
                    $0.appointmentID = input.vital.subject.appointmentID
                }
            }
            $0.context = input.context
            $0.details = Acme_Careplans_V1_SignalCarePlanWorkflowRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.notify.email
                    $0.name = input.details.notify.name
                }
            }
        }
        let step0: @Sendable () async throws -> Acme_Careplans_V1_SignalCarePlanWorkflowResponse = {
            try await self.careplansCarePlanWorkflow.signalCarePlanWorkflow(outbound0)
        }
        let reply0 = try await step0()
        let outbound1 = Acme_Notifications_V1_ValidateNotificationRequest.with {
            $0.context = input.context
            $0.notification = Acme_Notifications_V1_Notification.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply0.carePlan.audit.createdBy
                    $0.updatedBy = reply0.carePlan.audit.updatedBy
                }
                $0.customer = Acme_Notifications_V1_NotificationTemplateRef.with {
                    $0.displayName = input.vital.subject.displayName
                }
            }
        }
        let reply1 = try await self.notificationsNotificationValidation.validateNotification(outbound1)
        let outbound2 = Acme_Prescriptions_V1_QuoteRefillRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_QuoteRefillRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = reply0.carePlan.billingAddress.countryCode
                }
            }
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply1.notification.audit.updatedAt
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.preferredChannel = reply1.notification.requester.preferredChannel
                }
            }
        }
        async let remote2 = self.prescriptionsRefillCalculation.quoteRefill(outbound2)
        async let persisted2 = store.count(tenant: input.context.tenantID)
        let (reply2, count2) = try await (remote2, persisted2)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count2)])
        return Acme_Careplans_V1_RetryVitalWorkflowResponse.with {
            $0.outcome = Acme_Careplans_V1_RetryVitalWorkflowResponse.Outcome.with {
                $0.nextSteps = reply1.outcome.nextSteps
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply2.result.correlationID
                $0.details = reply2.result.details
                $0.message = reply0.outcome.message
                $0.status = Projection.firstValue(
                    [
                        reply0.outcome.status,
                        reply1.result.status,
                    ], default: .init())
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.source = input.vital.source
                $0.vitalID = input.vitalID
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processStartVitalWorkflow(_ input: Acme_Careplans_V1_StartVitalWorkflowRequest) async throws
        -> Acme_Careplans_V1_StartVitalWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "audit", detail: input.details.initiatedBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "StartVitalWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VitalRecord(input.vital, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Careplans_V1_SignalCarePlanWorkflowRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.counterparty = Acme_Appointments_V1_AppointmentRef.with {
                    $0.startsAt = input.vital.subject.startsAt
                }
            }
            $0.context = input.context
        }
        let reply0 = try await self.startVitalWorkflowStep0.execute(outbound0)
        let outbound1 = Acme_Telehealth_V1_ValidateVideoVisitRequest.with {
            $0.context = input.context
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = reply0.carePlan.billingAddress.postalCode
                }
            }
        }
        let port1 = RPCOperations.port { (request: Acme_Telehealth_V1_ValidateVideoVisitRequest) in
            try await self.telehealthVideoVisitValidation.validateVideoVisit(request)
        }
        let reply1 = try await port1.execute(outbound1)
        return Acme_Careplans_V1_StartVitalWorkflowResponse.with {
            $0.outcome = Acme_Careplans_V1_StartVitalWorkflowResponse.Outcome.with {
                $0.effectiveAt = reply1.outcome.effectiveAt
                $0.nextSteps = reply0.outcome.nextSteps
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.correlationID = reply1.result.correlationID
                $0.kind = input.vital.kind
                $0.vitalID = input.vitalID
            }
        }
    }
}
