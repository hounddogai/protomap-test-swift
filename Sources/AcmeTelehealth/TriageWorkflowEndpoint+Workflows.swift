import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension TriageWorkflowEndpoint {
    /// Execute the telehealth workflow and project its upstream replies.
    func processAdvanceTriageWorkflow(_ input: Acme_Telehealth_V1_AdvanceTriageWorkflowRequest) async throws
        -> Acme_Telehealth_V1_AdvanceTriageWorkflowResponse
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
            "AdvanceTriageWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try TriageRecord(input.triage, tenant: input.context.tenantID)
        try await store.save(record.stored)
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        let importFrame = Acme_Patients_V1_BatchCreatePatientsRequest.with {
            $0.context = input.context
        }
        _ = try await self.patientsPatient.batchCreatePatients { writer in
            try await writer.write(importFrame)
        }
        let selection0_2: String
        switch input.triage.origin {
        case .customer(let customer):
            selection0_2 = customer.displayName
        default: selection0_2 = .init()
        }
        let outbound0 = Acme_Careplans_V1_AdvanceVitalWorkflowRequest.with {
            $0.context = input.context
            $0.details = Acme_Careplans_V1_AdvanceVitalWorkflowRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.phone = input.details.notify.phone
                    $0.preferredChannel = input.details.notify.preferredChannel
                }
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.subject = Acme_Appointments_V1_AppointmentRef.with {
                    $0.displayName = selection0_2
                }
            }
        }
        let reply0 = try await self.careplansVitalWorkflow.advanceVitalWorkflow(outbound0)
        return Acme_Telehealth_V1_AdvanceTriageWorkflowResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.status = "ok"
            }
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.assignee = input.triage.assignee
                $0.triageID = input.triageID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processCancelTriageWorkflow(_ input: Acme_Telehealth_V1_CancelTriageWorkflowRequest) async throws
        -> Acme_Telehealth_V1_CancelTriageWorkflowResponse
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
            "CancelTriageWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try TriageRecord(input.triage, tenant: input.context.tenantID)
        try await store.save(record.stored)
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        let outbound0 = Acme_Fleet_V1_CreateVehicleRequest.with {
            $0.context = input.context
            $0.vehicle = Acme_Fleet_V1_Vehicle.with {
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.triage.assignee.displayName
                }
            }
        }
        async let remote0 = self.fleetVehicle.createVehicle(outbound0)
        async let persisted0 = store.count(tenant: input.context.tenantID)
        let (reply0, count0) = try await (remote0, persisted0)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count0)])
        let selection1_1: String
        switch reply0.vehicle.locator {
        case .address(let address):
            selection1_1 = address.region
        default: selection1_1 = .init()
        }
        let selection1_3: String
        switch input.triage.origin {
        case .customer(let customer):
            selection1_3 = customer.videoVisitID
        default: selection1_3 = .init()
        }
        let outbound1 = Acme_Careplans_V1_ListPendingCareGoalsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Careplans_V1_ListPendingCareGoalsRequest.Filter.with {
                $0.createdAfter = input.triage.sla.dueAt
                $0.labels = input.triage.customFields
                $0.ownerID = selection1_3
                $0.region = selection1_1
            }
        }
        let reply1 = try await self.careplansCareGoalApproval.listPendingCareGoals(outbound1)
        return Acme_Telehealth_V1_CancelTriageWorkflowResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply1.result.status
            }
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply0.vehicle.audit.createdAt
                }
                $0.comments = [
                    Acme_Telehealth_V1_TriageComment.with {
                        $0.createdAt = reply0.vehicle.audit.createdAt
                    }
                ]
                $0.subject = input.triage.subject
                $0.triageID = input.triageID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processInspectTriageWorkflow(_ input: Acme_Telehealth_V1_InspectTriageWorkflowRequest) async throws
        -> Acme_Telehealth_V1_InspectTriageWorkflowResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "InspectTriageWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "triage",
            action: "InspectTriageWorkflow", detail: input.context.traceID
        )
        let outbound0 = Acme_Careplans_V1_SignalCarePlanWorkflowRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.counterparty = Acme_Appointments_V1_AppointmentRef.with {
                    $0.startsAt = input.context.deadline
                }
            }
            $0.context = input.context
            $0.details = Acme_Careplans_V1_SignalCarePlanWorkflowRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.context.actor.email
                }
            }
        }
        let reply0 = try await self.inspectTriageWorkflowStep0.execute(outbound0)
        return Acme_Telehealth_V1_InspectTriageWorkflowResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply0.carePlan.audit.createdBy
                }
                $0.triageID = input.triageID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processListTriageWorkflows(_ input: Acme_Telehealth_V1_ListTriageWorkflowsRequest) async throws
        -> Acme_Telehealth_V1_ListTriageWorkflowsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "triage",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ListTriageWorkflows",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "triage",
            action: "ListTriageWorkflows", detail: input.context.traceID
        )
        return Acme_Telehealth_V1_ListTriageWorkflowsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processPauseTriageWorkflow(_ input: Acme_Telehealth_V1_PauseTriageWorkflowRequest) async throws
        -> Acme_Telehealth_V1_PauseTriageWorkflowResponse
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
            "PauseTriageWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try TriageRecord(input.triage, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let selection0_2: String
        switch input.triage.origin {
        case .customer(let customer):
            selection0_2 = customer.videoVisitID
        default: selection0_2 = .init()
        }
        let outbound0 = Acme_Careplans_V1_ListPendingVitalsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Careplans_V1_ListPendingVitalsRequest.Filter.with {
                $0.createdAfter = input.triage.audit.createdAt
                $0.labels = input.details.parameters
                $0.ownerID = selection0_2
            }
        }
        let reply0 = try await self.careplansVitalApproval.listPendingVitals(outbound0)
        let selection1_3: String
        switch input.triage.origin {
        case .customer(let customer):
            selection1_3 = customer.displayName
        default: selection1_3 = .init()
        }
        let outbound1 = Acme_Telehealth_V1_StartVisitNoteWorkflowRequest.with {
            $0.context = input.context
            $0.details = Acme_Telehealth_V1_StartVisitNoteWorkflowRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.notify.email
                }
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = input.triage.audit.updatedAt
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = selection1_3
                }
            }
        }
        let reply1 = try await self.telehealthVisitNoteWorkflow.startVisitNoteWorkflow(outbound1)
        let selection2_2: String
        switch reply1.visitNote.settlement {
        case .card(let card):
            selection2_2 = card.token
        default: selection2_2 = .init()
        }
        let outbound2 = Acme_Deliveries_V1_CreateDeliveryRequest.with {
            $0.context = input.context
            $0.delivery = Acme_Deliveries_V1_Delivery.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = input.triage.audit.updatedBy
                }
                $0.card = Acme_Deliveries_V1_DeliveryCardSettlement.with {
                    $0.token = selection2_2
                }
            }
        }
        let reply2 = try await self.deliveriesDelivery.createDelivery(outbound2)
        let outbound3 = Acme_Ledger_V1_ExplainLedgerAccountDecisionRequest.with {
            $0.context = input.context
            $0.ledgerAccount = Acme_Ledger_V1_LedgerAccount.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.preferredChannel = input.details.notify.preferredChannel
                }
            }
        }
        let port3 = RPCOperations.port { (request: Acme_Ledger_V1_ExplainLedgerAccountDecisionRequest) in
            try await self.ledgerLedgerAccountValidation.explainLedgerAccountDecision(request)
        }
        let reply3 = try await port3.execute(outbound3)
        return Acme_Telehealth_V1_PauseTriageWorkflowResponse.with {
            $0.outcome = Acme_Telehealth_V1_PauseTriageWorkflowResponse.Outcome.with {
                $0.status = reply0.result.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply2.result.correlationID
                $0.details = reply0.result.details
                $0.status = "ok"
            }
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply2.delivery.counterparty.displayName
                    $0.email = reply3.ledgerAccount.contact.email
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply1.visitNote.counterparty.email
                }
                $0.subject = input.triage.subject
                $0.triageID = input.triageID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processResumeTriageWorkflow(_ input: Acme_Telehealth_V1_ResumeTriageWorkflowRequest) async throws
        -> Acme_Telehealth_V1_ResumeTriageWorkflowResponse
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
            "ResumeTriageWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try TriageRecord(input.triage, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Telehealth_V1_ListVideoVisitWorkflowsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Telehealth_V1_ListVideoVisitWorkflowsRequest.Filter.with {
                $0.createdAfter = input.triage.audit.updatedAt
            }
        }
        let reply0 = try await self.resumeTriageWorkflowStep0(outbound0)
        let selection1_1: String
        switch input.triage.origin {
        case .customer(let customer):
            selection1_1 = customer.displayName
        default: selection1_1 = .init()
        }
        let outbound1 = Acme_Telehealth_V1_ApproveTriageRequest.with {
            $0.context = input.context
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.triage.assignee.displayName
                }
                $0.customer = Acme_Telehealth_V1_VideoVisitRef.with {
                    $0.displayName = selection1_1
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.notify.email
                }
            }
        }
        let reply1 = try await self.telehealthTriageApproval.approveTriage(outbound1)
        return Acme_Telehealth_V1_ResumeTriageWorkflowResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.message = reply0.result.message
                $0.status = "ok"
            }
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.assignee = input.triage.assignee
                $0.customFields = input.triage.customFields
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply1.triage.assignee.email
                }
                $0.triageID = reply1.triage.triageID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processRetryTriageWorkflow(_ input: Acme_Telehealth_V1_RetryTriageWorkflowRequest) async throws
        -> Acme_Telehealth_V1_RetryTriageWorkflowResponse
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
            "RetryTriageWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try TriageRecord(input.triage, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Notifications_V1_CloneNotificationRequest.with {
            $0.context = input.context
            $0.notification = Acme_Notifications_V1_Notification.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.email = input.triage.assignee.email
                }
                $0.customer = Acme_Notifications_V1_NotificationTemplateRef.with {
                    $0.displayName = input.triage.assignee.displayName
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.name = input.triage.requester.name
                }
                $0.sla = Acme_Notifications_V1_NotificationSla.with {
                    $0.dueAt = input.triage.sla.dueAt
                }
            }
        }
        guard let execute0 = self.retryTriageWorkflowStep0[settings.region] ?? self.retryTriageWorkflowStep0["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply0 = try await execute0(outbound0)
        let outbound1 = Acme_Patients_V1_CalculatePatientRequest.with {
            $0.context = input.context
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = input.triage.audit.updatedAt
                }
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply0.notification.assignee.displayName
                }
            }
        }
        let reply1 = try await self.patientsPatientCalculation.calculatePatient(outbound1)
        let outbound2 = Acme_Telehealth_V1_ListVisitNoteWorkflowsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Telehealth_V1_ListVisitNoteWorkflowsRequest.Filter.with {
                $0.region = reply1.patient.primaryAddress.region
            }
        }
        let envelope2 = try Google_Protobuf_Any(message: outbound2)
        let unpacked2 = try Acme_Telehealth_V1_ListVisitNoteWorkflowsRequest(unpackingAny: envelope2)
        let reply2 = try await self.telehealthVisitNoteWorkflow.listVisitNoteWorkflows(unpacked2)
        let outbound3 = Acme_Telehealth_V1_GetTriageApprovalStatusRequest.with {
            $0.context = input.context
            $0.triageID = input.triageID
        }
        let json3 = try outbound3.jsonString()
        let decoded3 = try Acme_Telehealth_V1_GetTriageApprovalStatusRequest(jsonString: json3)
        let reply3 = try await self.telehealthTriageApproval.getTriageApprovalStatus(decoded3)
        return Acme_Telehealth_V1_RetryTriageWorkflowResponse.with {
            $0.outcome = Acme_Telehealth_V1_RetryTriageWorkflowResponse.Outcome.with {
                $0.message = reply2.result.message
                $0.status = reply0.result.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply1.result.message
                $0.status = "ok"
            }
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = Projection.firstValue(
                        [
                            reply0.notification.audit.updatedBy,
                            reply1.patient.audit.updatedBy,
                        ], default: .init())
                }
                $0.customFields = reply3.triage.customFields
                $0.priority = input.triage.priority
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.preferredChannel = reply3.triage.requester.preferredChannel
                }
                $0.triageID = input.triageID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processStartTriageWorkflow(_ input: Acme_Telehealth_V1_StartTriageWorkflowRequest) async throws
        -> Acme_Telehealth_V1_StartTriageWorkflowResponse
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
            "StartTriageWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try TriageRecord(input.triage, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Patients_V1_ValidatePatientRequest.forTriageWorkflowEndpointStartTriageWorkflow0(
            input
        )
        let reply0 = try await self.patientsPatientValidation.validatePatient(outbound0)
        let outbound1 = Acme_Venues_V1_SuggestVenuesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Venues_V1_SuggestVenuesRequest.Filter.with {
                $0.region = reply0.patient.primaryAddress.region
            }
        }
        let reply1 = try await self.venuesVenueQuery.suggestVenues(
            outbound1, metadata: ["x-acme-region": .string(settings.region)]
        )
        return Acme_Telehealth_V1_StartTriageWorkflowResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply1.result.referenceIds
                $0.status = reply1.result.status
            }
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply0.patient.audit.etag
                }
                $0.priority = input.triage.priority
                $0.triageID = input.triageID
            }
        }
    }
}
