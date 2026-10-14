import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension MedicalRecordLifecycleEndpoint {
    /// Activates a medical record.
    func activateMedicalRecord(
        request: ServerRequest<Acme_Patients_V1_ActivateMedicalRecordRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_ActivateMedicalRecordResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processActivateMedicalRecord(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Expires a medical record.
    func expireMedicalRecord(
        request: ServerRequest<Acme_Patients_V1_ExpireMedicalRecordRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_ExpireMedicalRecordResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processExpireMedicalRecord(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a medical record.
    func getMedicalRecordLifecycle(
        request: ServerRequest<Acme_Patients_V1_GetMedicalRecordLifecycleRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_GetMedicalRecordLifecycleResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetMedicalRecordLifecycle(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Reinstates a medical record.
    func reinstateMedicalRecord(
        request: ServerRequest<Acme_Patients_V1_ReinstateMedicalRecordRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_ReinstateMedicalRecordResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processReinstateMedicalRecord(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Renews a medical record.
    func renewMedicalRecord(
        request: ServerRequest<Acme_Patients_V1_RenewMedicalRecordRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_RenewMedicalRecordResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRenewMedicalRecord(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Suspends a medical record.
    func suspendMedicalRecord(
        request: ServerRequest<Acme_Patients_V1_SuspendMedicalRecordRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_SuspendMedicalRecordResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSuspendMedicalRecord(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Terminates a medical record.
    func terminateMedicalRecord(
        request: ServerRequest<Acme_Patients_V1_TerminateMedicalRecordRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_TerminateMedicalRecordResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processTerminateMedicalRecord(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processActivateMedicalRecord(_ input: Acme_Patients_V1_ActivateMedicalRecordRequest) async throws
        -> Acme_Patients_V1_ActivateMedicalRecordResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "audit", detail: input.details.newOwner.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ActivateMedicalRecord",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "ActivateMedicalRecord", detail: input.context.traceID
        )
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        let archive = Data(try input.context.jsonString().utf8)
        let restoredContext = try Acme_Common_V1_RequestContext(
            jsonString: String(decoding: archive, as: UTF8.self)
        )
        _ = try await self.patientsAllergySync.pushAllergy(
            Acme_Patients_V1_PushAllergyRequest.with {
                $0.context = restoredContext
                $0.details = Acme_Patients_V1_PushAllergyRequest.Details.with {
                    $0.payload = archive
                }
            })
        let outbound0 = Acme_Documents_V1_PreviewDocumentRequest.with {
            $0.context = input.context
            $0.details = Acme_Documents_V1_PreviewDocumentRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.newOwner.email
                }
            }
        }
        let port0 = RPCOperations.port { (request: Acme_Documents_V1_PreviewDocumentRequest) in
            try await self.documentsDocumentValidation.previewDocument(request)
        }
        let reply0 = try await port0.execute(outbound0)
        let outbound1 = Acme_Featureflags_V1_ExplainFeatureFlagDecisionRequest.with {
            $0.context = input.context
            $0.details = Acme_Featureflags_V1_ExplainFeatureFlagDecisionRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.newOwner.email
                }
            }
        }
        let reply1 = try await self.activateMedicalRecordStep1(outbound1)
        return Acme_Patients_V1_ActivateMedicalRecordResponse.with {
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.lines = reply0.document.billingAddress.lines
                }
                $0.dueAt = reply0.document.dueAt
                $0.medicalRecordID = input.medicalRecordID
            }
            $0.outcome = Acme_Patients_V1_ActivateMedicalRecordResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply1.outcome.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processExpireMedicalRecord(_ input: Acme_Patients_V1_ExpireMedicalRecordRequest) async throws
        -> Acme_Patients_V1_ExpireMedicalRecordResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "audit", detail: input.details.newOwner.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ExpireMedicalRecord",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "ExpireMedicalRecord", detail: input.context.traceID
        )
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        let outbound0 = Acme_Prescriptions_V1_ShareRefillReportRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_ShareRefillReportRequest.Details.with {
                $0.recipient = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.newOwner.email
                    $0.name = input.details.notifyContact.name
                    $0.phone = input.details.notifyContact.phone
                    $0.preferredChannel = input.details.notifyContact.preferredChannel
                }
            }
        }
        guard let execute0 = self.expireMedicalRecordStep0[settings.region] ?? self.expireMedicalRecordStep0["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply0 = try await execute0(outbound0)
        let outbound1 = Acme_Patients_V1_CountMedicalRecordTotalsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Patients_V1_CountMedicalRecordTotalsRequest.Filter.with {
                $0.createdAfter = input.details.effectiveAt
                $0.ownerID = input.details.newOwner.userID
            }
        }
        let reply1 = try await self.patientsMedicalRecordReporting.countMedicalRecordTotals(outbound1)
        return Acme_Patients_V1_ExpireMedicalRecordResponse.with {
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.email = reply0.refill.assignee.email
                }
                $0.medicalRecordID = input.medicalRecordID
            }
            $0.outcome = Acme_Patients_V1_ExpireMedicalRecordResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.referenceIds = reply1.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processGetMedicalRecordLifecycle(_ input: Acme_Patients_V1_GetMedicalRecordLifecycleRequest) async throws
        -> Acme_Patients_V1_GetMedicalRecordLifecycleResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "GetMedicalRecordLifecycle",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "GetMedicalRecordLifecycle", detail: input.context.traceID
        )
        let outbound0 = Acme_Patients_V1_ListAllergyConflictsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Patients_V1_ListAllergyConflictsRequest.Filter.with {
                $0.createdAfter = input.context.deadline
                $0.ownerID = input.medicalRecordID
            }
        }
        let envelope0 = try Google_Protobuf_Any(message: outbound0)
        let unpacked0 = try Acme_Patients_V1_ListAllergyConflictsRequest(unpackingAny: envelope0)
        let reply0 = try await self.patientsAllergySync.listAllergyConflicts(unpacked0)
        return Acme_Patients_V1_GetMedicalRecordLifecycleResponse.with {
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.medicalRecordID = input.medicalRecordID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processReinstateMedicalRecord(_ input: Acme_Patients_V1_ReinstateMedicalRecordRequest) async throws
        -> Acme_Patients_V1_ReinstateMedicalRecordResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "audit", detail: input.details.newOwner.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ReinstateMedicalRecord",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "ReinstateMedicalRecord", detail: input.context.traceID
        )
        let outbound0 = Acme_Metrics_V1_SummarizeMetricSeriesesRequest.with {
            $0.annotations = input.annotations
            $0.context = input.context
            $0.reason = input.reason
        }
        let json0 = try outbound0.jsonString()
        let decoded0 = try Acme_Metrics_V1_SummarizeMetricSeriesesRequest(jsonString: json0)
        let reply0 = try await self.metricsMetricSeriesQuery.summarizeMetricSerieses(decoded0)
        let outbound1 =
            Acme_Prescriptions_V1_ListMedicationReportsRequest.forMedicalRecordLifecycleEndpointReinstateMedicalRecord1(
                input
            )
        let reply1 = try await self.prescriptionsMedicationReporting.listMedicationReports(outbound1)
        return Acme_Patients_V1_ReinstateMedicalRecordResponse.with {
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.medicalRecordID = input.medicalRecordID
            }
            $0.outcome = Acme_Patients_V1_ReinstateMedicalRecordResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
                $0.status = reply0.result.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processRenewMedicalRecord(_ input: Acme_Patients_V1_RenewMedicalRecordRequest) async throws
        -> Acme_Patients_V1_RenewMedicalRecordResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "audit", detail: input.details.newOwner.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "RenewMedicalRecord",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "RenewMedicalRecord", detail: input.context.traceID
        )
        let outbound0 = Acme_Patients_V1_BatchGetPatientsRequest.with {
            $0.context = input.context
        }
        let reply0 = try await self.patientsPatient.batchGetPatients(
            outbound0, metadata: ["x-acme-region": .string(settings.region)]
        )
        return Acme_Patients_V1_RenewMedicalRecordResponse.with {
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.medicalRecordID = input.medicalRecordID
            }
            $0.outcome = Acme_Patients_V1_RenewMedicalRecordResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
                $0.message = reply0.result.message
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processSuspendMedicalRecord(_ input: Acme_Patients_V1_SuspendMedicalRecordRequest) async throws
        -> Acme_Patients_V1_SuspendMedicalRecordResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "audit", detail: input.details.newOwner.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SuspendMedicalRecord",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "SuspendMedicalRecord", detail: input.context.traceID
        )
        let outbound0 = Acme_Documents_V1_NormalizeDocumentRequest.with {
            $0.context = input.context
            $0.details = Acme_Documents_V1_NormalizeDocumentRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.preferredChannel = input.details.notifyContact.preferredChannel
                }
            }
        }
        let reply0 = try await RPCOperations.call(outbound0) { request in
            try await self.documentsDocumentValidation.normalizeDocument(request)
        }
        return Acme_Patients_V1_SuspendMedicalRecordResponse.with {
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.recipient = reply0.document.billingAddress.recipient
                }
                $0.medicalRecordID = input.medicalRecordID
            }
            $0.outcome = Acme_Patients_V1_SuspendMedicalRecordResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processTerminateMedicalRecord(_ input: Acme_Patients_V1_TerminateMedicalRecordRequest) async throws
        -> Acme_Patients_V1_TerminateMedicalRecordResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "audit", detail: input.details.newOwner.email
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "TerminateMedicalRecord",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "TerminateMedicalRecord", detail: input.context.traceID
        )
        let outbound0 = Acme_Careplans_V1_StartCarePlanWorkflowRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.counterparty = Acme_Appointments_V1_AppointmentRef.with {
                    $0.displayName = Projection.read(
                        input, at: \Acme_Patients_V1_TerminateMedicalRecordRequest.details.newOwner.displayName)
                }
            }
            $0.context = Projection.read(input, at: \Acme_Patients_V1_TerminateMedicalRecordRequest.context)
            $0.details = Acme_Careplans_V1_StartCarePlanWorkflowRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.email = Projection.read(
                        input, at: \Acme_Patients_V1_TerminateMedicalRecordRequest.details.notifyContact.email)
                    $0.name = Projection.read(
                        input, at: \Acme_Patients_V1_TerminateMedicalRecordRequest.details.notifyContact.name)
                    $0.preferredChannel = Projection.read(
                        input,
                        at: \Acme_Patients_V1_TerminateMedicalRecordRequest.details.notifyContact.preferredChannel)
                }
            }
        }
        let reply0 = try await self.careplansCarePlanWorkflow.startCarePlanWorkflow(outbound0)
        return Acme_Patients_V1_TerminateMedicalRecordResponse.with {
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.medicalRecordID = input.medicalRecordID
            }
            $0.outcome = Acme_Patients_V1_TerminateMedicalRecordResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
                $0.nextSteps = reply0.outcome.nextSteps
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }
}
