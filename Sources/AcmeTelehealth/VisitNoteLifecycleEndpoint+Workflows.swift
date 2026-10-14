import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension VisitNoteLifecycleEndpoint {
    /// Execute the telehealth workflow and project its upstream replies.
    func processActivateVisitNote(_ input: Acme_Telehealth_V1_ActivateVisitNoteRequest) async throws
        -> Acme_Telehealth_V1_ActivateVisitNoteResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.userID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "audit", detail: input.details.newOwner.userID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ActivateVisitNote",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "ActivateVisitNote", detail: input.context.traceID
        )
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
        var outbound0 = Acme_Careplans_V1_ShareVitalReportRequest()
        outbound0.context = input.context
        outbound0.details = Acme_Careplans_V1_ShareVitalReportRequest.Details.with {
            $0.recipient = Acme_Common_V1_ContactInfo.with {
                $0.email = input.details.newOwner.email
                $0.name = input.details.notifyContact.name
                $0.phone = input.details.notifyContact.phone
                $0.preferredChannel = input.details.notifyContact.preferredChannel
            }
        }
        let reply0 = try await self.careplansVitalReporting.shareVitalReport(outbound0)
        let outbound1 = Acme_Telehealth_V1_SimulateVideoVisitRequest.with {
            $0.context = input.context
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.participants = [
                    Acme_Telehealth_V1_VideoVisitParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = input.details.newOwner.email
                            $0.name = input.details.notifyContact.name
                        }
                    }
                ]
            }
        }
        let step1: @Sendable () async throws -> Acme_Telehealth_V1_SimulateVideoVisitResponse = {
            try await self.telehealthVideoVisitCalculation.simulateVideoVisit(outbound1)
        }
        let reply1 = try await step1()
        return Acme_Telehealth_V1_ActivateVisitNoteResponse.with {
            $0.outcome = Acme_Telehealth_V1_ActivateVisitNoteResponse.Outcome.with {
                $0.effectiveAt = reply0.outcome.effectiveAt
                $0.message = reply0.outcome.message
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply1.videoVisit.audit.createdBy
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = input.details.newOwner.displayName
                    $0.email = reply1.videoVisit.organizer.email
                }
                $0.visitNoteID = input.visitNoteID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processExpireVisitNote(_ input: Acme_Telehealth_V1_ExpireVisitNoteRequest) async throws
        -> Acme_Telehealth_V1_ExpireVisitNoteResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "audit", detail: input.details.newOwner.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ExpireVisitNote",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "ExpireVisitNote", detail: input.context.traceID
        )
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        let outbound0 = Acme_Patients_V1_SummarizePatientsRequest.with {
            $0.context = input.context
            $0.reason = input.reason
        }
        let reply0 = try await self.patientsPatientQuery.summarizePatients(outbound0)
        let outbound1 = Acme_Identity_V1_SuggestUsersRequest.with {
            $0.context = input.context
            $0.filter = Acme_Identity_V1_SuggestUsersRequest.Filter.with {
                $0.labels = reply0.result.details
            }
        }
        async let remote1 = self.identityUserQuery.suggestUsers(outbound1)
        async let persisted1 = store.count(tenant: input.context.tenantID)
        let (reply1, count1) = try await (remote1, persisted1)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count1)])
        let outbound2 = Acme_Search_V1_ResolveSearchIndexesRequest.with {
            $0.context = input.context
        }
        let reply2 = try await self.expireVisitNoteStep2.execute(outbound2)
        return Acme_Telehealth_V1_ExpireVisitNoteResponse.with {
            $0.outcome = Acme_Telehealth_V1_ExpireVisitNoteResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
                $0.message = reply1.result.message
                $0.status = reply0.result.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply2.result.correlationID
                $0.message = reply2.result.message
                $0.status = "ok"
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.visitNoteID = input.visitNoteID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processGetVisitNoteLifecycle(_ input: Acme_Telehealth_V1_GetVisitNoteLifecycleRequest) async throws
        -> Acme_Telehealth_V1_GetVisitNoteLifecycleResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "GetVisitNoteLifecycle",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "GetVisitNoteLifecycle", detail: input.context.traceID
        )
        return Acme_Telehealth_V1_GetVisitNoteLifecycleResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.visitNoteID = input.visitNoteID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processReinstateVisitNote(_ input: Acme_Telehealth_V1_ReinstateVisitNoteRequest) async throws
        -> Acme_Telehealth_V1_ReinstateVisitNoteResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.notifyContact.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "audit", detail: input.details.notifyContact.email
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ReinstateVisitNote",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "ReinstateVisitNote", detail: input.context.traceID
        )
        let outbound0 = Acme_Yards_V1_EstimateYardRequest.with {
            $0.context = input.context
            $0.yard = Acme_Yards_V1_Yard.with {
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.email = input.details.newOwner.email
                    $0.userID = input.details.newOwner.userID
                }
            }
        }
        let port0 = RPCOperations.port { (request: Acme_Yards_V1_EstimateYardRequest) in
            try await self.yardsYardCalculation.estimateYard(request)
        }
        let reply0 = try await port0.execute(outbound0)
        let selection1_1: String
        switch reply0.yard.locator {
        case .address(let address):
            selection1_1 = address.region
        default: selection1_1 = .init()
        }
        let outbound1 = Acme_Identity_V1_SuggestUsersRequest.with {
            $0.context = input.context
            $0.filter = Acme_Identity_V1_SuggestUsersRequest.Filter.with {
                $0.createdAfter = reply0.yard.audit.createdAt
                $0.ownerID = input.details.newOwner.userID
                $0.region = selection1_1
            }
        }
        let reply1 = try await self.identityUserQuery.suggestUsers(outbound1)
        let outbound2 = Acme_Telehealth_V1_ValidateTriageRequest.with {
            $0.context = input.context
            $0.details = Acme_Telehealth_V1_ValidateTriageRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.phone = input.details.notifyContact.phone
                }
            }
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.userID = reply0.yard.owner.userID
                }
                $0.customer = Acme_Telehealth_V1_VideoVisitRef.with {
                    $0.displayName = input.details.newOwner.displayName
                }
            }
        }
        let reply2 = try await self.reinstateVisitNoteStep2(outbound2)
        let selection3_1: String
        switch reply0.yard.locator {
        case .address(let address):
            selection3_1 = address.region
        default: selection3_1 = .init()
        }
        let outbound3 = Acme_Telehealth_V1_SuggestVideoVisitsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Telehealth_V1_SuggestVideoVisitsRequest.Filter.with {
                $0.createdAfter = reply2.triage.sla.dueAt
                $0.region = selection3_1
            }
        }
        let reply3 = try await self.telehealthVideoVisitQuery.suggestVideoVisits(outbound3)
        return Acme_Telehealth_V1_ReinstateVisitNoteResponse.with {
            $0.outcome = Acme_Telehealth_V1_ReinstateVisitNoteResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
                $0.message = reply2.result.message
                $0.status = reply1.result.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.message = Projection.firstValue(
                    [
                        reply0.result.message,
                        reply3.result.message,
                    ], default: .init())
                $0.referenceIds = reply3.result.referenceIds
                $0.status = reply2.result.status
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.email = reply0.yard.owner.email
                }
                $0.visitNoteID = input.visitNoteID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processRenewVisitNote(_ input: Acme_Telehealth_V1_RenewVisitNoteRequest) async throws
        -> Acme_Telehealth_V1_RenewVisitNoteResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "audit", detail: input.details.newOwner.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "RenewVisitNote",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "RenewVisitNote", detail: input.context.traceID
        )
        let outbound0 = Acme_Telehealth_V1_RecalculateTriagesRequest.with {
            $0.context = input.context
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.email = input.details.newOwner.email
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.phone = input.details.notifyContact.phone
                }
            }
        }
        guard let execute0 = self.renewVisitNoteStep0[settings.region] ?? self.renewVisitNoteStep0["primary"] else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply0 = try await execute0(outbound0)
        let outbound1 = Acme_Telehealth_V1_EstimateVideoVisitRequest.with {
            $0.context = input.context
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.email = reply0.triage.requester.email
                }
                $0.participants = [
                    Acme_Telehealth_V1_VideoVisitParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = reply0.triage.assignee.email
                            $0.phone = reply0.triage.requester.phone
                        }
                    }
                ]
            }
        }
        let reply1 = try await self.telehealthVideoVisitCalculation.estimateVideoVisit(outbound1)
        return Acme_Telehealth_V1_RenewVisitNoteResponse.with {
            $0.outcome = Acme_Telehealth_V1_RenewVisitNoteResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply0.triage.audit.createdBy
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.locality = reply1.videoVisit.location.locality
                }
                $0.metadata = reply1.videoVisit.metadata
                $0.visitNoteID = input.visitNoteID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processScheduleVisitNoteExpiry(_ input: Acme_Telehealth_V1_ScheduleVisitNoteExpiryRequest) async throws
        -> Acme_Telehealth_V1_ScheduleVisitNoteExpiryResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "audit", detail: input.details.initiatedBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ScheduleVisitNoteExpiry",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VisitNoteRecord(input.visitNote, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Telehealth_V1_EstimateTriageRequest.with {
            $0.context = input.context
            $0.details = Acme_Telehealth_V1_EstimateTriageRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = input.visitNote.billingAddress.countryCode
                }
            }
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.email = input.visitNote.counterparty.email
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = input.visitNote.audit.etag
                }
                $0.comments = [
                    Acme_Telehealth_V1_TriageComment.with {
                        $0.createdAt = input.visitNote.audit.createdAt
                    }
                ]
            }
        }
        let envelope0 = try Google_Protobuf_Any(message: outbound0)
        let unpacked0 = try Acme_Telehealth_V1_EstimateTriageRequest(unpackingAny: envelope0)
        let reply0 = try await self.telehealthTriageCalculation.estimateTriage(unpacked0)
        let outbound1 = Acme_Metrics_V1_CheckMetricSeriesEligibilityRequest.with {
            $0.context = input.context
            $0.metricSeries = Acme_Metrics_V1_MetricSeries.with {
                $0.address = Acme_Common_V1_PostalAddress.with {
                    $0.lines = input.visitNote.billingAddress.lines
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = input.visitNote.audit.createdBy
                }
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.email = input.details.notify.email
                }
            }
        }
        let json1 = try outbound1.jsonString()
        let decoded1 = try Acme_Metrics_V1_CheckMetricSeriesEligibilityRequest(jsonString: json1)
        let reply1 = try await self.metricsMetricSeriesValidation.checkMetricSeriesEligibility(decoded1)
        let selection2_1: String
        switch reply1.metricSeries.locator {
        case .address(let address):
            selection2_1 = address.region
        default: selection2_1 = .init()
        }
        let selection2_2: Google_Protobuf_Timestamp
        switch reply0.triage.origin {
        case .customer(let customer):
            selection2_2 = customer.startsAt
        default: selection2_2 = .init()
        }
        let outbound2 = Acme_Audit_V1_CountAuditEventsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Audit_V1_CountAuditEventsRequest.Filter.with {
                $0.createdAfter = selection2_2
                $0.region = selection2_1
            }
        }
        let reply2 = try await self.auditAuditEventQuery.countAuditEvents(outbound2)
        let outbound3 =
            Acme_Telehealth_V1_CompareVisitNoteOptionsRequest.forVisitNoteLifecycleEndpointScheduleVisitNoteExpiry3(
                input,
                reply0: reply0
            )
        let reply3 = try await self.telehealthVisitNoteCalculation.compareVisitNoteOptions(outbound3)
        return Acme_Telehealth_V1_ScheduleVisitNoteExpiryResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply1.result.details
                $0.message = reply2.result.message
                $0.status = "ok"
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply0.triage.audit.updatedBy
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.lines = reply3.visitNote.billingAddress.lines
                    $0.locality = reply1.metricSeries.address.locality
                }
                $0.counterparty = reply3.visitNote.counterparty
                $0.number = input.visitNote.number
                $0.visitNoteID = input.visitNoteID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processSuspendVisitNote(_ input: Acme_Telehealth_V1_SuspendVisitNoteRequest) async throws
        -> Acme_Telehealth_V1_SuspendVisitNoteResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "audit", detail: input.details.newOwner.email
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SuspendVisitNote",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "SuspendVisitNote", detail: input.context.traceID
        )
        let outbound0 = Acme_Search_V1_CreateSearchIndexRequest.with {
            $0.context = input.context
            $0.searchIndex = Acme_Search_V1_SearchIndex.with {
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.details.newOwner.displayName
                }
            }
        }
        let reply0 = try await self.searchSearchIndex.createSearchIndex(
            outbound0, metadata: ["x-acme-region": .string(settings.region)]
        )
        let selection1_1: String
        switch reply0.searchIndex.locator {
        case .address(let address):
            selection1_1 = address.region
        default: selection1_1 = .init()
        }
        let outbound1 = Acme_Identity_V1_BrowseUsersRequest.with {
            $0.context = input.context
            $0.filter = Acme_Identity_V1_BrowseUsersRequest.Filter.with {
                $0.region = selection1_1
            }
        }
        let reply1 = try await self.identityUserQuery.browseUsers(outbound1)
        return Acme_Telehealth_V1_SuspendVisitNoteResponse.with {
            $0.outcome = Acme_Telehealth_V1_SuspendVisitNoteResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
                $0.message = reply1.result.message
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.locality = reply0.searchIndex.address.locality
                    $0.recipient = reply0.searchIndex.address.recipient
                }
                $0.visitNoteID = input.visitNoteID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processTerminateVisitNote(_ input: Acme_Telehealth_V1_TerminateVisitNoteRequest) async throws
        -> Acme_Telehealth_V1_TerminateVisitNoteResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "audit", detail: input.details.newOwner.email
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "TerminateVisitNote",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "TerminateVisitNote", detail: input.context.traceID
        )
        let outbound0 = Acme_Search_V1_CreateSearchIndexRequest.with {
            $0.context = input.context
            $0.searchIndex = Acme_Search_V1_SearchIndex.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.details.effectiveAt
                }
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.details.newOwner.displayName
                    $0.email = input.details.notifyContact.email
                    $0.userID = input.details.newOwner.userID
                }
            }
        }
        let reply0 = try await RPCOperations.call(outbound0) { request in
            try await self.searchSearchIndex.createSearchIndex(request)
        }
        let selection1_1: String
        switch reply0.searchIndex.locator {
        case .address(let address):
            selection1_1 = address.locality
        default: selection1_1 = .init()
        }
        let outbound1 = Acme_Telehealth_V1_SimulateVisitNoteRequest.with {
            $0.context = input.context
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply0.searchIndex.audit.createdAt
                    $0.createdBy = reply0.searchIndex.audit.createdBy
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.locality = selection1_1
                }
            }
        }
        let reply1 = try await self.telehealthVisitNoteCalculation.simulateVisitNote(outbound1)
        return Acme_Telehealth_V1_TerminateVisitNoteResponse.with {
            $0.outcome = Acme_Telehealth_V1_TerminateVisitNoteResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.status = "ok"
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.patientID = reply1.visitNote.counterparty.patientID
                }
                $0.visitNoteID = input.visitNoteID
            }
        }
    }
}
