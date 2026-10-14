import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension AllergyValidationEndpoint {
    /// Execute the patients workflow and project its upstream replies.
    func processCheckAllergyEligibility(_ input: Acme_Patients_V1_CheckAllergyEligibilityRequest) async throws
        -> Acme_Patients_V1_CheckAllergyEligibilityResponse
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
            "CheckAllergyEligibility",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try AllergyRecord(input.allergy, tenant: input.context.tenantID)
        try await store.save(record.stored)
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        let importFrame = Acme_Prescriptions_V1_BatchCreatePrescriptionsRequest.with {
            $0.context = input.context
        }
        _ = try await self.prescriptionsPrescription.batchCreatePrescriptions { writer in
            try await writer.write(importFrame)
        }
        let outbound0 = Acme_Metrics_V1_PreviewMetricSeriesRequest.with {
            $0.context = input.context
            $0.details = Acme_Metrics_V1_PreviewMetricSeriesRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.name = input.details.contact.name
                }
            }
        }
        let step0: @Sendable () async throws -> Acme_Metrics_V1_PreviewMetricSeriesResponse = {
            try await self.metricsMetricSeriesValidation.previewMetricSeries(outbound0)
        }
        let reply0 = try await step0()
        return Acme_Patients_V1_CheckAllergyEligibilityResponse.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.allergyID = input.allergyID
                $0.sequence = input.allergy.sequence
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.outcome.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processGetAllergyRules(_ input: Acme_Patients_V1_GetAllergyRulesRequest) async throws
        -> Acme_Patients_V1_GetAllergyRulesResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "GetAllergyRules",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "GetAllergyRules", detail: input.context.traceID
        )
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        return Acme_Patients_V1_GetAllergyRulesResponse.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.allergyID = input.allergyID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processLintAllergies(_ input: Acme_Patients_V1_LintAllergiesRequest) async throws
        -> Acme_Patients_V1_LintAllergiesResponse
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
            "LintAllergies",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try AllergyRecord(input.allergy, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let requests0 = input.allergy.measurements.map { element in
            Acme_Patients_V1_QuoteAllergyRequest.with {
                $0.allergy = Acme_Patients_V1_Allergy.with {
                    $0.measurements = [
                        Acme_Patients_V1_AllergyMeasurement.with {
                            $0.observedAt = element.observedAt
                            $0.unit = element.unit
                        }
                    ]
                }
                $0.context = input.context
            }
        }
        let replies0 = try await FanOut.map(requests0) { candidate in
            try await self.patientsAllergyCalculation.quoteAllergy(candidate)
        }
        let reply0 = replies0.first ?? Acme_Patients_V1_QuoteAllergyResponse()
        var outbound1 = Acme_Patients_V1_QuoteMedicalRecordRequest()
        outbound1.context = input.context
        outbound1.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
            $0.counterparty = Acme_Patients_V1_PatientRef.with {
                $0.email = reply0.allergy.subject.email
            }
            $0.lines = [
                Acme_Patients_V1_MedicalRecordLine.with {
                    $0.attributes = input.allergy.attributes
                }
            ]
        }
        let reply1 = try await self.patientsMedicalRecordCalculation.quoteMedicalRecord(outbound1)
        let outbound2 = Acme_Patients_V1_GetPatientRulesRequest.with {
            $0.context = input.context
            $0.patientID = input.allergy.subject.patientID
        }
        let reply2 = try await RPCOperations.read {
            try await self.patientsPatientValidation.getPatientRules(outbound2)
        }
        return Acme_Patients_V1_LintAllergiesResponse.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.allergyID = input.allergyID
                $0.kind = input.allergy.kind
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.email = reply2.patient.contact.email
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply2.result.correlationID
                $0.details = reply1.result.details
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processNormalizeAllergy(_ input: Acme_Patients_V1_NormalizeAllergyRequest) async throws
        -> Acme_Patients_V1_NormalizeAllergyResponse
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
            "NormalizeAllergy",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try AllergyRecord(input.allergy, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Prescriptions_V1_ValidateMedicationRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_ValidateMedicationRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.contact.email
                    $0.phone = input.details.contact.phone
                }
            }
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.allergy.subject.displayName
                }
            }
        }
        let reply0 = try await self.prescriptionsMedicationValidation.validateMedication(outbound0)
        let outbound1 = Acme_Patients_V1_NormalizePatientRequest.with {
            $0.context = input.context
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply0.medication.owner.email
                }
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.email = input.allergy.subject.email
                }
            }
        }
        async let remote1 = self.patientsPatientValidation.normalizePatient(outbound1)
        async let persisted1 = store.count(tenant: input.context.tenantID)
        let (reply1, count1) = try await (remote1, persisted1)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count1)])
        return Acme_Patients_V1_NormalizeAllergyResponse.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.allergyID = input.allergyID
                $0.attributes = reply1.patient.attributes
                $0.correlationID = reply0.result.correlationID
                $0.subject = input.allergy.subject
            }
            $0.outcome = Acme_Patients_V1_NormalizeAllergyResponse.Outcome.with {
                $0.status = Projection.firstValue(
                    [
                        reply0.outcome.status,
                        reply1.result.status,
                    ], default: .init())
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processPreviewAllergy(_ input: Acme_Patients_V1_PreviewAllergyRequest) async throws
        -> Acme_Patients_V1_PreviewAllergyResponse
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
            "PreviewAllergy",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try AllergyRecord(input.allergy, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Sponsorships_V1_SimulateSponsorRequest.with {
            $0.context = input.context
            $0.sponsor = Acme_Sponsorships_V1_Sponsor.with {
                $0.contact = input.details.contact
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.allergy.subject.displayName
                    $0.email = input.allergy.subject.email
                }
            }
        }
        let reply0 = try await self.previewAllergyStep0.execute(outbound0)
        let requests1 = input.allergy.measurements.map { element in
            Acme_Patients_V1_CalculateAllergyRequest.with {
                $0.allergy = Acme_Patients_V1_Allergy.with {
                    $0.measurements = [
                        Acme_Patients_V1_AllergyMeasurement.with {
                            $0.unit = element.unit
                        }
                    ]
                }
                $0.context = input.context
            }
        }
        let replies1 = try await FanOut.map(requests1) { candidate in
            try await self.patientsAllergyCalculation.calculateAllergy(candidate)
        }
        let reply1 = replies1.first ?? Acme_Patients_V1_CalculateAllergyResponse()
        _ = reply1
        return Acme_Patients_V1_PreviewAllergyResponse.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.allergyID = input.allergyID
                $0.correlationID = input.allergy.correlationID
            }
            $0.outcome = Acme_Patients_V1_PreviewAllergyResponse.Outcome.with {
                $0.message = reply0.result.message
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processScoreAllergy(_ input: Acme_Patients_V1_ScoreAllergyRequest) async throws
        -> Acme_Patients_V1_ScoreAllergyResponse
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
            "ScoreAllergy",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try AllergyRecord(input.allergy, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Boxoffice_V1_ExplainBoxOfficeSaleCalculationRequest.with {
            $0.boxOfficeSale = Acme_Boxoffice_V1_BoxOfficeSale.with {
                $0.counterparty = Acme_Boxoffice_V1_CashDrawerRef.with {
                    $0.currencyCode = input.details.currencyCode
                }
                $0.lines = [
                    Acme_Boxoffice_V1_BoxOfficeSaleLine.with {
                        $0.attributes = input.allergy.attributes
                    }
                ]
            }
            $0.context = input.context
        }
        let port0 = RPCOperations.port { (request: Acme_Boxoffice_V1_ExplainBoxOfficeSaleCalculationRequest) in
            try await self.boxofficeBoxOfficeSaleCalculation.explainBoxOfficeSaleCalculation(request)
        }
        let reply0 = try await port0.execute(outbound0)
        let outbound1 = Acme_Patients_V1_NormalizePatientRequest.with {
            $0.context = input.context
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = input.details.destination.postalCode
                }
            }
        }
        let reply1 = try await self.scoreAllergyStep1(outbound1)
        let outbound2 = Acme_Authorization_V1_LintAccessPoliciesRequest.with {
            $0.accessPolicy = Acme_Authorization_V1_AccessPolicy.with {
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.email = input.allergy.subject.email
                }
            }
            $0.context = input.context
        }
        guard let execute2 = self.scoreAllergyStep2[settings.region] ?? self.scoreAllergyStep2["primary"] else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply2 = try await execute2(outbound2)
        let selection3_1: Acme_Common_V1_Money
        switch reply2.accessPolicy.action {
        case .discount(let discount):
            selection3_1 = discount.amount
        default: selection3_1 = .init()
        }
        let outbound3 = Acme_Documents_V1_CheckDocumentEligibilityRequest.with {
            $0.context = input.context
            $0.document = Acme_Documents_V1_Document.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply0.boxOfficeSale.audit.updatedBy
                }
                $0.lines = [
                    Acme_Documents_V1_DocumentLine.with {
                        $0.tax = Acme_Documents_V1_DocumentLineTax.with {
                            $0.amount = selection3_1
                        }
                    }
                ]
            }
        }
        let reply3 = try await self.documentsDocumentValidation.checkDocumentEligibility(outbound3)
        return Acme_Patients_V1_ScoreAllergyResponse.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.allergyID = input.allergyID
                $0.correlationID = reply3.result.correlationID
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.email = Projection.firstValue(
                        [
                            reply1.patient.contact.email,
                            reply2.accessPolicy.owner.email,
                        ], default: .init())
                }
            }
            $0.breakdown = Acme_Patients_V1_ScoreAllergyResponse.Breakdown.with {
                $0.currencyCode = reply0.boxOfficeSale.counterparty.currencyCode
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = input.allergy.correlationID
                $0.details = Projection.firstValue(
                    [
                        reply1.result.details,
                        reply2.result.details,
                    ], default: .init())
                $0.message = reply0.outcome.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processValidateAllergy(_ input: Acme_Patients_V1_ValidateAllergyRequest) async throws
        -> Acme_Patients_V1_ValidateAllergyResponse
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
            "ValidateAllergy",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try AllergyRecord(input.allergy, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Authorization_V1_PreviewAccessPolicyRequest.with {
            $0.accessPolicy = Acme_Authorization_V1_AccessPolicy.with {
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.allergy.subject.displayName
                }
            }
            $0.context = input.context
            $0.details = Acme_Authorization_V1_PreviewAccessPolicyRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.contact.email
                    $0.phone = input.details.contact.phone
                }
            }
        }
        let reply0 = try await self.authorizationAccessPolicyValidation.previewAccessPolicy(outbound0)
        let outbound1 = Acme_Patients_V1_GetPatientRulesRequest.with {
            $0.context = input.context
            $0.patientID = input.allergy.subject.patientID
        }
        let envelope1 = try Google_Protobuf_Any(message: outbound1)
        let unpacked1 = try Acme_Patients_V1_GetPatientRulesRequest(unpackingAny: envelope1)
        let reply1 = try await self.patientsPatientValidation.getPatientRules(unpacked1)
        let outbound2 = Acme_Patients_V1_CompareAllergyOptionsRequest.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = reply1.patient.relationshipManager.displayName
                    $0.email = reply1.patient.relationshipManager.email
                    $0.patientID = reply1.patient.patientID
                }
            }
            $0.context = input.context
            $0.details = Acme_Patients_V1_CompareAllergyOptionsRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.recipient = reply1.patient.primaryAddress.recipient
                }
            }
        }
        let json2 = try outbound2.jsonString()
        let decoded2 = try Acme_Patients_V1_CompareAllergyOptionsRequest(jsonString: json2)
        let reply2 = try await self.patientsAllergyCalculation.compareAllergyOptions(decoded2)
        return Acme_Patients_V1_ValidateAllergyResponse.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.allergyID = input.allergyID
                $0.sequence = input.allergy.sequence
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = reply2.allergy.subject.displayName
                    $0.email = reply1.patient.contact.email
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply1.result.details
                $0.status = reply0.result.status
            }
        }
    }
}
