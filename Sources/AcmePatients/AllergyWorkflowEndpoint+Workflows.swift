import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension AllergyWorkflowEndpoint {
    /// Advances an allergy.
    func advanceAllergyWorkflow(
        request: ServerRequest<Acme_Patients_V1_AdvanceAllergyWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_AdvanceAllergyWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processAdvanceAllergyWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Cancels an allergy.
    func cancelAllergyWorkflow(
        request: ServerRequest<Acme_Patients_V1_CancelAllergyWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_CancelAllergyWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCancelAllergyWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns an allergy.
    func inspectAllergyWorkflow(
        request: ServerRequest<Acme_Patients_V1_InspectAllergyWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_InspectAllergyWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processInspectAllergyWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists allergies a page at a time.
    func listAllergyWorkflows(
        request: ServerRequest<Acme_Patients_V1_ListAllergyWorkflowsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_ListAllergyWorkflowsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListAllergyWorkflows(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Pauses an allergy.
    func pauseAllergyWorkflow(
        request: ServerRequest<Acme_Patients_V1_PauseAllergyWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_PauseAllergyWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processPauseAllergyWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Resumes an allergy.
    func resumeAllergyWorkflow(
        request: ServerRequest<Acme_Patients_V1_ResumeAllergyWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_ResumeAllergyWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processResumeAllergyWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Retrys an allergy.
    func retryAllergyWorkflow(
        request: ServerRequest<Acme_Patients_V1_RetryAllergyWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_RetryAllergyWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRetryAllergyWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Signals an allergy.
    func signalAllergyWorkflow(
        request: ServerRequest<Acme_Patients_V1_SignalAllergyWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_SignalAllergyWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSignalAllergyWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Starts an allergy.
    func startAllergyWorkflow(
        request: ServerRequest<Acme_Patients_V1_StartAllergyWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_StartAllergyWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processStartAllergyWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processAdvanceAllergyWorkflow(_ input: Acme_Patients_V1_AdvanceAllergyWorkflowRequest) async throws
        -> Acme_Patients_V1_AdvanceAllergyWorkflowResponse
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
            "AdvanceAllergyWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try AllergyRecord(input.allergy, tenant: input.context.tenantID)
        try await store.save(record.stored)
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        try followUps.submit(
            Acme_Identity_V1_GetUserRequest.with {
                $0.context = input.context
                $0.userID = input.context.actor.userID
            })
        let archive = Data(try input.context.jsonString().utf8)
        let restoredContext = try Acme_Common_V1_RequestContext(
            jsonString: String(decoding: archive, as: UTF8.self)
        )
        _ = try await self.prescriptionsRefillSync.resolveRefillConflict(
            Acme_Prescriptions_V1_ResolveRefillConflictRequest.with {
                $0.context = restoredContext
                $0.details = Acme_Prescriptions_V1_ResolveRefillConflictRequest.Details.with {
                    $0.payload = archive
                }
            })
        let requests0 = input.allergy.measurements.map { element in
            Acme_Patients_V1_ListMedicalRecordReportsRequest.with {
                $0.context = input.context
                $0.filter = Acme_Patients_V1_ListMedicalRecordReportsRequest.Filter.with {
                    $0.createdAfter = element.observedAt
                    $0.labels = input.details.parameters
                }
            }
        }
        let replies0 = try await FanOut.map(requests0) { candidate in
            try await self.patientsMedicalRecordReporting.listMedicalRecordReports(candidate)
        }
        let reply0 = replies0.first ?? Acme_Patients_V1_ListMedicalRecordReportsResponse()
        _ = reply0
        let requests1 = input.allergy.measurements.map { element in
            Acme_Benefits_V1_SearchBenefitPlansRequest.with {
                $0.context = input.context
                $0.filter = Acme_Benefits_V1_SearchBenefitPlansRequest.Filter.with {
                    $0.createdAfter = element.observedAt
                    $0.labels = input.allergy.attributes
                    $0.ownerID = input.allergy.subject.patientID
                }
            }
        }
        let replies1 = try await FanOut.map(requests1) { candidate in
            try await self.benefitsBenefitPlan.searchBenefitPlans(candidate)
        }
        let reply1 = replies1.first ?? Acme_Benefits_V1_SearchBenefitPlansResponse()
        _ = reply1
        let requests2 = input.allergy.measurements.map { element in
            Acme_Audit_V1_CountAuditEventsRequest.with {
                $0.context = input.context
                $0.filter = Acme_Audit_V1_CountAuditEventsRequest.Filter.with {
                    $0.createdAfter = element.observedAt
                    $0.ownerID = input.allergy.correlationID
                }
            }
        }
        let replies2 = try await FanOut.map(requests2) { candidate in
            try await self.auditAuditEventQuery.countAuditEvents(candidate)
        }
        let reply2 = replies2.first ?? Acme_Audit_V1_CountAuditEventsResponse()
        _ = reply2
        let outbound3 = Acme_Patients_V1_SimulateAllergyRequest.forAllergyWorkflowEndpointAdvanceAllergyWorkflow3(
            input
        )
        let reply3 = try await self.patientsAllergyCalculation.simulateAllergy(outbound3)
        return Acme_Patients_V1_AdvanceAllergyWorkflowResponse.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.allergyID = reply3.allergy.allergyID
                $0.attributes = reply3.allergy.attributes
                $0.correlationID = input.allergy.correlationID
                $0.source = input.allergy.source
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processCancelAllergyWorkflow(_ input: Acme_Patients_V1_CancelAllergyWorkflowRequest) async throws
        -> Acme_Patients_V1_CancelAllergyWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.allergy.correlationID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "audit", detail: input.allergy.correlationID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "CancelAllergyWorkflow",
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
        let outbound0 = Acme_Patients_V1_GetAllergyImportStatusRequest.with {
            $0.allergyID = input.allergy.allergyID
            $0.context = input.context
        }
        let reply0 = try await self.patientsAllergyImport.getAllergyImportStatus(
            outbound0, metadata: ["x-acme-region": .string(settings.region)]
        )
        let outbound1 = Acme_Documents_V1_ValidateDocumentRequest.with {
            $0.context = input.context
            $0.details = Acme_Documents_V1_ValidateDocumentRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.notify.email
                    $0.preferredChannel = input.details.notify.preferredChannel
                }
            }
            $0.document = Acme_Documents_V1_Document.with {
                $0.counterparty = Acme_Documents_V1_DocumentFolderRef.with {
                    $0.displayName = reply0.allergy.subject.displayName
                }
                $0.lines = [
                    Acme_Documents_V1_DocumentLine.with {
                        $0.attributes = input.allergy.attributes
                    }
                ]
            }
        }
        let reply1 = try await RPCOperations.call(outbound1) { request in
            try await self.documentsDocumentValidation.validateDocument(request)
        }
        let outbound2 = Acme_Patients_V1_ShareMedicalRecordReportRequest.with {
            $0.context = Projection.read(input, at: \Acme_Patients_V1_CancelAllergyWorkflowRequest.context)
            $0.details = Acme_Patients_V1_ShareMedicalRecordReportRequest.Details.with {
                $0.recipient = Acme_Common_V1_ContactInfo.with {
                    $0.email = Projection.read(
                        input, at: \Acme_Patients_V1_CancelAllergyWorkflowRequest.details.notify.email)
                    $0.name = Projection.read(
                        input, at: \Acme_Patients_V1_CancelAllergyWorkflowRequest.details.notify.name)
                    $0.phone = Projection.read(
                        input, at: \Acme_Patients_V1_CancelAllergyWorkflowRequest.details.notify.phone)
                }
            }
        }
        let reply2 = try await self.patientsMedicalRecordReporting.shareMedicalRecordReport(outbound2)
        let outbound3 = Acme_Patients_V1_RetryAllergyImportRequest.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = reply1.document.counterparty.displayName
                    $0.email = reply0.allergy.subject.email
                }
            }
            $0.context = input.context
            $0.details = Acme_Patients_V1_RetryAllergyImportRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply2.medicalRecord.counterparty.email
                }
            }
        }
        let step3: @Sendable () async throws -> Acme_Patients_V1_RetryAllergyImportResponse = {
            try await self.patientsAllergyImport.retryAllergyImport(outbound3)
        }
        let reply3 = try await step3()
        return Acme_Patients_V1_CancelAllergyWorkflowResponse.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.allergyID = input.allergyID
                $0.kind = reply0.allergy.kind
                $0.sequence = input.allergy.sequence
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = reply0.allergy.subject.displayName
                }
            }
            $0.outcome = Acme_Patients_V1_CancelAllergyWorkflowResponse.Outcome.with {
                $0.status = reply3.result.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply1.result.message
                $0.status = Projection.firstValue(
                    [
                        reply1.result.status,
                        reply2.result.status,
                    ], default: .init())
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processInspectAllergyWorkflow(_ input: Acme_Patients_V1_InspectAllergyWorkflowRequest) async throws
        -> Acme_Patients_V1_InspectAllergyWorkflowResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "InspectAllergyWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "InspectAllergyWorkflow", detail: input.context.traceID
        )
        var outbound0 = Acme_Documents_V1_PreviewDocumentRequest()
        outbound0.context = input.context
        outbound0.details = Acme_Documents_V1_PreviewDocumentRequest.Details.with {
            $0.contact = Acme_Common_V1_ContactInfo.with {
                $0.email = input.context.actor.email
            }
        }
        let reply0 = try await self.documentsDocumentValidation.previewDocument(outbound0)
        return Acme_Patients_V1_InspectAllergyWorkflowResponse.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.allergyID = input.allergyID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processListAllergyWorkflows(_ input: Acme_Patients_V1_ListAllergyWorkflowsRequest) async throws
        -> Acme_Patients_V1_ListAllergyWorkflowsResponse
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
            "ListAllergyWorkflows",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "ListAllergyWorkflows", detail: input.context.traceID
        )
        let outbound0 = Acme_Patients_V1_RejectAllergyRequest.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.measurements = [
                    Acme_Patients_V1_AllergyMeasurement.with {
                        $0.observedAt = input.filter.createdAfter
                    }
                ]
            }
            $0.context = input.context
            $0.details = Acme_Patients_V1_RejectAllergyRequest.Details.with {
                $0.approver = Acme_Identity_V1_UserRef.with {
                    $0.email = input.context.actor.email
                    $0.userID = input.context.actor.userID
                }
            }
        }
        let step0: @Sendable () async throws -> Acme_Patients_V1_RejectAllergyResponse = {
            try await self.patientsAllergyApproval.rejectAllergy(outbound0)
        }
        let reply0 = try await step0()
        return Acme_Patients_V1_ListAllergyWorkflowsResponse.with {
            $0.allergies = [
                Acme_Patients_V1_Allergy.with {
                    $0.subject = Acme_Patients_V1_PatientRef.with {
                        $0.displayName = reply0.allergy.subject.displayName
                    }
                }
            ]
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processPauseAllergyWorkflow(_ input: Acme_Patients_V1_PauseAllergyWorkflowRequest) async throws
        -> Acme_Patients_V1_PauseAllergyWorkflowResponse
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
            "PauseAllergyWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try AllergyRecord(input.allergy, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Patients_V1_GetPatientSyncStateRequest.with {
            $0.context = input.context
            $0.patientID = input.allergy.subject.patientID
        }
        let reply0 = try await self.patientsPatientSync.getPatientSyncState(outbound0)
        let outbound1 = Acme_Patients_V1_GenerateAllergyReportRequest.with {
            $0.allergyID = input.allergyID
            $0.annotations = input.annotations
            $0.context = input.context
            $0.reason = input.reason
        }
        async let remote1 = self.patientsAllergyReporting.generateAllergyReport(outbound1)
        async let persisted1 = store.count(tenant: input.context.tenantID)
        let (reply1, count1) = try await (remote1, persisted1)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count1)])
        return Acme_Patients_V1_PauseAllergyWorkflowResponse.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.allergyID = input.allergyID
                $0.subject = input.allergy.subject
            }
            $0.outcome = Acme_Patients_V1_PauseAllergyWorkflowResponse.Outcome.with {
                $0.status = reply1.result.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processResumeAllergyWorkflow(_ input: Acme_Patients_V1_ResumeAllergyWorkflowRequest) async throws
        -> Acme_Patients_V1_ResumeAllergyWorkflowResponse
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
            "ResumeAllergyWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try AllergyRecord(input.allergy, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Prescriptions_V1_PushRefillRequest.with {
            $0.context = input.context
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.customer = Acme_Prescriptions_V1_PrescriptionRef.with {
                    $0.displayName = input.allergy.subject.displayName
                }
            }
        }
        let reply0 = try await self.resumeAllergyWorkflowStep0.execute(outbound0)
        return Acme_Patients_V1_ResumeAllergyWorkflowResponse.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.allergyID = input.allergyID
                $0.kind = input.allergy.kind
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processRetryAllergyWorkflow(_ input: Acme_Patients_V1_RetryAllergyWorkflowRequest) async throws
        -> Acme_Patients_V1_RetryAllergyWorkflowResponse
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
            "RetryAllergyWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try AllergyRecord(input.allergy, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Notifications_V1_SummarizeNotificationsRequest.with {
            $0.context = input.context
            $0.reason = input.reason
        }
        let port0 = RPCOperations.port { (request: Acme_Notifications_V1_SummarizeNotificationsRequest) in
            try await self.notificationsNotificationQuery.summarizeNotifications(request)
        }
        let reply0 = try await port0.execute(outbound0)
        let outbound1 = Acme_Patients_V1_GenerateMedicalRecordReportRequest.with {
            $0.annotations = input.annotations
            $0.context = input.context
            $0.details = Acme_Patients_V1_GenerateMedicalRecordReportRequest.Details.with {
                $0.period = reply0.period
            }
            $0.reason = input.reason
        }
        let reply1 = try await self.retryAllergyWorkflowStep1(outbound1)
        return Acme_Patients_V1_RetryAllergyWorkflowResponse.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.allergyID = input.allergyID
                $0.kind = input.allergy.kind
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.details = reply0.result.details
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processSignalAllergyWorkflow(_ input: Acme_Patients_V1_SignalAllergyWorkflowRequest) async throws
        -> Acme_Patients_V1_SignalAllergyWorkflowResponse
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
            "SignalAllergyWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try AllergyRecord(input.allergy, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Prescriptions_V1_ReconcilePrescriptionsRequest.with {
            $0.context = input.context
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.patientID = input.allergy.subject.patientID
                }
            }
        }
        guard
            let execute0 = self.signalAllergyWorkflowStep0[settings.region]
                ?? self.signalAllergyWorkflowStep0["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply0 = try await execute0(outbound0)
        return Acme_Patients_V1_SignalAllergyWorkflowResponse.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.allergyID = input.allergyID
                $0.source = input.allergy.source
            }
            $0.outcome = Acme_Patients_V1_SignalAllergyWorkflowResponse.Outcome.with {
                $0.message = reply0.outcome.message
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processStartAllergyWorkflow(_ input: Acme_Patients_V1_StartAllergyWorkflowRequest) async throws
        -> Acme_Patients_V1_StartAllergyWorkflowResponse
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
            "StartAllergyWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try AllergyRecord(input.allergy, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let requests0 = input.allergy.measurements.map { element in
            Acme_Prescriptions_V1_ReconcileRefillsRequest.with {
                $0.context = input.context
                $0.refill = Acme_Prescriptions_V1_Refill.with {
                    $0.audit = Acme_Common_V1_AuditInfo.with {
                        $0.updatedAt = element.observedAt
                    }
                    $0.requester = Acme_Common_V1_ContactInfo.with {
                        $0.phone = input.details.notify.phone
                        $0.preferredChannel = input.details.notify.preferredChannel
                    }
                }
            }
        }
        let replies0 = try await FanOut.map(requests0) { candidate in
            try await self.prescriptionsRefillSync.reconcileRefills(candidate)
        }
        let reply0 = replies0.first ?? Acme_Prescriptions_V1_ReconcileRefillsResponse()
        let selection1_2: String
        switch reply0.refill.origin {
        case .customer(let customer):
            selection1_2 = customer.displayName
        default: selection1_2 = .init()
        }
        let outbound1 = Acme_Telehealth_V1_RetryVideoVisitWorkflowRequest.with {
            $0.context = input.context
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.displayName = selection1_2
                }
                $0.participants = [
                    Acme_Telehealth_V1_VideoVisitParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = input.allergy.subject.email
                            $0.name = reply0.refill.requester.name
                        }
                    }
                ]
            }
        }
        let reply1 = try await self.telehealthVideoVisitWorkflow.retryVideoVisitWorkflow(outbound1)
        return Acme_Patients_V1_StartAllergyWorkflowResponse.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.allergyID = input.allergyID
                $0.correlationID = input.allergy.correlationID
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = reply1.videoVisit.organizer.displayName
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }
}
