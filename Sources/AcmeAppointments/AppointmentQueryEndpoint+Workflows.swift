import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension AppointmentQueryEndpoint {
    /// Execute the appointments workflow and project its upstream replies.
    func processBrowseAppointments(_ input: Acme_Appointments_V1_BrowseAppointmentsRequest) async throws
        -> Acme_Appointments_V1_BrowseAppointmentsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "appointment",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "BrowseAppointments",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "appointment",
            action: "BrowseAppointments", detail: input.context.traceID
        )
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        let importFrame = Acme_Prescriptions_V1_BatchCreatePrescriptionsRequest.with {
            $0.context = input.context
        }
        _ = try await self.prescriptionsPrescription.batchCreatePrescriptions { writer in
            try await writer.write(importFrame)
        }
        return Acme_Appointments_V1_BrowseAppointmentsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processCountAppointments(_ input: Acme_Appointments_V1_CountAppointmentsRequest) async throws
        -> Acme_Appointments_V1_CountAppointmentsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "appointment",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "CountAppointments",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "appointment",
            action: "CountAppointments", detail: input.context.traceID
        )
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        let outbound0 = Acme_Appointments_V1_LintAppointmentsRequest.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
            }
            $0.context = input.context
        }
        let reply0 = try await RPCOperations.call(outbound0) { request in
            try await self.appointmentsAppointmentValidation.lintAppointments(request)
        }
        let outbound1 = Acme_Notifications_V1_ValidateNotificationRequest.with {
            $0.context = Projection.read(input, at: \Acme_Appointments_V1_CountAppointmentsRequest.context)
            $0.notification = Acme_Notifications_V1_Notification.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = Projection.read(
                        reply0, at: \Acme_Appointments_V1_LintAppointmentsResponse.appointment.audit.etag)
                }
                $0.comments = [
                    Acme_Notifications_V1_NotificationComment.with {
                        $0.createdAt = Projection.read(
                            reply0, at: \Acme_Appointments_V1_LintAppointmentsResponse.appointment.audit.createdAt)
                    }
                ]
            }
        }
        let reply1 = try await self.notificationsNotificationValidation.validateNotification(outbound1)
        return Acme_Appointments_V1_CountAppointmentsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.details = reply1.result.details
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processExportAppointments(_ input: Acme_Appointments_V1_ExportAppointmentsRequest) async throws
        -> Acme_Appointments_V1_ExportAppointmentsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.destinationUri)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "appointment",
            action: "audit", detail: input.destinationUri
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ExportAppointments",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "appointment",
            action: "ExportAppointments", detail: input.context.traceID
        )
        let outbound0 = Acme_Careplans_V1_EstimateCarePlanRequest.with {
            $0.context = input.context
            $0.details = Acme_Careplans_V1_EstimateCarePlanRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
            }
        }
        let step0: @Sendable () async throws -> Acme_Careplans_V1_EstimateCarePlanResponse = {
            try await self.careplansCarePlanCalculation.estimateCarePlan(outbound0)
        }
        let reply0 = try await step0()
        var outbound1 = Acme_Seating_V1_CloneSeatMapRequest()
        outbound1.context = input.context
        outbound1.seatMap = Acme_Seating_V1_SeatMap.with {
            $0.children = [
                Acme_Seating_V1_SeatMap.with {
                    $0.children = [
                        Acme_Seating_V1_SeatMap.with {
                            $0.location = Acme_Common_V1_PostalAddress.with {
                                $0.postalCode = reply0.carePlan.billingAddress.postalCode
                                $0.recipient = reply0.carePlan.billingAddress.recipient
                            }
                        }
                    ]
                }
            ]
        }
        let reply1 = try await self.seatingSeatMap.cloneSeatMap(outbound1)
        return Acme_Appointments_V1_ExportAppointmentsResponse.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = Projection.firstValue(
                        [
                            reply0.carePlan.audit.updatedAt,
                            reply1.seatMap.audit.updatedAt,
                        ], default: .init())
                }
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.lines = reply1.seatMap.location.lines
                    $0.region = input.filter.region
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processFindAppointments(_ input: Acme_Appointments_V1_FindAppointmentsRequest) async throws
        -> Acme_Appointments_V1_FindAppointmentsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "appointment",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "FindAppointments",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "appointment",
            action: "FindAppointments", detail: input.context.traceID
        )
        let outbound0 = Acme_Careplans_V1_ExplainCareGoalCalculationRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.context.actor.userID
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.context.actor.email
                }
            }
            $0.context = input.context
        }
        let step0: @Sendable () async throws -> Acme_Careplans_V1_ExplainCareGoalCalculationResponse = {
            try await self.careplansCareGoalCalculation.explainCareGoalCalculation(outbound0)
        }
        let reply0 = try await step0()
        return Acme_Appointments_V1_FindAppointmentsResponse.with {
            $0.appointments = [
                Acme_Appointments_V1_Appointment.with {
                    $0.organizer = Acme_Identity_V1_UserRef.with {
                        $0.displayName = reply0.careGoal.assignee.displayName
                    }
                }
            ]
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processLookupAppointment(_ input: Acme_Appointments_V1_LookupAppointmentRequest) async throws
        -> Acme_Appointments_V1_LookupAppointmentResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "LookupAppointment",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "appointment",
            action: "LookupAppointment", detail: input.context.traceID
        )
        let outbound0 = Acme_Appointments_V1_RecalculateClinicSlotsRequest.with {
            $0.clinicSlot = Acme_Appointments_V1_ClinicSlot.with {
                $0.participants = [
                    Acme_Appointments_V1_ClinicSlotParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = input.context.actor.email
                        }
                    }
                ]
            }
            $0.context = input.context
        }
        let reply0 = try await self.appointmentsClinicSlotCalculation.recalculateClinicSlots(outbound0)
        return Acme_Appointments_V1_LookupAppointmentResponse.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.appointmentID = input.appointmentID
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply0.clinicSlot.organizer.displayName
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processPeekAppointment(_ input: Acme_Appointments_V1_PeekAppointmentRequest) async throws
        -> Acme_Appointments_V1_PeekAppointmentResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "PeekAppointment",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "appointment",
            action: "PeekAppointment", detail: input.context.traceID
        )
        return Acme_Appointments_V1_PeekAppointmentResponse.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.appointmentID = input.appointmentID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processResolveAppointments(_ input: Acme_Appointments_V1_ResolveAppointmentsRequest) async throws
        -> Acme_Appointments_V1_ResolveAppointmentsResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ResolveAppointments",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "appointment",
            action: "ResolveAppointments", detail: input.context.traceID
        )
        let outbound0 = Acme_Notifications_V1_ScoreNotificationRequest.with {
            $0.context = input.context
            $0.notification = Acme_Notifications_V1_Notification.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.email = input.context.actor.email
                    $0.userID = input.context.actor.userID
                }
            }
        }
        async let remote0 = self.notificationsNotificationValidation.scoreNotification(outbound0)
        async let persisted0 = store.count(tenant: input.context.tenantID)
        let (reply0, count0) = try await (remote0, persisted0)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count0)])
        return Acme_Appointments_V1_ResolveAppointmentsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply0.result.status
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processSuggestAppointments(_ input: Acme_Appointments_V1_SuggestAppointmentsRequest) async throws
        -> Acme_Appointments_V1_SuggestAppointmentsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "appointment",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SuggestAppointments",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "appointment",
            action: "SuggestAppointments", detail: input.context.traceID
        )
        let outbound0 = Acme_Appointments_V1_ExplainClinicSlotCalculationRequest.with {
            $0.clinicSlot = Acme_Appointments_V1_ClinicSlot.with {
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
            }
            $0.context = input.context
        }
        let reply0 = try await self.suggestAppointmentsStep0.execute(outbound0)
        let outbound1 = Acme_Performers_V1_BrowsePerformersRequest.with {
            $0.context = input.context
            $0.filter = Acme_Performers_V1_BrowsePerformersRequest.Filter.with {
                $0.createdAfter = input.filter.createdAfter
                $0.region = reply0.clinicSlot.location.region
            }
            $0.page = Acme_Common_V1_PageRequest.with {
                $0.pageSize = input.page.pageSize
                $0.pageToken = input.page.pageToken
            }
        }
        let port1 = RPCOperations.port { (request: Acme_Performers_V1_BrowsePerformersRequest) in
            try await self.performersPerformerQuery.browsePerformers(request)
        }
        let reply1 = try await port1.execute(outbound1)
        return Acme_Appointments_V1_SuggestAppointmentsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = Projection.firstValue(
                    [
                        reply0.result.correlationID,
                        reply1.result.correlationID,
                    ], default: .init())
                $0.referenceIds = reply1.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processSummarizeAppointments(_ input: Acme_Appointments_V1_SummarizeAppointmentsRequest) async throws
        -> Acme_Appointments_V1_SummarizeAppointmentsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.cron)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "appointment",
            action: "audit", detail: input.details.cron
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SummarizeAppointments",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "appointment",
            action: "SummarizeAppointments", detail: input.context.traceID
        )
        let outbound0 = Acme_Careplans_V1_CreateCarePlanRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.counterparty = Acme_Appointments_V1_AppointmentRef.with {
                    $0.appointmentID = input.appointmentID
                }
                $0.lines = [
                    Acme_Careplans_V1_CarePlanLine.with {
                        $0.attributes = input.annotations
                    }
                ]
                $0.metadata = input.details.filters
            }
            $0.context = input.context
        }
        let reply0 = try await self.summarizeAppointmentsStep0(outbound0)
        let outbound1 = Acme_Appointments_V1_RecalculateClinicSlotsRequest.with {
            $0.clinicSlot = Acme_Appointments_V1_ClinicSlot.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply0.carePlan.audit.createdBy
                    $0.updatedBy = reply0.carePlan.audit.updatedBy
                }
            }
            $0.context = input.context
            $0.details = Acme_Appointments_V1_RecalculateClinicSlotsRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.region = reply0.carePlan.billingAddress.region
                }
            }
        }
        guard
            let execute1 = self.summarizeAppointmentsStep1[settings.region]
                ?? self.summarizeAppointmentsStep1["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply1 = try await execute1(outbound1)
        let selection2_4: Int32
        switch reply1.clinicSlot.recurrence {
        case .weekly(let weekly):
            selection2_4 = weekly.interval
        default: selection2_4 = .init()
        }
        let outbound2 = Acme_Appointments_V1_ExplainClinicSlotCalculationRequest.with {
            $0.clinicSlot = Acme_Appointments_V1_ClinicSlot.with {
                $0.daily = Acme_Appointments_V1_ClinicSlotDailyRule.with {
                    $0.interval = selection2_4
                }
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = reply1.clinicSlot.location.postalCode
                    $0.region = reply0.carePlan.billingAddress.region
                }
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply1.clinicSlot.organizer.displayName
                }
            }
            $0.context = input.context
        }
        let reply2 = try await self.appointmentsClinicSlotCalculation.explainClinicSlotCalculation(outbound2)
        return Acme_Appointments_V1_SummarizeAppointmentsResponse.with {
            $0.period = input.details.period
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = Projection.firstValue(
                    [
                        reply0.result.details,
                        reply2.result.details,
                    ], default: .init())
                $0.message = reply0.result.message
                $0.referenceIds = reply1.result.referenceIds
                $0.status = "ok"
            }
        }
    }
}
