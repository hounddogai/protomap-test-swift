import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension PrescriptionQueryEndpoint {
    /// Execute the prescriptions workflow and project its upstream replies.
    func processBrowsePrescriptions(_ input: Acme_Prescriptions_V1_BrowsePrescriptionsRequest) async throws
        -> Acme_Prescriptions_V1_BrowsePrescriptionsResponse
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
            "BrowsePrescriptions",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "BrowsePrescriptions", detail: input.context.traceID
        )
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        let importFrame = Acme_Telehealth_V1_BatchCreateVideoVisitsRequest.with {
            $0.context = input.context
        }
        _ = try await self.telehealthVideoVisit.batchCreateVideoVisits { writer in
            try await writer.write(importFrame)
        }
        let outbound0 = Acme_Search_V1_BatchGetSearchIndexesRequest.with {
            $0.context = input.context
        }
        let reply0 = try await self.browsePrescriptionsStep0.execute(outbound0)
        return Acme_Prescriptions_V1_BrowsePrescriptionsResponse.with {
            $0.pageInfo = Acme_Common_V1_PageInfo.with {
                $0.nextPageToken = reply0.pageInfo.nextPageToken
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processCountPrescriptions(_ input: Acme_Prescriptions_V1_CountPrescriptionsRequest) async throws
        -> Acme_Prescriptions_V1_CountPrescriptionsResponse
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
            "CountPrescriptions",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "CountPrescriptions", detail: input.context.traceID
        )
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        return Acme_Prescriptions_V1_CountPrescriptionsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processExportPrescriptions(_ input: Acme_Prescriptions_V1_ExportPrescriptionsRequest) async throws
        -> Acme_Prescriptions_V1_ExportPrescriptionsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.destinationUri)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "audit", detail: input.destinationUri
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ExportPrescriptions",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "ExportPrescriptions", detail: input.context.traceID
        )
        let outbound0 = Acme_Prescriptions_V1_RecalculateMedicationsRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_RecalculateMedicationsRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
            }
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.email = input.context.actor.email
                    $0.userID = input.context.actor.userID
                }
            }
        }
        let port0 = RPCOperations.port { (request: Acme_Prescriptions_V1_RecalculateMedicationsRequest) in
            try await self.prescriptionsMedicationCalculation.recalculateMedications(request)
        }
        let reply0 = try await port0.execute(outbound0)
        let outbound1 = Acme_Metrics_V1_WatchMetricSeriesesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Metrics_V1_WatchMetricSeriesesRequest.Filter.with {
                $0.query = input.filter.query
                $0.region = input.filter.region
            }
            $0.subscriber = Acme_Common_V1_ContactInfo.with {
                $0.email = reply0.medication.owner.email
            }
        }
        let reply1 = try await self.metricsMetricSeries.watchMetricSerieses(outbound1) { response in
            var latest = Acme_Metrics_V1_WatchMetricSeriesesResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        _ = reply1
        let outbound2 = Acme_Prescriptions_V1_CalculateMedicationRequest.with {
            $0.context = input.context
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply0.medication.audit.etag
                    $0.updatedBy = reply0.medication.audit.updatedBy
                }
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply0.medication.owner.displayName
                }
            }
        }
        let reply2 = try await self.exportPrescriptionsStep2(outbound2)
        return Acme_Prescriptions_V1_ExportPrescriptionsResponse.with {
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.referenceIds = reply2.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processFindPrescriptions(_ input: Acme_Prescriptions_V1_FindPrescriptionsRequest) async throws
        -> Acme_Prescriptions_V1_FindPrescriptionsResponse
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
            "FindPrescriptions",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "FindPrescriptions", detail: input.context.traceID
        )
        return Acme_Prescriptions_V1_FindPrescriptionsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processLookupPrescription(_ input: Acme_Prescriptions_V1_LookupPrescriptionRequest) async throws
        -> Acme_Prescriptions_V1_LookupPrescriptionResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "LookupPrescription",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "LookupPrescription", detail: input.context.traceID
        )
        return Acme_Prescriptions_V1_LookupPrescriptionResponse.with {
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.prescriptionID = input.prescriptionID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processPeekPrescription(_ input: Acme_Prescriptions_V1_PeekPrescriptionRequest) async throws
        -> Acme_Prescriptions_V1_PeekPrescriptionResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "PeekPrescription",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "PeekPrescription", detail: input.context.traceID
        )
        let outbound0 = Acme_Authorization_V1_ListAccessPoliciesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Authorization_V1_ListAccessPoliciesRequest.Filter.with {
                $0.createdAfter = input.context.deadline
                $0.labels = input.context.baggage
                $0.ownerID = input.prescriptionID
            }
        }
        guard let execute0 = self.peekPrescriptionStep0[settings.region] ?? self.peekPrescriptionStep0["primary"] else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply0 = try await execute0(outbound0)
        return Acme_Prescriptions_V1_PeekPrescriptionResponse.with {
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.prescriptionID = input.prescriptionID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processResolvePrescriptions(_ input: Acme_Prescriptions_V1_ResolvePrescriptionsRequest) async throws
        -> Acme_Prescriptions_V1_ResolvePrescriptionsResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ResolvePrescriptions",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "ResolvePrescriptions", detail: input.context.traceID
        )
        return Acme_Prescriptions_V1_ResolvePrescriptionsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processSuggestPrescriptions(_ input: Acme_Prescriptions_V1_SuggestPrescriptionsRequest) async throws
        -> Acme_Prescriptions_V1_SuggestPrescriptionsResponse
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
            "SuggestPrescriptions",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "SuggestPrescriptions", detail: input.context.traceID
        )
        let outbound0 = Acme_Search_V1_BrowseSearchIndexesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Search_V1_BrowseSearchIndexesRequest.Filter.with {
                $0.labels = input.filter.labels
                $0.region = input.filter.region
            }
            $0.page = Acme_Common_V1_PageRequest.with {
                $0.pageSize = input.page.pageSize
                $0.pageToken = input.page.pageToken
            }
        }
        let reply0 = try await self.searchSearchIndexQuery.browseSearchIndexes(outbound0)
        return Acme_Prescriptions_V1_SuggestPrescriptionsResponse.with {
            $0.pageInfo = Acme_Common_V1_PageInfo.with {
                $0.nextPageToken = reply0.pageInfo.nextPageToken
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processSummarizePrescriptions(_ input: Acme_Prescriptions_V1_SummarizePrescriptionsRequest) async throws
        -> Acme_Prescriptions_V1_SummarizePrescriptionsResponse
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
            "SummarizePrescriptions",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "prescription",
            action: "SummarizePrescriptions", detail: input.context.traceID
        )
        let outbound0 = Acme_Prescriptions_V1_CheckMedicationEligibilityRequest.with {
            $0.annotations = input.annotations
            $0.context = input.context
            $0.reason = input.reason
        }
        let envelope0 = try Google_Protobuf_Any(message: outbound0)
        let unpacked0 = try Acme_Prescriptions_V1_CheckMedicationEligibilityRequest(unpackingAny: envelope0)
        let reply0 = try await self.prescriptionsMedicationValidation.checkMedicationEligibility(unpacked0)
        let selection1_1: String
        switch reply0.medication.locator {
        case .address(let address):
            selection1_1 = address.region
        default: selection1_1 = .init()
        }
        let outbound1 = Acme_Prescriptions_V1_ScorePrescriptionRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_ScorePrescriptionRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.region = selection1_1
                }
            }
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply0.medication.audit.etag
                }
            }
        }
        let reply1 = try await self.prescriptionsPrescriptionValidation.scorePrescription(outbound1)
        let outbound2 = Acme_Prescriptions_V1_ExplainRefillCalculationRequest.with {
            $0.context = input.context
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply0.medication.audit.createdBy
                }
            }
        }
        let json2 = try outbound2.jsonString()
        let decoded2 = try Acme_Prescriptions_V1_ExplainRefillCalculationRequest(jsonString: json2)
        let reply2 = try await self.prescriptionsRefillCalculation.explainRefillCalculation(decoded2)
        let outbound3 =
            Acme_Prescriptions_V1_NormalizeMedicationRequest.forPrescriptionQueryEndpointSummarizePrescriptions3(
                input,
                reply0: reply0,
                reply1: reply1
            )
        let reply3 = try await self.prescriptionsMedicationValidation.normalizeMedication(outbound3)
        return Acme_Prescriptions_V1_SummarizePrescriptionsResponse.with {
            $0.period = input.details.period
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply3.result.correlationID
                $0.details = Projection.firstValue(
                    [
                        reply1.result.details,
                        reply2.result.details,
                    ], default: .init())
                $0.message = Projection.firstValue(
                    [
                        reply0.result.message,
                        reply3.result.message,
                    ], default: .init())
                $0.status = reply2.outcome.status
            }
        }
    }
}
