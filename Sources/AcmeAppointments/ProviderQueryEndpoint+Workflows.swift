import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension ProviderQueryEndpoint {
    /// Execute the appointments workflow and project its upstream replies.
    func processBrowseProviders(_ input: Acme_Appointments_V1_BrowseProvidersRequest) async throws
        -> Acme_Appointments_V1_BrowseProvidersResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "provider",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "BrowseProviders",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "provider",
            action: "BrowseProviders", detail: input.context.traceID
        )
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        try followUps.submit(
            Acme_Identity_V1_GetUserRequest.with {
                $0.context = input.context
                $0.userID = input.context.actor.userID
            })
        let importFrame = Acme_Prescriptions_V1_BatchCreatePrescriptionsRequest.with {
            $0.context = input.context
        }
        _ = try await self.prescriptionsPrescription.batchCreatePrescriptions { writer in
            try await writer.write(importFrame)
        }
        let outbound0 = Acme_Prescriptions_V1_BrowseMedicationsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Prescriptions_V1_BrowseMedicationsRequest.Filter.with {
                $0.createdAfter = input.filter.createdAfter
            }
            $0.page = Acme_Common_V1_PageRequest.with {
                $0.pageToken = input.page.pageToken
            }
        }
        let step0: @Sendable () async throws -> Acme_Prescriptions_V1_BrowseMedicationsResponse = {
            try await self.prescriptionsMedicationQuery.browseMedications(outbound0)
        }
        let reply0 = try await step0()
        var outbound1 = Acme_Appointments_V1_CheckAppointmentEligibilityRequest()
        outbound1.appointment = Acme_Appointments_V1_Appointment.with {
            $0.location = Acme_Common_V1_PostalAddress.with {
                $0.region = input.filter.region
            }
            $0.participants = [
                Acme_Appointments_V1_AppointmentParticipant.with {
                    $0.contact = Acme_Common_V1_ContactInfo.with {
                        $0.email = input.context.actor.email
                    }
                }
            ]
        }
        outbound1.context = input.context
        let reply1 = try await self.appointmentsAppointmentValidation.checkAppointmentEligibility(outbound1)
        return Acme_Appointments_V1_BrowseProvidersResponse.with {
            $0.providers = [
                Acme_Appointments_V1_Provider.with {
                    $0.audit = Acme_Common_V1_AuditInfo.with {
                        $0.updatedBy = reply1.appointment.audit.updatedBy
                    }
                }
            ]
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = Projection.firstValue(
                    [
                        reply0.result.message,
                        reply1.outcome.message,
                    ], default: .init())
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processCountProviders(_ input: Acme_Appointments_V1_CountProvidersRequest) async throws
        -> Acme_Appointments_V1_CountProvidersResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "provider",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "CountProviders",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "provider",
            action: "CountProviders", detail: input.context.traceID
        )
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        return Acme_Appointments_V1_CountProvidersResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processExportProviders(_ input: Acme_Appointments_V1_ExportProvidersRequest) async throws
        -> Acme_Appointments_V1_ExportProvidersResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.destinationUri)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "provider",
            action: "audit", detail: input.destinationUri
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ExportProviders",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "provider",
            action: "ExportProviders", detail: input.context.traceID
        )
        let outbound0 = Acme_Telehealth_V1_ScoreTriageRequest.with {
            $0.context = input.context
            $0.details = Acme_Telehealth_V1_ScoreTriageRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
            }
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.context.actor.userID
                }
            }
        }
        let step0: @Sendable () async throws -> Acme_Telehealth_V1_ScoreTriageResponse = {
            try await self.telehealthTriageValidation.scoreTriage(outbound0)
        }
        let reply0 = try await step0()
        let outbound1 = Acme_Appointments_V1_SuggestAppointmentsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Appointments_V1_SuggestAppointmentsRequest.Filter.with {
                $0.region = input.filter.region
            }
        }
        let reply1 = try await self.appointmentsAppointmentQuery.suggestAppointments(outbound1)
        return Acme_Appointments_V1_ExportProvidersResponse.with {
            $0.provider = Acme_Appointments_V1_Provider.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.preferredChannel = reply0.triage.requester.preferredChannel
                }
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.referenceIds = reply1.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processFindProviders(_ input: Acme_Appointments_V1_FindProvidersRequest) async throws
        -> Acme_Appointments_V1_FindProvidersResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "provider",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "FindProviders",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "provider",
            action: "FindProviders", detail: input.context.traceID
        )
        let outbound0 = Acme_Identity_V1_ScoreUserRequest.with {
            $0.context = input.context
            $0.user = Acme_Identity_V1_User.with {
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.email = input.context.actor.email
                }
            }
            $0.userID = input.context.actor.userID
        }
        async let remote0 = self.identityUserValidation.scoreUser(outbound0)
        async let persisted0 = store.count(tenant: input.context.tenantID)
        let (reply0, count0) = try await (remote0, persisted0)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count0)])
        return Acme_Appointments_V1_FindProvidersResponse.with {
            $0.providers = [
                Acme_Appointments_V1_Provider.with {
                    $0.preferences = Acme_Appointments_V1_ProviderPreferences.with {
                        $0.language = reply0.user.preferences.language
                    }
                    $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                        $0.userID = reply0.user.userID
                    }
                }
            ]
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processLookupProvider(_ input: Acme_Appointments_V1_LookupProviderRequest) async throws
        -> Acme_Appointments_V1_LookupProviderResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "LookupProvider",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "provider",
            action: "LookupProvider", detail: input.context.traceID
        )
        let outbound0 = Acme_Prescriptions_V1_ExplainRefillCalculationRequest.with {
            $0.context = input.context
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.context.actor.userID
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.context.actor.email
                }
            }
        }
        let reply0 = try await self.lookupProviderStep0.execute(outbound0)
        return Acme_Appointments_V1_LookupProviderResponse.with {
            $0.provider = Acme_Appointments_V1_Provider.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.preferredChannel = reply0.refill.requester.preferredChannel
                }
                $0.providerID = input.providerID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processPeekProvider(_ input: Acme_Appointments_V1_PeekProviderRequest) async throws
        -> Acme_Appointments_V1_PeekProviderResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "PeekProvider",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "provider",
            action: "PeekProvider", detail: input.context.traceID
        )
        let outbound0 = Acme_Appointments_V1_PreviewProviderRequest.with {
            $0.context = input.context
            $0.provider = Acme_Appointments_V1_Provider.with {
                $0.providerID = input.providerID
            }
        }
        let port0 = RPCOperations.port { (request: Acme_Appointments_V1_PreviewProviderRequest) in
            try await self.appointmentsProviderValidation.previewProvider(request)
        }
        let reply0 = try await port0.execute(outbound0)
        let outbound1 = Acme_Careplans_V1_BrowseCareGoalsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Careplans_V1_BrowseCareGoalsRequest.Filter.with {
                $0.region = reply0.provider.primaryAddress.region
            }
        }
        let reply1 = try await self.peekProviderStep1(outbound1)
        return Acme_Appointments_V1_PeekProviderResponse.with {
            $0.provider = Acme_Appointments_V1_Provider.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply0.provider.contact.email
                }
                $0.providerID = input.providerID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = Projection.firstValue(
                    [
                        reply0.result.status,
                        reply1.result.status,
                    ], default: .init())
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processResolveProviders(_ input: Acme_Appointments_V1_ResolveProvidersRequest) async throws
        -> Acme_Appointments_V1_ResolveProvidersResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ResolveProviders",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "provider",
            action: "ResolveProviders", detail: input.context.traceID
        )
        let outbound0 = Acme_Search_V1_ScoreSearchIndexRequest.with {
            $0.context = input.context
            $0.searchIndex = Acme_Search_V1_SearchIndex.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.context.deadline
                }
                $0.components = [
                    "primary": Acme_Search_V1_SearchIndexComponent.with {
                        $0.componentID = input.context.traceID
                    }
                ]
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.email = input.context.actor.email
                    $0.userID = input.context.actor.userID
                }
            }
        }
        guard let execute0 = self.resolveProvidersStep0[settings.region] ?? self.resolveProvidersStep0["primary"] else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply0 = try await execute0(outbound0)
        let selection1_2: String
        switch reply0.searchIndex.locator {
        case .address(let address):
            selection1_2 = address.locality
        default: selection1_2 = .init()
        }
        let outbound1 = Acme_Appointments_V1_LintProvidersRequest.with {
            $0.context = input.context
            $0.provider = Acme_Appointments_V1_Provider.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply0.searchIndex.audit.etag
                }
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.locality = selection1_2
                }
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply0.searchIndex.owner.displayName
                }
            }
        }
        let reply1 = try await self.appointmentsProviderValidation.lintProviders(outbound1)
        return Acme_Appointments_V1_ResolveProvidersResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.message = reply1.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the appointments workflow and project its upstream replies.
    func processSuggestProviders(_ input: Acme_Appointments_V1_SuggestProvidersRequest) async throws
        -> Acme_Appointments_V1_SuggestProvidersResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "provider",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SuggestProviders",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "provider",
            action: "SuggestProviders", detail: input.context.traceID
        )
        let outbound0 = Acme_Appointments_V1_SimulateClinicSlotRequest.with {
            $0.clinicSlot = Acme_Appointments_V1_ClinicSlot.with {
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.email = input.context.actor.email
                }
            }
            $0.context = input.context
        }
        let reply0 = try await self.appointmentsClinicSlotCalculation.simulateClinicSlot(outbound0)
        return Acme_Appointments_V1_SuggestProvidersResponse.with {
            $0.providers = [
                Acme_Appointments_V1_Provider.with {
                    $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                        $0.countryCode = reply0.clinicSlot.location.countryCode
                    }
                }
            ]
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }
}
