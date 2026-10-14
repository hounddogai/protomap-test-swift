import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension CareInboxQueryEndpoint {
    /// Execute the patientapp workflow and project its upstream replies.
    func processBrowseCareInboxes(_ input: Acme_Patientapp_V1_BrowseCareInboxesRequest) async throws
        -> Acme_Patientapp_V1_BrowseCareInboxesResponse
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
            "BrowseCareInboxes",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "BrowseCareInboxes", detail: input.context.traceID
        )
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        try followUps.submit(
            Acme_Identity_V1_GetUserRequest.with {
                $0.context = input.context
                $0.userID = input.context.actor.userID
            })
        let importFrame = Acme_Prescriptions_V1_StreamMedicationChangesRequest.with {
            $0.context = input.context
        }
        _ = try await self.prescriptionsMedicationSync.streamMedicationChanges { writer in
            try await writer.write(importFrame)
        } onResponse: { response in
            var latest = Acme_Prescriptions_V1_StreamMedicationChangesResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        var outbound0 = Acme_Patientapp_V1_NotifyCareInboxWatchersRequest()
        outbound0.context = input.context
        outbound0.details = Acme_Patientapp_V1_NotifyCareInboxWatchersRequest.Details.with {
            $0.recipient = Acme_Common_V1_ContactInfo.with {
                $0.email = input.context.actor.email
            }
            $0.variables = input.filter.labels
        }
        let reply0 = try await self.patientappCareInboxNotification.notifyCareInboxWatchers(outbound0)
        return Acme_Patientapp_V1_BrowseCareInboxesResponse.with {
            $0.careInboxes = [
                Acme_Patientapp_V1_CareInbox.with {
                    $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                        $0.locality = reply0.careInbox.billingAddress.locality
                    }
                    $0.counterparty = Acme_Patients_V1_PatientRef.with {
                        $0.email = reply0.careInbox.counterparty.email
                    }
                }
            ]
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processCountCareInboxes(_ input: Acme_Patientapp_V1_CountCareInboxesRequest) async throws
        -> Acme_Patientapp_V1_CountCareInboxesResponse
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
            "CountCareInboxes",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "CountCareInboxes", detail: input.context.traceID
        )
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        return Acme_Patientapp_V1_CountCareInboxesResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processExportCareInboxes(_ input: Acme_Patientapp_V1_ExportCareInboxesRequest) async throws
        -> Acme_Patientapp_V1_ExportCareInboxesResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.destinationUri)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "audit", detail: input.destinationUri
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ExportCareInboxes",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "ExportCareInboxes", detail: input.context.traceID
        )
        let outbound0 = Acme_Patients_V1_ReconcileMedicalRecordsRequest.with {
            $0.context = input.context
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.email = input.context.actor.email
                }
            }
        }
        let step0: @Sendable () async throws -> Acme_Patients_V1_ReconcileMedicalRecordsResponse = {
            try await self.patientsMedicalRecordSync.reconcileMedicalRecords(outbound0)
        }
        let reply0 = try await step0()
        let outbound1 = Acme_Patientapp_V1_SubscribePatientHomeUpdatesRequest.with {
            $0.annotations = input.filter.labels
            $0.context = input.context
            $0.details = Acme_Patientapp_V1_SubscribePatientHomeUpdatesRequest.Details.with {
                $0.recipient = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply0.medicalRecord.counterparty.email
                }
            }
        }
        let reply1 = try await self.patientappPatientHomeNotification.subscribePatientHomeUpdates(outbound1)
        let selection2_1: String
        switch reply1.patientHome.origin {
        case .customer(let customer):
            selection2_1 = customer.displayName
        default: selection2_1 = .init()
        }
        let selection2_2: String
        switch reply1.patientHome.origin {
        case .customer(let customer):
            selection2_2 = customer.email
        default: selection2_2 = .init()
        }
        let outbound2 = Acme_Careplans_V1_DelegateCareGoalApprovalRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.displayName = selection2_1
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply0.medicalRecord.audit.createdBy
                }
                $0.customer = Acme_Patients_V1_PatientRef.with {
                    $0.email = selection2_2
                }
            }
            $0.context = input.context
        }
        let reply2 = try await self.careplansCareGoalApproval.delegateCareGoalApproval(outbound2)
        let outbound3 = Acme_Patients_V1_ListMedicalRecordConflictsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Patients_V1_ListMedicalRecordConflictsRequest.Filter.with {
                $0.createdAfter = input.filter.createdAfter
                $0.query = input.filter.query
                $0.region = reply0.medicalRecord.billingAddress.region
            }
        }
        async let remote3 = self.patientsMedicalRecordSync.listMedicalRecordConflicts(outbound3)
        async let persisted3 = store.count(tenant: input.context.tenantID)
        let (reply3, count3) = try await (remote3, persisted3)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count3)])
        return Acme_Patientapp_V1_ExportCareInboxesResponse.with {
            $0.careInbox = Acme_Patientapp_V1_CareInbox.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply0.medicalRecord.audit.etag
                    $0.updatedAt = reply1.patientHome.audit.updatedAt
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.patientID = reply2.careGoal.customer.patientID
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply3.result.correlationID
                $0.referenceIds = reply2.result.referenceIds + reply3.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processFindCareInboxes(_ input: Acme_Patientapp_V1_FindCareInboxesRequest) async throws
        -> Acme_Patientapp_V1_FindCareInboxesResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.query)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "audit", detail: input.filter.query
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "FindCareInboxes",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "FindCareInboxes", detail: input.context.traceID
        )
        let outbound0 = Acme_Patientapp_V1_FindPatientHomesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Patientapp_V1_FindPatientHomesRequest.Filter.with {
                $0.createdAfter = input.filter.createdAfter
                $0.ownerID = input.filter.ownerID
                $0.region = input.filter.region
            }
            $0.page = Acme_Common_V1_PageRequest.with {
                $0.pageSize = input.page.pageSize
            }
        }
        let reply0 = try await self.findCareInboxesStep0.execute(outbound0)
        let outbound1 = Acme_Patientapp_V1_ReplayCareInboxEventsRequest.with {
            $0.context = input.context
            $0.details = Acme_Patientapp_V1_ReplayCareInboxEventsRequest.Details.with {
                $0.messageID = reply0.result.message
            }
        }
        let port1 = RPCOperations.port { (request: Acme_Patientapp_V1_ReplayCareInboxEventsRequest) in
            try await self.patientappCareInboxIntegration.replayCareInboxEvents(request)
        }
        let reply1 = try await port1.execute(outbound1)
        return Acme_Patientapp_V1_FindCareInboxesResponse.with {
            $0.careInboxes = [
                Acme_Patientapp_V1_CareInbox.with {
                    $0.billingAddress = reply1.careInbox.billingAddress
                    $0.counterparty = reply1.careInbox.counterparty
                }
            ]
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply0.result.referenceIds
                $0.status = reply0.result.status
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processLookupCareInbox(_ input: Acme_Patientapp_V1_LookupCareInboxRequest) async throws
        -> Acme_Patientapp_V1_LookupCareInboxResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "LookupCareInbox",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "LookupCareInbox", detail: input.context.traceID
        )
        let outbound0 = Acme_Prescriptions_V1_StreamPrescriptionMetricsRequest.with {
            $0.context = input.context
            $0.subscriber = Acme_Common_V1_ContactInfo.with {
                $0.email = input.context.actor.email
            }
        }
        let reply0 = try await self.prescriptionsPrescriptionReporting.streamPrescriptionMetrics(outbound0) {
            response in
            var latest = Acme_Prescriptions_V1_StreamPrescriptionMetricsResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        _ = reply0
        return Acme_Patientapp_V1_LookupCareInboxResponse.with {
            $0.careInbox = Acme_Patientapp_V1_CareInbox.with {
                $0.careInboxID = input.careInboxID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processPeekCareInbox(_ input: Acme_Patientapp_V1_PeekCareInboxRequest) async throws
        -> Acme_Patientapp_V1_PeekCareInboxResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "PeekCareInbox",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "PeekCareInbox", detail: input.context.traceID
        )
        let outbound0 = Acme_Metrics_V1_BrowseMetricSeriesesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Metrics_V1_BrowseMetricSeriesesRequest.Filter.with {
                $0.createdAfter = input.context.deadline
                $0.ownerID = input.careInboxID
            }
        }
        let reply0 = try await self.peekCareInboxStep0(outbound0)
        return Acme_Patientapp_V1_PeekCareInboxResponse.with {
            $0.careInbox = Acme_Patientapp_V1_CareInbox.with {
                $0.careInboxID = input.careInboxID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply0.result.status
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processResolveCareInboxes(_ input: Acme_Patientapp_V1_ResolveCareInboxesRequest) async throws
        -> Acme_Patientapp_V1_ResolveCareInboxesResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ResolveCareInboxes",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "ResolveCareInboxes", detail: input.context.traceID
        )
        let outbound0 = Acme_Notifications_V1_BatchGetNotificationsRequest.with {
            $0.context = input.context
        }
        guard let execute0 = self.resolveCareInboxesStep0[settings.region] ?? self.resolveCareInboxesStep0["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply0 = try await execute0(outbound0)
        return Acme_Patientapp_V1_ResolveCareInboxesResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.result.message
                $0.status = reply0.result.status
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processSuggestCareInboxes(_ input: Acme_Patientapp_V1_SuggestCareInboxesRequest) async throws
        -> Acme_Patientapp_V1_SuggestCareInboxesResponse
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
            "SuggestCareInboxes",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "SuggestCareInboxes", detail: input.context.traceID
        )
        return Acme_Patientapp_V1_SuggestCareInboxesResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processSummarizeCareInboxes(_ input: Acme_Patientapp_V1_SummarizeCareInboxesRequest) async throws
        -> Acme_Patientapp_V1_SummarizeCareInboxesResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.careInboxID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "audit", detail: input.careInboxID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SummarizeCareInboxes",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_inbox",
            action: "SummarizeCareInboxes", detail: input.context.traceID
        )
        let outbound0 = Acme_Careplans_V1_CancelCareGoalWorkflowRequest.with {
            $0.annotations = input.annotations
            $0.context = input.context
            $0.reason = input.reason
        }
        let reply0 = try await self.careplansCareGoalWorkflow.cancelCareGoalWorkflow(outbound0)
        let outbound1 = Acme_Insurance_V1_BrowsePoliciesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Insurance_V1_BrowsePoliciesRequest.Filter.with {
                $0.createdAfter = reply0.careGoal.audit.createdAt
                $0.ownerID = reply0.careGoal.careGoalID
            }
        }
        let envelope1 = try Google_Protobuf_Any(message: outbound1)
        let unpacked1 = try Acme_Insurance_V1_BrowsePoliciesRequest(unpackingAny: envelope1)
        let reply1 = try await self.insurancePolicyQuery.browsePolicies(unpacked1)
        let outbound2 = Acme_Patients_V1_DelegateMedicalRecordApprovalRequest.with {
            $0.context = input.context
            $0.details = Acme_Patients_V1_DelegateMedicalRecordApprovalRequest.Details.with {
                $0.approver = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply0.careGoal.assignee.displayName
                }
            }
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply0.careGoal.audit.createdBy
                    $0.updatedBy = reply0.careGoal.audit.updatedBy
                }
            }
        }
        let json2 = try outbound2.jsonString()
        let decoded2 = try Acme_Patients_V1_DelegateMedicalRecordApprovalRequest(jsonString: json2)
        let reply2 = try await self.patientsMedicalRecordApproval.delegateMedicalRecordApproval(decoded2)
        let outbound3 =
            Acme_Patientapp_V1_NotifyCareInboxWatchersRequest.forCareInboxQueryEndpointSummarizeCareInboxes3(
                input,
                reply0: reply0,
                reply2: reply2
            )
        let reply3 = try await self.patientappCareInboxNotification.notifyCareInboxWatchers(outbound3)
        return Acme_Patientapp_V1_SummarizeCareInboxesResponse.with {
            $0.period = input.details.period
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.details = reply1.result.details
                $0.message = Projection.firstValue(
                    [
                        reply2.result.message,
                        reply3.outcome.message,
                    ], default: .init())
                $0.status = "ok"
            }
        }
    }
}
