import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension AppointmentEndpoint {
    /// Returns several appointments at once.
    func batchGetAppointments(
        request: ServerRequest<Acme_Appointments_V1_BatchGetAppointmentsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_BatchGetAppointmentsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processBatchGetAppointments(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Creates an appointment.
    func cloneAppointment(
        request: ServerRequest<Acme_Appointments_V1_CloneAppointmentRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_CloneAppointmentResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCloneAppointment(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Creates an appointment.
    func createAppointment(
        request: ServerRequest<Acme_Appointments_V1_CreateAppointmentRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_CreateAppointmentResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCreateAppointment(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Deletes an appointment.
    func deleteAppointment(
        request: ServerRequest<Acme_Appointments_V1_DeleteAppointmentRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_DeleteAppointmentResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processDeleteAppointment(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns an appointment.
    func getAppointment(
        request: ServerRequest<Acme_Appointments_V1_GetAppointmentRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_GetAppointmentResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetAppointment(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists appointments a page at a time.
    func listAppointments(
        request: ServerRequest<Acme_Appointments_V1_ListAppointmentsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_ListAppointmentsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListAppointments(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Changes an appointment.
    func updateAppointment(
        request: ServerRequest<Acme_Appointments_V1_UpdateAppointmentRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_UpdateAppointmentResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processUpdateAppointment(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processBatchGetAppointments(_ input: Acme_Appointments_V1_BatchGetAppointmentsRequest) async throws
        -> Acme_Appointments_V1_BatchGetAppointmentsResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "BatchGetAppointments",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "appointment",
            action: "BatchGetAppointments", detail: input.context.traceID
        )
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        try followUps.submit(
            Acme_Identity_V1_GetUserRequest.with {
                $0.context = input.context
                $0.userID = input.context.actor.userID
            })
        let importFrame = Acme_Telehealth_V1_BatchCreateVideoVisitsRequest.with {
            $0.context = input.context
        }
        _ = try await self.telehealthVideoVisit.batchCreateVideoVisits { writer in
            try await writer.write(importFrame)
        }
        let outbound0 = Acme_Shows_V1_SummarizeShowsRequest.with {
            $0.context = input.context
            $0.details = Acme_Shows_V1_SummarizeShowsRequest.Details.with {
                $0.filters = input.context.baggage
            }
        }
        let reply0 = try await self.showsShowQuery.summarizeShows(outbound0)
        return Acme_Appointments_V1_BatchGetAppointmentsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processCloneAppointment(_ input: Acme_Appointments_V1_CloneAppointmentRequest) async throws
        -> Acme_Appointments_V1_CloneAppointmentResponse
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
            "CloneAppointment",
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
        let requests0 = input.appointment.participants.map { element in
            Acme_Telehealth_V1_RecalculateVideoVisitsRequest.with {
                $0.context = input.context
                $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                    $0.participants = [
                        Acme_Telehealth_V1_VideoVisitParticipant.with {
                            $0.contact = Acme_Common_V1_ContactInfo.with {
                                $0.email = element.contact.email
                                $0.phone = element.contact.phone
                                $0.preferredChannel = element.contact.preferredChannel
                            }
                        }
                    ]
                }
            }
        }
        let replies0 = try await FanOut.map(requests0) { candidate in
            try await self.telehealthVideoVisitCalculation.recalculateVideoVisits(candidate)
        }
        let reply0 = replies0.first ?? Acme_Telehealth_V1_RecalculateVideoVisitsResponse()
        let outbound1 = Acme_Featureflags_V1_LintFeatureFlagsRequest.with {
            $0.context = input.context
            $0.featureFlag = Acme_Featureflags_V1_FeatureFlag.with {
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.userID = reply0.videoVisit.organizer.userID
                }
            }
        }
        let envelope1 = try Google_Protobuf_Any(message: outbound1)
        let unpacked1 = try Acme_Featureflags_V1_LintFeatureFlagsRequest(unpackingAny: envelope1)
        let reply1 = try await self.featureflagsFeatureFlagValidation.lintFeatureFlags(unpacked1)
        return Acme_Appointments_V1_CloneAppointmentResponse.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.location = input.appointment.location
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.email = reply1.featureFlag.owner.email
                }
                $0.status = input.appointment.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processCreateAppointment(_ input: Acme_Appointments_V1_CreateAppointmentRequest) async throws
        -> Acme_Appointments_V1_CreateAppointmentResponse
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
            "CreateAppointment",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try AppointmentRecord(input.appointment, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Appointments_V1_ScoreClinicSlotRequest.with {
            $0.clinicSlot = Acme_Appointments_V1_ClinicSlot.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = input.appointment.audit.createdBy
                    $0.updatedBy = input.appointment.audit.updatedBy
                }
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.lines = input.appointment.location.lines
                }
            }
            $0.context = input.context
            $0.details = Acme_Appointments_V1_ScoreClinicSlotRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.locality = input.appointment.location.locality
                }
            }
        }
        let json0 = try outbound0.jsonString()
        let decoded0 = try Acme_Appointments_V1_ScoreClinicSlotRequest(jsonString: json0)
        let reply0 = try await self.appointmentsClinicSlotValidation.scoreClinicSlot(decoded0)
        let outbound1 = Acme_Appointments_V1_LintProvidersRequest.forAppointmentEndpointCreateAppointment1(
            input,
            reply0: reply0
        )
        let reply1 = try await self.appointmentsProviderValidation.lintProviders(outbound1)
        return Acme_Appointments_V1_CreateAppointmentResponse.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply1.provider.audit.updatedAt
                }
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.locality = reply0.clinicSlot.location.locality
                }
                $0.metadata = input.appointment.metadata
                $0.status = input.appointment.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processDeleteAppointment(_ input: Acme_Appointments_V1_DeleteAppointmentRequest) async throws
        -> Acme_Appointments_V1_DeleteAppointmentResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.appointmentID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "appointment",
            action: "audit", detail: input.appointmentID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "DeleteAppointment",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "appointment",
            action: "DeleteAppointment", detail: input.context.traceID
        )
        let outbound0 = Acme_Appointments_V1_CheckClinicSlotEligibilityRequest.with {
            $0.clinicSlot = Acme_Appointments_V1_ClinicSlot.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = input.etag
                }
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.context.actor.userID
                }
                $0.participants = [
                    Acme_Appointments_V1_ClinicSlotParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = input.context.actor.email
                        }
                    }
                ]
            }
            $0.context = input.context
            $0.reason = input.reason
        }
        let reply0 = try await self.appointmentsClinicSlotValidation.checkClinicSlotEligibility(
            outbound0, metadata: ["x-acme-region": .string(settings.region)]
        )
        return Acme_Appointments_V1_DeleteAppointmentResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.outcome.message
                $0.status = reply0.outcome.status
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processGetAppointment(_ input: Acme_Appointments_V1_GetAppointmentRequest) async throws
        -> Acme_Appointments_V1_GetAppointmentResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "GetAppointment",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "appointment",
            action: "GetAppointment", detail: input.context.traceID
        )
        let outbound0 = Acme_Appointments_V1_FindProvidersRequest.with {
            $0.context = input.context
            $0.filter = Acme_Appointments_V1_FindProvidersRequest.Filter.with {
                $0.createdAfter = input.context.deadline
                $0.labels = input.context.baggage
                $0.ownerID = input.appointmentID
            }
        }
        let reply0 = try await RPCOperations.call(outbound0) { request in
            try await self.appointmentsProviderQuery.findProviders(request)
        }
        let outbound1 = Acme_Prescriptions_V1_SuggestMedicationsRequest.with {
            $0.context = Projection.read(input, at: \Acme_Appointments_V1_GetAppointmentRequest.context)
            $0.filter = Acme_Prescriptions_V1_SuggestMedicationsRequest.Filter.with {
                $0.ownerID = Projection.read(input, at: \Acme_Appointments_V1_GetAppointmentRequest.appointmentID)
            }
        }
        let reply1 = try await self.prescriptionsMedicationQuery.suggestMedications(outbound1)
        return Acme_Appointments_V1_GetAppointmentResponse.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.appointmentID = input.appointmentID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply1.result.message
                $0.referenceIds = reply0.result.referenceIds
                $0.status = Projection.firstValue(
                    [
                        reply0.result.status,
                        reply1.result.status,
                    ], default: .init())
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processListAppointments(_ input: Acme_Appointments_V1_ListAppointmentsRequest) async throws
        -> Acme_Appointments_V1_ListAppointmentsResponse
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
            "ListAppointments",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "appointment",
            action: "ListAppointments", detail: input.context.traceID
        )
        let outbound0 = Acme_Appointments_V1_QuoteClinicSlotRequest.with {
            $0.clinicSlot = Acme_Appointments_V1_ClinicSlot.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.filter.createdAfter
                }
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.context.actor.userID
                }
                $0.participants = [
                    Acme_Appointments_V1_ClinicSlotParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = input.context.actor.email
                        }
                    }
                ]
            }
            $0.context = input.context
            $0.details = Acme_Appointments_V1_QuoteClinicSlotRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
            }
        }
        let step0: @Sendable () async throws -> Acme_Appointments_V1_QuoteClinicSlotResponse = {
            try await self.appointmentsClinicSlotCalculation.quoteClinicSlot(outbound0)
        }
        let reply0 = try await step0()
        return Acme_Appointments_V1_ListAppointmentsResponse.with {
            $0.appointments = [
                Acme_Appointments_V1_Appointment.with {
                    $0.location = reply0.clinicSlot.location
                }
            ]
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processUpdateAppointment(_ input: Acme_Appointments_V1_UpdateAppointmentRequest) async throws
        -> Acme_Appointments_V1_UpdateAppointmentResponse
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
            "UpdateAppointment",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try AppointmentRecord(input.appointment, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let selection0_2: Int32
        switch input.appointment.recurrence {
        case .daily(let daily):
            selection0_2 = daily.interval
        default: selection0_2 = .init()
        }
        let outbound0 = Acme_Appointments_V1_ValidateClinicSlotRequest.with {
            $0.clinicSlot = Acme_Appointments_V1_ClinicSlot.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = input.appointment.audit.createdBy
                }
                $0.daily = Acme_Appointments_V1_ClinicSlotDailyRule.with {
                    $0.interval = selection0_2
                }
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.appointment.organizer.userID
                }
                $0.participants = [
                    Acme_Appointments_V1_ClinicSlotParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = input.appointment.organizer.email
                        }
                    }
                ]
            }
            $0.context = input.context
        }
        let reply0 = try await self.appointmentsClinicSlotValidation.validateClinicSlot(outbound0)
        let requests1 = input.appointment.participants.map { element in
            Acme_Appointments_V1_CountAppointmentsRequest.with {
                $0.context = input.context
                $0.filter = Acme_Appointments_V1_CountAppointmentsRequest.Filter.with {
                    $0.ownerID = element.participantID
                    $0.region = reply0.clinicSlot.location.region
                }
            }
        }
        let replies1 = try await FanOut.map(requests1) { candidate in
            try await self.appointmentsAppointmentQuery.countAppointments(candidate)
        }
        let reply1 = replies1.first ?? Acme_Appointments_V1_CountAppointmentsResponse()
        _ = reply1
        return Acme_Appointments_V1_UpdateAppointmentResponse.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = reply0.clinicSlot.location.postalCode
                }
                $0.status = input.appointment.status
                $0.title = input.appointment.title
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }
}
