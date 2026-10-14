import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension AllergyLifecycleEndpoint {
    /// Execute the patients workflow and project its upstream replies.
    func processActivateAllergy(_ input: Acme_Patients_V1_ActivateAllergyRequest) async throws
        -> Acme_Patients_V1_ActivateAllergyResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.userID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "audit", detail: input.details.newOwner.userID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ActivateAllergy",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "ActivateAllergy", detail: input.context.traceID
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
        let outbound0 = Acme_Telehealth_V1_SubmitVisitNoteRequest.with {
            $0.context = input.context
            $0.details = Acme_Telehealth_V1_SubmitVisitNoteRequest.Details.with {
                $0.approver = Acme_Identity_V1_UserRef.with {
                    $0.email = input.details.notifyContact.email
                }
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = input.details.newOwner.displayName
                    $0.email = input.details.newOwner.email
                }
            }
        }
        let reply0 = try await RPCOperations.call(outbound0) { request in
            try await self.telehealthVisitNoteApproval.submitVisitNote(request)
        }
        let outbound1 = Acme_Careplans_V1_ListPendingCarePlansRequest.with {
            $0.context = Projection.read(input, at: \Acme_Patients_V1_ActivateAllergyRequest.context)
            $0.filter = Acme_Careplans_V1_ListPendingCarePlansRequest.Filter.with {
                $0.createdAfter = Projection.read(
                    reply0, at: \Acme_Telehealth_V1_SubmitVisitNoteResponse.visitNote.issuedAt)
                $0.region = Projection.read(
                    reply0, at: \Acme_Telehealth_V1_SubmitVisitNoteResponse.visitNote.billingAddress.region)
            }
        }
        let reply1 = try await self.careplansCarePlanApproval.listPendingCarePlans(outbound1)
        return Acme_Patients_V1_ActivateAllergyResponse.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.allergyID = input.allergyID
                $0.correlationID = reply0.result.correlationID
            }
            $0.outcome = Acme_Patients_V1_ActivateAllergyResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
                $0.status = reply0.outcome.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processExpireAllergy(_ input: Acme_Patients_V1_ExpireAllergyRequest) async throws
        -> Acme_Patients_V1_ExpireAllergyResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "audit", detail: input.details.newOwner.email
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ExpireAllergy",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "ExpireAllergy", detail: input.context.traceID
        )
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        let outbound0 = Acme_Patients_V1_ValidateAllergyImportRequest.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = input.details.newOwner.displayName
                    $0.email = input.details.notifyContact.email
                }
            }
            $0.context = input.context
            $0.details = Acme_Patients_V1_ValidateAllergyImportRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.preferredChannel = input.details.notifyContact.preferredChannel
                }
            }
        }
        let step0: @Sendable () async throws -> Acme_Patients_V1_ValidateAllergyImportResponse = {
            try await self.patientsAllergyImport.validateAllergyImport(outbound0)
        }
        let reply0 = try await step0()
        var outbound1 = Acme_Patients_V1_ResolveMedicalRecordConflictRequest()
        outbound1.context = input.context
        outbound1.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
            $0.counterparty = Acme_Patients_V1_PatientRef.with {
                $0.displayName = input.details.newOwner.displayName
                $0.email = input.details.notifyContact.email
            }
        }
        let reply1 = try await self.patientsMedicalRecordSync.resolveMedicalRecordConflict(outbound1)
        return Acme_Patients_V1_ExpireAllergyResponse.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.allergyID = input.allergyID
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = input.details.newOwner.displayName
                }
            }
            $0.outcome = Acme_Patients_V1_ExpireAllergyResponse.Outcome.with {
                $0.effectiveAt = reply0.outcome.effectiveAt
                $0.message = reply1.outcome.message
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply1.outcome.status
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processGetAllergyLifecycle(_ input: Acme_Patients_V1_GetAllergyLifecycleRequest) async throws
        -> Acme_Patients_V1_GetAllergyLifecycleResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "GetAllergyLifecycle",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "GetAllergyLifecycle", detail: input.context.traceID
        )
        let outbound0 = Acme_Identity_V1_BatchGetUsersRequest.with {
            $0.context = input.context
        }
        let reply0 = try await RPCOperations.read {
            try await self.identityUser.batchGetUsers(outbound0)
        }
        return Acme_Patients_V1_GetAllergyLifecycleResponse.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.allergyID = input.allergyID
                $0.correlationID = reply0.result.correlationID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply0.result.status
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processReinstateAllergy(_ input: Acme_Patients_V1_ReinstateAllergyRequest) async throws
        -> Acme_Patients_V1_ReinstateAllergyResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "audit", detail: input.details.newOwner.email
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ReinstateAllergy",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "ReinstateAllergy", detail: input.context.traceID
        )
        let outbound0 = Acme_Prescriptions_V1_ResolveMedicationConflictRequest.with {
            $0.annotations = input.annotations
            $0.context = input.context
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.details.newOwner.displayName
                    $0.email = input.details.notifyContact.email
                }
            }
        }
        let reply0 = try await self.prescriptionsMedicationSync.resolveMedicationConflict(outbound0)
        let selection1_1: String
        switch reply0.medication.locator {
        case .address(let address):
            selection1_1 = address.region
        default: selection1_1 = .init()
        }
        let outbound1 = Acme_Patients_V1_ListMedicalRecordConflictsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Patients_V1_ListMedicalRecordConflictsRequest.Filter.with {
                $0.createdAfter = reply0.medication.audit.createdAt
                $0.ownerID = reply0.medication.components["primary", default: .init()].componentID
                $0.region = selection1_1
            }
        }
        let reply1 = try await self.patientsMedicalRecordSync.listMedicalRecordConflicts(outbound1)
        return Acme_Patients_V1_ReinstateAllergyResponse.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.allergyID = input.allergyID
            }
            $0.outcome = Acme_Patients_V1_ReinstateAllergyResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
                $0.status = reply1.result.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.status = reply1.result.status
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processRenewAllergy(_ input: Acme_Patients_V1_RenewAllergyRequest) async throws
        -> Acme_Patients_V1_RenewAllergyResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "audit", detail: input.details.newOwner.email
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "RenewAllergy",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "RenewAllergy", detail: input.context.traceID
        )
        let outbound0 = Acme_Localization_V1_QuoteTranslationKeyRequest.with {
            $0.context = input.context
            $0.translationKey = Acme_Localization_V1_TranslationKey.with {
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.details.newOwner.displayName
                    $0.email = input.details.notifyContact.email
                }
            }
        }
        async let remote0 = self.localizationTranslationKeyCalculation.quoteTranslationKey(outbound0)
        async let persisted0 = store.count(tenant: input.context.tenantID)
        let (reply0, count0) = try await (remote0, persisted0)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count0)])
        let outbound1 = Acme_Documents_V1_PreviewDocumentRequest.with {
            $0.context = input.context
            $0.document = Acme_Documents_V1_Document.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply0.translationKey.audit.createdBy
                }
            }
        }
        let reply1 = try await self.renewAllergyStep1.execute(outbound1)
        return Acme_Patients_V1_RenewAllergyResponse.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.allergyID = input.allergyID
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = reply0.translationKey.owner.displayName
                }
            }
            $0.outcome = Acme_Patients_V1_RenewAllergyResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
                $0.status = reply1.result.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.details = reply0.result.details
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processScheduleAllergyExpiry(_ input: Acme_Patients_V1_ScheduleAllergyExpiryRequest) async throws
        -> Acme_Patients_V1_ScheduleAllergyExpiryResponse
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
            "ScheduleAllergyExpiry",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try AllergyRecord(input.allergy, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Careplans_V1_ResumeCarePlanWorkflowRequest.with {
            $0.context = input.context
            $0.details = Acme_Careplans_V1_ResumeCarePlanWorkflowRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.allergy.subject.email
                    $0.phone = input.details.notify.phone
                }
            }
        }
        let port0 = RPCOperations.port { (request: Acme_Careplans_V1_ResumeCarePlanWorkflowRequest) in
            try await self.careplansCarePlanWorkflow.resumeCarePlanWorkflow(request)
        }
        let reply0 = try await port0.execute(outbound0)
        let outbound1 = Acme_Patients_V1_PushPatientRequest.with {
            $0.context = input.context
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.locality = reply0.carePlan.billingAddress.locality
                }
            }
        }
        let reply1 = try await self.scheduleAllergyExpiryStep1(outbound1)
        return Acme_Patients_V1_ScheduleAllergyExpiryResponse.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.allergyID = input.allergyID
                $0.sequence = input.allergy.sequence
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply0.result.referenceIds
                $0.status = reply1.outcome.status
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processSuspendAllergy(_ input: Acme_Patients_V1_SuspendAllergyRequest) async throws
        -> Acme_Patients_V1_SuspendAllergyResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "audit", detail: input.details.newOwner.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SuspendAllergy",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "SuspendAllergy", detail: input.context.traceID
        )
        let outbound0 = Acme_Patients_V1_ShareMedicalRecordReportRequest.with {
            $0.context = input.context
            $0.details = Acme_Patients_V1_ShareMedicalRecordReportRequest.Details.with {
                $0.recipient = Acme_Common_V1_ContactInfo.with {
                    $0.name = input.details.notifyContact.name
                }
            }
        }
        guard let execute0 = self.suspendAllergyStep0[settings.region] ?? self.suspendAllergyStep0["primary"] else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply0 = try await execute0(outbound0)
        let outbound1 = Acme_Patients_V1_QuotePatientRequest.with {
            $0.context = input.context
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply0.medicalRecord.audit.updatedBy
                }
            }
        }
        let reply1 = try await self.patientsPatientCalculation.quotePatient(outbound1)
        let outbound2 = Acme_Localization_V1_CalculateTranslationKeyRequest.with {
            $0.context = input.context
            $0.translationKey = Acme_Localization_V1_TranslationKey.with {
                $0.address = Acme_Common_V1_PostalAddress.with {
                    $0.locality = reply0.medicalRecord.billingAddress.locality
                    $0.region = reply0.medicalRecord.billingAddress.region
                }
            }
        }
        let envelope2 = try Google_Protobuf_Any(message: outbound2)
        let unpacked2 = try Acme_Localization_V1_CalculateTranslationKeyRequest(unpackingAny: envelope2)
        let reply2 = try await self.localizationTranslationKeyCalculation.calculateTranslationKey(unpacked2)
        return Acme_Patients_V1_SuspendAllergyResponse.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.allergyID = input.allergyID
                $0.attributes = reply1.patient.attributes
                $0.measurements = [
                    Acme_Patients_V1_AllergyMeasurement.with {
                        $0.unit = reply2.translationKey.dimensions.unit
                    }
                ]
            }
            $0.outcome = Acme_Patients_V1_SuspendAllergyResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
                $0.message = reply2.result.message
                $0.nextSteps = reply0.outcome.nextSteps
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processTerminateAllergy(_ input: Acme_Patients_V1_TerminateAllergyRequest) async throws
        -> Acme_Patients_V1_TerminateAllergyResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "audit", detail: input.details.newOwner.email
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "TerminateAllergy",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "TerminateAllergy", detail: input.context.traceID
        )
        let outbound0 = Acme_Patients_V1_ResolveMedicalRecordConflictRequest.with {
            $0.context = input.context
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = input.details.newOwner.displayName
                }
            }
        }
        let json0 = try outbound0.jsonString()
        let decoded0 = try Acme_Patients_V1_ResolveMedicalRecordConflictRequest(jsonString: json0)
        let reply0 = try await self.patientsMedicalRecordSync.resolveMedicalRecordConflict(decoded0)
        let outbound1 = Acme_Identity_V1_CreateUserRequest.forAllergyLifecycleEndpointTerminateAllergy1(
            input,
            reply0: reply0
        )
        let reply1 = try await self.identityUser.createUser(outbound1)
        let outbound2 = Acme_Careplans_V1_ListCarePlanWorkflowsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Careplans_V1_ListCarePlanWorkflowsRequest.Filter.with {
                $0.createdAfter = reply1.user.audit.updatedAt
                $0.labels = reply0.medicalRecord.metadata
                $0.ownerID = input.details.newOwner.userID
                $0.region = reply1.user.primaryAddress.region
            }
        }
        let reply2 = try await self.careplansCarePlanWorkflow.listCarePlanWorkflows(
            outbound2, metadata: ["x-acme-region": .string(settings.region)]
        )
        return Acme_Patients_V1_TerminateAllergyResponse.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.allergyID = input.allergyID
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.email = reply1.user.contact.email
                }
            }
            $0.outcome = Acme_Patients_V1_TerminateAllergyResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
                $0.referenceID = reply0.outcome.referenceID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply2.result.message
                $0.referenceIds = reply1.result.referenceIds
                $0.status = "ok"
            }
        }
    }
}
