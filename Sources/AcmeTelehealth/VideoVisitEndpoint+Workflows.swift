import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension VideoVisitEndpoint {
    /// Takes a stream of video visits and answers once at the end.
    func batchCreateVideoVisits(
        request: StreamingServerRequest<Acme_Telehealth_V1_BatchCreateVideoVisitsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_BatchCreateVideoVisitsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            var response = Acme_Telehealth_V1_BatchCreateVideoVisitsResponse()
            var accepted: Int64 = 0
            for try await message in request.messages {
                response = try await processBatchCreateVideoVisits(message)
                accepted += 1
            }
            response.accepted = accepted
            return ServerResponse(message: response)
        }
    }

    /// Returns several video visits at once.
    func batchGetVideoVisits(
        request: ServerRequest<Acme_Telehealth_V1_BatchGetVideoVisitsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_BatchGetVideoVisitsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processBatchGetVideoVisits(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Creates a video visit.
    func cloneVideoVisit(
        request: ServerRequest<Acme_Telehealth_V1_CloneVideoVisitRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_CloneVideoVisitResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCloneVideoVisit(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Creates a video visit.
    func createVideoVisit(
        request: ServerRequest<Acme_Telehealth_V1_CreateVideoVisitRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_CreateVideoVisitResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCreateVideoVisit(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Deletes a video visit.
    func deleteVideoVisit(
        request: ServerRequest<Acme_Telehealth_V1_DeleteVideoVisitRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_DeleteVideoVisitResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processDeleteVideoVisit(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a video visit.
    func getVideoVisit(
        request: ServerRequest<Acme_Telehealth_V1_GetVideoVisitRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_GetVideoVisitResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetVideoVisit(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists video visits a page at a time.
    func searchVideoVisits(
        request: ServerRequest<Acme_Telehealth_V1_SearchVideoVisitsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_SearchVideoVisitsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSearchVideoVisits(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Changes a video visit.
    func updateVideoVisit(
        request: ServerRequest<Acme_Telehealth_V1_UpdateVideoVisitRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_UpdateVideoVisitResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processUpdateVideoVisit(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Streams the changes of video visits as they happen.
    func watchVideoVisits(
        request: ServerRequest<Acme_Telehealth_V1_WatchVideoVisitsRequest>,
        context: ServerContext
    ) async throws -> StreamingServerResponse<Acme_Telehealth_V1_WatchVideoVisitsResponse> {
        return StreamingServerResponse { writer in
            try await CallerScope.$metadata.withValue(request.metadata) {
                let response = try await self.processWatchVideoVisits(request.message)
                try await writer.write(response)
                return [:]
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processBatchCreateVideoVisits(_ input: Acme_Telehealth_V1_BatchCreateVideoVisitsRequest) async throws
        -> Acme_Telehealth_V1_BatchCreateVideoVisitsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.header.format)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "audit", detail: input.header.format
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "BatchCreateVideoVisits",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "BatchCreateVideoVisits", detail: input.context.traceID
        )
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        let importFrame = Acme_Careplans_V1_BatchCreateCarePlansRequest.with {
            $0.context = input.context
        }
        _ = try await self.careplansCarePlan.batchCreateCarePlans { writer in
            try await writer.write(importFrame)
        }
        let selection0_1: String
        switch input.chunk {
        case .header(let header):
            selection0_1 = header.submittedBy.phone
        default: selection0_1 = .init()
        }
        let selection0_2: String
        switch input.chunk {
        case .header(let header):
            selection0_2 = header.submittedBy.email
        default: selection0_2 = .init()
        }
        let outbound0 = Acme_Careplans_V1_LintCarePlansRequest.with {
            $0.context = input.context
            $0.details = Acme_Careplans_V1_LintCarePlansRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = selection0_2
                    $0.phone = selection0_1
                }
            }
        }
        let reply0 = try await self.careplansCarePlanValidation.lintCarePlans(outbound0)
        let selection1_1: String
        switch reply0.carePlan.settlement {
        case .card(let card):
            selection1_1 = card.token
        default: selection1_1 = .init()
        }
        let selection1_2: String
        switch input.chunk {
        case .record(let record):
            selection1_2 = record.location.locality
        default: selection1_2 = .init()
        }
        let outbound1 = Acme_Telehealth_V1_RecalculateVisitNotesRequest.with {
            $0.context = input.context
            $0.details = Acme_Telehealth_V1_RecalculateVisitNotesRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.locality = selection1_2
                }
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.card = Acme_Telehealth_V1_VisitNoteCardSettlement.with {
                    $0.token = selection1_1
                }
            }
        }
        let reply1 = try await self.telehealthVisitNoteCalculation.recalculateVisitNotes(outbound1)
        let outbound2 = Acme_Ledger_V1_WatchLedgerAccountsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Ledger_V1_WatchLedgerAccountsRequest.Filter.with {
                $0.region = reply0.carePlan.billingAddress.region
            }
            $0.subscriber = Acme_Common_V1_ContactInfo.with {
                $0.email = input.header.submittedBy.email
            }
        }
        let reply2 = try await self.ledgerLedgerAccount.watchLedgerAccounts(outbound2) { response in
            var latest = Acme_Ledger_V1_WatchLedgerAccountsResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        _ = reply2
        return Acme_Telehealth_V1_BatchCreateVideoVisitsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = Projection.firstValue(
                    [
                        reply0.result.correlationID,
                        reply1.result.correlationID,
                    ], default: .init())
                $0.message = reply0.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processBatchGetVideoVisits(_ input: Acme_Telehealth_V1_BatchGetVideoVisitsRequest) async throws
        -> Acme_Telehealth_V1_BatchGetVideoVisitsResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "BatchGetVideoVisits",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "BatchGetVideoVisits", detail: input.context.traceID
        )
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        let outbound0 = Acme_Venues_V1_NormalizeVenueRequest.with {
            $0.context = input.context
            $0.details = Acme_Venues_V1_NormalizeVenueRequest.Details.with {
                $0.locale = input.context.locale
            }
            $0.venue = Acme_Venues_V1_Venue.with {
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.email = input.context.actor.email
                    $0.userID = input.context.actor.userID
                }
            }
        }
        let reply0 = try await self.batchGetVideoVisitsStep0(outbound0)
        return Acme_Telehealth_V1_BatchGetVideoVisitsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.videoVisits = [
                Acme_Telehealth_V1_VideoVisit.with {
                    $0.location = Acme_Common_V1_PostalAddress.with {
                        $0.postalCode = reply0.venue.address.postalCode
                    }
                    $0.organizer = Acme_Identity_V1_UserRef.with {
                        $0.displayName = reply0.venue.owner.displayName
                    }
                }
            ]
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processCloneVideoVisit(_ input: Acme_Telehealth_V1_CloneVideoVisitRequest) async throws
        -> Acme_Telehealth_V1_CloneVideoVisitResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.requestID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "audit", detail: input.requestID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "CloneVideoVisit",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VideoVisitRecord(input.videoVisit, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Telehealth_V1_RecalculateVideoVisitsRequest.with {
            $0.context = input.context
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.participants = [
                    Acme_Telehealth_V1_VideoVisitParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = input.videoVisit.organizer.email
                        }
                    }
                ]
            }
        }
        guard let execute0 = self.cloneVideoVisitStep0[settings.region] ?? self.cloneVideoVisitStep0["primary"] else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply0 = try await execute0(outbound0)
        let outbound1 = Acme_Careplans_V1_CheckCarePlanEligibilityRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = input.videoVisit.audit.createdBy
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = reply0.videoVisit.location.countryCode
                    $0.locality = reply0.videoVisit.location.locality
                }
            }
            $0.context = input.context
        }
        let reply1 = try await self.careplansCarePlanValidation.checkCarePlanEligibility(outbound1)
        return Acme_Telehealth_V1_CloneVideoVisitResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = reply1.carePlan.billingAddress.countryCode
                    $0.postalCode = reply1.carePlan.billingAddress.postalCode
                }
                $0.title = input.videoVisit.title
                $0.videoVisitID = reply0.videoVisit.videoVisitID
                $0.window = input.videoVisit.window
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processCreateVideoVisit(_ input: Acme_Telehealth_V1_CreateVideoVisitRequest) async throws
        -> Acme_Telehealth_V1_CreateVideoVisitResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.requestID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "audit", detail: input.requestID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "CreateVideoVisit",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VideoVisitRecord(input.videoVisit, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Seating_V1_WatchSeatMapsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Seating_V1_WatchSeatMapsRequest.Filter.with {
                $0.createdAfter = input.videoVisit.audit.createdAt
                $0.region = input.videoVisit.location.region
            }
            $0.since = input.videoVisit.audit.updatedAt
            $0.subscriber = Acme_Common_V1_ContactInfo.with {
                $0.email = input.videoVisit.organizer.email
            }
        }
        let reply0 = try await self.seatingSeatMap.watchSeatMaps(outbound0) { response in
            var latest = Acme_Seating_V1_WatchSeatMapsResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        _ = reply0
        return Acme_Telehealth_V1_CreateVideoVisitResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.status = input.videoVisit.status
                $0.window = input.videoVisit.window
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processDeleteVideoVisit(_ input: Acme_Telehealth_V1_DeleteVideoVisitRequest) async throws
        -> Acme_Telehealth_V1_DeleteVideoVisitResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.reason)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "audit", detail: input.reason
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "DeleteVideoVisit",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "DeleteVideoVisit", detail: input.context.traceID
        )
        let outbound0 = Acme_Telehealth_V1_ValidateTriageRequest.with {
            $0.context = input.context
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = input.etag
                }
                $0.customer = Acme_Telehealth_V1_VideoVisitRef.with {
                    $0.videoVisitID = input.videoVisitID
                }
            }
        }
        let envelope0 = try Google_Protobuf_Any(message: outbound0)
        let unpacked0 = try Acme_Telehealth_V1_ValidateTriageRequest(unpackingAny: envelope0)
        let reply0 = try await self.telehealthTriageValidation.validateTriage(unpacked0)
        let selection1_3: String
        switch reply0.triage.origin {
        case .customer(let customer):
            selection1_3 = customer.displayName
        default: selection1_3 = .init()
        }
        let outbound1 = Acme_Careplans_V1_LintVitalsRequest.with {
            $0.context = input.context
            $0.details = Acme_Careplans_V1_LintVitalsRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply0.triage.requester.email
                    $0.name = reply0.triage.requester.name
                    $0.phone = reply0.triage.requester.phone
                }
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.subject = Acme_Appointments_V1_AppointmentRef.with {
                    $0.displayName = selection1_3
                }
            }
        }
        let reply1 = try await self.careplansVitalValidation.lintVitals(outbound1)
        let outbound2 = Acme_Telehealth_V1_RecalculateVideoVisitsRequest.with {
            $0.context = input.context
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply0.triage.audit.updatedAt
                }
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.email = reply0.triage.requester.email
                }
                $0.participants = [
                    Acme_Telehealth_V1_VideoVisitParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = reply0.triage.assignee.email
                            $0.name = reply0.triage.requester.name
                        }
                    }
                ]
            }
        }
        let json2 = try outbound2.jsonString()
        let decoded2 = try Acme_Telehealth_V1_RecalculateVideoVisitsRequest(jsonString: json2)
        let reply2 = try await self.telehealthVideoVisitCalculation.recalculateVideoVisits(decoded2)
        let outbound3 = Acme_Telehealth_V1_PreviewVideoVisitRequest.forVideoVisitEndpointDeleteVideoVisit3(
            input,
            reply0: reply0,
            reply2: reply2
        )
        let reply3 = try await self.telehealthVideoVisitValidation.previewVideoVisit(outbound3)
        return Acme_Telehealth_V1_DeleteVideoVisitResponse.with {
            $0.effectiveAt = reply0.outcome.effectiveAt
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = Projection.firstValue(
                    [
                        reply0.result.correlationID,
                        reply2.result.correlationID,
                    ], default: .init())
                $0.referenceIds = reply1.result.referenceIds
                $0.status = reply3.outcome.status
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processGetVideoVisit(_ input: Acme_Telehealth_V1_GetVideoVisitRequest) async throws
        -> Acme_Telehealth_V1_GetVideoVisitResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "GetVideoVisit",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "GetVideoVisit", detail: input.context.traceID
        )
        return Acme_Telehealth_V1_GetVideoVisitResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.videoVisitID = input.videoVisitID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processSearchVideoVisits(_ input: Acme_Telehealth_V1_SearchVideoVisitsRequest) async throws
        -> Acme_Telehealth_V1_SearchVideoVisitsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SearchVideoVisits",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "SearchVideoVisits", detail: input.context.traceID
        )
        let outbound0 = Acme_Careplans_V1_ExplainCareGoalDecisionRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.context.actor.userID
                }
            }
            $0.context = input.context
        }
        let reply0 = try await self.careplansCareGoalValidation.explainCareGoalDecision(
            outbound0, metadata: ["x-acme-region": .string(settings.region)]
        )
        let outbound1 = Acme_Careplans_V1_SuggestCareGoalsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Careplans_V1_SuggestCareGoalsRequest.Filter.with {
                $0.region = input.filter.region
            }
        }
        let reply1 = try await RPCOperations.call(outbound1) { request in
            try await self.careplansCareGoalQuery.suggestCareGoals(request)
        }
        return Acme_Telehealth_V1_SearchVideoVisitsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply1.result.message
                $0.referenceIds = reply1.result.referenceIds
                $0.status = "ok"
            }
            $0.videoVisits = [
                Acme_Telehealth_V1_VideoVisit.with {
                    $0.organizer = Acme_Identity_V1_UserRef.with {
                        $0.userID = reply0.careGoal.assignee.userID
                    }
                }
            ]
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processUpdateVideoVisit(_ input: Acme_Telehealth_V1_UpdateVideoVisitRequest) async throws
        -> Acme_Telehealth_V1_UpdateVideoVisitResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.videoVisit.audit.etag)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "audit", detail: input.videoVisit.audit.etag
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "UpdateVideoVisit",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VideoVisitRecord(input.videoVisit, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Telehealth_V1_ValidateTriageRequest.with {
            $0.context = Projection.read(input, at: \Acme_Telehealth_V1_UpdateVideoVisitRequest.context)
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = Projection.read(
                        input, at: \Acme_Telehealth_V1_UpdateVideoVisitRequest.videoVisit.audit.createdAt)
                    $0.createdBy = Projection.read(
                        input, at: \Acme_Telehealth_V1_UpdateVideoVisitRequest.videoVisit.audit.createdBy)
                    $0.updatedAt = Projection.read(
                        input, at: \Acme_Telehealth_V1_UpdateVideoVisitRequest.videoVisit.audit.updatedAt)
                }
            }
        }
        let reply0 = try await self.telehealthTriageValidation.validateTriage(outbound0)
        let outbound1 = Acme_Telehealth_V1_BrowseVisitNotesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Telehealth_V1_BrowseVisitNotesRequest.Filter.with {
                $0.region = input.videoVisit.location.region
            }
        }
        let step1: @Sendable () async throws -> Acme_Telehealth_V1_BrowseVisitNotesResponse = {
            try await self.telehealthVisitNoteQuery.browseVisitNotes(outbound1)
        }
        let reply1 = try await step1()
        var outbound2 = Acme_Telehealth_V1_PreviewTriageRequest()
        outbound2.context = input.context
        outbound2.details = Acme_Telehealth_V1_PreviewTriageRequest.Details.with {
            $0.contact = Acme_Common_V1_ContactInfo.with {
                $0.name = reply0.triage.requester.name
            }
        }
        outbound2.triage = Acme_Telehealth_V1_Triage.with {
            $0.requester = Acme_Common_V1_ContactInfo.with {
                $0.email = input.videoVisit.organizer.email
            }
        }
        let reply2 = try await self.telehealthTriageValidation.previewTriage(outbound2)
        return Acme_Telehealth_V1_UpdateVideoVisitResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply1.result.message
                $0.status = reply1.result.status
            }
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply2.triage.assignee.displayName
                    $0.email = reply0.triage.assignee.email
                }
                $0.participants = [
                    Acme_Telehealth_V1_VideoVisitParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = reply2.triage.requester.email
                            $0.phone = reply0.triage.requester.phone
                        }
                    }
                ]
                $0.status = input.videoVisit.status
                $0.title = input.videoVisit.title
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processWatchVideoVisits(_ input: Acme_Telehealth_V1_WatchVideoVisitsRequest) async throws
        -> Acme_Telehealth_V1_WatchVideoVisitsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "WatchVideoVisits",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "WatchVideoVisits", detail: input.context.traceID
        )
        let outbound0 = Acme_Careplans_V1_LintCarePlansRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
            }
            $0.context = input.context
            $0.details = Acme_Careplans_V1_LintCarePlansRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.name = input.subscriber.name
                    $0.phone = input.subscriber.phone
                }
            }
        }
        let step0: @Sendable () async throws -> Acme_Careplans_V1_LintCarePlansResponse = {
            try await self.careplansCarePlanValidation.lintCarePlans(outbound0)
        }
        let reply0 = try await step0()
        let outbound1 = Acme_Telehealth_V1_EstimateVideoVisitRequest.with {
            $0.context = input.context
            $0.details = Acme_Telehealth_V1_EstimateVideoVisitRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.region = reply0.carePlan.billingAddress.region
                }
            }
        }
        let reply1 = try await self.telehealthVideoVisitCalculation.estimateVideoVisit(outbound1)
        let outbound2 = Acme_Telehealth_V1_ValidateTriageRequest.with {
            $0.context = input.context
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply0.carePlan.audit.updatedAt
                }
            }
        }
        async let remote2 = self.telehealthTriageValidation.validateTriage(outbound2)
        async let persisted2 = store.count(tenant: input.context.tenantID)
        let (reply2, count2) = try await (remote2, persisted2)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count2)])
        return Acme_Telehealth_V1_WatchVideoVisitsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply0.carePlan.audit.updatedAt
                }
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.lines = reply0.carePlan.billingAddress.lines
                    $0.region = input.filter.region
                }
                $0.organizer = Projection.updating(reply1.videoVisit.organizer) {
                    $0.email = reply2.triage.assignee.email
                }
                $0.status = reply1.videoVisit.status
            }
        }
    }
}
