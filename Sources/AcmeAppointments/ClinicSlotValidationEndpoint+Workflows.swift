import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension ClinicSlotValidationEndpoint {
    /// Execute the appointments workflow and project its upstream replies.
    func processCheckClinicSlotEligibility(_ input: Acme_Appointments_V1_CheckClinicSlotEligibilityRequest) async throws
        -> Acme_Appointments_V1_CheckClinicSlotEligibilityResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.clinicSlot.audit.createdBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "clinic_slot",
            action: "audit", detail: input.clinicSlot.audit.createdBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "CheckClinicSlotEligibility",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try ClinicSlotRecord(input.clinicSlot, tenant: input.context.tenantID)
        try await store.save(record.stored)
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        let importFrame = Acme_Prescriptions_V1_BatchCreatePrescriptionsRequest.with {
            $0.context = input.context
        }
        _ = try await self.prescriptionsPrescription.batchCreatePrescriptions { writer in
            try await writer.write(importFrame)
        }
        let outbound0 = Acme_Identity_V1_FindUsersRequest.with {
            $0.context = input.context
            $0.filter = Acme_Identity_V1_FindUsersRequest.Filter.with {
                $0.createdAfter = input.clinicSlot.audit.createdAt
                $0.labels = input.clinicSlot.metadata
                $0.region = input.clinicSlot.location.region
            }
        }
        let reply0 = try await self.identityUserQuery.findUsers(
            outbound0, metadata: ["x-acme-region": .string(settings.region)]
        )
        let outbound1 = Acme_Shows_V1_EstimateShowRequest.with {
            $0.context = input.context
            $0.show = Acme_Shows_V1_Show.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.clinicSlot.audit.createdAt
                    $0.updatedBy = input.clinicSlot.audit.updatedBy
                }
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.clinicSlot.organizer.displayName
                }
            }
        }
        let reply1 = try await RPCOperations.call(outbound1) { request in
            try await self.showsShowCalculation.estimateShow(request)
        }
        return Acme_Appointments_V1_CheckClinicSlotEligibilityResponse.with {
            $0.clinicSlot = Acme_Appointments_V1_ClinicSlot.with {
                $0.clinicSlotID = input.clinicSlotID
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.locality = reply1.show.location.locality
                }
                $0.metadata = reply1.show.metadata
                $0.window = input.clinicSlot.window
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processExplainClinicSlotDecision(_ input: Acme_Appointments_V1_ExplainClinicSlotDecisionRequest) async throws
        -> Acme_Appointments_V1_ExplainClinicSlotDecisionResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.clinicSlot.audit.createdBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "clinic_slot",
            action: "audit", detail: input.clinicSlot.audit.createdBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ExplainClinicSlotDecision",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try ClinicSlotRecord(input.clinicSlot, tenant: input.context.tenantID)
        try await store.save(record.stored)
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        let outbound0 = Acme_Ledger_V1_CountLedgerAccountsRequest.with {
            $0.context = Projection.read(input, at: \Acme_Appointments_V1_ExplainClinicSlotDecisionRequest.context)
            $0.filter = Acme_Ledger_V1_CountLedgerAccountsRequest.Filter.with {
                $0.region = Projection.read(
                    input, at: \Acme_Appointments_V1_ExplainClinicSlotDecisionRequest.clinicSlot.location.region)
            }
        }
        let reply0 = try await self.ledgerLedgerAccountQuery.countLedgerAccounts(outbound0)
        let outbound1 = Acme_Appointments_V1_ScoreProviderRequest.with {
            $0.context = input.context
            $0.provider = Acme_Appointments_V1_Provider.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.clinicSlot.audit.createdAt
                }
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.name = input.details.contact.name
                }
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = input.clinicSlot.location.countryCode
                    $0.lines = input.clinicSlot.location.lines
                }
            }
        }
        let step1: @Sendable () async throws -> Acme_Appointments_V1_ScoreProviderResponse = {
            try await self.appointmentsProviderValidation.scoreProvider(outbound1)
        }
        let reply1 = try await step1()
        var outbound2 = Acme_Appointments_V1_LintProvidersRequest()
        outbound2.context = input.context
        outbound2.provider = Acme_Appointments_V1_Provider.with {
            $0.preferences = Acme_Appointments_V1_ProviderPreferences.with {
                $0.quietHours = reply1.provider.preferences.quietHours
            }
        }
        let reply2 = try await self.appointmentsProviderValidation.lintProviders(outbound2)
        let outbound3 = Acme_Appointments_V1_ExplainProviderDecisionRequest.with {
            $0.context = input.context
            $0.provider = Acme_Appointments_V1_Provider.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply2.provider.audit.etag
                }
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.phone = reply1.provider.contact.phone
                }
                $0.preferences = Acme_Appointments_V1_ProviderPreferences.with {
                    $0.quietHours = reply2.provider.preferences.quietHours
                }
            }
        }
        let step3: @Sendable () async throws -> Acme_Appointments_V1_ExplainProviderDecisionResponse = {
            try await self.appointmentsProviderValidation.explainProviderDecision(outbound3)
        }
        let reply3 = try await step3()
        return Acme_Appointments_V1_ExplainClinicSlotDecisionResponse.with {
            $0.clinicSlot = Acme_Appointments_V1_ClinicSlot.with {
                $0.clinicSlotID = input.clinicSlotID
                $0.participants = [
                    Acme_Appointments_V1_ClinicSlotParticipant.with {
                        $0.contact = reply2.provider.contact
                    }
                ]
                $0.title = input.clinicSlot.title
            }
            $0.outcome = Acme_Appointments_V1_ExplainClinicSlotDecisionResponse.Outcome.with {
                $0.message = Projection.firstValue(
                    [
                        reply0.result.message,
                        reply2.result.message,
                    ], default: .init())
                $0.nextSteps = reply3.outcome.nextSteps
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply3.result.details
                $0.message = reply1.result.message
                $0.referenceIds = reply1.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processLintClinicSlots(_ input: Acme_Appointments_V1_LintClinicSlotsRequest) async throws
        -> Acme_Appointments_V1_LintClinicSlotsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.clinicSlot.audit.createdBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "clinic_slot",
            action: "audit", detail: input.clinicSlot.audit.createdBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "LintClinicSlots",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try ClinicSlotRecord(input.clinicSlot, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Appointments_V1_LintProvidersRequest.with {
            $0.context = input.context
            $0.provider = Acme_Appointments_V1_Provider.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.preferredChannel = input.details.contact.preferredChannel
                }
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = input.clinicSlot.location.postalCode
                }
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.clinicSlot.organizer.displayName
                }
            }
        }
        let reply0 = try await self.appointmentsProviderValidation.lintProviders(outbound0)
        let outbound1 = Acme_Appointments_V1_ValidateProviderRequest.with {
            $0.context = input.context
            $0.provider = Acme_Appointments_V1_Provider.with {
                $0.preferences = Acme_Appointments_V1_ProviderPreferences.with {
                    $0.marketingOptIn = reply0.provider.preferences.marketingOptIn
                }
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.email = input.clinicSlot.organizer.email
                    $0.userID = input.clinicSlot.organizer.userID
                }
            }
        }
        async let remote1 = self.appointmentsProviderValidation.validateProvider(outbound1)
        async let persisted1 = store.count(tenant: input.context.tenantID)
        let (reply1, count1) = try await (remote1, persisted1)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count1)])
        return Acme_Appointments_V1_LintClinicSlotsResponse.with {
            $0.clinicSlot = Acme_Appointments_V1_ClinicSlot.with {
                $0.clinicSlotID = input.clinicSlotID
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = reply1.provider.primaryAddress.postalCode
                }
                $0.organizer = input.clinicSlot.organizer
            }
            $0.outcome = Acme_Appointments_V1_LintClinicSlotsResponse.Outcome.with {
                $0.referenceID = reply1.outcome.referenceID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processNormalizeClinicSlot(_ input: Acme_Appointments_V1_NormalizeClinicSlotRequest) async throws
        -> Acme_Appointments_V1_NormalizeClinicSlotResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.clinicSlot.audit.etag)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "clinic_slot",
            action: "audit", detail: input.clinicSlot.audit.etag
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "NormalizeClinicSlot",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try ClinicSlotRecord(input.clinicSlot, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Venues_V1_ExplainVenueDecisionRequest.with {
            $0.context = input.context
            $0.venue = Acme_Venues_V1_Venue.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = input.clinicSlot.audit.createdBy
                }
            }
        }
        let reply0 = try await self.normalizeClinicSlotStep0.execute(outbound0)
        return Acme_Appointments_V1_NormalizeClinicSlotResponse.with {
            $0.clinicSlot = Acme_Appointments_V1_ClinicSlot.with {
                $0.clinicSlotID = input.clinicSlotID
                $0.organizer = input.clinicSlot.organizer
            }
            $0.outcome = Acme_Appointments_V1_NormalizeClinicSlotResponse.Outcome.with {
                $0.message = reply0.result.message
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processPreviewClinicSlot(_ input: Acme_Appointments_V1_PreviewClinicSlotRequest) async throws
        -> Acme_Appointments_V1_PreviewClinicSlotResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.clinicSlot.audit.createdBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "clinic_slot",
            action: "audit", detail: input.clinicSlot.audit.createdBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "PreviewClinicSlot",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try ClinicSlotRecord(input.clinicSlot, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let requests0 = input.clinicSlot.participants.map { element in
            Acme_Appointments_V1_ValidateProviderRequest.with {
                $0.context = input.context
                $0.provider = Acme_Appointments_V1_Provider.with {
                    $0.contact = Acme_Common_V1_ContactInfo.with {
                        $0.phone = element.contact.phone
                    }
                }
            }
        }
        let replies0 = try await FanOut.map(requests0) { candidate in
            try await self.appointmentsProviderValidation.validateProvider(candidate)
        }
        let reply0 = replies0.first ?? Acme_Appointments_V1_ValidateProviderResponse()
        let outbound1 = Acme_Appointments_V1_EstimateClinicSlotRequest.with {
            $0.clinicSlot = Acme_Appointments_V1_ClinicSlot.with {
                $0.participants = [
                    Acme_Appointments_V1_ClinicSlotParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = reply0.provider.relationshipManager.email
                            $0.phone = input.details.contact.phone
                            $0.preferredChannel = input.details.contact.preferredChannel
                        }
                    }
                ]
            }
            $0.context = input.context
        }
        let port1 = RPCOperations.port { (request: Acme_Appointments_V1_EstimateClinicSlotRequest) in
            try await self.appointmentsClinicSlotCalculation.estimateClinicSlot(request)
        }
        let reply1 = try await port1.execute(outbound1)
        return Acme_Appointments_V1_PreviewClinicSlotResponse.with {
            $0.clinicSlot = Acme_Appointments_V1_ClinicSlot.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply1.clinicSlot.audit.createdAt
                }
                $0.clinicSlotID = input.clinicSlotID
                $0.metadata = input.clinicSlot.metadata
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processScoreClinicSlot(_ input: Acme_Appointments_V1_ScoreClinicSlotRequest) async throws
        -> Acme_Appointments_V1_ScoreClinicSlotResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.clinicSlot.audit.createdBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "clinic_slot",
            action: "audit", detail: input.clinicSlot.audit.createdBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ScoreClinicSlot",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try ClinicSlotRecord(input.clinicSlot, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Careplans_V1_QuoteCareGoalRequest.with {
            $0.context = input.context
            $0.details = Acme_Careplans_V1_QuoteCareGoalRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.clinicSlot.location.region
                }
            }
        }
        let reply0 = try await self.scoreClinicSlotStep0(outbound0)
        let outbound1 = Acme_Broadcasts_V1_BatchGetBroadcastsRequest.with {
            $0.context = input.context
        }
        guard let execute1 = self.scoreClinicSlotStep1[settings.region] ?? self.scoreClinicSlotStep1["primary"] else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply1 = try await execute1(outbound1)
        let outbound2 = Acme_Appointments_V1_ScoreProviderRequest.with {
            $0.context = input.context
            $0.provider = Acme_Appointments_V1_Provider.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply0.careGoal.assignee.email
                }
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = input.details.destination.countryCode
                    $0.recipient = input.clinicSlot.location.recipient
                }
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.clinicSlot.organizer.userID
                }
            }
        }
        let reply2 = try await self.appointmentsProviderValidation.scoreProvider(outbound2)
        let outbound3 = Acme_Broadcasts_V1_SearchBroadcastsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Broadcasts_V1_SearchBroadcastsRequest.Filter.with {
                $0.region = reply2.provider.primaryAddress.region
            }
        }
        let envelope3 = try Google_Protobuf_Any(message: outbound3)
        let unpacked3 = try Acme_Broadcasts_V1_SearchBroadcastsRequest(unpackingAny: envelope3)
        let reply3 = try await self.broadcastsBroadcast.searchBroadcasts(unpacked3)
        return Acme_Appointments_V1_ScoreClinicSlotResponse.with {
            $0.clinicSlot = Acme_Appointments_V1_ClinicSlot.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply2.provider.audit.createdBy
                }
                $0.clinicSlotID = input.clinicSlotID
                $0.metadata = input.clinicSlot.metadata
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply0.careGoal.assignee.displayName
                }
                $0.participants = [
                    Acme_Appointments_V1_ClinicSlotParticipant.with {
                        $0.contact = Projection.updating(reply2.provider.contact) {
                            $0.preferredChannel = reply0.careGoal.requester.preferredChannel
                        }
                    }
                ]
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply3.result.correlationID
                $0.status = Projection.firstValue(
                    [
                        reply1.result.status,
                        reply3.result.status,
                    ], default: .init())
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processValidateClinicSlot(_ input: Acme_Appointments_V1_ValidateClinicSlotRequest) async throws
        -> Acme_Appointments_V1_ValidateClinicSlotResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.clinicSlot.audit.etag)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "clinic_slot",
            action: "audit", detail: input.clinicSlot.audit.etag
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ValidateClinicSlot",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try ClinicSlotRecord(input.clinicSlot, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Careplans_V1_SimulateCareGoalRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = input.clinicSlot.audit.createdBy
                    $0.updatedAt = input.clinicSlot.audit.updatedAt
                }
            }
            $0.context = input.context
            $0.details = Acme_Careplans_V1_SimulateCareGoalRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.locality = input.clinicSlot.location.locality
                }
            }
        }
        let json0 = try outbound0.jsonString()
        let decoded0 = try Acme_Careplans_V1_SimulateCareGoalRequest(jsonString: json0)
        let reply0 = try await self.careplansCareGoalCalculation.simulateCareGoal(decoded0)
        let outbound1 =
            Acme_Appointments_V1_ExplainProviderDecisionRequest.forClinicSlotValidationEndpointValidateClinicSlot1(
                input,
                reply0: reply0
            )
        let reply1 = try await self.appointmentsProviderValidation.explainProviderDecision(outbound1)
        return Acme_Appointments_V1_ValidateClinicSlotResponse.with {
            $0.clinicSlot = Acme_Appointments_V1_ClinicSlot.with {
                $0.clinicSlotID = input.clinicSlotID
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.lines = reply1.provider.primaryAddress.lines
                    $0.locality = reply1.provider.primaryAddress.locality
                }
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.email = reply0.careGoal.customer.email
                }
                $0.participants = [
                    Acme_Appointments_V1_ClinicSlotParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = reply0.careGoal.requester.email
                        }
                    }
                ]
                $0.title = input.clinicSlot.title
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }
}
