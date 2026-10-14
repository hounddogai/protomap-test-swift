import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension RefillLifecycleEndpoint {
    /// Execute the prescriptions workflow and project its upstream replies.
    func processActivateRefill(_ input: Acme_Prescriptions_V1_ActivateRefillRequest) async throws
        -> Acme_Prescriptions_V1_ActivateRefillResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "audit", detail: input.details.newOwner.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ActivateRefill",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "ActivateRefill", detail: input.context.traceID
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
        let outbound0 =
            Acme_Patients_V1_ExplainMedicalRecordCalculationRequest.forRefillLifecycleEndpointActivateRefill0(
                input
            )
        let reply0 = try await self.patientsMedicalRecordCalculation.explainMedicalRecordCalculation(outbound0)
        let outbound1 = Acme_Ledger_V1_FindLedgerAccountsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Ledger_V1_FindLedgerAccountsRequest.Filter.with {
                $0.createdAfter = reply0.medicalRecord.audit.updatedAt
                $0.ownerID = reply0.medicalRecord.counterparty.patientID
                $0.region = reply0.medicalRecord.billingAddress.region
            }
        }
        let reply1 = try await self.ledgerLedgerAccountQuery.findLedgerAccounts(
            outbound1, metadata: ["x-acme-region": .string(settings.region)]
        )
        return Acme_Prescriptions_V1_ActivateRefillResponse.with {
            $0.outcome = Acme_Prescriptions_V1_ActivateRefillResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
                $0.message = reply1.result.message
                $0.status = reply0.result.status
            }
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.refillID = input.refillID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processExpireRefill(_ input: Acme_Prescriptions_V1_ExpireRefillRequest) async throws
        -> Acme_Prescriptions_V1_ExpireRefillResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "audit", detail: input.details.newOwner.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ExpireRefill",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "ExpireRefill", detail: input.context.traceID
        )
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        let outbound0 = Acme_Careplans_V1_SubmitCareGoalRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.email = input.details.notifyContact.email
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.name = input.details.notifyContact.name
                }
            }
            $0.context = input.context
            $0.details = Acme_Careplans_V1_SubmitCareGoalRequest.Details.with {
                $0.approver = Acme_Identity_V1_UserRef.with {
                    $0.email = input.details.newOwner.email
                    $0.userID = input.details.newOwner.userID
                }
            }
        }
        let reply0 = try await RPCOperations.call(outbound0) { request in
            try await self.careplansCareGoalApproval.submitCareGoal(request)
        }
        return Acme_Prescriptions_V1_ExpireRefillResponse.with {
            $0.outcome = Acme_Prescriptions_V1_ExpireRefillResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
            }
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.email = reply0.careGoal.requester.email
                }
                $0.refillID = input.refillID
                $0.subject = reply0.careGoal.subject
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processGetRefillLifecycle(_ input: Acme_Prescriptions_V1_GetRefillLifecycleRequest) async throws
        -> Acme_Prescriptions_V1_GetRefillLifecycleResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "GetRefillLifecycle",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "GetRefillLifecycle", detail: input.context.traceID
        )
        let outbound0 = Acme_Prescriptions_V1_RetryRefillImportRequest.with {
            $0.context = Projection.read(input, at: \Acme_Prescriptions_V1_GetRefillLifecycleRequest.context)
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.email = Projection.read(
                        input, at: \Acme_Prescriptions_V1_GetRefillLifecycleRequest.context.actor.email)
                    $0.userID = Projection.read(
                        input, at: \Acme_Prescriptions_V1_GetRefillLifecycleRequest.context.actor.userID)
                }
                $0.refillID = Projection.read(input, at: \Acme_Prescriptions_V1_GetRefillLifecycleRequest.refillID)
                $0.sla = Acme_Prescriptions_V1_RefillSla.with {
                    $0.dueAt = Projection.read(
                        input, at: \Acme_Prescriptions_V1_GetRefillLifecycleRequest.context.deadline)
                }
            }
        }
        let reply0 = try await self.prescriptionsRefillImport.retryRefillImport(outbound0)
        return Acme_Prescriptions_V1_GetRefillLifecycleResponse.with {
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.refillID = input.refillID
                $0.sla = Acme_Prescriptions_V1_RefillSla.with {
                    $0.policyID = reply0.refill.sla.policyID
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processReinstateRefill(_ input: Acme_Prescriptions_V1_ReinstateRefillRequest) async throws
        -> Acme_Prescriptions_V1_ReinstateRefillResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "audit", detail: input.details.newOwner.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ReinstateRefill",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "ReinstateRefill", detail: input.context.traceID
        )
        let outbound0 = Acme_Patients_V1_PreviewMedicalRecordRequest.with {
            $0.context = input.context
            $0.details = Acme_Patients_V1_PreviewMedicalRecordRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.notifyContact.email
                }
            }
        }
        let step0: @Sendable () async throws -> Acme_Patients_V1_PreviewMedicalRecordResponse = {
            try await self.patientsMedicalRecordValidation.previewMedicalRecord(outbound0)
        }
        let reply0 = try await step0()
        return Acme_Prescriptions_V1_ReinstateRefillResponse.with {
            $0.outcome = Acme_Prescriptions_V1_ReinstateRefillResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
            }
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.refillID = input.refillID
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply0.medicalRecord.counterparty.email
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processRenewRefill(_ input: Acme_Prescriptions_V1_RenewRefillRequest) async throws
        -> Acme_Prescriptions_V1_RenewRefillResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.notifyContact.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "audit", detail: input.details.notifyContact.email
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "RenewRefill",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "RenewRefill", detail: input.context.traceID
        )
        var outbound0 = Acme_Careplans_V1_CancelVitalWorkflowRequest()
        outbound0.context = input.context
        outbound0.details = Acme_Careplans_V1_CancelVitalWorkflowRequest.Details.with {
            $0.notify = Acme_Common_V1_ContactInfo.with {
                $0.email = input.details.newOwner.email
                $0.preferredChannel = input.details.notifyContact.preferredChannel
            }
        }
        let reply0 = try await self.careplansVitalWorkflow.cancelVitalWorkflow(outbound0)
        let outbound1 = Acme_Patients_V1_ResolvePatientsRequest.with {
            $0.context = input.context
        }
        let reply1 = try await RPCOperations.read {
            try await self.patientsPatientQuery.resolvePatients(outbound1)
        }
        let outbound2 = Acme_Prescriptions_V1_SyncRefillsRequest.with {
            $0.context = input.context
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.details.newOwner.userID
                }
                $0.customer = Acme_Prescriptions_V1_PrescriptionRef.with {
                    $0.displayName = input.details.newOwner.displayName
                }
            }
        }
        let reply2 = try await self.prescriptionsRefillSync.syncRefills(outbound2)
        let outbound3 = Acme_Prescriptions_V1_ExplainMedicationDecisionRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_ExplainMedicationDecisionRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.name = input.details.notifyContact.name
                    $0.preferredChannel = reply2.refill.requester.preferredChannel
                }
            }
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.details.newOwner.displayName
                    $0.email = reply2.refill.assignee.email
                }
            }
        }
        async let remote3 = self.prescriptionsMedicationValidation.explainMedicationDecision(outbound3)
        async let persisted3 = store.count(tenant: input.context.tenantID)
        let (reply3, count3) = try await (remote3, persisted3)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count3)])
        return Acme_Prescriptions_V1_RenewRefillResponse.with {
            $0.outcome = Acme_Prescriptions_V1_RenewRefillResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
                $0.status = reply3.result.status
            }
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.refillID = input.refillID
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply2.refill.requester.email
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply0.result.referenceIds + reply1.result.referenceIds
                $0.status = reply0.outcome.status
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processScheduleRefillExpiry(_ input: Acme_Prescriptions_V1_ScheduleRefillExpiryRequest) async throws
        -> Acme_Prescriptions_V1_ScheduleRefillExpiryResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "audit", detail: input.details.initiatedBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ScheduleRefillExpiry",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try RefillRecord(input.refill, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let requests0 = input.refill.comments.map { element in
            Acme_Careplans_V1_AdvanceVitalWorkflowRequest.with {
                $0.context = input.context
                $0.details = Acme_Careplans_V1_AdvanceVitalWorkflowRequest.Details.with {
                    $0.notify = Acme_Common_V1_ContactInfo.with {
                        $0.email = element.authorEmail
                    }
                }
            }
        }
        let replies0 = try await FanOut.map(requests0) { candidate in
            try await self.careplansVitalWorkflow.advanceVitalWorkflow(candidate)
        }
        let reply0 = replies0.first ?? Acme_Careplans_V1_AdvanceVitalWorkflowResponse()
        _ = reply0
        return Acme_Prescriptions_V1_ScheduleRefillExpiryResponse.with {
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.refillID = input.refillID
                $0.subject = input.refill.subject
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processSuspendRefill(_ input: Acme_Prescriptions_V1_SuspendRefillRequest) async throws
        -> Acme_Prescriptions_V1_SuspendRefillResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "audit", detail: input.details.newOwner.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SuspendRefill",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "SuspendRefill", detail: input.context.traceID
        )
        let outbound0 = Acme_Prescriptions_V1_CancelRefillImportRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_CancelRefillImportRequest.Details.with {
                $0.notifyContact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.notifyContact.email
                    $0.phone = input.details.notifyContact.phone
                }
            }
            $0.refillID = input.refillID
        }
        let reply0 = try await self.suspendRefillStep0.execute(outbound0)
        let outbound1 = Acme_Patients_V1_QuoteMedicalRecordRequest.with {
            $0.context = input.context
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply0.refill.audit.etag
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = reply0.refill.assignee.displayName
                    $0.email = input.details.notifyContact.email
                }
            }
        }
        let port1 = RPCOperations.port { (request: Acme_Patients_V1_QuoteMedicalRecordRequest) in
            try await self.patientsMedicalRecordCalculation.quoteMedicalRecord(request)
        }
        let reply1 = try await port1.execute(outbound1)
        return Acme_Prescriptions_V1_SuspendRefillResponse.with {
            $0.outcome = Acme_Prescriptions_V1_SuspendRefillResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
                $0.status = reply0.outcome.status
            }
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply0.refill.customer.displayName
                }
                $0.comments = [
                    Acme_Prescriptions_V1_RefillComment.with {
                        $0.createdAt = reply1.medicalRecord.audit.createdAt
                    }
                ]
                $0.refillID = input.refillID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply1.result.status
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processTerminateRefill(_ input: Acme_Prescriptions_V1_TerminateRefillRequest) async throws
        -> Acme_Prescriptions_V1_TerminateRefillResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "audit", detail: input.details.newOwner.email
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "TerminateRefill",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "TerminateRefill", detail: input.context.traceID
        )
        let outbound0 = Acme_Search_V1_ScoreSearchIndexRequest.with {
            $0.context = input.context
            $0.searchIndex = Acme_Search_V1_SearchIndex.with {
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.details.newOwner.displayName
                    $0.email = input.details.notifyContact.email
                }
            }
        }
        let reply0 = try await self.terminateRefillStep0(outbound0)
        return Acme_Prescriptions_V1_TerminateRefillResponse.with {
            $0.outcome = Acme_Prescriptions_V1_TerminateRefillResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
            }
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply0.searchIndex.audit.updatedBy
                }
                $0.refillID = input.refillID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }
}
