import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension MedicationLifecycleEndpoint {
    /// Execute the prescriptions workflow and project its upstream replies.
    func processActivateMedication(_ input: Acme_Prescriptions_V1_ActivateMedicationRequest) async throws
        -> Acme_Prescriptions_V1_ActivateMedicationResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "audit", detail: input.details.newOwner.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ActivateMedication",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "ActivateMedication", detail: input.context.traceID
        )
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        try followUps.submit(
            Acme_Identity_V1_GetUserRequest.with {
                $0.context = input.context
                $0.userID = input.context.actor.userID
            })
        let importFrame = Acme_Prescriptions_V1_StreamMedicationChangesRequest.with {
            $0.context = input.context
        }
        _ = try await self.prescriptionsMedicationSync.streamMedicationChanges { writer in
            try await writer.write(importFrame)
        } onResponse: { response in
            var latest = Acme_Prescriptions_V1_StreamMedicationChangesResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        let outbound0 = Acme_Prescriptions_V1_ListMedicationConflictsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Prescriptions_V1_ListMedicationConflictsRequest.Filter.with {
                $0.createdAfter = input.details.effectiveAt
                $0.labels = input.annotations
                $0.ownerID = input.details.newOwner.userID
            }
        }
        let step0: @Sendable () async throws -> Acme_Prescriptions_V1_ListMedicationConflictsResponse = {
            try await self.prescriptionsMedicationSync.listMedicationConflicts(outbound0)
        }
        let reply0 = try await step0()
        var outbound1 = Acme_Ledger_V1_CountLedgerAccountsRequest()
        outbound1.context = input.context
        outbound1.filter = Acme_Ledger_V1_CountLedgerAccountsRequest.Filter.with {
            $0.createdAfter = input.details.effectiveAt
            $0.labels = reply0.result.details
            $0.ownerID = input.details.newOwner.userID
        }
        let reply1 = try await self.ledgerLedgerAccountQuery.countLedgerAccounts(outbound1)
        return Acme_Prescriptions_V1_ActivateMedicationResponse.with {
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.medicationID = input.medicationID
            }
            $0.outcome = Acme_Prescriptions_V1_ActivateMedicationResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
                $0.message = reply1.result.message
                $0.status = reply1.result.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processExpireMedication(_ input: Acme_Prescriptions_V1_ExpireMedicationRequest) async throws
        -> Acme_Prescriptions_V1_ExpireMedicationResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.notifyContact.phone)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "audit", detail: input.details.notifyContact.phone
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ExpireMedication",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "ExpireMedication", detail: input.context.traceID
        )
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        let outbound0 = Acme_Prescriptions_V1_ListMedicationConflictsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Prescriptions_V1_ListMedicationConflictsRequest.Filter.with {
                $0.createdAfter = input.details.effectiveAt
                $0.labels = input.annotations
                $0.ownerID = input.details.newOwner.userID
            }
        }
        let reply0 = try await RPCOperations.read {
            try await self.prescriptionsMedicationSync.listMedicationConflicts(outbound0)
        }
        let outbound1 = Acme_Patients_V1_SimulateAllergyRequest.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.correlationID = reply0.result.correlationID
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = input.details.newOwner.displayName
                    $0.email = input.details.notifyContact.email
                }
            }
            $0.context = input.context
        }
        let reply1 = try await self.patientsAllergyCalculation.simulateAllergy(outbound1)
        let outbound2 = Acme_Prescriptions_V1_CheckMedicationEligibilityRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_CheckMedicationEligibilityRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.notifyContact.email
                    $0.preferredChannel = input.details.notifyContact.preferredChannel
                }
            }
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply1.allergy.subject.displayName
                    $0.email = input.details.newOwner.email
                }
            }
        }
        async let remote2 = self.prescriptionsMedicationValidation.checkMedicationEligibility(outbound2)
        async let persisted2 = store.count(tenant: input.context.tenantID)
        let (reply2, count2) = try await (remote2, persisted2)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count2)])
        return Acme_Prescriptions_V1_ExpireMedicationResponse.with {
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.dimensions = Acme_Prescriptions_V1_MedicationDimensions.with {
                    $0.width = reply2.medication.dimensions.width
                }
                $0.medicationID = input.medicationID
            }
            $0.outcome = Acme_Prescriptions_V1_ExpireMedicationResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.referenceIds = reply1.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processGetMedicationLifecycle(_ input: Acme_Prescriptions_V1_GetMedicationLifecycleRequest) async throws
        -> Acme_Prescriptions_V1_GetMedicationLifecycleResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "GetMedicationLifecycle",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "GetMedicationLifecycle", detail: input.context.traceID
        )
        let outbound0 = Acme_Corporateevents_V1_ResolveCorporateEventsRequest.with {
            $0.context = input.context
        }
        let reply0 = try await self.getMedicationLifecycleStep0.execute(outbound0)
        let outbound1 = Acme_Prescriptions_V1_ReconcileRefillsRequest.with {
            $0.context = input.context
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.context.actor.email
                }
            }
        }
        let port1 = RPCOperations.port { (request: Acme_Prescriptions_V1_ReconcileRefillsRequest) in
            try await self.prescriptionsRefillSync.reconcileRefills(request)
        }
        let reply1 = try await port1.execute(outbound1)
        return Acme_Prescriptions_V1_GetMedicationLifecycleResponse.with {
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.medicationID = input.medicationID
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.email = reply1.refill.requester.email
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply0.result.status
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processReinstateMedication(_ input: Acme_Prescriptions_V1_ReinstateMedicationRequest) async throws
        -> Acme_Prescriptions_V1_ReinstateMedicationResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "audit", detail: input.details.newOwner.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ReinstateMedication",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "ReinstateMedication", detail: input.context.traceID
        )
        let outbound0 = Acme_Careplans_V1_RejectCareGoalRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.notifyContact.email
                }
            }
            $0.context = input.context
            $0.details = Acme_Careplans_V1_RejectCareGoalRequest.Details.with {
                $0.approver = Acme_Identity_V1_UserRef.with {
                    $0.email = input.details.newOwner.email
                    $0.userID = input.details.newOwner.userID
                }
            }
        }
        let reply0 = try await self.reinstateMedicationStep0(outbound0)
        let selection1_2: String
        switch reply0.careGoal.origin {
        case .customer(let customer):
            selection1_2 = customer.patientID
        default: selection1_2 = .init()
        }
        let outbound1 = Acme_Patients_V1_CompareAllergyOptionsRequest.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.correlationID = reply0.result.correlationID
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = reply0.careGoal.assignee.displayName
                    $0.email = reply0.careGoal.assignee.email
                    $0.patientID = selection1_2
                }
            }
            $0.context = input.context
        }
        let reply1 = try await self.patientsAllergyCalculation.compareAllergyOptions(outbound1)
        let outbound2 = Acme_Documents_V1_BatchGetDocumentsRequest.with {
            $0.context = input.context
        }
        guard let execute2 = self.reinstateMedicationStep2[settings.region] ?? self.reinstateMedicationStep2["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply2 = try await execute2(outbound2)
        let outbound3 = Acme_Metrics_V1_CheckMetricSeriesEligibilityRequest.with {
            $0.context = input.context
            $0.metricSeries = Acme_Metrics_V1_MetricSeries.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply0.careGoal.audit.etag
                    $0.updatedAt = reply0.careGoal.audit.updatedAt
                }
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.email = input.details.newOwner.email
                }
            }
        }
        let reply3 = try await self.metricsMetricSeriesValidation.checkMetricSeriesEligibility(outbound3)
        return Acme_Prescriptions_V1_ReinstateMedicationResponse.with {
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.medicationID = input.medicationID
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.email = reply0.careGoal.requester.email
                }
                $0.specs = reply3.metricSeries.specs
            }
            $0.outcome = Acme_Prescriptions_V1_ReinstateMedicationResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
                $0.message = Projection.firstValue(
                    [
                        reply1.result.message,
                        reply3.outcome.message,
                    ], default: .init())
                $0.status = reply2.result.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.allergy.correlationID
                $0.message = reply2.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processRenewMedication(_ input: Acme_Prescriptions_V1_RenewMedicationRequest) async throws
        -> Acme_Prescriptions_V1_RenewMedicationResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "audit", detail: input.details.newOwner.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "RenewMedication",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "RenewMedication", detail: input.context.traceID
        )
        let outbound0 = Acme_Inventory_V1_ListStockItemsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Inventory_V1_ListStockItemsRequest.Filter.with {
                $0.createdAfter = input.details.effectiveAt
                $0.labels = input.annotations
                $0.ownerID = input.details.newOwner.userID
            }
        }
        let envelope0 = try Google_Protobuf_Any(message: outbound0)
        let unpacked0 = try Acme_Inventory_V1_ListStockItemsRequest(unpackingAny: envelope0)
        let reply0 = try await self.inventoryStockItem.listStockItems(unpacked0)
        let outbound1 = Acme_Patients_V1_CheckAllergyEligibilityRequest.with {
            $0.context = input.context
            $0.details = Acme_Patients_V1_CheckAllergyEligibilityRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.newOwner.email
                    $0.name = input.details.notifyContact.name
                    $0.phone = input.details.notifyContact.phone
                }
            }
        }
        let json1 = try outbound1.jsonString()
        let decoded1 = try Acme_Patients_V1_CheckAllergyEligibilityRequest(jsonString: json1)
        let reply1 = try await self.patientsAllergyValidation.checkAllergyEligibility(decoded1)
        let outbound2 = Acme_Careplans_V1_ListPendingVitalsRequest.forMedicationLifecycleEndpointRenewMedication2(
            input
        )
        let reply2 = try await self.careplansVitalApproval.listPendingVitals(outbound2)
        let outbound3 = Acme_Patients_V1_CreatePatientRequest.with {
            $0.context = input.context
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.newOwner.email
                    $0.name = input.details.notifyContact.name
                    $0.preferredChannel = input.details.notifyContact.preferredChannel
                }
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply1.allergy.subject.displayName
                }
            }
        }
        let reply3 = try await self.patientsPatient.createPatient(
            outbound3, metadata: ["x-acme-region": .string(settings.region)]
        )
        return Acme_Prescriptions_V1_RenewMedicationResponse.with {
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.medicationID = input.medicationID
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.email = reply3.patient.relationshipManager.email
                }
            }
            $0.outcome = Acme_Prescriptions_V1_RenewMedicationResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
                $0.message = Projection.firstValue(
                    [
                        reply0.result.message,
                        reply1.outcome.message,
                    ], default: .init())
                $0.status = reply1.result.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply2.result.details
                $0.message = reply2.result.message
                $0.status = reply3.result.status
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processScheduleMedicationExpiry(_ input: Acme_Prescriptions_V1_ScheduleMedicationExpiryRequest) async throws
        -> Acme_Prescriptions_V1_ScheduleMedicationExpiryResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "audit", detail: input.details.initiatedBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ScheduleMedicationExpiry",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicationRecord(input.medication, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Notifications_V1_ExportNotificationsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Notifications_V1_ExportNotificationsRequest.Filter.with {
                $0.createdAfter = input.medication.audit.createdAt
                $0.ownerID = input.medication.owner.userID
                $0.region = input.medication.address.region
            }
        }
        let reply0 = try await self.notificationsNotificationQuery.exportNotifications(outbound0) { response in
            var latest = Acme_Notifications_V1_ExportNotificationsResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        _ = reply0
        let outbound1 = Acme_Prescriptions_V1_FetchMedicationReportRequest.with {
            $0.context = input.context
            $0.medicationID = input.medication.medicationID
        }
        let reply1 = try await RPCOperations.call(outbound1) { request in
            try await self.prescriptionsMedicationReporting.fetchMedicationReport(request)
        }
        let outbound2 = Acme_Prescriptions_V1_GenerateMedicationReportRequest.with {
            $0.context = Projection.read(input, at: \Acme_Prescriptions_V1_ScheduleMedicationExpiryRequest.context)
            $0.medicationID = Projection.read(
                reply1, at: \Acme_Prescriptions_V1_FetchMedicationReportResponse.medication.medicationID)
        }
        let reply2 = try await self.prescriptionsMedicationReporting.generateMedicationReport(outbound2)
        return Acme_Prescriptions_V1_ScheduleMedicationExpiryResponse.with {
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.code = input.medication.code
                $0.dimensions = Acme_Prescriptions_V1_MedicationDimensions.with {
                    $0.height = reply1.medication.dimensions.height
                }
                $0.medicationID = reply1.medication.medicationID
                $0.owner = input.medication.owner
            }
            $0.outcome = Acme_Prescriptions_V1_ScheduleMedicationExpiryResponse.Outcome.with {
                $0.status = reply2.result.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply2.result.status
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processSuspendMedication(_ input: Acme_Prescriptions_V1_SuspendMedicationRequest) async throws
        -> Acme_Prescriptions_V1_SuspendMedicationResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "audit", detail: input.details.newOwner.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SuspendMedication",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "SuspendMedication", detail: input.context.traceID
        )
        let outbound0 = Acme_Prescriptions_V1_ListRefillConflictsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Prescriptions_V1_ListRefillConflictsRequest.Filter.with {
                $0.createdAfter = input.details.effectiveAt
                $0.labels = input.annotations
                $0.ownerID = input.medicationID
            }
        }
        let step0: @Sendable () async throws -> Acme_Prescriptions_V1_ListRefillConflictsResponse = {
            try await self.prescriptionsRefillSync.listRefillConflicts(outbound0)
        }
        let reply0 = try await step0()
        return Acme_Prescriptions_V1_SuspendMedicationResponse.with {
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.medicationID = input.medicationID
            }
            $0.outcome = Acme_Prescriptions_V1_SuspendMedicationResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processTerminateMedication(_ input: Acme_Prescriptions_V1_TerminateMedicationRequest) async throws
        -> Acme_Prescriptions_V1_TerminateMedicationResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.userID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "audit", detail: input.details.newOwner.userID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "TerminateMedication",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "TerminateMedication", detail: input.context.traceID
        )
        var outbound0 = Acme_Patients_V1_SimulateAllergyRequest()
        outbound0.allergy = Acme_Patients_V1_Allergy.with {
            $0.subject = Acme_Patients_V1_PatientRef.with {
                $0.displayName = input.details.newOwner.displayName
                $0.email = input.details.newOwner.email
            }
        }
        outbound0.annotations = input.annotations
        outbound0.context = input.context
        outbound0.reason = input.reason
        let reply0 = try await self.patientsAllergyCalculation.simulateAllergy(outbound0)
        return Acme_Prescriptions_V1_TerminateMedicationResponse.with {
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.medicationID = input.medicationID
            }
            $0.outcome = Acme_Prescriptions_V1_TerminateMedicationResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.details = reply0.result.details
                $0.status = "ok"
            }
        }
    }
}
