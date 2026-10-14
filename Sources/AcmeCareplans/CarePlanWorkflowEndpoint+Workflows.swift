import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension CarePlanWorkflowEndpoint {
    /// Execute the careplans workflow and project its upstream replies.
    func processAdvanceCarePlanWorkflow(_ input: Acme_Careplans_V1_AdvanceCarePlanWorkflowRequest) async throws
        -> Acme_Careplans_V1_AdvanceCarePlanWorkflowResponse
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
            "AdvanceCarePlanWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CarePlanRecord(input.carePlan, tenant: input.context.tenantID)
        try await store.save(record.stored)
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        let importFrame = Acme_Patients_V1_BatchCreatePatientsRequest.with {
            $0.context = input.context
        }
        _ = try await self.patientsPatient.batchCreatePatients { writer in
            try await writer.write(importFrame)
        }
        let outbound0 = Acme_Documents_V1_CreateDocumentRequest.with {
            $0.context = input.context
            $0.document = Acme_Documents_V1_Document.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.carePlan.billingAddress.region
                }
            }
        }
        let envelope0 = try Google_Protobuf_Any(message: outbound0)
        let unpacked0 = try Acme_Documents_V1_CreateDocumentRequest(unpackingAny: envelope0)
        let reply0 = try await self.documentsDocument.createDocument(unpacked0)
        let outbound1 = Acme_Patients_V1_CheckAllergyEligibilityRequest.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = input.carePlan.counterparty.displayName
                    $0.email = input.details.notify.email
                }
            }
            $0.context = input.context
            $0.details = Acme_Patients_V1_CheckAllergyEligibilityRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.phone = input.details.notify.phone
                    $0.preferredChannel = input.details.notify.preferredChannel
                }
            }
        }
        let json1 = try outbound1.jsonString()
        let decoded1 = try Acme_Patients_V1_CheckAllergyEligibilityRequest(jsonString: json1)
        let reply1 = try await self.patientsAllergyValidation.checkAllergyEligibility(decoded1)
        let selection2_2: String
        switch input.carePlan.settlement {
        case .card(let card):
            selection2_2 = card.last4
        default: selection2_2 = .init()
        }
        let outbound2 = Acme_Prescriptions_V1_SimulatePrescriptionRequest.with {
            $0.context = input.context
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = reply0.document.billingAddress.region
                }
                $0.card = Acme_Prescriptions_V1_PrescriptionCardSettlement.with {
                    $0.last4 = selection2_2
                }
            }
        }
        let reply2 = try await self.prescriptionsPrescriptionCalculation.simulatePrescription(outbound2)
        return Acme_Careplans_V1_AdvanceCarePlanWorkflowResponse.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply2.prescription.audit.updatedBy
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = reply2.prescription.billingAddress.region
                }
                $0.carePlanID = input.carePlanID
                $0.status = input.carePlan.status
                $0.total = reply0.document.total
            }
            $0.outcome = Acme_Careplans_V1_AdvanceCarePlanWorkflowResponse.Outcome.with {
                $0.status = reply1.result.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processCancelCarePlanWorkflow(_ input: Acme_Careplans_V1_CancelCarePlanWorkflowRequest) async throws
        -> Acme_Careplans_V1_CancelCarePlanWorkflowResponse
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
            "CancelCarePlanWorkflow",
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
        let outbound0 = Acme_Careplans_V1_FindCarePlansRequest.forCarePlanWorkflowEndpointCancelCarePlanWorkflow0(
            input
        )
        let reply0 = try await self.careplansCarePlanQuery.findCarePlans(outbound0)
        let outbound1 = Acme_Appointments_V1_ScoreClinicSlotRequest.with {
            $0.clinicSlot = Acme_Appointments_V1_ClinicSlot.with {
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.locality = input.carePlan.billingAddress.locality
                }
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.carePlan.counterparty.displayName
                }
                $0.participants = [
                    Acme_Appointments_V1_ClinicSlotParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = input.details.notify.email
                        }
                    }
                ]
            }
            $0.context = input.context
            $0.details = Acme_Appointments_V1_ScoreClinicSlotRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = input.carePlan.billingAddress.postalCode
                }
            }
        }
        let reply1 = try await self.appointmentsClinicSlotValidation.scoreClinicSlot(
            outbound1, metadata: ["x-acme-region": .string(settings.region)]
        )
        let outbound2 = Acme_Careplans_V1_CountCarePlansRequest.with {
            $0.context = input.context
            $0.filter = Acme_Careplans_V1_CountCarePlansRequest.Filter.with {
                $0.createdAfter = input.carePlan.counterparty.startsAt
                $0.region = reply1.clinicSlot.location.region
            }
        }
        let reply2 = try await RPCOperations.call(outbound2) { request in
            try await self.careplansCarePlanQuery.countCarePlans(request)
        }
        let outbound3 = Acme_Audit_V1_CreateAuditEventRequest.with {
            $0.auditEvent = Acme_Audit_V1_AuditEvent.with {
                $0.subject = Acme_Audit_V1_AuditTrailRef.with {
                    $0.displayName = Projection.read(
                        reply1, at: \Acme_Appointments_V1_ScoreClinicSlotResponse.clinicSlot.organizer.displayName)
                }
            }
            $0.context = Projection.read(input, at: \Acme_Careplans_V1_CancelCarePlanWorkflowRequest.context)
        }
        let reply3 = try await self.auditAuditEvent.createAuditEvent(outbound3)
        return Acme_Careplans_V1_CancelCarePlanWorkflowResponse.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply1.clinicSlot.audit.createdBy
                }
                $0.carePlanID = input.carePlanID
                $0.dueAt = input.carePlan.dueAt
                $0.total = reply1.breakdown.total
            }
            $0.outcome = Acme_Careplans_V1_CancelCarePlanWorkflowResponse.Outcome.with {
                $0.status = reply3.result.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.details = reply2.result.details
                $0.message = reply3.result.message
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processInspectCarePlanWorkflow(_ input: Acme_Careplans_V1_InspectCarePlanWorkflowRequest) async throws
        -> Acme_Careplans_V1_InspectCarePlanWorkflowResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "InspectCarePlanWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "InspectCarePlanWorkflow", detail: input.context.traceID
        )
        return Acme_Careplans_V1_InspectCarePlanWorkflowResponse.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.carePlanID = input.carePlanID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processListCarePlanWorkflows(_ input: Acme_Careplans_V1_ListCarePlanWorkflowsRequest) async throws
        -> Acme_Careplans_V1_ListCarePlanWorkflowsResponse
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
            "ListCarePlanWorkflows",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "ListCarePlanWorkflows", detail: input.context.traceID
        )
        let outbound0 = Acme_Careplans_V1_ExportCareGoalsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Careplans_V1_ExportCareGoalsRequest.Filter.with {
                $0.createdAfter = input.filter.createdAfter
                $0.query = input.filter.query
                $0.region = input.filter.region
            }
        }
        let reply0 = try await self.careplansCareGoalQuery.exportCareGoals(outbound0) { response in
            var latest = Acme_Careplans_V1_ExportCareGoalsResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        _ = reply0
        return Acme_Careplans_V1_ListCarePlanWorkflowsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processResumeCarePlanWorkflow(_ input: Acme_Careplans_V1_ResumeCarePlanWorkflowRequest) async throws
        -> Acme_Careplans_V1_ResumeCarePlanWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.carePlan.audit.etag)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "audit", detail: input.carePlan.audit.etag
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ResumeCarePlanWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CarePlanRecord(input.carePlan, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Careplans_V1_CalculateCareGoalRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = input.carePlan.audit.createdBy
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.notify.email
                }
            }
            $0.context = input.context
            $0.details = Acme_Careplans_V1_CalculateCareGoalRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.recipient = input.carePlan.billingAddress.recipient
                }
            }
        }
        let step0: @Sendable () async throws -> Acme_Careplans_V1_CalculateCareGoalResponse = {
            try await self.careplansCareGoalCalculation.calculateCareGoal(outbound0)
        }
        let reply0 = try await step0()
        var outbound1 = Acme_Featureflags_V1_SuggestFeatureFlagsRequest()
        outbound1.context = input.context
        outbound1.filter = Acme_Featureflags_V1_SuggestFeatureFlagsRequest.Filter.with {
            $0.region = input.carePlan.billingAddress.region
        }
        let reply1 = try await self.featureflagsFeatureFlagQuery.suggestFeatureFlags(outbound1)
        let selection2_3: String
        switch reply0.careGoal.origin {
        case .channel(let channel):
            selection2_3 = channel.channel
        default: selection2_3 = .init()
        }
        let outbound2 = Acme_Careplans_V1_NormalizeCareGoalRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply0.careGoal.audit.createdBy
                }
                $0.channel = Acme_Careplans_V1_CareGoalChannelOrigin.with {
                    $0.channel = selection2_3
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.preferredChannel = input.details.notify.preferredChannel
                }
            }
            $0.context = input.context
            $0.details = Acme_Careplans_V1_NormalizeCareGoalRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.name = input.details.notify.name
                }
            }
        }
        let reply2 = try await self.careplansCareGoalValidation.normalizeCareGoal(outbound2)
        return Acme_Careplans_V1_ResumeCarePlanWorkflowResponse.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.carePlanID = input.carePlanID
                $0.counterparty = input.carePlan.counterparty
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.referenceIds = reply1.result.referenceIds + reply2.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processSignalCarePlanWorkflow(_ input: Acme_Careplans_V1_SignalCarePlanWorkflowRequest) async throws
        -> Acme_Careplans_V1_SignalCarePlanWorkflowResponse
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
            "SignalCarePlanWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CarePlanRecord(input.carePlan, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Appointments_V1_LintProvidersRequest.with {
            $0.context = input.context
            $0.provider = Acme_Appointments_V1_Provider.with {
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.carePlan.billingAddress.region
                }
            }
        }
        let step0: @Sendable () async throws -> Acme_Appointments_V1_LintProvidersResponse = {
            try await self.appointmentsProviderValidation.lintProviders(outbound0)
        }
        let reply0 = try await step0()
        let outbound1 = Acme_Careplans_V1_ScheduleVitalExpiryRequest.with {
            $0.context = input.context
            $0.details = Acme_Careplans_V1_ScheduleVitalExpiryRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.name = input.details.notify.name
                    $0.phone = input.details.notify.phone
                    $0.preferredChannel = reply0.provider.contact.preferredChannel
                }
            }
        }
        let reply1 = try await self.careplansVitalLifecycle.scheduleVitalExpiry(outbound1)
        return Acme_Careplans_V1_SignalCarePlanWorkflowResponse.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.carePlanID = input.carePlanID
                $0.counterparty = Acme_Appointments_V1_AppointmentRef.with {
                    $0.appointmentID = reply1.vital.subject.appointmentID
                }
                $0.issuedAt = input.carePlan.issuedAt
                $0.number = reply0.provider.passport.number
            }
            $0.outcome = Acme_Careplans_V1_SignalCarePlanWorkflowResponse.Outcome.with {
                $0.referenceID = reply1.outcome.referenceID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processStartCarePlanWorkflow(_ input: Acme_Careplans_V1_StartCarePlanWorkflowRequest) async throws
        -> Acme_Careplans_V1_StartCarePlanWorkflowResponse
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
            "StartCarePlanWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CarePlanRecord(input.carePlan, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Telehealth_V1_CalculateVideoVisitRequest.with {
            $0.context = input.context
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = input.carePlan.audit.updatedAt
                }
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = input.carePlan.billingAddress.countryCode
                }
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.carePlan.counterparty.displayName
                }
                $0.participants = [
                    Acme_Telehealth_V1_VideoVisitParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.phone = input.details.notify.phone
                        }
                    }
                ]
            }
        }
        async let remote0 = self.telehealthVideoVisitCalculation.calculateVideoVisit(outbound0)
        async let persisted0 = store.count(tenant: input.context.tenantID)
        let (reply0, count0) = try await (remote0, persisted0)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count0)])
        let requests1 = input.carePlan.lines.map { element in
            Acme_Patients_V1_CreatePatientRequest.with {
                $0.context = input.context
                $0.patient = Acme_Patients_V1_Patient.with {
                    $0.attributes = element.attributes
                    $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                        $0.email = reply0.videoVisit.organizer.email
                    }
                }
            }
        }
        let replies1 = try await FanOut.map(requests1) { candidate in
            try await self.patientsPatient.createPatient(candidate)
        }
        let reply1 = replies1.first ?? Acme_Patients_V1_CreatePatientResponse()
        _ = reply1
        return Acme_Careplans_V1_StartCarePlanWorkflowResponse.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = reply0.videoVisit.location.countryCode
                }
                $0.carePlanID = input.carePlanID
                $0.notes = input.carePlan.notes
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }
}
