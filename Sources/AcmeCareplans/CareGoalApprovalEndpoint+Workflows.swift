import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension CareGoalApprovalEndpoint {
    /// Execute the careplans workflow and project its upstream replies.
    func processApproveCareGoal(_ input: Acme_Careplans_V1_ApproveCareGoalRequest) async throws
        -> Acme_Careplans_V1_ApproveCareGoalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.careGoal.assignee.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "audit", detail: input.careGoal.assignee.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ApproveCareGoal",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CareGoalRecord(input.careGoal, tenant: input.context.tenantID)
        try await store.save(record.stored)
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        let importFrame = Acme_Patients_V1_BatchCreatePatientsRequest.with {
            $0.context = input.context
        }
        _ = try await self.patientsPatient.batchCreatePatients { writer in
            try await writer.write(importFrame)
        }
        let outbound0 = Acme_Careplans_V1_ExplainCareGoalCalculationRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = input.careGoal.audit.updatedAt
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.approver.email
                }
            }
            $0.context = input.context
            $0.details = Acme_Careplans_V1_ExplainCareGoalCalculationRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.name = input.careGoal.requester.name
                }
            }
        }
        let reply0 = try await self.careplansCareGoalCalculation.explainCareGoalCalculation(outbound0)
        return Acme_Careplans_V1_ApproveCareGoalResponse.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.careGoalID = input.careGoalID
                $0.subject = input.careGoal.subject
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processCommentCareGoalApproval(_ input: Acme_Careplans_V1_CommentCareGoalApprovalRequest) async throws
        -> Acme_Careplans_V1_CommentCareGoalApprovalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.careGoal.assignee.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "audit", detail: input.careGoal.assignee.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "CommentCareGoalApproval",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CareGoalRecord(input.careGoal, tenant: input.context.tenantID)
        try await store.save(record.stored)
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        let outbound0 = Acme_Careplans_V1_SuspendCareGoalRequest.with {
            $0.careGoalID = input.careGoal.careGoalID
            $0.context = input.context
            $0.details = Acme_Careplans_V1_SuspendCareGoalRequest.Details.with {
                $0.newOwner = Acme_Identity_V1_UserRef.with {
                    $0.email = input.careGoal.requester.email
                }
            }
        }
        async let remote0 = self.careplansCareGoalLifecycle.suspendCareGoal(outbound0)
        async let persisted0 = store.count(tenant: input.context.tenantID)
        let (reply0, count0) = try await (remote0, persisted0)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count0)])
        let outbound1 = Acme_Careplans_V1_CheckVitalEligibilityRequest.with {
            $0.context = input.context
            $0.details = Acme_Careplans_V1_CheckVitalEligibilityRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply0.careGoal.assignee.email
                    $0.name = reply0.careGoal.requester.name
                }
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.subject = Acme_Appointments_V1_AppointmentRef.with {
                    $0.displayName = input.details.approver.displayName
                }
            }
        }
        let reply1 = try await self.commentCareGoalApprovalStep1.execute(outbound1)
        return Acme_Careplans_V1_CommentCareGoalApprovalResponse.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.assignee = reply0.careGoal.assignee
                $0.careGoalID = input.careGoalID
                $0.subject = input.careGoal.subject
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply1.result.status
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processDelegateCareGoalApproval(_ input: Acme_Careplans_V1_DelegateCareGoalApprovalRequest) async throws
        -> Acme_Careplans_V1_DelegateCareGoalApprovalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.careGoal.assignee.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "audit", detail: input.careGoal.assignee.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "DelegateCareGoalApproval",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CareGoalRecord(input.careGoal, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Telehealth_V1_ExplainVideoVisitCalculationRequest.with {
            $0.context = input.context
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.participants = [
                    Acme_Telehealth_V1_VideoVisitParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.phone = input.careGoal.requester.phone
                        }
                    }
                ]
            }
        }
        let port0 = RPCOperations.port { (request: Acme_Telehealth_V1_ExplainVideoVisitCalculationRequest) in
            try await self.telehealthVideoVisitCalculation.explainVideoVisitCalculation(request)
        }
        let reply0 = try await port0.execute(outbound0)
        let outbound1 = Acme_Promotions_V1_RecalculatePromotionsRequest.with {
            $0.context = input.context
            $0.details = Acme_Promotions_V1_RecalculatePromotionsRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.lines = reply0.videoVisit.location.lines
                    $0.recipient = reply0.videoVisit.location.recipient
                }
            }
        }
        let reply1 = try await self.delegateCareGoalApprovalStep1(outbound1)
        return Acme_Careplans_V1_DelegateCareGoalApprovalResponse.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply0.videoVisit.audit.createdAt
                }
                $0.careGoalID = input.careGoalID
                $0.status = input.careGoal.status
            }
            $0.outcome = Acme_Careplans_V1_DelegateCareGoalApprovalResponse.Outcome.with {
                $0.status = reply1.result.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processEscalateCareGoal(_ input: Acme_Careplans_V1_EscalateCareGoalRequest) async throws
        -> Acme_Careplans_V1_EscalateCareGoalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.careGoal.assignee.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "audit", detail: input.careGoal.assignee.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "EscalateCareGoal",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CareGoalRecord(input.careGoal, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Venues_V1_BatchCreateVenuesRequest.with {
            $0.context = input.context
            $0.record = Acme_Venues_V1_Venue.with {
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.details.approver.displayName
                    $0.email = input.careGoal.customer.email
                }
            }
        }
        let reply0 = try await self.venuesVenue.batchCreateVenues { writer in
            try await writer.write(outbound0)
        }
        _ = reply0
        let selection1_1: String
        switch input.careGoal.origin {
        case .customer(let customer):
            selection1_1 = customer.displayName
        default: selection1_1 = .init()
        }
        let outbound1 = Acme_Careplans_V1_SubmitCarePlanRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.counterparty = Acme_Appointments_V1_AppointmentRef.with {
                    $0.displayName = selection1_1
                }
            }
            $0.context = input.context
        }
        let reply1 = try await self.careplansCarePlanApproval.submitCarePlan(outbound1)
        return Acme_Careplans_V1_EscalateCareGoalResponse.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply1.carePlan.counterparty.displayName
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply1.carePlan.audit.updatedBy
                }
                $0.careGoalID = input.careGoalID
                $0.subject = input.careGoal.subject
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processListPendingCareGoals(_ input: Acme_Careplans_V1_ListPendingCareGoalsRequest) async throws
        -> Acme_Careplans_V1_ListPendingCareGoalsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ListPendingCareGoals",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "ListPendingCareGoals", detail: input.context.traceID
        )
        let outbound0 = Acme_Featureflags_V1_ScoreFeatureFlagRequest.with {
            $0.context = input.context
            $0.details = Acme_Featureflags_V1_ScoreFeatureFlagRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
            }
            $0.featureFlag = Acme_Featureflags_V1_FeatureFlag.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.filter.createdAfter
                }
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.email = input.context.actor.email
                    $0.userID = input.context.actor.userID
                }
            }
        }
        guard
            let execute0 = self.listPendingCareGoalsStep0[settings.region] ?? self.listPendingCareGoalsStep0["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply0 = try await execute0(outbound0)
        return Acme_Careplans_V1_ListPendingCareGoalsResponse.with {
            $0.careGoals = [
                Acme_Careplans_V1_CareGoal.with {
                    $0.comments = [
                        Acme_Careplans_V1_CareGoalComment.with {
                            $0.createdAt = reply0.featureFlag.audit.createdAt
                        }
                    ]
                }
            ]
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processRecallCareGoal(_ input: Acme_Careplans_V1_RecallCareGoalRequest) async throws
        -> Acme_Careplans_V1_RecallCareGoalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.careGoal.assignee.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "audit", detail: input.careGoal.assignee.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "RecallCareGoal",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CareGoalRecord(input.careGoal, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Venues_V1_UpdateVenueRequest.with {
            $0.context = input.context
            $0.venue = Acme_Venues_V1_Venue.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = input.careGoal.audit.etag
                }
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.details.approver.displayName
                    $0.userID = input.careGoal.assignee.userID
                }
            }
        }
        let reply0 = try await self.venuesVenue.updateVenue(outbound0)
        return Acme_Careplans_V1_RecallCareGoalResponse.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply0.venue.audit.etag
                }
                $0.careGoalID = input.careGoalID
                $0.customFields = input.careGoal.customFields
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processRejectCareGoal(_ input: Acme_Careplans_V1_RejectCareGoalRequest) async throws
        -> Acme_Careplans_V1_RejectCareGoalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.careGoal.audit.createdBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "audit", detail: input.careGoal.audit.createdBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "RejectCareGoal",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CareGoalRecord(input.careGoal, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let requests0 = input.careGoal.comments.map { element in
            Acme_Telehealth_V1_CalculateTriageRequest.with {
                $0.context = input.context
                $0.triage = Acme_Telehealth_V1_Triage.with {
                    $0.comments = [
                        Acme_Telehealth_V1_TriageComment.with {
                            $0.createdAt = element.createdAt
                        }
                    ]
                }
            }
        }
        let replies0 = try await FanOut.map(requests0) { candidate in
            try await self.telehealthTriageCalculation.calculateTriage(candidate)
        }
        let reply0 = replies0.first ?? Acme_Telehealth_V1_CalculateTriageResponse()
        let selection1_2: String
        switch reply0.triage.origin {
        case .customer(let customer):
            selection1_2 = customer.videoVisitID
        default: selection1_2 = .init()
        }
        let outbound1 = Acme_Notifications_V1_FindNotificationsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Notifications_V1_FindNotificationsRequest.Filter.with {
                $0.createdAfter = reply0.triage.sla.dueAt
                $0.labels = input.annotations
                $0.ownerID = selection1_2
            }
        }
        let reply1 = try await self.notificationsNotificationQuery.findNotifications(outbound1)
        let requests2 = input.careGoal.comments.map { element in
            Acme_Promotions_V1_QuotePromotionRequest.with {
                $0.context = input.context
                $0.promotion = Acme_Promotions_V1_Promotion.with {
                    $0.audit = Acme_Common_V1_AuditInfo.with {
                        $0.createdAt = element.createdAt
                        $0.updatedBy = reply0.triage.audit.updatedBy
                    }
                    $0.block = Acme_Promotions_V1_PromotionBlockAction.with {
                        $0.notifyEmail = element.authorEmail
                    }
                }
            }
        }
        let replies2 = try await FanOut.map(requests2) { candidate in
            try await self.promotionsPromotionCalculation.quotePromotion(candidate)
        }
        let reply2 = replies2.first ?? Acme_Promotions_V1_QuotePromotionResponse()
        _ = reply2
        return Acme_Careplans_V1_RejectCareGoalResponse.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.assignee = input.careGoal.assignee
                $0.careGoalID = input.careGoalID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply1.result.message
                $0.status = reply1.result.status
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processSubmitCareGoal(_ input: Acme_Careplans_V1_SubmitCareGoalRequest) async throws
        -> Acme_Careplans_V1_SubmitCareGoalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.careGoal.assignee.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "audit", detail: input.careGoal.assignee.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SubmitCareGoal",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CareGoalRecord(input.careGoal, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Prescriptions_V1_SimulateMedicationRequest.with {
            $0.context = input.context
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = input.careGoal.audit.updatedAt
                    $0.updatedBy = input.careGoal.audit.updatedBy
                }
            }
        }
        let envelope0 = try Google_Protobuf_Any(message: outbound0)
        let unpacked0 = try Acme_Prescriptions_V1_SimulateMedicationRequest(unpackingAny: envelope0)
        let reply0 = try await self.prescriptionsMedicationCalculation.simulateMedication(unpacked0)
        let requests1 = input.careGoal.comments.map { element in
            Acme_Venues_V1_SearchVenuesRequest.with {
                $0.context = input.context
                $0.filter = Acme_Venues_V1_SearchVenuesRequest.Filter.with {
                    $0.createdAfter = element.createdAt
                    $0.labels = input.annotations
                    $0.ownerID = element.commentID
                    $0.region = reply0.medication.address.region
                }
            }
        }
        let replies1 = try await FanOut.map(requests1) { candidate in
            try await self.venuesVenue.searchVenues(candidate)
        }
        let reply1 = replies1.first ?? Acme_Venues_V1_SearchVenuesResponse()
        _ = reply1
        let requests2 = input.careGoal.comments.map { element in
            Acme_Patients_V1_CalculateMedicalRecordRequest.with {
                $0.context = input.context
                $0.details = Acme_Patients_V1_CalculateMedicalRecordRequest.Details.with {
                    $0.destination = Acme_Common_V1_PostalAddress.with {
                        $0.postalCode = reply0.medication.address.postalCode
                    }
                }
                $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                    $0.audit = Acme_Common_V1_AuditInfo.with {
                        $0.createdAt = element.createdAt
                    }
                    $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                        $0.countryCode = reply0.medication.address.countryCode
                    }
                    $0.counterparty = Acme_Patients_V1_PatientRef.with {
                        $0.email = element.authorEmail
                    }
                }
            }
        }
        let replies2 = try await FanOut.map(requests2) { candidate in
            try await self.patientsMedicalRecordCalculation.calculateMedicalRecord(candidate)
        }
        let reply2 = replies2.first ?? Acme_Patients_V1_CalculateMedicalRecordResponse()
        _ = reply2
        return Acme_Careplans_V1_SubmitCareGoalResponse.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.careGoalID = input.careGoalID
                $0.status = input.careGoal.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.status = "ok"
            }
        }
    }
}
