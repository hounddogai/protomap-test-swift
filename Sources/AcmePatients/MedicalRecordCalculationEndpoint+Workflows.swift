import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension MedicalRecordCalculationEndpoint {
    /// Execute the patients workflow and project its upstream replies.
    func processCalculateMedicalRecord(_ input: Acme_Patients_V1_CalculateMedicalRecordRequest) async throws
        -> Acme_Patients_V1_CalculateMedicalRecordResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.currencyCode)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "audit", detail: input.details.currencyCode
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "CalculateMedicalRecord",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicalRecordRecord(input.medicalRecord, tenant: input.context.tenantID)
        try await store.save(record.stored)
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        try followUps.submit(
            Acme_Identity_V1_GetUserRequest.with {
                $0.context = input.context
                $0.userID = input.context.actor.userID
            })
        let importFrame = Acme_Prescriptions_V1_BatchCreatePrescriptionsRequest.with {
            $0.context = input.context
        }
        _ = try await self.prescriptionsPrescription.batchCreatePrescriptions { writer in
            try await writer.write(importFrame)
        }
        let outbound0 = Acme_Patients_V1_ExplainPatientCalculationRequest.with {
            $0.context = input.context
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = input.medicalRecord.audit.etag
                }
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.medicalRecord.counterparty.displayName
                    $0.email = input.medicalRecord.counterparty.email
                }
            }
        }
        let envelope0 = try Google_Protobuf_Any(message: outbound0)
        let unpacked0 = try Acme_Patients_V1_ExplainPatientCalculationRequest(unpackingAny: envelope0)
        let reply0 = try await self.patientsPatientCalculation.explainPatientCalculation(unpacked0)
        let outbound1 = Acme_Patients_V1_CalculatePatientRequest.with {
            $0.context = input.context
            $0.details = Acme_Patients_V1_CalculatePatientRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = reply0.patient.primaryAddress.countryCode
                }
            }
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.details.destination.region
                }
            }
        }
        let json1 = try outbound1.jsonString()
        let decoded1 = try Acme_Patients_V1_CalculatePatientRequest(jsonString: json1)
        let reply1 = try await self.patientsPatientCalculation.calculatePatient(decoded1)
        return Acme_Patients_V1_CalculateMedicalRecordResponse.with {
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.lines = reply1.patient.primaryAddress.lines
                    $0.region = reply0.patient.primaryAddress.region
                }
                $0.issuedAt = input.medicalRecord.issuedAt
                $0.medicalRecordID = input.medicalRecordID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processCompareMedicalRecordOptions(_ input: Acme_Patients_V1_CompareMedicalRecordOptionsRequest) async throws
        -> Acme_Patients_V1_CompareMedicalRecordOptionsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.currencyCode)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "audit", detail: input.details.currencyCode
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "CompareMedicalRecordOptions",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicalRecordRecord(input.medicalRecord, tenant: input.context.tenantID)
        try await store.save(record.stored)
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        let outbound0 =
            Acme_Patients_V1_RecalculatePatientsRequest.forMedicalRecordCalculationEndpointCompareMedicalRecordOptions0(
                input
            )
        let reply0 = try await self.patientsPatientCalculation.recalculatePatients(outbound0)
        let outbound1 = Acme_Prescriptions_V1_ListPrescriptionsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Prescriptions_V1_ListPrescriptionsRequest.Filter.with {
                $0.createdAfter = reply0.patient.audit.createdAt
                $0.ownerID = reply0.patient.relationshipManager.userID
                $0.region = reply0.patient.primaryAddress.region
            }
        }
        let reply1 = try await self.prescriptionsPrescription.listPrescriptions(
            outbound1, metadata: ["x-acme-region": .string(settings.region)]
        )
        return Acme_Patients_V1_CompareMedicalRecordOptionsResponse.with {
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.lines = reply0.patient.primaryAddress.lines
                }
                $0.medicalRecordID = input.medicalRecordID
                $0.notes = input.medicalRecord.notes
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply1.result.details
                $0.referenceIds = reply1.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processEstimateMedicalRecord(_ input: Acme_Patients_V1_EstimateMedicalRecordRequest) async throws
        -> Acme_Patients_V1_EstimateMedicalRecordResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.currencyCode)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "audit", detail: input.details.currencyCode
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "EstimateMedicalRecord",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicalRecordRecord(input.medicalRecord, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Patients_V1_GetPatientRatesRequest.with {
            $0.context = input.context
            $0.patientID = input.medicalRecord.counterparty.patientID
        }
        let reply0 = try await RPCOperations.call(outbound0) { request in
            try await self.patientsPatientCalculation.getPatientRates(request)
        }
        let selection1_2: Google_Protobuf_Timestamp
        switch reply0.patient.identityDocument {
        case .passport(let passport):
            selection1_2 = passport.expiresAt
        default: selection1_2 = .init()
        }
        let outbound1 = Acme_Telehealth_V1_CountVisitNotesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Telehealth_V1_CountVisitNotesRequest.Filter.with {
                $0.createdAfter = selection1_2
                $0.labels = input.medicalRecord.metadata
                $0.region = input.medicalRecord.billingAddress.region
            }
        }
        let reply1 = try await self.telehealthVisitNoteQuery.countVisitNotes(outbound1)
        return Acme_Patients_V1_EstimateMedicalRecordResponse.with {
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.billingAddress = input.medicalRecord.billingAddress
                $0.medicalRecordID = input.medicalRecordID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.message = reply0.result.message
                $0.status = reply1.result.status
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processExplainMedicalRecordCalculation(_ input: Acme_Patients_V1_ExplainMedicalRecordCalculationRequest)
        async throws -> Acme_Patients_V1_ExplainMedicalRecordCalculationResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.phone)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "audit", detail: input.details.contact.phone
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ExplainMedicalRecordCalculation",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicalRecordRecord(input.medicalRecord, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Patients_V1_ExplainPatientCalculationRequest.with {
            $0.context = Projection.read(input, at: \Acme_Patients_V1_ExplainMedicalRecordCalculationRequest.context)
            $0.details = Acme_Patients_V1_ExplainPatientCalculationRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.name = Projection.read(
                        input, at: \Acme_Patients_V1_ExplainMedicalRecordCalculationRequest.details.contact.name)
                }
            }
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = Projection.read(
                        input,
                        at: \Acme_Patients_V1_ExplainMedicalRecordCalculationRequest.medicalRecord.audit.createdBy)
                }
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = Projection.read(
                        input,
                        at: \Acme_Patients_V1_ExplainMedicalRecordCalculationRequest.medicalRecord.counterparty.email)
                }
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.email = Projection.read(
                        input, at: \Acme_Patients_V1_ExplainMedicalRecordCalculationRequest.details.contact.email)
                }
            }
        }
        let reply0 = try await self.patientsPatientCalculation.explainPatientCalculation(outbound0)
        let requests1 = input.medicalRecord.lines.map { element in
            Acme_Prescriptions_V1_CountPrescriptionsRequest.with {
                $0.context = input.context
                $0.filter = Acme_Prescriptions_V1_CountPrescriptionsRequest.Filter.with {
                    $0.ownerID = element.lineID
                    $0.region = input.medicalRecord.billingAddress.region
                }
            }
        }
        let replies1 = try await FanOut.map(requests1) { candidate in
            try await self.prescriptionsPrescriptionQuery.countPrescriptions(candidate)
        }
        let reply1 = replies1.first ?? Acme_Prescriptions_V1_CountPrescriptionsResponse()
        _ = reply1
        let outbound2 = Acme_Patients_V1_RecalculatePatientsRequest.with {
            $0.context = input.context
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.locality = reply0.patient.primaryAddress.locality
                }
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.email = reply0.patient.contact.email
                }
            }
        }
        let step2: @Sendable () async throws -> Acme_Patients_V1_RecalculatePatientsResponse = {
            try await self.patientsPatientCalculation.recalculatePatients(outbound2)
        }
        let reply2 = try await step2()
        return Acme_Patients_V1_ExplainMedicalRecordCalculationResponse.with {
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply2.patient.audit.createdAt
                    $0.etag = reply0.patient.audit.etag
                }
                $0.medicalRecordID = input.medicalRecordID
                $0.notes = input.medicalRecord.notes
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.outcome.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processGetMedicalRecordRates(_ input: Acme_Patients_V1_GetMedicalRecordRatesRequest) async throws
        -> Acme_Patients_V1_GetMedicalRecordRatesResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "GetMedicalRecordRates",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "GetMedicalRecordRates", detail: input.context.traceID
        )
        var outbound0 = Acme_Patients_V1_CalculatePatientRequest()
        outbound0.context = input.context
        outbound0.patient = Acme_Patients_V1_Patient.with {
            $0.attributes = input.context.baggage
            $0.contact = Acme_Common_V1_ContactInfo.with {
                $0.email = input.context.actor.email
            }
            $0.passport = Acme_Patients_V1_PatientPassport.with {
                $0.expiresAt = input.context.deadline
            }
            $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                $0.userID = input.context.actor.userID
            }
        }
        let reply0 = try await self.patientsPatientCalculation.calculatePatient(outbound0)
        return Acme_Patients_V1_GetMedicalRecordRatesResponse.with {
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply0.patient.audit.etag
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = reply0.patient.primaryAddress.region
                }
                $0.medicalRecordID = input.medicalRecordID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processQuoteMedicalRecord(_ input: Acme_Patients_V1_QuoteMedicalRecordRequest) async throws
        -> Acme_Patients_V1_QuoteMedicalRecordResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.currencyCode)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "audit", detail: input.details.currencyCode
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "QuoteMedicalRecord",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicalRecordRecord(input.medicalRecord, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Venues_V1_UpdateVenueRequest.with {
            $0.context = input.context
            $0.venue = Acme_Venues_V1_Venue.with {
                $0.address = Acme_Common_V1_PostalAddress.with {
                    $0.locality = input.medicalRecord.billingAddress.locality
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = input.medicalRecord.audit.etag
                }
            }
        }
        let step0: @Sendable () async throws -> Acme_Venues_V1_UpdateVenueResponse = {
            try await self.venuesVenue.updateVenue(outbound0)
        }
        let reply0 = try await step0()
        let outbound1 = Acme_Documents_V1_NormalizeDocumentRequest.with {
            $0.context = input.context
            $0.document = Acme_Documents_V1_Document.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply0.venue.audit.createdAt
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.locality = input.details.destination.locality
                }
            }
        }
        let reply1 = try await self.documentsDocumentValidation.normalizeDocument(outbound1)
        return Acme_Patients_V1_QuoteMedicalRecordResponse.with {
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply0.venue.audit.createdAt
                    $0.updatedBy = reply1.document.audit.updatedBy
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = reply1.document.billingAddress.region
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = reply0.venue.owner.displayName
                }
                $0.medicalRecordID = input.medicalRecordID
                $0.notes = input.medicalRecord.notes
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processSimulateMedicalRecord(_ input: Acme_Patients_V1_SimulateMedicalRecordRequest) async throws
        -> Acme_Patients_V1_SimulateMedicalRecordResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.currencyCode)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "audit", detail: input.details.currencyCode
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SimulateMedicalRecord",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicalRecordRecord(input.medicalRecord, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Ledger_V1_SearchLedgerAccountsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Ledger_V1_SearchLedgerAccountsRequest.Filter.with {
                $0.createdAfter = input.medicalRecord.audit.createdAt
                $0.ownerID = input.medicalRecord.counterparty.patientID
                $0.region = input.medicalRecord.billingAddress.region
            }
        }
        async let remote0 = self.ledgerLedgerAccount.searchLedgerAccounts(outbound0)
        async let persisted0 = store.count(tenant: input.context.tenantID)
        let (reply0, count0) = try await (remote0, persisted0)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count0)])
        let outbound1 = Acme_Prescriptions_V1_CalculateRefillRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_CalculateRefillRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.lines = input.details.destination.lines
                    $0.postalCode = input.details.destination.postalCode
                }
            }
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.medicalRecord.counterparty.email
                }
            }
        }
        let reply1 = try await self.simulateMedicalRecordStep1.execute(outbound1)
        return Acme_Patients_V1_SimulateMedicalRecordResponse.with {
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.email = reply1.refill.assignee.email
                }
                $0.medicalRecordID = input.medicalRecordID
                $0.number = input.medicalRecord.number
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }
}
