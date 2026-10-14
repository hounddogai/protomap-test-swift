import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension VisitNoteQueryEndpoint {
    /// Lists visit notes a page at a time.
    func browseVisitNotes(
        request: ServerRequest<Acme_Telehealth_V1_BrowseVisitNotesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_BrowseVisitNotesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processBrowseVisitNotes(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Counts visit notes by status.
    func countVisitNotes(
        request: ServerRequest<Acme_Telehealth_V1_CountVisitNotesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_CountVisitNotesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCountVisitNotes(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Streams every matching visit note.
    func exportVisitNotes(
        request: ServerRequest<Acme_Telehealth_V1_ExportVisitNotesRequest>,
        context: ServerContext
    ) async throws -> StreamingServerResponse<Acme_Telehealth_V1_ExportVisitNotesResponse> {
        return StreamingServerResponse { writer in
            try await CallerScope.$metadata.withValue(request.metadata) {
                let response = try await self.processExportVisitNotes(request.message)
                try await writer.write(response)
                return [:]
            }
        }
    }

    /// Returns a visit note.
    func lookupVisitNote(
        request: ServerRequest<Acme_Telehealth_V1_LookupVisitNoteRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_LookupVisitNoteResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processLookupVisitNote(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a visit note.
    func peekVisitNote(
        request: ServerRequest<Acme_Telehealth_V1_PeekVisitNoteRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_PeekVisitNoteResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processPeekVisitNote(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns several visit notes at once.
    func resolveVisitNotes(
        request: ServerRequest<Acme_Telehealth_V1_ResolveVisitNotesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_ResolveVisitNotesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processResolveVisitNotes(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists visit notes a page at a time.
    func suggestVisitNotes(
        request: ServerRequest<Acme_Telehealth_V1_SuggestVisitNotesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_SuggestVisitNotesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSuggestVisitNotes(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Summarizes a visit note.
    func summarizeVisitNotes(
        request: ServerRequest<Acme_Telehealth_V1_SummarizeVisitNotesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_SummarizeVisitNotesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSummarizeVisitNotes(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processBrowseVisitNotes(_ input: Acme_Telehealth_V1_BrowseVisitNotesRequest) async throws
        -> Acme_Telehealth_V1_BrowseVisitNotesResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "BrowseVisitNotes",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "BrowseVisitNotes", detail: input.context.traceID
        )
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        let importFrame = Acme_Careplans_V1_BatchCreateCarePlansRequest.with {
            $0.context = input.context
        }
        _ = try await self.careplansCarePlan.batchCreateCarePlans { writer in
            try await writer.write(importFrame)
        }
        return Acme_Telehealth_V1_BrowseVisitNotesResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processCountVisitNotes(_ input: Acme_Telehealth_V1_CountVisitNotesRequest) async throws
        -> Acme_Telehealth_V1_CountVisitNotesResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "CountVisitNotes",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "CountVisitNotes", detail: input.context.traceID
        )
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        let outbound0 = Acme_Telehealth_V1_EstimateTriageRequest.with {
            $0.context = Projection.read(input, at: \Acme_Telehealth_V1_CountVisitNotesRequest.context)
            $0.details = Acme_Telehealth_V1_EstimateTriageRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.region = Projection.read(input, at: \Acme_Telehealth_V1_CountVisitNotesRequest.filter.region)
                }
            }
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.email = Projection.read(
                        input, at: \Acme_Telehealth_V1_CountVisitNotesRequest.context.actor.email)
                    $0.userID = Projection.read(
                        input, at: \Acme_Telehealth_V1_CountVisitNotesRequest.context.actor.userID)
                }
                $0.sla = Acme_Telehealth_V1_TriageSla.with {
                    $0.dueAt = Projection.read(
                        input, at: \Acme_Telehealth_V1_CountVisitNotesRequest.filter.createdAfter)
                }
            }
        }
        let reply0 = try await self.telehealthTriageCalculation.estimateTriage(outbound0)
        return Acme_Telehealth_V1_CountVisitNotesResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.status = "ok"
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processExportVisitNotes(_ input: Acme_Telehealth_V1_ExportVisitNotesRequest) async throws
        -> Acme_Telehealth_V1_ExportVisitNotesResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.destinationUri)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "audit", detail: input.destinationUri
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ExportVisitNotes",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "ExportVisitNotes", detail: input.context.traceID
        )
        let outbound0 = Acme_Telehealth_V1_RecalculateTriagesRequest.with {
            $0.context = input.context
            $0.details = Acme_Telehealth_V1_RecalculateTriagesRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
            }
        }
        let step0: @Sendable () async throws -> Acme_Telehealth_V1_RecalculateTriagesResponse = {
            try await self.telehealthTriageCalculation.recalculateTriages(outbound0)
        }
        let reply0 = try await step0()
        var outbound1 = Acme_Telehealth_V1_SuggestVideoVisitsRequest()
        outbound1.context = input.context
        outbound1.filter = Acme_Telehealth_V1_SuggestVideoVisitsRequest.Filter.with {
            $0.createdAfter = input.filter.createdAfter
            $0.query = input.filter.query
            $0.region = input.filter.region
        }
        let reply1 = try await self.telehealthVideoVisitQuery.suggestVideoVisits(outbound1)
        return Acme_Telehealth_V1_ExportVisitNotesResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.status = "ok"
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply0.triage.audit.updatedAt
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processLookupVisitNote(_ input: Acme_Telehealth_V1_LookupVisitNoteRequest) async throws
        -> Acme_Telehealth_V1_LookupVisitNoteResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "LookupVisitNote",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "LookupVisitNote", detail: input.context.traceID
        )
        let outbound0 = Acme_Telehealth_V1_RecalculateVideoVisitsRequest.with {
            $0.context = input.context
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
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
        }
        let step0: @Sendable () async throws -> Acme_Telehealth_V1_RecalculateVideoVisitsResponse = {
            try await self.telehealthVideoVisitCalculation.recalculateVideoVisits(outbound0)
        }
        let reply0 = try await step0()
        let outbound1 = Acme_Telehealth_V1_ValidateTriageRequest.with {
            $0.context = input.context
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply0.videoVisit.organizer.displayName
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply0.videoVisit.audit.createdAt
                    $0.etag = reply0.videoVisit.audit.etag
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply0.videoVisit.organizer.email
                }
            }
        }
        let reply1 = try await self.telehealthTriageValidation.validateTriage(outbound1)
        return Acme_Telehealth_V1_LookupVisitNoteResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.message = reply1.outcome.message
                $0.referenceIds = reply1.result.referenceIds
                $0.status = "ok"
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.lines = reply0.videoVisit.location.lines
                }
                $0.visitNoteID = input.visitNoteID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processPeekVisitNote(_ input: Acme_Telehealth_V1_PeekVisitNoteRequest) async throws
        -> Acme_Telehealth_V1_PeekVisitNoteResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "PeekVisitNote",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "PeekVisitNote", detail: input.context.traceID
        )
        return Acme_Telehealth_V1_PeekVisitNoteResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.visitNoteID = input.visitNoteID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processResolveVisitNotes(_ input: Acme_Telehealth_V1_ResolveVisitNotesRequest) async throws
        -> Acme_Telehealth_V1_ResolveVisitNotesResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ResolveVisitNotes",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "ResolveVisitNotes", detail: input.context.traceID
        )
        let outbound0 = Acme_Careplans_V1_CalculateVitalRequest.with {
            $0.context = input.context
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.subject = Acme_Appointments_V1_AppointmentRef.with {
                    $0.startsAt = input.context.deadline
                }
            }
        }
        async let remote0 = self.careplansVitalCalculation.calculateVital(outbound0)
        async let persisted0 = store.count(tenant: input.context.tenantID)
        let (reply0, count0) = try await (remote0, persisted0)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count0)])
        return Acme_Telehealth_V1_ResolveVisitNotesResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processSuggestVisitNotes(_ input: Acme_Telehealth_V1_SuggestVisitNotesRequest) async throws
        -> Acme_Telehealth_V1_SuggestVisitNotesResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SuggestVisitNotes",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "SuggestVisitNotes", detail: input.context.traceID
        )
        let outbound0 = Acme_Audit_V1_BatchGetAuditEventsRequest.with {
            $0.context = input.context
        }
        let reply0 = try await self.suggestVisitNotesStep0.execute(outbound0)
        return Acme_Telehealth_V1_SuggestVisitNotesResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processSummarizeVisitNotes(_ input: Acme_Telehealth_V1_SummarizeVisitNotesRequest) async throws
        -> Acme_Telehealth_V1_SummarizeVisitNotesResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.cron)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "audit", detail: input.details.cron
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SummarizeVisitNotes",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "SummarizeVisitNotes", detail: input.context.traceID
        )
        let outbound0 = Acme_Telehealth_V1_RecalculateTriagesRequest.with {
            $0.context = input.context
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.email = input.context.actor.email
                }
            }
        }
        let port0 = RPCOperations.port { (request: Acme_Telehealth_V1_RecalculateTriagesRequest) in
            try await self.telehealthTriageCalculation.recalculateTriages(request)
        }
        let reply0 = try await port0.execute(outbound0)
        let outbound1 = Acme_Telehealth_V1_NormalizeVisitNoteRequest.with {
            $0.context = input.context
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.email = reply0.triage.assignee.email
                }
            }
        }
        let reply1 = try await self.summarizeVisitNotesStep1(outbound1)
        let outbound2 = Acme_Telehealth_V1_CalculateVideoVisitRequest.with {
            $0.context = input.context
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = reply1.visitNote.billingAddress.countryCode
                }
                $0.participants = [
                    Acme_Telehealth_V1_VideoVisitParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.name = reply0.triage.requester.name
                            $0.preferredChannel = reply0.triage.requester.preferredChannel
                        }
                    }
                ]
            }
        }
        guard let execute2 = self.summarizeVisitNotesStep2[settings.region] ?? self.summarizeVisitNotesStep2["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply2 = try await execute2(outbound2)
        let outbound3 = Acme_Featureflags_V1_PreviewFeatureFlagRequest.with {
            $0.context = input.context
            $0.featureFlag = Acme_Featureflags_V1_FeatureFlag.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply2.videoVisit.audit.createdAt
                    $0.etag = reply0.triage.audit.etag
                }
            }
        }
        let reply3 = try await self.featureflagsFeatureFlagValidation.previewFeatureFlag(outbound3)
        return Acme_Telehealth_V1_SummarizeVisitNotesResponse.with {
            $0.period = input.details.period
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = Projection.firstValue(
                    [
                        reply0.result.correlationID,
                        reply3.result.correlationID,
                    ], default: .init())
                $0.details = Projection.firstValue(
                    [
                        reply0.result.details,
                        reply2.result.details,
                    ], default: .init())
                $0.referenceIds = reply3.result.referenceIds
                $0.status = reply1.outcome.status
            }
        }
    }
}
