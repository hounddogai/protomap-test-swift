import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension MedicationApprovalEndpoint {
    /// Approves a medication.
    func approveMedication(
        request: ServerRequest<Acme_Prescriptions_V1_ApproveMedicationRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ApproveMedicationResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processApproveMedication(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Comments a medication.
    func commentMedicationApproval(
        request: ServerRequest<Acme_Prescriptions_V1_CommentMedicationApprovalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_CommentMedicationApprovalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCommentMedicationApproval(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Delegates a medication.
    func delegateMedicationApproval(
        request: ServerRequest<Acme_Prescriptions_V1_DelegateMedicationApprovalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_DelegateMedicationApprovalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processDelegateMedicationApproval(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Escalates a medication.
    func escalateMedication(
        request: ServerRequest<Acme_Prescriptions_V1_EscalateMedicationRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_EscalateMedicationResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processEscalateMedication(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a medication.
    func getMedicationApprovalStatus(
        request: ServerRequest<Acme_Prescriptions_V1_GetMedicationApprovalStatusRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_GetMedicationApprovalStatusResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetMedicationApprovalStatus(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists medications a page at a time.
    func listPendingMedications(
        request: ServerRequest<Acme_Prescriptions_V1_ListPendingMedicationsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ListPendingMedicationsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListPendingMedications(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Recalls a medication.
    func recallMedication(
        request: ServerRequest<Acme_Prescriptions_V1_RecallMedicationRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_RecallMedicationResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRecallMedication(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Rejects a medication.
    func rejectMedication(
        request: ServerRequest<Acme_Prescriptions_V1_RejectMedicationRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_RejectMedicationResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRejectMedication(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Submits a medication.
    func submitMedication(
        request: ServerRequest<Acme_Prescriptions_V1_SubmitMedicationRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_SubmitMedicationResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSubmitMedication(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processApproveMedication(_ input: Acme_Prescriptions_V1_ApproveMedicationRequest) async throws
        -> Acme_Prescriptions_V1_ApproveMedicationResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "audit", detail: input.details.approver.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ApproveMedication",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicationRecord(input.medication, tenant: input.context.tenantID)
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
        let selection0_1: String
        switch input.medication.locator {
        case .address(let address):
            selection0_1 = address.region
        default: selection0_1 = .init()
        }
        let outbound0 = Acme_Patients_V1_SuggestMedicalRecordsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Patients_V1_SuggestMedicalRecordsRequest.Filter.with {
                $0.createdAfter = input.medication.audit.createdAt
                $0.labels = input.medication.specs
                $0.ownerID = input.medication.owner.userID
                $0.region = selection0_1
            }
        }
        let reply0 = try await self.patientsMedicalRecordQuery.suggestMedicalRecords(outbound0)
        let selection1_2: [String]
        switch input.medication.locator {
        case .address(let address):
            selection1_2 = address.lines
        default: selection1_2 = .init()
        }
        let outbound1 = Acme_Patients_V1_ScoreMedicalRecordRequest.with {
            $0.context = input.context
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.lines = selection1_2
                }
                $0.lines = [
                    Acme_Patients_V1_MedicalRecordLine.with {
                        $0.quantity = input.medication.components["primary", default: .init()].quantity
                    }
                ]
            }
        }
        let reply1 = try await self.patientsMedicalRecordValidation.scoreMedicalRecord(outbound1)
        return Acme_Prescriptions_V1_ApproveMedicationResponse.with {
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply1.medicalRecord.audit.etag
                }
                $0.medicationID = input.medicationID
                $0.name = input.medication.name
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processCommentMedicationApproval(_ input: Acme_Prescriptions_V1_CommentMedicationApprovalRequest) async throws
        -> Acme_Prescriptions_V1_CommentMedicationApprovalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "audit", detail: input.details.approver.email
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "CommentMedicationApproval",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicationRecord(input.medication, tenant: input.context.tenantID)
        try await store.save(record.stored)
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        let selection0_1: String
        switch input.medication.locator {
        case .address(let address):
            selection0_1 = address.region
        default: selection0_1 = .init()
        }
        let outbound0 = Acme_Venues_V1_BrowseVenuesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Venues_V1_BrowseVenuesRequest.Filter.with {
                $0.createdAfter = input.medication.audit.updatedAt
                $0.ownerID = input.medication.owner.userID
                $0.region = selection0_1
            }
        }
        let reply0 = try await self.venuesVenueQuery.browseVenues(outbound0)
        let outbound1 = Acme_Telehealth_V1_DelegateTriageApprovalRequest.with {
            $0.context = input.context
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.customer = Acme_Telehealth_V1_VideoVisitRef.with {
                    $0.displayName = input.details.approver.displayName
                }
            }
        }
        let reply1 = try await self.telehealthTriageApproval.delegateTriageApproval(outbound1)
        let selection2_1: [String]
        switch input.medication.locator {
        case .address(let address):
            selection2_1 = address.lines
        default: selection2_1 = .init()
        }
        let selection2_2: String
        switch input.medication.locator {
        case .address(let address):
            selection2_2 = address.countryCode
        default: selection2_2 = .init()
        }
        let selection2_3: String
        switch reply1.triage.origin {
        case .customer(let customer):
            selection2_3 = customer.displayName
        default: selection2_3 = .init()
        }
        let selection2_4: String
        switch input.medication.locator {
        case .address(let address):
            selection2_4 = address.region
        default: selection2_4 = .init()
        }
        let outbound2 = Acme_Patients_V1_RecalculatePatientsRequest.with {
            $0.context = input.context
            $0.details = Acme_Patients_V1_RecalculatePatientsRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = selection2_2
                    $0.lines = selection2_1
                    $0.region = selection2_4
                }
            }
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.displayName = selection2_3
                }
            }
        }
        let reply2 = try await self.patientsPatientCalculation.recalculatePatients(outbound2)
        return Acme_Prescriptions_V1_CommentMedicationApprovalResponse.with {
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.medicationID = input.medicationID
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply2.patient.relationshipManager.displayName
                    $0.userID = reply1.triage.assignee.userID
                }
            }
            $0.outcome = Acme_Prescriptions_V1_CommentMedicationApprovalResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
                $0.message = reply1.outcome.message
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processDelegateMedicationApproval(_ input: Acme_Prescriptions_V1_DelegateMedicationApprovalRequest)
        async throws -> Acme_Prescriptions_V1_DelegateMedicationApprovalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "audit", detail: input.details.approver.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "DelegateMedicationApproval",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicationRecord(input.medication, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let selection0_1: String
        switch input.medication.locator {
        case .address(let address):
            selection0_1 = address.recipient
        default: selection0_1 = .init()
        }
        let selection0_2: String
        switch input.medication.locator {
        case .address(let address):
            selection0_2 = address.countryCode
        default: selection0_2 = .init()
        }
        let selection0_3: [String]
        switch input.medication.locator {
        case .address(let address):
            selection0_3 = address.lines
        default: selection0_3 = .init()
        }
        let outbound0 = Acme_Careplans_V1_SignalCarePlanWorkflowRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = selection0_2
                    $0.lines = selection0_3
                    $0.recipient = selection0_1
                }
            }
            $0.context = input.context
            $0.details = Acme_Careplans_V1_SignalCarePlanWorkflowRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.medication.owner.email
                }
            }
        }
        let reply0 = try await self.careplansCarePlanWorkflow.signalCarePlanWorkflow(outbound0)
        let outbound1 = Acme_Careplans_V1_AdvanceVitalWorkflowRequest.with {
            $0.context = input.context
            $0.details = Acme_Careplans_V1_AdvanceVitalWorkflowRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.approver.email
                }
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.measurements = [
                    Acme_Careplans_V1_VitalMeasurement.with {
                        $0.unit = input.medication.dimensions.unit
                    }
                ]
                $0.subject = Acme_Appointments_V1_AppointmentRef.with {
                    $0.appointmentID = reply0.carePlan.counterparty.appointmentID
                    $0.startsAt = reply0.carePlan.counterparty.startsAt
                }
            }
        }
        async let remote1 = self.careplansVitalWorkflow.advanceVitalWorkflow(outbound1)
        async let persisted1 = store.count(tenant: input.context.tenantID)
        let (reply1, count1) = try await (remote1, persisted1)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count1)])
        let outbound2 = Acme_Prescriptions_V1_ScheduleMedicationExpiryRequest.with {
            $0.context = input.context
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.address = Acme_Common_V1_PostalAddress.with {
                    $0.locality = reply0.carePlan.billingAddress.locality
                    $0.region = reply0.carePlan.billingAddress.region
                }
            }
        }
        let reply2 = try await self.delegateMedicationApprovalStep2.execute(outbound2)
        return Acme_Prescriptions_V1_DelegateMedicationApprovalResponse.with {
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply2.medication.audit.updatedAt
                }
                $0.medicationID = input.medicationID
            }
            $0.outcome = Acme_Prescriptions_V1_DelegateMedicationApprovalResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
                $0.message = Projection.firstValue(
                    [
                        reply0.outcome.message,
                        reply2.result.message,
                    ], default: .init())
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply0.result.referenceIds
                $0.status = reply1.result.status
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processEscalateMedication(_ input: Acme_Prescriptions_V1_EscalateMedicationRequest) async throws
        -> Acme_Prescriptions_V1_EscalateMedicationResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "audit", detail: input.details.approver.email
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "EscalateMedication",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicationRecord(input.medication, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let selection0_1: String
        switch input.medication.locator {
        case .address(let address):
            selection0_1 = address.region
        default: selection0_1 = .init()
        }
        let outbound0 = Acme_Venues_V1_FindVenuesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Venues_V1_FindVenuesRequest.Filter.with {
                $0.createdAfter = input.medication.audit.createdAt
                $0.ownerID = input.medication.components["primary", default: .init()].componentID
                $0.region = selection0_1
            }
        }
        let reply0 = try await self.venuesVenueQuery.findVenues(outbound0)
        let selection1_1: [String]
        switch input.medication.locator {
        case .address(let address):
            selection1_1 = address.lines
        default: selection1_1 = .init()
        }
        let outbound1 = Acme_Patients_V1_CalculateAllergyRequest.with {
            $0.context = input.context
            $0.details = Acme_Patients_V1_CalculateAllergyRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.lines = selection1_1
                }
            }
        }
        let reply1 = try await self.patientsAllergyCalculation.calculateAllergy(outbound1)
        let outbound2 = Acme_Featureflags_V1_CheckFeatureFlagEligibilityRequest.with {
            $0.context = input.context
            $0.featureFlag = Acme_Featureflags_V1_FeatureFlag.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = input.medication.audit.updatedAt
                }
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.details.approver.displayName
                }
            }
        }
        let port2 = RPCOperations.port { (request: Acme_Featureflags_V1_CheckFeatureFlagEligibilityRequest) in
            try await self.featureflagsFeatureFlagValidation.checkFeatureFlagEligibility(request)
        }
        let reply2 = try await port2.execute(outbound2)
        return Acme_Prescriptions_V1_EscalateMedicationResponse.with {
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply2.featureFlag.audit.updatedBy
                }
                $0.medicationID = input.medicationID
                $0.name = input.medication.name
            }
            $0.outcome = Acme_Prescriptions_V1_EscalateMedicationResponse.Outcome.with {
                $0.status = reply1.result.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply0.result.status
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processGetMedicationApprovalStatus(_ input: Acme_Prescriptions_V1_GetMedicationApprovalStatusRequest)
        async throws -> Acme_Prescriptions_V1_GetMedicationApprovalStatusResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "GetMedicationApprovalStatus",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "GetMedicationApprovalStatus", detail: input.context.traceID
        )
        let outbound0 = Acme_Careplans_V1_ApproveVitalRequest.with {
            $0.context = input.context
            $0.details = Acme_Careplans_V1_ApproveVitalRequest.Details.with {
                $0.approver = Acme_Identity_V1_UserRef.with {
                    $0.email = input.context.actor.email
                    $0.userID = input.context.actor.userID
                }
            }
        }
        let reply0 = try await self.getMedicationApprovalStatusStep0(outbound0)
        return Acme_Prescriptions_V1_GetMedicationApprovalStatusResponse.with {
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.medicationID = input.medicationID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processListPendingMedications(_ input: Acme_Prescriptions_V1_ListPendingMedicationsRequest) async throws
        -> Acme_Prescriptions_V1_ListPendingMedicationsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ListPendingMedications",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "ListPendingMedications", detail: input.context.traceID
        )
        let outbound0 = Acme_Patients_V1_SummarizePatientsRequest.with {
            $0.annotations = input.context.baggage
            $0.context = input.context
            $0.details = Acme_Patients_V1_SummarizePatientsRequest.Details.with {
                $0.filters = input.filter.labels
            }
        }
        guard
            let execute0 = self.listPendingMedicationsStep0[settings.region]
                ?? self.listPendingMedicationsStep0["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply0 = try await execute0(outbound0)
        return Acme_Prescriptions_V1_ListPendingMedicationsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply0.result.status
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processRecallMedication(_ input: Acme_Prescriptions_V1_RecallMedicationRequest) async throws
        -> Acme_Prescriptions_V1_RecallMedicationResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "audit", detail: input.details.approver.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "RecallMedication",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicationRecord(input.medication, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let selection0_1: String
        switch input.medication.locator {
        case .address(let address):
            selection0_1 = address.region
        default: selection0_1 = .init()
        }
        let outbound0 = Acme_Telehealth_V1_ListPendingTriagesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Telehealth_V1_ListPendingTriagesRequest.Filter.with {
                $0.createdAfter = input.medication.audit.updatedAt
                $0.ownerID = input.details.approver.userID
                $0.region = selection0_1
            }
        }
        let reply0 = try await self.telehealthTriageApproval.listPendingTriages(outbound0)
        let selection1_1: String
        switch input.medication.locator {
        case .address(let address):
            selection1_1 = address.region
        default: selection1_1 = .init()
        }
        let outbound1 = Acme_Prescriptions_V1_ListMedicationConflictsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Prescriptions_V1_ListMedicationConflictsRequest.Filter.with {
                $0.createdAfter = input.medication.audit.createdAt
                $0.ownerID = input.medication.components["primary", default: .init()].componentID
                $0.region = selection1_1
            }
        }
        let reply1 = try await self.prescriptionsMedicationSync.listMedicationConflicts(outbound1)
        return Acme_Prescriptions_V1_RecallMedicationResponse.with {
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.medicationID = input.medicationID
            }
            $0.outcome = Acme_Prescriptions_V1_RecallMedicationResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
                $0.status = reply1.result.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.message = reply1.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processRejectMedication(_ input: Acme_Prescriptions_V1_RejectMedicationRequest) async throws
        -> Acme_Prescriptions_V1_RejectMedicationResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "audit", detail: input.details.approver.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "RejectMedication",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicationRecord(input.medication, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let selection0_1: String
        switch input.medication.locator {
        case .address(let address):
            selection0_1 = address.countryCode
        default: selection0_1 = .init()
        }
        let selection0_2: String
        switch input.medication.locator {
        case .address(let address):
            selection0_2 = address.recipient
        default: selection0_2 = .init()
        }
        let outbound0 = Acme_Prescriptions_V1_RecalculatePrescriptionsRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_RecalculatePrescriptionsRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.recipient = selection0_2
                }
            }
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = selection0_1
                }
            }
        }
        let reply0 = try await self.prescriptionsPrescriptionCalculation.recalculatePrescriptions(outbound0)
        let outbound1 = Acme_Prescriptions_V1_ExplainMedicationCalculationRequest.with {
            $0.context = input.context
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.address = Acme_Common_V1_PostalAddress.with {
                    $0.region = reply0.prescription.billingAddress.region
                }
                $0.dimensions = Acme_Prescriptions_V1_MedicationDimensions.with {
                    $0.height = input.medication.dimensions.height
                }
            }
        }
        let reply1 = try await self.prescriptionsMedicationCalculation.explainMedicationCalculation(outbound1)
        return Acme_Prescriptions_V1_RejectMedicationResponse.with {
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.capacity = reply1.medication.capacity
                $0.dimensions = Acme_Prescriptions_V1_MedicationDimensions.with {
                    $0.length = reply1.medication.dimensions.length
                }
                $0.medicationID = input.medicationID
                $0.specs = input.medication.specs
            }
            $0.outcome = Acme_Prescriptions_V1_RejectMedicationResponse.Outcome.with {
                $0.message = reply0.result.message
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processSubmitMedication(_ input: Acme_Prescriptions_V1_SubmitMedicationRequest) async throws
        -> Acme_Prescriptions_V1_SubmitMedicationResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "audit", detail: input.details.approver.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SubmitMedication",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicationRecord(input.medication, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let selection0_1: String
        switch input.medication.locator {
        case .address(let address):
            selection0_1 = address.region
        default: selection0_1 = .init()
        }
        let outbound0 = Acme_Venues_V1_FindVenuesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Venues_V1_FindVenuesRequest.Filter.with {
                $0.createdAfter = input.medication.audit.createdAt
                $0.ownerID = input.medication.owner.userID
                $0.region = selection0_1
            }
        }
        let reply0 = try await self.venuesVenueQuery.findVenues(outbound0)
        return Acme_Prescriptions_V1_SubmitMedicationResponse.with {
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.medicationID = input.medicationID
                $0.status = input.medication.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.status = reply0.result.status
            }
        }
    }
}
