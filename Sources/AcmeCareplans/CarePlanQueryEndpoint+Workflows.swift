import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension CarePlanQueryEndpoint {
    /// Execute the careplans workflow and project its upstream replies.
    func processBrowseCarePlans(_ input: Acme_Careplans_V1_BrowseCarePlansRequest) async throws
        -> Acme_Careplans_V1_BrowseCarePlansResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "BrowseCarePlans",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "BrowseCarePlans", detail: input.context.traceID
        )
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        try followUps.submit(
            Acme_Identity_V1_GetUserRequest.with {
                $0.context = input.context
                $0.userID = input.context.actor.userID
            })
        let outbound0 = Acme_Careplans_V1_CheckCarePlanEligibilityRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
            }
            $0.context = input.context
            $0.details = Acme_Careplans_V1_CheckCarePlanEligibilityRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.context.actor.email
                }
            }
        }
        let reply0 = try await self.browseCarePlansStep0.execute(outbound0)
        return Acme_Careplans_V1_BrowseCarePlansResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply0.outcome.status
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processCountCarePlans(_ input: Acme_Careplans_V1_CountCarePlansRequest) async throws
        -> Acme_Careplans_V1_CountCarePlansResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "CountCarePlans",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "CountCarePlans", detail: input.context.traceID
        )
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        let outbound0 = Acme_Notifications_V1_CloneNotificationRequest.with {
            $0.context = input.context
            $0.notification = Acme_Notifications_V1_Notification.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.email = input.context.actor.email
                    $0.userID = input.context.actor.userID
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = input.filter.createdAfter
                }
                $0.customFields = input.filter.labels
            }
        }
        let port0 = RPCOperations.port { (request: Acme_Notifications_V1_CloneNotificationRequest) in
            try await self.notificationsNotification.cloneNotification(request)
        }
        let reply0 = try await port0.execute(outbound0)
        return Acme_Careplans_V1_CountCarePlansResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processExportCarePlans(_ input: Acme_Careplans_V1_ExportCarePlansRequest) async throws
        -> Acme_Careplans_V1_ExportCarePlansResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.destinationUri)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "audit", detail: input.destinationUri
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ExportCarePlans",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "ExportCarePlans", detail: input.context.traceID
        )
        let outbound0 = Acme_Careplans_V1_RecalculateCareGoalsRequest.with {
            $0.context = input.context
            $0.details = Acme_Careplans_V1_RecalculateCareGoalsRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
            }
        }
        let reply0 = try await self.exportCarePlansStep0(outbound0)
        let outbound1 = Acme_Careplans_V1_ExplainCareGoalCalculationRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.customer = Acme_Patients_V1_PatientRef.with {
                    $0.email = reply0.careGoal.requester.email
                }
            }
            $0.context = input.context
        }
        guard let execute1 = self.exportCarePlansStep1[settings.region] ?? self.exportCarePlansStep1["primary"] else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply1 = try await execute1(outbound1)
        return Acme_Careplans_V1_ExportCarePlansResponse.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply1.careGoal.audit.updatedAt
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
                $0.counterparty = Acme_Appointments_V1_AppointmentRef.with {
                    $0.displayName = reply1.careGoal.assignee.displayName
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.result.message
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processFindCarePlans(_ input: Acme_Careplans_V1_FindCarePlansRequest) async throws
        -> Acme_Careplans_V1_FindCarePlansResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "FindCarePlans",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "FindCarePlans", detail: input.context.traceID
        )
        let outbound0 = Acme_Identity_V1_NormalizeUserRequest.with {
            $0.context = input.context
            $0.user = Acme_Identity_V1_User.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.context.actor.email
                }
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
            }
        }
        let reply0 = try await self.identityUserValidation.normalizeUser(outbound0)
        return Acme_Careplans_V1_FindCarePlansResponse.with {
            $0.carePlans = [
                Acme_Careplans_V1_CarePlan.with {
                    $0.audit = Acme_Common_V1_AuditInfo.with {
                        $0.etag = reply0.user.audit.etag
                    }
                }
            ]
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processLookupCarePlan(_ input: Acme_Careplans_V1_LookupCarePlanRequest) async throws
        -> Acme_Careplans_V1_LookupCarePlanResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "LookupCarePlan",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "LookupCarePlan", detail: input.context.traceID
        )
        return Acme_Careplans_V1_LookupCarePlanResponse.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.carePlanID = input.carePlanID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processPeekCarePlan(_ input: Acme_Careplans_V1_PeekCarePlanRequest) async throws
        -> Acme_Careplans_V1_PeekCarePlanResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "PeekCarePlan",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "PeekCarePlan", detail: input.context.traceID
        )
        let outbound0 = Acme_Careplans_V1_NormalizeCarePlanRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = input.context.deadline
                }
            }
            $0.carePlanID = input.carePlanID
            $0.context = input.context
            $0.details = Acme_Careplans_V1_NormalizeCarePlanRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.context.actor.email
                }
                $0.locale = input.context.locale
            }
        }
        let envelope0 = try Google_Protobuf_Any(message: outbound0)
        let unpacked0 = try Acme_Careplans_V1_NormalizeCarePlanRequest(unpackingAny: envelope0)
        let reply0 = try await self.careplansCarePlanValidation.normalizeCarePlan(unpacked0)
        let outbound1 = Acme_Careplans_V1_RecalculateCareGoalsRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply0.carePlan.audit.createdAt
                }
            }
            $0.context = input.context
            $0.details = Acme_Careplans_V1_RecalculateCareGoalsRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.locality = reply0.carePlan.billingAddress.locality
                    $0.postalCode = reply0.carePlan.billingAddress.postalCode
                    $0.recipient = reply0.carePlan.billingAddress.recipient
                }
            }
        }
        let json1 = try outbound1.jsonString()
        let decoded1 = try Acme_Careplans_V1_RecalculateCareGoalsRequest(jsonString: json1)
        let reply1 = try await self.careplansCareGoalCalculation.recalculateCareGoals(decoded1)
        return Acme_Careplans_V1_PeekCarePlanResponse.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply1.careGoal.audit.updatedBy
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = reply0.carePlan.billingAddress.region
                }
                $0.carePlanID = input.carePlanID
                $0.counterparty = Acme_Appointments_V1_AppointmentRef.with {
                    $0.displayName = reply1.careGoal.customer.displayName
                }
                $0.dueAt = reply0.carePlan.dueAt
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processResolveCarePlans(_ input: Acme_Careplans_V1_ResolveCarePlansRequest) async throws
        -> Acme_Careplans_V1_ResolveCarePlansResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ResolveCarePlans",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "ResolveCarePlans", detail: input.context.traceID
        )
        let outbound0 = Acme_Venues_V1_NormalizeVenueRequest.forCarePlanQueryEndpointResolveCarePlans0(
            input
        )
        let reply0 = try await self.venuesVenueValidation.normalizeVenue(outbound0)
        return Acme_Careplans_V1_ResolveCarePlansResponse.with {
            $0.carePlans = [
                Acme_Careplans_V1_CarePlan.with {
                    $0.audit = Acme_Common_V1_AuditInfo.with {
                        $0.updatedAt = reply0.venue.audit.updatedAt
                    }
                    $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                        $0.countryCode = reply0.venue.address.countryCode
                    }
                }
            ]
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processSuggestCarePlans(_ input: Acme_Careplans_V1_SuggestCarePlansRequest) async throws
        -> Acme_Careplans_V1_SuggestCarePlansResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SuggestCarePlans",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "SuggestCarePlans", detail: input.context.traceID
        )
        let outbound0 = Acme_Careplans_V1_ExplainVitalCalculationRequest.with {
            $0.context = input.context
            $0.details = Acme_Careplans_V1_ExplainVitalCalculationRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.context.actor.email
                }
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.subject = Acme_Appointments_V1_AppointmentRef.with {
                    $0.startsAt = input.filter.createdAfter
                }
            }
        }
        let reply0 = try await self.careplansVitalCalculation.explainVitalCalculation(
            outbound0, metadata: ["x-acme-region": .string(settings.region)]
        )
        return Acme_Careplans_V1_SuggestCarePlansResponse.with {
            $0.carePlans = [
                Acme_Careplans_V1_CarePlan.with {
                    $0.counterparty = Acme_Appointments_V1_AppointmentRef.with {
                        $0.displayName = reply0.vital.subject.displayName
                    }
                }
            ]
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processSummarizeCarePlans(_ input: Acme_Careplans_V1_SummarizeCarePlansRequest) async throws
        -> Acme_Careplans_V1_SummarizeCarePlansResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.carePlanID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "audit", detail: input.carePlanID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SummarizeCarePlans",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "SummarizeCarePlans", detail: input.context.traceID
        )
        let outbound0 = Acme_Search_V1_LintSearchIndexesRequest.with {
            $0.context = input.context
            $0.details = Acme_Search_V1_LintSearchIndexesRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.context.actor.email
                }
            }
            $0.reason = input.reason
        }
        let reply0 = try await RPCOperations.call(outbound0) { request in
            try await self.searchSearchIndexValidation.lintSearchIndexes(request)
        }
        let selection1_1: String
        switch reply0.searchIndex.locator {
        case .address(let address):
            selection1_1 = address.region
        default: selection1_1 = .init()
        }
        let outbound1 = Acme_Notifications_V1_SearchNotificationsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Notifications_V1_SearchNotificationsRequest.Filter.with {
                $0.createdAfter = reply0.searchIndex.audit.updatedAt
                $0.region = selection1_1
            }
        }
        let reply1 = try await self.notificationsNotification.searchNotifications(outbound1)
        return Acme_Careplans_V1_SummarizeCarePlansResponse.with {
            $0.period = input.details.period
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply1.result.details
                $0.status = reply0.outcome.status
            }
        }
    }
}
