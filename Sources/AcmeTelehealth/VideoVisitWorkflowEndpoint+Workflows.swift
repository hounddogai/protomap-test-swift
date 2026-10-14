import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension VideoVisitWorkflowEndpoint {
    /// Execute the telehealth workflow and project its upstream replies.
    func processAdvanceVideoVisitWorkflow(_ input: Acme_Telehealth_V1_AdvanceVideoVisitWorkflowRequest) async throws
        -> Acme_Telehealth_V1_AdvanceVideoVisitWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "audit", detail: input.details.initiatedBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "AdvanceVideoVisitWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VideoVisitRecord(input.videoVisit, tenant: input.context.tenantID)
        try await store.save(record.stored)
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        let importFrame = Acme_Telehealth_V1_BatchCreateVideoVisitsRequest.with {
            $0.context = input.context
        }
        _ = try await self.telehealthVideoVisit.batchCreateVideoVisits { writer in
            try await writer.write(importFrame)
        }
        let outbound0 = Acme_Careplans_V1_AdvanceCarePlanWorkflowRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = input.videoVisit.audit.updatedBy
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = input.videoVisit.location.countryCode
                }
                $0.counterparty = Acme_Appointments_V1_AppointmentRef.with {
                    $0.displayName = input.videoVisit.organizer.displayName
                }
            }
            $0.context = input.context
            $0.details = Acme_Careplans_V1_AdvanceCarePlanWorkflowRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.phone = input.details.notify.phone
                }
            }
        }
        let step0: @Sendable () async throws -> Acme_Careplans_V1_AdvanceCarePlanWorkflowResponse = {
            try await self.careplansCarePlanWorkflow.advanceCarePlanWorkflow(outbound0)
        }
        let reply0 = try await step0()
        var outbound1 = Acme_Careplans_V1_CalculateCareGoalRequest()
        outbound1.careGoal = Acme_Careplans_V1_CareGoal.with {
            $0.assignee = Acme_Identity_V1_UserRef.with {
                $0.displayName = input.videoVisit.organizer.displayName
            }
            $0.audit = Acme_Common_V1_AuditInfo.with {
                $0.createdAt = input.videoVisit.audit.createdAt
            }
        }
        outbound1.context = input.context
        let reply1 = try await self.careplansCareGoalCalculation.calculateCareGoal(outbound1)
        let requests2 = input.videoVisit.participants.map { element in
            Acme_Telehealth_V1_CommentVisitNoteApprovalRequest.with {
                $0.context = input.context
                $0.details = Acme_Telehealth_V1_CommentVisitNoteApprovalRequest.Details.with {
                    $0.approver = Acme_Identity_V1_UserRef.with {
                        $0.email = element.contact.email
                    }
                }
            }
        }
        let replies2 = try await FanOut.map(requests2) { candidate in
            try await self.telehealthVisitNoteApproval.commentVisitNoteApproval(candidate)
        }
        let reply2 = replies2.first ?? Acme_Telehealth_V1_CommentVisitNoteApprovalResponse()
        _ = reply2
        return Acme_Telehealth_V1_AdvanceVideoVisitWorkflowResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.result.message
                $0.status = "ok"
            }
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.location = input.videoVisit.location
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.email = reply1.careGoal.requester.email
                }
                $0.participants = [
                    Acme_Telehealth_V1_VideoVisitParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = reply1.careGoal.assignee.email
                        }
                    }
                ]
                $0.videoVisitID = input.videoVisitID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processCancelVideoVisitWorkflow(_ input: Acme_Telehealth_V1_CancelVideoVisitWorkflowRequest) async throws
        -> Acme_Telehealth_V1_CancelVideoVisitWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "audit", detail: input.details.initiatedBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "CancelVideoVisitWorkflow",
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
        let outbound0 = Acme_Venues_V1_CountVenuesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Venues_V1_CountVenuesRequest.Filter.with {
                $0.createdAfter = input.videoVisit.audit.updatedAt
                $0.labels = input.annotations
                $0.ownerID = input.videoVisitID
                $0.region = input.videoVisit.location.region
            }
        }
        let reply0 = try await RPCOperations.read {
            try await self.venuesVenueQuery.countVenues(outbound0)
        }
        let outbound1 = Acme_Patients_V1_BrowsePatientsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Patients_V1_BrowsePatientsRequest.Filter.with {
                $0.createdAfter = input.videoVisit.audit.updatedAt
                $0.labels = input.annotations
                $0.region = input.videoVisit.location.region
            }
        }
        let reply1 = try await self.patientsPatientQuery.browsePatients(outbound1)
        let outbound2 = Acme_Telehealth_V1_ListPendingVisitNotesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Telehealth_V1_ListPendingVisitNotesRequest.Filter.with {
                $0.createdAfter = input.videoVisit.audit.updatedAt
                $0.labels = reply1.result.details
                $0.ownerID = input.videoVisit.organizer.userID
                $0.region = input.videoVisit.location.region
            }
        }
        async let remote2 = self.telehealthVisitNoteApproval.listPendingVisitNotes(outbound2)
        async let persisted2 = store.count(tenant: input.context.tenantID)
        let (reply2, count2) = try await (remote2, persisted2)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count2)])
        return Acme_Telehealth_V1_CancelVideoVisitWorkflowResponse.with {
            $0.outcome = Acme_Telehealth_V1_CancelVideoVisitWorkflowResponse.Outcome.with {
                $0.status = Projection.firstValue(
                    [
                        reply1.result.status,
                        reply2.result.status,
                    ], default: .init())
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.details = reply0.result.details
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.videoVisitID = input.videoVisitID
                $0.window = input.videoVisit.window
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processInspectVideoVisitWorkflow(_ input: Acme_Telehealth_V1_InspectVideoVisitWorkflowRequest) async throws
        -> Acme_Telehealth_V1_InspectVideoVisitWorkflowResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "InspectVideoVisitWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "InspectVideoVisitWorkflow", detail: input.context.traceID
        )
        return Acme_Telehealth_V1_InspectVideoVisitWorkflowResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.videoVisitID = input.videoVisitID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processListVideoVisitWorkflows(_ input: Acme_Telehealth_V1_ListVideoVisitWorkflowsRequest) async throws
        -> Acme_Telehealth_V1_ListVideoVisitWorkflowsResponse
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
            "ListVideoVisitWorkflows",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "ListVideoVisitWorkflows", detail: input.context.traceID
        )
        let outbound0 = Acme_Patients_V1_PreviewAllergyRequest.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.occurredAt = input.filter.createdAfter
            }
            $0.context = input.context
            $0.details = Acme_Patients_V1_PreviewAllergyRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.context.actor.email
                }
                $0.locale = input.context.locale
            }
        }
        let reply0 = try await self.listVideoVisitWorkflowsStep0.execute(outbound0)
        let outbound1 = Acme_Telehealth_V1_RejectVisitNoteRequest.with {
            $0.context = input.context
            $0.details = Acme_Telehealth_V1_RejectVisitNoteRequest.Details.with {
                $0.approver = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply0.allergy.subject.displayName
                }
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.patientID = reply0.allergy.subject.patientID
                }
            }
        }
        let port1 = RPCOperations.port { (request: Acme_Telehealth_V1_RejectVisitNoteRequest) in
            try await self.telehealthVisitNoteApproval.rejectVisitNote(request)
        }
        let reply1 = try await port1.execute(outbound1)
        return Acme_Telehealth_V1_ListVideoVisitWorkflowsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply1.result.message
                $0.status = reply0.result.status
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processRetryVideoVisitWorkflow(_ input: Acme_Telehealth_V1_RetryVideoVisitWorkflowRequest) async throws
        -> Acme_Telehealth_V1_RetryVideoVisitWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "audit", detail: input.details.initiatedBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "RetryVideoVisitWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VideoVisitRecord(input.videoVisit, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Patients_V1_CheckMedicalRecordEligibilityRequest.with {
            $0.context = input.context
            $0.details = Acme_Patients_V1_CheckMedicalRecordEligibilityRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.videoVisit.organizer.email
                }
            }
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = input.videoVisit.organizer.displayName
                }
            }
        }
        let reply0 = try await self.retryVideoVisitWorkflowStep0(outbound0)
        let outbound1 = Acme_Telehealth_V1_ApproveVideoVisitRequest.with {
            $0.context = input.context
            $0.details = Acme_Telehealth_V1_ApproveVideoVisitRequest.Details.with {
                $0.approver = Acme_Identity_V1_UserRef.with {
                    $0.email = input.videoVisit.organizer.email
                }
            }
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply0.medicalRecord.audit.updatedAt
                }
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.region = reply0.medicalRecord.billingAddress.region
                }
            }
        }
        guard
            let execute1 = self.retryVideoVisitWorkflowStep1[settings.region]
                ?? self.retryVideoVisitWorkflowStep1["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply1 = try await execute1(outbound1)
        let outbound2 = Acme_Careplans_V1_RejectCareGoalRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.videoVisit.organizer.displayName
                    $0.email = reply1.videoVisit.organizer.email
                }
                $0.comments = [
                    Acme_Careplans_V1_CareGoalComment.with {
                        $0.createdAt = reply1.videoVisit.audit.createdAt
                    }
                ]
            }
            $0.context = input.context
            $0.details = Acme_Careplans_V1_RejectCareGoalRequest.Details.with {
                $0.approver = Acme_Identity_V1_UserRef.with {
                    $0.email = reply0.medicalRecord.counterparty.email
                }
            }
        }
        let reply2 = try await self.careplansCareGoalApproval.rejectCareGoal(outbound2)
        return Acme_Telehealth_V1_RetryVideoVisitWorkflowResponse.with {
            $0.outcome = Acme_Telehealth_V1_RetryVideoVisitWorkflowResponse.Outcome.with {
                $0.message = reply1.outcome.message
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.result.message
                $0.status = "ok"
            }
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.recipient = reply1.videoVisit.location.recipient
                }
                $0.participants = [
                    Acme_Telehealth_V1_VideoVisitParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = reply2.careGoal.requester.email
                        }
                    }
                ]
                $0.videoVisitID = input.videoVisitID
                $0.window = input.videoVisit.window
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processSignalVideoVisitWorkflow(_ input: Acme_Telehealth_V1_SignalVideoVisitWorkflowRequest) async throws
        -> Acme_Telehealth_V1_SignalVideoVisitWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "audit", detail: input.details.initiatedBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SignalVideoVisitWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VideoVisitRecord(input.videoVisit, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Patients_V1_SimulateMedicalRecordRequest.with {
            $0.context = input.context
            $0.details = Acme_Patients_V1_SimulateMedicalRecordRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.locality = input.videoVisit.location.locality
                }
            }
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.videoVisit.audit.createdAt
                    $0.updatedAt = input.videoVisit.audit.updatedAt
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.videoVisit.location.region
                }
            }
        }
        let envelope0 = try Google_Protobuf_Any(message: outbound0)
        let unpacked0 = try Acme_Patients_V1_SimulateMedicalRecordRequest(unpackingAny: envelope0)
        let reply0 = try await self.patientsMedicalRecordCalculation.simulateMedicalRecord(unpacked0)
        let outbound1 = Acme_Careplans_V1_RejectCareGoalRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.customer = Acme_Patients_V1_PatientRef.with {
                    $0.patientID = reply0.medicalRecord.counterparty.patientID
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.name = input.details.notify.name
                }
            }
            $0.context = input.context
            $0.details = Acme_Careplans_V1_RejectCareGoalRequest.Details.with {
                $0.approver = Acme_Identity_V1_UserRef.with {
                    $0.email = reply0.medicalRecord.counterparty.email
                }
            }
        }
        let json1 = try outbound1.jsonString()
        let decoded1 = try Acme_Careplans_V1_RejectCareGoalRequest(jsonString: json1)
        let reply1 = try await self.careplansCareGoalApproval.rejectCareGoal(decoded1)
        let requests2 = input.videoVisit.participants.map { element in
            Acme_Careplans_V1_ListVitalWorkflowsRequest.with {
                $0.context = input.context
                $0.filter = Acme_Careplans_V1_ListVitalWorkflowsRequest.Filter.with {
                    $0.createdAfter = input.videoVisit.audit.createdAt
                    $0.ownerID = element.participantID
                    $0.region = input.videoVisit.location.region
                }
            }
        }
        let replies2 = try await FanOut.map(requests2) { candidate in
            try await self.careplansVitalWorkflow.listVitalWorkflows(candidate)
        }
        let reply2 = replies2.first ?? Acme_Careplans_V1_ListVitalWorkflowsResponse()
        _ = reply2
        return Acme_Telehealth_V1_SignalVideoVisitWorkflowResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.email = reply1.careGoal.assignee.email
                }
                $0.participants = [
                    Acme_Telehealth_V1_VideoVisitParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = reply0.medicalRecord.counterparty.email
                        }
                    }
                ]
                $0.title = input.videoVisit.title
                $0.videoVisitID = input.videoVisitID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processStartVideoVisitWorkflow(_ input: Acme_Telehealth_V1_StartVideoVisitWorkflowRequest) async throws
        -> Acme_Telehealth_V1_StartVideoVisitWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "audit", detail: input.details.initiatedBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "StartVideoVisitWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VideoVisitRecord(input.videoVisit, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let requests0 = input.videoVisit.participants.map { element in
            Acme_Careplans_V1_ApproveCarePlanRequest.with {
                $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                    $0.audit = Acme_Common_V1_AuditInfo.with {
                        $0.updatedBy = input.videoVisit.audit.updatedBy
                    }
                    $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                        $0.locality = input.videoVisit.location.locality
                    }
                }
                $0.context = input.context
                $0.details = Acme_Careplans_V1_ApproveCarePlanRequest.Details.with {
                    $0.approver = Acme_Identity_V1_UserRef.with {
                        $0.displayName = input.videoVisit.organizer.displayName
                        $0.email = element.contact.email
                    }
                }
            }
        }
        let replies0 = try await FanOut.map(requests0) { candidate in
            try await self.careplansCarePlanApproval.approveCarePlan(candidate)
        }
        let reply0 = replies0.first ?? Acme_Careplans_V1_ApproveCarePlanResponse()
        _ = reply0
        return Acme_Telehealth_V1_StartVideoVisitWorkflowResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.location = input.videoVisit.location
                $0.videoVisitID = input.videoVisitID
            }
        }
    }
}
