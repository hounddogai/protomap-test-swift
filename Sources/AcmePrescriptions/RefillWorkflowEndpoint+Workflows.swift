import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension RefillWorkflowEndpoint {
    /// Advances a refill.
    func advanceRefillWorkflow(
        request: ServerRequest<Acme_Prescriptions_V1_AdvanceRefillWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_AdvanceRefillWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processAdvanceRefillWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Cancels a refill.
    func cancelRefillWorkflow(
        request: ServerRequest<Acme_Prescriptions_V1_CancelRefillWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_CancelRefillWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCancelRefillWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a refill.
    func inspectRefillWorkflow(
        request: ServerRequest<Acme_Prescriptions_V1_InspectRefillWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_InspectRefillWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processInspectRefillWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists refills a page at a time.
    func listRefillWorkflows(
        request: ServerRequest<Acme_Prescriptions_V1_ListRefillWorkflowsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ListRefillWorkflowsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListRefillWorkflows(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Pauses a refill.
    func pauseRefillWorkflow(
        request: ServerRequest<Acme_Prescriptions_V1_PauseRefillWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_PauseRefillWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processPauseRefillWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Resumes a refill.
    func resumeRefillWorkflow(
        request: ServerRequest<Acme_Prescriptions_V1_ResumeRefillWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ResumeRefillWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processResumeRefillWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Retrys a refill.
    func retryRefillWorkflow(
        request: ServerRequest<Acme_Prescriptions_V1_RetryRefillWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_RetryRefillWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRetryRefillWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Signals a refill.
    func signalRefillWorkflow(
        request: ServerRequest<Acme_Prescriptions_V1_SignalRefillWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_SignalRefillWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSignalRefillWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Starts a refill.
    func startRefillWorkflow(
        request: ServerRequest<Acme_Prescriptions_V1_StartRefillWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_StartRefillWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processStartRefillWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processAdvanceRefillWorkflow(_ input: Acme_Prescriptions_V1_AdvanceRefillWorkflowRequest) async throws
        -> Acme_Prescriptions_V1_AdvanceRefillWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "audit", detail: input.details.initiatedBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "AdvanceRefillWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try RefillRecord(input.refill, tenant: input.context.tenantID)
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
        _ = try await self.prescriptionsRefillSync.pushRefill(
            Acme_Prescriptions_V1_PushRefillRequest.with {
                $0.context = restoredContext
                $0.details = Acme_Prescriptions_V1_PushRefillRequest.Details.with {
                    $0.payload = archive
                }
            })
        let outbound0 = Acme_Prescriptions_V1_StartPrescriptionWorkflowRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_StartPrescriptionWorkflowRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.refill.assignee.email
                    $0.phone = input.details.notify.phone
                }
            }
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = input.refill.audit.updatedBy
                }
                $0.dueAt = input.refill.sla.dueAt
            }
        }
        let step0: @Sendable () async throws -> Acme_Prescriptions_V1_StartPrescriptionWorkflowResponse = {
            try await self.prescriptionsPrescriptionWorkflow.startPrescriptionWorkflow(outbound0)
        }
        let reply0 = try await step0()
        var outbound1 = Acme_Patients_V1_CalculateMedicalRecordRequest()
        outbound1.context = input.context
        outbound1.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
            $0.audit = Acme_Common_V1_AuditInfo.with {
                $0.createdBy = reply0.prescription.audit.createdBy
            }
        }
        let reply1 = try await self.patientsMedicalRecordCalculation.calculateMedicalRecord(outbound1)
        let requests2 = input.refill.history.map { element in
            Acme_Venues_V1_SearchVenuesRequest.with {
                $0.context = input.context
                $0.filter = Acme_Venues_V1_SearchVenuesRequest.Filter.with {
                    $0.createdAfter = element.changedAt
                    $0.ownerID = reply0.prescription.counterparty.patientID
                    $0.region = reply1.medicalRecord.billingAddress.region
                }
            }
        }
        let replies2 = try await FanOut.map(requests2) { candidate in
            try await self.venuesVenue.searchVenues(candidate)
        }
        let reply2 = replies2.first ?? Acme_Venues_V1_SearchVenuesResponse()
        _ = reply2
        let requests3 = input.refill.comments.map { element in
            Acme_Prescriptions_V1_SyncRefillsRequest.with {
                $0.context = input.context
                $0.refill = Acme_Prescriptions_V1_Refill.with {
                    $0.comments = [
                        Acme_Prescriptions_V1_RefillComment.with {
                            $0.createdAt = element.createdAt
                        }
                    ]
                }
            }
        }
        let replies3 = try await FanOut.map(requests3) { candidate in
            try await self.prescriptionsRefillSync.syncRefills(candidate)
        }
        let reply3 = replies3.first ?? Acme_Prescriptions_V1_SyncRefillsResponse()
        _ = reply3
        return Acme_Prescriptions_V1_AdvanceRefillWorkflowResponse.with {
            $0.outcome = Acme_Prescriptions_V1_AdvanceRefillWorkflowResponse.Outcome.with {
                $0.nextSteps = reply0.outcome.nextSteps
                $0.referenceID = reply0.outcome.referenceID
            }
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.assignee = input.refill.assignee
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply1.medicalRecord.audit.etag
                }
                $0.refillID = input.refillID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processCancelRefillWorkflow(_ input: Acme_Prescriptions_V1_CancelRefillWorkflowRequest) async throws
        -> Acme_Prescriptions_V1_CancelRefillWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "audit", detail: input.details.initiatedBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "CancelRefillWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try RefillRecord(input.refill, tenant: input.context.tenantID)
        try await store.save(record.stored)
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        let outbound0 = Acme_Search_V1_CheckSearchIndexEligibilityRequest.with {
            $0.context = input.context
            $0.searchIndex = Acme_Search_V1_SearchIndex.with {
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.email = input.details.notify.email
                }
            }
        }
        let step0: @Sendable () async throws -> Acme_Search_V1_CheckSearchIndexEligibilityResponse = {
            try await self.searchSearchIndexValidation.checkSearchIndexEligibility(outbound0)
        }
        let reply0 = try await step0()
        return Acme_Prescriptions_V1_CancelRefillWorkflowResponse.with {
            $0.outcome = Acme_Prescriptions_V1_CancelRefillWorkflowResponse.Outcome.with {
                $0.message = reply0.result.message
            }
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.refillID = input.refillID
                $0.status = input.refill.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply0.outcome.status
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processInspectRefillWorkflow(_ input: Acme_Prescriptions_V1_InspectRefillWorkflowRequest) async throws
        -> Acme_Prescriptions_V1_InspectRefillWorkflowResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "InspectRefillWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "InspectRefillWorkflow", detail: input.context.traceID
        )
        let outbound0 = Acme_Careplans_V1_AdvanceCareGoalWorkflowRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.context.actor.userID
                }
                $0.externalReference = input.refillID
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.context.actor.email
                }
            }
            $0.context = input.context
        }
        let reply0 = try await self.careplansCareGoalWorkflow.advanceCareGoalWorkflow(outbound0)
        let outbound1 = Acme_Patients_V1_CheckPatientEligibilityRequest.with {
            $0.context = input.context
            $0.details = Acme_Patients_V1_CheckPatientEligibilityRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply0.careGoal.requester.email
                    $0.phone = reply0.careGoal.requester.phone
                }
            }
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply0.careGoal.audit.etag
                }
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.email = reply0.careGoal.assignee.email
                }
            }
        }
        async let remote1 = self.patientsPatientValidation.checkPatientEligibility(outbound1)
        async let persisted1 = store.count(tenant: input.context.tenantID)
        let (reply1, count1) = try await (remote1, persisted1)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count1)])
        return Acme_Prescriptions_V1_InspectRefillWorkflowResponse.with {
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.userID = Projection.firstValue(
                        [
                            reply0.careGoal.assignee.userID,
                            reply1.patient.relationshipManager.userID,
                        ], default: .init())
                }
                $0.refillID = input.refillID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = Projection.firstValue(
                    [
                        reply0.outcome.status,
                        reply1.outcome.status,
                    ], default: .init())
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processListRefillWorkflows(_ input: Acme_Prescriptions_V1_ListRefillWorkflowsRequest) async throws
        -> Acme_Prescriptions_V1_ListRefillWorkflowsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ListRefillWorkflows",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "ListRefillWorkflows", detail: input.context.traceID
        )
        let outbound0 = Acme_Prescriptions_V1_ResumePrescriptionWorkflowRequest.with {
            $0.context = input.context
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = input.filter.createdAfter
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.email = input.context.actor.email
                }
                $0.metadata = input.filter.labels
            }
        }
        let reply0 = try await self.listRefillWorkflowsStep0.execute(outbound0)
        return Acme_Prescriptions_V1_ListRefillWorkflowsResponse.with {
            $0.refills = [
                Acme_Prescriptions_V1_Refill.with {
                    $0.audit = Acme_Common_V1_AuditInfo.with {
                        $0.createdBy = reply0.prescription.audit.createdBy
                    }
                    $0.comments = [
                        Acme_Prescriptions_V1_RefillComment.with {
                            $0.createdAt = reply0.prescription.audit.createdAt
                        }
                    ]
                }
            ]
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processPauseRefillWorkflow(_ input: Acme_Prescriptions_V1_PauseRefillWorkflowRequest) async throws
        -> Acme_Prescriptions_V1_PauseRefillWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "audit", detail: input.details.initiatedBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "PauseRefillWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try RefillRecord(input.refill, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Promotions_V1_SimulatePromotionRequest.with {
            $0.context = input.context
            $0.promotion = Acme_Promotions_V1_Promotion.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.refill.audit.createdAt
                }
            }
        }
        let port0 = RPCOperations.port { (request: Acme_Promotions_V1_SimulatePromotionRequest) in
            try await self.promotionsPromotionCalculation.simulatePromotion(request)
        }
        let reply0 = try await port0.execute(outbound0)
        let outbound1 = Acme_Careplans_V1_AdvanceCareGoalWorkflowRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.phone = input.refill.requester.phone
                }
            }
            $0.context = input.context
        }
        let reply1 = try await self.pauseRefillWorkflowStep1(outbound1)
        let requests2 = input.refill.comments.map { element in
            Acme_Boxoffice_V1_CloneBoxOfficeSaleRequest.with {
                $0.boxOfficeSale = Acme_Boxoffice_V1_BoxOfficeSale.with {
                    $0.audit = Acme_Common_V1_AuditInfo.with {
                        $0.createdAt = element.createdAt
                        $0.etag = reply1.careGoal.audit.etag
                        $0.updatedBy = reply1.careGoal.audit.updatedBy
                    }
                    $0.dueAt = input.refill.sla.dueAt
                }
                $0.context = input.context
            }
        }
        let replies2 = try await FanOut.map(requests2) { candidate in
            try await self.boxofficeBoxOfficeSale.cloneBoxOfficeSale(candidate)
        }
        let reply2 = replies2.first ?? Acme_Boxoffice_V1_CloneBoxOfficeSaleResponse()
        _ = reply2
        let outbound3 = Acme_Search_V1_ResolveSearchIndexesRequest.with {
            $0.context = input.context
        }
        guard let execute3 = self.pauseRefillWorkflowStep3[settings.region] ?? self.pauseRefillWorkflowStep3["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply3 = try await execute3(outbound3)
        return Acme_Prescriptions_V1_PauseRefillWorkflowResponse.with {
            $0.outcome = Acme_Prescriptions_V1_PauseRefillWorkflowResponse.Outcome.with {
                $0.message = reply3.result.message
            }
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.userID = reply0.promotion.owner.userID
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply0.promotion.audit.updatedBy
                }
                $0.refillID = input.refillID
                $0.sla = Acme_Prescriptions_V1_RefillSla.with {
                    $0.breached = reply1.careGoal.sla.breached
                }
                $0.status = input.refill.status
                $0.subject = reply1.careGoal.subject
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processResumeRefillWorkflow(_ input: Acme_Prescriptions_V1_ResumeRefillWorkflowRequest) async throws
        -> Acme_Prescriptions_V1_ResumeRefillWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "audit", detail: input.details.initiatedBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ResumeRefillWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try RefillRecord(input.refill, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Prescriptions_V1_ListRefillImportsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Prescriptions_V1_ListRefillImportsRequest.Filter.with {
                $0.createdAfter = input.refill.audit.createdAt
            }
        }
        let reply0 = try await self.prescriptionsRefillImport.listRefillImports(outbound0)
        return Acme_Prescriptions_V1_ResumeRefillWorkflowResponse.with {
            $0.outcome = Acme_Prescriptions_V1_ResumeRefillWorkflowResponse.Outcome.with {
                $0.status = reply0.result.status
            }
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.assignee = input.refill.assignee
                $0.refillID = input.refillID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply0.result.status
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processRetryRefillWorkflow(_ input: Acme_Prescriptions_V1_RetryRefillWorkflowRequest) async throws
        -> Acme_Prescriptions_V1_RetryRefillWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "audit", detail: input.details.initiatedBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "RetryRefillWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try RefillRecord(input.refill, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Telehealth_V1_ValidateVideoVisitRequest.with {
            $0.context = input.context
            $0.details = Acme_Telehealth_V1_ValidateVideoVisitRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.refill.requester.email
                }
            }
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.email = input.refill.assignee.email
                }
                $0.participants = [
                    Acme_Telehealth_V1_VideoVisitParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = input.details.notify.email
                            $0.name = input.refill.requester.name
                        }
                    }
                ]
            }
        }
        let envelope0 = try Google_Protobuf_Any(message: outbound0)
        let unpacked0 = try Acme_Telehealth_V1_ValidateVideoVisitRequest(unpackingAny: envelope0)
        let reply0 = try await self.telehealthVideoVisitValidation.validateVideoVisit(unpacked0)
        let outbound1 = Acme_Prescriptions_V1_SimulateRefillRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_SimulateRefillRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.locality = reply0.videoVisit.location.locality
                }
            }
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.email = input.details.notify.email
                }
                $0.sla = Acme_Prescriptions_V1_RefillSla.with {
                    $0.pausedFor = input.refill.sla.pausedFor
                }
            }
        }
        let json1 = try outbound1.jsonString()
        let decoded1 = try Acme_Prescriptions_V1_SimulateRefillRequest(jsonString: json1)
        let reply1 = try await self.prescriptionsRefillCalculation.simulateRefill(decoded1)
        return Acme_Prescriptions_V1_RetryRefillWorkflowResponse.with {
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply0.videoVisit.audit.createdAt
                    $0.updatedAt = reply0.videoVisit.audit.updatedAt
                }
                $0.refillID = input.refillID
                $0.sla = Acme_Prescriptions_V1_RefillSla.with {
                    $0.policyID = reply1.refill.sla.policyID
                }
                $0.status = input.refill.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processSignalRefillWorkflow(_ input: Acme_Prescriptions_V1_SignalRefillWorkflowRequest) async throws
        -> Acme_Prescriptions_V1_SignalRefillWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "audit", detail: input.details.initiatedBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SignalRefillWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try RefillRecord(input.refill, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let selection0_2: String
        switch input.refill.origin {
        case .customer(let customer):
            selection0_2 = customer.number
        default: selection0_2 = .init()
        }
        let outbound0 = Acme_Prescriptions_V1_MapRefillImportColumnsRequest.with {
            $0.context = input.context
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = input.refill.audit.updatedAt
                }
                $0.customer = Acme_Prescriptions_V1_PrescriptionRef.with {
                    $0.number = selection0_2
                }
            }
        }
        let reply0 = try await self.prescriptionsRefillImport.mapRefillImportColumns(outbound0)
        let outbound1 = Acme_Ledger_V1_SearchLedgerAccountsRequest.forRefillWorkflowEndpointSignalRefillWorkflow1(
            input
        )
        let reply1 = try await self.ledgerLedgerAccount.searchLedgerAccounts(outbound1)
        return Acme_Prescriptions_V1_SignalRefillWorkflowResponse.with {
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.email = reply0.refill.assignee.email
                }
                $0.refillID = input.refillID
                $0.sla = Acme_Prescriptions_V1_RefillSla.with {
                    $0.pausedFor = reply0.refill.sla.pausedFor
                }
                $0.subject = input.refill.subject
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply1.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processStartRefillWorkflow(_ input: Acme_Prescriptions_V1_StartRefillWorkflowRequest) async throws
        -> Acme_Prescriptions_V1_StartRefillWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "refill",
            action: "audit", detail: input.details.initiatedBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "StartRefillWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try RefillRecord(input.refill, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let selection0_1: String
        switch input.refill.origin {
        case .customer(let customer):
            selection0_1 = customer.prescriptionID
        default: selection0_1 = .init()
        }
        let outbound0 = Acme_Prescriptions_V1_SchedulePrescriptionReportRequest.with {
            $0.annotations = input.annotations
            $0.context = input.context
            $0.prescriptionID = selection0_1
            $0.reason = input.reason
        }
        let reply0 = try await self.prescriptionsPrescriptionReporting.schedulePrescriptionReport(outbound0)
        let outbound1 = Acme_Prescriptions_V1_SignalMedicationWorkflowRequest.with {
            $0.context = input.context
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = input.refill.audit.createdBy
                    $0.etag = input.refill.audit.etag
                    $0.updatedAt = input.refill.audit.updatedAt
                }
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.email = input.details.notify.email
                }
            }
        }
        let reply1 = try await self.prescriptionsMedicationWorkflow.signalMedicationWorkflow(
            outbound1, metadata: ["x-acme-region": .string(settings.region)]
        )
        let outbound2 = Acme_Venues_V1_UpdateVenueRequest.with {
            $0.context = input.context
            $0.venue = Acme_Venues_V1_Venue.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.refill.audit.createdAt
                    $0.createdBy = input.refill.audit.createdBy
                }
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.refill.assignee.userID
                }
            }
        }
        let reply2 = try await RPCOperations.call(outbound2) { request in
            try await self.venuesVenue.updateVenue(request)
        }
        let selection3_2: String
        switch reply2.venue.locator {
        case .address(let address):
            selection3_2 = address.countryCode
        default: selection3_2 = .init()
        }
        let selection3_4: String
        switch reply2.venue.locator {
        case .address(let address):
            selection3_4 = address.recipient
        default: selection3_4 = .init()
        }
        let outbound3 = Acme_Prescriptions_V1_SignalPrescriptionWorkflowRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_SignalPrescriptionWorkflowRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply1.medication.owner.email
                }
            }
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply2.venue.audit.etag
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = selection3_2
                    $0.recipient = selection3_4
                }
            }
        }
        let reply3 = try await self.prescriptionsPrescriptionWorkflow.signalPrescriptionWorkflow(outbound3)
        return Acme_Prescriptions_V1_StartRefillWorkflowResponse.with {
            $0.outcome = Acme_Prescriptions_V1_StartRefillWorkflowResponse.Outcome.with {
                $0.message = reply3.result.message
            }
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.comments = [
                    Acme_Prescriptions_V1_RefillComment.with {
                        $0.createdAt = Projection.firstValue(
                            [
                                reply1.medication.audit.createdAt,
                                reply3.prescription.audit.createdAt,
                            ], default: .init())
                    }
                ]
                $0.priority = input.refill.priority
                $0.refillID = input.refillID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.message = Projection.firstValue(
                    [
                        reply0.result.message,
                        reply2.result.message,
                    ], default: .init())
                $0.status = "ok"
            }
        }
    }
}
