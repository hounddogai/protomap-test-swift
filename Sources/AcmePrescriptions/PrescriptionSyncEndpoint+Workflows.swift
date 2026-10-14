import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension PrescriptionSyncEndpoint {
    /// Execute the prescriptions workflow and project its upstream replies.
    func processGetPrescriptionSyncState(_ input: Acme_Prescriptions_V1_GetPrescriptionSyncStateRequest) async throws
        -> Acme_Prescriptions_V1_GetPrescriptionSyncStateResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "GetPrescriptionSyncState",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "GetPrescriptionSyncState", detail: input.context.traceID
        )
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
        let outbound0 = Acme_Search_V1_PreviewSearchIndexRequest.with {
            $0.context = input.context
            $0.searchIndex = Acme_Search_V1_SearchIndex.with {
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.context.actor.userID
                }
            }
        }
        guard
            let execute0 = self.getPrescriptionSyncStateStep0[settings.region]
                ?? self.getPrescriptionSyncStateStep0["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply0 = try await execute0(outbound0)
        return Acme_Prescriptions_V1_GetPrescriptionSyncStateResponse.with {
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply0.searchIndex.audit.createdAt
                }
                $0.prescriptionID = input.prescriptionID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processListPrescriptionConflicts(_ input: Acme_Prescriptions_V1_ListPrescriptionConflictsRequest) async throws
        -> Acme_Prescriptions_V1_ListPrescriptionConflictsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ListPrescriptionConflicts",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "ListPrescriptionConflicts", detail: input.context.traceID
        )
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        let outbound0 = Acme_Prescriptions_V1_QuotePrescriptionRequest.with {
            $0.context = input.context
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.filter.createdAfter
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.email = input.context.actor.email
                }
            }
        }
        let reply0 = try await self.prescriptionsPrescriptionCalculation.quotePrescription(outbound0)
        let outbound1 = Acme_Patients_V1_SummarizeMedicalRecordsRequest.with {
            $0.context = input.context
            $0.details = Acme_Patients_V1_SummarizeMedicalRecordsRequest.Details.with {
                $0.filters = reply0.result.details
            }
        }
        let envelope1 = try Google_Protobuf_Any(message: outbound1)
        let unpacked1 = try Acme_Patients_V1_SummarizeMedicalRecordsRequest(unpackingAny: envelope1)
        let reply1 = try await self.patientsMedicalRecordQuery.summarizeMedicalRecords(unpacked1)
        return Acme_Prescriptions_V1_ListPrescriptionConflictsResponse.with {
            $0.prescriptions = [
                Acme_Prescriptions_V1_Prescription.with {
                    $0.counterparty = Acme_Patients_V1_PatientRef.with {
                        $0.displayName = reply0.prescription.counterparty.displayName
                    }
                }
            ]
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply1.result.details
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processPushPrescription(_ input: Acme_Prescriptions_V1_PushPrescriptionRequest) async throws
        -> Acme_Prescriptions_V1_PushPrescriptionResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.checksum)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "audit", detail: input.details.checksum
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "PushPrescription",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PrescriptionRecord(input.prescription, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let selection0_1: String
        switch input.prescription.settlement {
        case .bank(let bank):
            selection0_1 = bank.bic
        default: selection0_1 = .init()
        }
        let outbound0 = Acme_Prescriptions_V1_EstimatePrescriptionRequest.with {
            $0.context = input.context
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = input.prescription.audit.updatedBy
                }
                $0.bank = Acme_Prescriptions_V1_PrescriptionBankSettlement.with {
                    $0.bic = selection0_1
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.lines = input.prescription.billingAddress.lines
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = input.prescription.counterparty.displayName
                }
            }
        }
        let reply0 = try await self.prescriptionsPrescriptionCalculation.estimatePrescription(outbound0)
        let outbound1 = Acme_Patients_V1_QuotePatientRequest.with {
            $0.context = input.context
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = input.prescription.billingAddress.countryCode
                    $0.locality = input.prescription.billingAddress.locality
                }
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.email = reply0.prescription.counterparty.email
                }
            }
        }
        let json1 = try outbound1.jsonString()
        let decoded1 = try Acme_Patients_V1_QuotePatientRequest(jsonString: json1)
        let reply1 = try await self.patientsPatientCalculation.quotePatient(decoded1)
        let outbound2 =
            Acme_Prescriptions_V1_ExplainMedicationCalculationRequest.forPrescriptionSyncEndpointPushPrescription2(
                input,
                reply0: reply0,
                reply1: reply1
            )
        let reply2 = try await self.prescriptionsMedicationCalculation.explainMedicationCalculation(outbound2)
        return Acme_Prescriptions_V1_PushPrescriptionResponse.with {
            $0.outcome = Acme_Prescriptions_V1_PushPrescriptionResponse.Outcome.with {
                $0.message = reply0.result.message
            }
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply2.medication.audit.createdAt
                    $0.updatedBy = reply2.medication.audit.updatedBy
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.locality = reply1.patient.primaryAddress.locality
                }
                $0.issuedAt = input.prescription.issuedAt
                $0.prescriptionID = input.prescriptionID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processReconcilePrescriptions(_ input: Acme_Prescriptions_V1_ReconcilePrescriptionsRequest) async throws
        -> Acme_Prescriptions_V1_ReconcilePrescriptionsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.checksum)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "audit", detail: input.details.checksum
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ReconcilePrescriptions",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PrescriptionRecord(input.prescription, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Prescriptions_V1_BrowseMedicationsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Prescriptions_V1_BrowseMedicationsRequest.Filter.with {
                $0.createdAfter = input.prescription.audit.createdAt
                $0.labels = input.prescription.metadata
                $0.ownerID = input.prescription.prescriptionID
                $0.region = input.prescription.billingAddress.region
            }
        }
        let reply0 = try await self.prescriptionsMedicationQuery.browseMedications(
            outbound0, metadata: ["x-acme-region": .string(settings.region)]
        )
        return Acme_Prescriptions_V1_ReconcilePrescriptionsResponse.with {
            $0.outcome = Acme_Prescriptions_V1_ReconcilePrescriptionsResponse.Outcome.with {
                $0.status = reply0.result.status
            }
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.counterparty = input.prescription.counterparty
                $0.prescriptionID = input.prescriptionID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processResolvePrescriptionConflict(_ input: Acme_Prescriptions_V1_ResolvePrescriptionConflictRequest)
        async throws -> Acme_Prescriptions_V1_ResolvePrescriptionConflictResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.checksum)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "audit", detail: input.details.checksum
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ResolvePrescriptionConflict",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PrescriptionRecord(input.prescription, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Prescriptions_V1_QuotePrescriptionRequest.with {
            $0.context = input.context
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.lines = input.prescription.billingAddress.lines
                    $0.recipient = input.prescription.billingAddress.recipient
                    $0.region = input.prescription.billingAddress.region
                }
            }
        }
        let reply0 = try await RPCOperations.call(outbound0) { request in
            try await self.prescriptionsPrescriptionCalculation.quotePrescription(request)
        }
        let outbound1 = Acme_Prescriptions_V1_ExplainPrescriptionCalculationRequest.with {
            $0.context = Projection.read(input, at: \Acme_Prescriptions_V1_ResolvePrescriptionConflictRequest.context)
            $0.details = Acme_Prescriptions_V1_ExplainPrescriptionCalculationRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = Projection.read(
                        reply0, at: \Acme_Prescriptions_V1_QuotePrescriptionResponse.prescription.counterparty.email)
                }
            }
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = Projection.read(
                        input,
                        at: \Acme_Prescriptions_V1_ResolvePrescriptionConflictRequest.prescription.audit.updatedAt)
                    $0.updatedBy = Projection.read(
                        input,
                        at: \Acme_Prescriptions_V1_ResolvePrescriptionConflictRequest.prescription.audit.updatedBy)
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.recipient = Projection.read(
                        reply0,
                        at: \Acme_Prescriptions_V1_QuotePrescriptionResponse.prescription.billingAddress.recipient)
                }
            }
        }
        let reply1 = try await self.prescriptionsPrescriptionCalculation.explainPrescriptionCalculation(outbound1)
        return Acme_Prescriptions_V1_ResolvePrescriptionConflictResponse.with {
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.billingAddress = input.prescription.billingAddress
                $0.counterparty = reply1.prescription.counterparty
                $0.number = reply1.prescription.number
                $0.prescriptionID = input.prescriptionID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processStreamPrescriptionChanges(_ input: Acme_Prescriptions_V1_StreamPrescriptionChangesRequest) async throws
        -> Acme_Prescriptions_V1_StreamPrescriptionChangesResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.ack.status)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "audit", detail: input.ack.status
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "StreamPrescriptionChanges",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "StreamPrescriptionChanges", detail: input.context.traceID
        )
        let selection0_1: String
        switch input.frame {
        case .change(let change):
            selection0_1 = change.audit.updatedBy
        default: selection0_1 = .init()
        }
        let outbound0 = Acme_Prescriptions_V1_CheckRefillEligibilityRequest.with {
            $0.context = input.context
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = selection0_1
                }
            }
        }
        let reply0 = try await self.prescriptionsRefillValidation.checkRefillEligibility(outbound0)
        let selection1_1: Google_Protobuf_Timestamp
        switch input.frame {
        case .change(let change):
            selection1_1 = change.audit.createdAt
        default: selection1_1 = .init()
        }
        let outbound1 = Acme_Prescriptions_V1_CheckMedicationEligibilityRequest.with {
            $0.context = input.context
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = selection1_1
                }
            }
        }
        let reply1 = try await self.prescriptionsMedicationValidation.checkMedicationEligibility(outbound1)
        let selection2_2: String
        switch reply1.medication.locator {
        case .address(let address):
            selection2_2 = address.locality
        default: selection2_2 = .init()
        }
        let outbound2 = Acme_Patients_V1_EstimatePatientRequest.with {
            $0.context = input.context
            $0.details = Acme_Patients_V1_EstimatePatientRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.locality = selection2_2
                }
            }
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.email = reply1.medication.owner.email
                }
            }
        }
        let reply2 = try await self.patientsPatientCalculation.estimatePatient(outbound2)
        return Acme_Prescriptions_V1_StreamPrescriptionChangesResponse.with {
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply2.patient.audit.createdAt
                }
                $0.billingAddress = input.change.billingAddress
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = reply0.refill.customer.displayName
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.details = Projection.firstValue(
                    [
                        reply1.result.details,
                        reply2.result.details,
                    ], default: .init())
                $0.status = "ok"
            }
            $0.sequence = input.ack.sequence
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processSyncPrescriptions(_ input: Acme_Prescriptions_V1_SyncPrescriptionsRequest) async throws
        -> Acme_Prescriptions_V1_SyncPrescriptionsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.checksum)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "audit", detail: input.details.checksum
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SyncPrescriptions",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PrescriptionRecord(input.prescription, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let selection0_1: String
        switch input.prescription.settlement {
        case .card(let card):
            selection0_1 = card.holderName
        default: selection0_1 = .init()
        }
        let outbound0 = Acme_Patients_V1_QuoteMedicalRecordRequest.with {
            $0.context = input.context
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = input.prescription.audit.updatedAt
                }
                $0.card = Acme_Patients_V1_MedicalRecordCardSettlement.with {
                    $0.holderName = selection0_1
                }
            }
        }
        let reply0 = try await self.patientsMedicalRecordCalculation.quoteMedicalRecord(outbound0)
        let outbound1 = Acme_Prescriptions_V1_GetPrescriptionRulesRequest.with {
            $0.context = input.context
            $0.prescriptionID = input.prescription.prescriptionID
        }
        let step1: @Sendable () async throws -> Acme_Prescriptions_V1_GetPrescriptionRulesResponse = {
            try await self.prescriptionsPrescriptionValidation.getPrescriptionRules(outbound1)
        }
        let reply1 = try await step1()
        return Acme_Prescriptions_V1_SyncPrescriptionsResponse.with {
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply0.medicalRecord.audit.etag
                }
                $0.issuedAt = reply1.prescription.issuedAt
                $0.prescriptionID = input.prescriptionID
                $0.status = input.prescription.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.status = "ok"
            }
        }
    }
}
