import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension MedicationSyncEndpoint {
    /// Execute the prescriptions workflow and project its upstream replies.
    func processListMedicationConflicts(_ input: Acme_Prescriptions_V1_ListMedicationConflictsRequest) async throws
        -> Acme_Prescriptions_V1_ListMedicationConflictsResponse
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
            "ListMedicationConflicts",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "ListMedicationConflicts", detail: input.context.traceID
        )
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        let importFrame = Acme_Prescriptions_V1_StreamPrescriptionChangesRequest.with {
            $0.context = input.context
        }
        _ = try await self.prescriptionsPrescriptionSync.streamPrescriptionChanges { writer in
            try await writer.write(importFrame)
        } onResponse: { response in
            var latest = Acme_Prescriptions_V1_StreamPrescriptionChangesResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        let outbound0 = Acme_Prescriptions_V1_PreviewPrescriptionRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_PreviewPrescriptionRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.context.actor.email
                }
                $0.locale = input.context.locale
            }
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
                $0.dueAt = input.filter.createdAfter
            }
        }
        let reply0 = try await RPCOperations.call(outbound0) { request in
            try await self.prescriptionsPrescriptionValidation.previewPrescription(request)
        }
        let outbound1 = Acme_Prescriptions_V1_PushPrescriptionRequest.with {
            $0.context = Projection.read(input, at: \Acme_Prescriptions_V1_ListMedicationConflictsRequest.context)
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = Projection.read(
                        reply0, at: \Acme_Prescriptions_V1_PreviewPrescriptionResponse.prescription.audit.createdBy)
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.patientID = Projection.read(
                        reply0,
                        at: \Acme_Prescriptions_V1_PreviewPrescriptionResponse.prescription.counterparty.patientID)
                }
            }
        }
        let reply1 = try await self.prescriptionsPrescriptionSync.pushPrescription(outbound1)
        return Acme_Prescriptions_V1_ListMedicationConflictsResponse.with {
            $0.medications = [
                Acme_Prescriptions_V1_Medication.with {
                    $0.audit = Acme_Common_V1_AuditInfo.with {
                        $0.updatedBy = reply1.prescription.audit.updatedBy
                    }
                }
            ]
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.result.message
                $0.referenceIds = reply0.result.referenceIds
                $0.status = reply1.result.status
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processPullMedications(_ input: Acme_Prescriptions_V1_PullMedicationsRequest) async throws
        -> Acme_Prescriptions_V1_PullMedicationsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.checksum)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "audit", detail: input.details.checksum
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "PullMedications",
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
        let outbound0 = Acme_Prescriptions_V1_CalculateMedicationRequest.with {
            $0.context = input.context
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.dimensions = Acme_Prescriptions_V1_MedicationDimensions.with {
                    $0.width = input.medication.dimensions.width
                }
            }
        }
        let step0: @Sendable () async throws -> Acme_Prescriptions_V1_CalculateMedicationResponse = {
            try await self.prescriptionsMedicationCalculation.calculateMedication(outbound0)
        }
        let reply0 = try await step0()
        return Acme_Prescriptions_V1_PullMedicationsResponse.with {
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.dimensions = Acme_Prescriptions_V1_MedicationDimensions.with {
                    $0.height = reply0.medication.dimensions.height
                }
                $0.medicationID = input.medicationID
                $0.owner = input.medication.owner
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processPushMedication(_ input: Acme_Prescriptions_V1_PushMedicationRequest) async throws
        -> Acme_Prescriptions_V1_PushMedicationResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.checksum)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "audit", detail: input.details.checksum
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "PushMedication",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicationRecord(input.medication, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let selection0_2: String
        switch input.medication.locator {
        case .address(let address):
            selection0_2 = address.recipient
        default: selection0_2 = .init()
        }
        let outbound0 = Acme_Patients_V1_CalculateMedicalRecordRequest.with {
            $0.context = input.context
            $0.details = Acme_Patients_V1_CalculateMedicalRecordRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.recipient = selection0_2
                }
            }
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = input.medication.audit.createdBy
                    $0.updatedBy = input.medication.audit.updatedBy
                }
            }
        }
        let reply0 = try await self.patientsMedicalRecordCalculation.calculateMedicalRecord(outbound0)
        return Acme_Prescriptions_V1_PushMedicationResponse.with {
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply0.medicalRecord.audit.createdAt
                    $0.etag = reply0.medicalRecord.audit.etag
                }
                $0.medicationID = input.medicationID
                $0.status = input.medication.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processResolveMedicationConflict(_ input: Acme_Prescriptions_V1_ResolveMedicationConflictRequest) async throws
        -> Acme_Prescriptions_V1_ResolveMedicationConflictResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.checksum)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "audit", detail: input.details.checksum
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ResolveMedicationConflict",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicationRecord(input.medication, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let selection0_1: [String]
        switch input.medication.locator {
        case .address(let address):
            selection0_1 = address.lines
        default: selection0_1 = .init()
        }
        let selection0_2: String
        switch input.medication.locator {
        case .address(let address):
            selection0_2 = address.recipient
        default: selection0_2 = .init()
        }
        let outbound0 = Acme_Prescriptions_V1_NormalizePrescriptionRequest.with {
            $0.context = input.context
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.medication.audit.createdAt
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.lines = selection0_1
                    $0.recipient = selection0_2
                }
                $0.lines = [
                    Acme_Prescriptions_V1_PrescriptionLine.with {
                        $0.description_p = input.medication.components["primary", default: .init()].description_p
                    }
                ]
            }
        }
        let reply0 = try await self.prescriptionsPrescriptionValidation.normalizePrescription(outbound0)
        var outbound1 = Acme_Metrics_V1_NormalizeMetricSeriesRequest()
        outbound1.context = input.context
        outbound1.metricSeries = Acme_Metrics_V1_MetricSeries.with {
            $0.audit = Acme_Common_V1_AuditInfo.with {
                $0.etag = input.medication.audit.etag
                $0.updatedAt = reply0.prescription.audit.updatedAt
            }
            $0.owner = Acme_Identity_V1_UserRef.with {
                $0.displayName = reply0.prescription.counterparty.displayName
            }
        }
        let reply1 = try await self.metricsMetricSeriesValidation.normalizeMetricSeries(outbound1)
        let selection2_1: String
        switch reply1.metricSeries.locator {
        case .address(let address):
            selection2_1 = address.region
        default: selection2_1 = .init()
        }
        let outbound2 = Acme_Authorization_V1_BrowseAccessPoliciesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Authorization_V1_BrowseAccessPoliciesRequest.Filter.with {
                $0.createdAfter = reply0.prescription.audit.createdAt
                $0.ownerID = reply1.metricSeries.components["primary", default: .init()].componentID
                $0.region = selection2_1
            }
        }
        let reply2 = try await self.authorizationAccessPolicyQuery.browseAccessPolicies(outbound2)
        let outbound3 = Acme_Patients_V1_SummarizePatientsRequest.with {
            $0.context = input.context
            $0.patientID = reply0.prescription.counterparty.patientID
        }
        let step3: @Sendable () async throws -> Acme_Patients_V1_SummarizePatientsResponse = {
            try await self.patientsPatientQuery.summarizePatients(outbound3)
        }
        let reply3 = try await step3()
        return Acme_Prescriptions_V1_ResolveMedicationConflictResponse.with {
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply0.prescription.audit.createdAt
                }
                $0.medicationID = input.medicationID
                $0.status = input.medication.status
                $0.tags = reply1.metricSeries.tags
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply3.result.details
                $0.message = Projection.firstValue(
                    [
                        reply0.outcome.message,
                        reply2.result.message,
                    ], default: .init())
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processStreamMedicationChanges(_ input: Acme_Prescriptions_V1_StreamMedicationChangesRequest) async throws
        -> Acme_Prescriptions_V1_StreamMedicationChangesResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.ack.status)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "audit", detail: input.ack.status
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "StreamMedicationChanges",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "StreamMedicationChanges", detail: input.context.traceID
        )
        let outbound0 = Acme_Prescriptions_V1_ResolveMedicationsRequest.with {
            $0.context = input.context
        }
        let reply0 = try await self.prescriptionsMedicationQuery.resolveMedications(outbound0)
        let selection1_1: String
        switch input.frame {
        case .change(let change):
            selection1_1 = change.components["primary", default: .init()].description_p
        default: selection1_1 = .init()
        }
        let outbound1 = Acme_Patients_V1_CheckMedicalRecordEligibilityRequest.with {
            $0.context = input.context
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.lines = [
                    Acme_Patients_V1_MedicalRecordLine.with {
                        $0.description_p = selection1_1
                    }
                ]
            }
        }
        let reply1 = try await self.patientsMedicalRecordValidation.checkMedicalRecordEligibility(outbound1)
        let selection2_1: String
        switch input.frame {
        case .change(let change):
            selection2_1 = change.audit.etag
        default: selection2_1 = .init()
        }
        let outbound2 = Acme_Telehealth_V1_PauseTriageWorkflowRequest.with {
            $0.context = input.context
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = selection2_1
                }
            }
        }
        let reply2 = try await self.telehealthTriageWorkflow.pauseTriageWorkflow(outbound2)
        let selection3_3: String
        switch reply2.triage.origin {
        case .channel(let channel):
            selection3_3 = channel.address
        default: selection3_3 = .init()
        }
        let outbound3 = Acme_Prescriptions_V1_RetryRefillImportRequest.with {
            $0.context = input.context
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.userID = reply2.triage.assignee.userID
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply2.triage.audit.createdBy
                }
                $0.channel = Acme_Prescriptions_V1_RefillChannelOrigin.with {
                    $0.address = selection3_3
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.preferredChannel = reply2.triage.requester.preferredChannel
                }
            }
        }
        let reply3 = try await self.prescriptionsRefillImport.retryRefillImport(outbound3)
        return Acme_Prescriptions_V1_StreamMedicationChangesResponse.with {
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.name = input.change.name
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply2.triage.assignee.displayName
                    $0.email = reply2.triage.requester.email
                    $0.userID = reply3.refill.assignee.userID
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.message = Projection.firstValue(
                    [
                        reply0.result.message,
                        reply3.outcome.message,
                    ], default: .init())
                $0.status = reply1.outcome.status
            }
            $0.sequence = input.ack.sequence
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processSyncMedications(_ input: Acme_Prescriptions_V1_SyncMedicationsRequest) async throws
        -> Acme_Prescriptions_V1_SyncMedicationsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.checksum)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "audit", detail: input.details.checksum
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SyncMedications",
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
        let outbound0 = Acme_Identity_V1_ListUsersRequest.with {
            $0.context = input.context
            $0.filter = Acme_Identity_V1_ListUsersRequest.Filter.with {
                $0.createdAfter = input.medication.audit.createdAt
                $0.ownerID = input.medication.components["primary", default: .init()].componentID
                $0.region = selection0_1
            }
        }
        let reply0 = try await self.identityUser.listUsers(outbound0)
        let outbound1 = Acme_Patients_V1_CalculatePatientRequest.with {
            $0.context = input.context
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.medication.owner.userID
                }
            }
        }
        async let remote1 = self.patientsPatientCalculation.calculatePatient(outbound1)
        async let persisted1 = store.count(tenant: input.context.tenantID)
        let (reply1, count1) = try await (remote1, persisted1)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count1)])
        let outbound2 = Acme_Prescriptions_V1_CheckPrescriptionEligibilityRequest.with {
            $0.context = input.context
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply1.patient.audit.etag
                    $0.updatedAt = reply1.patient.audit.updatedAt
                }
            }
        }
        let reply2 = try await self.syncMedicationsStep2.execute(outbound2)
        return Acme_Prescriptions_V1_SyncMedicationsResponse.with {
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply1.patient.audit.updatedBy
                }
                $0.medicationID = input.medicationID
                $0.name = input.medication.name
            }
            $0.outcome = Acme_Prescriptions_V1_SyncMedicationsResponse.Outcome.with {
                $0.status = reply2.outcome.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply1.result.details
                $0.message = reply0.result.message
                $0.status = Projection.firstValue(
                    [
                        reply0.result.status,
                        reply2.outcome.status,
                    ], default: .init())
            }
        }
    }
}
