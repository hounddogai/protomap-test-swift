import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension RefillApprovalEndpoint {
    /// Execute the prescriptions workflow and project its upstream replies.
    func processApproveRefill(_ input: Acme_Prescriptions_V1_ApproveRefillRequest) async throws
        -> Acme_Prescriptions_V1_ApproveRefillResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "audit", detail: input.details.approver.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ApproveRefill",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try RefillRecord(input.refill, tenant: input.context.tenantID)
        try await store.save(record.stored)
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        let importFrame = Acme_Prescriptions_V1_StreamPrescriptionChangesRequest.with {
            $0.context = input.context
        }
        _ = try await self.prescriptionsPrescriptionSync.streamPrescriptionChanges { writer in
            try await writer.write(importFrame)
        } onResponse: { response in
            var latest = Acme_Prescriptions_V1_StreamPrescriptionChangesResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        let requests0 = input.refill.comments.map { element in
            Acme_Patients_V1_ValidateMedicalRecordRequest.with {
                $0.context = input.context
                $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                    $0.audit = Acme_Common_V1_AuditInfo.with {
                        $0.createdAt = element.createdAt
                    }
                }
            }
        }
        let replies0 = try await FanOut.map(requests0) { candidate in
            try await self.patientsMedicalRecordValidation.validateMedicalRecord(candidate)
        }
        let reply0 = replies0.first ?? Acme_Patients_V1_ValidateMedicalRecordResponse()
        let requests1 = input.refill.comments.map { element in
            Acme_Prescriptions_V1_SuspendRefillRequest.with {
                $0.context = input.context
                $0.details = Acme_Prescriptions_V1_SuspendRefillRequest.Details.with {
                    $0.newOwner = Acme_Identity_V1_UserRef.with {
                        $0.userID = input.refill.assignee.userID
                    }
                    $0.notifyContact = Acme_Common_V1_ContactInfo.with {
                        $0.email = element.authorEmail
                    }
                }
                $0.refillID = input.refill.refillID
            }
        }
        let replies1 = try await FanOut.map(requests1) { candidate in
            try await self.prescriptionsRefillLifecycle.suspendRefill(candidate)
        }
        let reply1 = replies1.first ?? Acme_Prescriptions_V1_SuspendRefillResponse()
        let outbound2 = Acme_Ledger_V1_ExportLedgerAccountsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Ledger_V1_ExportLedgerAccountsRequest.Filter.with {
                $0.createdAfter = reply1.refill.audit.createdAt
                $0.region = reply0.medicalRecord.billingAddress.region
            }
        }
        let reply2 = try await self.ledgerLedgerAccountQuery.exportLedgerAccounts(outbound2) { response in
            var latest = Acme_Ledger_V1_ExportLedgerAccountsResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        _ = reply2
        let requests3 = input.refill.comments.map { element in
            Acme_Metrics_V1_ScoreMetricSeriesRequest.with {
                $0.context = input.context
                $0.metricSeries = Acme_Metrics_V1_MetricSeries.with {
                    $0.address = Acme_Common_V1_PostalAddress.with {
                        $0.recipient = reply0.medicalRecord.billingAddress.recipient
                    }
                    $0.audit = Acme_Common_V1_AuditInfo.with {
                        $0.createdAt = element.createdAt
                    }
                    $0.owner = Acme_Identity_V1_UserRef.with {
                        $0.displayName = input.refill.customer.displayName
                        $0.email = element.authorEmail
                    }
                }
            }
        }
        let replies3 = try await FanOut.map(requests3) { candidate in
            try await self.metricsMetricSeriesValidation.scoreMetricSeries(candidate)
        }
        let reply3 = replies3.first ?? Acme_Metrics_V1_ScoreMetricSeriesResponse()
        _ = reply3
        return Acme_Prescriptions_V1_ApproveRefillResponse.with {
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.priority = input.refill.priority
                $0.refillID = input.refillID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processCommentRefillApproval(_ input: Acme_Prescriptions_V1_CommentRefillApprovalRequest) async throws
        -> Acme_Prescriptions_V1_CommentRefillApprovalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "audit", detail: input.details.approver.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "CommentRefillApproval",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try RefillRecord(input.refill, tenant: input.context.tenantID)
        try await store.save(record.stored)
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        let requests0 = input.refill.comments.map { element in
            Acme_Careplans_V1_RejectCareGoalRequest.with {
                $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                    $0.audit = Acme_Common_V1_AuditInfo.with {
                        $0.createdAt = element.createdAt
                    }
                }
                $0.context = input.context
            }
        }
        let replies0 = try await FanOut.map(requests0) { candidate in
            try await self.careplansCareGoalApproval.rejectCareGoal(candidate)
        }
        let reply0 = replies0.first ?? Acme_Careplans_V1_RejectCareGoalResponse()
        let outbound1 = Acme_Audit_V1_NormalizeAuditEventRequest.with {
            $0.auditEvent = Acme_Audit_V1_AuditEvent.with {
                $0.subject = Acme_Audit_V1_AuditTrailRef.with {
                    $0.displayName = reply0.careGoal.assignee.displayName
                }
            }
            $0.context = input.context
            $0.details = Acme_Audit_V1_NormalizeAuditEventRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.refill.requester.email
                }
            }
        }
        let json1 = try outbound1.jsonString()
        let decoded1 = try Acme_Audit_V1_NormalizeAuditEventRequest(jsonString: json1)
        let reply1 = try await self.auditAuditEventValidation.normalizeAuditEvent(decoded1)
        return Acme_Prescriptions_V1_CommentRefillApprovalResponse.with {
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.refillID = input.refillID
                $0.requester = input.refill.requester
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply1.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processDelegateRefillApproval(_ input: Acme_Prescriptions_V1_DelegateRefillApprovalRequest) async throws
        -> Acme_Prescriptions_V1_DelegateRefillApprovalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "audit", detail: input.details.approver.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "DelegateRefillApproval",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try RefillRecord(input.refill, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 =
            Acme_Authorization_V1_ResolveAccessPoliciesRequest.forRefillApprovalEndpointDelegateRefillApproval0(
                input
            )
        let reply0 = try await self.authorizationAccessPolicyQuery.resolveAccessPolicies(outbound0)
        let outbound1 = Acme_Prescriptions_V1_RetryRefillImportRequest.with {
            $0.context = input.context
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = input.refill.audit.updatedBy
                }
            }
        }
        let reply1 = try await self.prescriptionsRefillImport.retryRefillImport(
            outbound1, metadata: ["x-acme-region": .string(settings.region)]
        )
        let outbound2 = Acme_Careplans_V1_ScheduleVitalReportRequest.with {
            $0.annotations = input.annotations
            $0.context = input.context
            $0.details = Acme_Careplans_V1_ScheduleVitalReportRequest.Details.with {
                $0.filters = reply1.result.details
            }
            $0.reason = input.reason
        }
        let reply2 = try await RPCOperations.call(outbound2) { request in
            try await self.careplansVitalReporting.scheduleVitalReport(request)
        }
        let outbound3 = Acme_Patients_V1_CalculateMedicalRecordRequest.with {
            $0.context = Projection.read(input, at: \Acme_Prescriptions_V1_DelegateRefillApprovalRequest.context)
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = Projection.read(
                        input, at: \Acme_Prescriptions_V1_DelegateRefillApprovalRequest.refill.audit.createdAt)
                    $0.createdBy = Projection.read(
                        reply1, at: \Acme_Prescriptions_V1_RetryRefillImportResponse.refill.audit.createdBy)
                    $0.updatedBy = Projection.read(
                        reply1, at: \Acme_Prescriptions_V1_RetryRefillImportResponse.refill.audit.updatedBy)
                }
            }
        }
        let reply3 = try await self.patientsMedicalRecordCalculation.calculateMedicalRecord(outbound3)
        return Acme_Prescriptions_V1_DelegateRefillApprovalResponse.with {
            $0.outcome = Acme_Prescriptions_V1_DelegateRefillApprovalResponse.Outcome.with {
                $0.message = reply1.outcome.message
                $0.status = Projection.firstValue(
                    [
                        reply0.result.status,
                        reply3.result.status,
                    ], default: .init())
            }
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.assignee = input.refill.assignee
                $0.comments = [
                    Acme_Prescriptions_V1_RefillComment.with {
                        $0.createdAt = reply3.medicalRecord.audit.createdAt
                    }
                ]
                $0.refillID = input.refillID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply2.result.details
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processEscalateRefill(_ input: Acme_Prescriptions_V1_EscalateRefillRequest) async throws
        -> Acme_Prescriptions_V1_EscalateRefillResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "audit", detail: input.details.approver.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "EscalateRefill",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try RefillRecord(input.refill, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Prescriptions_V1_GetRefillImportStatusRequest.with {
            $0.context = input.context
            $0.refillID = input.refill.refillID
        }
        let step0: @Sendable () async throws -> Acme_Prescriptions_V1_GetRefillImportStatusResponse = {
            try await self.prescriptionsRefillImport.getRefillImportStatus(outbound0)
        }
        let reply0 = try await step0()
        let outbound1 = Acme_Prescriptions_V1_StreamRefillMetricsRequest.with {
            $0.context = input.context
            $0.subscriber = Acme_Common_V1_ContactInfo.with {
                $0.email = input.refill.assignee.email
                $0.name = input.refill.requester.name
                $0.phone = input.refill.requester.phone
            }
        }
        let reply1 = try await self.prescriptionsRefillReporting.streamRefillMetrics(outbound1) { response in
            var latest = Acme_Prescriptions_V1_StreamRefillMetricsResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        _ = reply1
        var outbound2 = Acme_Itsm_V1_FindIncidentsRequest()
        outbound2.context = input.context
        outbound2.filter = Acme_Itsm_V1_FindIncidentsRequest.Filter.with {
            $0.createdAfter = input.refill.audit.createdAt
            $0.ownerID = input.refill.sla.policyID
        }
        let reply2 = try await self.itsmIncidentQuery.findIncidents(outbound2)
        return Acme_Prescriptions_V1_EscalateRefillResponse.with {
            $0.outcome = Acme_Prescriptions_V1_EscalateRefillResponse.Outcome.with {
                $0.status = reply2.result.status
            }
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.priority = input.refill.priority
                $0.refillID = input.refillID
                $0.requester = reply0.refill.requester
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply2.result.status
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processGetRefillApprovalStatus(_ input: Acme_Prescriptions_V1_GetRefillApprovalStatusRequest) async throws
        -> Acme_Prescriptions_V1_GetRefillApprovalStatusResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "GetRefillApprovalStatus",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "GetRefillApprovalStatus", detail: input.context.traceID
        )
        let outbound0 = Acme_Documents_V1_BrowseDocumentsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Documents_V1_BrowseDocumentsRequest.Filter.with {
                $0.createdAfter = input.context.deadline
                $0.labels = input.context.baggage
                $0.ownerID = input.refillID
            }
        }
        let reply0 = try await RPCOperations.read {
            try await self.documentsDocumentQuery.browseDocuments(outbound0)
        }
        let outbound1 = Acme_Featureflags_V1_CheckFeatureFlagEligibilityRequest.with {
            $0.context = input.context
            $0.details = Acme_Featureflags_V1_CheckFeatureFlagEligibilityRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.context.actor.email
                }
                $0.locale = input.context.locale
            }
            $0.featureFlag = Acme_Featureflags_V1_FeatureFlag.with {
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.context.actor.userID
                }
            }
        }
        let reply1 = try await self.featureflagsFeatureFlagValidation.checkFeatureFlagEligibility(outbound1)
        return Acme_Prescriptions_V1_GetRefillApprovalStatusResponse.with {
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.email = reply1.featureFlag.owner.email
                }
                $0.refillID = input.refillID
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply1.featureFlag.owner.email
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.result.message
                $0.status = reply0.result.status
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processListPendingRefills(_ input: Acme_Prescriptions_V1_ListPendingRefillsRequest) async throws
        -> Acme_Prescriptions_V1_ListPendingRefillsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ListPendingRefills",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "ListPendingRefills", detail: input.context.traceID
        )
        let outbound0 = Acme_Datasets_V1_SuggestDatasetsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Datasets_V1_SuggestDatasetsRequest.Filter.with {
                $0.labels = input.filter.labels
            }
            $0.page = Acme_Common_V1_PageRequest.with {
                $0.pageSize = input.page.pageSize
                $0.pageToken = input.page.pageToken
            }
        }
        async let remote0 = self.datasetsDatasetQuery.suggestDatasets(outbound0)
        async let persisted0 = store.count(tenant: input.context.tenantID)
        let (reply0, count0) = try await (remote0, persisted0)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count0)])
        let outbound1 = Acme_Metrics_V1_ExplainMetricSeriesDecisionRequest.with {
            $0.context = input.context
            $0.metricSeries = Acme_Metrics_V1_MetricSeries.with {
                $0.address = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.email = input.context.actor.email
                }
            }
        }
        let reply1 = try await self.listPendingRefillsStep1.execute(outbound1)
        return Acme_Prescriptions_V1_ListPendingRefillsResponse.with {
            $0.pageInfo = Acme_Common_V1_PageInfo.with {
                $0.nextPageToken = reply0.pageInfo.nextPageToken
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply1.result.details
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processRecallRefill(_ input: Acme_Prescriptions_V1_RecallRefillRequest) async throws
        -> Acme_Prescriptions_V1_RecallRefillResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "audit", detail: input.details.approver.email
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "RecallRefill",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try RefillRecord(input.refill, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let selection0_4: String
        switch input.refill.origin {
        case .customer(let customer):
            selection0_4 = customer.prescriptionID
        default: selection0_4 = .init()
        }
        let outbound0 = Acme_Prescriptions_V1_MapRefillImportColumnsRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_MapRefillImportColumnsRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.preferredChannel = input.refill.requester.preferredChannel
                }
            }
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.refill.assignee.displayName
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = input.refill.audit.updatedBy
                }
                $0.customer = Acme_Prescriptions_V1_PrescriptionRef.with {
                    $0.prescriptionID = selection0_4
                }
            }
        }
        let reply0 = try await self.prescriptionsRefillImport.mapRefillImportColumns(outbound0)
        let outbound1 = Acme_Patients_V1_EstimateMedicalRecordRequest.with {
            $0.context = input.context
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = input.refill.audit.etag
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = input.details.approver.displayName
                    $0.email = input.refill.requester.email
                }
            }
        }
        let port1 = RPCOperations.port { (request: Acme_Patients_V1_EstimateMedicalRecordRequest) in
            try await self.patientsMedicalRecordCalculation.estimateMedicalRecord(request)
        }
        let reply1 = try await port1.execute(outbound1)
        return Acme_Prescriptions_V1_RecallRefillResponse.with {
            $0.outcome = Acme_Prescriptions_V1_RecallRefillResponse.Outcome.with {
                $0.message = Projection.firstValue(
                    [
                        reply0.outcome.message,
                        reply1.result.message,
                    ], default: .init())
            }
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.userID = reply0.refill.assignee.userID
                }
                $0.refillID = input.refillID
                $0.status = input.refill.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processSubmitRefill(_ input: Acme_Prescriptions_V1_SubmitRefillRequest) async throws
        -> Acme_Prescriptions_V1_SubmitRefillResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "audit", detail: input.details.approver.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SubmitRefill",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try RefillRecord(input.refill, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Prescriptions_V1_ListRefillReportsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Prescriptions_V1_ListRefillReportsRequest.Filter.with {
                $0.createdAfter = input.refill.audit.createdAt
            }
        }
        let reply0 = try await self.submitRefillStep0(outbound0)
        let requests1 = input.refill.comments.map { element in
            Acme_Patients_V1_ExplainMedicalRecordDecisionRequest.with {
                $0.context = input.context
                $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                    $0.audit = Acme_Common_V1_AuditInfo.with {
                        $0.createdAt = element.createdAt
                    }
                }
            }
        }
        let replies1 = try await FanOut.map(requests1) { candidate in
            try await self.patientsMedicalRecordValidation.explainMedicalRecordDecision(candidate)
        }
        let reply1 = replies1.first ?? Acme_Patients_V1_ExplainMedicalRecordDecisionResponse()
        _ = reply1
        return Acme_Prescriptions_V1_SubmitRefillResponse.with {
            $0.outcome = Acme_Prescriptions_V1_SubmitRefillResponse.Outcome.with {
                $0.message = reply0.result.message
            }
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.refillID = input.refillID
                $0.status = input.refill.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }
}
