import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension MedicalRecordReportingEndpoint {
    /// Execute the patients workflow and project its upstream replies.
    func processCountMedicalRecordTotals(_ input: Acme_Patients_V1_CountMedicalRecordTotalsRequest) async throws
        -> Acme_Patients_V1_CountMedicalRecordTotalsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "CountMedicalRecordTotals",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "CountMedicalRecordTotals", detail: input.context.traceID
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
        var outbound0 = Acme_Keymanagement_V1_QuoteCryptoKeyRequest()
        outbound0.context = input.context
        outbound0.cryptoKey = Acme_Keymanagement_V1_CryptoKey.with {
            $0.labels = input.filter.labels
        }
        let reply0 = try await self.keymanagementCryptoKeyCalculation.quoteCryptoKey(outbound0)
        return Acme_Patients_V1_CountMedicalRecordTotalsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.result.message
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processDeleteMedicalRecordReport(_ input: Acme_Patients_V1_DeleteMedicalRecordReportRequest) async throws
        -> Acme_Patients_V1_DeleteMedicalRecordReportResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.medicalRecordID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "audit", detail: input.medicalRecordID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "DeleteMedicalRecordReport",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "DeleteMedicalRecordReport", detail: input.context.traceID
        )
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        let outbound0 = Acme_Identity_V1_CloneUserRequest.with {
            $0.context = input.context
            $0.user = Acme_Identity_V1_User.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = input.etag
                }
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.email = input.context.actor.email
                    $0.userID = input.context.actor.userID
                }
            }
        }
        let step0: @Sendable () async throws -> Acme_Identity_V1_CloneUserResponse = {
            try await self.identityUser.cloneUser(outbound0)
        }
        let reply0 = try await step0()
        let outbound1 = Acme_Notifications_V1_ScoreNotificationRequest.with {
            $0.context = input.context
            $0.notification = Acme_Notifications_V1_Notification.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.email = reply0.user.contact.email
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply0.user.audit.updatedAt
                }
            }
        }
        let reply1 = try await self.notificationsNotificationValidation.scoreNotification(outbound1)
        let outbound2 = Acme_Metrics_V1_SearchMetricSeriesesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Metrics_V1_SearchMetricSeriesesRequest.Filter.with {
                $0.createdAfter = reply0.user.audit.createdAt
                $0.ownerID = reply1.notification.sla.policyID
                $0.region = reply0.user.primaryAddress.region
            }
        }
        async let remote2 = self.metricsMetricSeries.searchMetricSerieses(outbound2)
        async let persisted2 = store.count(tenant: input.context.tenantID)
        let (reply2, count2) = try await (remote2, persisted2)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count2)])
        let outbound3 = Acme_Patients_V1_ReconcileMedicalRecordsRequest.with {
            $0.context = input.context
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply1.notification.audit.updatedBy
                }
            }
        }
        let reply3 = try await self.deleteMedicalRecordReportStep3.execute(outbound3)
        return Acme_Patients_V1_DeleteMedicalRecordReportResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.details = Projection.firstValue(
                    [
                        reply2.result.details,
                        reply3.result.details,
                    ], default: .init())
                $0.message = reply1.result.message
                $0.status = reply3.outcome.status
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processFetchMedicalRecordReport(_ input: Acme_Patients_V1_FetchMedicalRecordReportRequest) async throws
        -> Acme_Patients_V1_FetchMedicalRecordReportResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "FetchMedicalRecordReport",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "FetchMedicalRecordReport", detail: input.context.traceID
        )
        return Acme_Patients_V1_FetchMedicalRecordReportResponse.with {
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.medicalRecordID = input.medicalRecordID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processGenerateMedicalRecordReport(_ input: Acme_Patients_V1_GenerateMedicalRecordReportRequest) async throws
        -> Acme_Patients_V1_GenerateMedicalRecordReportResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.cron)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "audit", detail: input.details.cron
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "GenerateMedicalRecordReport",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "GenerateMedicalRecordReport", detail: input.context.traceID
        )
        let outbound0 = Acme_Patients_V1_MapAllergyImportColumnsRequest.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.email = input.context.actor.email
                }
            }
            $0.annotations = input.annotations
            $0.context = input.context
        }
        let port0 = RPCOperations.port { (request: Acme_Patients_V1_MapAllergyImportColumnsRequest) in
            try await self.patientsAllergyImport.mapAllergyImportColumns(request)
        }
        let reply0 = try await port0.execute(outbound0)
        return Acme_Patients_V1_GenerateMedicalRecordReportResponse.with {
            $0.period = input.details.period
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply0.result.status
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processListMedicalRecordReports(_ input: Acme_Patients_V1_ListMedicalRecordReportsRequest) async throws
        -> Acme_Patients_V1_ListMedicalRecordReportsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ListMedicalRecordReports",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "ListMedicalRecordReports", detail: input.context.traceID
        )
        let outbound0 = Acme_Patients_V1_ListMedicalRecordConflictsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Patients_V1_ListMedicalRecordConflictsRequest.Filter.with {
                $0.createdAfter = input.filter.createdAfter
                $0.statuses = input.filter.statuses
            }
        }
        let reply0 = try await self.listMedicalRecordReportsStep0(outbound0)
        let outbound1 = Acme_Search_V1_ExportSearchIndexesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Search_V1_ExportSearchIndexesRequest.Filter.with {
                $0.createdAfter = input.filter.createdAfter
                $0.region = input.filter.region
            }
        }
        let reply1 = try await self.searchSearchIndexQuery.exportSearchIndexes(outbound1) { response in
            var latest = Acme_Search_V1_ExportSearchIndexesResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        _ = reply1
        return Acme_Patients_V1_ListMedicalRecordReportsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processScheduleMedicalRecordReport(_ input: Acme_Patients_V1_ScheduleMedicalRecordReportRequest) async throws
        -> Acme_Patients_V1_ScheduleMedicalRecordReportResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.cron)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "audit", detail: input.details.cron
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ScheduleMedicalRecordReport",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "ScheduleMedicalRecordReport", detail: input.context.traceID
        )
        let outbound0 = Acme_Catalog_V1_ExplainProductCalculationRequest.with {
            $0.context = input.context
            $0.reason = input.reason
        }
        guard
            let execute0 = self.scheduleMedicalRecordReportStep0[settings.region]
                ?? self.scheduleMedicalRecordReportStep0["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply0 = try await execute0(outbound0)
        let outbound1 = Acme_Notifications_V1_CreateNotificationRequest.with {
            $0.context = input.context
            $0.notification = Acme_Notifications_V1_Notification.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.userID = reply0.product.owner.userID
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply0.product.audit.etag
                }
            }
        }
        let reply1 = try await self.notificationsNotification.createNotification(outbound1)
        return Acme_Patients_V1_ScheduleMedicalRecordReportResponse.with {
            $0.period = input.details.period
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.message = reply0.outcome.message
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processShareMedicalRecordReport(_ input: Acme_Patients_V1_ShareMedicalRecordReportRequest) async throws
        -> Acme_Patients_V1_ShareMedicalRecordReportResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.channel)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "audit", detail: input.details.channel
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ShareMedicalRecordReport",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "ShareMedicalRecordReport", detail: input.context.traceID
        )
        let outbound0 = Acme_Telehealth_V1_ScheduleVisitNoteExpiryRequest.with {
            $0.context = input.context
            $0.details = Acme_Telehealth_V1_ScheduleVisitNoteExpiryRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.phone = input.details.recipient.phone
                }
            }
        }
        let envelope0 = try Google_Protobuf_Any(message: outbound0)
        let unpacked0 = try Acme_Telehealth_V1_ScheduleVisitNoteExpiryRequest(unpackingAny: envelope0)
        let reply0 = try await self.telehealthVisitNoteLifecycle.scheduleVisitNoteExpiry(unpacked0)
        let outbound1 = Acme_Prescriptions_V1_CancelRefillWorkflowRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_CancelRefillWorkflowRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply0.visitNote.counterparty.email
                }
            }
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.customer = Acme_Prescriptions_V1_PrescriptionRef.with {
                    $0.displayName = reply0.visitNote.counterparty.displayName
                }
            }
        }
        let json1 = try outbound1.jsonString()
        let decoded1 = try Acme_Prescriptions_V1_CancelRefillWorkflowRequest(jsonString: json1)
        let reply1 = try await self.prescriptionsRefillWorkflow.cancelRefillWorkflow(decoded1)
        let outbound2 =
            Acme_Patients_V1_ReconcileMedicalRecordsRequest.forMedicalRecordReportingEndpointShareMedicalRecordReport2(
                input,
                reply0: reply0
            )
        let reply2 = try await self.patientsMedicalRecordSync.reconcileMedicalRecords(outbound2)
        return Acme_Patients_V1_ShareMedicalRecordReportResponse.with {
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply0.visitNote.audit.createdAt
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.email = reply1.refill.requester.email
                    $0.patientID = reply2.medicalRecord.counterparty.patientID
                }
                $0.medicalRecordID = input.medicalRecordID
            }
            $0.outcome = Acme_Patients_V1_ShareMedicalRecordReportResponse.Outcome.with {
                $0.effectiveAt = reply2.outcome.effectiveAt
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply1.outcome.message
                $0.status = reply0.outcome.status
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processStreamMedicalRecordMetrics(_ input: Acme_Patients_V1_StreamMedicalRecordMetricsRequest) async throws
        -> Acme_Patients_V1_StreamMedicalRecordMetricsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "StreamMedicalRecordMetrics",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "StreamMedicalRecordMetrics", detail: input.context.traceID
        )
        let outbound0 = Acme_Patients_V1_PushAllergyRequest.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.attributes = input.filter.labels
                $0.measurements = [
                    Acme_Patients_V1_AllergyMeasurement.with {
                        $0.observedAt = input.filter.createdAfter
                    }
                ]
                $0.occurredAt = input.since
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.email = input.subscriber.email
                }
            }
            $0.context = input.context
        }
        let reply0 = try await self.patientsAllergySync.pushAllergy(
            outbound0, metadata: ["x-acme-region": .string(settings.region)]
        )
        let outbound1 = Acme_Patients_V1_BrowsePatientsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Patients_V1_BrowsePatientsRequest.Filter.with {
                $0.labels = input.filter.labels
                $0.region = input.filter.region
            }
        }
        let reply1 = try await RPCOperations.call(outbound1) { request in
            try await self.patientsPatientQuery.browsePatients(request)
        }
        return Acme_Patients_V1_StreamMedicalRecordMetricsResponse.with {
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.email = input.subscriber.email
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.details = reply0.result.details
                $0.referenceIds = reply0.result.referenceIds
                $0.status = reply1.result.status
            }
        }
    }
}
