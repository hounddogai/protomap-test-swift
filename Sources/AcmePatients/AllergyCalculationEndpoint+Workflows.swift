import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension AllergyCalculationEndpoint {
    /// Calculates an allergy.
    func calculateAllergy(
        request: ServerRequest<Acme_Patients_V1_CalculateAllergyRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_CalculateAllergyResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCalculateAllergy(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Compares an allergy.
    func compareAllergyOptions(
        request: ServerRequest<Acme_Patients_V1_CompareAllergyOptionsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_CompareAllergyOptionsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCompareAllergyOptions(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Estimates an allergy.
    func estimateAllergy(
        request: ServerRequest<Acme_Patients_V1_EstimateAllergyRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_EstimateAllergyResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processEstimateAllergy(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns an allergy.
    func getAllergyRates(
        request: ServerRequest<Acme_Patients_V1_GetAllergyRatesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_GetAllergyRatesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetAllergyRates(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Quotes an allergy.
    func quoteAllergy(
        request: ServerRequest<Acme_Patients_V1_QuoteAllergyRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_QuoteAllergyResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processQuoteAllergy(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Recalculates an allergy.
    func recalculateAllergies(
        request: ServerRequest<Acme_Patients_V1_RecalculateAllergiesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_RecalculateAllergiesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRecalculateAllergies(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Simulates an allergy.
    func simulateAllergy(
        request: ServerRequest<Acme_Patients_V1_SimulateAllergyRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_SimulateAllergyResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSimulateAllergy(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processCalculateAllergy(_ input: Acme_Patients_V1_CalculateAllergyRequest) async throws
        -> Acme_Patients_V1_CalculateAllergyResponse
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
            "CalculateAllergy",
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
        let importFrame = Acme_Telehealth_V1_BatchCreateVideoVisitsRequest.with {
            $0.context = input.context
        }
        _ = try await self.telehealthVideoVisit.batchCreateVideoVisits { writer in
            try await writer.write(importFrame)
        }
        let outbound0 = Acme_Appointments_V1_ScoreClinicSlotRequest.with {
            $0.context = input.context
            $0.details = Acme_Appointments_V1_ScoreClinicSlotRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = input.details.destination.countryCode
                    $0.recipient = input.details.destination.recipient
                }
            }
        }
        let reply0 = try await self.calculateAllergyStep0.execute(outbound0)
        let outbound1 = Acme_Patients_V1_NormalizePatientRequest.with {
            $0.context = input.context
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.locality = input.details.destination.locality
                }
            }
        }
        let port1 = RPCOperations.port { (request: Acme_Patients_V1_NormalizePatientRequest) in
            try await self.patientsPatientValidation.normalizePatient(request)
        }
        let reply1 = try await port1.execute(outbound1)
        let outbound2 = Acme_Prescriptions_V1_CalculatePrescriptionRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_CalculatePrescriptionRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = reply1.patient.primaryAddress.postalCode
                }
            }
        }
        let reply2 = try await self.calculateAllergyStep2(outbound2)
        return Acme_Patients_V1_CalculateAllergyResponse.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.allergyID = input.allergyID
                $0.correlationID = reply0.result.correlationID
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = reply2.prescription.counterparty.displayName
                    $0.patientID = reply2.prescription.counterparty.patientID
                }
            }
            $0.breakdown = Acme_Patients_V1_CalculateAllergyResponse.Breakdown.with {
                $0.currencyCode = input.details.currencyCode
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply1.outcome.status
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processCompareAllergyOptions(_ input: Acme_Patients_V1_CompareAllergyOptionsRequest) async throws
        -> Acme_Patients_V1_CompareAllergyOptionsResponse
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
            "CompareAllergyOptions",
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
        let outbound0 = Acme_Audit_V1_CheckAuditEventEligibilityRequest.with {
            $0.auditEvent = Acme_Audit_V1_AuditEvent.with {
                $0.correlationID = input.allergy.correlationID
                $0.kind = input.allergy.kind
                $0.subject = Acme_Audit_V1_AuditTrailRef.with {
                    $0.displayName = input.allergy.subject.displayName
                }
            }
            $0.context = input.context
        }
        guard
            let execute0 = self.compareAllergyOptionsStep0[settings.region]
                ?? self.compareAllergyOptionsStep0["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply0 = try await execute0(outbound0)
        let outbound1 = Acme_Patients_V1_ValidatePatientRequest.with {
            $0.context = input.context
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.recipient = input.details.destination.recipient
                }
            }
        }
        let reply1 = try await self.patientsPatientValidation.validatePatient(outbound1)
        return Acme_Patients_V1_CompareAllergyOptionsResponse.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.allergyID = input.allergyID
                $0.attributes = reply0.auditEvent.attributes
                $0.subject = input.allergy.subject
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.auditEvent.correlationID
                $0.message = reply1.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processEstimateAllergy(_ input: Acme_Patients_V1_EstimateAllergyRequest) async throws
        -> Acme_Patients_V1_EstimateAllergyResponse
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
            "EstimateAllergy",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try AllergyRecord(input.allergy, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Patients_V1_GetPatientRulesRequest.with {
            $0.context = input.context
            $0.patientID = input.allergy.subject.patientID
        }
        let envelope0 = try Google_Protobuf_Any(message: outbound0)
        let unpacked0 = try Acme_Patients_V1_GetPatientRulesRequest(unpackingAny: envelope0)
        let reply0 = try await self.patientsPatientValidation.getPatientRules(unpacked0)
        return Acme_Patients_V1_EstimateAllergyResponse.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.allergyID = input.allergyID
                $0.attributes = reply0.patient.attributes
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = input.allergy.correlationID
                $0.status = reply0.result.status
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processGetAllergyRates(_ input: Acme_Patients_V1_GetAllergyRatesRequest) async throws
        -> Acme_Patients_V1_GetAllergyRatesResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "GetAllergyRates",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "GetAllergyRates", detail: input.context.traceID
        )
        let outbound0 = Acme_Prescriptions_V1_LintMedicationsRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_LintMedicationsRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.context.actor.email
                }
                $0.locale = input.context.locale
            }
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.components = [
                    "primary": Acme_Prescriptions_V1_MedicationComponent.with {
                        $0.componentID = input.allergyID
                    }
                ]
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.context.actor.userID
                }
            }
        }
        let json0 = try outbound0.jsonString()
        let decoded0 = try Acme_Prescriptions_V1_LintMedicationsRequest(jsonString: json0)
        let reply0 = try await self.prescriptionsMedicationValidation.lintMedications(decoded0)
        let outbound1 =
            Acme_Patients_V1_ExplainMedicalRecordCalculationRequest.forAllergyCalculationEndpointGetAllergyRates1(
                input,
                reply0: reply0
            )
        let reply1 = try await self.patientsMedicalRecordCalculation.explainMedicalRecordCalculation(outbound1)
        return Acme_Patients_V1_GetAllergyRatesResponse.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.allergyID = input.allergyID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = Projection.firstValue(
                    [
                        reply0.result.correlationID,
                        reply1.result.correlationID,
                    ], default: .init())
                $0.message = reply0.outcome.message
                $0.status = reply1.outcome.status
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processQuoteAllergy(_ input: Acme_Patients_V1_QuoteAllergyRequest) async throws
        -> Acme_Patients_V1_QuoteAllergyResponse
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
            "QuoteAllergy",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try AllergyRecord(input.allergy, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let requests0 = input.allergy.measurements.map { element in
            Acme_Metrics_V1_CountMetricSeriesesRequest.with {
                $0.context = input.context
                $0.filter = Acme_Metrics_V1_CountMetricSeriesesRequest.Filter.with {
                    $0.createdAfter = element.observedAt
                }
            }
        }
        let replies0 = try await FanOut.map(requests0) { candidate in
            try await self.metricsMetricSeriesQuery.countMetricSerieses(candidate)
        }
        let reply0 = replies0.first ?? Acme_Metrics_V1_CountMetricSeriesesResponse()
        _ = reply0
        let outbound1 = Acme_Patients_V1_GetPatientRulesRequest.with {
            $0.context = input.context
            $0.patientID = input.allergy.subject.patientID
        }
        let reply1 = try await self.patientsPatientValidation.getPatientRules(
            outbound1, metadata: ["x-acme-region": .string(settings.region)]
        )
        let outbound2 = Acme_Documents_V1_CreateDocumentRequest.with {
            $0.context = input.context
            $0.document = Acme_Documents_V1_Document.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply1.patient.audit.createdAt
                    $0.etag = reply1.patient.audit.etag
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = reply1.patient.primaryAddress.countryCode
                }
            }
        }
        let reply2 = try await RPCOperations.call(outbound2) { request in
            try await self.documentsDocument.createDocument(request)
        }
        let outbound3 = Acme_Documents_V1_CheckDocumentEligibilityRequest.with {
            $0.context = Projection.read(input, at: \Acme_Patients_V1_QuoteAllergyRequest.context)
            $0.document = Acme_Documents_V1_Document.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = Projection.read(
                        reply2, at: \Acme_Documents_V1_CreateDocumentResponse.document.audit.createdAt)
                    $0.createdBy = Projection.read(
                        reply1, at: \Acme_Patients_V1_GetPatientRulesResponse.patient.audit.createdBy)
                    $0.etag = Projection.read(reply1, at: \Acme_Patients_V1_GetPatientRulesResponse.patient.audit.etag)
                }
            }
        }
        let reply3 = try await self.documentsDocumentValidation.checkDocumentEligibility(outbound3)
        return Acme_Patients_V1_QuoteAllergyResponse.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.allergyID = input.allergyID
            }
            $0.breakdown = Acme_Patients_V1_QuoteAllergyResponse.Breakdown.with {
                $0.currencyCode = input.details.currencyCode
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = Projection.firstValue(
                    [
                        reply1.result.details,
                        reply2.result.details,
                    ], default: .init())
                $0.referenceIds = reply3.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processRecalculateAllergies(_ input: Acme_Patients_V1_RecalculateAllergiesRequest) async throws
        -> Acme_Patients_V1_RecalculateAllergiesResponse
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
            "RecalculateAllergies",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try AllergyRecord(input.allergy, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Prescriptions_V1_LintMedicationsRequest.with {
            $0.context = input.context
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.address = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.details.destination.region
                }
            }
        }
        let step0: @Sendable () async throws -> Acme_Prescriptions_V1_LintMedicationsResponse = {
            try await self.prescriptionsMedicationValidation.lintMedications(outbound0)
        }
        let reply0 = try await step0()
        let selection1_1: String
        switch reply0.medication.locator {
        case .address(let address):
            selection1_1 = address.postalCode
        default: selection1_1 = .init()
        }
        let selection1_3: String
        switch reply0.medication.locator {
        case .address(let address):
            selection1_3 = address.locality
        default: selection1_3 = .init()
        }
        let outbound1 = Acme_Documents_V1_LintDocumentsRequest.with {
            $0.context = input.context
            $0.document = Acme_Documents_V1_Document.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply0.medication.audit.etag
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.locality = selection1_3
                    $0.postalCode = selection1_1
                }
                $0.counterparty = Acme_Documents_V1_DocumentFolderRef.with {
                    $0.displayName = reply0.medication.owner.displayName
                }
            }
        }
        let reply1 = try await self.documentsDocumentValidation.lintDocuments(outbound1)
        return Acme_Patients_V1_RecalculateAllergiesResponse.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.allergyID = input.allergyID
                $0.kind = input.allergy.kind
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = reply0.medication.owner.displayName
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply1.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processSimulateAllergy(_ input: Acme_Patients_V1_SimulateAllergyRequest) async throws
        -> Acme_Patients_V1_SimulateAllergyResponse
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
            "SimulateAllergy",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try AllergyRecord(input.allergy, tenant: input.context.tenantID)
        try await store.save(record.stored)
        var outbound0 = Acme_Patients_V1_QuoteMedicalRecordRequest()
        outbound0.context = input.context
        outbound0.details = Acme_Patients_V1_QuoteMedicalRecordRequest.Details.with {
            $0.destination = Acme_Common_V1_PostalAddress.with {
                $0.postalCode = input.details.destination.postalCode
            }
        }
        outbound0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
            $0.counterparty = Acme_Patients_V1_PatientRef.with {
                $0.patientID = input.allergy.subject.patientID
            }
        }
        let reply0 = try await self.patientsMedicalRecordCalculation.quoteMedicalRecord(outbound0)
        let requests1 = input.allergy.measurements.map { element in
            Acme_Audit_V1_ValidateAuditEventRequest.with {
                $0.auditEvent = Acme_Audit_V1_AuditEvent.with {
                    $0.measurements = [
                        Acme_Audit_V1_AuditEventMeasurement.with {
                            $0.metric = element.metric
                            $0.observedAt = element.observedAt
                            $0.unit = element.unit
                            $0.value = element.value
                        }
                    ]
                }
                $0.context = input.context
            }
        }
        let replies1 = try await FanOut.map(requests1) { candidate in
            try await self.auditAuditEventValidation.validateAuditEvent(candidate)
        }
        let reply1 = replies1.first ?? Acme_Audit_V1_ValidateAuditEventResponse()
        _ = reply1
        return Acme_Patients_V1_SimulateAllergyResponse.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.allergyID = input.allergyID
                $0.attributes = input.allergy.attributes
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.email = reply0.medicalRecord.counterparty.email
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }
}
