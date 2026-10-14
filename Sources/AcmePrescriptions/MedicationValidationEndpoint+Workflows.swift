import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension MedicationValidationEndpoint {
    /// Checks a medication.
    func checkMedicationEligibility(
        request: ServerRequest<Acme_Prescriptions_V1_CheckMedicationEligibilityRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_CheckMedicationEligibilityResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCheckMedicationEligibility(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Explains a medication.
    func explainMedicationDecision(
        request: ServerRequest<Acme_Prescriptions_V1_ExplainMedicationDecisionRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ExplainMedicationDecisionResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processExplainMedicationDecision(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a medication.
    func getMedicationRules(
        request: ServerRequest<Acme_Prescriptions_V1_GetMedicationRulesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_GetMedicationRulesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetMedicationRules(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lints a medication.
    func lintMedications(
        request: ServerRequest<Acme_Prescriptions_V1_LintMedicationsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_LintMedicationsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processLintMedications(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Normalizes a medication.
    func normalizeMedication(
        request: ServerRequest<Acme_Prescriptions_V1_NormalizeMedicationRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_NormalizeMedicationResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processNormalizeMedication(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Previews a medication.
    func previewMedication(
        request: ServerRequest<Acme_Prescriptions_V1_PreviewMedicationRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_PreviewMedicationResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processPreviewMedication(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Validates a medication.
    func validateMedication(
        request: ServerRequest<Acme_Prescriptions_V1_ValidateMedicationRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ValidateMedicationResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processValidateMedication(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processCheckMedicationEligibility(_ input: Acme_Prescriptions_V1_CheckMedicationEligibilityRequest)
        async throws -> Acme_Prescriptions_V1_CheckMedicationEligibilityResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.phone)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "audit", detail: input.details.contact.phone
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "CheckMedicationEligibility",
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
        let importFrame = Acme_Careplans_V1_BatchCreateCarePlansRequest.with {
            $0.context = input.context
        }
        _ = try await self.careplansCarePlan.batchCreateCarePlans { writer in
            try await writer.write(importFrame)
        }
        let selection0_4: String
        switch input.medication.locator {
        case .address(let address):
            selection0_4 = address.recipient
        default: selection0_4 = .init()
        }
        let outbound0 = Acme_Prescriptions_V1_EstimateRefillRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_EstimateRefillRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.recipient = selection0_4
                }
            }
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.medication.audit.createdAt
                    $0.etag = input.medication.audit.etag
                }
                $0.customer = Acme_Prescriptions_V1_PrescriptionRef.with {
                    $0.displayName = input.medication.owner.displayName
                }
            }
        }
        let reply0 = try await self.prescriptionsRefillCalculation.estimateRefill(outbound0)
        let selection1_1: String
        switch input.medication.locator {
        case .address(let address):
            selection1_1 = address.locality
        default: selection1_1 = .init()
        }
        let selection1_4: String
        switch input.medication.locator {
        case .address(let address):
            selection1_4 = address.postalCode
        default: selection1_4 = .init()
        }
        let outbound1 = Acme_Prescriptions_V1_EstimatePrescriptionRequest.with {
            $0.context = input.context
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.locality = selection1_1
                    $0.postalCode = selection1_4
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.email = input.details.contact.email
                }
                $0.lines = [
                    Acme_Prescriptions_V1_PrescriptionLine.with {
                        $0.description_p = input.medication.components["primary", default: .init()].description_p
                    }
                ]
            }
        }
        let reply1 = try await self.prescriptionsPrescriptionCalculation.estimatePrescription(outbound1)
        return Acme_Prescriptions_V1_CheckMedicationEligibilityResponse.with {
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply1.prescription.audit.createdAt
                    $0.updatedAt = reply1.prescription.audit.updatedAt
                }
                $0.code = input.medication.code
                $0.medicationID = input.medicationID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processExplainMedicationDecision(_ input: Acme_Prescriptions_V1_ExplainMedicationDecisionRequest) async throws
        -> Acme_Prescriptions_V1_ExplainMedicationDecisionResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "audit", detail: input.details.contact.email
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ExplainMedicationDecision",
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
        let outbound0 = Acme_Telehealth_V1_ResolveVisitNotesRequest.with {
            $0.context = input.context
        }
        let port0 = RPCOperations.port { (request: Acme_Telehealth_V1_ResolveVisitNotesRequest) in
            try await self.telehealthVisitNoteQuery.resolveVisitNotes(request)
        }
        let reply0 = try await port0.execute(outbound0)
        let outbound1 = Acme_Prescriptions_V1_CompareMedicationOptionsRequest.with {
            $0.context = input.context
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.dimensions = Acme_Prescriptions_V1_MedicationDimensions.with {
                    $0.width = input.medication.dimensions.width
                }
            }
        }
        let reply1 = try await self.explainMedicationDecisionStep1(outbound1)
        return Acme_Prescriptions_V1_ExplainMedicationDecisionResponse.with {
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.dimensions = Acme_Prescriptions_V1_MedicationDimensions.with {
                    $0.length = reply1.medication.dimensions.length
                }
                $0.medicationID = input.medicationID
                $0.status = input.medication.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.result.message
                $0.status = reply0.result.status
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processGetMedicationRules(_ input: Acme_Prescriptions_V1_GetMedicationRulesRequest) async throws
        -> Acme_Prescriptions_V1_GetMedicationRulesResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "GetMedicationRules",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "GetMedicationRules", detail: input.context.traceID
        )
        let outbound0 = Acme_Careplans_V1_ExplainVitalCalculationRequest.with {
            $0.context = input.context
            $0.details = Acme_Careplans_V1_ExplainVitalCalculationRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.context.actor.email
                }
                $0.locale = input.context.locale
            }
        }
        guard let execute0 = self.getMedicationRulesStep0[settings.region] ?? self.getMedicationRulesStep0["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply0 = try await execute0(outbound0)
        return Acme_Prescriptions_V1_GetMedicationRulesResponse.with {
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.medicationID = input.medicationID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processLintMedications(_ input: Acme_Prescriptions_V1_LintMedicationsRequest) async throws
        -> Acme_Prescriptions_V1_LintMedicationsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.phone)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "audit", detail: input.details.contact.phone
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "LintMedications",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicationRecord(input.medication, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Prescriptions_V1_RecalculatePrescriptionsRequest.with {
            $0.context = input.context
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = input.medication.owner.displayName
                }
            }
        }
        let reply0 = try await self.prescriptionsPrescriptionCalculation.recalculatePrescriptions(outbound0)
        let outbound1 = Acme_Prescriptions_V1_CalculatePrescriptionRequest.with {
            $0.context = input.context
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = reply0.prescription.counterparty.displayName
                }
            }
        }
        let envelope1 = try Google_Protobuf_Any(message: outbound1)
        let unpacked1 = try Acme_Prescriptions_V1_CalculatePrescriptionRequest(unpackingAny: envelope1)
        let reply1 = try await self.prescriptionsPrescriptionCalculation.calculatePrescription(unpacked1)
        let outbound2 = Acme_Telehealth_V1_SummarizeVideoVisitsRequest.with {
            $0.annotations = input.annotations
            $0.context = input.context
            $0.reason = input.reason
        }
        let json2 = try outbound2.jsonString()
        let decoded2 = try Acme_Telehealth_V1_SummarizeVideoVisitsRequest(jsonString: json2)
        let reply2 = try await self.telehealthVideoVisitQuery.summarizeVideoVisits(decoded2)
        let outbound3 = Acme_Careplans_V1_NormalizeVitalRequest.forMedicationValidationEndpointLintMedications3(
            input
        )
        let reply3 = try await self.careplansVitalValidation.normalizeVital(outbound3)
        return Acme_Prescriptions_V1_LintMedicationsResponse.with {
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.medicationID = input.medicationID
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply1.prescription.counterparty.displayName
                }
                $0.status = input.medication.status
            }
            $0.outcome = Acme_Prescriptions_V1_LintMedicationsResponse.Outcome.with {
                $0.message = reply0.result.message
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply3.result.message
                $0.referenceIds = reply1.result.referenceIds
                $0.status = Projection.firstValue(
                    [
                        reply0.result.status,
                        reply2.result.status,
                    ], default: .init())
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processNormalizeMedication(_ input: Acme_Prescriptions_V1_NormalizeMedicationRequest) async throws
        -> Acme_Prescriptions_V1_NormalizeMedicationResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "audit", detail: input.details.contact.email
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "NormalizeMedication",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicationRecord(input.medication, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Telehealth_V1_RecalculateVideoVisitsRequest.with {
            $0.context = input.context
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.participants = [
                    Acme_Telehealth_V1_VideoVisitParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.preferredChannel = input.details.contact.preferredChannel
                        }
                    }
                ]
            }
        }
        let reply0 = try await self.telehealthVideoVisitCalculation.recalculateVideoVisits(
            outbound0, metadata: ["x-acme-region": .string(settings.region)]
        )
        let outbound1 = Acme_Prescriptions_V1_ComparePrescriptionOptionsRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_ComparePrescriptionOptionsRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.lines = reply0.videoVisit.location.lines
                }
            }
        }
        let reply1 = try await RPCOperations.call(outbound1) { request in
            try await self.prescriptionsPrescriptionCalculation.comparePrescriptionOptions(request)
        }
        return Acme_Prescriptions_V1_NormalizeMedicationResponse.with {
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.medicationID = input.medicationID
                $0.owner = input.medication.owner
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.details = reply1.result.details
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processPreviewMedication(_ input: Acme_Prescriptions_V1_PreviewMedicationRequest) async throws
        -> Acme_Prescriptions_V1_PreviewMedicationResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.phone)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "audit", detail: input.details.contact.phone
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "PreviewMedication",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicationRecord(input.medication, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let selection0_3: String
        switch input.medication.locator {
        case .address(let address):
            selection0_3 = address.countryCode
        default: selection0_3 = .init()
        }
        let outbound0 = Acme_Prescriptions_V1_RecalculateRefillsRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_RecalculateRefillsRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = selection0_3
                }
            }
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = input.medication.audit.updatedAt
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.name = input.details.contact.name
                    $0.preferredChannel = input.details.contact.preferredChannel
                }
            }
        }
        let reply0 = try await self.prescriptionsRefillCalculation.recalculateRefills(outbound0)
        let selection1_3: String
        switch reply0.refill.origin {
        case .customer(let customer):
            selection1_3 = customer.displayName
        default: selection1_3 = .init()
        }
        let outbound1 = Acme_Careplans_V1_ScoreCareGoalRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.displayName = selection1_3
                    $0.email = input.details.contact.email
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply0.refill.audit.createdAt
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.medication.owner.email
                }
            }
            $0.context = input.context
        }
        let reply1 = try await self.careplansCareGoalValidation.scoreCareGoal(outbound1)
        return Acme_Prescriptions_V1_PreviewMedicationResponse.with {
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.code = input.medication.code
                $0.medicationID = input.medicationID
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply0.refill.customer.displayName
                }
                $0.tags = reply0.refill.tags
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply1.result.details
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processValidateMedication(_ input: Acme_Prescriptions_V1_ValidateMedicationRequest) async throws
        -> Acme_Prescriptions_V1_ValidateMedicationResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.phone)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "audit", detail: input.details.contact.phone
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ValidateMedication",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicationRecord(input.medication, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let selection0_2: String
        switch input.medication.locator {
        case .address(let address):
            selection0_2 = address.postalCode
        default: selection0_2 = .init()
        }
        let outbound0 = Acme_Prescriptions_V1_ComparePrescriptionOptionsRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_ComparePrescriptionOptionsRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = selection0_2
                }
            }
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = input.medication.owner.displayName
                }
            }
        }
        let reply0 = try await self.prescriptionsPrescriptionCalculation.comparePrescriptionOptions(outbound0)
        let outbound1 = Acme_Careplans_V1_ExplainVitalDecisionRequest.with {
            $0.context = Projection.read(input, at: \Acme_Prescriptions_V1_ValidateMedicationRequest.context)
            $0.details = Acme_Careplans_V1_ExplainVitalDecisionRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = Projection.read(
                        input, at: \Acme_Prescriptions_V1_ValidateMedicationRequest.details.contact.email)
                }
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.subject = Acme_Appointments_V1_AppointmentRef.with {
                    $0.displayName = Projection.read(
                        reply0,
                        at:
                            \Acme_Prescriptions_V1_ComparePrescriptionOptionsResponse.prescription.counterparty
                            .displayName)
                }
            }
        }
        let reply1 = try await self.careplansVitalValidation.explainVitalDecision(outbound1)
        return Acme_Prescriptions_V1_ValidateMedicationResponse.with {
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply0.prescription.audit.createdAt
                    $0.etag = reply0.prescription.audit.etag
                }
                $0.medicationID = input.medicationID
                $0.specs = input.medication.specs
            }
            $0.outcome = Acme_Prescriptions_V1_ValidateMedicationResponse.Outcome.with {
                $0.referenceID = reply1.outcome.referenceID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply1.result.message
                $0.status = "ok"
            }
        }
    }
}
