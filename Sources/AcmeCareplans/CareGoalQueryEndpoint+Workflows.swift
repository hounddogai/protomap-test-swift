import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension CareGoalQueryEndpoint {
    /// Execute the careplans workflow and project its upstream replies.
    func processBrowseCareGoals(_ input: Acme_Careplans_V1_BrowseCareGoalsRequest) async throws
        -> Acme_Careplans_V1_BrowseCareGoalsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "BrowseCareGoals",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "BrowseCareGoals", detail: input.context.traceID
        )
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        try followUps.submit(
            Acme_Identity_V1_GetUserRequest.with {
                $0.context = input.context
                $0.userID = input.context.actor.userID
            })
        let outbound0 = Acme_Careplans_V1_SimulateCareGoalRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.customer = Acme_Patients_V1_PatientRef.with {
                    $0.email = input.context.actor.email
                }
                $0.history = [
                    Acme_Careplans_V1_CareGoalStatusChange.with {
                        $0.changedAt = input.filter.createdAfter
                    }
                ]
            }
            $0.context = input.context
            $0.details = Acme_Careplans_V1_SimulateCareGoalRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
            }
        }
        let step0: @Sendable () async throws -> Acme_Careplans_V1_SimulateCareGoalResponse = {
            try await self.careplansCareGoalCalculation.simulateCareGoal(outbound0)
        }
        let reply0 = try await step0()
        return Acme_Careplans_V1_BrowseCareGoalsResponse.with {
            $0.careGoals = [
                Acme_Careplans_V1_CareGoal.with {
                    $0.priority = reply0.careGoal.priority
                }
            ]
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processCountCareGoals(_ input: Acme_Careplans_V1_CountCareGoalsRequest) async throws
        -> Acme_Careplans_V1_CountCareGoalsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "CountCareGoals",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "CountCareGoals", detail: input.context.traceID
        )
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        return Acme_Careplans_V1_CountCareGoalsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processExportCareGoals(_ input: Acme_Careplans_V1_ExportCareGoalsRequest) async throws
        -> Acme_Careplans_V1_ExportCareGoalsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.destinationUri)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "audit", detail: input.destinationUri
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ExportCareGoals",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "ExportCareGoals", detail: input.context.traceID
        )
        var outbound0 = Acme_Careplans_V1_ValidateCareGoalRequest()
        outbound0.careGoal = Acme_Careplans_V1_CareGoal.with {
            $0.requester = Acme_Common_V1_ContactInfo.with {
                $0.email = input.context.actor.email
            }
        }
        outbound0.context = input.context
        let reply0 = try await self.careplansCareGoalValidation.validateCareGoal(outbound0)
        return Acme_Careplans_V1_ExportCareGoalsResponse.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.phone = reply0.careGoal.requester.phone
                }
                $0.sla = Acme_Careplans_V1_CareGoalSla.with {
                    $0.pausedFor = reply0.careGoal.sla.pausedFor
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processFindCareGoals(_ input: Acme_Careplans_V1_FindCareGoalsRequest) async throws
        -> Acme_Careplans_V1_FindCareGoalsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "FindCareGoals",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "FindCareGoals", detail: input.context.traceID
        )
        let outbound0 = Acme_Careplans_V1_ResolveCarePlansRequest.with {
            $0.context = input.context
        }
        let reply0 = try await RPCOperations.read {
            try await self.careplansCarePlanQuery.resolveCarePlans(outbound0)
        }
        let outbound1 = Acme_Careplans_V1_EstimateVitalRequest.with {
            $0.context = input.context
            $0.details = Acme_Careplans_V1_EstimateVitalRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.attributes = input.filter.labels
                $0.correlationID = reply0.result.correlationID
                $0.subject = Acme_Appointments_V1_AppointmentRef.with {
                    $0.startsAt = input.filter.createdAfter
                }
            }
        }
        let reply1 = try await self.careplansVitalCalculation.estimateVital(outbound1)
        return Acme_Careplans_V1_FindCareGoalsResponse.with {
            $0.pageInfo = Acme_Common_V1_PageInfo.with {
                $0.totalSize = reply0.pageInfo.totalSize
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.referenceIds = reply1.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processLookupCareGoal(_ input: Acme_Careplans_V1_LookupCareGoalRequest) async throws
        -> Acme_Careplans_V1_LookupCareGoalResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "LookupCareGoal",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "LookupCareGoal", detail: input.context.traceID
        )
        return Acme_Careplans_V1_LookupCareGoalResponse.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.careGoalID = input.careGoalID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processPeekCareGoal(_ input: Acme_Careplans_V1_PeekCareGoalRequest) async throws
        -> Acme_Careplans_V1_PeekCareGoalResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "PeekCareGoal",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "PeekCareGoal", detail: input.context.traceID
        )
        let outbound0 = Acme_Careplans_V1_ExplainCarePlanDecisionRequest.with {
            $0.context = input.context
            $0.details = Acme_Careplans_V1_ExplainCarePlanDecisionRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.context.actor.email
                }
            }
        }
        async let remote0 = self.careplansCarePlanValidation.explainCarePlanDecision(outbound0)
        async let persisted0 = store.count(tenant: input.context.tenantID)
        let (reply0, count0) = try await (remote0, persisted0)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count0)])
        return Acme_Careplans_V1_PeekCareGoalResponse.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.careGoalID = input.careGoalID
                $0.sla = Acme_Careplans_V1_CareGoalSla.with {
                    $0.dueAt = reply0.carePlan.dueAt
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply0.outcome.status
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processResolveCareGoals(_ input: Acme_Careplans_V1_ResolveCareGoalsRequest) async throws
        -> Acme_Careplans_V1_ResolveCareGoalsResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ResolveCareGoals",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "ResolveCareGoals", detail: input.context.traceID
        )
        return Acme_Careplans_V1_ResolveCareGoalsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processSuggestCareGoals(_ input: Acme_Careplans_V1_SuggestCareGoalsRequest) async throws
        -> Acme_Careplans_V1_SuggestCareGoalsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SuggestCareGoals",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "SuggestCareGoals", detail: input.context.traceID
        )
        return Acme_Careplans_V1_SuggestCareGoalsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processSummarizeCareGoals(_ input: Acme_Careplans_V1_SummarizeCareGoalsRequest) async throws
        -> Acme_Careplans_V1_SummarizeCareGoalsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.careGoalID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "audit", detail: input.careGoalID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SummarizeCareGoals",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_goal",
            action: "SummarizeCareGoals", detail: input.context.traceID
        )
        let outbound0 = Acme_Careplans_V1_PreviewCarePlanRequest.with {
            $0.annotations = input.annotations
            $0.context = input.context
            $0.reason = input.reason
        }
        let reply0 = try await self.summarizeCareGoalsStep0.execute(outbound0)
        let outbound1 = Acme_Careplans_V1_EstimateVitalRequest.with {
            $0.context = input.context
            $0.details = Acme_Careplans_V1_EstimateVitalRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.region = reply0.carePlan.billingAddress.region
                }
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.subject = Acme_Appointments_V1_AppointmentRef.with {
                    $0.displayName = reply0.carePlan.counterparty.displayName
                    $0.startsAt = reply0.carePlan.counterparty.startsAt
                }
            }
        }
        let port1 = RPCOperations.port { (request: Acme_Careplans_V1_EstimateVitalRequest) in
            try await self.careplansVitalCalculation.estimateVital(request)
        }
        let reply1 = try await port1.execute(outbound1)
        let outbound2 = Acme_Careplans_V1_NormalizeCareGoalRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply1.vital.subject.displayName
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply0.carePlan.audit.createdBy
                    $0.updatedBy = reply0.carePlan.audit.updatedBy
                }
                $0.customer = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = reply0.carePlan.counterparty.displayName
                }
            }
            $0.context = input.context
        }
        let reply2 = try await self.summarizeCareGoalsStep2(outbound2)
        return Acme_Careplans_V1_SummarizeCareGoalsResponse.with {
            $0.period = input.details.period
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.referenceIds = reply0.result.referenceIds + reply1.result.referenceIds
                $0.status = reply2.outcome.status
            }
        }
    }
}
