import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension AllergyApprovalEndpoint {
    /// Execute the patients workflow and project its upstream replies.
    func processApproveAllergy(_ input: Acme_Patients_V1_ApproveAllergyRequest) async throws
        -> Acme_Patients_V1_ApproveAllergyResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.allergy.allergyID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "audit", detail: input.allergy.allergyID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ApproveAllergy",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try AllergyRecord(input.allergy, tenant: input.context.tenantID)
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
        let outbound0 = Acme_Patients_V1_SummarizePatientsRequest.with {
            $0.annotations = input.annotations
            $0.context = input.context
            $0.patientID = input.allergy.subject.patientID
            $0.reason = input.reason
        }
        let reply0 = try await self.approveAllergyStep0.execute(outbound0)
        let outbound1 = Acme_Careplans_V1_PauseVitalWorkflowRequest.with {
            $0.context = input.context
            $0.details = Acme_Careplans_V1_PauseVitalWorkflowRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.approver.email
                }
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.subject = Acme_Appointments_V1_AppointmentRef.with {
                    $0.displayName = input.allergy.subject.displayName
                }
            }
        }
        let port1 = RPCOperations.port { (request: Acme_Careplans_V1_PauseVitalWorkflowRequest) in
            try await self.careplansVitalWorkflow.pauseVitalWorkflow(request)
        }
        let reply1 = try await port1.execute(outbound1)
        return Acme_Patients_V1_ApproveAllergyResponse.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.allergyID = input.allergyID
                $0.source = input.allergy.source
            }
            $0.outcome = Acme_Patients_V1_ApproveAllergyResponse.Outcome.with {
                $0.referenceID = reply1.outcome.referenceID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.vital.correlationID
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processCommentAllergyApproval(_ input: Acme_Patients_V1_CommentAllergyApprovalRequest) async throws
        -> Acme_Patients_V1_CommentAllergyApprovalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.allergy.allergyID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "audit", detail: input.allergy.allergyID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "CommentAllergyApproval",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try AllergyRecord(input.allergy, tenant: input.context.tenantID)
        try await store.save(record.stored)
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        let outbound0 = Acme_Patients_V1_ReconcileMedicalRecordsRequest.with {
            $0.context = input.context
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = input.allergy.subject.displayName
                }
                $0.lines = [
                    Acme_Patients_V1_MedicalRecordLine.with {
                        $0.attributes = input.allergy.attributes
                    }
                ]
            }
        }
        let reply0 = try await self.commentAllergyApprovalStep0(outbound0)
        let outbound1 = Acme_Careplans_V1_CancelCareGoalWorkflowRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply0.medicalRecord.audit.updatedAt
                    $0.updatedBy = reply0.medicalRecord.audit.updatedBy
                }
                $0.customer = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = input.allergy.subject.displayName
                }
            }
            $0.context = input.context
            $0.details = Acme_Careplans_V1_CancelCareGoalWorkflowRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.allergy.subject.email
                }
            }
        }
        guard
            let execute1 = self.commentAllergyApprovalStep1[settings.region]
                ?? self.commentAllergyApprovalStep1["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply1 = try await execute1(outbound1)
        return Acme_Patients_V1_CommentAllergyApprovalResponse.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.allergyID = input.allergyID
                $0.kind = input.allergy.kind
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = reply1.careGoal.customer.displayName
                }
            }
            $0.outcome = Acme_Patients_V1_CommentAllergyApprovalResponse.Outcome.with {
                $0.message = reply0.outcome.message
                $0.status = Projection.firstValue(
                    [
                        reply0.outcome.status,
                        reply1.outcome.status,
                    ], default: .init())
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processDelegateAllergyApproval(_ input: Acme_Patients_V1_DelegateAllergyApprovalRequest) async throws
        -> Acme_Patients_V1_DelegateAllergyApprovalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.allergy.allergyID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "audit", detail: input.allergy.allergyID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "DelegateAllergyApproval",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try AllergyRecord(input.allergy, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Careplans_V1_RetryVitalWorkflowRequest.with {
            $0.context = input.context
            $0.details = Acme_Careplans_V1_RetryVitalWorkflowRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.approver.email
                }
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.attributes = input.allergy.attributes
                $0.occurredAt = input.allergy.occurredAt
                $0.sequence = input.allergy.sequence
            }
        }
        let reply0 = try await self.careplansVitalWorkflow.retryVitalWorkflow(outbound0)
        let outbound1 = Acme_Pipelines_V1_CalculatePipelineRequest.with {
            $0.context = input.context
            $0.pipeline = Acme_Pipelines_V1_Pipeline.with {
                $0.participants = [
                    Acme_Pipelines_V1_PipelineParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = input.details.approver.email
                        }
                    }
                ]
            }
        }
        let envelope1 = try Google_Protobuf_Any(message: outbound1)
        let unpacked1 = try Acme_Pipelines_V1_CalculatePipelineRequest(unpackingAny: envelope1)
        let reply1 = try await self.pipelinesPipelineCalculation.calculatePipeline(unpacked1)
        let outbound2 = Acme_Patients_V1_CancelAllergyImportRequest.with {
            $0.allergyID = input.allergyID
            $0.context = input.context
            $0.details = Acme_Patients_V1_CancelAllergyImportRequest.Details.with {
                $0.newOwner = Acme_Identity_V1_UserRef.with {
                    $0.email = input.details.approver.email
                    $0.userID = input.details.approver.userID
                }
            }
        }
        let json2 = try outbound2.jsonString()
        let decoded2 = try Acme_Patients_V1_CancelAllergyImportRequest(jsonString: json2)
        let reply2 = try await self.patientsAllergyImport.cancelAllergyImport(decoded2)
        return Acme_Patients_V1_DelegateAllergyApprovalResponse.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.allergyID = input.allergyID
                $0.correlationID = reply2.allergy.correlationID
                $0.occurredAt = input.allergy.occurredAt
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = reply2.allergy.subject.displayName
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply1.result.details
                $0.status = reply0.result.status
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processEscalateAllergy(_ input: Acme_Patients_V1_EscalateAllergyRequest) async throws
        -> Acme_Patients_V1_EscalateAllergyResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.allergy.allergyID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "audit", detail: input.allergy.allergyID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "EscalateAllergy",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try AllergyRecord(input.allergy, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let requests0 = input.allergy.measurements.map { element in
            Acme_Appointments_V1_CancelAppointmentWorkflowRequest.with {
                $0.appointment = Acme_Appointments_V1_Appointment.with {
                    $0.audit = Acme_Common_V1_AuditInfo.with {
                        $0.createdAt = element.observedAt
                    }
                    $0.participants = [
                        Acme_Appointments_V1_AppointmentParticipant.with {
                            $0.contact = Acme_Common_V1_ContactInfo.with {
                                $0.email = input.details.approver.email
                            }
                        }
                    ]
                }
                $0.context = input.context
                $0.details = Acme_Appointments_V1_CancelAppointmentWorkflowRequest.Details.with {
                    $0.notify = Acme_Common_V1_ContactInfo.with {
                        $0.email = input.allergy.subject.email
                    }
                }
            }
        }
        let replies0 = try await FanOut.map(requests0) { candidate in
            try await self.appointmentsAppointmentWorkflow.cancelAppointmentWorkflow(candidate)
        }
        let reply0 = replies0.first ?? Acme_Appointments_V1_CancelAppointmentWorkflowResponse()
        _ = reply0
        let outbound1 = Acme_Patients_V1_GenerateMedicalRecordReportRequest.forAllergyApprovalEndpointEscalateAllergy1(
            input
        )
        let reply1 = try await self.patientsMedicalRecordReporting.generateMedicalRecordReport(outbound1)
        return Acme_Patients_V1_EscalateAllergyResponse.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.allergyID = input.allergyID
                $0.correlationID = reply1.result.correlationID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = input.allergy.correlationID
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processGetAllergyApprovalStatus(_ input: Acme_Patients_V1_GetAllergyApprovalStatusRequest) async throws
        -> Acme_Patients_V1_GetAllergyApprovalStatusResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "GetAllergyApprovalStatus",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "GetAllergyApprovalStatus", detail: input.context.traceID
        )
        let outbound0 = Acme_Prescriptions_V1_ReconcileRefillsRequest.with {
            $0.context = input.context
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.context.actor.userID
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.context.actor.email
                }
            }
        }
        let reply0 = try await self.prescriptionsRefillSync.reconcileRefills(
            outbound0, metadata: ["x-acme-region": .string(settings.region)]
        )
        let outbound1 = Acme_Patients_V1_PreviewMedicalRecordRequest.with {
            $0.context = input.context
            $0.details = Acme_Patients_V1_PreviewMedicalRecordRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply0.refill.assignee.email
                }
            }
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply0.refill.audit.updatedAt
                    $0.updatedBy = reply0.refill.audit.updatedBy
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.email = reply0.refill.requester.email
                }
            }
        }
        let reply1 = try await RPCOperations.call(outbound1) { request in
            try await self.patientsMedicalRecordValidation.previewMedicalRecord(request)
        }
        return Acme_Patients_V1_GetAllergyApprovalStatusResponse.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.allergyID = input.allergyID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply0.result.referenceIds
                $0.status = reply1.outcome.status
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processListPendingAllergies(_ input: Acme_Patients_V1_ListPendingAllergiesRequest) async throws
        -> Acme_Patients_V1_ListPendingAllergiesResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ListPendingAllergies",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "ListPendingAllergies", detail: input.context.traceID
        )
        let outbound0 = Acme_Patients_V1_RejectMedicalRecordRequest.with {
            $0.context = Projection.read(input, at: \Acme_Patients_V1_ListPendingAllergiesRequest.context)
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = Projection.read(input, at: \Acme_Patients_V1_ListPendingAllergiesRequest.filter.region)
                }
            }
        }
        let reply0 = try await self.patientsMedicalRecordApproval.rejectMedicalRecord(outbound0)
        return Acme_Patients_V1_ListPendingAllergiesResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processRecallAllergy(_ input: Acme_Patients_V1_RecallAllergyRequest) async throws
        -> Acme_Patients_V1_RecallAllergyResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.allergy.allergyID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "audit", detail: input.allergy.allergyID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "RecallAllergy",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try AllergyRecord(input.allergy, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let requests0 = input.allergy.measurements.map { element in
            Acme_Patients_V1_CancelPatientWorkflowRequest.with {
                $0.context = input.context
                $0.details = Acme_Patients_V1_CancelPatientWorkflowRequest.Details.with {
                    $0.notify = Acme_Common_V1_ContactInfo.with {
                        $0.email = input.allergy.subject.email
                    }
                }
                $0.patient = Acme_Patients_V1_Patient.with {
                    $0.audit = Acme_Common_V1_AuditInfo.with {
                        $0.createdAt = element.observedAt
                    }
                    $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                        $0.displayName = input.allergy.subject.displayName
                    }
                }
            }
        }
        let replies0 = try await FanOut.map(requests0) { candidate in
            try await self.patientsPatientWorkflow.cancelPatientWorkflow(candidate)
        }
        let reply0 = replies0.first ?? Acme_Patients_V1_CancelPatientWorkflowResponse()
        _ = reply0
        return Acme_Patients_V1_RecallAllergyResponse.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.allergyID = input.allergyID
            }
            $0.outcome = Acme_Patients_V1_RecallAllergyResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processRejectAllergy(_ input: Acme_Patients_V1_RejectAllergyRequest) async throws
        -> Acme_Patients_V1_RejectAllergyResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.allergy.allergyID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "audit", detail: input.allergy.allergyID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "RejectAllergy",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try AllergyRecord(input.allergy, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Patients_V1_RecallMedicalRecordRequest.with {
            $0.context = input.context
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = input.details.approver.displayName
                }
            }
        }
        let step0: @Sendable () async throws -> Acme_Patients_V1_RecallMedicalRecordResponse = {
            try await self.patientsMedicalRecordApproval.recallMedicalRecord(outbound0)
        }
        let reply0 = try await step0()
        var outbound1 = Acme_Authorization_V1_ResolveAccessPoliciesRequest()
        outbound1.context = input.context
        let reply1 = try await self.authorizationAccessPolicyQuery.resolveAccessPolicies(outbound1)
        let requests2 = input.allergy.measurements.map { element in
            Acme_Venues_V1_BrowseVenuesRequest.with {
                $0.context = input.context
                $0.filter = Acme_Venues_V1_BrowseVenuesRequest.Filter.with {
                    $0.createdAfter = element.observedAt
                    $0.ownerID = input.details.approver.userID
                    $0.region = reply0.medicalRecord.billingAddress.region
                }
            }
        }
        let replies2 = try await FanOut.map(requests2) { candidate in
            try await self.venuesVenueQuery.browseVenues(candidate)
        }
        let reply2 = replies2.first ?? Acme_Venues_V1_BrowseVenuesResponse()
        _ = reply2
        return Acme_Patients_V1_RejectAllergyResponse.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.allergyID = input.allergyID
                $0.correlationID = reply0.result.correlationID
            }
            $0.outcome = Acme_Patients_V1_RejectAllergyResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply1.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processSubmitAllergy(_ input: Acme_Patients_V1_SubmitAllergyRequest) async throws
        -> Acme_Patients_V1_SubmitAllergyResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.allergy.allergyID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "audit", detail: input.allergy.allergyID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SubmitAllergy",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try AllergyRecord(input.allergy, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Venues_V1_ExplainVenueDecisionRequest.with {
            $0.context = input.context
            $0.details = Acme_Venues_V1_ExplainVenueDecisionRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.approver.email
                }
            }
        }
        let step0: @Sendable () async throws -> Acme_Venues_V1_ExplainVenueDecisionResponse = {
            try await self.venuesVenueValidation.explainVenueDecision(outbound0)
        }
        let reply0 = try await step0()
        let outbound1 = Acme_Patients_V1_ShareAllergyReportRequest.with {
            $0.context = input.context
            $0.details = Acme_Patients_V1_ShareAllergyReportRequest.Details.with {
                $0.recipient = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.allergy.subject.email
                }
            }
            $0.reason = input.reason
        }
        let reply1 = try await self.patientsAllergyReporting.shareAllergyReport(outbound1)
        let outbound2 = Acme_Patients_V1_RecallMedicalRecordRequest.with {
            $0.context = input.context
            $0.details = Acme_Patients_V1_RecallMedicalRecordRequest.Details.with {
                $0.approver = Acme_Identity_V1_UserRef.with {
                    $0.email = input.allergy.subject.email
                    $0.userID = input.details.approver.userID
                }
            }
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = input.details.approver.displayName
                }
            }
        }
        async let remote2 = self.patientsMedicalRecordApproval.recallMedicalRecord(outbound2)
        async let persisted2 = store.count(tenant: input.context.tenantID)
        let (reply2, count2) = try await (remote2, persisted2)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count2)])
        let selection3_1: String
        switch reply0.venue.locator {
        case .address(let address):
            selection3_1 = address.region
        default: selection3_1 = .init()
        }
        let outbound3 = Acme_Patients_V1_ListPendingMedicalRecordsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Patients_V1_ListPendingMedicalRecordsRequest.Filter.with {
                $0.region = selection3_1
            }
        }
        let reply3 = try await self.patientsMedicalRecordApproval.listPendingMedicalRecords(outbound3)
        return Acme_Patients_V1_SubmitAllergyResponse.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.allergyID = input.allergyID
                $0.source = input.allergy.source
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.email = reply1.allergy.subject.email
                }
            }
            $0.outcome = Acme_Patients_V1_SubmitAllergyResponse.Outcome.with {
                $0.message = reply3.result.message
                $0.nextSteps = reply0.outcome.nextSteps
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.message = reply2.result.message
                $0.status = reply3.result.status
            }
        }
    }
}
