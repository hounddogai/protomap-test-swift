import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension PatientHomeIntegrationEndpoint {
    /// Acknowledges a patient home.
    func acknowledgePatientHomeEvent(
        request: ServerRequest<Acme_Patientapp_V1_AcknowledgePatientHomeEventRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_AcknowledgePatientHomeEventResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processAcknowledgePatientHomeEvent(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Connects a patient home.
    func connectPatientHomeSource(
        request: ServerRequest<Acme_Patientapp_V1_ConnectPatientHomeSourceRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_ConnectPatientHomeSourceResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processConnectPatientHomeSource(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Disconnects a patient home.
    func disconnectPatientHomeSource(
        request: ServerRequest<Acme_Patientapp_V1_DisconnectPatientHomeSourceRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_DisconnectPatientHomeSourceResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processDisconnectPatientHomeSource(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Takes a stream of patient homes and answers once at the end.
    func ingestPatientHomeEvents(
        request: StreamingServerRequest<Acme_Patientapp_V1_IngestPatientHomeEventsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_IngestPatientHomeEventsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            var response = Acme_Patientapp_V1_IngestPatientHomeEventsResponse()
            var accepted: Int64 = 0
            for try await message in request.messages {
                response = try await processIngestPatientHomeEvents(message)
                accepted += 1
            }
            response.accepted = accepted
            return ServerResponse(message: response)
        }
    }

    /// Lists patient homes a page at a time.
    func listPatientHomeSources(
        request: ServerRequest<Acme_Patientapp_V1_ListPatientHomeSourcesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_ListPatientHomeSourcesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListPatientHomeSources(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Exchanges changes of patient homes with a peer.
    func relayPatientHomeMessages(
        request: StreamingServerRequest<Acme_Patientapp_V1_RelayPatientHomeMessagesRequest>,
        context: ServerContext
    ) async throws -> StreamingServerResponse<Acme_Patientapp_V1_RelayPatientHomeMessagesResponse> {
        return StreamingServerResponse { writer in
            try await CallerScope.$metadata.withValue(request.metadata) {
                for try await message in request.messages {
                    let response = try await self.processRelayPatientHomeMessages(message)
                    try await writer.write(response)
                }
                return [:]
            }
        }
    }

    /// Replays a patient home.
    func replayPatientHomeEvents(
        request: ServerRequest<Acme_Patientapp_V1_ReplayPatientHomeEventsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_ReplayPatientHomeEventsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processReplayPatientHomeEvents(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processAcknowledgePatientHomeEvent(_ input: Acme_Patientapp_V1_AcknowledgePatientHomeEventRequest) async throws
        -> Acme_Patientapp_V1_AcknowledgePatientHomeEventResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.endpoint)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "audit", detail: input.details.endpoint
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "AcknowledgePatientHomeEvent",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "AcknowledgePatientHomeEvent", detail: input.context.traceID
        )
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
        _ = try await self.patientsPatientSync.resolvePatientConflict(
            Acme_Patients_V1_ResolvePatientConflictRequest.with {
                $0.context = restoredContext
                $0.details = Acme_Patients_V1_ResolvePatientConflictRequest.Details.with {
                    $0.payload = archive
                }
            })
        let outbound0 = Acme_Patients_V1_DelegatePatientApprovalRequest.with {
            $0.context = input.context
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.email = input.context.actor.email
                }
            }
            $0.reason = input.reason
        }
        let port0 = RPCOperations.port { (request: Acme_Patients_V1_DelegatePatientApprovalRequest) in
            try await self.patientsPatientApproval.delegatePatientApproval(request)
        }
        let reply0 = try await port0.execute(outbound0)
        let outbound1 = Acme_Patientapp_V1_AdvancePatientHomeWorkflowRequest.with {
            $0.context = input.context
            $0.details = Acme_Patientapp_V1_AdvancePatientHomeWorkflowRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply0.patient.contact.email
                    $0.name = reply0.patient.contact.name
                }
            }
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.customer = Acme_Patients_V1_PatientRef.with {
                    $0.email = reply0.patient.relationshipManager.email
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.preferredChannel = reply0.patient.contact.preferredChannel
                }
            }
        }
        let reply1 = try await self.acknowledgePatientHomeEventStep1(outbound1)
        let outbound2 = Acme_Patientapp_V1_RetryCareInboxWorkflowRequest.with {
            $0.careInbox = Acme_Patientapp_V1_CareInbox.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply1.patientHome.audit.createdBy
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.locality = reply0.patient.primaryAddress.locality
                }
            }
            $0.context = input.context
            $0.details = Acme_Patientapp_V1_RetryCareInboxWorkflowRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.name = reply0.patient.contact.name
                    $0.preferredChannel = reply1.patientHome.requester.preferredChannel
                }
            }
        }
        guard
            let execute2 = self.acknowledgePatientHomeEventStep2[settings.region]
                ?? self.acknowledgePatientHomeEventStep2["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply2 = try await execute2(outbound2)
        return Acme_Patientapp_V1_AcknowledgePatientHomeEventResponse.with {
            $0.outcome = Acme_Patientapp_V1_AcknowledgePatientHomeEventResponse.Outcome.with {
                $0.status = reply1.result.status
            }
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply2.careInbox.audit.createdBy
                }
                $0.comments = [
                    Acme_Patientapp_V1_PatientHomeComment.with {
                        $0.createdAt = reply0.patient.audit.createdAt
                    }
                ]
                $0.patientHomeID = input.patientHomeID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = Projection.firstValue(
                    [
                        reply0.result.details,
                        reply2.result.details,
                    ], default: .init())
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processConnectPatientHomeSource(_ input: Acme_Patientapp_V1_ConnectPatientHomeSourceRequest) async throws
        -> Acme_Patientapp_V1_ConnectPatientHomeSourceResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.endpoint)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "audit", detail: input.details.endpoint
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ConnectPatientHomeSource",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "ConnectPatientHomeSource", detail: input.context.traceID
        )
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        let outbound0 = Acme_Patientapp_V1_InspectPatientHomeWorkflowRequest.with {
            $0.context = input.context
            $0.patientHomeID = input.patientHomeID
        }
        let reply0 = try await self.patientappPatientHomeWorkflow.inspectPatientHomeWorkflow(outbound0)
        let outbound1 = Acme_Patientapp_V1_PausePatientHomeWorkflowRequest.with {
            $0.context = input.context
            $0.details = Acme_Patientapp_V1_PausePatientHomeWorkflowRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.preferredChannel = reply0.patientHome.requester.preferredChannel
                }
            }
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.phone = reply0.patientHome.requester.phone
                }
            }
        }
        let envelope1 = try Google_Protobuf_Any(message: outbound1)
        let unpacked1 = try Acme_Patientapp_V1_PausePatientHomeWorkflowRequest(unpackingAny: envelope1)
        let reply1 = try await self.patientappPatientHomeWorkflow.pausePatientHomeWorkflow(unpacked1)
        let outbound2 = Acme_Patientapp_V1_AdvanceCareInboxWorkflowRequest.with {
            $0.careInbox = Acme_Patientapp_V1_CareInbox.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply1.patientHome.audit.createdBy
                    $0.etag = reply0.patientHome.audit.etag
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = reply0.patientHome.assignee.displayName
                }
            }
            $0.context = input.context
        }
        let json2 = try outbound2.jsonString()
        let decoded2 = try Acme_Patientapp_V1_AdvanceCareInboxWorkflowRequest(jsonString: json2)
        let reply2 = try await self.patientappCareInboxWorkflow.advanceCareInboxWorkflow(decoded2)
        let selection3_2: String
        switch reply0.patientHome.origin {
        case .customer(let customer):
            selection3_2 = customer.displayName
        default: selection3_2 = .init()
        }
        let selection3_3: String
        switch reply0.patientHome.origin {
        case .customer(let customer):
            selection3_3 = customer.email
        default: selection3_3 = .init()
        }
        let outbound3 = Acme_Patients_V1_SubmitAllergyRequest.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.email = selection3_3
                }
            }
            $0.context = input.context
            $0.details = Acme_Patients_V1_SubmitAllergyRequest.Details.with {
                $0.approver = Acme_Identity_V1_UserRef.with {
                    $0.displayName = selection3_2
                    $0.userID = reply0.patientHome.assignee.userID
                }
            }
        }
        let reply3 = try await self.patientsAllergyApproval.submitAllergy(outbound3)
        return Acme_Patientapp_V1_ConnectPatientHomeSourceResponse.with {
            $0.outcome = Acme_Patientapp_V1_ConnectPatientHomeSourceResponse.Outcome.with {
                $0.referenceID = reply3.outcome.referenceID
            }
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply2.careInbox.audit.createdAt
                    $0.updatedAt = reply1.patientHome.audit.updatedAt
                }
                $0.patientHomeID = input.patientHomeID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply2.result.correlationID
                $0.status = reply0.result.status
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processDisconnectPatientHomeSource(_ input: Acme_Patientapp_V1_DisconnectPatientHomeSourceRequest) async throws
        -> Acme_Patientapp_V1_DisconnectPatientHomeSourceResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.endpoint)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "audit", detail: input.details.endpoint
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "DisconnectPatientHomeSource",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "DisconnectPatientHomeSource", detail: input.context.traceID
        )
        let outbound0 = Acme_Documents_V1_WatchDocumentsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Documents_V1_WatchDocumentsRequest.Filter.with {
                $0.createdAfter = input.details.receivedAt
                $0.labels = input.annotations
                $0.ownerID = input.details.messageID
            }
            $0.subscriber = Acme_Common_V1_ContactInfo.with {
                $0.email = input.context.actor.email
            }
        }
        let reply0 = try await self.documentsDocument.watchDocuments(outbound0) { response in
            var latest = Acme_Documents_V1_WatchDocumentsResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        _ = reply0
        let outbound1 =
            Acme_Patientapp_V1_SignalPatientHomeWorkflowRequest
            .forPatientHomeIntegrationEndpointDisconnectPatientHomeSource1(
                input
            )
        let reply1 = try await self.patientappPatientHomeWorkflow.signalPatientHomeWorkflow(outbound1)
        return Acme_Patientapp_V1_DisconnectPatientHomeSourceResponse.with {
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.patientHomeID = input.patientHomeID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processIngestPatientHomeEvents(_ input: Acme_Patientapp_V1_IngestPatientHomeEventsRequest) async throws
        -> Acme_Patientapp_V1_IngestPatientHomeEventsResponse
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
            "IngestPatientHomeEvents",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "IngestPatientHomeEvents", detail: input.context.traceID
        )
        let selection0_1: String
        switch input.chunk {
        case .record(let record):
            selection0_1 = record.assignee.email
        default: selection0_1 = .init()
        }
        let selection0_2: String
        switch input.chunk {
        case .record(let record):
            selection0_2 = record.customer.displayName
        default: selection0_2 = .init()
        }
        let selection0_3: String
        switch input.chunk {
        case .record(let record):
            selection0_3 = record.customer.email
        default: selection0_3 = .init()
        }
        let outbound0 = Acme_Patients_V1_SubmitAllergyRequest.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.email = selection0_1
                }
            }
            $0.context = input.context
            $0.details = Acme_Patients_V1_SubmitAllergyRequest.Details.with {
                $0.approver = Acme_Identity_V1_UserRef.with {
                    $0.displayName = selection0_2
                    $0.email = selection0_3
                }
            }
        }
        let reply0 = try await self.patientsAllergyApproval.submitAllergy(outbound0)
        let selection1_1: Google_Protobuf_Timestamp
        switch input.chunk {
        case .record(let record):
            selection1_1 = record.audit.updatedAt
        default: selection1_1 = .init()
        }
        let outbound1 = Acme_Documents_V1_FindDocumentsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Documents_V1_FindDocumentsRequest.Filter.with {
                $0.createdAfter = selection1_1
                $0.labels = reply0.result.details
                $0.ownerID = reply0.outcome.referenceID
            }
        }
        let reply1 = try await self.documentsDocumentQuery.findDocuments(outbound1)
        let requests2 = input.record.comments.map { element in
            Acme_Careplans_V1_ApproveCarePlanRequest.with {
                $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                    $0.audit = Acme_Common_V1_AuditInfo.with {
                        $0.createdAt = element.createdAt
                    }
                }
                $0.context = input.context
                $0.details = Acme_Careplans_V1_ApproveCarePlanRequest.Details.with {
                    $0.approver = Acme_Identity_V1_UserRef.with {
                        $0.email = element.authorEmail
                    }
                }
            }
        }
        let replies2 = try await FanOut.map(requests2) { candidate in
            try await self.careplansCarePlanApproval.approveCarePlan(candidate)
        }
        let reply2 = replies2.first ?? Acme_Careplans_V1_ApproveCarePlanResponse()
        _ = reply2
        return Acme_Patientapp_V1_IngestPatientHomeEventsResponse.with {
            $0.rejections = [
                Acme_Patientapp_V1_IngestPatientHomeEventsResponse.Rejection.with {
                    $0.sequence = reply0.allergy.sequence
                }
            ]
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply1.result.details
                $0.status = reply0.outcome.status
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processListPatientHomeSources(_ input: Acme_Patientapp_V1_ListPatientHomeSourcesRequest) async throws
        -> Acme_Patientapp_V1_ListPatientHomeSourcesResponse
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
            "ListPatientHomeSources",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "ListPatientHomeSources", detail: input.context.traceID
        )
        let outbound0 = Acme_Patients_V1_CancelPatientWorkflowRequest.with {
            $0.context = input.context
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
            }
        }
        let reply0 = try await self.patientsPatientWorkflow.cancelPatientWorkflow(
            outbound0, metadata: ["x-acme-region": .string(settings.region)]
        )
        let outbound1 = Acme_Patientapp_V1_ListCareInboxWorkflowsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Patientapp_V1_ListCareInboxWorkflowsRequest.Filter.with {
                $0.ownerID = input.filter.ownerID
                $0.region = reply0.patient.primaryAddress.region
            }
            $0.page = Acme_Common_V1_PageRequest.with {
                $0.pageSize = input.page.pageSize
            }
        }
        let reply1 = try await RPCOperations.call(outbound1) { request in
            try await self.patientappCareInboxWorkflow.listCareInboxWorkflows(request)
        }
        return Acme_Patientapp_V1_ListPatientHomeSourcesResponse.with {
            $0.pageInfo = Acme_Common_V1_PageInfo.with {
                $0.totalSize = reply1.pageInfo.totalSize
            }
            $0.patientHomes = [
                Acme_Patientapp_V1_PatientHome.with {
                    $0.audit = Acme_Common_V1_AuditInfo.with {
                        $0.createdBy = reply0.patient.audit.createdBy
                    }
                }
            ]
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processRelayPatientHomeMessages(_ input: Acme_Patientapp_V1_RelayPatientHomeMessagesRequest) async throws
        -> Acme_Patientapp_V1_RelayPatientHomeMessagesResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.ack.status)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "audit", detail: input.ack.status
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "RelayPatientHomeMessages",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "RelayPatientHomeMessages", detail: input.context.traceID
        )
        let selection0_1: Google_Protobuf_Timestamp
        switch input.frame {
        case .change(let change):
            selection0_1 = change.sla.dueAt
        default: selection0_1 = .init()
        }
        let selection0_2: String
        switch input.frame {
        case .change(let change):
            selection0_2 = change.patientHomeID
        default: selection0_2 = .init()
        }
        let selection0_3: [String: String]
        switch input.frame {
        case .change(let change):
            selection0_3 = change.customFields
        default: selection0_3 = .init()
        }
        let outbound0 = Acme_Prescriptions_V1_ListPendingPrescriptionsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Prescriptions_V1_ListPendingPrescriptionsRequest.Filter.with {
                $0.createdAfter = selection0_1
                $0.labels = selection0_3
                $0.ownerID = selection0_2
            }
        }
        let reply0 = try await self.prescriptionsPrescriptionApproval.listPendingPrescriptions(outbound0)
        let selection1_1: String
        switch input.frame {
        case .change(let change):
            selection1_1 = change.assignee.email
        default: selection1_1 = .init()
        }
        let selection1_2: Acme_Common_V1_PersonName
        switch input.frame {
        case .change(let change):
            selection1_2 = change.requester.name
        default: selection1_2 = .init()
        }
        let selection1_3: Google_Protobuf_Timestamp
        switch input.frame {
        case .change(let change):
            selection1_3 = change.sla.dueAt
        default: selection1_3 = .init()
        }
        let selection1_4: Google_Protobuf_Timestamp
        switch input.frame {
        case .change(let change):
            selection1_4 = change.audit.createdAt
        default: selection1_4 = .init()
        }
        let outbound1 = Acme_Patientapp_V1_PausePatientHomeWorkflowRequest.with {
            $0.context = input.context
            $0.details = Acme_Patientapp_V1_PausePatientHomeWorkflowRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.name = selection1_2
                }
            }
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = selection1_4
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = selection1_1
                }
                $0.sla = Acme_Patientapp_V1_PatientHomeSla.with {
                    $0.dueAt = selection1_3
                }
            }
        }
        let reply1 = try await self.patientappPatientHomeWorkflow.pausePatientHomeWorkflow(outbound1)
        let outbound2 = Acme_Payroll_V1_SummarizePayRunsRequest.with {
            $0.annotations = reply1.patientHome.customFields
            $0.context = Projection.read(input, at: \Acme_Patientapp_V1_RelayPatientHomeMessagesRequest.context)
            $0.details = Acme_Payroll_V1_SummarizePayRunsRequest.Details.with {
                $0.filters = reply1.result.details
            }
        }
        let reply2 = try await self.payrollPayRunQuery.summarizePayRuns(outbound2)
        return Acme_Patientapp_V1_RelayPatientHomeMessagesResponse.with {
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.customFields = input.change.customFields
                $0.subject = input.change.subject
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = Projection.firstValue(
                    [
                        reply0.result.correlationID,
                        reply1.result.correlationID,
                        reply2.result.correlationID,
                    ], default: .init())
                $0.message = Projection.firstValue(
                    [
                        reply0.result.message,
                        reply2.result.message,
                    ], default: .init())
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processReplayPatientHomeEvents(_ input: Acme_Patientapp_V1_ReplayPatientHomeEventsRequest) async throws
        -> Acme_Patientapp_V1_ReplayPatientHomeEventsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.endpoint)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "audit", detail: input.details.endpoint
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ReplayPatientHomeEvents",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "ReplayPatientHomeEvents", detail: input.context.traceID
        )
        let outbound0 = Acme_Fanportal_V1_WatchFanSessionsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Fanportal_V1_WatchFanSessionsRequest.Filter.with {
                $0.createdAfter = input.details.receivedAt
                $0.labels = input.annotations
                $0.ownerID = input.details.messageID
            }
            $0.subscriber = Acme_Common_V1_ContactInfo.with {
                $0.email = input.context.actor.email
            }
        }
        let reply0 = try await self.fanportalFanSession.watchFanSessions(outbound0) { response in
            var latest = Acme_Fanportal_V1_WatchFanSessionsResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        _ = reply0
        let outbound1 = Acme_Audit_V1_SuggestAuditEventsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Audit_V1_SuggestAuditEventsRequest.Filter.with {
                $0.createdAfter = input.details.receivedAt
                $0.labels = input.annotations
                $0.ownerID = input.details.messageID
            }
        }
        let step1: @Sendable () async throws -> Acme_Audit_V1_SuggestAuditEventsResponse = {
            try await self.auditAuditEventQuery.suggestAuditEvents(outbound1)
        }
        let reply1 = try await step1()
        var outbound2 = Acme_Telehealth_V1_RetryVideoVisitWorkflowRequest()
        outbound2.annotations = input.annotations
        outbound2.context = input.context
        outbound2.reason = input.reason
        outbound2.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
            $0.organizer = Acme_Identity_V1_UserRef.with {
                $0.userID = input.context.actor.userID
            }
            $0.participants = [
                Acme_Telehealth_V1_VideoVisitParticipant.with {
                    $0.contact = Acme_Common_V1_ContactInfo.with {
                        $0.email = input.context.actor.email
                    }
                }
            ]
        }
        let reply2 = try await self.telehealthVideoVisitWorkflow.retryVideoVisitWorkflow(outbound2)
        return Acme_Patientapp_V1_ReplayPatientHomeEventsResponse.with {
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.patientHomeID = input.patientHomeID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply2.result.referenceIds
                $0.status = Projection.firstValue(
                    [
                        reply1.result.status,
                        reply2.outcome.status,
                    ], default: .init())
            }
        }
    }
}
