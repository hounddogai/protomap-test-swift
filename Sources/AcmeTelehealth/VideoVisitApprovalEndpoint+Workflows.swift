import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension VideoVisitApprovalEndpoint {
    /// Approves a video visit.
    func approveVideoVisit(
        request: ServerRequest<Acme_Telehealth_V1_ApproveVideoVisitRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_ApproveVideoVisitResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processApproveVideoVisit(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Comments a video visit.
    func commentVideoVisitApproval(
        request: ServerRequest<Acme_Telehealth_V1_CommentVideoVisitApprovalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_CommentVideoVisitApprovalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCommentVideoVisitApproval(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Delegates a video visit.
    func delegateVideoVisitApproval(
        request: ServerRequest<Acme_Telehealth_V1_DelegateVideoVisitApprovalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_DelegateVideoVisitApprovalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processDelegateVideoVisitApproval(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a video visit.
    func getVideoVisitApprovalStatus(
        request: ServerRequest<Acme_Telehealth_V1_GetVideoVisitApprovalStatusRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_GetVideoVisitApprovalStatusResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetVideoVisitApprovalStatus(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists video visits a page at a time.
    func listPendingVideoVisits(
        request: ServerRequest<Acme_Telehealth_V1_ListPendingVideoVisitsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_ListPendingVideoVisitsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListPendingVideoVisits(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Recalls a video visit.
    func recallVideoVisit(
        request: ServerRequest<Acme_Telehealth_V1_RecallVideoVisitRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_RecallVideoVisitResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRecallVideoVisit(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Rejects a video visit.
    func rejectVideoVisit(
        request: ServerRequest<Acme_Telehealth_V1_RejectVideoVisitRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_RejectVideoVisitResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRejectVideoVisit(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Submits a video visit.
    func submitVideoVisit(
        request: ServerRequest<Acme_Telehealth_V1_SubmitVideoVisitRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_SubmitVideoVisitResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSubmitVideoVisit(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processApproveVideoVisit(_ input: Acme_Telehealth_V1_ApproveVideoVisitRequest) async throws
        -> Acme_Telehealth_V1_ApproveVideoVisitResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "audit", detail: input.details.approver.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ApproveVideoVisit",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VideoVisitRecord(input.videoVisit, tenant: input.context.tenantID)
        try await store.save(record.stored)
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        try followUps.submit(
            Acme_Identity_V1_GetUserRequest.with {
                $0.context = input.context
                $0.userID = input.context.actor.userID
            })
        let importFrame = Acme_Prescriptions_V1_BatchCreatePrescriptionsRequest.with {
            $0.context = input.context
        }
        _ = try await self.prescriptionsPrescription.batchCreatePrescriptions { writer in
            try await writer.write(importFrame)
        }
        let outbound0 = Acme_Telehealth_V1_CheckVisitNoteEligibilityRequest.with {
            $0.context = input.context
            $0.details = Acme_Telehealth_V1_CheckVisitNoteEligibilityRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.approver.email
                }
            }
        }
        let reply0 = try await RPCOperations.call(outbound0) { request in
            try await self.telehealthVisitNoteValidation.checkVisitNoteEligibility(request)
        }
        let requests1 = input.videoVisit.participants.map { element in
            Acme_Telehealth_V1_SuggestVisitNotesRequest.with {
                $0.context = input.context
                $0.filter = Acme_Telehealth_V1_SuggestVisitNotesRequest.Filter.with {
                    $0.createdAfter = reply0.outcome.effectiveAt
                    $0.labels = reply0.result.details
                    $0.ownerID = element.participantID
                    $0.region = reply0.visitNote.billingAddress.region
                }
            }
        }
        let replies1 = try await FanOut.map(requests1) { candidate in
            try await self.telehealthVisitNoteQuery.suggestVisitNotes(candidate)
        }
        let reply1 = replies1.first ?? Acme_Telehealth_V1_SuggestVisitNotesResponse()
        _ = reply1
        return Acme_Telehealth_V1_ApproveVideoVisitResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply0.visitNote.audit.createdAt
                }
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = reply0.visitNote.billingAddress.postalCode
                }
                $0.status = input.videoVisit.status
                $0.videoVisitID = input.videoVisitID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processCommentVideoVisitApproval(_ input: Acme_Telehealth_V1_CommentVideoVisitApprovalRequest) async throws
        -> Acme_Telehealth_V1_CommentVideoVisitApprovalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "audit", detail: input.details.approver.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "CommentVideoVisitApproval",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VideoVisitRecord(input.videoVisit, tenant: input.context.tenantID)
        try await store.save(record.stored)
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        let outbound0 = Acme_Featureflags_V1_CheckFeatureFlagEligibilityRequest.with {
            $0.context = Projection.read(input, at: \Acme_Telehealth_V1_CommentVideoVisitApprovalRequest.context)
            $0.featureFlag = Acme_Featureflags_V1_FeatureFlag.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = Projection.read(
                        input, at: \Acme_Telehealth_V1_CommentVideoVisitApprovalRequest.videoVisit.audit.createdBy)
                }
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.displayName = Projection.read(
                        input, at: \Acme_Telehealth_V1_CommentVideoVisitApprovalRequest.videoVisit.organizer.displayName
                    )
                    $0.userID = Projection.read(
                        input, at: \Acme_Telehealth_V1_CommentVideoVisitApprovalRequest.videoVisit.organizer.userID)
                }
            }
        }
        let reply0 = try await self.featureflagsFeatureFlagValidation.checkFeatureFlagEligibility(outbound0)
        return Acme_Telehealth_V1_CommentVideoVisitApprovalResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply0.featureFlag.audit.createdAt
                }
                $0.title = input.videoVisit.title
                $0.videoVisitID = input.videoVisitID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processDelegateVideoVisitApproval(_ input: Acme_Telehealth_V1_DelegateVideoVisitApprovalRequest) async throws
        -> Acme_Telehealth_V1_DelegateVideoVisitApprovalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "audit", detail: input.details.approver.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "DelegateVideoVisitApproval",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VideoVisitRecord(input.videoVisit, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Patients_V1_CheckPatientEligibilityRequest.with {
            $0.context = input.context
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = input.videoVisit.audit.updatedBy
                }
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = input.videoVisit.location.postalCode
                }
            }
        }
        let step0: @Sendable () async throws -> Acme_Patients_V1_CheckPatientEligibilityResponse = {
            try await self.patientsPatientValidation.checkPatientEligibility(outbound0)
        }
        let reply0 = try await step0()
        return Acme_Telehealth_V1_DelegateVideoVisitApprovalResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply0.patient.audit.updatedAt
                }
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.region = reply0.patient.primaryAddress.region
                }
                $0.status = input.videoVisit.status
                $0.videoVisitID = input.videoVisitID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processGetVideoVisitApprovalStatus(_ input: Acme_Telehealth_V1_GetVideoVisitApprovalStatusRequest) async throws
        -> Acme_Telehealth_V1_GetVideoVisitApprovalStatusResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "GetVideoVisitApprovalStatus",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "GetVideoVisitApprovalStatus", detail: input.context.traceID
        )
        var outbound0 = Acme_Ratelimiting_V1_CalculateRateLimitRequest()
        outbound0.context = input.context
        outbound0.rateLimit = Acme_Ratelimiting_V1_RateLimit.with {
            $0.audit = Acme_Common_V1_AuditInfo.with {
                $0.createdAt = input.context.deadline
            }
            $0.owner = Acme_Identity_V1_UserRef.with {
                $0.email = input.context.actor.email
                $0.userID = input.context.actor.userID
            }
        }
        let reply0 = try await self.ratelimitingRateLimitCalculation.calculateRateLimit(outbound0)
        let selection1_2: String
        switch reply0.rateLimit.action {
        case .block(let block):
            selection1_2 = block.reason
        default: selection1_2 = .init()
        }
        let outbound1 = Acme_Patients_V1_CalculateAllergyRequest.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.correlationID = reply0.result.correlationID
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = reply0.rateLimit.owner.displayName
                    $0.email = reply0.rateLimit.owner.email
                }
            }
            $0.context = input.context
            $0.reason = selection1_2
        }
        let reply1 = try await self.patientsAllergyCalculation.calculateAllergy(outbound1)
        return Acme_Telehealth_V1_GetVideoVisitApprovalStatusResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply1.result.message
                $0.status = "ok"
            }
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply0.rateLimit.audit.createdAt
                }
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.userID = reply0.rateLimit.owner.userID
                }
                $0.participants = [
                    Acme_Telehealth_V1_VideoVisitParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = reply1.allergy.subject.email
                        }
                    }
                ]
                $0.videoVisitID = input.videoVisitID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processListPendingVideoVisits(_ input: Acme_Telehealth_V1_ListPendingVideoVisitsRequest) async throws
        -> Acme_Telehealth_V1_ListPendingVideoVisitsResponse
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
            "ListPendingVideoVisits",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "ListPendingVideoVisits", detail: input.context.traceID
        )
        return Acme_Telehealth_V1_ListPendingVideoVisitsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processRecallVideoVisit(_ input: Acme_Telehealth_V1_RecallVideoVisitRequest) async throws
        -> Acme_Telehealth_V1_RecallVideoVisitResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "audit", detail: input.details.approver.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "RecallVideoVisit",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VideoVisitRecord(input.videoVisit, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Telehealth_V1_EstimateVideoVisitRequest.with {
            $0.context = input.context
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.participants = [
                    Acme_Telehealth_V1_VideoVisitParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = input.details.approver.email
                        }
                    }
                ]
            }
        }
        let step0: @Sendable () async throws -> Acme_Telehealth_V1_EstimateVideoVisitResponse = {
            try await self.telehealthVideoVisitCalculation.estimateVideoVisit(outbound0)
        }
        let reply0 = try await step0()
        let outbound1 = Acme_Patients_V1_CalculateAllergyRequest.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = input.videoVisit.organizer.displayName
                    $0.email = input.details.approver.email
                }
            }
            $0.context = input.context
            $0.details = Acme_Patients_V1_CalculateAllergyRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = input.videoVisit.location.countryCode
                    $0.recipient = reply0.videoVisit.location.recipient
                }
            }
        }
        let reply1 = try await self.patientsAllergyCalculation.calculateAllergy(outbound1)
        return Acme_Telehealth_V1_RecallVideoVisitResponse.with {
            $0.outcome = Acme_Telehealth_V1_RecallVideoVisitResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply1.result.message
                $0.referenceIds = reply1.result.referenceIds
                $0.status = "ok"
            }
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply0.videoVisit.audit.updatedBy
                }
                $0.metadata = input.videoVisit.metadata
                $0.videoVisitID = reply0.videoVisit.videoVisitID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processRejectVideoVisit(_ input: Acme_Telehealth_V1_RejectVideoVisitRequest) async throws
        -> Acme_Telehealth_V1_RejectVideoVisitResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "audit", detail: input.details.approver.email
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "RejectVideoVisit",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VideoVisitRecord(input.videoVisit, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Telehealth_V1_QuoteTriageRequest.with {
            $0.context = input.context
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = input.videoVisit.audit.etag
                    $0.updatedAt = input.videoVisit.audit.updatedAt
                }
                $0.customer = Acme_Telehealth_V1_VideoVisitRef.with {
                    $0.displayName = input.details.approver.displayName
                }
            }
        }
        async let remote0 = self.telehealthTriageCalculation.quoteTriage(outbound0)
        async let persisted0 = store.count(tenant: input.context.tenantID)
        let (reply0, count0) = try await (remote0, persisted0)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count0)])
        let selection1_2: Google_Protobuf_Timestamp
        switch reply0.triage.origin {
        case .customer(let customer):
            selection1_2 = customer.startsAt
        default: selection1_2 = .init()
        }
        let outbound1 = Acme_Venues_V1_BrowseVenuesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Venues_V1_BrowseVenuesRequest.Filter.with {
                $0.createdAfter = selection1_2
                $0.region = input.videoVisit.location.region
            }
        }
        let reply1 = try await self.venuesVenueQuery.browseVenues(outbound1)
        let outbound2 = Acme_Careplans_V1_ShareVitalReportRequest.with {
            $0.context = input.context
            $0.details = Acme_Careplans_V1_ShareVitalReportRequest.Details.with {
                $0.recipient = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.videoVisit.organizer.email
                }
            }
        }
        let reply2 = try await self.rejectVideoVisitStep2.execute(outbound2)
        let outbound3 = Acme_Telehealth_V1_ValidateVisitNoteRequest.with {
            $0.context = input.context
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = input.details.approver.displayName
                    $0.email = input.videoVisit.organizer.email
                }
            }
        }
        let port3 = RPCOperations.port { (request: Acme_Telehealth_V1_ValidateVisitNoteRequest) in
            try await self.telehealthVisitNoteValidation.validateVisitNote(request)
        }
        let reply3 = try await port3.execute(outbound3)
        return Acme_Telehealth_V1_RejectVideoVisitResponse.with {
            $0.outcome = Acme_Telehealth_V1_RejectVideoVisitResponse.Outcome.with {
                $0.referenceID = reply2.outcome.referenceID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply1.result.details
                $0.message = reply1.result.message
                $0.status = "ok"
            }
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply0.triage.assignee.displayName
                    $0.email = reply0.triage.assignee.email
                }
                $0.participants = [
                    Acme_Telehealth_V1_VideoVisitParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = reply3.visitNote.counterparty.email
                        }
                    }
                ]
                $0.videoVisitID = input.videoVisitID
                $0.window = input.videoVisit.window
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processSubmitVideoVisit(_ input: Acme_Telehealth_V1_SubmitVideoVisitRequest) async throws
        -> Acme_Telehealth_V1_SubmitVideoVisitResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "audit", detail: input.details.approver.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SubmitVideoVisit",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VideoVisitRecord(input.videoVisit, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let requests0 = input.videoVisit.participants.map { element in
            Acme_Careplans_V1_RejectCarePlanRequest.with {
                $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                    $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                        $0.countryCode = input.videoVisit.location.countryCode
                    }
                }
                $0.context = input.context
                $0.details = Acme_Careplans_V1_RejectCarePlanRequest.Details.with {
                    $0.approver = Acme_Identity_V1_UserRef.with {
                        $0.displayName = input.videoVisit.organizer.displayName
                        $0.email = element.contact.email
                    }
                }
            }
        }
        let replies0 = try await FanOut.map(requests0) { candidate in
            try await self.careplansCarePlanApproval.rejectCarePlan(candidate)
        }
        let reply0 = replies0.first ?? Acme_Careplans_V1_RejectCarePlanResponse()
        let outbound1 = Acme_Notifications_V1_CheckNotificationEligibilityRequest.with {
            $0.context = input.context
            $0.notification = Acme_Notifications_V1_Notification.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.videoVisit.organizer.userID
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.videoVisit.audit.createdAt
                    $0.etag = input.videoVisit.audit.etag
                }
                $0.customer = Acme_Notifications_V1_NotificationTemplateRef.with {
                    $0.displayName = reply0.carePlan.counterparty.displayName
                }
            }
        }
        let reply1 = try await self.submitVideoVisitStep1(outbound1)
        return Acme_Telehealth_V1_SubmitVideoVisitResponse.with {
            $0.outcome = Acme_Telehealth_V1_SubmitVideoVisitResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply1.result.message
                $0.status = "ok"
            }
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply1.notification.audit.updatedAt
                }
                $0.videoVisitID = input.videoVisitID
            }
        }
    }
}
