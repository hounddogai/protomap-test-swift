import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension MedicationQueryEndpoint {
    /// Lists medications a page at a time.
    func browseMedications(
        request: ServerRequest<Acme_Prescriptions_V1_BrowseMedicationsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_BrowseMedicationsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processBrowseMedications(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Counts medications by status.
    func countMedications(
        request: ServerRequest<Acme_Prescriptions_V1_CountMedicationsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_CountMedicationsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCountMedications(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Streams every matching medication.
    func exportMedications(
        request: ServerRequest<Acme_Prescriptions_V1_ExportMedicationsRequest>,
        context: ServerContext
    ) async throws -> StreamingServerResponse<Acme_Prescriptions_V1_ExportMedicationsResponse> {
        return StreamingServerResponse { writer in
            try await CallerScope.$metadata.withValue(request.metadata) {
                let response = try await self.processExportMedications(request.message)
                try await writer.write(response)
                return [:]
            }
        }
    }

    /// Lists medications a page at a time.
    func findMedications(
        request: ServerRequest<Acme_Prescriptions_V1_FindMedicationsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_FindMedicationsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processFindMedications(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a medication.
    func lookupMedication(
        request: ServerRequest<Acme_Prescriptions_V1_LookupMedicationRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_LookupMedicationResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processLookupMedication(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a medication.
    func peekMedication(
        request: ServerRequest<Acme_Prescriptions_V1_PeekMedicationRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_PeekMedicationResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processPeekMedication(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns several medications at once.
    func resolveMedications(
        request: ServerRequest<Acme_Prescriptions_V1_ResolveMedicationsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ResolveMedicationsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processResolveMedications(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists medications a page at a time.
    func suggestMedications(
        request: ServerRequest<Acme_Prescriptions_V1_SuggestMedicationsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_SuggestMedicationsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSuggestMedications(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Summarizes a medication.
    func summarizeMedications(
        request: ServerRequest<Acme_Prescriptions_V1_SummarizeMedicationsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_SummarizeMedicationsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSummarizeMedications(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processBrowseMedications(_ input: Acme_Prescriptions_V1_BrowseMedicationsRequest) async throws
        -> Acme_Prescriptions_V1_BrowseMedicationsResponse
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
            "BrowseMedications",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "BrowseMedications", detail: input.context.traceID
        )
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        let importFrame = Acme_Telehealth_V1_BatchCreateVideoVisitsRequest.with {
            $0.context = input.context
        }
        _ = try await self.telehealthVideoVisit.batchCreateVideoVisits { writer in
            try await writer.write(importFrame)
        }
        let outbound0 = Acme_Prescriptions_V1_RecalculateMedicationsRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_RecalculateMedicationsRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
            }
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.filter.createdAfter
                }
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.email = input.context.actor.email
                    $0.userID = input.context.actor.userID
                }
            }
        }
        let step0: @Sendable () async throws -> Acme_Prescriptions_V1_RecalculateMedicationsResponse = {
            try await self.prescriptionsMedicationCalculation.recalculateMedications(outbound0)
        }
        let reply0 = try await step0()
        return Acme_Prescriptions_V1_BrowseMedicationsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processCountMedications(_ input: Acme_Prescriptions_V1_CountMedicationsRequest) async throws
        -> Acme_Prescriptions_V1_CountMedicationsResponse
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
            "CountMedications",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "CountMedications", detail: input.context.traceID
        )
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        let outbound0 = Acme_Documents_V1_CountDocumentsRequest.with {
            $0.context = input.context
            $0.page = Acme_Common_V1_PageRequest.with {
                $0.pageToken = input.page.pageToken
            }
        }
        let reply0 = try await self.documentsDocumentQuery.countDocuments(outbound0)
        return Acme_Prescriptions_V1_CountMedicationsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processExportMedications(_ input: Acme_Prescriptions_V1_ExportMedicationsRequest) async throws
        -> Acme_Prescriptions_V1_ExportMedicationsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.destinationUri)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "audit", detail: input.destinationUri
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ExportMedications",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "ExportMedications", detail: input.context.traceID
        )
        let outbound0 = Acme_Prescriptions_V1_ExplainMedicationCalculationRequest.with {
            $0.context = input.context
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.address = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.context.actor.userID
                }
            }
        }
        async let remote0 = self.prescriptionsMedicationCalculation.explainMedicationCalculation(outbound0)
        async let persisted0 = store.count(tenant: input.context.tenantID)
        let (reply0, count0) = try await (remote0, persisted0)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count0)])
        let outbound1 = Acme_Careplans_V1_ValidateCareGoalRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.userID = reply0.medication.owner.userID
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply0.medication.audit.createdAt
                    $0.createdBy = reply0.medication.audit.createdBy
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply0.medication.owner.email
                }
            }
            $0.context = input.context
        }
        let reply1 = try await self.exportMedicationsStep1.execute(outbound1)
        let selection2_1: String
        switch reply0.medication.locator {
        case .address(let address):
            selection2_1 = address.region
        default: selection2_1 = .init()
        }
        let outbound2 = Acme_Prescriptions_V1_FindPrescriptionsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Prescriptions_V1_FindPrescriptionsRequest.Filter.with {
                $0.createdAfter = input.filter.createdAfter
                $0.labels = input.filter.labels
                $0.query = input.filter.query
                $0.region = selection2_1
            }
        }
        let reply2 = try await self.prescriptionsPrescriptionQuery.findPrescriptions(outbound2)
        return Acme_Prescriptions_V1_ExportMedicationsResponse.with {
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.components = [
                    "primary": Acme_Prescriptions_V1_MedicationComponent.with {
                        $0.quantity = reply0.medication.components["primary", default: .init()].quantity
                    }
                ]
                $0.dimensions = Acme_Prescriptions_V1_MedicationDimensions.with {
                    $0.width = reply0.medication.dimensions.width
                }
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.email = reply1.careGoal.assignee.email
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply2.result.message
                $0.status = reply1.outcome.status
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processFindMedications(_ input: Acme_Prescriptions_V1_FindMedicationsRequest) async throws
        -> Acme_Prescriptions_V1_FindMedicationsResponse
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
            "FindMedications",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "FindMedications", detail: input.context.traceID
        )
        return Acme_Prescriptions_V1_FindMedicationsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processLookupMedication(_ input: Acme_Prescriptions_V1_LookupMedicationRequest) async throws
        -> Acme_Prescriptions_V1_LookupMedicationResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "LookupMedication",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "LookupMedication", detail: input.context.traceID
        )
        let outbound0 = Acme_Prescriptions_V1_ExplainPrescriptionDecisionRequest.with {
            $0.annotations = input.context.baggage
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_ExplainPrescriptionDecisionRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.context.actor.email
                }
                $0.locale = input.context.locale
            }
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = input.context.deadline
                }
            }
        }
        let port0 = RPCOperations.port { (request: Acme_Prescriptions_V1_ExplainPrescriptionDecisionRequest) in
            try await self.prescriptionsPrescriptionValidation.explainPrescriptionDecision(request)
        }
        let reply0 = try await port0.execute(outbound0)
        let outbound1 = Acme_Featureflags_V1_SuggestFeatureFlagsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Featureflags_V1_SuggestFeatureFlagsRequest.Filter.with {
                $0.createdAfter = reply0.prescription.audit.createdAt
                $0.region = reply0.prescription.billingAddress.region
            }
        }
        let reply1 = try await self.lookupMedicationStep1(outbound1)
        return Acme_Prescriptions_V1_LookupMedicationResponse.with {
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply0.prescription.audit.createdAt
                }
                $0.medicationID = input.medicationID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.outcome.message
                $0.status = reply1.result.status
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processPeekMedication(_ input: Acme_Prescriptions_V1_PeekMedicationRequest) async throws
        -> Acme_Prescriptions_V1_PeekMedicationResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "PeekMedication",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "PeekMedication", detail: input.context.traceID
        )
        return Acme_Prescriptions_V1_PeekMedicationResponse.with {
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.medicationID = input.medicationID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processResolveMedications(_ input: Acme_Prescriptions_V1_ResolveMedicationsRequest) async throws
        -> Acme_Prescriptions_V1_ResolveMedicationsResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ResolveMedications",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "ResolveMedications", detail: input.context.traceID
        )
        let outbound0 = Acme_Sponsorships_V1_CloneSponsorRequest.with {
            $0.context = input.context
            $0.sponsor = Acme_Sponsorships_V1_Sponsor.with {
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.context.actor.userID
                }
            }
        }
        guard let execute0 = self.resolveMedicationsStep0[settings.region] ?? self.resolveMedicationsStep0["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply0 = try await execute0(outbound0)
        let outbound1 = Acme_Prescriptions_V1_FindPrescriptionsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Prescriptions_V1_FindPrescriptionsRequest.Filter.with {
                $0.createdAfter = reply0.sponsor.audit.updatedAt
                $0.labels = reply0.sponsor.attributes
                $0.ownerID = reply0.sponsor.relationshipManager.userID
                $0.region = reply0.sponsor.primaryAddress.region
            }
        }
        let reply1 = try await self.prescriptionsPrescriptionQuery.findPrescriptions(outbound1)
        return Acme_Prescriptions_V1_ResolveMedicationsResponse.with {
            $0.medications = [
                Acme_Prescriptions_V1_Medication.with {
                    $0.audit = Acme_Common_V1_AuditInfo.with {
                        $0.createdBy = reply0.sponsor.audit.createdBy
                    }
                }
            ]
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply1.result.message
                $0.status = Projection.firstValue(
                    [
                        reply0.result.status,
                        reply1.result.status,
                    ], default: .init())
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processSuggestMedications(_ input: Acme_Prescriptions_V1_SuggestMedicationsRequest) async throws
        -> Acme_Prescriptions_V1_SuggestMedicationsResponse
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
            "SuggestMedications",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "SuggestMedications", detail: input.context.traceID
        )
        return Acme_Prescriptions_V1_SuggestMedicationsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processSummarizeMedications(_ input: Acme_Prescriptions_V1_SummarizeMedicationsRequest) async throws
        -> Acme_Prescriptions_V1_SummarizeMedicationsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.cron)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "audit", detail: input.details.cron
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SummarizeMedications",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "SummarizeMedications", detail: input.context.traceID
        )
        let outbound0 = Acme_Seating_V1_CloneSeatMapRequest.with {
            $0.context = input.context
            $0.seatMap = Acme_Seating_V1_SeatMap.with {
                $0.children = [
                    Acme_Seating_V1_SeatMap.with {
                        $0.children = [
                            Acme_Seating_V1_SeatMap.with {
                                $0.manager = Acme_Identity_V1_UserRef.with {
                                    $0.email = input.context.actor.email
                                }
                            }
                        ]
                    }
                ]
            }
        }
        let envelope0 = try Google_Protobuf_Any(message: outbound0)
        let unpacked0 = try Acme_Seating_V1_CloneSeatMapRequest(unpackingAny: envelope0)
        let reply0 = try await self.seatingSeatMap.cloneSeatMap(unpacked0)
        let outbound1 = Acme_Metrics_V1_UpdateMetricSeriesRequest.with {
            $0.context = input.context
            $0.metricSeries = Acme_Metrics_V1_MetricSeries.with {
                $0.address = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = reply0.seatMap.location.postalCode
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply0.seatMap.audit.createdBy
                    $0.updatedAt = reply0.seatMap.audit.updatedAt
                }
            }
        }
        let json1 = try outbound1.jsonString()
        let decoded1 = try Acme_Metrics_V1_UpdateMetricSeriesRequest(jsonString: json1)
        let reply1 = try await self.metricsMetricSeries.updateMetricSeries(decoded1)
        let outbound2 = Acme_Featureflags_V1_CountFeatureFlagsRequest.forMedicationQueryEndpointSummarizeMedications2(
            input,
            reply0: reply0,
            reply1: reply1
        )
        let reply2 = try await self.featureflagsFeatureFlagQuery.countFeatureFlags(outbound2)
        let selection3_2: String
        switch reply1.metricSeries.locator {
        case .address(let address):
            selection3_2 = address.recipient
        default: selection3_2 = .init()
        }
        let outbound3 = Acme_Telehealth_V1_ScoreVisitNoteRequest.with {
            $0.context = input.context
            $0.details = Acme_Telehealth_V1_ScoreVisitNoteRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.locality = reply0.seatMap.location.locality
                }
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.recipient = selection3_2
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.email = reply1.metricSeries.owner.email
                }
            }
        }
        let reply3 = try await self.telehealthVisitNoteValidation.scoreVisitNote(outbound3)
        return Acme_Prescriptions_V1_SummarizeMedicationsResponse.with {
            $0.period = input.details.period
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.details = reply3.result.details
                $0.message = reply2.result.message
                $0.referenceIds = reply0.result.referenceIds + reply2.result.referenceIds
                $0.status = "ok"
            }
        }
    }
}
