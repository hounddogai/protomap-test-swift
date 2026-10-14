import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension AppointmentWorkflowEndpoint {
    /// Execute the appointments workflow and project its upstream replies.
    func processAdvanceAppointmentWorkflow(_ input: Acme_Appointments_V1_AdvanceAppointmentWorkflowRequest) async throws
        -> Acme_Appointments_V1_AdvanceAppointmentWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.appointment.appointmentID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "appointment",
            action: "audit", detail: input.appointment.appointmentID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "AdvanceAppointmentWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try AppointmentRecord(input.appointment, tenant: input.context.tenantID)
        try await store.save(record.stored)
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        try followUps.submit(
            Acme_Identity_V1_GetUserRequest.with {
                $0.context = input.context
                $0.userID = input.context.actor.userID
            })
        let importFrame = Acme_Prescriptions_V1_StreamMedicationChangesRequest.with {
            $0.context = input.context
        }
        _ = try await self.prescriptionsMedicationSync.streamMedicationChanges { writer in
            try await writer.write(importFrame)
        } onResponse: { response in
            var latest = Acme_Prescriptions_V1_StreamMedicationChangesResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        let outbound0 = Acme_Prescriptions_V1_PushRefillRequest.with {
            $0.context = input.context
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.email = input.details.notify.email
                    $0.userID = input.appointment.organizer.userID
                }
                $0.customer = Acme_Prescriptions_V1_PrescriptionRef.with {
                    $0.displayName = input.appointment.organizer.displayName
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.appointment.organizer.email
                }
            }
        }
        let json0 = try outbound0.jsonString()
        let decoded0 = try Acme_Prescriptions_V1_PushRefillRequest(jsonString: json0)
        let reply0 = try await self.prescriptionsRefillSync.pushRefill(decoded0)
        let outbound1 =
            Acme_Telehealth_V1_CommentVisitNoteApprovalRequest.forAppointmentWorkflowEndpointAdvanceAppointmentWorkflow1(
                input,
                reply0: reply0
            )
        let reply1 = try await self.telehealthVisitNoteApproval.commentVisitNoteApproval(outbound1)
        return Acme_Appointments_V1_AdvanceAppointmentWorkflowResponse.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.appointmentID = input.appointmentID
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.region = reply1.visitNote.billingAddress.region
                }
                $0.participants = [
                    Acme_Appointments_V1_AppointmentParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = reply0.refill.assignee.email
                        }
                    }
                ]
                $0.title = input.appointment.title
            }
            $0.outcome = Acme_Appointments_V1_AdvanceAppointmentWorkflowResponse.Outcome.with {
                $0.referenceID = reply1.outcome.referenceID
                $0.status = reply0.result.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processCancelAppointmentWorkflow(_ input: Acme_Appointments_V1_CancelAppointmentWorkflowRequest) async throws
        -> Acme_Appointments_V1_CancelAppointmentWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.appointment.appointmentID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "appointment",
            action: "audit", detail: input.appointment.appointmentID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "CancelAppointmentWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try AppointmentRecord(input.appointment, tenant: input.context.tenantID)
        try await store.save(record.stored)
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        let outbound0 = Acme_Documents_V1_SuggestDocumentsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Documents_V1_SuggestDocumentsRequest.Filter.with {
                $0.region = input.appointment.location.region
            }
        }
        let reply0 = try await self.documentsDocumentQuery.suggestDocuments(
            outbound0, metadata: ["x-acme-region": .string(settings.region)]
        )
        return Acme_Appointments_V1_CancelAppointmentWorkflowResponse.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.appointmentID = input.appointmentID
                $0.title = input.appointment.title
            }
            $0.outcome = Acme_Appointments_V1_CancelAppointmentWorkflowResponse.Outcome.with {
                $0.message = reply0.result.message
                $0.status = reply0.result.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processInspectAppointmentWorkflow(_ input: Acme_Appointments_V1_InspectAppointmentWorkflowRequest) async throws
        -> Acme_Appointments_V1_InspectAppointmentWorkflowResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "InspectAppointmentWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "appointment",
            action: "InspectAppointmentWorkflow", detail: input.context.traceID
        )
        let outbound0 = Acme_Careplans_V1_CommentCareGoalApprovalRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.context.actor.userID
                }
            }
            $0.context = input.context
        }
        let reply0 = try await RPCOperations.call(outbound0) { request in
            try await self.careplansCareGoalApproval.commentCareGoalApproval(request)
        }
        return Acme_Appointments_V1_InspectAppointmentWorkflowResponse.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.appointmentID = input.appointmentID
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply0.careGoal.audit.etag
                }
                $0.participants = [
                    Acme_Appointments_V1_AppointmentParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.name = reply0.careGoal.requester.name
                        }
                    }
                ]
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processPauseAppointmentWorkflow(_ input: Acme_Appointments_V1_PauseAppointmentWorkflowRequest) async throws
        -> Acme_Appointments_V1_PauseAppointmentWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.appointment.audit.createdBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "appointment",
            action: "audit", detail: input.appointment.audit.createdBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "PauseAppointmentWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try AppointmentRecord(input.appointment, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Identity_V1_UpdateUserRequest.with {
            $0.context = Projection.read(input, at: \Acme_Appointments_V1_PauseAppointmentWorkflowRequest.context)
            $0.user = Acme_Identity_V1_User.with {
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.recipient = Projection.read(
                        input, at: \Acme_Appointments_V1_PauseAppointmentWorkflowRequest.appointment.location.recipient)
                }
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.email = Projection.read(
                        input, at: \Acme_Appointments_V1_PauseAppointmentWorkflowRequest.appointment.organizer.email)
                    $0.userID = Projection.read(
                        input, at: \Acme_Appointments_V1_PauseAppointmentWorkflowRequest.appointment.organizer.userID)
                }
            }
        }
        let reply0 = try await self.identityUser.updateUser(outbound0)
        let outbound1 = Acme_Appointments_V1_LookupAppointmentRequest.with {
            $0.appointmentID = input.appointment.appointmentID
            $0.context = input.context
        }
        let step1: @Sendable () async throws -> Acme_Appointments_V1_LookupAppointmentResponse = {
            try await self.appointmentsAppointmentQuery.lookupAppointment(outbound1)
        }
        let reply1 = try await step1()
        let requests2 = input.appointment.participants.map { element in
            Acme_Telehealth_V1_CommentTriageApprovalRequest.with {
                $0.context = input.context
                $0.details = Acme_Telehealth_V1_CommentTriageApprovalRequest.Details.with {
                    $0.approver = Acme_Identity_V1_UserRef.with {
                        $0.email = element.contact.email
                    }
                }
                $0.triage = Acme_Telehealth_V1_Triage.with {
                    $0.requester = Acme_Common_V1_ContactInfo.with {
                        $0.phone = element.contact.phone
                        $0.preferredChannel = element.contact.preferredChannel
                    }
                }
            }
        }
        let replies2 = try await FanOut.map(requests2) { candidate in
            try await self.telehealthTriageApproval.commentTriageApproval(candidate)
        }
        let reply2 = replies2.first ?? Acme_Telehealth_V1_CommentTriageApprovalResponse()
        _ = reply2
        return Acme_Appointments_V1_PauseAppointmentWorkflowResponse.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.appointmentID = input.appointmentID
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply1.appointment.audit.etag
                }
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.recipient = reply1.appointment.location.recipient
                }
                $0.metadata = input.appointment.metadata
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processResumeAppointmentWorkflow(_ input: Acme_Appointments_V1_ResumeAppointmentWorkflowRequest) async throws
        -> Acme_Appointments_V1_ResumeAppointmentWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.appointment.appointmentID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "appointment",
            action: "audit", detail: input.appointment.appointmentID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ResumeAppointmentWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try AppointmentRecord(input.appointment, tenant: input.context.tenantID)
        try await store.save(record.stored)
        var outbound0 = Acme_Venues_V1_ExplainVenueDecisionRequest()
        outbound0.context = input.context
        outbound0.venue = Acme_Venues_V1_Venue.with {
            $0.owner = Acme_Identity_V1_UserRef.with {
                $0.displayName = input.appointment.organizer.displayName
            }
        }
        let reply0 = try await self.venuesVenueValidation.explainVenueDecision(outbound0)
        let selection1_3: Int32
        switch input.appointment.recurrence {
        case .daily(let daily):
            selection1_3 = daily.atHour
        default: selection1_3 = .init()
        }
        let outbound1 = Acme_Appointments_V1_SubmitAppointmentRequest.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.daily = Acme_Appointments_V1_AppointmentDailyRule.with {
                    $0.atHour = selection1_3
                }
                $0.participants = [
                    Acme_Appointments_V1_AppointmentParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.phone = input.details.notify.phone
                        }
                    }
                ]
            }
            $0.context = input.context
            $0.details = Acme_Appointments_V1_SubmitAppointmentRequest.Details.with {
                $0.approver = Acme_Identity_V1_UserRef.with {
                    $0.email = input.appointment.organizer.email
                }
            }
        }
        let reply1 = try await self.appointmentsAppointmentApproval.submitAppointment(outbound1)
        return Acme_Appointments_V1_ResumeAppointmentWorkflowResponse.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.appointmentID = input.appointmentID
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply0.venue.audit.etag
                }
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.region = reply1.appointment.location.region
                }
                $0.window = input.appointment.window
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processRetryAppointmentWorkflow(_ input: Acme_Appointments_V1_RetryAppointmentWorkflowRequest) async throws
        -> Acme_Appointments_V1_RetryAppointmentWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.appointment.appointmentID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "appointment",
            action: "audit", detail: input.appointment.appointmentID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "RetryAppointmentWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try AppointmentRecord(input.appointment, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Appointments_V1_ExplainClinicSlotDecisionRequest.with {
            $0.clinicSlot = Acme_Appointments_V1_ClinicSlot.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = input.appointment.audit.updatedBy
                }
            }
            $0.context = input.context
        }
        let step0: @Sendable () async throws -> Acme_Appointments_V1_ExplainClinicSlotDecisionResponse = {
            try await self.appointmentsClinicSlotValidation.explainClinicSlotDecision(outbound0)
        }
        let reply0 = try await step0()
        let requests1 = input.appointment.participants.map { element in
            Acme_Appointments_V1_CommentAppointmentApprovalRequest.with {
                $0.appointment = Acme_Appointments_V1_Appointment.with {
                    $0.participants = [
                        Acme_Appointments_V1_AppointmentParticipant.with {
                            $0.participantID = element.participantID
                        }
                    ]
                }
                $0.context = input.context
            }
        }
        let replies1 = try await FanOut.map(requests1) { candidate in
            try await self.appointmentsAppointmentApproval.commentAppointmentApproval(candidate)
        }
        let reply1 = replies1.first ?? Acme_Appointments_V1_CommentAppointmentApprovalResponse()
        _ = reply1
        return Acme_Appointments_V1_RetryAppointmentWorkflowResponse.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.appointmentID = input.appointmentID
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply0.clinicSlot.audit.updatedBy
                }
                $0.metadata = input.appointment.metadata
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processStartAppointmentWorkflow(_ input: Acme_Appointments_V1_StartAppointmentWorkflowRequest) async throws
        -> Acme_Appointments_V1_StartAppointmentWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.appointment.appointmentID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "appointment",
            action: "audit", detail: input.appointment.appointmentID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "StartAppointmentWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try AppointmentRecord(input.appointment, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Appointments_V1_LintProvidersRequest.with {
            $0.context = input.context
            $0.provider = Acme_Appointments_V1_Provider.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = input.appointment.audit.updatedBy
                }
            }
        }
        let reply0 = try await self.appointmentsProviderValidation.lintProviders(outbound0)
        let requests1 = input.appointment.participants.map { element in
            Acme_Telehealth_V1_DelegateTriageApprovalRequest.with {
                $0.context = input.context
                $0.triage = Acme_Telehealth_V1_Triage.with {
                    $0.assignee = Acme_Identity_V1_UserRef.with {
                        $0.email = element.contact.email
                    }
                    $0.requester = Acme_Common_V1_ContactInfo.with {
                        $0.name = element.contact.name
                        $0.phone = element.contact.phone
                        $0.preferredChannel = element.contact.preferredChannel
                    }
                }
            }
        }
        let replies1 = try await FanOut.map(requests1) { candidate in
            try await self.telehealthTriageApproval.delegateTriageApproval(candidate)
        }
        let reply1 = replies1.first ?? Acme_Telehealth_V1_DelegateTriageApprovalResponse()
        _ = reply1
        return Acme_Appointments_V1_StartAppointmentWorkflowResponse.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.appointmentID = input.appointmentID
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply0.provider.audit.createdBy
                }
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.email = reply0.provider.contact.email
                }
                $0.status = input.appointment.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }
}
