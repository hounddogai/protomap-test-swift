import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension CarePlanApprovalEndpoint {
    /// Execute the careplans workflow and project its upstream replies.
    func processApproveCarePlan(_ input: Acme_Careplans_V1_ApproveCarePlanRequest) async throws
        -> Acme_Careplans_V1_ApproveCarePlanResponse
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
            "ApproveCarePlan",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CarePlanRecord(input.carePlan, tenant: input.context.tenantID)
        try await store.save(record.stored)
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        let importFrame = Acme_Telehealth_V1_BatchCreateVideoVisitsRequest.with {
            $0.context = input.context
        }
        _ = try await self.telehealthVideoVisit.batchCreateVideoVisits { writer in
            try await writer.write(importFrame)
        }
        let outbound0 = Acme_Appointments_V1_ExportProvidersRequest.with {
            $0.context = input.context
            $0.filter = Acme_Appointments_V1_ExportProvidersRequest.Filter.with {
                $0.createdAfter = input.carePlan.audit.createdAt
                $0.ownerID = input.carePlan.carePlanID
                $0.region = input.carePlan.billingAddress.region
            }
        }
        let reply0 = try await self.appointmentsProviderQuery.exportProviders(outbound0) { response in
            var latest = Acme_Appointments_V1_ExportProvidersResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        _ = reply0
        return Acme_Careplans_V1_ApproveCarePlanResponse.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.carePlanID = input.carePlanID
                $0.status = input.carePlan.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processCommentCarePlanApproval(_ input: Acme_Careplans_V1_CommentCarePlanApprovalRequest) async throws
        -> Acme_Careplans_V1_CommentCarePlanApprovalResponse
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
            "CommentCarePlanApproval",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CarePlanRecord(input.carePlan, tenant: input.context.tenantID)
        try await store.save(record.stored)
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        let outbound0 = Acme_Shipping_V1_UpdateShipmentRequest.with {
            $0.context = input.context
            $0.shipment = Acme_Shipping_V1_Shipment.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.lines = input.carePlan.billingAddress.lines
                }
            }
        }
        let envelope0 = try Google_Protobuf_Any(message: outbound0)
        let unpacked0 = try Acme_Shipping_V1_UpdateShipmentRequest(unpackingAny: envelope0)
        let reply0 = try await self.shippingShipment.updateShipment(unpacked0)
        let requests1 = input.carePlan.attachments.map { element in
            Acme_Prescriptions_V1_ScorePrescriptionRequest.with {
                $0.context = input.context
                $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                    $0.attachments = [
                        Acme_Prescriptions_V1_PrescriptionAttachment.with {
                            $0.fileName = element.fileName
                            $0.uri = element.uri
                        }
                    ]
                }
            }
        }
        let replies1 = try await FanOut.map(requests1) { candidate in
            try await self.prescriptionsPrescriptionValidation.scorePrescription(candidate)
        }
        let reply1 = replies1.first ?? Acme_Prescriptions_V1_ScorePrescriptionResponse()
        let outbound2 = Acme_Careplans_V1_RecalculateCareGoalsRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply1.prescription.audit.etag
                }
                $0.customer = Acme_Patients_V1_PatientRef.with {
                    $0.patientID = reply1.prescription.counterparty.patientID
                }
            }
            $0.context = input.context
            $0.details = Acme_Careplans_V1_RecalculateCareGoalsRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = reply0.shipment.billingAddress.postalCode
                }
            }
        }
        let json2 = try outbound2.jsonString()
        let decoded2 = try Acme_Careplans_V1_RecalculateCareGoalsRequest(jsonString: json2)
        let reply2 = try await self.careplansCareGoalCalculation.recalculateCareGoals(decoded2)
        let outbound3 = Acme_Telehealth_V1_QuoteVisitNoteRequest.forCarePlanApprovalEndpointCommentCarePlanApproval3(
            input,
            reply1: reply1,
            reply2: reply2
        )
        let reply3 = try await self.telehealthVisitNoteCalculation.quoteVisitNote(outbound3)
        return Acme_Careplans_V1_CommentCarePlanApprovalResponse.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply3.visitNote.audit.createdBy
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = reply0.shipment.billingAddress.countryCode
                }
                $0.carePlanID = input.carePlanID
                $0.dueAt = reply2.careGoal.sla.dueAt
                $0.status = input.carePlan.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processDelegateCarePlanApproval(_ input: Acme_Careplans_V1_DelegateCarePlanApprovalRequest) async throws
        -> Acme_Careplans_V1_DelegateCarePlanApprovalResponse
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
            "DelegateCarePlanApproval",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CarePlanRecord(input.carePlan, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Telehealth_V1_EstimateVideoVisitRequest.with {
            $0.context = input.context
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.carePlan.counterparty.displayName
                }
                $0.participants = [
                    Acme_Telehealth_V1_VideoVisitParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = input.details.approver.email
                        }
                    }
                ]
            }
        }
        let reply0 = try await self.telehealthVideoVisitCalculation.estimateVideoVisit(
            outbound0, metadata: ["x-acme-region": .string(settings.region)]
        )
        let outbound1 = Acme_Metrics_V1_ValidateMetricSeriesRequest.with {
            $0.context = input.context
            $0.metricSeries = Acme_Metrics_V1_MetricSeries.with {
                $0.address = Acme_Common_V1_PostalAddress.with {
                    $0.locality = reply0.videoVisit.location.locality
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply0.videoVisit.audit.updatedBy
                }
            }
        }
        let reply1 = try await RPCOperations.call(outbound1) { request in
            try await self.metricsMetricSeriesValidation.validateMetricSeries(request)
        }
        let outbound2 = Acme_Patients_V1_LintAllergiesRequest.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = Projection.read(
                        reply1, at: \Acme_Metrics_V1_ValidateMetricSeriesResponse.metricSeries.owner.displayName)
                }
            }
            $0.context = Projection.read(input, at: \Acme_Careplans_V1_DelegateCarePlanApprovalRequest.context)
        }
        let reply2 = try await self.patientsAllergyValidation.lintAllergies(outbound2)
        let selection3_2: [String]
        switch reply1.metricSeries.locator {
        case .address(let address):
            selection3_2 = address.lines
        default: selection3_2 = .init()
        }
        let outbound3 = Acme_Careplans_V1_EstimateCareGoalRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply2.allergy.subject.email
                }
            }
            $0.context = input.context
            $0.details = Acme_Careplans_V1_EstimateCareGoalRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.lines = selection3_2
                }
            }
        }
        let reply3 = try await self.careplansCareGoalCalculation.estimateCareGoal(outbound3)
        return Acme_Careplans_V1_DelegateCarePlanApprovalResponse.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply3.careGoal.audit.updatedBy
                }
                $0.carePlanID = input.carePlanID
                $0.counterparty = Acme_Appointments_V1_AppointmentRef.with {
                    $0.displayName = reply3.careGoal.assignee.displayName
                }
                $0.metadata = input.carePlan.metadata
            }
            $0.outcome = Acme_Careplans_V1_DelegateCarePlanApprovalResponse.Outcome.with {
                $0.message = reply0.result.message
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply1.result.details
                $0.message = reply2.outcome.message
                $0.referenceIds = reply1.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processGetCarePlanApprovalStatus(_ input: Acme_Careplans_V1_GetCarePlanApprovalStatusRequest) async throws
        -> Acme_Careplans_V1_GetCarePlanApprovalStatusResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "GetCarePlanApprovalStatus",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "GetCarePlanApprovalStatus", detail: input.context.traceID
        )
        let outbound0 = Acme_Careplans_V1_ExplainCareGoalDecisionRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.email = input.context.actor.email
                    $0.userID = input.context.actor.userID
                }
            }
            $0.context = input.context
            $0.details = Acme_Careplans_V1_ExplainCareGoalDecisionRequest.Details.with {
                $0.locale = input.context.locale
            }
        }
        let step0: @Sendable () async throws -> Acme_Careplans_V1_ExplainCareGoalDecisionResponse = {
            try await self.careplansCareGoalValidation.explainCareGoalDecision(outbound0)
        }
        let reply0 = try await step0()
        var outbound1 = Acme_Careplans_V1_QuoteCareGoalRequest()
        outbound1.careGoal = Acme_Careplans_V1_CareGoal.with {
            $0.assignee = Acme_Identity_V1_UserRef.with {
                $0.displayName = reply0.careGoal.assignee.displayName
                $0.userID = reply0.careGoal.assignee.userID
            }
            $0.audit = Acme_Common_V1_AuditInfo.with {
                $0.etag = reply0.careGoal.audit.etag
                $0.updatedAt = reply0.careGoal.audit.updatedAt
            }
        }
        outbound1.context = input.context
        let reply1 = try await self.careplansCareGoalCalculation.quoteCareGoal(outbound1)
        return Acme_Careplans_V1_GetCarePlanApprovalStatusResponse.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply1.careGoal.audit.createdBy
                    $0.etag = reply0.careGoal.audit.etag
                }
                $0.carePlanID = input.carePlanID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processListPendingCarePlans(_ input: Acme_Careplans_V1_ListPendingCarePlansRequest) async throws
        -> Acme_Careplans_V1_ListPendingCarePlansResponse
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
            "ListPendingCarePlans",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "ListPendingCarePlans", detail: input.context.traceID
        )
        let outbound0 = Acme_Careplans_V1_CloneCarePlanRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.filter.createdAfter
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
                $0.lines = [
                    Acme_Careplans_V1_CarePlanLine.with {
                        $0.attributes = input.filter.labels
                    }
                ]
            }
            $0.context = input.context
        }
        let step0: @Sendable () async throws -> Acme_Careplans_V1_CloneCarePlanResponse = {
            try await self.careplansCarePlan.cloneCarePlan(outbound0)
        }
        let reply0 = try await step0()
        return Acme_Careplans_V1_ListPendingCarePlansResponse.with {
            $0.carePlans = [
                Acme_Careplans_V1_CarePlan.with {
                    $0.billingAddress = reply0.carePlan.billingAddress
                    $0.status = reply0.carePlan.status
                }
            ]
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processRejectCarePlan(_ input: Acme_Careplans_V1_RejectCarePlanRequest) async throws
        -> Acme_Careplans_V1_RejectCarePlanResponse
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
            "RejectCarePlan",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CarePlanRecord(input.carePlan, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Patients_V1_PreviewAllergyRequest.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = input.details.approver.displayName
                    $0.email = input.details.approverEmail
                }
            }
            $0.annotations = input.annotations
            $0.context = input.context
            $0.details = Acme_Patients_V1_PreviewAllergyRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.approver.email
                }
            }
        }
        let reply0 = try await self.patientsAllergyValidation.previewAllergy(outbound0)
        let outbound1 = Acme_Careplans_V1_RenewCarePlanRequest.with {
            $0.carePlanID = input.carePlanID
            $0.context = input.context
            $0.details = Acme_Careplans_V1_RenewCarePlanRequest.Details.with {
                $0.newOwner = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.details.approver.displayName
                    $0.email = reply0.allergy.subject.email
                }
                $0.notifyContact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.approver.email
                }
            }
        }
        async let remote1 = self.careplansCarePlanLifecycle.renewCarePlan(outbound1)
        async let persisted1 = store.count(tenant: input.context.tenantID)
        let (reply1, count1) = try await (remote1, persisted1)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count1)])
        return Acme_Careplans_V1_RejectCarePlanResponse.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.lines = reply1.carePlan.billingAddress.lines
                }
                $0.carePlanID = input.carePlanID
                $0.notes = input.carePlan.notes
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.outcome.message
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processSubmitCarePlan(_ input: Acme_Careplans_V1_SubmitCarePlanRequest) async throws
        -> Acme_Careplans_V1_SubmitCarePlanResponse
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
            "SubmitCarePlan",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CarePlanRecord(input.carePlan, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Careplans_V1_ResolveCareGoalsRequest.with {
            $0.context = input.context
        }
        let reply0 = try await self.submitCarePlanStep0.execute(outbound0)
        let selection1_2: String
        switch input.carePlan.settlement {
        case .card(let card):
            selection1_2 = card.last4
        default: selection1_2 = .init()
        }
        let outbound1 = Acme_Careplans_V1_QuoteCarePlanRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = input.carePlan.billingAddress.countryCode
                }
                $0.card = Acme_Careplans_V1_CarePlanCardSettlement.with {
                    $0.last4 = selection1_2
                }
                $0.counterparty = Acme_Appointments_V1_AppointmentRef.with {
                    $0.displayName = input.carePlan.counterparty.displayName
                }
            }
            $0.context = input.context
        }
        let reply1 = try await self.careplansCarePlanCalculation.quoteCarePlan(outbound1)
        return Acme_Careplans_V1_SubmitCarePlanResponse.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = reply1.carePlan.billingAddress.region
                }
                $0.carePlanID = input.carePlanID
                $0.number = input.carePlan.number
            }
            $0.outcome = Acme_Careplans_V1_SubmitCarePlanResponse.Outcome.with {
                $0.message = reply0.result.message
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.status = "ok"
            }
        }
    }
}
