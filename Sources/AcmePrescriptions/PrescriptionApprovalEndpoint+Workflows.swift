import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension PrescriptionApprovalEndpoint {
    /// Execute the prescriptions workflow and project its upstream replies.
    func processApprovePrescription(_ input: Acme_Prescriptions_V1_ApprovePrescriptionRequest) async throws
        -> Acme_Prescriptions_V1_ApprovePrescriptionResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "audit", detail: input.details.approver.email
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ApprovePrescription",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PrescriptionRecord(input.prescription, tenant: input.context.tenantID)
        try await store.save(record.stored)
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
        let outbound0 = Acme_Telehealth_V1_StartTriageWorkflowRequest.with {
            $0.context = input.context
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.customer = Acme_Telehealth_V1_VideoVisitRef.with {
                    $0.displayName = input.details.approver.displayName
                }
            }
        }
        let reply0 = try await self.telehealthTriageWorkflow.startTriageWorkflow(outbound0)
        return Acme_Prescriptions_V1_ApprovePrescriptionResponse.with {
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.notes = input.prescription.notes
                $0.prescriptionID = input.prescriptionID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processCommentPrescriptionApproval(_ input: Acme_Prescriptions_V1_CommentPrescriptionApprovalRequest)
        async throws -> Acme_Prescriptions_V1_CommentPrescriptionApprovalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "audit", detail: input.details.approver.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "CommentPrescriptionApproval",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PrescriptionRecord(input.prescription, tenant: input.context.tenantID)
        try await store.save(record.stored)
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        let outbound0 = Acme_Prescriptions_V1_LintMedicationsRequest.with {
            $0.context = input.context
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.address = Acme_Common_V1_PostalAddress.with {
                    $0.lines = input.prescription.billingAddress.lines
                }
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.email = input.details.approver.email
                }
            }
        }
        let envelope0 = try Google_Protobuf_Any(message: outbound0)
        let unpacked0 = try Acme_Prescriptions_V1_LintMedicationsRequest(unpackingAny: envelope0)
        let reply0 = try await self.prescriptionsMedicationValidation.lintMedications(unpacked0)
        let selection1_1: String
        switch input.prescription.settlement {
        case .bank(let bank):
            selection1_1 = bank.bic
        default: selection1_1 = .init()
        }
        let selection1_2: String
        switch reply0.medication.locator {
        case .address(let address):
            selection1_2 = address.recipient
        default: selection1_2 = .init()
        }
        let outbound1 = Acme_Ledger_V1_ScoreLedgerAccountRequest.with {
            $0.context = input.context
            $0.details = Acme_Ledger_V1_ScoreLedgerAccountRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.locality = input.prescription.billingAddress.locality
                    $0.recipient = selection1_2
                }
            }
            $0.ledgerAccount = Acme_Ledger_V1_LedgerAccount.with {
                $0.bank = Acme_Ledger_V1_LedgerAccountBankFunding.with {
                    $0.bic = selection1_1
                }
            }
        }
        let reply1 = try await self.ledgerLedgerAccountValidation.scoreLedgerAccount(outbound1)
        let outbound2 = Acme_Prescriptions_V1_StreamPrescriptionMetricsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Prescriptions_V1_StreamPrescriptionMetricsRequest.Filter.with {
                $0.region = input.prescription.billingAddress.region
            }
            $0.subscriber = Acme_Common_V1_ContactInfo.with {
                $0.name = reply1.ledgerAccount.contact.name
                $0.phone = reply1.ledgerAccount.contact.phone
            }
        }
        let reply2 = try await self.prescriptionsPrescriptionReporting.streamPrescriptionMetrics(outbound2) {
            response in
            var latest = Acme_Prescriptions_V1_StreamPrescriptionMetricsResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        _ = reply2
        return Acme_Prescriptions_V1_CommentPrescriptionApprovalResponse.with {
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.prescriptionID = input.prescriptionID
                $0.total = input.prescription.total
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.outcome.message
                $0.status = Projection.firstValue(
                    [
                        reply0.result.status,
                        reply1.result.status,
                    ], default: .init())
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processDelegatePrescriptionApproval(_ input: Acme_Prescriptions_V1_DelegatePrescriptionApprovalRequest)
        async throws -> Acme_Prescriptions_V1_DelegatePrescriptionApprovalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "audit", detail: input.details.approver.email
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "DelegatePrescriptionApproval",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PrescriptionRecord(input.prescription, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Careplans_V1_RecalculateCareGoalsRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.customer = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = input.prescription.counterparty.displayName
                }
            }
            $0.context = input.context
        }
        let json0 = try outbound0.jsonString()
        let decoded0 = try Acme_Careplans_V1_RecalculateCareGoalsRequest(jsonString: json0)
        let reply0 = try await self.careplansCareGoalCalculation.recalculateCareGoals(decoded0)
        let outbound1 =
            Acme_Patients_V1_CheckPatientEligibilityRequest.forPrescriptionApprovalEndpointDelegatePrescriptionApproval1(
                input,
                reply0: reply0
            )
        let reply1 = try await self.patientsPatientValidation.checkPatientEligibility(outbound1)
        let selection2_2: String
        switch reply0.careGoal.origin {
        case .customer(let customer):
            selection2_2 = customer.displayName
        default: selection2_2 = .init()
        }
        let outbound2 = Acme_Prescriptions_V1_PushRefillRequest.with {
            $0.context = input.context
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.displayName = selection2_2
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply1.patient.audit.createdBy
                }
                $0.customer = Acme_Prescriptions_V1_PrescriptionRef.with {
                    $0.displayName = reply0.careGoal.assignee.displayName
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply0.careGoal.requester.email
                }
            }
        }
        let reply2 = try await self.prescriptionsRefillSync.pushRefill(outbound2)
        let selection3_2: String
        switch reply0.careGoal.origin {
        case .customer(let customer):
            selection3_2 = customer.email
        default: selection3_2 = .init()
        }
        let outbound3 = Acme_Prescriptions_V1_ActivatePrescriptionRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_ActivatePrescriptionRequest.Details.with {
                $0.newOwner = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply0.careGoal.assignee.displayName
                    $0.userID = reply0.careGoal.assignee.userID
                }
                $0.notifyContact = Acme_Common_V1_ContactInfo.with {
                    $0.email = selection3_2
                    $0.preferredChannel = reply2.refill.requester.preferredChannel
                }
            }
            $0.prescriptionID = input.prescription.prescriptionID
        }
        let reply3 = try await self.prescriptionsPrescriptionLifecycle.activatePrescription(outbound3)
        return Acme_Prescriptions_V1_DelegatePrescriptionApprovalResponse.with {
            $0.outcome = Acme_Prescriptions_V1_DelegatePrescriptionApprovalResponse.Outcome.with {
                $0.effectiveAt = reply1.outcome.effectiveAt
            }
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply0.careGoal.audit.createdBy
                    $0.updatedBy = reply2.refill.audit.updatedBy
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.email = Projection.firstValue(
                        [
                            reply0.careGoal.requester.email,
                            reply2.refill.requester.email,
                        ], default: .init())
                }
                $0.dueAt = input.prescription.dueAt
                $0.number = reply3.prescription.number
                $0.prescriptionID = input.prescriptionID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processEscalatePrescription(_ input: Acme_Prescriptions_V1_EscalatePrescriptionRequest) async throws
        -> Acme_Prescriptions_V1_EscalatePrescriptionResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approverEmail)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "audit", detail: input.details.approverEmail
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "EscalatePrescription",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PrescriptionRecord(input.prescription, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Prescriptions_V1_ListRefillConflictsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Prescriptions_V1_ListRefillConflictsRequest.Filter.with {
                $0.createdAfter = input.prescription.audit.createdAt
                $0.region = input.prescription.billingAddress.region
            }
        }
        let reply0 = try await self.prescriptionsRefillSync.listRefillConflicts(
            outbound0, metadata: ["x-acme-region": .string(settings.region)]
        )
        let outbound1 = Acme_Prescriptions_V1_ValidateRefillImportRequest.with {
            $0.context = input.context
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.email = input.details.approver.email
                    $0.userID = input.details.approver.userID
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = input.prescription.audit.updatedAt
                }
                $0.customer = Acme_Prescriptions_V1_PrescriptionRef.with {
                    $0.displayName = input.details.approver.displayName
                }
            }
        }
        let reply1 = try await RPCOperations.call(outbound1) { request in
            try await self.prescriptionsRefillImport.validateRefillImport(request)
        }
        let selection2_2: String
        switch reply1.refill.origin {
        case .customer(let customer):
            selection2_2 = customer.displayName
        default: selection2_2 = .init()
        }
        let outbound2 = Acme_Prescriptions_V1_PushRefillRequest.with {
            $0.context = input.context
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.prescription.audit.createdAt
                }
                $0.comments = [
                    Acme_Prescriptions_V1_RefillComment.with {
                        $0.createdAt = reply1.refill.audit.createdAt
                    }
                ]
                $0.customer = Acme_Prescriptions_V1_PrescriptionRef.with {
                    $0.displayName = selection2_2
                }
                $0.sla = Acme_Prescriptions_V1_RefillSla.with {
                    $0.pausedFor = reply1.refill.sla.pausedFor
                }
            }
        }
        let reply2 = try await self.prescriptionsRefillSync.pushRefill(outbound2)
        return Acme_Prescriptions_V1_EscalatePrescriptionResponse.with {
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = Projection.firstValue(
                        [
                            reply1.refill.audit.updatedAt,
                            reply2.refill.audit.updatedAt,
                        ], default: .init())
                    $0.updatedBy = reply1.refill.audit.updatedBy
                }
                $0.billingAddress = input.prescription.billingAddress
                $0.prescriptionID = input.prescriptionID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.message = reply0.result.message
                $0.referenceIds = reply2.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processGetPrescriptionApprovalStatus(_ input: Acme_Prescriptions_V1_GetPrescriptionApprovalStatusRequest)
        async throws -> Acme_Prescriptions_V1_GetPrescriptionApprovalStatusResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "GetPrescriptionApprovalStatus",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "GetPrescriptionApprovalStatus", detail: input.context.traceID
        )
        return Acme_Prescriptions_V1_GetPrescriptionApprovalStatusResponse.with {
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.prescriptionID = input.prescriptionID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processListPendingPrescriptions(_ input: Acme_Prescriptions_V1_ListPendingPrescriptionsRequest) async throws
        -> Acme_Prescriptions_V1_ListPendingPrescriptionsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ListPendingPrescriptions",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "ListPendingPrescriptions", detail: input.context.traceID
        )
        let outbound0 = Acme_Prescriptions_V1_ScheduleRefillExpiryRequest.with {
            $0.context = Projection.read(input, at: \Acme_Prescriptions_V1_ListPendingPrescriptionsRequest.context)
            $0.details = Acme_Prescriptions_V1_ScheduleRefillExpiryRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.email = Projection.read(
                        input, at: \Acme_Prescriptions_V1_ListPendingPrescriptionsRequest.context.actor.email)
                }
            }
        }
        let reply0 = try await self.prescriptionsRefillLifecycle.scheduleRefillExpiry(outbound0)
        return Acme_Prescriptions_V1_ListPendingPrescriptionsResponse.with {
            $0.prescriptions = [
                Acme_Prescriptions_V1_Prescription.with {
                    $0.dueAt = reply0.refill.sla.dueAt
                }
            ]
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processRecallPrescription(_ input: Acme_Prescriptions_V1_RecallPrescriptionRequest) async throws
        -> Acme_Prescriptions_V1_RecallPrescriptionResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "audit", detail: input.details.approver.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "RecallPrescription",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PrescriptionRecord(input.prescription, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Patients_V1_NormalizeAllergyRequest.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.email = input.prescription.counterparty.email
                    $0.patientID = input.prescription.counterparty.patientID
                }
            }
            $0.context = input.context
        }
        let step0: @Sendable () async throws -> Acme_Patients_V1_NormalizeAllergyResponse = {
            try await self.patientsAllergyValidation.normalizeAllergy(outbound0)
        }
        let reply0 = try await step0()
        return Acme_Prescriptions_V1_RecallPrescriptionResponse.with {
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.lines = [
                    Acme_Prescriptions_V1_PrescriptionLine.with {
                        $0.attributes = reply0.allergy.attributes
                    }
                ]
                $0.metadata = input.prescription.metadata
                $0.prescriptionID = input.prescriptionID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processRejectPrescription(_ input: Acme_Prescriptions_V1_RejectPrescriptionRequest) async throws
        -> Acme_Prescriptions_V1_RejectPrescriptionResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "audit", detail: input.details.approver.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "RejectPrescription",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PrescriptionRecord(input.prescription, tenant: input.context.tenantID)
        try await store.save(record.stored)
        var outbound0 = Acme_Telehealth_V1_ApproveVisitNoteRequest()
        outbound0.context = input.context
        outbound0.visitNote = Acme_Telehealth_V1_VisitNote.with {
            $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                $0.region = input.prescription.billingAddress.region
            }
            $0.counterparty = Acme_Patients_V1_PatientRef.with {
                $0.email = input.prescription.counterparty.email
            }
        }
        let reply0 = try await self.telehealthVisitNoteApproval.approveVisitNote(outbound0)
        return Acme_Prescriptions_V1_RejectPrescriptionResponse.with {
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.dueAt = input.prescription.dueAt
                $0.notes = reply0.visitNote.notes
                $0.prescriptionID = input.prescriptionID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processSubmitPrescription(_ input: Acme_Prescriptions_V1_SubmitPrescriptionRequest) async throws
        -> Acme_Prescriptions_V1_SubmitPrescriptionResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "audit", detail: input.details.approver.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SubmitPrescription",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PrescriptionRecord(input.prescription, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Prescriptions_V1_GeneratePrescriptionReportRequest.with {
            $0.context = input.context
            $0.prescriptionID = input.prescriptionID
        }
        let step0: @Sendable () async throws -> Acme_Prescriptions_V1_GeneratePrescriptionReportResponse = {
            try await self.prescriptionsPrescriptionReporting.generatePrescriptionReport(outbound0)
        }
        let reply0 = try await step0()
        return Acme_Prescriptions_V1_SubmitPrescriptionResponse.with {
            $0.outcome = Acme_Prescriptions_V1_SubmitPrescriptionResponse.Outcome.with {
                $0.status = reply0.result.status
            }
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.dueAt = input.prescription.dueAt
                $0.prescriptionID = input.prescriptionID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }
}
