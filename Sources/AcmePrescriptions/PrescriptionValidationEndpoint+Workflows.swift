import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension PrescriptionValidationEndpoint {
    /// Checks a prescription.
    func checkPrescriptionEligibility(
        request: ServerRequest<Acme_Prescriptions_V1_CheckPrescriptionEligibilityRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_CheckPrescriptionEligibilityResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCheckPrescriptionEligibility(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Explains a prescription.
    func explainPrescriptionDecision(
        request: ServerRequest<Acme_Prescriptions_V1_ExplainPrescriptionDecisionRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ExplainPrescriptionDecisionResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processExplainPrescriptionDecision(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a prescription.
    func getPrescriptionRules(
        request: ServerRequest<Acme_Prescriptions_V1_GetPrescriptionRulesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_GetPrescriptionRulesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetPrescriptionRules(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Normalizes a prescription.
    func normalizePrescription(
        request: ServerRequest<Acme_Prescriptions_V1_NormalizePrescriptionRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_NormalizePrescriptionResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processNormalizePrescription(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Previews a prescription.
    func previewPrescription(
        request: ServerRequest<Acme_Prescriptions_V1_PreviewPrescriptionRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_PreviewPrescriptionResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processPreviewPrescription(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Scores a prescription.
    func scorePrescription(
        request: ServerRequest<Acme_Prescriptions_V1_ScorePrescriptionRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ScorePrescriptionResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processScorePrescription(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Validates a prescription.
    func validatePrescription(
        request: ServerRequest<Acme_Prescriptions_V1_ValidatePrescriptionRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ValidatePrescriptionResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processValidatePrescription(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processCheckPrescriptionEligibility(_ input: Acme_Prescriptions_V1_CheckPrescriptionEligibilityRequest)
        async throws -> Acme_Prescriptions_V1_CheckPrescriptionEligibilityResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "audit", detail: input.details.contact.email
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "CheckPrescriptionEligibility",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PrescriptionRecord(input.prescription, tenant: input.context.tenantID)
        try await store.save(record.stored)
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        let importFrame = Acme_Telehealth_V1_BatchCreateVideoVisitsRequest.with {
            $0.context = input.context
        }
        _ = try await self.telehealthVideoVisit.batchCreateVideoVisits { writer in
            try await writer.write(importFrame)
        }
        var outbound0 = Acme_Telehealth_V1_ExplainTriageCalculationRequest()
        outbound0.context = input.context
        outbound0.details = Acme_Telehealth_V1_ExplainTriageCalculationRequest.Details.with {
            $0.contact = Acme_Common_V1_ContactInfo.with {
                $0.email = input.prescription.counterparty.email
            }
        }
        let reply0 = try await self.telehealthTriageCalculation.explainTriageCalculation(outbound0)
        return Acme_Prescriptions_V1_CheckPrescriptionEligibilityResponse.with {
            $0.outcome = Acme_Prescriptions_V1_CheckPrescriptionEligibilityResponse.Outcome.with {
                $0.status = reply0.result.status
            }
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.metadata = input.prescription.metadata
                $0.prescriptionID = input.prescriptionID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processExplainPrescriptionDecision(_ input: Acme_Prescriptions_V1_ExplainPrescriptionDecisionRequest)
        async throws -> Acme_Prescriptions_V1_ExplainPrescriptionDecisionResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "audit", detail: input.details.contact.email
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ExplainPrescriptionDecision",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PrescriptionRecord(input.prescription, tenant: input.context.tenantID)
        try await store.save(record.stored)
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        let outbound0 = Acme_Careplans_V1_ValidateCarePlanRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.recipient = input.prescription.billingAddress.recipient
                }
            }
            $0.context = input.context
            $0.details = Acme_Careplans_V1_ValidateCarePlanRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.phone = input.details.contact.phone
                }
            }
        }
        let step0: @Sendable () async throws -> Acme_Careplans_V1_ValidateCarePlanResponse = {
            try await self.careplansCarePlanValidation.validateCarePlan(outbound0)
        }
        let reply0 = try await step0()
        let outbound1 = Acme_Prescriptions_V1_CalculatePrescriptionRequest.with {
            $0.context = input.context
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = input.prescription.audit.createdBy
                }
            }
        }
        let reply1 = try await self.prescriptionsPrescriptionCalculation.calculatePrescription(outbound1)
        let outbound2 = Acme_Prescriptions_V1_CalculateMedicationRequest.with {
            $0.context = input.context
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply1.prescription.audit.createdBy
                }
            }
        }
        async let remote2 = self.prescriptionsMedicationCalculation.calculateMedication(outbound2)
        async let persisted2 = store.count(tenant: input.context.tenantID)
        let (reply2, count2) = try await (remote2, persisted2)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count2)])
        return Acme_Prescriptions_V1_ExplainPrescriptionDecisionResponse.with {
            $0.outcome = Acme_Prescriptions_V1_ExplainPrescriptionDecisionResponse.Outcome.with {
                $0.status = reply2.result.status
            }
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.lines = reply2.medication.address.lines
                    $0.postalCode = reply0.carePlan.billingAddress.postalCode
                }
                $0.issuedAt = input.prescription.issuedAt
                $0.prescriptionID = input.prescriptionID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply1.result.details
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processGetPrescriptionRules(_ input: Acme_Prescriptions_V1_GetPrescriptionRulesRequest) async throws
        -> Acme_Prescriptions_V1_GetPrescriptionRulesResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "GetPrescriptionRules",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "GetPrescriptionRules", detail: input.context.traceID
        )
        return Acme_Prescriptions_V1_GetPrescriptionRulesResponse.with {
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.prescriptionID = input.prescriptionID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processNormalizePrescription(_ input: Acme_Prescriptions_V1_NormalizePrescriptionRequest) async throws
        -> Acme_Prescriptions_V1_NormalizePrescriptionResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "audit", detail: input.details.contact.email
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "NormalizePrescription",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PrescriptionRecord(input.prescription, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let selection0_2: String
        switch input.prescription.settlement {
        case .card(let card):
            selection0_2 = card.holderName
        default: selection0_2 = .init()
        }
        let outbound0 = Acme_Telehealth_V1_CalculateVisitNoteRequest.with {
            $0.context = input.context
            $0.details = Acme_Telehealth_V1_CalculateVisitNoteRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = input.prescription.billingAddress.postalCode
                }
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.card = Acme_Telehealth_V1_VisitNoteCardSettlement.with {
                    $0.holderName = selection0_2
                }
            }
        }
        let reply0 = try await self.telehealthVisitNoteCalculation.calculateVisitNote(outbound0)
        let selection1_2: String
        switch input.prescription.settlement {
        case .bank(let bank):
            selection1_2 = bank.bic
        default: selection1_2 = .init()
        }
        let outbound1 = Acme_Prescriptions_V1_ComparePrescriptionOptionsRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_ComparePrescriptionOptionsRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = input.prescription.billingAddress.postalCode
                }
            }
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.bank = Acme_Prescriptions_V1_PrescriptionBankSettlement.with {
                    $0.bic = selection1_2
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.locality = input.prescription.billingAddress.locality
                    $0.recipient = input.prescription.billingAddress.recipient
                }
            }
        }
        let reply1 = try await self.prescriptionsPrescriptionCalculation.comparePrescriptionOptions(outbound1)
        let outbound2 = Acme_Featureflags_V1_ListFeatureFlagsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Featureflags_V1_ListFeatureFlagsRequest.Filter.with {
                $0.createdAfter = reply1.prescription.audit.createdAt
                $0.region = reply0.visitNote.billingAddress.region
            }
        }
        let reply2 = try await self.normalizePrescriptionStep2.execute(outbound2)
        return Acme_Prescriptions_V1_NormalizePrescriptionResponse.with {
            $0.outcome = Acme_Prescriptions_V1_NormalizePrescriptionResponse.Outcome.with {
                $0.message = reply2.result.message
            }
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = reply1.prescription.billingAddress.postalCode
                }
                $0.counterparty = input.prescription.counterparty
                $0.issuedAt = reply1.prescription.issuedAt
                $0.prescriptionID = input.prescriptionID
                $0.total = reply0.visitNote.total
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processPreviewPrescription(_ input: Acme_Prescriptions_V1_PreviewPrescriptionRequest) async throws
        -> Acme_Prescriptions_V1_PreviewPrescriptionResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "audit", detail: input.details.contact.email
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "PreviewPrescription",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PrescriptionRecord(input.prescription, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let selection0_1: String
        switch input.prescription.settlement {
        case .card(let card):
            selection0_1 = card.network
        default: selection0_1 = .init()
        }
        let outbound0 = Acme_Prescriptions_V1_EstimatePrescriptionRequest.with {
            $0.context = input.context
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.card = Acme_Prescriptions_V1_PrescriptionCardSettlement.with {
                    $0.network = selection0_1
                }
            }
        }
        let reply0 = try await self.prescriptionsPrescriptionCalculation.estimatePrescription(outbound0)
        let requests1 = input.prescription.lines.map { element in
            Acme_Telehealth_V1_BrowseVisitNotesRequest.with {
                $0.context = input.context
                $0.filter = Acme_Telehealth_V1_BrowseVisitNotesRequest.Filter.with {
                    $0.createdAfter = reply0.prescription.audit.createdAt
                    $0.labels = element.attributes
                    $0.ownerID = element.lineID
                    $0.region = reply0.prescription.billingAddress.region
                }
            }
        }
        let replies1 = try await FanOut.map(requests1) { candidate in
            try await self.telehealthVisitNoteQuery.browseVisitNotes(candidate)
        }
        let reply1 = replies1.first ?? Acme_Telehealth_V1_BrowseVisitNotesResponse()
        _ = reply1
        return Acme_Prescriptions_V1_PreviewPrescriptionResponse.with {
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.billingAddress = reply0.prescription.billingAddress
                $0.metadata = input.prescription.metadata
                $0.prescriptionID = input.prescriptionID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processScorePrescription(_ input: Acme_Prescriptions_V1_ScorePrescriptionRequest) async throws
        -> Acme_Prescriptions_V1_ScorePrescriptionResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.currencyCode)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "audit", detail: input.details.currencyCode
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ScorePrescription",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PrescriptionRecord(input.prescription, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Metrics_V1_CountMetricSeriesesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Metrics_V1_CountMetricSeriesesRequest.Filter.with {
                $0.createdAfter = input.prescription.audit.createdAt
                $0.region = input.prescription.billingAddress.region
            }
        }
        let port0 = RPCOperations.port { (request: Acme_Metrics_V1_CountMetricSeriesesRequest) in
            try await self.metricsMetricSeriesQuery.countMetricSerieses(request)
        }
        let reply0 = try await port0.execute(outbound0)
        let outbound1 = Acme_Prescriptions_V1_GetPrescriptionRatesRequest.with {
            $0.context = input.context
            $0.prescriptionID = input.prescription.prescriptionID
        }
        let reply1 = try await self.scorePrescriptionStep1(outbound1)
        return Acme_Prescriptions_V1_ScorePrescriptionResponse.with {
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.number = input.prescription.number
                $0.prescriptionID = input.prescriptionID
                $0.total = reply1.prescription.total
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.details = reply0.result.details
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processValidatePrescription(_ input: Acme_Prescriptions_V1_ValidatePrescriptionRequest) async throws
        -> Acme_Prescriptions_V1_ValidatePrescriptionResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "audit", detail: input.details.contact.email
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ValidatePrescription",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PrescriptionRecord(input.prescription, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Prescriptions_V1_GetPrescriptionRatesRequest.with {
            $0.context = input.context
            $0.prescriptionID = input.prescription.prescriptionID
        }
        guard
            let execute0 = self.validatePrescriptionStep0[settings.region] ?? self.validatePrescriptionStep0["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply0 = try await execute0(outbound0)
        let outbound1 = Acme_Seating_V1_CompareSeatMapOptionsRequest.with {
            $0.context = input.context
            $0.seatMap = Acme_Seating_V1_SeatMap.with {
                $0.children = [
                    Acme_Seating_V1_SeatMap.with {
                        $0.children = [
                            Acme_Seating_V1_SeatMap.with {
                                $0.audit = Acme_Common_V1_AuditInfo.with {
                                    $0.updatedBy = input.prescription.audit.updatedBy
                                }
                                $0.location = Acme_Common_V1_PostalAddress.with {
                                    $0.countryCode = input.prescription.billingAddress.countryCode
                                }
                            }
                        ]
                    }
                ]
            }
        }
        let reply1 = try await self.seatingSeatMapCalculation.compareSeatMapOptions(outbound1)
        let selection2_1: String
        switch input.prescription.settlement {
        case .card(let card):
            selection2_1 = card.network
        default: selection2_1 = .init()
        }
        let selection2_2: String
        switch reply0.prescription.settlement {
        case .card(let card):
            selection2_2 = card.holderName
        default: selection2_2 = .init()
        }
        let outbound2 = Acme_Prescriptions_V1_RecalculatePrescriptionsRequest.with {
            $0.context = input.context
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.card = Acme_Prescriptions_V1_PrescriptionCardSettlement.with {
                    $0.holderName = selection2_2
                    $0.network = selection2_1
                }
            }
        }
        let reply2 = try await self.prescriptionsPrescriptionCalculation.recalculatePrescriptions(outbound2)
        let outbound3 = Acme_Notifications_V1_NormalizeNotificationRequest.with {
            $0.context = input.context
            $0.details = Acme_Notifications_V1_NormalizeNotificationRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.phone = input.details.contact.phone
                }
            }
            $0.notification = Acme_Notifications_V1_Notification.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = input.prescription.audit.updatedBy
                }
            }
        }
        let envelope3 = try Google_Protobuf_Any(message: outbound3)
        let unpacked3 = try Acme_Notifications_V1_NormalizeNotificationRequest(unpackingAny: envelope3)
        let reply3 = try await self.notificationsNotificationValidation.normalizeNotification(unpacked3)
        return Acme_Prescriptions_V1_ValidatePrescriptionResponse.with {
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply3.notification.audit.createdAt
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = reply2.prescription.counterparty.displayName
                    $0.patientID = reply0.prescription.counterparty.patientID
                }
                $0.dueAt = input.prescription.dueAt
                $0.prescriptionID = input.prescriptionID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply1.result.message
                $0.status = "ok"
            }
        }
    }
}
