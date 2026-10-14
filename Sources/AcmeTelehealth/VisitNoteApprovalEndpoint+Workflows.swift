import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension VisitNoteApprovalEndpoint {
    /// Approves a visit note.
    func approveVisitNote(
        request: ServerRequest<Acme_Telehealth_V1_ApproveVisitNoteRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_ApproveVisitNoteResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processApproveVisitNote(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Comments a visit note.
    func commentVisitNoteApproval(
        request: ServerRequest<Acme_Telehealth_V1_CommentVisitNoteApprovalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_CommentVisitNoteApprovalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCommentVisitNoteApproval(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists visit notes a page at a time.
    func listPendingVisitNotes(
        request: ServerRequest<Acme_Telehealth_V1_ListPendingVisitNotesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_ListPendingVisitNotesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListPendingVisitNotes(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Recalls a visit note.
    func recallVisitNote(
        request: ServerRequest<Acme_Telehealth_V1_RecallVisitNoteRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_RecallVisitNoteResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRecallVisitNote(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Rejects a visit note.
    func rejectVisitNote(
        request: ServerRequest<Acme_Telehealth_V1_RejectVisitNoteRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_RejectVisitNoteResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRejectVisitNote(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Submits a visit note.
    func submitVisitNote(
        request: ServerRequest<Acme_Telehealth_V1_SubmitVisitNoteRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_SubmitVisitNoteResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSubmitVisitNote(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processApproveVisitNote(_ input: Acme_Telehealth_V1_ApproveVisitNoteRequest) async throws
        -> Acme_Telehealth_V1_ApproveVisitNoteResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "audit", detail: input.details.approver.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ApproveVisitNote",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VisitNoteRecord(input.visitNote, tenant: input.context.tenantID)
        try await store.save(record.stored)
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        try followUps.submit(
            Acme_Identity_V1_GetUserRequest.with {
                $0.context = input.context
                $0.userID = input.context.actor.userID
            })
        let importFrame = Acme_Careplans_V1_BatchCreateCarePlansRequest.with {
            $0.context = input.context
        }
        _ = try await self.careplansCarePlan.batchCreateCarePlans { writer in
            try await writer.write(importFrame)
        }
        let outbound0 = Acme_Telehealth_V1_CompareVisitNoteOptionsRequest.forVisitNoteApprovalEndpointApproveVisitNote0(
            input
        )
        let reply0 = try await self.telehealthVisitNoteCalculation.compareVisitNoteOptions(outbound0)
        let outbound1 = Acme_Careplans_V1_EscalateCareGoalRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.approver.email
                }
            }
            $0.context = input.context
        }
        let reply1 = try await self.careplansCareGoalApproval.escalateCareGoal(
            outbound1, metadata: ["x-acme-region": .string(settings.region)]
        )
        return Acme_Telehealth_V1_ApproveVisitNoteResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply1.careGoal.audit.etag
                }
                $0.billingAddress = input.visitNote.billingAddress
                $0.counterparty = Projection.updating(reply0.visitNote.counterparty) {
                    $0.displayName = reply1.careGoal.assignee.displayName
                }
                $0.visitNoteID = input.visitNoteID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processCommentVisitNoteApproval(_ input: Acme_Telehealth_V1_CommentVisitNoteApprovalRequest) async throws
        -> Acme_Telehealth_V1_CommentVisitNoteApprovalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "audit", detail: input.details.approver.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "CommentVisitNoteApproval",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VisitNoteRecord(input.visitNote, tenant: input.context.tenantID)
        try await store.save(record.stored)
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        let selection0_1: String
        switch input.visitNote.settlement {
        case .card(let card):
            selection0_1 = card.network
        default: selection0_1 = .init()
        }
        let outbound0 = Acme_Ledger_V1_NormalizeLedgerAccountRequest.with {
            $0.context = input.context
            $0.ledgerAccount = Acme_Ledger_V1_LedgerAccount.with {
                $0.card = Acme_Ledger_V1_LedgerAccountCardFunding.with {
                    $0.network = selection0_1
                }
            }
        }
        let reply0 = try await self.ledgerLedgerAccountValidation.normalizeLedgerAccount(outbound0)
        return Acme_Telehealth_V1_CommentVisitNoteApprovalResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.message = reply0.outcome.message
                $0.status = "ok"
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.billingAddress = input.visitNote.billingAddress
                $0.visitNoteID = input.visitNoteID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processListPendingVisitNotes(_ input: Acme_Telehealth_V1_ListPendingVisitNotesRequest) async throws
        -> Acme_Telehealth_V1_ListPendingVisitNotesResponse
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
            "ListPendingVisitNotes",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "ListPendingVisitNotes", detail: input.context.traceID
        )
        return Acme_Telehealth_V1_ListPendingVisitNotesResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processRecallVisitNote(_ input: Acme_Telehealth_V1_RecallVisitNoteRequest) async throws
        -> Acme_Telehealth_V1_RecallVisitNoteResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.userID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "audit", detail: input.details.approver.userID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "RecallVisitNote",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VisitNoteRecord(input.visitNote, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Careplans_V1_AdvanceVitalWorkflowRequest.with {
            $0.annotations = input.annotations
            $0.context = input.context
            $0.details = Acme_Careplans_V1_AdvanceVitalWorkflowRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.approver.email
                }
            }
            $0.reason = input.reason
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.subject = Acme_Appointments_V1_AppointmentRef.with {
                    $0.displayName = input.details.approver.displayName
                }
            }
        }
        let reply0 = try await RPCOperations.call(outbound0) { request in
            try await self.careplansVitalWorkflow.advanceVitalWorkflow(request)
        }
        let outbound1 = Acme_Telehealth_V1_CalculateTriageRequest.with {
            $0.context = Projection.read(input, at: \Acme_Telehealth_V1_RecallVisitNoteRequest.context)
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.email = Projection.read(
                        input, at: \Acme_Telehealth_V1_RecallVisitNoteRequest.visitNote.counterparty.email)
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = Projection.read(
                        input, at: \Acme_Telehealth_V1_RecallVisitNoteRequest.visitNote.audit.etag)
                }
            }
        }
        let reply1 = try await self.telehealthTriageCalculation.calculateTriage(outbound1)
        let outbound2 = Acme_Patients_V1_LookupPatientRequest.with {
            $0.context = input.context
            $0.patientID = input.visitNote.counterparty.patientID
        }
        let step2: @Sendable () async throws -> Acme_Patients_V1_LookupPatientResponse = {
            try await self.patientsPatientQuery.lookupPatient(outbound2)
        }
        let reply2 = try await step2()
        var outbound3 = Acme_Telehealth_V1_ExplainVisitNoteCalculationRequest()
        outbound3.context = input.context
        outbound3.details = Acme_Telehealth_V1_ExplainVisitNoteCalculationRequest.Details.with {
            $0.contact = Acme_Common_V1_ContactInfo.with {
                $0.preferredChannel = reply2.patient.contact.preferredChannel
            }
        }
        outbound3.visitNote = Acme_Telehealth_V1_VisitNote.with {
            $0.audit = Acme_Common_V1_AuditInfo.with {
                $0.updatedBy = input.visitNote.audit.updatedBy
            }
        }
        let reply3 = try await self.telehealthVisitNoteCalculation.explainVisitNoteCalculation(outbound3)
        return Acme_Telehealth_V1_RecallVisitNoteResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply3.result.referenceIds
                $0.status = "ok"
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply3.visitNote.audit.createdBy
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = reply2.patient.primaryAddress.region
                }
                $0.counterparty = input.visitNote.counterparty
                $0.lines = [
                    Acme_Telehealth_V1_VisitNoteLine.with {
                        $0.attributes = reply0.vital.attributes
                    }
                ]
                $0.total = reply1.breakdown.total
                $0.visitNoteID = input.visitNoteID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processRejectVisitNote(_ input: Acme_Telehealth_V1_RejectVisitNoteRequest) async throws
        -> Acme_Telehealth_V1_RejectVisitNoteResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.userID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "audit", detail: input.details.approver.userID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "RejectVisitNote",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VisitNoteRecord(input.visitNote, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let selection0_1: String
        switch input.visitNote.settlement {
        case .bank(let bank):
            selection0_1 = bank.accountHolder
        default: selection0_1 = .init()
        }
        let outbound0 = Acme_Ledger_V1_ExplainLedgerAccountDecisionRequest.with {
            $0.context = input.context
            $0.details = Acme_Ledger_V1_ExplainLedgerAccountDecisionRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.approver.email
                }
            }
            $0.ledgerAccount = Acme_Ledger_V1_LedgerAccount.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = input.visitNote.audit.etag
                }
                $0.bank = Acme_Ledger_V1_LedgerAccountBankFunding.with {
                    $0.accountHolder = selection0_1
                }
                $0.holder = Acme_Ledger_V1_PostingBatchRef.with {
                    $0.displayName = input.details.approver.displayName
                }
            }
        }
        let reply0 = try await self.ledgerLedgerAccountValidation.explainLedgerAccountDecision(outbound0)
        let requests1 = input.visitNote.lines.map { element in
            Acme_Prescriptions_V1_SimulatePrescriptionRequest.with {
                $0.context = input.context
                $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                    $0.lines = [
                        Acme_Prescriptions_V1_PrescriptionLine.with {
                            $0.attributes = element.attributes
                            $0.tax = Acme_Prescriptions_V1_PrescriptionLineTax.with {
                                $0.amount = element.tax.amount
                                $0.exemptions = element.tax.exemptions
                                $0.rate = element.tax.rate
                            }
                        }
                    ]
                }
            }
        }
        let replies1 = try await FanOut.map(requests1) { candidate in
            try await self.prescriptionsPrescriptionCalculation.simulatePrescription(candidate)
        }
        let reply1 = replies1.first ?? Acme_Prescriptions_V1_SimulatePrescriptionResponse()
        _ = reply1
        return Acme_Telehealth_V1_RejectVisitNoteResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.total = input.visitNote.total
                $0.visitNoteID = input.visitNoteID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processSubmitVisitNote(_ input: Acme_Telehealth_V1_SubmitVisitNoteRequest) async throws
        -> Acme_Telehealth_V1_SubmitVisitNoteResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "audit", detail: input.details.approver.email
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SubmitVisitNote",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VisitNoteRecord(input.visitNote, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Authorization_V1_CountAccessPoliciesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Authorization_V1_CountAccessPoliciesRequest.Filter.with {
                $0.createdAfter = input.visitNote.audit.updatedAt
                $0.ownerID = input.visitNote.counterparty.patientID
                $0.region = input.visitNote.billingAddress.region
            }
        }
        let reply0 = try await RPCOperations.read {
            try await self.authorizationAccessPolicyQuery.countAccessPolicies(outbound0)
        }
        let requests1 = input.visitNote.lines.map { element in
            Acme_Telehealth_V1_CalculateVisitNoteRequest.with {
                $0.context = input.context
                $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                    $0.lines = [
                        Acme_Telehealth_V1_VisitNoteLine.with {
                            $0.attributes = element.attributes
                            $0.lineID = element.lineID
                            $0.tax = Acme_Telehealth_V1_VisitNoteLineTax.with {
                                $0.exemptions = element.tax.exemptions
                            }
                        }
                    ]
                }
            }
        }
        let replies1 = try await FanOut.map(requests1) { candidate in
            try await self.telehealthVisitNoteCalculation.calculateVisitNote(candidate)
        }
        let reply1 = replies1.first ?? Acme_Telehealth_V1_CalculateVisitNoteResponse()
        let outbound2 = Acme_Telehealth_V1_GetVisitNoteRulesRequest.with {
            $0.context = input.context
            $0.visitNoteID = input.visitNoteID
        }
        let reply2 = try await self.telehealthVisitNoteValidation.getVisitNoteRules(outbound2)
        let selection3_1: String
        switch reply1.visitNote.settlement {
        case .bank(let bank):
            selection3_1 = bank.bic
        default: selection3_1 = .init()
        }
        let outbound3 = Acme_Careplans_V1_DelegateCarePlanApprovalRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.bank = Acme_Careplans_V1_CarePlanBankSettlement.with {
                    $0.bic = selection3_1
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = reply1.visitNote.billingAddress.countryCode
                }
                $0.counterparty = Acme_Appointments_V1_AppointmentRef.with {
                    $0.displayName = input.details.approver.displayName
                }
            }
            $0.context = input.context
            $0.details = Acme_Careplans_V1_DelegateCarePlanApprovalRequest.Details.with {
                $0.approver = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.visitNote.counterparty.displayName
                }
            }
        }
        let reply3 = try await self.careplansCarePlanApproval.delegateCarePlanApproval(outbound3)
        return Acme_Telehealth_V1_SubmitVisitNoteResponse.with {
            $0.outcome = Acme_Telehealth_V1_SubmitVisitNoteResponse.Outcome.with {
                $0.referenceID = reply3.outcome.referenceID
                $0.status = reply0.result.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.status = "ok"
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.issuedAt = reply2.visitNote.issuedAt
                $0.status = input.visitNote.status
                $0.visitNoteID = input.visitNoteID
            }
        }
    }
}
