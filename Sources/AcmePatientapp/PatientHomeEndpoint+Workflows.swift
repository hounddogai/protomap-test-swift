import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension PatientHomeEndpoint {
    /// Takes a stream of patient homes and answers once at the end.
    func batchCreatePatientHomes(
        request: StreamingServerRequest<Acme_Patientapp_V1_BatchCreatePatientHomesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_BatchCreatePatientHomesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            var response = Acme_Patientapp_V1_BatchCreatePatientHomesResponse()
            var accepted: Int64 = 0
            for try await message in request.messages {
                response = try await processBatchCreatePatientHomes(message)
                accepted += 1
            }
            response.accepted = accepted
            return ServerResponse(message: response)
        }
    }

    /// Returns several patient homes at once.
    func batchGetPatientHomes(
        request: ServerRequest<Acme_Patientapp_V1_BatchGetPatientHomesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_BatchGetPatientHomesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processBatchGetPatientHomes(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Creates a patient home.
    func clonePatientHome(
        request: ServerRequest<Acme_Patientapp_V1_ClonePatientHomeRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_ClonePatientHomeResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processClonePatientHome(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Creates a patient home.
    func createPatientHome(
        request: ServerRequest<Acme_Patientapp_V1_CreatePatientHomeRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_CreatePatientHomeResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCreatePatientHome(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Deletes a patient home.
    func deletePatientHome(
        request: ServerRequest<Acme_Patientapp_V1_DeletePatientHomeRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_DeletePatientHomeResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processDeletePatientHome(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a patient home.
    func getPatientHome(
        request: ServerRequest<Acme_Patientapp_V1_GetPatientHomeRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_GetPatientHomeResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetPatientHome(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists patient homes a page at a time.
    func listPatientHomes(
        request: ServerRequest<Acme_Patientapp_V1_ListPatientHomesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_ListPatientHomesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListPatientHomes(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists patient homes a page at a time.
    func searchPatientHomes(
        request: ServerRequest<Acme_Patientapp_V1_SearchPatientHomesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_SearchPatientHomesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSearchPatientHomes(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Changes a patient home.
    func updatePatientHome(
        request: ServerRequest<Acme_Patientapp_V1_UpdatePatientHomeRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_UpdatePatientHomeResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processUpdatePatientHome(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Streams the changes of patient homes as they happen.
    func watchPatientHomes(
        request: ServerRequest<Acme_Patientapp_V1_WatchPatientHomesRequest>,
        context: ServerContext
    ) async throws -> StreamingServerResponse<Acme_Patientapp_V1_WatchPatientHomesResponse> {
        return StreamingServerResponse { writer in
            try await CallerScope.$metadata.withValue(request.metadata) {
                let response = try await self.processWatchPatientHomes(request.message)
                try await writer.write(response)
                return [:]
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processBatchCreatePatientHomes(_ input: Acme_Patientapp_V1_BatchCreatePatientHomesRequest) async throws
        -> Acme_Patientapp_V1_BatchCreatePatientHomesResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.header.format)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "audit", detail: input.header.format
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "BatchCreatePatientHomes",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "BatchCreatePatientHomes", detail: input.context.traceID
        )
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        let archive = Data(try input.context.jsonString().utf8)
        let restoredContext = try Acme_Common_V1_RequestContext(
            jsonString: String(decoding: archive, as: UTF8.self)
        )
        _ = try await self.prescriptionsMedicationSync.pushMedication(
            Acme_Prescriptions_V1_PushMedicationRequest.with {
                $0.context = restoredContext
                $0.details = Acme_Prescriptions_V1_PushMedicationRequest.Details.with {
                    $0.payload = archive
                }
            })
        let selection0_1: String
        switch input.chunk {
        case .record(let record):
            selection0_1 = record.customer.email
        default: selection0_1 = .init()
        }
        let outbound0 = Acme_Appointments_V1_PauseAppointmentWorkflowRequest.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.participants = [
                    Acme_Appointments_V1_AppointmentParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = selection0_1
                        }
                    }
                ]
            }
            $0.context = input.context
        }
        let reply0 = try await self.appointmentsAppointmentWorkflow.pauseAppointmentWorkflow(outbound0)
        let selection1_1: String
        switch input.chunk {
        case .header(let header):
            selection1_1 = header.submittedBy.email
        default: selection1_1 = .init()
        }
        let outbound1 = Acme_Patientapp_V1_SignalPatientHomeWorkflowRequest.with {
            $0.context = input.context
            $0.details = Acme_Patientapp_V1_SignalPatientHomeWorkflowRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.email = selection1_1
                }
            }
        }
        let reply1 = try await self.patientappPatientHomeWorkflow.signalPatientHomeWorkflow(outbound1)
        return Acme_Patientapp_V1_BatchCreatePatientHomesResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.details = Projection.firstValue(
                    [
                        reply0.result.details,
                        reply1.result.details,
                    ], default: .init())
                $0.status = reply1.outcome.status
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processBatchGetPatientHomes(_ input: Acme_Patientapp_V1_BatchGetPatientHomesRequest) async throws
        -> Acme_Patientapp_V1_BatchGetPatientHomesResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "BatchGetPatientHomes",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "BatchGetPatientHomes", detail: input.context.traceID
        )
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        let outbound0 = Acme_Patientapp_V1_SuggestPatientHomesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Patientapp_V1_SuggestPatientHomesRequest.Filter.with {
                $0.createdAfter = input.context.deadline
            }
        }
        let json0 = try outbound0.jsonString()
        let decoded0 = try Acme_Patientapp_V1_SuggestPatientHomesRequest(jsonString: json0)
        let reply0 = try await self.patientappPatientHomeQuery.suggestPatientHomes(decoded0)
        return Acme_Patientapp_V1_BatchGetPatientHomesResponse.with {
            $0.pageInfo = Acme_Common_V1_PageInfo.with {
                $0.totalSize = reply0.pageInfo.totalSize
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processClonePatientHome(_ input: Acme_Patientapp_V1_ClonePatientHomeRequest) async throws
        -> Acme_Patientapp_V1_ClonePatientHomeResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.patientHome.assignee.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "audit", detail: input.patientHome.assignee.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ClonePatientHome",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PatientHomeRecord(input.patientHome, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Patientapp_V1_SummarizeCareInboxesRequest.forPatientHomeEndpointClonePatientHome0(
            input
        )
        let reply0 = try await self.patientappCareInboxQuery.summarizeCareInboxes(outbound0)
        let selection1_1: String
        switch input.patientHome.origin {
        case .customer(let customer):
            selection1_1 = customer.email
        default: selection1_1 = .init()
        }
        let outbound1 = Acme_Telehealth_V1_AdvanceTriageWorkflowRequest.with {
            $0.context = input.context
            $0.details = Acme_Telehealth_V1_AdvanceTriageWorkflowRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.email = selection1_1
                }
            }
        }
        let reply1 = try await self.telehealthTriageWorkflow.advanceTriageWorkflow(outbound1)
        return Acme_Patientapp_V1_ClonePatientHomeResponse.with {
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.patientHomeID = input.patientHome.patientHomeID
                $0.sla = Acme_Patientapp_V1_PatientHomeSla.with {
                    $0.dueAt = reply1.triage.sla.dueAt
                }
                $0.subject = input.patientHome.subject
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processCreatePatientHome(_ input: Acme_Patientapp_V1_CreatePatientHomeRequest) async throws
        -> Acme_Patientapp_V1_CreatePatientHomeResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.patientHome.assignee.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "audit", detail: input.patientHome.assignee.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "CreatePatientHome",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PatientHomeRecord(input.patientHome, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Patientapp_V1_SummarizeCareInboxesRequest.with {
            $0.annotations = input.patientHome.customFields
            $0.context = input.context
            $0.details = Acme_Patientapp_V1_SummarizeCareInboxesRequest.Details.with {
                $0.filters = input.context.baggage
            }
        }
        let reply0 = try await self.patientappCareInboxQuery.summarizeCareInboxes(
            outbound0, metadata: ["x-acme-region": .string(settings.region)]
        )
        let outbound1 = Acme_Patients_V1_ListPendingPatientsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Patients_V1_ListPendingPatientsRequest.Filter.with {
                $0.createdAfter = input.patientHome.audit.updatedAt
                $0.labels = reply0.result.details
                $0.ownerID = input.patientHome.assignee.userID
            }
        }
        let reply1 = try await RPCOperations.call(outbound1) { request in
            try await self.patientsPatientApproval.listPendingPatients(request)
        }
        return Acme_Patientapp_V1_CreatePatientHomeResponse.with {
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.priority = input.patientHome.priority
                $0.requester = input.patientHome.requester
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply1.result.message
                $0.status = reply0.result.status
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processDeletePatientHome(_ input: Acme_Patientapp_V1_DeletePatientHomeRequest) async throws
        -> Acme_Patientapp_V1_DeletePatientHomeResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.patientHomeID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "audit", detail: input.patientHomeID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "DeletePatientHome",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "DeletePatientHome", detail: input.context.traceID
        )
        let outbound0 = Acme_Notifications_V1_ValidateNotificationRequest.with {
            $0.context = Projection.read(input, at: \Acme_Patientapp_V1_DeletePatientHomeRequest.context)
            $0.notification = Acme_Notifications_V1_Notification.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = Projection.read(input, at: \Acme_Patientapp_V1_DeletePatientHomeRequest.etag)
                }
            }
            $0.reason = Projection.read(input, at: \Acme_Patientapp_V1_DeletePatientHomeRequest.reason)
        }
        let reply0 = try await self.notificationsNotificationValidation.validateNotification(outbound0)
        let outbound1 = Acme_Patientapp_V1_DisconnectCareInboxSourceRequest.with {
            $0.annotations = reply0.result.details
            $0.context = input.context
            $0.details = Acme_Patientapp_V1_DisconnectCareInboxSourceRequest.Details.with {
                $0.messageID = reply0.result.message
                $0.receivedAt = reply0.notification.audit.updatedAt
            }
            $0.reason = input.reason
        }
        let step1: @Sendable () async throws -> Acme_Patientapp_V1_DisconnectCareInboxSourceResponse = {
            try await self.patientappCareInboxIntegration.disconnectCareInboxSource(outbound1)
        }
        let reply1 = try await step1()
        var outbound2 = Acme_Patientapp_V1_FindPatientHomesRequest()
        outbound2.context = input.context
        outbound2.filter = Acme_Patientapp_V1_FindPatientHomesRequest.Filter.with {
            $0.createdAfter = reply0.notification.audit.updatedAt
            $0.ownerID = reply0.notification.assignee.userID
            $0.region = reply1.careInbox.billingAddress.region
        }
        let reply2 = try await self.patientappPatientHomeQuery.findPatientHomes(outbound2)
        return Acme_Patientapp_V1_DeletePatientHomeResponse.with {
            $0.effectiveAt = reply1.outcome.effectiveAt
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply2.result.correlationID
                $0.message = reply0.result.message
                $0.referenceIds = reply2.result.referenceIds
                $0.status = reply0.outcome.status
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processGetPatientHome(_ input: Acme_Patientapp_V1_GetPatientHomeRequest) async throws
        -> Acme_Patientapp_V1_GetPatientHomeResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "GetPatientHome",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "GetPatientHome", detail: input.context.traceID
        )
        let outbound0 = Acme_Patientapp_V1_CancelPatientHomeWorkflowRequest.with {
            $0.context = input.context
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.patientHomeID = input.patientHomeID
            }
        }
        let step0: @Sendable () async throws -> Acme_Patientapp_V1_CancelPatientHomeWorkflowResponse = {
            try await self.patientappPatientHomeWorkflow.cancelPatientHomeWorkflow(outbound0)
        }
        let reply0 = try await step0()
        let selection1_1: String
        switch reply0.patientHome.origin {
        case .customer(let customer):
            selection1_1 = customer.email
        default: selection1_1 = .init()
        }
        let outbound1 = Acme_Notifications_V1_CloneNotificationRequest.with {
            $0.context = input.context
            $0.notification = Acme_Notifications_V1_Notification.with {
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = selection1_1
                }
            }
        }
        let reply1 = try await self.notificationsNotification.cloneNotification(outbound1)
        return Acme_Patientapp_V1_GetPatientHomeResponse.with {
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply1.notification.assignee.displayName
                }
                $0.patientHomeID = input.patientHomeID
                $0.sla = Acme_Patientapp_V1_PatientHomeSla.with {
                    $0.policyID = reply0.patientHome.sla.policyID
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processListPatientHomes(_ input: Acme_Patientapp_V1_ListPatientHomesRequest) async throws
        -> Acme_Patientapp_V1_ListPatientHomesResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ListPatientHomes",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "ListPatientHomes", detail: input.context.traceID
        )
        let outbound0 = Acme_Patients_V1_RetryPatientWorkflowRequest.with {
            $0.context = input.context
            $0.details = Acme_Patients_V1_RetryPatientWorkflowRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.context.actor.email
                }
            }
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
            }
        }
        let reply0 = try await self.patientsPatientWorkflow.retryPatientWorkflow(outbound0)
        return Acme_Patientapp_V1_ListPatientHomesResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processSearchPatientHomes(_ input: Acme_Patientapp_V1_SearchPatientHomesRequest) async throws
        -> Acme_Patientapp_V1_SearchPatientHomesResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SearchPatientHomes",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "SearchPatientHomes", detail: input.context.traceID
        )
        let outbound0 = Acme_Patientapp_V1_SignalPatientHomeWorkflowRequest.with {
            $0.context = input.context
            $0.details = Acme_Patientapp_V1_SignalPatientHomeWorkflowRequest.Details.with {
                $0.parameters = input.filter.labels
            }
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.email = input.context.actor.email
                    $0.userID = input.context.actor.userID
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.filter.createdAfter
                }
            }
        }
        async let remote0 = self.patientappPatientHomeWorkflow.signalPatientHomeWorkflow(outbound0)
        async let persisted0 = store.count(tenant: input.context.tenantID)
        let (reply0, count0) = try await (remote0, persisted0)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count0)])
        return Acme_Patientapp_V1_SearchPatientHomesResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply0.outcome.status
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processUpdatePatientHome(_ input: Acme_Patientapp_V1_UpdatePatientHomeRequest) async throws
        -> Acme_Patientapp_V1_UpdatePatientHomeResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.patientHome.assignee.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "audit", detail: input.patientHome.assignee.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "UpdatePatientHome",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PatientHomeRecord(input.patientHome, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let requests0 = input.patientHome.history.map { element in
            Acme_Fanportal_V1_CountFanSessionsRequest.with {
                $0.context = input.context
                $0.filter = Acme_Fanportal_V1_CountFanSessionsRequest.Filter.with {
                    $0.createdAfter = element.changedAt
                    $0.labels = input.patientHome.customFields
                    $0.ownerID = input.patientHome.customer.patientID
                }
            }
        }
        let replies0 = try await FanOut.map(requests0) { candidate in
            try await self.fanportalFanSessionQuery.countFanSessions(candidate)
        }
        let reply0 = replies0.first ?? Acme_Fanportal_V1_CountFanSessionsResponse()
        _ = reply0
        let selection1_1: String
        switch input.patientHome.origin {
        case .customer(let customer):
            selection1_1 = customer.displayName
        default: selection1_1 = .init()
        }
        let selection1_2: String
        switch input.patientHome.origin {
        case .customer(let customer):
            selection1_2 = customer.email
        default: selection1_2 = .init()
        }
        let outbound1 = Acme_Search_V1_ScoreSearchIndexRequest.with {
            $0.context = input.context
            $0.searchIndex = Acme_Search_V1_SearchIndex.with {
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.displayName = selection1_1
                    $0.email = selection1_2
                    $0.userID = input.patientHome.assignee.userID
                }
            }
        }
        let reply1 = try await self.searchSearchIndexValidation.scoreSearchIndex(outbound1)
        let selection2_1: String
        switch reply1.searchIndex.locator {
        case .address(let address):
            selection2_1 = address.countryCode
        default: selection2_1 = .init()
        }
        let outbound2 = Acme_Patients_V1_RejectPatientRequest.with {
            $0.context = input.context
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = selection2_1
                }
            }
        }
        let reply2 = try await self.patientsPatientApproval.rejectPatient(outbound2)
        let outbound3 = Acme_Patients_V1_RetryPatientWorkflowRequest.with {
            $0.context = input.context
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.phone = input.patientHome.requester.phone
                }
            }
        }
        let reply3 = try await self.updatePatientHomeStep3.execute(outbound3)
        return Acme_Patientapp_V1_UpdatePatientHomeResponse.with {
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.userID = reply1.searchIndex.owner.userID
                }
                $0.patientHomeID = input.patientHome.patientHomeID
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.preferredChannel = reply3.patient.contact.preferredChannel
                }
                $0.status = input.patientHome.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply2.result.details
                $0.referenceIds = reply1.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processWatchPatientHomes(_ input: Acme_Patientapp_V1_WatchPatientHomesRequest) async throws
        -> Acme_Patientapp_V1_WatchPatientHomesResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.query)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "audit", detail: input.filter.query
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "WatchPatientHomes",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "WatchPatientHomes", detail: input.context.traceID
        )
        let outbound0 = Acme_Patientapp_V1_ResumePatientHomeWorkflowRequest.with {
            $0.context = input.context
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.email = input.subscriber.email
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.name = input.subscriber.name
                    $0.phone = input.subscriber.phone
                    $0.preferredChannel = input.subscriber.preferredChannel
                }
            }
        }
        let port0 = RPCOperations.port { (request: Acme_Patientapp_V1_ResumePatientHomeWorkflowRequest) in
            try await self.patientappPatientHomeWorkflow.resumePatientHomeWorkflow(request)
        }
        let reply0 = try await port0.execute(outbound0)
        let outbound1 = Acme_Notifications_V1_ExportNotificationsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Notifications_V1_ExportNotificationsRequest.Filter.with {
                $0.ownerID = input.filter.ownerID
            }
        }
        let reply1 = try await self.notificationsNotificationQuery.exportNotifications(outbound1) { response in
            var latest = Acme_Notifications_V1_ExportNotificationsResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        _ = reply1
        let outbound2 = Acme_Dispatch_V1_ResolveDispatchOrdersRequest.with {
            $0.context = input.context
        }
        let reply2 = try await self.watchPatientHomesStep2(outbound2)
        let outbound3 = Acme_Patientapp_V1_CountCareInboxesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Patientapp_V1_CountCareInboxesRequest.Filter.with {
                $0.createdAfter = input.filter.createdAfter
                $0.ownerID = input.filter.ownerID
            }
        }
        guard let execute3 = self.watchPatientHomesStep3[settings.region] ?? self.watchPatientHomesStep3["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply3 = try await execute3(outbound3)
        return Acme_Patientapp_V1_WatchPatientHomesResponse.with {
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.email = reply0.patientHome.assignee.email
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.subscriber.email
                    $0.preferredChannel = input.subscriber.preferredChannel
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = Projection.firstValue(
                    [
                        reply2.result.correlationID,
                        reply3.result.correlationID,
                    ], default: .init())
                $0.details = reply2.result.details
                $0.status = "ok"
            }
        }
    }
}
