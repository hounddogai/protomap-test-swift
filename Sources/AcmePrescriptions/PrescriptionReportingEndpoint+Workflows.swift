import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension PrescriptionReportingEndpoint {
    /// Counts prescriptions by status.
    func countPrescriptionTotals(
        request: ServerRequest<Acme_Prescriptions_V1_CountPrescriptionTotalsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_CountPrescriptionTotalsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCountPrescriptionTotals(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Deletes a prescription.
    func deletePrescriptionReport(
        request: ServerRequest<Acme_Prescriptions_V1_DeletePrescriptionReportRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_DeletePrescriptionReportResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processDeletePrescriptionReport(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a prescription.
    func fetchPrescriptionReport(
        request: ServerRequest<Acme_Prescriptions_V1_FetchPrescriptionReportRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_FetchPrescriptionReportResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processFetchPrescriptionReport(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Generates a prescription.
    func generatePrescriptionReport(
        request: ServerRequest<Acme_Prescriptions_V1_GeneratePrescriptionReportRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_GeneratePrescriptionReportResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGeneratePrescriptionReport(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists prescriptions a page at a time.
    func listPrescriptionReports(
        request: ServerRequest<Acme_Prescriptions_V1_ListPrescriptionReportsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ListPrescriptionReportsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListPrescriptionReports(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Schedules a prescription.
    func schedulePrescriptionReport(
        request: ServerRequest<Acme_Prescriptions_V1_SchedulePrescriptionReportRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_SchedulePrescriptionReportResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSchedulePrescriptionReport(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Shares a prescription.
    func sharePrescriptionReport(
        request: ServerRequest<Acme_Prescriptions_V1_SharePrescriptionReportRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_SharePrescriptionReportResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSharePrescriptionReport(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Streams the changes of prescriptions as they happen.
    func streamPrescriptionMetrics(
        request: ServerRequest<Acme_Prescriptions_V1_StreamPrescriptionMetricsRequest>,
        context: ServerContext
    ) async throws -> StreamingServerResponse<Acme_Prescriptions_V1_StreamPrescriptionMetricsResponse> {
        return StreamingServerResponse { writer in
            try await CallerScope.$metadata.withValue(request.metadata) {
                let response = try await self.processStreamPrescriptionMetrics(request.message)
                try await writer.write(response)
                return [:]
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processCountPrescriptionTotals(_ input: Acme_Prescriptions_V1_CountPrescriptionTotalsRequest) async throws
        -> Acme_Prescriptions_V1_CountPrescriptionTotalsResponse
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
            "CountPrescriptionTotals",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "CountPrescriptionTotals", detail: input.context.traceID
        )
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        try followUps.submit(
            Acme_Identity_V1_GetUserRequest.with {
                $0.context = input.context
                $0.userID = input.context.actor.userID
            })
        let archive = Data(try input.context.jsonString().utf8)
        let restoredContext = try Acme_Common_V1_RequestContext(
            jsonString: String(decoding: archive, as: UTF8.self)
        )
        _ = try await self.prescriptionsMedicationSync.pullMedications(
            Acme_Prescriptions_V1_PullMedicationsRequest.with {
                $0.context = restoredContext
                $0.details = Acme_Prescriptions_V1_PullMedicationsRequest.Details.with {
                    $0.payload = archive
                }
            })
        let outbound0 = Acme_Payments_V1_QuotePaymentRequest.with {
            $0.context = input.context
            $0.payment = Acme_Payments_V1_Payment.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.filter.createdAfter
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
                $0.lines = [
                    Acme_Payments_V1_PaymentLine.with {
                        $0.attributes = input.filter.labels
                    }
                ]
            }
        }
        let reply0 = try await self.paymentsPaymentCalculation.quotePayment(
            outbound0, metadata: ["x-acme-region": .string(settings.region)]
        )
        return Acme_Prescriptions_V1_CountPrescriptionTotalsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply0.result.referenceIds
                $0.status = reply0.result.status
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processDeletePrescriptionReport(_ input: Acme_Prescriptions_V1_DeletePrescriptionReportRequest) async throws
        -> Acme_Prescriptions_V1_DeletePrescriptionReportResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "DeletePrescriptionReport",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "DeletePrescriptionReport", detail: input.context.traceID
        )
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        let outbound0 = Acme_Patients_V1_CountPatientsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Patients_V1_CountPatientsRequest.Filter.with {
                $0.createdAfter = input.context.deadline
                $0.labels = input.context.baggage
                $0.ownerID = input.prescriptionID
            }
        }
        let reply0 = try await RPCOperations.call(outbound0) { request in
            try await self.patientsPatientQuery.countPatients(request)
        }
        let outbound1 = Acme_Prescriptions_V1_CountMedicationsRequest.with {
            $0.context = Projection.read(input, at: \Acme_Prescriptions_V1_DeletePrescriptionReportRequest.context)
            $0.filter = Acme_Prescriptions_V1_CountMedicationsRequest.Filter.with {
                $0.createdAfter = Projection.read(
                    input, at: \Acme_Prescriptions_V1_DeletePrescriptionReportRequest.context.deadline)
                $0.labels = reply0.result.details
                $0.ownerID = Projection.read(reply0, at: \Acme_Patients_V1_CountPatientsResponse.result.correlationID)
            }
        }
        let reply1 = try await self.prescriptionsMedicationQuery.countMedications(outbound1)
        let outbound2 = Acme_Authorization_V1_LintAccessPoliciesRequest.with {
            $0.accessPolicy = Acme_Authorization_V1_AccessPolicy.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = input.etag
                }
                $0.block = Acme_Authorization_V1_AccessPolicyBlockAction.with {
                    $0.reason = input.reason
                }
            }
            $0.context = input.context
        }
        let step2: @Sendable () async throws -> Acme_Authorization_V1_LintAccessPoliciesResponse = {
            try await self.authorizationAccessPolicyValidation.lintAccessPolicies(outbound2)
        }
        let reply2 = try await step2()
        return Acme_Prescriptions_V1_DeletePrescriptionReportResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = Projection.firstValue(
                    [
                        reply1.result.details,
                        reply2.result.details,
                    ], default: .init())
                $0.message = reply1.result.message
                $0.referenceIds = reply2.result.referenceIds
                $0.status = reply0.result.status
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processFetchPrescriptionReport(_ input: Acme_Prescriptions_V1_FetchPrescriptionReportRequest) async throws
        -> Acme_Prescriptions_V1_FetchPrescriptionReportResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "FetchPrescriptionReport",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "FetchPrescriptionReport", detail: input.context.traceID
        )
        var outbound0 = Acme_Patients_V1_EstimatePatientRequest()
        outbound0.context = input.context
        outbound0.patient = Acme_Patients_V1_Patient.with {
            $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                $0.userID = input.context.actor.userID
            }
        }
        let reply0 = try await self.patientsPatientCalculation.estimatePatient(outbound0)
        return Acme_Prescriptions_V1_FetchPrescriptionReportResponse.with {
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.patientID = reply0.patient.patientID
                }
                $0.prescriptionID = input.prescriptionID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processGeneratePrescriptionReport(_ input: Acme_Prescriptions_V1_GeneratePrescriptionReportRequest)
        async throws -> Acme_Prescriptions_V1_GeneratePrescriptionReportResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.cron)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "audit", detail: input.details.cron
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "GeneratePrescriptionReport",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "GeneratePrescriptionReport", detail: input.context.traceID
        )
        let outbound0 = Acme_Patients_V1_BatchGetPatientsRequest.with {
            $0.context = input.context
        }
        let reply0 = try await RPCOperations.read {
            try await self.patientsPatient.batchGetPatients(outbound0)
        }
        let outbound1 = Acme_Patients_V1_FindMedicalRecordsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Patients_V1_FindMedicalRecordsRequest.Filter.with {
                $0.createdAfter = input.context.deadline
                $0.labels = input.details.filters
                $0.ownerID = reply0.result.correlationID
            }
        }
        let reply1 = try await self.patientsMedicalRecordQuery.findMedicalRecords(outbound1)
        return Acme_Prescriptions_V1_GeneratePrescriptionReportResponse.with {
            $0.period = input.details.period
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = Projection.firstValue(
                    [
                        reply0.result.correlationID,
                        reply1.result.correlationID,
                    ], default: .init())
                $0.message = reply0.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processListPrescriptionReports(_ input: Acme_Prescriptions_V1_ListPrescriptionReportsRequest) async throws
        -> Acme_Prescriptions_V1_ListPrescriptionReportsResponse
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
            "ListPrescriptionReports",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "ListPrescriptionReports", detail: input.context.traceID
        )
        let outbound0 = Acme_Prescriptions_V1_PushMedicationRequest.with {
            $0.context = input.context
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.address = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
            }
        }
        async let remote0 = self.prescriptionsMedicationSync.pushMedication(outbound0)
        async let persisted0 = store.count(tenant: input.context.tenantID)
        let (reply0, count0) = try await (remote0, persisted0)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count0)])
        return Acme_Prescriptions_V1_ListPrescriptionReportsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processSchedulePrescriptionReport(_ input: Acme_Prescriptions_V1_SchedulePrescriptionReportRequest)
        async throws -> Acme_Prescriptions_V1_SchedulePrescriptionReportResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.cron)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "audit", detail: input.details.cron
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SchedulePrescriptionReport",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "SchedulePrescriptionReport", detail: input.context.traceID
        )
        let outbound0 = Acme_Fraud_V1_BatchGetRiskAssessmentsRequest.with {
            $0.context = input.context
        }
        let reply0 = try await self.schedulePrescriptionReportStep0.execute(outbound0)
        let outbound1 = Acme_Authorization_V1_NormalizeAccessPolicyRequest.with {
            $0.accessPolicy = Acme_Authorization_V1_AccessPolicy.with {
                $0.block = Acme_Authorization_V1_AccessPolicyBlockAction.with {
                    $0.reason = input.reason
                }
            }
            $0.annotations = input.annotations
            $0.context = input.context
            $0.details = Acme_Authorization_V1_NormalizeAccessPolicyRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.context.actor.email
                }
                $0.locale = input.context.locale
            }
        }
        let port1 = RPCOperations.port { (request: Acme_Authorization_V1_NormalizeAccessPolicyRequest) in
            try await self.authorizationAccessPolicyValidation.normalizeAccessPolicy(request)
        }
        let reply1 = try await port1.execute(outbound1)
        return Acme_Prescriptions_V1_SchedulePrescriptionReportResponse.with {
            $0.period = input.details.period
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply1.result.details
                $0.message = Projection.firstValue(
                    [
                        reply0.result.message,
                        reply1.outcome.message,
                    ], default: .init())
                $0.status = reply0.result.status
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processSharePrescriptionReport(_ input: Acme_Prescriptions_V1_SharePrescriptionReportRequest) async throws
        -> Acme_Prescriptions_V1_SharePrescriptionReportResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.recipient.preferredChannel)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "audit", detail: input.details.recipient.preferredChannel
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SharePrescriptionReport",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "SharePrescriptionReport", detail: input.context.traceID
        )
        let outbound0 = Acme_Authorization_V1_CountAccessPoliciesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Authorization_V1_CountAccessPoliciesRequest.Filter.with {
                $0.labels = input.details.variables
            }
        }
        let reply0 = try await self.sharePrescriptionReportStep0(outbound0)
        let outbound1 = Acme_Careplans_V1_EscalateCareGoalRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.email = input.details.recipient.email
                }
                $0.channel = Acme_Careplans_V1_CareGoalChannelOrigin.with {
                    $0.channel = input.details.channel
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.phone = input.details.recipient.phone
                }
            }
            $0.context = input.context
        }
        guard
            let execute1 = self.sharePrescriptionReportStep1[settings.region]
                ?? self.sharePrescriptionReportStep1["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply1 = try await execute1(outbound1)
        let outbound2 = Acme_Prescriptions_V1_PushPrescriptionRequest.with {
            $0.context = input.context
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply1.careGoal.audit.updatedAt
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.email = input.details.recipient.email
                }
            }
        }
        let reply2 = try await self.prescriptionsPrescriptionSync.pushPrescription(outbound2)
        let outbound3 = Acme_Venues_V1_SummarizeVenuesRequest.with {
            $0.context = input.context
            $0.reason = input.reason
        }
        let envelope3 = try Google_Protobuf_Any(message: outbound3)
        let unpacked3 = try Acme_Venues_V1_SummarizeVenuesRequest(unpackingAny: envelope3)
        let reply3 = try await self.venuesVenueQuery.summarizeVenues(unpacked3)
        return Acme_Prescriptions_V1_SharePrescriptionReportResponse.with {
            $0.outcome = Acme_Prescriptions_V1_SharePrescriptionReportResponse.Outcome.with {
                $0.message = reply0.result.message
                $0.nextSteps = reply1.outcome.nextSteps
            }
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.locality = reply2.prescription.billingAddress.locality
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.email = reply1.careGoal.requester.email
                }
                $0.prescriptionID = input.prescriptionID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply0.result.referenceIds + reply3.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processStreamPrescriptionMetrics(_ input: Acme_Prescriptions_V1_StreamPrescriptionMetricsRequest) async throws
        -> Acme_Prescriptions_V1_StreamPrescriptionMetricsResponse
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
            "StreamPrescriptionMetrics",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "StreamPrescriptionMetrics", detail: input.context.traceID
        )
        let outbound0 = Acme_Prescriptions_V1_ValidateRefillImportRequest.with {
            $0.context = input.context
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.subscriber.email
                    $0.phone = input.subscriber.phone
                    $0.preferredChannel = input.subscriber.preferredChannel
                }
            }
        }
        let json0 = try outbound0.jsonString()
        let decoded0 = try Acme_Prescriptions_V1_ValidateRefillImportRequest(jsonString: json0)
        let reply0 = try await self.prescriptionsRefillImport.validateRefillImport(decoded0)
        let outbound1 =
            Acme_Careplans_V1_ExplainCarePlanCalculationRequest
            .forPrescriptionReportingEndpointStreamPrescriptionMetrics1(
                input,
                reply0: reply0
            )
        let reply1 = try await self.careplansCarePlanCalculation.explainCarePlanCalculation(outbound1)
        return Acme_Prescriptions_V1_StreamPrescriptionMetricsResponse.with {
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply0.refill.audit.etag
                    $0.updatedBy = reply1.carePlan.audit.updatedBy
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.email = input.subscriber.email
                }
                $0.dueAt = reply0.refill.sla.dueAt
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }
}
