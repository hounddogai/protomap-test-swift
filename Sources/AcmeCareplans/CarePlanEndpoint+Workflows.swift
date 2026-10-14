import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension CarePlanEndpoint {
    /// Takes a stream of care plans and answers once at the end.
    func batchCreateCarePlans(
        request: StreamingServerRequest<Acme_Careplans_V1_BatchCreateCarePlansRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_BatchCreateCarePlansResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            var response = Acme_Careplans_V1_BatchCreateCarePlansResponse()
            var accepted: Int64 = 0
            for try await message in request.messages {
                response = try await processBatchCreateCarePlans(message)
                accepted += 1
            }
            response.accepted = accepted
            return ServerResponse(message: response)
        }
    }

    /// Returns several care plans at once.
    func batchGetCarePlans(
        request: ServerRequest<Acme_Careplans_V1_BatchGetCarePlansRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_BatchGetCarePlansResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processBatchGetCarePlans(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Creates a care plan.
    func cloneCarePlan(
        request: ServerRequest<Acme_Careplans_V1_CloneCarePlanRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_CloneCarePlanResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCloneCarePlan(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Creates a care plan.
    func createCarePlan(
        request: ServerRequest<Acme_Careplans_V1_CreateCarePlanRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_CreateCarePlanResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCreateCarePlan(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Deletes a care plan.
    func deleteCarePlan(
        request: ServerRequest<Acme_Careplans_V1_DeleteCarePlanRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_DeleteCarePlanResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processDeleteCarePlan(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a care plan.
    func getCarePlan(
        request: ServerRequest<Acme_Careplans_V1_GetCarePlanRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_GetCarePlanResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetCarePlan(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists care plans a page at a time.
    func listCarePlans(
        request: ServerRequest<Acme_Careplans_V1_ListCarePlansRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_ListCarePlansResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListCarePlans(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Changes a care plan.
    func updateCarePlan(
        request: ServerRequest<Acme_Careplans_V1_UpdateCarePlanRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_UpdateCarePlanResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processUpdateCarePlan(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Streams the changes of care plans as they happen.
    func watchCarePlans(
        request: ServerRequest<Acme_Careplans_V1_WatchCarePlansRequest>,
        context: ServerContext
    ) async throws -> StreamingServerResponse<Acme_Careplans_V1_WatchCarePlansResponse> {
        return StreamingServerResponse { writer in
            try await CallerScope.$metadata.withValue(request.metadata) {
                let response = try await self.processWatchCarePlans(request.message)
                try await writer.write(response)
                return [:]
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processBatchCreateCarePlans(_ input: Acme_Careplans_V1_BatchCreateCarePlansRequest) async throws
        -> Acme_Careplans_V1_BatchCreateCarePlansResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.header.format)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "audit", detail: input.header.format
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "BatchCreateCarePlans",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "BatchCreateCarePlans", detail: input.context.traceID
        )
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        let selection0_1: String
        switch input.chunk {
        case .record(let record):
            selection0_1 = record.billingAddress.region
        default: selection0_1 = .init()
        }
        let selection0_2: Google_Protobuf_Timestamp
        switch input.chunk {
        case .record(let record):
            selection0_2 = record.audit.updatedAt
        default: selection0_2 = .init()
        }
        let selection0_3: String
        switch input.chunk {
        case .record(let record):
            selection0_3 = record.counterparty.appointmentID
        default: selection0_3 = .init()
        }
        let selection0_4: [String: String]
        switch input.chunk {
        case .record(let record):
            selection0_4 = record.metadata
        default: selection0_4 = .init()
        }
        let outbound0 = Acme_Authorization_V1_ListAccessPoliciesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Authorization_V1_ListAccessPoliciesRequest.Filter.with {
                $0.createdAfter = selection0_2
                $0.labels = selection0_4
                $0.ownerID = selection0_3
                $0.region = selection0_1
            }
        }
        let reply0 = try await self.authorizationAccessPolicy.listAccessPolicies(outbound0)
        let selection1_1: String
        switch input.chunk {
        case .record(let record):
            selection1_1 = record.billingAddress.region
        default: selection1_1 = .init()
        }
        let outbound1 = Acme_Ledger_V1_FindLedgerAccountsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Ledger_V1_FindLedgerAccountsRequest.Filter.with {
                $0.region = selection1_1
            }
        }
        let reply1 = try await self.ledgerLedgerAccountQuery.findLedgerAccounts(outbound1)
        let selection2_1: String
        switch input.chunk {
        case .record(let record):
            selection2_1 = record.billingAddress.region
        default: selection2_1 = .init()
        }
        let selection2_2: Google_Protobuf_Timestamp
        switch input.chunk {
        case .record(let record):
            selection2_2 = record.audit.createdAt
        default: selection2_2 = .init()
        }
        let outbound2 = Acme_Careplans_V1_BrowseCarePlansRequest.with {
            $0.context = input.context
            $0.filter = Acme_Careplans_V1_BrowseCarePlansRequest.Filter.with {
                $0.createdAfter = selection2_2
                $0.region = selection2_1
            }
        }
        let reply2 = try await self.careplansCarePlanQuery.browseCarePlans(outbound2)
        return Acme_Careplans_V1_BatchCreateCarePlansResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.message = reply1.result.message
                $0.referenceIds = reply0.result.referenceIds + reply1.result.referenceIds + reply2.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processBatchGetCarePlans(_ input: Acme_Careplans_V1_BatchGetCarePlansRequest) async throws
        -> Acme_Careplans_V1_BatchGetCarePlansResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "BatchGetCarePlans",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "BatchGetCarePlans", detail: input.context.traceID
        )
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        let outbound0 = Acme_Careplans_V1_ExplainCarePlanDecisionRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = Projection.read(
                        input, at: \Acme_Careplans_V1_BatchGetCarePlansRequest.context.deadline)
                }
            }
            $0.context = Projection.read(input, at: \Acme_Careplans_V1_BatchGetCarePlansRequest.context)
            $0.details = Acme_Careplans_V1_ExplainCarePlanDecisionRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = Projection.read(
                        input, at: \Acme_Careplans_V1_BatchGetCarePlansRequest.context.actor.email)
                }
                $0.locale = Projection.read(input, at: \Acme_Careplans_V1_BatchGetCarePlansRequest.context.locale)
            }
        }
        let reply0 = try await self.careplansCarePlanValidation.explainCarePlanDecision(outbound0)
        let outbound1 = Acme_Authorization_V1_PreviewAccessPolicyRequest.with {
            $0.accessPolicy = Acme_Authorization_V1_AccessPolicy.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply0.carePlan.audit.createdAt
                    $0.createdBy = reply0.carePlan.audit.createdBy
                }
            }
            $0.context = input.context
        }
        let step1: @Sendable () async throws -> Acme_Authorization_V1_PreviewAccessPolicyResponse = {
            try await self.authorizationAccessPolicyValidation.previewAccessPolicy(outbound1)
        }
        let reply1 = try await step1()
        return Acme_Careplans_V1_BatchGetCarePlansResponse.with {
            $0.carePlans = [
                Acme_Careplans_V1_CarePlan.with {
                    $0.audit = Acme_Common_V1_AuditInfo.with {
                        $0.updatedAt = reply1.accessPolicy.audit.updatedAt
                    }
                    $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                        $0.lines = reply0.carePlan.billingAddress.lines
                    }
                    $0.notes = reply0.carePlan.notes
                }
            ]
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processCloneCarePlan(_ input: Acme_Careplans_V1_CloneCarePlanRequest) async throws
        -> Acme_Careplans_V1_CloneCarePlanResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.carePlan.audit.createdBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "audit", detail: input.carePlan.audit.createdBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "CloneCarePlan",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CarePlanRecord(input.carePlan, tenant: input.context.tenantID)
        try await store.save(record.stored)
        var outbound0 = Acme_Careplans_V1_CalculateCarePlanRequest()
        outbound0.carePlan = Acme_Careplans_V1_CarePlan.with {
            $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                $0.postalCode = input.carePlan.billingAddress.postalCode
            }
        }
        outbound0.context = input.context
        outbound0.details = Acme_Careplans_V1_CalculateCarePlanRequest.Details.with {
            $0.destination = Acme_Common_V1_PostalAddress.with {
                $0.countryCode = input.carePlan.billingAddress.countryCode
            }
        }
        let reply0 = try await self.careplansCarePlanCalculation.calculateCarePlan(outbound0)
        let outbound1 = Acme_Careplans_V1_BrowseCarePlansRequest.with {
            $0.context = input.context
            $0.filter = Acme_Careplans_V1_BrowseCarePlansRequest.Filter.with {
                $0.region = reply0.carePlan.billingAddress.region
            }
        }
        let reply1 = try await RPCOperations.read {
            try await self.careplansCarePlanQuery.browseCarePlans(outbound1)
        }
        return Acme_Careplans_V1_CloneCarePlanResponse.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.carePlanID = input.carePlan.carePlanID
                $0.status = reply0.carePlan.status
                $0.total = input.carePlan.total
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.referenceIds = reply1.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processCreateCarePlan(_ input: Acme_Careplans_V1_CreateCarePlanRequest) async throws
        -> Acme_Careplans_V1_CreateCarePlanResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.carePlan.audit.createdBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "audit", detail: input.carePlan.audit.createdBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "CreateCarePlan",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CarePlanRecord(input.carePlan, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Sponsorships_V1_ExportSponsorsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Sponsorships_V1_ExportSponsorsRequest.Filter.with {
                $0.createdAfter = input.carePlan.counterparty.startsAt
                $0.region = input.carePlan.billingAddress.region
            }
        }
        let reply0 = try await self.sponsorshipsSponsorQuery.exportSponsors(outbound0) { response in
            var latest = Acme_Sponsorships_V1_ExportSponsorsResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        _ = reply0
        let selection1_2: String
        switch input.carePlan.settlement {
        case .bank(let bank):
            selection1_2 = bank.accountHolder
        default: selection1_2 = .init()
        }
        let outbound1 = Acme_Careplans_V1_ValidateCarePlanRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.carePlan.audit.createdAt
                }
                $0.bank = Acme_Careplans_V1_CarePlanBankSettlement.with {
                    $0.accountHolder = selection1_2
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.lines = input.carePlan.billingAddress.lines
                    $0.postalCode = input.carePlan.billingAddress.postalCode
                }
            }
            $0.context = input.context
        }
        let reply1 = try await self.careplansCarePlanValidation.validateCarePlan(outbound1)
        let outbound2 = Acme_Documents_V1_SummarizeDocumentsRequest.with {
            $0.annotations = input.carePlan.metadata
            $0.context = input.context
            $0.details = Acme_Documents_V1_SummarizeDocumentsRequest.Details.with {
                $0.filters = reply1.result.details
            }
        }
        let reply2 = try await self.documentsDocumentQuery.summarizeDocuments(outbound2)
        let requests3 = input.carePlan.attachments.map { element in
            Acme_Careplans_V1_QuoteCarePlanRequest.with {
                $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                    $0.attachments = [
                        Acme_Careplans_V1_CarePlanAttachment.with {
                            $0.checksum = element.checksum
                            $0.contentType = element.contentType
                            $0.uri = element.uri
                        }
                    ]
                }
                $0.context = input.context
            }
        }
        let replies3 = try await FanOut.map(requests3) { candidate in
            try await self.careplansCarePlanCalculation.quoteCarePlan(candidate)
        }
        let reply3 = replies3.first ?? Acme_Careplans_V1_QuoteCarePlanResponse()
        _ = reply3
        return Acme_Careplans_V1_CreateCarePlanResponse.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.counterparty = Acme_Appointments_V1_AppointmentRef.with {
                    $0.displayName = reply1.carePlan.counterparty.displayName
                }
                $0.metadata = input.carePlan.metadata
                $0.number = input.carePlan.number
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply2.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processDeleteCarePlan(_ input: Acme_Careplans_V1_DeleteCarePlanRequest) async throws
        -> Acme_Careplans_V1_DeleteCarePlanResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.etag)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "audit", detail: input.etag
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "DeleteCarePlan",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "DeleteCarePlan", detail: input.context.traceID
        )
        let outbound0 = Acme_Careplans_V1_EstimateVitalRequest.with {
            $0.context = input.context
            $0.reason = input.reason
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.correlationID = input.carePlanID
                $0.occurredAt = input.context.deadline
                $0.source = input.context.actor.userID
            }
        }
        async let remote0 = self.careplansVitalCalculation.estimateVital(outbound0)
        async let persisted0 = store.count(tenant: input.context.tenantID)
        let (reply0, count0) = try await (remote0, persisted0)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count0)])
        return Acme_Careplans_V1_DeleteCarePlanResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processGetCarePlan(_ input: Acme_Careplans_V1_GetCarePlanRequest) async throws
        -> Acme_Careplans_V1_GetCarePlanResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "GetCarePlan",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "GetCarePlan", detail: input.context.traceID
        )
        let outbound0 = Acme_Careplans_V1_SimulateCarePlanRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.context.deadline
                }
            }
            $0.carePlanID = input.carePlanID
            $0.context = input.context
        }
        let reply0 = try await self.getCarePlanStep0.execute(outbound0)
        let outbound1 = Acme_Documents_V1_CheckDocumentEligibilityRequest.with {
            $0.context = input.context
            $0.document = Acme_Documents_V1_Document.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.locality = reply0.carePlan.billingAddress.locality
                }
            }
        }
        let port1 = RPCOperations.port { (request: Acme_Documents_V1_CheckDocumentEligibilityRequest) in
            try await self.documentsDocumentValidation.checkDocumentEligibility(request)
        }
        let reply1 = try await port1.execute(outbound1)
        return Acme_Careplans_V1_GetCarePlanResponse.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = reply0.carePlan.billingAddress.postalCode
                }
                $0.carePlanID = input.carePlanID
                $0.counterparty = Acme_Appointments_V1_AppointmentRef.with {
                    $0.displayName = reply1.document.counterparty.displayName
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processListCarePlans(_ input: Acme_Careplans_V1_ListCarePlansRequest) async throws
        -> Acme_Careplans_V1_ListCarePlansResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ListCarePlans",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "ListCarePlans", detail: input.context.traceID
        )
        let outbound0 = Acme_Careplans_V1_EstimateCareGoalRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.context.actor.userID
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.filter.createdAfter
                }
            }
            $0.context = input.context
            $0.details = Acme_Careplans_V1_EstimateCareGoalRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
            }
        }
        let reply0 = try await self.listCarePlansStep0(outbound0)
        let selection1_2: String
        switch reply0.careGoal.origin {
        case .customer(let customer):
            selection1_2 = customer.displayName
        default: selection1_2 = .init()
        }
        let outbound1 = Acme_Careplans_V1_ScoreCarePlanRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply0.careGoal.audit.createdAt
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
                $0.counterparty = Acme_Appointments_V1_AppointmentRef.with {
                    $0.displayName = selection1_2
                }
            }
            $0.context = input.context
        }
        let reply1 = try await self.careplansCarePlanValidation.scoreCarePlan(outbound1)
        return Acme_Careplans_V1_ListCarePlansResponse.with {
            $0.carePlans = [
                Acme_Careplans_V1_CarePlan.with {
                    $0.audit = Acme_Common_V1_AuditInfo.with {
                        $0.updatedBy = reply0.careGoal.audit.updatedBy
                    }
                    $0.total = reply1.breakdown.total
                }
            ]
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processUpdateCarePlan(_ input: Acme_Careplans_V1_UpdateCarePlanRequest) async throws
        -> Acme_Careplans_V1_UpdateCarePlanResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.carePlan.audit.createdBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "audit", detail: input.carePlan.audit.createdBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "UpdateCarePlan",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CarePlanRecord(input.carePlan, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Careplans_V1_BrowseCarePlansRequest.with {
            $0.context = input.context
            $0.filter = Acme_Careplans_V1_BrowseCarePlansRequest.Filter.with {
                $0.createdAfter = input.carePlan.audit.createdAt
                $0.region = input.carePlan.billingAddress.region
            }
        }
        guard let execute0 = self.updateCarePlanStep0[settings.region] ?? self.updateCarePlanStep0["primary"] else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply0 = try await execute0(outbound0)
        let outbound1 = Acme_Careplans_V1_CompareCarePlanOptionsRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = input.carePlan.audit.updatedAt
                }
            }
            $0.context = input.context
            $0.details = Acme_Careplans_V1_CompareCarePlanOptionsRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = input.carePlan.billingAddress.countryCode
                }
            }
        }
        let reply1 = try await self.careplansCarePlanCalculation.compareCarePlanOptions(outbound1)
        return Acme_Careplans_V1_UpdateCarePlanResponse.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.lines = reply1.carePlan.billingAddress.lines
                }
                $0.counterparty = input.carePlan.counterparty
                $0.dueAt = input.carePlan.dueAt
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processWatchCarePlans(_ input: Acme_Careplans_V1_WatchCarePlansRequest) async throws
        -> Acme_Careplans_V1_WatchCarePlansResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.subscriber.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "audit", detail: input.subscriber.email
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "WatchCarePlans",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "WatchCarePlans", detail: input.context.traceID
        )
        let outbound0 = Acme_Admissions_V1_BrowseAdmissionsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Admissions_V1_BrowseAdmissionsRequest.Filter.with {
                $0.createdAfter = input.filter.createdAfter
                $0.labels = input.filter.labels
                $0.ownerID = input.filter.ownerID
                $0.query = input.filter.query
            }
        }
        let envelope0 = try Google_Protobuf_Any(message: outbound0)
        let unpacked0 = try Acme_Admissions_V1_BrowseAdmissionsRequest(unpackingAny: envelope0)
        let reply0 = try await self.admissionsAdmissionQuery.browseAdmissions(unpacked0)
        return Acme_Careplans_V1_WatchCarePlansResponse.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }
}
