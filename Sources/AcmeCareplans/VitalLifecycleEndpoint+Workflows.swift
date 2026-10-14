import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension VitalLifecycleEndpoint {
    /// Execute the careplans workflow and project its upstream replies.
    func processActivateVital(_ input: Acme_Careplans_V1_ActivateVitalRequest) async throws
        -> Acme_Careplans_V1_ActivateVitalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "audit", detail: input.details.newOwner.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ActivateVital",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "ActivateVital", detail: input.context.traceID
        )
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        try followUps.submit(
            Acme_Identity_V1_GetUserRequest.with {
                $0.context = input.context
                $0.userID = input.context.actor.userID
            })
        let importFrame = Acme_Careplans_V1_BatchCreateCarePlansRequest.with {
            $0.context = input.context
        }
        _ = try await self.careplansCarePlan.batchCreateCarePlans { writer in
            try await writer.write(importFrame)
        }
        let outbound0 = Acme_Careplans_V1_CountCarePlansRequest.with {
            $0.context = input.context
            $0.filter = Acme_Careplans_V1_CountCarePlansRequest.Filter.with {
                $0.createdAfter = input.details.effectiveAt
                $0.ownerID = input.details.newOwner.userID
            }
        }
        let reply0 = try await RPCOperations.call(outbound0) { request in
            try await self.careplansCarePlanQuery.countCarePlans(request)
        }
        return Acme_Careplans_V1_ActivateVitalResponse.with {
            $0.outcome = Acme_Careplans_V1_ActivateVitalResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.status = "ok"
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.vitalID = input.vitalID
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processExpireVital(_ input: Acme_Careplans_V1_ExpireVitalRequest) async throws
        -> Acme_Careplans_V1_ExpireVitalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "audit", detail: input.details.newOwner.email
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ExpireVital",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "ExpireVital", detail: input.context.traceID
        )
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        let outbound0 = Acme_Audit_V1_CountAuditEventsRequest.with {
            $0.context = Projection.read(input, at: \Acme_Careplans_V1_ExpireVitalRequest.context)
            $0.filter = Acme_Audit_V1_CountAuditEventsRequest.Filter.with {
                $0.createdAfter = Projection.read(input, at: \Acme_Careplans_V1_ExpireVitalRequest.details.effectiveAt)
                $0.labels = input.annotations
                $0.ownerID = Projection.read(input, at: \Acme_Careplans_V1_ExpireVitalRequest.details.newOwner.userID)
            }
        }
        let reply0 = try await self.auditAuditEventQuery.countAuditEvents(outbound0)
        let outbound1 = Acme_Patients_V1_BrowsePatientsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Patients_V1_BrowsePatientsRequest.Filter.with {
                $0.createdAfter = input.details.effectiveAt
                $0.labels = reply0.result.details
                $0.ownerID = input.details.newOwner.userID
            }
        }
        let step1: @Sendable () async throws -> Acme_Patients_V1_BrowsePatientsResponse = {
            try await self.patientsPatientQuery.browsePatients(outbound1)
        }
        let reply1 = try await step1()
        var outbound2 = Acme_Featureflags_V1_ScoreFeatureFlagRequest()
        outbound2.context = input.context
        outbound2.featureFlag = Acme_Featureflags_V1_FeatureFlag.with {
            $0.block = Acme_Featureflags_V1_FeatureFlagBlockAction.with {
                $0.reason = input.reason
            }
            $0.owner = Acme_Identity_V1_UserRef.with {
                $0.displayName = input.details.newOwner.displayName
                $0.email = input.details.notifyContact.email
            }
        }
        let reply2 = try await self.featureflagsFeatureFlagValidation.scoreFeatureFlag(outbound2)
        return Acme_Careplans_V1_ExpireVitalResponse.with {
            $0.outcome = Acme_Careplans_V1_ExpireVitalResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
                $0.message = reply1.result.message
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply0.result.referenceIds
                $0.status = reply2.result.status
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.correlationID = Projection.firstValue(
                    [
                        reply0.result.correlationID,
                        reply1.result.correlationID,
                    ], default: .init())
                $0.vitalID = input.vitalID
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processGetVitalLifecycle(_ input: Acme_Careplans_V1_GetVitalLifecycleRequest) async throws
        -> Acme_Careplans_V1_GetVitalLifecycleResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "GetVitalLifecycle",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "GetVitalLifecycle", detail: input.context.traceID
        )
        return Acme_Careplans_V1_GetVitalLifecycleResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.vitalID = input.vitalID
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processReinstateVital(_ input: Acme_Careplans_V1_ReinstateVitalRequest) async throws
        -> Acme_Careplans_V1_ReinstateVitalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "audit", detail: input.details.newOwner.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ReinstateVital",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "ReinstateVital", detail: input.context.traceID
        )
        let outbound0 = Acme_Ledger_V1_SearchLedgerAccountsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Ledger_V1_SearchLedgerAccountsRequest.Filter.with {
                $0.createdAfter = input.details.effectiveAt
                $0.labels = input.annotations
                $0.ownerID = input.details.newOwner.userID
            }
        }
        let reply0 = try await RPCOperations.read {
            try await self.ledgerLedgerAccount.searchLedgerAccounts(outbound0)
        }
        let outbound1 = Acme_Appointments_V1_SuggestProvidersRequest.with {
            $0.context = input.context
            $0.filter = Acme_Appointments_V1_SuggestProvidersRequest.Filter.with {
                $0.createdAfter = input.details.effectiveAt
            }
        }
        let reply1 = try await self.appointmentsProviderQuery.suggestProviders(outbound1)
        let outbound2 = Acme_Ledger_V1_WatchLedgerAccountsRequest.with {
            $0.context = input.context
            $0.subscriber = Acme_Common_V1_ContactInfo.with {
                $0.email = input.details.newOwner.email
                $0.name = input.details.notifyContact.name
                $0.phone = input.details.notifyContact.phone
                $0.preferredChannel = input.details.notifyContact.preferredChannel
            }
        }
        let reply2 = try await self.ledgerLedgerAccount.watchLedgerAccounts(outbound2) { response in
            var latest = Acme_Ledger_V1_WatchLedgerAccountsResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        _ = reply2
        let outbound3 = Acme_Prescriptions_V1_PreviewRefillRequest.with {
            $0.context = input.context
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.email = input.details.newOwner.email
                    $0.userID = input.details.newOwner.userID
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.name = input.details.notifyContact.name
                }
            }
        }
        async let remote3 = self.prescriptionsRefillValidation.previewRefill(outbound3)
        async let persisted3 = store.count(tenant: input.context.tenantID)
        let (reply3, count3) = try await (remote3, persisted3)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count3)])
        return Acme_Careplans_V1_ReinstateVitalResponse.with {
            $0.outcome = Acme_Careplans_V1_ReinstateVitalResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
                $0.message = reply3.outcome.message
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply1.result.message
                $0.status = "ok"
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.correlationID = Projection.firstValue(
                    [
                        reply0.result.correlationID,
                        reply1.result.correlationID,
                    ], default: .init())
                $0.subject = Acme_Appointments_V1_AppointmentRef.with {
                    $0.displayName = reply3.refill.assignee.displayName
                }
                $0.vitalID = input.vitalID
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processRenewVital(_ input: Acme_Careplans_V1_RenewVitalRequest) async throws
        -> Acme_Careplans_V1_RenewVitalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "audit", detail: input.details.newOwner.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "RenewVital",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "RenewVital", detail: input.context.traceID
        )
        let outbound0 = Acme_Careplans_V1_LintCareGoalsRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.email = input.details.notifyContact.email
                }
            }
            $0.context = input.context
            $0.details = Acme_Careplans_V1_LintCareGoalsRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.name = input.details.notifyContact.name
                    $0.phone = input.details.notifyContact.phone
                }
            }
        }
        let reply0 = try await self.renewVitalStep0.execute(outbound0)
        let outbound1 = Acme_Identity_V1_BrowseUsersRequest.with {
            $0.context = input.context
            $0.filter = Acme_Identity_V1_BrowseUsersRequest.Filter.with {
                $0.createdAfter = reply0.careGoal.sla.dueAt
            }
        }
        let port1 = RPCOperations.port { (request: Acme_Identity_V1_BrowseUsersRequest) in
            try await self.identityUserQuery.browseUsers(request)
        }
        let reply1 = try await port1.execute(outbound1)
        return Acme_Careplans_V1_RenewVitalResponse.with {
            $0.outcome = Acme_Careplans_V1_RenewVitalResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
                $0.nextSteps = reply0.outcome.nextSteps
                $0.status = reply1.result.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.subject = Acme_Appointments_V1_AppointmentRef.with {
                    $0.displayName = reply0.careGoal.assignee.displayName
                }
                $0.vitalID = input.vitalID
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processScheduleVitalExpiry(_ input: Acme_Careplans_V1_ScheduleVitalExpiryRequest) async throws
        -> Acme_Careplans_V1_ScheduleVitalExpiryResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "audit", detail: input.details.initiatedBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ScheduleVitalExpiry",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VitalRecord(input.vital, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Careplans_V1_QuoteVitalRequest.with {
            $0.context = input.context
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.subject = Acme_Appointments_V1_AppointmentRef.with {
                    $0.appointmentID = input.vital.subject.appointmentID
                    $0.displayName = input.vital.subject.displayName
                }
            }
        }
        let reply0 = try await self.scheduleVitalExpiryStep0(outbound0)
        let outbound1 = Acme_Prescriptions_V1_CalculateMedicationRequest.with {
            $0.context = input.context
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.vital.subject.displayName
                    $0.email = input.details.notify.email
                }
            }
        }
        guard let execute1 = self.scheduleVitalExpiryStep1[settings.region] ?? self.scheduleVitalExpiryStep1["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply1 = try await execute1(outbound1)
        return Acme_Careplans_V1_ScheduleVitalExpiryResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = Projection.firstValue(
                    [
                        reply0.result.correlationID,
                        reply1.result.correlationID,
                    ], default: .init())
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.correlationID = reply1.result.correlationID
                $0.occurredAt = input.vital.occurredAt
                $0.vitalID = input.vitalID
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processSuspendVital(_ input: Acme_Careplans_V1_SuspendVitalRequest) async throws
        -> Acme_Careplans_V1_SuspendVitalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "audit", detail: input.details.newOwner.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SuspendVital",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "SuspendVital", detail: input.context.traceID
        )
        let outbound0 = Acme_Careplans_V1_BrowseCarePlansRequest.with {
            $0.context = input.context
            $0.filter = Acme_Careplans_V1_BrowseCarePlansRequest.Filter.with {
                $0.createdAfter = input.details.effectiveAt
            }
        }
        let reply0 = try await self.careplansCarePlanQuery.browseCarePlans(outbound0)
        let outbound1 = Acme_Careplans_V1_ListVitalReportsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Careplans_V1_ListVitalReportsRequest.Filter.with {
                $0.createdAfter = input.details.effectiveAt
                $0.labels = reply0.result.details
                $0.ownerID = reply0.result.correlationID
            }
        }
        let envelope1 = try Google_Protobuf_Any(message: outbound1)
        let unpacked1 = try Acme_Careplans_V1_ListVitalReportsRequest(unpackingAny: envelope1)
        let reply1 = try await self.careplansVitalReporting.listVitalReports(unpacked1)
        return Acme_Careplans_V1_SuspendVitalResponse.with {
            $0.outcome = Acme_Careplans_V1_SuspendVitalResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.details = Projection.firstValue(
                    [
                        reply0.result.details,
                        reply1.result.details,
                    ], default: .init())
                $0.status = "ok"
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.vitalID = input.vitalID
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processTerminateVital(_ input: Acme_Careplans_V1_TerminateVitalRequest) async throws
        -> Acme_Careplans_V1_TerminateVitalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "audit", detail: input.details.newOwner.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "TerminateVital",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "TerminateVital", detail: input.context.traceID
        )
        let outbound0 = Acme_Notifications_V1_FindNotificationsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Notifications_V1_FindNotificationsRequest.Filter.with {
                $0.ownerID = input.details.newOwner.userID
            }
        }
        let json0 = try outbound0.jsonString()
        let decoded0 = try Acme_Notifications_V1_FindNotificationsRequest(jsonString: json0)
        let reply0 = try await self.notificationsNotificationQuery.findNotifications(decoded0)
        let outbound1 = Acme_Appointments_V1_CountProvidersRequest.forVitalLifecycleEndpointTerminateVital1(
            input,
            reply0: reply0
        )
        let reply1 = try await self.appointmentsProviderQuery.countProviders(outbound1)
        let outbound2 = Acme_Ledger_V1_PreviewLedgerAccountRequest.with {
            $0.context = input.context
            $0.details = Acme_Ledger_V1_PreviewLedgerAccountRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.name = input.details.notifyContact.name
                    $0.phone = input.details.notifyContact.phone
                }
            }
            $0.ledgerAccount = Acme_Ledger_V1_LedgerAccount.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.preferredChannel = input.details.notifyContact.preferredChannel
                }
            }
        }
        let reply2 = try await self.ledgerLedgerAccountValidation.previewLedgerAccount(
            outbound2, metadata: ["x-acme-region": .string(settings.region)]
        )
        let outbound3 = Acme_Surveys_V1_ListSurveysRequest.with {
            $0.context = input.context
            $0.filter = Acme_Surveys_V1_ListSurveysRequest.Filter.with {
                $0.createdAfter = reply2.ledgerAccount.audit.updatedAt
                $0.labels = reply2.ledgerAccount.labels
                $0.ownerID = input.details.newOwner.userID
            }
        }
        let reply3 = try await RPCOperations.call(outbound3) { request in
            try await self.surveysSurvey.listSurveys(request)
        }
        return Acme_Careplans_V1_TerminateVitalResponse.with {
            $0.outcome = Acme_Careplans_V1_TerminateVitalResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
                $0.message = reply3.result.message
                $0.nextSteps = reply2.outcome.nextSteps
                $0.status = reply3.result.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = Projection.firstValue(
                    [
                        reply0.result.details,
                        reply1.result.details,
                    ], default: .init())
                $0.referenceIds = reply0.result.referenceIds + reply1.result.referenceIds
                $0.status = "ok"
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.vitalID = input.vitalID
            }
        }
    }
}
