import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension ProviderValidationEndpoint {
    /// Explains a provider.
    func explainProviderDecision(
        request: ServerRequest<Acme_Appointments_V1_ExplainProviderDecisionRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_ExplainProviderDecisionResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processExplainProviderDecision(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a provider.
    func getProviderRules(
        request: ServerRequest<Acme_Appointments_V1_GetProviderRulesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_GetProviderRulesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetProviderRules(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lints a provider.
    func lintProviders(
        request: ServerRequest<Acme_Appointments_V1_LintProvidersRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_LintProvidersResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processLintProviders(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Previews a provider.
    func previewProvider(
        request: ServerRequest<Acme_Appointments_V1_PreviewProviderRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_PreviewProviderResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processPreviewProvider(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Scores a provider.
    func scoreProvider(
        request: ServerRequest<Acme_Appointments_V1_ScoreProviderRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_ScoreProviderResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processScoreProvider(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Validates a provider.
    func validateProvider(
        request: ServerRequest<Acme_Appointments_V1_ValidateProviderRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_ValidateProviderResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processValidateProvider(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processExplainProviderDecision(_ input: Acme_Appointments_V1_ExplainProviderDecisionRequest) async throws
        -> Acme_Appointments_V1_ExplainProviderDecisionResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "provider",
            action: "audit", detail: input.details.contact.email
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ExplainProviderDecision",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try ProviderRecord(input.provider, tenant: input.context.tenantID)
        try await store.save(record.stored)
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        let importFrame = Acme_Telehealth_V1_BatchCreateVideoVisitsRequest.with {
            $0.context = input.context
        }
        _ = try await self.telehealthVideoVisit.batchCreateVideoVisits { writer in
            try await writer.write(importFrame)
        }
        let outbound0 = Acme_Prescriptions_V1_EstimatePrescriptionRequest.with {
            $0.context = input.context
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.lines = input.provider.primaryAddress.lines
                    $0.postalCode = input.provider.primaryAddress.postalCode
                }
            }
        }
        let envelope0 = try Google_Protobuf_Any(message: outbound0)
        let unpacked0 = try Acme_Prescriptions_V1_EstimatePrescriptionRequest(unpackingAny: envelope0)
        let reply0 = try await self.prescriptionsPrescriptionCalculation.estimatePrescription(unpacked0)
        return Acme_Appointments_V1_ExplainProviderDecisionResponse.with {
            $0.provider = Acme_Appointments_V1_Provider.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.name = input.provider.name
                }
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.lines = reply0.prescription.billingAddress.lines
                }
                $0.providerID = input.providerID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processGetProviderRules(_ input: Acme_Appointments_V1_GetProviderRulesRequest) async throws
        -> Acme_Appointments_V1_GetProviderRulesResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "GetProviderRules",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "provider",
            action: "GetProviderRules", detail: input.context.traceID
        )
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        let outbound0 = Acme_Appointments_V1_ExplainAppointmentDecisionRequest.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.context.actor.userID
                }
                $0.participants = [
                    Acme_Appointments_V1_AppointmentParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = input.context.actor.email
                        }
                    }
                ]
            }
            $0.context = input.context
            $0.details = Acme_Appointments_V1_ExplainAppointmentDecisionRequest.Details.with {
                $0.locale = input.context.locale
            }
        }
        let json0 = try outbound0.jsonString()
        let decoded0 = try Acme_Appointments_V1_ExplainAppointmentDecisionRequest(jsonString: json0)
        let reply0 = try await self.appointmentsAppointmentValidation.explainAppointmentDecision(decoded0)
        let selection1_2: Int32
        switch reply0.appointment.recurrence {
        case .daily(let daily):
            selection1_2 = daily.interval
        default: selection1_2 = .init()
        }
        let outbound1 = Acme_Appointments_V1_ScoreAppointmentRequest.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.daily = Acme_Appointments_V1_AppointmentDailyRule.with {
                    $0.interval = selection1_2
                }
                $0.participants = [
                    Acme_Appointments_V1_AppointmentParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = reply0.appointment.organizer.email
                        }
                    }
                ]
            }
            $0.context = input.context
        }
        let reply1 = try await self.appointmentsAppointmentValidation.scoreAppointment(outbound1)
        return Acme_Appointments_V1_GetProviderRulesResponse.with {
            $0.provider = Acme_Appointments_V1_Provider.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply1.appointment.audit.updatedAt
                }
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = Projection.firstValue(
                        [
                            reply0.appointment.organizer.email,
                            reply1.appointment.organizer.email,
                        ], default: .init())
                }
                $0.providerID = input.providerID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processLintProviders(_ input: Acme_Appointments_V1_LintProvidersRequest) async throws
        -> Acme_Appointments_V1_LintProvidersResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "provider",
            action: "audit", detail: input.details.contact.email
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "LintProviders",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try ProviderRecord(input.provider, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Telehealth_V1_ScoreVideoVisitRequest.forProviderValidationEndpointLintProviders0(
            input
        )
        let reply0 = try await self.telehealthVideoVisitValidation.scoreVideoVisit(outbound0)
        let outbound1 = Acme_Documents_V1_FindDocumentsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Documents_V1_FindDocumentsRequest.Filter.with {
                $0.region = reply0.videoVisit.location.region
            }
        }
        let reply1 = try await self.documentsDocumentQuery.findDocuments(
            outbound1, metadata: ["x-acme-region": .string(settings.region)]
        )
        return Acme_Appointments_V1_LintProvidersResponse.with {
            $0.provider = Acme_Appointments_V1_Provider.with {
                $0.attributes = input.provider.attributes
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = reply0.videoVisit.location.postalCode
                }
                $0.providerID = input.providerID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.message = reply1.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processPreviewProvider(_ input: Acme_Appointments_V1_PreviewProviderRequest) async throws
        -> Acme_Appointments_V1_PreviewProviderResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.phone)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "provider",
            action: "audit", detail: input.details.contact.phone
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "PreviewProvider",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try ProviderRecord(input.provider, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Documents_V1_BrowseDocumentsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Documents_V1_BrowseDocumentsRequest.Filter.with {
                $0.createdAfter = input.provider.audit.updatedAt
                $0.labels = input.provider.attributes
                $0.ownerID = input.provider.relationshipManager.userID
                $0.region = input.provider.primaryAddress.region
            }
        }
        let reply0 = try await RPCOperations.call(outbound0) { request in
            try await self.documentsDocumentQuery.browseDocuments(request)
        }
        let outbound1 = Acme_Appointments_V1_NormalizeAppointmentRequest.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = Projection.read(
                        input, at: \Acme_Appointments_V1_PreviewProviderRequest.provider.audit.updatedBy)
                }
                $0.participants = [
                    Acme_Appointments_V1_AppointmentParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = Projection.read(
                                input, at: \Acme_Appointments_V1_PreviewProviderRequest.details.contact.email)
                            $0.phone = Projection.read(
                                input, at: \Acme_Appointments_V1_PreviewProviderRequest.provider.contact.phone)
                        }
                    }
                ]
            }
            $0.context = Projection.read(input, at: \Acme_Appointments_V1_PreviewProviderRequest.context)
        }
        let reply1 = try await self.appointmentsAppointmentValidation.normalizeAppointment(outbound1)
        return Acme_Appointments_V1_PreviewProviderResponse.with {
            $0.provider = Acme_Appointments_V1_Provider.with {
                $0.contact = input.provider.contact
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.lines = reply1.appointment.location.lines
                }
                $0.providerID = input.providerID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processScoreProvider(_ input: Acme_Appointments_V1_ScoreProviderRequest) async throws
        -> Acme_Appointments_V1_ScoreProviderResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.currencyCode)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "provider",
            action: "audit", detail: input.details.currencyCode
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ScoreProvider",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try ProviderRecord(input.provider, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Careplans_V1_RecalculateCareGoalsRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = input.provider.audit.etag
                }
            }
            $0.context = input.context
        }
        let step0: @Sendable () async throws -> Acme_Careplans_V1_RecalculateCareGoalsResponse = {
            try await self.careplansCareGoalCalculation.recalculateCareGoals(outbound0)
        }
        let reply0 = try await step0()
        var outbound1 = Acme_Telehealth_V1_QuoteVideoVisitRequest()
        outbound1.context = input.context
        outbound1.details = Acme_Telehealth_V1_QuoteVideoVisitRequest.Details.with {
            $0.destination = Acme_Common_V1_PostalAddress.with {
                $0.postalCode = input.details.destination.postalCode
            }
        }
        outbound1.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
            $0.audit = Acme_Common_V1_AuditInfo.with {
                $0.etag = reply0.careGoal.audit.etag
            }
            $0.participants = [
                Acme_Telehealth_V1_VideoVisitParticipant.with {
                    $0.contact = Acme_Common_V1_ContactInfo.with {
                        $0.name = reply0.careGoal.requester.name
                    }
                }
            ]
        }
        let reply1 = try await self.telehealthVideoVisitCalculation.quoteVideoVisit(outbound1)
        return Acme_Appointments_V1_ScoreProviderResponse.with {
            $0.provider = Acme_Appointments_V1_Provider.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.name = reply0.careGoal.requester.name
                }
                $0.name = input.provider.name
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = reply1.videoVisit.location.region
                }
                $0.providerID = input.providerID
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply0.careGoal.customer.displayName
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply1.result.status
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processValidateProvider(_ input: Acme_Appointments_V1_ValidateProviderRequest) async throws
        -> Acme_Appointments_V1_ValidateProviderResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "provider",
            action: "audit", detail: input.details.contact.email
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ValidateProvider",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try ProviderRecord(input.provider, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Search_V1_SearchSearchIndexesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Search_V1_SearchSearchIndexesRequest.Filter.with {
                $0.createdAfter = input.provider.audit.updatedAt
                $0.region = input.provider.primaryAddress.region
            }
        }
        let reply0 = try await RPCOperations.read {
            try await self.searchSearchIndex.searchSearchIndexes(outbound0)
        }
        return Acme_Appointments_V1_ValidateProviderResponse.with {
            $0.provider = Acme_Appointments_V1_Provider.with {
                $0.attributes = input.provider.attributes
                $0.providerID = input.providerID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply0.result.status
            }
        }
    }
}
