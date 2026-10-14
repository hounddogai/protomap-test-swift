import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension AllergyReportingEndpoint {
    /// Counts allergies by status.
    func countAllergyTotals(
        request: ServerRequest<Acme_Patients_V1_CountAllergyTotalsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_CountAllergyTotalsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCountAllergyTotals(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Deletes an allergy.
    func deleteAllergyReport(
        request: ServerRequest<Acme_Patients_V1_DeleteAllergyReportRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_DeleteAllergyReportResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processDeleteAllergyReport(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns an allergy.
    func fetchAllergyReport(
        request: ServerRequest<Acme_Patients_V1_FetchAllergyReportRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_FetchAllergyReportResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processFetchAllergyReport(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Generates an allergy.
    func generateAllergyReport(
        request: ServerRequest<Acme_Patients_V1_GenerateAllergyReportRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_GenerateAllergyReportResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGenerateAllergyReport(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists allergies a page at a time.
    func listAllergyReports(
        request: ServerRequest<Acme_Patients_V1_ListAllergyReportsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_ListAllergyReportsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListAllergyReports(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Schedules an allergy.
    func scheduleAllergyReport(
        request: ServerRequest<Acme_Patients_V1_ScheduleAllergyReportRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_ScheduleAllergyReportResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processScheduleAllergyReport(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Shares an allergy.
    func shareAllergyReport(
        request: ServerRequest<Acme_Patients_V1_ShareAllergyReportRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_ShareAllergyReportResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processShareAllergyReport(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Streams the changes of allergies as they happen.
    func streamAllergyMetrics(
        request: ServerRequest<Acme_Patients_V1_StreamAllergyMetricsRequest>,
        context: ServerContext
    ) async throws -> StreamingServerResponse<Acme_Patients_V1_StreamAllergyMetricsResponse> {
        return StreamingServerResponse { writer in
            try await CallerScope.$metadata.withValue(request.metadata) {
                let response = try await self.processStreamAllergyMetrics(request.message)
                try await writer.write(response)
                return [:]
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processCountAllergyTotals(_ input: Acme_Patients_V1_CountAllergyTotalsRequest) async throws
        -> Acme_Patients_V1_CountAllergyTotalsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "CountAllergyTotals",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "CountAllergyTotals", detail: input.context.traceID
        )
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        let archive = Data(try input.context.jsonString().utf8)
        let restoredContext = try Acme_Common_V1_RequestContext(
            jsonString: String(decoding: archive, as: UTF8.self)
        )
        _ = try await self.prescriptionsPrescriptionSync.syncPrescriptions(
            Acme_Prescriptions_V1_SyncPrescriptionsRequest.with {
                $0.context = restoredContext
                $0.details = Acme_Prescriptions_V1_SyncPrescriptionsRequest.Details.with {
                    $0.payload = archive
                }
            })
        let outbound0 = Acme_Patients_V1_SummarizePatientsRequest.with {
            $0.context = input.context
            $0.details = Acme_Patients_V1_SummarizePatientsRequest.Details.with {
                $0.filters = input.filter.labels
            }
        }
        let reply0 = try await RPCOperations.call(outbound0) { request in
            try await self.patientsPatientQuery.summarizePatients(request)
        }
        let outbound1 = Acme_Patients_V1_SchedulePatientExpiryRequest.with {
            $0.context = Projection.read(input, at: \Acme_Patients_V1_CountAllergyTotalsRequest.context)
            $0.details = Acme_Patients_V1_SchedulePatientExpiryRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.email = Projection.read(
                        input, at: \Acme_Patients_V1_CountAllergyTotalsRequest.context.actor.email)
                }
            }
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = Projection.read(
                        input, at: \Acme_Patients_V1_CountAllergyTotalsRequest.filter.createdAfter)
                }
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = Projection.read(input, at: \Acme_Patients_V1_CountAllergyTotalsRequest.filter.region)
                }
            }
        }
        let reply1 = try await self.patientsPatientLifecycle.schedulePatientExpiry(outbound1)
        return Acme_Patients_V1_CountAllergyTotalsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.status = Projection.firstValue(
                    [
                        reply0.result.status,
                        reply1.outcome.status,
                    ], default: .init())
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processDeleteAllergyReport(_ input: Acme_Patients_V1_DeleteAllergyReportRequest) async throws
        -> Acme_Patients_V1_DeleteAllergyReportResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.allergyID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "audit", detail: input.allergyID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "DeleteAllergyReport",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "DeleteAllergyReport", detail: input.context.traceID
        )
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        let outbound0 = Acme_Authorization_V1_ValidateAccessPolicyRequest.with {
            $0.accessPolicy = Acme_Authorization_V1_AccessPolicy.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = input.etag
                }
            }
            $0.context = input.context
            $0.details = Acme_Authorization_V1_ValidateAccessPolicyRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.context.actor.email
                }
            }
        }
        let step0: @Sendable () async throws -> Acme_Authorization_V1_ValidateAccessPolicyResponse = {
            try await self.authorizationAccessPolicyValidation.validateAccessPolicy(outbound0)
        }
        let reply0 = try await step0()
        var outbound1 = Acme_Patients_V1_RecalculatePatientsRequest()
        outbound1.context = input.context
        outbound1.patient = Acme_Patients_V1_Patient.with {
            $0.audit = Acme_Common_V1_AuditInfo.with {
                $0.etag = reply0.accessPolicy.audit.etag
            }
            $0.contact = Acme_Common_V1_ContactInfo.with {
                $0.email = reply0.accessPolicy.owner.email
            }
            $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                $0.displayName = reply0.accessPolicy.owner.displayName
            }
        }
        let reply1 = try await self.patientsPatientCalculation.recalculatePatients(outbound1)
        return Acme_Patients_V1_DeleteAllergyReportResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.details = reply1.result.details
                $0.message = reply1.result.message
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processFetchAllergyReport(_ input: Acme_Patients_V1_FetchAllergyReportRequest) async throws
        -> Acme_Patients_V1_FetchAllergyReportResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "FetchAllergyReport",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "FetchAllergyReport", detail: input.context.traceID
        )
        return Acme_Patients_V1_FetchAllergyReportResponse.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.allergyID = input.allergyID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processGenerateAllergyReport(_ input: Acme_Patients_V1_GenerateAllergyReportRequest) async throws
        -> Acme_Patients_V1_GenerateAllergyReportResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.cron)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "audit", detail: input.details.cron
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "GenerateAllergyReport",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "GenerateAllergyReport", detail: input.context.traceID
        )
        let outbound0 = Acme_Patients_V1_ResolvePatientsRequest.with {
            $0.context = input.context
        }
        let reply0 = try await RPCOperations.read {
            try await self.patientsPatientQuery.resolvePatients(outbound0)
        }
        let outbound1 = Acme_Patients_V1_ListPatientsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Patients_V1_ListPatientsRequest.Filter.with {
                $0.createdAfter = input.context.deadline
                $0.labels = input.details.filters
                $0.ownerID = input.allergyID
            }
        }
        let reply1 = try await self.patientsPatient.listPatients(outbound1)
        return Acme_Patients_V1_GenerateAllergyReportResponse.with {
            $0.period = input.details.period
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply0.result.referenceIds
                $0.status = Projection.firstValue(
                    [
                        reply0.result.status,
                        reply1.result.status,
                    ], default: .init())
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processListAllergyReports(_ input: Acme_Patients_V1_ListAllergyReportsRequest) async throws
        -> Acme_Patients_V1_ListAllergyReportsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ListAllergyReports",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "ListAllergyReports", detail: input.context.traceID
        )
        let outbound0 = Acme_Prescriptions_V1_ListRefillImportsRequest.with {
            $0.context = input.context
            $0.page = Acme_Common_V1_PageRequest.with {
                $0.pageSize = input.page.pageSize
            }
        }
        async let remote0 = self.prescriptionsRefillImport.listRefillImports(outbound0)
        async let persisted0 = store.count(tenant: input.context.tenantID)
        let (reply0, count0) = try await (remote0, persisted0)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count0)])
        return Acme_Patients_V1_ListAllergyReportsResponse.with {
            $0.pageInfo = Acme_Common_V1_PageInfo.with {
                $0.nextPageToken = reply0.pageInfo.nextPageToken
                $0.totalSize = reply0.pageInfo.totalSize
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processScheduleAllergyReport(_ input: Acme_Patients_V1_ScheduleAllergyReportRequest) async throws
        -> Acme_Patients_V1_ScheduleAllergyReportResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.allergyID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "audit", detail: input.allergyID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ScheduleAllergyReport",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "ScheduleAllergyReport", detail: input.context.traceID
        )
        let outbound0 = Acme_Careplans_V1_ScheduleVitalReportRequest.with {
            $0.context = input.context
            $0.details = Acme_Careplans_V1_ScheduleVitalReportRequest.Details.with {
                $0.filters = input.details.filters
                $0.format = input.details.format
                $0.period = input.details.period
            }
        }
        let reply0 = try await self.scheduleAllergyReportStep0.execute(outbound0)
        let outbound1 = Acme_Search_V1_CountSearchIndexesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Search_V1_CountSearchIndexesRequest.Filter.with {
                $0.labels = input.details.filters
            }
        }
        let port1 = RPCOperations.port { (request: Acme_Search_V1_CountSearchIndexesRequest) in
            try await self.searchSearchIndexQuery.countSearchIndexes(request)
        }
        let reply1 = try await port1.execute(outbound1)
        return Acme_Patients_V1_ScheduleAllergyReportResponse.with {
            $0.period = input.details.period
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply1.result.message
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processShareAllergyReport(_ input: Acme_Patients_V1_ShareAllergyReportRequest) async throws
        -> Acme_Patients_V1_ShareAllergyReportResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.channel)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "audit", detail: input.details.channel
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ShareAllergyReport",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "ShareAllergyReport", detail: input.context.traceID
        )
        let outbound0 = Acme_Prescriptions_V1_MapRefillImportColumnsRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_MapRefillImportColumnsRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.name = input.details.recipient.name
                    $0.phone = input.details.recipient.phone
                }
            }
        }
        let reply0 = try await self.shareAllergyReportStep0(outbound0)
        let selection1_1: String
        switch reply0.refill.origin {
        case .customer(let customer):
            selection1_1 = customer.displayName
        default: selection1_1 = .init()
        }
        let outbound1 = Acme_Patients_V1_SyncAllergiesRequest.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = selection1_1
                }
            }
            $0.context = input.context
        }
        let reply1 = try await self.patientsAllergySync.syncAllergies(outbound1)
        let outbound2 = Acme_Patients_V1_RetryAllergyImportRequest.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = reply0.refill.assignee.displayName
                    $0.email = reply1.allergy.subject.email
                }
            }
            $0.context = input.context
            $0.details = Acme_Patients_V1_RetryAllergyImportRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.recipient.email
                }
            }
        }
        guard let execute2 = self.shareAllergyReportStep2[settings.region] ?? self.shareAllergyReportStep2["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply2 = try await execute2(outbound2)
        return Acme_Patients_V1_ShareAllergyReportResponse.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.allergyID = input.allergyID
                $0.kind = reply1.allergy.kind
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = reply0.refill.customer.displayName
                    $0.email = input.details.recipient.email
                }
            }
            $0.outcome = Acme_Patients_V1_ShareAllergyReportResponse.Outcome.with {
                $0.status = reply1.outcome.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply2.allergy.correlationID
                $0.status = reply0.outcome.status
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processStreamAllergyMetrics(_ input: Acme_Patients_V1_StreamAllergyMetricsRequest) async throws
        -> Acme_Patients_V1_StreamAllergyMetricsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "StreamAllergyMetrics",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "allergy",
            action: "StreamAllergyMetrics", detail: input.context.traceID
        )
        let outbound0 = Acme_Search_V1_UpdateSearchIndexRequest.with {
            $0.context = input.context
            $0.searchIndex = Acme_Search_V1_SearchIndex.with {
                $0.address = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.since
                }
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.email = input.subscriber.email
                    $0.userID = input.context.actor.userID
                }
            }
        }
        let reply0 = try await self.searchSearchIndex.updateSearchIndex(outbound0)
        let selection1_1: String
        switch reply0.searchIndex.locator {
        case .address(let address):
            selection1_1 = address.recipient
        default: selection1_1 = .init()
        }
        let selection1_2: [String]
        switch reply0.searchIndex.locator {
        case .address(let address):
            selection1_2 = address.lines
        default: selection1_2 = .init()
        }
        let outbound1 = Acme_Identity_V1_ScoreUserRequest.with {
            $0.context = input.context
            $0.details = Acme_Identity_V1_ScoreUserRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.lines = selection1_2
                }
            }
            $0.user = Acme_Identity_V1_User.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply0.searchIndex.audit.etag
                    $0.updatedAt = reply0.searchIndex.audit.updatedAt
                }
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.recipient = selection1_1
                }
            }
        }
        let reply1 = try await self.identityUserValidation.scoreUser(outbound1)
        return Acme_Patients_V1_StreamAllergyMetricsResponse.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.attributes = reply1.user.attributes
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.email = input.subscriber.email
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.result.message
                $0.referenceIds = reply1.result.referenceIds
                $0.status = "ok"
            }
        }
    }
}
