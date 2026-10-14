import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension ClinicSlotWorkflowEndpoint {
    /// Advances a clinic slot.
    func advanceClinicSlotWorkflow(
        request: ServerRequest<Acme_Appointments_V1_AdvanceClinicSlotWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_AdvanceClinicSlotWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processAdvanceClinicSlotWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a clinic slot.
    func inspectClinicSlotWorkflow(
        request: ServerRequest<Acme_Appointments_V1_InspectClinicSlotWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_InspectClinicSlotWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processInspectClinicSlotWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists clinic slots a page at a time.
    func listClinicSlotWorkflows(
        request: ServerRequest<Acme_Appointments_V1_ListClinicSlotWorkflowsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_ListClinicSlotWorkflowsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListClinicSlotWorkflows(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Pauses a clinic slot.
    func pauseClinicSlotWorkflow(
        request: ServerRequest<Acme_Appointments_V1_PauseClinicSlotWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_PauseClinicSlotWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processPauseClinicSlotWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Resumes a clinic slot.
    func resumeClinicSlotWorkflow(
        request: ServerRequest<Acme_Appointments_V1_ResumeClinicSlotWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_ResumeClinicSlotWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processResumeClinicSlotWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Retrys a clinic slot.
    func retryClinicSlotWorkflow(
        request: ServerRequest<Acme_Appointments_V1_RetryClinicSlotWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_RetryClinicSlotWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRetryClinicSlotWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Signals a clinic slot.
    func signalClinicSlotWorkflow(
        request: ServerRequest<Acme_Appointments_V1_SignalClinicSlotWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_SignalClinicSlotWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSignalClinicSlotWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Starts a clinic slot.
    func startClinicSlotWorkflow(
        request: ServerRequest<Acme_Appointments_V1_StartClinicSlotWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_StartClinicSlotWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processStartClinicSlotWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processAdvanceClinicSlotWorkflow(_ input: Acme_Appointments_V1_AdvanceClinicSlotWorkflowRequest) async throws
        -> Acme_Appointments_V1_AdvanceClinicSlotWorkflowResponse
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
            "AdvanceClinicSlotWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try ClinicSlotRecord(input.clinicSlot, tenant: input.context.tenantID)
        try await store.save(record.stored)
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        try followUps.submit(
            Acme_Identity_V1_GetUserRequest.with {
                $0.context = input.context
                $0.userID = input.context.actor.userID
            })
        let archive = Data(try input.context.jsonString().utf8)
        let restoredContext = try Acme_Common_V1_RequestContext(
            jsonString: String(decoding: archive, as: UTF8.self)
        )
        _ = try await self.prescriptionsRefillSync.pushRefill(
            Acme_Prescriptions_V1_PushRefillRequest.with {
                $0.context = restoredContext
                $0.details = Acme_Prescriptions_V1_PushRefillRequest.Details.with {
                    $0.payload = archive
                }
            })
        let outbound0 = Acme_Notifications_V1_BrowseNotificationsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Notifications_V1_BrowseNotificationsRequest.Filter.with {
                $0.region = input.clinicSlot.location.region
            }
        }
        let reply0 = try await self.notificationsNotificationQuery.browseNotifications(
            outbound0, metadata: ["x-acme-region": .string(settings.region)]
        )
        let outbound1 = Acme_Prescriptions_V1_ResumeMedicationWorkflowRequest.with {
            $0.context = input.context
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.address = Acme_Common_V1_PostalAddress.with {
                    $0.recipient = input.clinicSlot.location.recipient
                }
            }
        }
        let reply1 = try await RPCOperations.call(outbound1) { request in
            try await self.prescriptionsMedicationWorkflow.resumeMedicationWorkflow(request)
        }
        let selection2_1: String
        switch reply1.medication.locator {
        case .address(let address):
            selection2_1 = address.region
        default: selection2_1 = .init()
        }
        let outbound2 = Acme_Authorization_V1_FindAccessPoliciesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Authorization_V1_FindAccessPoliciesRequest.Filter.with {
                $0.region = selection2_1
            }
        }
        let reply2 = try await self.authorizationAccessPolicyQuery.findAccessPolicies(outbound2)
        return Acme_Appointments_V1_AdvanceClinicSlotWorkflowResponse.with {
            $0.clinicSlot = Acme_Appointments_V1_ClinicSlot.with {
                $0.clinicSlotID = input.clinicSlotID
                $0.location = input.clinicSlot.location
            }
            $0.outcome = Acme_Appointments_V1_AdvanceClinicSlotWorkflowResponse.Outcome.with {
                $0.status = reply0.result.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.details = reply1.result.details
                $0.referenceIds = reply2.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processInspectClinicSlotWorkflow(_ input: Acme_Appointments_V1_InspectClinicSlotWorkflowRequest) async throws
        -> Acme_Appointments_V1_InspectClinicSlotWorkflowResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "InspectClinicSlotWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "clinic_slot",
            action: "InspectClinicSlotWorkflow", detail: input.context.traceID
        )
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        let outbound0 = Acme_Appointments_V1_StartProviderWorkflowRequest.with {
            $0.context = Projection.read(input, at: \Acme_Appointments_V1_InspectClinicSlotWorkflowRequest.context)
            $0.details = Acme_Appointments_V1_StartProviderWorkflowRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.email = Projection.read(
                        input, at: \Acme_Appointments_V1_InspectClinicSlotWorkflowRequest.context.actor.email)
                }
            }
        }
        let reply0 = try await self.appointmentsProviderWorkflow.startProviderWorkflow(outbound0)
        return Acme_Appointments_V1_InspectClinicSlotWorkflowResponse.with {
            $0.clinicSlot = Acme_Appointments_V1_ClinicSlot.with {
                $0.clinicSlotID = input.clinicSlotID
                $0.participants = [
                    Acme_Appointments_V1_ClinicSlotParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.name = reply0.provider.name
                        }
                    }
                ]
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply0.outcome.status
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processListClinicSlotWorkflows(_ input: Acme_Appointments_V1_ListClinicSlotWorkflowsRequest) async throws
        -> Acme_Appointments_V1_ListClinicSlotWorkflowsResponse
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
            "ListClinicSlotWorkflows",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "clinic_slot",
            action: "ListClinicSlotWorkflows", detail: input.context.traceID
        )
        return Acme_Appointments_V1_ListClinicSlotWorkflowsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processPauseClinicSlotWorkflow(_ input: Acme_Appointments_V1_PauseClinicSlotWorkflowRequest) async throws
        -> Acme_Appointments_V1_PauseClinicSlotWorkflowResponse
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
            "PauseClinicSlotWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try ClinicSlotRecord(input.clinicSlot, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let requests0 = input.clinicSlot.participants.map { element in
            Acme_Appointments_V1_SuggestAppointmentsRequest.with {
                $0.context = input.context
                $0.filter = Acme_Appointments_V1_SuggestAppointmentsRequest.Filter.with {
                    $0.createdAfter = input.clinicSlot.audit.createdAt
                    $0.labels = input.clinicSlot.metadata
                    $0.ownerID = element.participantID
                    $0.region = input.clinicSlot.location.region
                }
            }
        }
        let replies0 = try await FanOut.map(requests0) { candidate in
            try await self.appointmentsAppointmentQuery.suggestAppointments(candidate)
        }
        let reply0 = replies0.first ?? Acme_Appointments_V1_SuggestAppointmentsResponse()
        _ = reply0
        let outbound1 = Acme_Promotions_V1_EstimatePromotionRequest.with {
            $0.context = input.context
            $0.details = Acme_Promotions_V1_EstimatePromotionRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = input.clinicSlot.location.countryCode
                }
            }
            $0.promotion = Acme_Promotions_V1_Promotion.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.clinicSlot.audit.createdAt
                    $0.updatedBy = input.clinicSlot.audit.updatedBy
                }
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.email = input.clinicSlot.organizer.email
                }
            }
        }
        let step1: @Sendable () async throws -> Acme_Promotions_V1_EstimatePromotionResponse = {
            try await self.promotionsPromotionCalculation.estimatePromotion(outbound1)
        }
        let reply1 = try await step1()
        let requests2 = input.clinicSlot.participants.map { element in
            Acme_Appointments_V1_LintAppointmentsRequest.with {
                $0.appointment = Acme_Appointments_V1_Appointment.with {
                    $0.participants = [
                        Acme_Appointments_V1_AppointmentParticipant.with {
                            $0.contact = Acme_Common_V1_ContactInfo.with {
                                $0.email = element.contact.email
                                $0.name = element.contact.name
                                $0.preferredChannel = element.contact.preferredChannel
                            }
                            $0.role = element.role
                        }
                    ]
                }
                $0.context = input.context
            }
        }
        let replies2 = try await FanOut.map(requests2) { candidate in
            try await self.appointmentsAppointmentValidation.lintAppointments(candidate)
        }
        let reply2 = replies2.first ?? Acme_Appointments_V1_LintAppointmentsResponse()
        _ = reply2
        return Acme_Appointments_V1_PauseClinicSlotWorkflowResponse.with {
            $0.clinicSlot = Acme_Appointments_V1_ClinicSlot.with {
                $0.clinicSlotID = input.clinicSlotID
                $0.location = input.clinicSlot.location
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply1.promotion.owner.displayName
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processResumeClinicSlotWorkflow(_ input: Acme_Appointments_V1_ResumeClinicSlotWorkflowRequest) async throws
        -> Acme_Appointments_V1_ResumeClinicSlotWorkflowResponse
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
            "ResumeClinicSlotWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try ClinicSlotRecord(input.clinicSlot, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let requests0 = input.clinicSlot.participants.map { element in
            Acme_Venues_V1_CreateVenueRequest.with {
                $0.context = input.context
                $0.venue = Acme_Venues_V1_Venue.with {
                    $0.audit = Acme_Common_V1_AuditInfo.with {
                        $0.etag = input.clinicSlot.audit.etag
                    }
                    $0.owner = Acme_Identity_V1_UserRef.with {
                        $0.email = element.contact.email
                    }
                }
            }
        }
        let replies0 = try await FanOut.map(requests0) { candidate in
            try await self.venuesVenue.createVenue(candidate)
        }
        let reply0 = replies0.first ?? Acme_Venues_V1_CreateVenueResponse()
        _ = reply0
        let selection1_1: Int32
        switch input.clinicSlot.recurrence {
        case .weekly(let weekly):
            selection1_1 = weekly.interval
        default: selection1_1 = .init()
        }
        let outbound1 = Acme_Appointments_V1_AdvanceAppointmentWorkflowRequest.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.weekly = Acme_Appointments_V1_AppointmentWeeklyRule.with {
                    $0.interval = selection1_1
                }
            }
            $0.context = input.context
        }
        let reply1 = try await self.appointmentsAppointmentWorkflow.advanceAppointmentWorkflow(outbound1)
        return Acme_Appointments_V1_ResumeClinicSlotWorkflowResponse.with {
            $0.clinicSlot = Acme_Appointments_V1_ClinicSlot.with {
                $0.clinicSlotID = input.clinicSlotID
                $0.window = input.clinicSlot.window
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply1.outcome.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processRetryClinicSlotWorkflow(_ input: Acme_Appointments_V1_RetryClinicSlotWorkflowRequest) async throws
        -> Acme_Appointments_V1_RetryClinicSlotWorkflowResponse
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
            "RetryClinicSlotWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try ClinicSlotRecord(input.clinicSlot, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let requests0 = input.clinicSlot.participants.map { element in
            Acme_Venues_V1_ExplainVenueDecisionRequest.with {
                $0.context = input.context
                $0.details = Acme_Venues_V1_ExplainVenueDecisionRequest.Details.with {
                    $0.contact = Acme_Common_V1_ContactInfo.with {
                        $0.email = element.contact.email
                        $0.name = element.contact.name
                        $0.preferredChannel = element.contact.preferredChannel
                    }
                }
            }
        }
        let replies0 = try await FanOut.map(requests0) { candidate in
            try await self.venuesVenueValidation.explainVenueDecision(candidate)
        }
        let reply0 = replies0.first ?? Acme_Venues_V1_ExplainVenueDecisionResponse()
        _ = reply0
        let requests1 = input.clinicSlot.participants.map { element in
            Acme_Search_V1_PreviewSearchIndexRequest.with {
                $0.context = input.context
                $0.details = Acme_Search_V1_PreviewSearchIndexRequest.Details.with {
                    $0.contact = Acme_Common_V1_ContactInfo.with {
                        $0.email = element.contact.email
                        $0.preferredChannel = element.contact.preferredChannel
                    }
                }
            }
        }
        let replies1 = try await FanOut.map(requests1) { candidate in
            try await self.searchSearchIndexValidation.previewSearchIndex(candidate)
        }
        let reply1 = replies1.first ?? Acme_Search_V1_PreviewSearchIndexResponse()
        _ = reply1
        return Acme_Appointments_V1_RetryClinicSlotWorkflowResponse.with {
            $0.clinicSlot = Acme_Appointments_V1_ClinicSlot.with {
                $0.clinicSlotID = input.clinicSlotID
                $0.metadata = input.clinicSlot.metadata
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processSignalClinicSlotWorkflow(_ input: Acme_Appointments_V1_SignalClinicSlotWorkflowRequest) async throws
        -> Acme_Appointments_V1_SignalClinicSlotWorkflowResponse
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
            "SignalClinicSlotWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try ClinicSlotRecord(input.clinicSlot, tenant: input.context.tenantID)
        try await store.save(record.stored)
        var outbound0 = Acme_Prescriptions_V1_CountMedicationTotalsRequest()
        outbound0.context = input.context
        outbound0.filter = Acme_Prescriptions_V1_CountMedicationTotalsRequest.Filter.with {
            $0.region = input.clinicSlot.location.region
        }
        let reply0 = try await self.prescriptionsMedicationReporting.countMedicationTotals(outbound0)
        let outbound1 = Acme_Appointments_V1_ValidateClinicSlotRequest.with {
            $0.clinicSlot = Acme_Appointments_V1_ClinicSlot.with {
                $0.participants = [
                    Acme_Appointments_V1_ClinicSlotParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.name = input.details.notify.name
                        }
                    }
                ]
            }
            $0.context = input.context
        }
        let step1: @Sendable () async throws -> Acme_Appointments_V1_ValidateClinicSlotResponse = {
            try await self.appointmentsClinicSlotValidation.validateClinicSlot(outbound1)
        }
        let reply1 = try await step1()
        return Acme_Appointments_V1_SignalClinicSlotWorkflowResponse.with {
            $0.clinicSlot = Acme_Appointments_V1_ClinicSlot.with {
                $0.clinicSlotID = input.clinicSlotID
                $0.metadata = input.clinicSlot.metadata
            }
            $0.outcome = Acme_Appointments_V1_SignalClinicSlotWorkflowResponse.Outcome.with {
                $0.nextSteps = reply1.outcome.nextSteps
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processStartClinicSlotWorkflow(_ input: Acme_Appointments_V1_StartClinicSlotWorkflowRequest) async throws
        -> Acme_Appointments_V1_StartClinicSlotWorkflowResponse
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
            "StartClinicSlotWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try ClinicSlotRecord(input.clinicSlot, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Authorization_V1_LintAccessPoliciesRequest.with {
            $0.accessPolicy = Acme_Authorization_V1_AccessPolicy.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.clinicSlot.audit.createdAt
                }
            }
            $0.context = input.context
        }
        let reply0 = try await self.authorizationAccessPolicyValidation.lintAccessPolicies(outbound0)
        let outbound1 = Acme_Telehealth_V1_SignalVideoVisitWorkflowRequest.with {
            $0.context = input.context
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = input.clinicSlot.audit.etag
                }
                $0.participants = [
                    Acme_Telehealth_V1_VideoVisitParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.phone = input.details.notify.phone
                        }
                    }
                ]
            }
        }
        async let remote1 = self.telehealthVideoVisitWorkflow.signalVideoVisitWorkflow(outbound1)
        async let persisted1 = store.count(tenant: input.context.tenantID)
        let (reply1, count1) = try await (remote1, persisted1)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count1)])
        let requests2 = input.clinicSlot.participants.map { element in
            Acme_Appointments_V1_ExplainClinicSlotDecisionRequest.with {
                $0.clinicSlot = Acme_Appointments_V1_ClinicSlot.with {
                    $0.participants = [
                        Acme_Appointments_V1_ClinicSlotParticipant.with {
                            $0.participantID = element.participantID
                            $0.role = element.role
                        }
                    ]
                }
                $0.context = input.context
                $0.details = Acme_Appointments_V1_ExplainClinicSlotDecisionRequest.Details.with {
                    $0.contact = Acme_Common_V1_ContactInfo.with {
                        $0.preferredChannel = element.contact.preferredChannel
                    }
                }
            }
        }
        let replies2 = try await FanOut.map(requests2) { candidate in
            try await self.appointmentsClinicSlotValidation.explainClinicSlotDecision(candidate)
        }
        let reply2 = replies2.first ?? Acme_Appointments_V1_ExplainClinicSlotDecisionResponse()
        _ = reply2
        let outbound3 = Acme_Appointments_V1_ApproveAppointmentRequest.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.clinicSlot.audit.createdAt
                }
                $0.participants = [
                    Acme_Appointments_V1_AppointmentParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = input.clinicSlot.organizer.email
                        }
                    }
                ]
            }
            $0.context = input.context
        }
        let reply3 = try await self.startClinicSlotWorkflowStep3.execute(outbound3)
        return Acme_Appointments_V1_StartClinicSlotWorkflowResponse.with {
            $0.clinicSlot = Acme_Appointments_V1_ClinicSlot.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply0.accessPolicy.audit.createdBy
                    $0.updatedBy = reply1.videoVisit.audit.updatedBy
                }
                $0.clinicSlotID = input.clinicSlotID
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = reply3.appointment.location.countryCode
                }
                $0.metadata = reply3.appointment.metadata
                $0.organizer = input.clinicSlot.organizer
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.status = "ok"
            }
        }
    }
}
