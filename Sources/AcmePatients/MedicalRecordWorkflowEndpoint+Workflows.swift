import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension MedicalRecordWorkflowEndpoint {
    /// Execute the patients workflow and project its upstream replies.
    func processAdvanceMedicalRecordWorkflow(_ input: Acme_Patients_V1_AdvanceMedicalRecordWorkflowRequest) async throws
        -> Acme_Patients_V1_AdvanceMedicalRecordWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "audit", detail: input.details.initiatedBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "AdvanceMedicalRecordWorkflow",
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
        var outbound0 = Acme_Patients_V1_ReconcileMedicalRecordsRequest()
        outbound0.context = input.context
        outbound0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
            $0.audit = Acme_Common_V1_AuditInfo.with {
                $0.updatedBy = input.medicalRecord.audit.updatedBy
            }
        }
        let reply0 = try await self.patientsMedicalRecordSync.reconcileMedicalRecords(outbound0)
        let requests1 = input.medicalRecord.lines.map { element in
            Acme_Patients_V1_PushPatientRequest.with {
                $0.context = input.context
                $0.patient = Acme_Patients_V1_Patient.with {
                    $0.attributes = element.attributes
                    $0.audit = Acme_Common_V1_AuditInfo.with {
                        $0.updatedAt = input.medicalRecord.audit.updatedAt
                    }
                    $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                        $0.recipient = input.medicalRecord.billingAddress.recipient
                    }
                }
            }
        }
        let replies1 = try await FanOut.map(requests1) { candidate in
            try await self.patientsPatientSync.pushPatient(candidate)
        }
        let reply1 = replies1.first ?? Acme_Patients_V1_PushPatientResponse()
        _ = reply1
        return Acme_Patients_V1_AdvanceMedicalRecordWorkflowResponse.with {
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.billingAddress = reply0.medicalRecord.billingAddress
                $0.issuedAt = input.medicalRecord.issuedAt
                $0.medicalRecordID = input.medicalRecordID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processCancelMedicalRecordWorkflow(_ input: Acme_Patients_V1_CancelMedicalRecordWorkflowRequest) async throws
        -> Acme_Patients_V1_CancelMedicalRecordWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "audit", detail: input.details.initiatedBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "CancelMedicalRecordWorkflow",
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
        let outbound0 = Acme_Patients_V1_ListPatientReportsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Patients_V1_ListPatientReportsRequest.Filter.with {
                $0.createdAfter = input.medicalRecord.audit.createdAt
                $0.labels = input.annotations
                $0.ownerID = input.medicalRecord.counterparty.patientID
                $0.region = input.medicalRecord.billingAddress.region
            }
        }
        let reply0 = try await RPCOperations.read {
            try await self.patientsPatientReporting.listPatientReports(outbound0)
        }
        let outbound1 = Acme_Patients_V1_RecallPatientRequest.with {
            $0.context = input.context
            $0.details = Acme_Patients_V1_RecallPatientRequest.Details.with {
                $0.approver = Acme_Identity_V1_UserRef.with {
                    $0.email = input.medicalRecord.counterparty.email
                }
            }
        }
        let reply1 = try await self.patientsPatientApproval.recallPatient(outbound1)
        let selection2_2: String
        switch input.medicalRecord.settlement {
        case .card(let card):
            selection2_2 = card.holderName
        default: selection2_2 = .init()
        }
        let outbound2 = Acme_Patients_V1_EstimateMedicalRecordRequest.with {
            $0.context = input.context
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.lines = input.medicalRecord.billingAddress.lines
                    $0.region = reply1.patient.primaryAddress.region
                }
                $0.card = Acme_Patients_V1_MedicalRecordCardSettlement.with {
                    $0.holderName = selection2_2
                }
            }
        }
        let reply2 = try await self.patientsMedicalRecordCalculation.estimateMedicalRecord(outbound2)
        let outbound3 = Acme_Venues_V1_CountVenuesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Venues_V1_CountVenuesRequest.Filter.with {
                $0.createdAfter = reply2.medicalRecord.audit.createdAt
                $0.ownerID = input.medicalRecordID
                $0.region = reply2.medicalRecord.billingAddress.region
            }
        }
        async let remote3 = self.venuesVenueQuery.countVenues(outbound3)
        async let persisted3 = store.count(tenant: input.context.tenantID)
        let (reply3, count3) = try await (remote3, persisted3)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count3)])
        return Acme_Patients_V1_CancelMedicalRecordWorkflowResponse.with {
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply1.patient.audit.createdBy
                }
                $0.dueAt = input.medicalRecord.dueAt
                $0.medicalRecordID = input.medicalRecordID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply3.result.details
                $0.referenceIds = reply2.result.referenceIds + reply3.result.referenceIds
                $0.status = reply0.result.status
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processInspectMedicalRecordWorkflow(_ input: Acme_Patients_V1_InspectMedicalRecordWorkflowRequest) async throws
        -> Acme_Patients_V1_InspectMedicalRecordWorkflowResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "InspectMedicalRecordWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "InspectMedicalRecordWorkflow", detail: input.context.traceID
        )
        let outbound0 = Acme_Appointments_V1_ListPendingProvidersRequest.with {
            $0.context = input.context
            $0.filter = Acme_Appointments_V1_ListPendingProvidersRequest.Filter.with {
                $0.createdAfter = input.context.deadline
                $0.labels = input.context.baggage
                $0.ownerID = input.medicalRecordID
            }
        }
        let reply0 = try await self.inspectMedicalRecordWorkflowStep0.execute(outbound0)
        let outbound1 = Acme_Patients_V1_ResolveAllergyConflictRequest.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.attributes = reply0.result.details
                $0.correlationID = reply0.result.correlationID
                $0.source = input.medicalRecordID
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.email = input.context.actor.email
                }
            }
            $0.context = input.context
        }
        let port1 = RPCOperations.port { (request: Acme_Patients_V1_ResolveAllergyConflictRequest) in
            try await self.patientsAllergySync.resolveAllergyConflict(request)
        }
        let reply1 = try await port1.execute(outbound1)
        return Acme_Patients_V1_InspectMedicalRecordWorkflowResponse.with {
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.medicalRecordID = input.medicalRecordID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.allergy.correlationID
                $0.message = Projection.firstValue(
                    [
                        reply0.result.message,
                        reply1.outcome.message,
                    ], default: .init())
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processListMedicalRecordWorkflows(_ input: Acme_Patients_V1_ListMedicalRecordWorkflowsRequest) async throws
        -> Acme_Patients_V1_ListMedicalRecordWorkflowsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.query)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "audit", detail: input.filter.query
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ListMedicalRecordWorkflows",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "ListMedicalRecordWorkflows", detail: input.context.traceID
        )
        let outbound0 = Acme_Patients_V1_ApproveAllergyRequest.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.correlationID = input.filter.ownerID
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.email = input.context.actor.email
                }
            }
            $0.context = input.context
            $0.details = Acme_Patients_V1_ApproveAllergyRequest.Details.with {
                $0.approver = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.context.actor.userID
                }
                $0.effectiveAt = input.filter.createdAfter
            }
        }
        let reply0 = try await self.listMedicalRecordWorkflowsStep0(outbound0)
        let outbound1 = Acme_Patients_V1_RecallPatientRequest.with {
            $0.context = input.context
            $0.details = Acme_Patients_V1_RecallPatientRequest.Details.with {
                $0.approver = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply0.allergy.subject.displayName
                }
            }
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.email = reply0.allergy.subject.email
                }
            }
        }
        guard
            let execute1 = self.listMedicalRecordWorkflowsStep1[settings.region]
                ?? self.listMedicalRecordWorkflowsStep1["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply1 = try await execute1(outbound1)
        return Acme_Patients_V1_ListMedicalRecordWorkflowsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.referenceIds = reply1.result.referenceIds
                $0.status = Projection.firstValue(
                    [
                        reply0.outcome.status,
                        reply1.outcome.status,
                    ], default: .init())
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processPauseMedicalRecordWorkflow(_ input: Acme_Patients_V1_PauseMedicalRecordWorkflowRequest) async throws
        -> Acme_Patients_V1_PauseMedicalRecordWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "audit", detail: input.details.initiatedBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "PauseMedicalRecordWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicalRecordRecord(input.medicalRecord, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Patients_V1_SubmitPatientRequest.with {
            $0.context = input.context
            $0.details = Acme_Patients_V1_SubmitPatientRequest.Details.with {
                $0.approver = Acme_Identity_V1_UserRef.with {
                    $0.email = input.details.notify.email
                }
            }
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.medicalRecord.audit.createdAt
                }
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.medicalRecord.counterparty.displayName
                }
            }
        }
        let reply0 = try await self.patientsPatientApproval.submitPatient(outbound0)
        let outbound1 = Acme_Metrics_V1_ScoreMetricSeriesRequest.with {
            $0.context = input.context
            $0.metricSeries = Acme_Metrics_V1_MetricSeries.with {
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.email = input.medicalRecord.counterparty.email
                }
            }
        }
        let envelope1 = try Google_Protobuf_Any(message: outbound1)
        let unpacked1 = try Acme_Metrics_V1_ScoreMetricSeriesRequest(unpackingAny: envelope1)
        let reply1 = try await self.metricsMetricSeriesValidation.scoreMetricSeries(unpacked1)
        let outbound2 = Acme_Patients_V1_SignalPatientWorkflowRequest.with {
            $0.context = input.context
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.email = input.details.notify.email
                }
            }
        }
        let json2 = try outbound2.jsonString()
        let decoded2 = try Acme_Patients_V1_SignalPatientWorkflowRequest(jsonString: json2)
        let reply2 = try await self.patientsPatientWorkflow.signalPatientWorkflow(decoded2)
        return Acme_Patients_V1_PauseMedicalRecordWorkflowResponse.with {
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply0.patient.audit.createdBy
                    $0.updatedBy = reply1.metricSeries.audit.updatedBy
                }
                $0.counterparty = input.medicalRecord.counterparty
                $0.medicalRecordID = input.medicalRecordID
                $0.number = reply0.patient.passport.number
            }
            $0.outcome = Acme_Patients_V1_PauseMedicalRecordWorkflowResponse.Outcome.with {
                $0.nextSteps = reply2.outcome.nextSteps
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processResumeMedicalRecordWorkflow(_ input: Acme_Patients_V1_ResumeMedicalRecordWorkflowRequest) async throws
        -> Acme_Patients_V1_ResumeMedicalRecordWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "audit", detail: input.details.initiatedBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ResumeMedicalRecordWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicalRecordRecord(input.medicalRecord, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 =
            Acme_Patients_V1_ReconcilePatientsRequest.forMedicalRecordWorkflowEndpointResumeMedicalRecordWorkflow0(
                input
            )
        let reply0 = try await self.patientsPatientSync.reconcilePatients(outbound0)
        let outbound1 = Acme_Patients_V1_ListAllergyReportsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Patients_V1_ListAllergyReportsRequest.Filter.with {
                $0.createdAfter = reply0.patient.audit.updatedAt
                $0.labels = reply0.patient.attributes
                $0.ownerID = reply0.outcome.referenceID
                $0.region = input.medicalRecord.billingAddress.region
            }
        }
        let reply1 = try await self.patientsAllergyReporting.listAllergyReports(
            outbound1, metadata: ["x-acme-region": .string(settings.region)]
        )
        let outbound2 = Acme_Patients_V1_FetchMedicalRecordReportRequest.with {
            $0.context = input.context
            $0.medicalRecordID = input.medicalRecordID
        }
        let reply2 = try await RPCOperations.call(outbound2) { request in
            try await self.patientsMedicalRecordReporting.fetchMedicalRecordReport(request)
        }
        return Acme_Patients_V1_ResumeMedicalRecordWorkflowResponse.with {
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = reply0.patient.primaryAddress.postalCode
                }
                $0.counterparty = input.medicalRecord.counterparty
                $0.medicalRecordID = input.medicalRecordID
            }
            $0.outcome = Acme_Patients_V1_ResumeMedicalRecordWorkflowResponse.Outcome.with {
                $0.status = Projection.firstValue(
                    [
                        reply0.result.status,
                        reply2.result.status,
                    ], default: .init())
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.message = reply1.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processRetryMedicalRecordWorkflow(_ input: Acme_Patients_V1_RetryMedicalRecordWorkflowRequest) async throws
        -> Acme_Patients_V1_RetryMedicalRecordWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "audit", detail: input.details.initiatedBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "RetryMedicalRecordWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicalRecordRecord(input.medicalRecord, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Patients_V1_SharePatientReportRequest.with {
            $0.context = Projection.read(input, at: \Acme_Patients_V1_RetryMedicalRecordWorkflowRequest.context)
            $0.details = Acme_Patients_V1_SharePatientReportRequest.Details.with {
                $0.recipient = Acme_Common_V1_ContactInfo.with {
                    $0.email = Projection.read(
                        input, at: \Acme_Patients_V1_RetryMedicalRecordWorkflowRequest.details.notify.email)
                }
            }
        }
        let reply0 = try await self.patientsPatientReporting.sharePatientReport(outbound0)
        let outbound1 = Acme_Performance_V1_CountReviewsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Performance_V1_CountReviewsRequest.Filter.with {
                $0.createdAfter = input.medicalRecord.audit.updatedAt
                $0.ownerID = reply0.patient.relationshipManager.userID
                $0.region = input.medicalRecord.billingAddress.region
            }
        }
        let step1: @Sendable () async throws -> Acme_Performance_V1_CountReviewsResponse = {
            try await self.performanceReviewQuery.countReviews(outbound1)
        }
        let reply1 = try await step1()
        let requests2 = input.medicalRecord.lines.map { element in
            Acme_Patients_V1_CommentMedicalRecordApprovalRequest.with {
                $0.context = input.context
                $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                    $0.lines = [
                        Acme_Patients_V1_MedicalRecordLine.with {
                            $0.tax = Acme_Patients_V1_MedicalRecordLineTax.with {
                                $0.jurisdiction = element.tax.jurisdiction
                            }
                        }
                    ]
                }
            }
        }
        let replies2 = try await FanOut.map(requests2) { candidate in
            try await self.patientsMedicalRecordApproval.commentMedicalRecordApproval(candidate)
        }
        let reply2 = replies2.first ?? Acme_Patients_V1_CommentMedicalRecordApprovalResponse()
        let outbound3 = Acme_Identity_V1_WatchUsersRequest.with {
            $0.context = input.context
            $0.filter = Acme_Identity_V1_WatchUsersRequest.Filter.with {
                $0.region = reply2.medicalRecord.billingAddress.region
            }
            $0.subscriber = Acme_Common_V1_ContactInfo.with {
                $0.email = reply2.medicalRecord.counterparty.email
                $0.name = reply0.patient.contact.name
                $0.phone = reply0.patient.contact.phone
            }
        }
        let reply3 = try await self.identityUser.watchUsers(outbound3) { response in
            var latest = Acme_Identity_V1_WatchUsersResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        _ = reply3
        return Acme_Patients_V1_RetryMedicalRecordWorkflowResponse.with {
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = reply0.patient.primaryAddress.countryCode
                }
                $0.issuedAt = input.medicalRecord.issuedAt
                $0.medicalRecordID = input.medicalRecordID
            }
            $0.outcome = Acme_Patients_V1_RetryMedicalRecordWorkflowResponse.Outcome.with {
                $0.status = reply1.result.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processSignalMedicalRecordWorkflow(_ input: Acme_Patients_V1_SignalMedicalRecordWorkflowRequest) async throws
        -> Acme_Patients_V1_SignalMedicalRecordWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "audit", detail: input.details.initiatedBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SignalMedicalRecordWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicalRecordRecord(input.medicalRecord, tenant: input.context.tenantID)
        try await store.save(record.stored)
        var outbound0 = Acme_Patients_V1_CountPatientTotalsRequest()
        outbound0.context = input.context
        outbound0.filter = Acme_Patients_V1_CountPatientTotalsRequest.Filter.with {
            $0.createdAfter = input.medicalRecord.issuedAt
            $0.labels = input.medicalRecord.metadata
            $0.ownerID = input.medicalRecord.counterparty.patientID
            $0.region = input.medicalRecord.billingAddress.region
        }
        let reply0 = try await self.patientsPatientReporting.countPatientTotals(outbound0)
        let selection1_1: String
        switch input.medicalRecord.settlement {
        case .bank(let bank):
            selection1_1 = bank.accountHolder
        default: selection1_1 = .init()
        }
        let outbound1 = Acme_Patients_V1_RecallMedicalRecordRequest.with {
            $0.context = input.context
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.bank = Acme_Patients_V1_MedicalRecordBankSettlement.with {
                    $0.accountHolder = selection1_1
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = input.medicalRecord.counterparty.displayName
                }
            }
        }
        let reply1 = try await self.patientsMedicalRecordApproval.recallMedicalRecord(outbound1)
        let outbound2 = Acme_Search_V1_CountSearchIndexesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Search_V1_CountSearchIndexesRequest.Filter.with {
                $0.createdAfter = reply1.medicalRecord.audit.createdAt
                $0.labels = input.details.parameters
                $0.ownerID = reply1.medicalRecord.counterparty.patientID
                $0.region = reply1.medicalRecord.billingAddress.region
            }
        }
        let reply2 = try await RPCOperations.read {
            try await self.searchSearchIndexQuery.countSearchIndexes(outbound2)
        }
        let outbound3 = Acme_Patients_V1_StreamMedicalRecordMetricsRequest.with {
            $0.context = input.context
            $0.subscriber = Acme_Common_V1_ContactInfo.with {
                $0.email = reply1.medicalRecord.counterparty.email
            }
        }
        let reply3 = try await self.patientsMedicalRecordReporting.streamMedicalRecordMetrics(outbound3) { response in
            var latest = Acme_Patients_V1_StreamMedicalRecordMetricsResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        _ = reply3
        return Acme_Patients_V1_SignalMedicalRecordWorkflowResponse.with {
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.counterparty = input.medicalRecord.counterparty
                $0.medicalRecordID = input.medicalRecordID
            }
            $0.outcome = Acme_Patients_V1_SignalMedicalRecordWorkflowResponse.Outcome.with {
                $0.message = Projection.firstValue(
                    [
                        reply1.result.message,
                        reply2.result.message,
                    ], default: .init())
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.message = reply1.result.message
                $0.status = reply0.result.status
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processStartMedicalRecordWorkflow(_ input: Acme_Patients_V1_StartMedicalRecordWorkflowRequest) async throws
        -> Acme_Patients_V1_StartMedicalRecordWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "audit", detail: input.details.initiatedBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "StartMedicalRecordWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicalRecordRecord(input.medicalRecord, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Careplans_V1_ScheduleVitalReportRequest.with {
            $0.annotations = input.annotations
            $0.context = input.context
            $0.details = Acme_Careplans_V1_ScheduleVitalReportRequest.Details.with {
                $0.filters = input.details.parameters
            }
            $0.reason = input.reason
        }
        let reply0 = try await self.careplansVitalReporting.scheduleVitalReport(outbound0)
        return Acme_Patients_V1_StartMedicalRecordWorkflowResponse.with {
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.medicalRecordID = input.medicalRecordID
                $0.notes = input.medicalRecord.notes
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.message = reply0.result.message
                $0.status = "ok"
            }
        }
    }
}
