import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension CareInboxIntegrationEndpoint {
    /// Acknowledges a care inbox.
    func acknowledgeCareInboxEvent(
        request: ServerRequest<Acme_Patientapp_V1_AcknowledgeCareInboxEventRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_AcknowledgeCareInboxEventResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processAcknowledgeCareInboxEvent(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Connects a care inbox.
    func connectCareInboxSource(
        request: ServerRequest<Acme_Patientapp_V1_ConnectCareInboxSourceRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_ConnectCareInboxSourceResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processConnectCareInboxSource(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Disconnects a care inbox.
    func disconnectCareInboxSource(
        request: ServerRequest<Acme_Patientapp_V1_DisconnectCareInboxSourceRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_DisconnectCareInboxSourceResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processDisconnectCareInboxSource(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Takes a stream of care inboxes and answers once at the end.
    func ingestCareInboxEvents(
        request: StreamingServerRequest<Acme_Patientapp_V1_IngestCareInboxEventsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_IngestCareInboxEventsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            var response = Acme_Patientapp_V1_IngestCareInboxEventsResponse()
            var accepted: Int64 = 0
            for try await message in request.messages {
                response = try await processIngestCareInboxEvents(message)
                accepted += 1
            }
            response.accepted = accepted
            return ServerResponse(message: response)
        }
    }

    /// Lists care inboxes a page at a time.
    func listCareInboxSources(
        request: ServerRequest<Acme_Patientapp_V1_ListCareInboxSourcesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_ListCareInboxSourcesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListCareInboxSources(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Exchanges changes of care inboxes with a peer.
    func relayCareInboxMessages(
        request: StreamingServerRequest<Acme_Patientapp_V1_RelayCareInboxMessagesRequest>,
        context: ServerContext
    ) async throws -> StreamingServerResponse<Acme_Patientapp_V1_RelayCareInboxMessagesResponse> {
        return StreamingServerResponse { writer in
            try await CallerScope.$metadata.withValue(request.metadata) {
                for try await message in request.messages {
                    let response = try await self.processRelayCareInboxMessages(message)
                    try await writer.write(response)
                }
                return [:]
            }
        }
    }

    /// Replays a care inbox.
    func replayCareInboxEvents(
        request: ServerRequest<Acme_Patientapp_V1_ReplayCareInboxEventsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_ReplayCareInboxEventsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processReplayCareInboxEvents(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Tests a care inbox.
    func testCareInboxConnection(
        request: ServerRequest<Acme_Patientapp_V1_TestCareInboxConnectionRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_TestCareInboxConnectionResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processTestCareInboxConnection(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processAcknowledgeCareInboxEvent(_ input: Acme_Patientapp_V1_AcknowledgeCareInboxEventRequest) async throws
        -> Acme_Patientapp_V1_AcknowledgeCareInboxEventResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.endpoint)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "audit", detail: input.details.endpoint
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "AcknowledgeCareInboxEvent",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "AcknowledgeCareInboxEvent", detail: input.context.traceID
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
        _ = try await self.patientsMedicalRecordSync.reconcileMedicalRecords(
            Acme_Patients_V1_ReconcileMedicalRecordsRequest.with {
                $0.context = restoredContext
                $0.details = Acme_Patients_V1_ReconcileMedicalRecordsRequest.Details.with {
                    $0.payload = archive
                }
            })
        let outbound0 = Acme_Search_V1_CreateSearchIndexRequest.with {
            $0.context = input.context
            $0.searchIndex = Acme_Search_V1_SearchIndex.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = input.details.receivedAt
                }
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.email = input.context.actor.email
                    $0.userID = input.context.actor.userID
                }
            }
        }
        let reply0 = try await self.acknowledgeCareInboxEventStep0(outbound0)
        let outbound1 = Acme_Patientapp_V1_StartPatientHomeWorkflowRequest.with {
            $0.context = input.context
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply0.searchIndex.audit.etag
                }
                $0.customer = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = reply0.searchIndex.owner.displayName
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply0.searchIndex.owner.email
                }
            }
        }
        guard
            let execute1 = self.acknowledgeCareInboxEventStep1[settings.region]
                ?? self.acknowledgeCareInboxEventStep1["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply1 = try await execute1(outbound1)
        let selection2_1: String
        switch reply0.searchIndex.locator {
        case .address(let address):
            selection2_1 = address.region
        default: selection2_1 = .init()
        }
        let outbound2 = Acme_Patients_V1_ListPendingPatientsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Patients_V1_ListPendingPatientsRequest.Filter.with {
                $0.createdAfter = reply1.patientHome.audit.updatedAt
                $0.labels = reply1.result.details
                $0.ownerID = reply0.searchIndex.owner.userID
                $0.region = selection2_1
            }
        }
        let reply2 = try await self.patientsPatientApproval.listPendingPatients(outbound2)
        let selection3_2: String
        switch reply1.patientHome.origin {
        case .customer(let customer):
            selection3_2 = customer.email
        default: selection3_2 = .init()
        }
        let outbound3 = Acme_Patientapp_V1_SignalPatientHomeWorkflowRequest.with {
            $0.context = input.context
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.email = selection3_2
                    $0.userID = reply1.patientHome.assignee.userID
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply0.searchIndex.owner.email
                    $0.name = reply1.patientHome.requester.name
                }
            }
        }
        let reply3 = try await self.patientappPatientHomeWorkflow.signalPatientHomeWorkflow(outbound3)
        return Acme_Patientapp_V1_AcknowledgeCareInboxEventResponse.with {
            $0.careInbox = Acme_Patientapp_V1_CareInbox.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply3.patientHome.audit.createdBy
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.recipient = reply0.searchIndex.address.recipient
                }
                $0.careInboxID = input.careInboxID
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.patientID = reply3.patientHome.customer.patientID
                }
                $0.lines = [
                    Acme_Patientapp_V1_CareInboxLine.with {
                        $0.description_p = reply0.searchIndex.components["primary", default: .init()].description_p
                    }
                ]
            }
            $0.outcome = Acme_Patientapp_V1_AcknowledgeCareInboxEventResponse.Outcome.with {
                $0.referenceID = reply1.outcome.referenceID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply2.result.status
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processConnectCareInboxSource(_ input: Acme_Patientapp_V1_ConnectCareInboxSourceRequest) async throws
        -> Acme_Patientapp_V1_ConnectCareInboxSourceResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.endpoint)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "audit", detail: input.details.endpoint
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ConnectCareInboxSource",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "ConnectCareInboxSource", detail: input.context.traceID
        )
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        let outbound0 = Acme_Patientapp_V1_ReplayPatientHomeEventsRequest.with {
            $0.annotations = input.annotations
            $0.context = input.context
            $0.details = Acme_Patientapp_V1_ReplayPatientHomeEventsRequest.Details.with {
                $0.receivedAt = input.details.receivedAt
            }
        }
        let reply0 = try await self.patientappPatientHomeIntegration.replayPatientHomeEvents(outbound0)
        let outbound1 = Acme_Patientapp_V1_ConnectPatientHomeSourceRequest.with {
            $0.context = input.context
            $0.details = Acme_Patientapp_V1_ConnectPatientHomeSourceRequest.Details.with {
                $0.receivedAt = input.details.receivedAt
                $0.sourceSystem = input.details.sourceSystem
            }
        }
        let envelope1 = try Google_Protobuf_Any(message: outbound1)
        let unpacked1 = try Acme_Patientapp_V1_ConnectPatientHomeSourceRequest(unpackingAny: envelope1)
        let reply1 = try await self.patientappPatientHomeIntegration.connectPatientHomeSource(unpacked1)
        return Acme_Patientapp_V1_ConnectCareInboxSourceResponse.with {
            $0.careInbox = Acme_Patientapp_V1_CareInbox.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply0.patientHome.audit.createdBy
                }
                $0.careInboxID = input.careInboxID
            }
            $0.outcome = Acme_Patientapp_V1_ConnectCareInboxSourceResponse.Outcome.with {
                $0.status = Projection.firstValue(
                    [
                        reply0.result.status,
                        reply1.result.status,
                    ], default: .init())
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply1.result.details
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processDisconnectCareInboxSource(_ input: Acme_Patientapp_V1_DisconnectCareInboxSourceRequest) async throws
        -> Acme_Patientapp_V1_DisconnectCareInboxSourceResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.endpoint)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "audit", detail: input.details.endpoint
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "DisconnectCareInboxSource",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "DisconnectCareInboxSource", detail: input.context.traceID
        )
        let outbound0 = Acme_Patients_V1_EstimateAllergyRequest.with {
            $0.annotations = input.annotations
            $0.context = input.context
        }
        let json0 = try outbound0.jsonString()
        let decoded0 = try Acme_Patients_V1_EstimateAllergyRequest(jsonString: json0)
        let reply0 = try await self.patientsAllergyCalculation.estimateAllergy(decoded0)
        let outbound1 = Acme_Venues_V1_PreviewVenueRequest.forCareInboxIntegrationEndpointDisconnectCareInboxSource1(
            input,
            reply0: reply0
        )
        let reply1 = try await self.venuesVenueValidation.previewVenue(outbound1)
        let outbound2 = Acme_Telehealth_V1_ScheduleTriageExpiryRequest.with {
            $0.context = input.context
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply1.venue.owner.displayName
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply1.venue.audit.createdAt
                }
            }
        }
        let reply2 = try await self.telehealthTriageLifecycle.scheduleTriageExpiry(
            outbound2, metadata: ["x-acme-region": .string(settings.region)]
        )
        return Acme_Patientapp_V1_DisconnectCareInboxSourceResponse.with {
            $0.careInbox = Acme_Patientapp_V1_CareInbox.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply1.venue.audit.updatedBy
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.locality = reply1.venue.address.locality
                }
                $0.careInboxID = input.careInboxID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.status = reply2.result.status
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processIngestCareInboxEvents(_ input: Acme_Patientapp_V1_IngestCareInboxEventsRequest) async throws
        -> Acme_Patientapp_V1_IngestCareInboxEventsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.header.format)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "audit", detail: input.header.format
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "IngestCareInboxEvents",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "IngestCareInboxEvents", detail: input.context.traceID
        )
        let selection0_1: String
        switch input.chunk {
        case .header(let header):
            selection0_1 = header.submittedBy.email
        default: selection0_1 = .init()
        }
        let selection0_2: String
        switch input.chunk {
        case .record(let record):
            selection0_2 = record.counterparty.email
        default: selection0_2 = .init()
        }
        let selection0_3: String
        switch input.chunk {
        case .record(let record):
            selection0_3 = record.counterparty.patientID
        default: selection0_3 = .init()
        }
        let outbound0 = Acme_Patients_V1_CommentAllergyApprovalRequest.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.email = selection0_2
                    $0.patientID = selection0_3
                }
            }
            $0.context = input.context
            $0.details = Acme_Patients_V1_CommentAllergyApprovalRequest.Details.with {
                $0.approver = Acme_Identity_V1_UserRef.with {
                    $0.email = selection0_1
                }
            }
        }
        let reply0 = try await self.patientsAllergyApproval.commentAllergyApproval(outbound0)
        let selection1_2: Google_Protobuf_Timestamp
        switch input.chunk {
        case .record(let record):
            selection1_2 = record.audit.createdAt
        default: selection1_2 = .init()
        }
        let selection1_3: [String: String]
        switch input.chunk {
        case .record(let record):
            selection1_3 = record.metadata
        default: selection1_3 = .init()
        }
        let outbound1 = Acme_Patientapp_V1_AcknowledgePatientHomeEventRequest.with {
            $0.annotations = selection1_3
            $0.context = input.context
            $0.details = Acme_Patientapp_V1_AcknowledgePatientHomeEventRequest.Details.with {
                $0.messageID = reply0.result.message
                $0.receivedAt = selection1_2
            }
        }
        let reply1 = try await self.patientappPatientHomeIntegration.acknowledgePatientHomeEvent(outbound1)
        let selection2_2: String
        switch input.chunk {
        case .record(let record):
            selection2_2 = record.card.token
        default: selection2_2 = .init()
        }
        let selection2_3: String
        switch input.chunk {
        case .record(let record):
            selection2_3 = record.card.holderName
        default: selection2_3 = .init()
        }
        let selection2_4: [String]
        switch input.chunk {
        case .record(let record):
            selection2_4 = record.billingAddress.lines
        default: selection2_4 = .init()
        }
        let outbound2 = Acme_Patientapp_V1_AdvanceCareInboxWorkflowRequest.with {
            $0.careInbox = Acme_Patientapp_V1_CareInbox.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.lines = selection2_4
                }
                $0.card = Acme_Patientapp_V1_CareInboxCardSettlement.with {
                    $0.holderName = selection2_3
                    $0.token = selection2_2
                }
            }
            $0.context = input.context
            $0.details = Acme_Patientapp_V1_AdvanceCareInboxWorkflowRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.name = reply1.patientHome.requester.name
                }
            }
        }
        let reply2 = try await self.patientappCareInboxWorkflow.advanceCareInboxWorkflow(outbound2)
        return Acme_Patientapp_V1_IngestCareInboxEventsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.referenceIds = reply1.result.referenceIds
                $0.status = reply2.result.status
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processListCareInboxSources(_ input: Acme_Patientapp_V1_ListCareInboxSourcesRequest) async throws
        -> Acme_Patientapp_V1_ListCareInboxSourcesResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ListCareInboxSources",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "ListCareInboxSources", detail: input.context.traceID
        )
        return Acme_Patientapp_V1_ListCareInboxSourcesResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processRelayCareInboxMessages(_ input: Acme_Patientapp_V1_RelayCareInboxMessagesRequest) async throws
        -> Acme_Patientapp_V1_RelayCareInboxMessagesResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.ack.status)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "audit", detail: input.ack.status
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "RelayCareInboxMessages",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "RelayCareInboxMessages", detail: input.context.traceID
        )
        let selection0_1: String
        switch input.frame {
        case .change(let change):
            selection0_1 = change.billingAddress.region
        default: selection0_1 = .init()
        }
        let outbound0 = Acme_Patientapp_V1_ListPatientHomeSourcesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Patientapp_V1_ListPatientHomeSourcesRequest.Filter.with {
                $0.region = selection0_1
            }
        }
        let reply0 = try await self.patientappPatientHomeIntegration.listPatientHomeSources(outbound0)
        let selection1_1: Google_Protobuf_Timestamp
        switch input.frame {
        case .change(let change):
            selection1_1 = change.audit.createdAt
        default: selection1_1 = .init()
        }
        let selection1_3: [String: String]
        switch input.frame {
        case .change(let change):
            selection1_3 = change.metadata
        default: selection1_3 = .init()
        }
        let outbound1 = Acme_Patientapp_V1_ReplayPatientHomeEventsRequest.with {
            $0.annotations = selection1_3
            $0.context = input.context
            $0.details = Acme_Patientapp_V1_ReplayPatientHomeEventsRequest.Details.with {
                $0.messageID = reply0.result.message
                $0.receivedAt = selection1_1
            }
        }
        let reply1 = try await self.patientappPatientHomeIntegration.replayPatientHomeEvents(outbound1)
        let selection2_1: String
        switch input.frame {
        case .change(let change):
            selection2_1 = change.billingAddress.region
        default: selection2_1 = .init()
        }
        let outbound2 = Acme_Fanportal_V1_FindFanSessionsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Fanportal_V1_FindFanSessionsRequest.Filter.with {
                $0.region = selection2_1
            }
        }
        let reply2 = try await self.fanportalFanSessionQuery.findFanSessions(outbound2)
        let requests3 = input.change.lines.map { element in
            Acme_Patients_V1_ApproveMedicalRecordRequest.with {
                $0.context = input.context
                $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                    $0.lines = [
                        Acme_Patients_V1_MedicalRecordLine.with {
                            $0.tax = Acme_Patients_V1_MedicalRecordLineTax.with {
                                $0.exemptions = element.tax.exemptions
                            }
                        }
                    ]
                }
            }
        }
        let replies3 = try await FanOut.map(requests3) { candidate in
            try await self.patientsMedicalRecordApproval.approveMedicalRecord(candidate)
        }
        let reply3 = replies3.first ?? Acme_Patients_V1_ApproveMedicalRecordResponse()
        _ = reply3
        return Acme_Patientapp_V1_RelayCareInboxMessagesResponse.with {
            $0.careInbox = Acme_Patientapp_V1_CareInbox.with {
                $0.careInboxID = input.change.careInboxID
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = reply1.patientHome.customer.displayName
                    $0.patientID = reply1.patientHome.customer.patientID
                }
                $0.dueAt = input.change.dueAt
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.referenceIds = reply0.result.referenceIds
                $0.status = reply2.result.status
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processReplayCareInboxEvents(_ input: Acme_Patientapp_V1_ReplayCareInboxEventsRequest) async throws
        -> Acme_Patientapp_V1_ReplayCareInboxEventsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.messageID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "audit", detail: input.details.messageID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ReplayCareInboxEvents",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "ReplayCareInboxEvents", detail: input.context.traceID
        )
        let outbound0 = Acme_Patientapp_V1_ResumePatientHomeWorkflowRequest.with {
            $0.annotations = input.annotations
            $0.context = input.context
        }
        let reply0 = try await RPCOperations.call(outbound0) { request in
            try await self.patientappPatientHomeWorkflow.resumePatientHomeWorkflow(request)
        }
        let outbound1 = Acme_Telehealth_V1_ApproveTriageRequest.with {
            $0.context = Projection.read(input, at: \Acme_Patientapp_V1_ReplayCareInboxEventsRequest.context)
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.customer = Acme_Telehealth_V1_VideoVisitRef.with {
                    $0.displayName = Projection.read(
                        reply0,
                        at: \Acme_Patientapp_V1_ResumePatientHomeWorkflowResponse.patientHome.assignee.displayName)
                }
                $0.sla = Acme_Telehealth_V1_TriageSla.with {
                    $0.breached = Projection.read(
                        reply0, at: \Acme_Patientapp_V1_ResumePatientHomeWorkflowResponse.patientHome.sla.breached)
                }
            }
        }
        let reply1 = try await self.telehealthTriageApproval.approveTriage(outbound1)
        let outbound2 = Acme_Patientapp_V1_ConnectPatientHomeSourceRequest.with {
            $0.context = input.context
            $0.details = Acme_Patientapp_V1_ConnectPatientHomeSourceRequest.Details.with {
                $0.endpoint = input.details.endpoint
                $0.receivedAt = input.details.receivedAt
                $0.sourceSystem = input.details.sourceSystem
            }
            $0.patientHomeID = reply0.patientHome.patientHomeID
        }
        let step2: @Sendable () async throws -> Acme_Patientapp_V1_ConnectPatientHomeSourceResponse = {
            try await self.patientappPatientHomeIntegration.connectPatientHomeSource(outbound2)
        }
        let reply2 = try await step2()
        return Acme_Patientapp_V1_ReplayCareInboxEventsResponse.with {
            $0.careInbox = Acme_Patientapp_V1_CareInbox.with {
                $0.careInboxID = input.careInboxID
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = reply2.patientHome.assignee.displayName
                    $0.patientID = reply0.patientHome.customer.patientID
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = Projection.firstValue(
                    [
                        reply0.result.correlationID,
                        reply1.result.correlationID,
                    ], default: .init())
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processTestCareInboxConnection(_ input: Acme_Patientapp_V1_TestCareInboxConnectionRequest) async throws
        -> Acme_Patientapp_V1_TestCareInboxConnectionResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.endpoint)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "audit", detail: input.details.endpoint
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "TestCareInboxConnection",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "TestCareInboxConnection", detail: input.context.traceID
        )
        var outbound0 = Acme_Patientapp_V1_DisconnectPatientHomeSourceRequest()
        outbound0.annotations = input.annotations
        outbound0.context = input.context
        outbound0.details = Acme_Patientapp_V1_DisconnectPatientHomeSourceRequest.Details.with {
            $0.messageID = input.details.messageID
            $0.receivedAt = input.details.receivedAt
        }
        let reply0 = try await self.patientappPatientHomeIntegration.disconnectPatientHomeSource(outbound0)
        let outbound1 = Acme_Identity_V1_GetUserRulesRequest.with {
            $0.context = input.context
            $0.userID = input.context.actor.userID
        }
        let reply1 = try await RPCOperations.read {
            try await self.identityUserValidation.getUserRules(outbound1)
        }
        let outbound2 = Acme_Prescriptions_V1_ListRefillReportsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Prescriptions_V1_ListRefillReportsRequest.Filter.with {
                $0.createdAfter = reply0.patientHome.audit.createdAt
                $0.region = reply1.user.primaryAddress.region
            }
        }
        let reply2 = try await self.prescriptionsRefillReporting.listRefillReports(outbound2)
        return Acme_Patientapp_V1_TestCareInboxConnectionResponse.with {
            $0.careInbox = Acme_Patientapp_V1_CareInbox.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = reply1.user.primaryAddress.countryCode
                    $0.recipient = reply1.user.primaryAddress.recipient
                }
                $0.careInboxID = input.careInboxID
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.email = reply0.patientHome.assignee.email
                }
            }
            $0.outcome = Acme_Patientapp_V1_TestCareInboxConnectionResponse.Outcome.with {
                $0.status = reply2.result.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply2.result.message
                $0.status = "ok"
            }
        }
    }
}
