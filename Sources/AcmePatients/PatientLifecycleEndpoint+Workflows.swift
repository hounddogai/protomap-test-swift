import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension PatientLifecycleEndpoint {
    /// Execute the patients workflow and project its upstream replies.
    func processActivatePatient(_ input: Acme_Patients_V1_ActivatePatientRequest) async throws
        -> Acme_Patients_V1_ActivatePatientResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "audit", detail: input.details.newOwner.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ActivatePatient",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "ActivatePatient", detail: input.context.traceID
        )
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        let importFrame = Acme_Patients_V1_StreamPatientChangesRequest.with {
            $0.context = input.context
        }
        _ = try await self.patientsPatientSync.streamPatientChanges { writer in
            try await writer.write(importFrame)
        } onResponse: { response in
            var latest = Acme_Patients_V1_StreamPatientChangesResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        let outbound0 = Acme_Metrics_V1_CheckMetricSeriesEligibilityRequest.with {
            $0.context = input.context
            $0.details = Acme_Metrics_V1_CheckMetricSeriesEligibilityRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.name = input.details.notifyContact.name
                }
            }
            $0.metricSeries = Acme_Metrics_V1_MetricSeries.with {
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.email = input.details.notifyContact.email
                }
            }
        }
        let reply0 = try await self.metricsMetricSeriesValidation.checkMetricSeriesEligibility(
            outbound0, metadata: ["x-acme-region": .string(settings.region)]
        )
        return Acme_Patients_V1_ActivatePatientResponse.with {
            $0.outcome = Acme_Patients_V1_ActivatePatientResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
            }
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply0.metricSeries.owner.email
                }
                $0.patientID = input.patientID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply0.outcome.status
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processExpirePatient(_ input: Acme_Patients_V1_ExpirePatientRequest) async throws
        -> Acme_Patients_V1_ExpirePatientResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.userID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "audit", detail: input.details.newOwner.userID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ExpirePatient",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "ExpirePatient", detail: input.context.traceID
        )
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        let outbound0 = Acme_Patients_V1_SyncPatientsRequest.with {
            $0.context = input.context
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.newOwner.email
                    $0.name = input.details.notifyContact.name
                    $0.preferredChannel = input.details.notifyContact.preferredChannel
                }
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.details.newOwner.displayName
                }
            }
        }
        let reply0 = try await RPCOperations.call(outbound0) { request in
            try await self.patientsPatientSync.syncPatients(request)
        }
        let selection1_2: String
        switch reply0.patient.identityDocument {
        case .nationalID(let nationalID):
            selection1_2 = nationalID.number
        default: selection1_2 = .init()
        }
        let outbound1 = Acme_Patients_V1_PushMedicalRecordRequest.with {
            $0.context = input.context
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply0.patient.audit.updatedBy
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.locality = reply0.patient.primaryAddress.locality
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.email = input.details.newOwner.email
                }
                $0.number = selection1_2
            }
        }
        let reply1 = try await self.patientsMedicalRecordSync.pushMedicalRecord(outbound1)
        let outbound2 = Acme_Patients_V1_ExplainMedicalRecordDecisionRequest.with {
            $0.context = Projection.read(input, at: \Acme_Patients_V1_ExpirePatientRequest.context)
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.lines = reply1.medicalRecord.billingAddress.lines
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.email = Projection.read(
                        reply0, at: \Acme_Patients_V1_SyncPatientsResponse.patient.relationshipManager.email)
                }
            }
        }
        let reply2 = try await self.patientsMedicalRecordValidation.explainMedicalRecordDecision(outbound2)
        let selection3_1: String
        switch reply0.patient.identityDocument {
        case .passport(let passport):
            selection3_1 = passport.number
        default: selection3_1 = .init()
        }
        let outbound3 = Acme_Patients_V1_NormalizePatientRequest.with {
            $0.context = input.context
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply1.medicalRecord.audit.createdAt
                }
                $0.nationalID = Acme_Patients_V1_PatientNationalId.with {
                    $0.number = selection3_1
                }
            }
        }
        let reply3 = try await self.patientsPatientValidation.normalizePatient(outbound3)
        return Acme_Patients_V1_ExpirePatientResponse.with {
            $0.outcome = Acme_Patients_V1_ExpirePatientResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
                $0.message = reply0.outcome.message
                $0.status = reply3.outcome.status
            }
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply2.medicalRecord.audit.createdBy
                }
                $0.patientID = input.patientID
                $0.preferences = Acme_Patients_V1_PatientPreferences.with {
                    $0.language = reply0.patient.preferences.language
                }
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply2.medicalRecord.counterparty.displayName
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply1.result.details
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processRenewPatient(_ input: Acme_Patients_V1_RenewPatientRequest) async throws
        -> Acme_Patients_V1_RenewPatientResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "audit", detail: input.details.newOwner.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "RenewPatient",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "RenewPatient", detail: input.context.traceID
        )
        let outbound0 = Acme_Patients_V1_ListAllergyImportsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Patients_V1_ListAllergyImportsRequest.Filter.with {
                $0.createdAfter = input.details.effectiveAt
                $0.labels = input.annotations
                $0.ownerID = input.details.newOwner.userID
            }
        }
        let step0: @Sendable () async throws -> Acme_Patients_V1_ListAllergyImportsResponse = {
            try await self.patientsAllergyImport.listAllergyImports(outbound0)
        }
        let reply0 = try await step0()
        return Acme_Patients_V1_RenewPatientResponse.with {
            $0.outcome = Acme_Patients_V1_RenewPatientResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
            }
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.patientID = input.patientID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.message = reply0.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processSchedulePatientExpiry(_ input: Acme_Patients_V1_SchedulePatientExpiryRequest) async throws
        -> Acme_Patients_V1_SchedulePatientExpiryResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "audit", detail: input.details.initiatedBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SchedulePatientExpiry",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PatientRecord(input.patient, tenant: input.context.tenantID)
        try await store.save(record.stored)
        var outbound0 = Acme_Careplans_V1_RejectVitalRequest()
        outbound0.context = input.context
        outbound0.details = Acme_Careplans_V1_RejectVitalRequest.Details.with {
            $0.approver = Acme_Identity_V1_UserRef.with {
                $0.email = input.patient.contact.email
                $0.userID = input.patient.relationshipManager.userID
            }
        }
        outbound0.vital = Acme_Careplans_V1_Vital.with {
            $0.attributes = input.patient.attributes
            $0.subject = Acme_Appointments_V1_AppointmentRef.with {
                $0.displayName = input.patient.relationshipManager.displayName
            }
        }
        let reply0 = try await self.careplansVitalApproval.rejectVital(outbound0)
        let outbound1 = Acme_Patients_V1_ReconcileAllergiesRequest.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.email = input.patient.contact.email
                }
            }
            $0.context = input.context
        }
        let step1: @Sendable () async throws -> Acme_Patients_V1_ReconcileAllergiesResponse = {
            try await self.patientsAllergySync.reconcileAllergies(outbound1)
        }
        let reply1 = try await step1()
        let outbound2 = Acme_Featureflags_V1_CheckFeatureFlagEligibilityRequest.with {
            $0.context = input.context
            $0.details = Acme_Featureflags_V1_CheckFeatureFlagEligibilityRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.phone = input.details.notify.phone
                }
            }
            $0.featureFlag = Acme_Featureflags_V1_FeatureFlag.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = input.patient.audit.createdBy
                }
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.patient.relationshipManager.userID
                }
            }
        }
        let reply2 = try await self.featureflagsFeatureFlagValidation.checkFeatureFlagEligibility(outbound2)
        let outbound3 = Acme_Budgeting_V1_ResolveBudgetsRequest.with {
            $0.context = input.context
        }
        async let remote3 = self.budgetingBudgetQuery.resolveBudgets(outbound3)
        async let persisted3 = store.count(tenant: input.context.tenantID)
        let (reply3, count3) = try await (remote3, persisted3)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count3)])
        return Acme_Patients_V1_SchedulePatientExpiryResponse.with {
            $0.outcome = Acme_Patients_V1_SchedulePatientExpiryResponse.Outcome.with {
                $0.status = reply3.result.status
            }
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply2.featureFlag.audit.createdBy
                    $0.updatedAt = reply2.featureFlag.audit.updatedAt
                }
                $0.patientID = input.patientID
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply0.vital.subject.displayName
                }
                $0.status = input.patient.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply1.outcome.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processSuspendPatient(_ input: Acme_Patients_V1_SuspendPatientRequest) async throws
        -> Acme_Patients_V1_SuspendPatientResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.notifyContact.preferredChannel)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "audit", detail: input.details.notifyContact.preferredChannel
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SuspendPatient",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "SuspendPatient", detail: input.context.traceID
        )
        let outbound0 = Acme_Metrics_V1_ValidateMetricSeriesRequest.with {
            $0.context = input.context
            $0.metricSeries = Acme_Metrics_V1_MetricSeries.with {
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.details.newOwner.userID
                }
            }
        }
        let reply0 = try await self.suspendPatientStep0.execute(outbound0)
        let outbound1 = Acme_Patients_V1_SchedulePatientReportRequest.with {
            $0.annotations = input.annotations
            $0.context = input.context
            $0.patientID = input.patientID
            $0.reason = input.reason
        }
        let port1 = RPCOperations.port { (request: Acme_Patients_V1_SchedulePatientReportRequest) in
            try await self.patientsPatientReporting.schedulePatientReport(request)
        }
        let reply1 = try await port1.execute(outbound1)
        let outbound2 = Acme_Patients_V1_MapAllergyImportColumnsRequest.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = input.details.newOwner.displayName
                    $0.email = input.details.notifyContact.email
                }
            }
            $0.context = input.context
            $0.details = Acme_Patients_V1_MapAllergyImportColumnsRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.newOwner.email
                    $0.phone = input.details.notifyContact.phone
                }
            }
        }
        let reply2 = try await self.suspendPatientStep2(outbound2)
        return Acme_Patients_V1_SuspendPatientResponse.with {
            $0.outcome = Acme_Patients_V1_SuspendPatientResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
                $0.status = reply1.result.status
            }
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply0.metricSeries.audit.etag
                }
                $0.patientID = input.patientID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.status = reply2.result.status
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processTerminatePatient(_ input: Acme_Patients_V1_TerminatePatientRequest) async throws
        -> Acme_Patients_V1_TerminatePatientResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.notifyContact.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "audit", detail: input.details.notifyContact.email
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "TerminatePatient",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "TerminatePatient", detail: input.context.traceID
        )
        let outbound0 = Acme_Featureflags_V1_SuggestFeatureFlagsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Featureflags_V1_SuggestFeatureFlagsRequest.Filter.with {
                $0.createdAfter = input.details.effectiveAt
                $0.ownerID = input.details.newOwner.userID
            }
        }
        guard let execute0 = self.terminatePatientStep0[settings.region] ?? self.terminatePatientStep0["primary"] else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply0 = try await execute0(outbound0)
        let outbound1 = Acme_Search_V1_ResolveSearchIndexesRequest.with {
            $0.context = input.context
        }
        let reply1 = try await self.searchSearchIndexQuery.resolveSearchIndexes(outbound1)
        let outbound2 = Acme_Patients_V1_SyncMedicalRecordsRequest.with {
            $0.context = input.context
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = input.details.newOwner.displayName
                    $0.email = input.details.newOwner.email
                }
            }
        }
        let envelope2 = try Google_Protobuf_Any(message: outbound2)
        let unpacked2 = try Acme_Patients_V1_SyncMedicalRecordsRequest(unpackingAny: envelope2)
        let reply2 = try await self.patientsMedicalRecordSync.syncMedicalRecords(unpacked2)
        return Acme_Patients_V1_TerminatePatientResponse.with {
            $0.outcome = Acme_Patients_V1_TerminatePatientResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
                $0.message = reply2.outcome.message
            }
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.patientID = input.patientID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply1.result.message
                $0.status = reply0.result.status
            }
        }
    }
}
