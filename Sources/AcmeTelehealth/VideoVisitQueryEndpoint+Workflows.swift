import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension VideoVisitQueryEndpoint {
    /// Execute the telehealth workflow and project its upstream replies.
    func processBrowseVideoVisits(_ input: Acme_Telehealth_V1_BrowseVideoVisitsRequest) async throws
        -> Acme_Telehealth_V1_BrowseVideoVisitsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "BrowseVideoVisits",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "BrowseVideoVisits", detail: input.context.traceID
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
        let outbound0 = Acme_Telehealth_V1_EstimateTriageRequest.with {
            $0.context = input.context
            $0.details = Acme_Telehealth_V1_EstimateTriageRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
            }
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.context.actor.email
                }
            }
        }
        let step0: @Sendable () async throws -> Acme_Telehealth_V1_EstimateTriageResponse = {
            try await self.telehealthTriageCalculation.estimateTriage(outbound0)
        }
        let reply0 = try await step0()
        return Acme_Telehealth_V1_BrowseVideoVisitsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply0.result.status
            }
            $0.videoVisits = [
                Acme_Telehealth_V1_VideoVisit.with {
                    $0.organizer = Acme_Identity_V1_UserRef.with {
                        $0.displayName = reply0.triage.customer.displayName
                    }
                }
            ]
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processCountVideoVisits(_ input: Acme_Telehealth_V1_CountVideoVisitsRequest) async throws
        -> Acme_Telehealth_V1_CountVideoVisitsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "CountVideoVisits",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "CountVideoVisits", detail: input.context.traceID
        )
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        var outbound0 = Acme_Metrics_V1_SuggestMetricSeriesesRequest()
        outbound0.context = input.context
        outbound0.filter = Acme_Metrics_V1_SuggestMetricSeriesesRequest.Filter.with {
            $0.createdAfter = input.filter.createdAfter
            $0.query = input.filter.query
            $0.region = input.filter.region
        }
        outbound0.orderBy = input.orderBy
        let reply0 = try await self.metricsMetricSeriesQuery.suggestMetricSerieses(outbound0)
        return Acme_Telehealth_V1_CountVideoVisitsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.result.message
                $0.status = reply0.result.status
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processExportVideoVisits(_ input: Acme_Telehealth_V1_ExportVideoVisitsRequest) async throws
        -> Acme_Telehealth_V1_ExportVideoVisitsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.destinationUri)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "audit", detail: input.destinationUri
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ExportVideoVisits",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "ExportVideoVisits", detail: input.context.traceID
        )
        let outbound0 = Acme_Documents_V1_ResolveDocumentsRequest.with {
            $0.context = input.context
        }
        let reply0 = try await RPCOperations.read {
            try await self.documentsDocumentQuery.resolveDocuments(outbound0)
        }
        let outbound1 = Acme_Telehealth_V1_CompareVisitNoteOptionsRequest.with {
            $0.context = input.context
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.email = input.context.actor.email
                }
                $0.dueAt = input.filter.createdAfter
                $0.lines = [
                    Acme_Telehealth_V1_VisitNoteLine.with {
                        $0.attributes = input.filter.labels
                    }
                ]
            }
        }
        let reply1 = try await self.telehealthVisitNoteCalculation.compareVisitNoteOptions(outbound1)
        return Acme_Telehealth_V1_ExportVideoVisitsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply0.result.status
            }
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.email = reply1.visitNote.counterparty.email
                }
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processLookupVideoVisit(_ input: Acme_Telehealth_V1_LookupVideoVisitRequest) async throws
        -> Acme_Telehealth_V1_LookupVideoVisitResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "LookupVideoVisit",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "LookupVideoVisit", detail: input.context.traceID
        )
        return Acme_Telehealth_V1_LookupVideoVisitResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.videoVisitID = input.videoVisitID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processPeekVideoVisit(_ input: Acme_Telehealth_V1_PeekVideoVisitRequest) async throws
        -> Acme_Telehealth_V1_PeekVideoVisitResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "PeekVideoVisit",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "PeekVideoVisit", detail: input.context.traceID
        )
        return Acme_Telehealth_V1_PeekVideoVisitResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.videoVisitID = input.videoVisitID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processResolveVideoVisits(_ input: Acme_Telehealth_V1_ResolveVideoVisitsRequest) async throws
        -> Acme_Telehealth_V1_ResolveVideoVisitsResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ResolveVideoVisits",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "ResolveVideoVisits", detail: input.context.traceID
        )
        let outbound0 = Acme_Telehealth_V1_RecalculateTriagesRequest.with {
            $0.context = input.context
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.context.actor.userID
                }
                $0.customFields = input.context.baggage
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.context.actor.email
                }
                $0.sla = Acme_Telehealth_V1_TriageSla.with {
                    $0.dueAt = input.context.deadline
                }
            }
        }
        async let remote0 = self.telehealthTriageCalculation.recalculateTriages(outbound0)
        async let persisted0 = store.count(tenant: input.context.tenantID)
        let (reply0, count0) = try await (remote0, persisted0)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count0)])
        return Acme_Telehealth_V1_ResolveVideoVisitsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.videoVisits = [
                Acme_Telehealth_V1_VideoVisit.with {
                    $0.participants = [
                        Acme_Telehealth_V1_VideoVisitParticipant.with {
                            $0.contact = Acme_Common_V1_ContactInfo.with {
                                $0.email = reply0.triage.assignee.email
                            }
                        }
                    ]
                }
            ]
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processSuggestVideoVisits(_ input: Acme_Telehealth_V1_SuggestVideoVisitsRequest) async throws
        -> Acme_Telehealth_V1_SuggestVideoVisitsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SuggestVideoVisits",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "SuggestVideoVisits", detail: input.context.traceID
        )
        let outbound0 = Acme_Careplans_V1_ScoreCarePlanRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.context.deadline
                    $0.updatedAt = input.filter.createdAfter
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
                $0.lines = [
                    Acme_Careplans_V1_CarePlanLine.with {
                        $0.attributes = input.filter.labels
                    }
                ]
            }
            $0.context = input.context
        }
        let reply0 = try await self.suggestVideoVisitsStep0.execute(outbound0)
        return Acme_Telehealth_V1_SuggestVideoVisitsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.videoVisits = [
                Acme_Telehealth_V1_VideoVisit.with {
                    $0.audit = Acme_Common_V1_AuditInfo.with {
                        $0.etag = reply0.carePlan.audit.etag
                    }
                }
            ]
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processSummarizeVideoVisits(_ input: Acme_Telehealth_V1_SummarizeVideoVisitsRequest) async throws
        -> Acme_Telehealth_V1_SummarizeVideoVisitsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.cron)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "audit", detail: input.details.cron
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SummarizeVideoVisits",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "video_visit",
            action: "SummarizeVideoVisits", detail: input.context.traceID
        )
        let outbound0 = Acme_Telehealth_V1_CompareTriageOptionsRequest.with {
            $0.annotations = input.annotations
            $0.context = input.context
            $0.reason = input.reason
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.email = input.context.actor.email
                }
                $0.customer = Acme_Telehealth_V1_VideoVisitRef.with {
                    $0.videoVisitID = input.videoVisitID
                }
            }
        }
        let port0 = RPCOperations.port { (request: Acme_Telehealth_V1_CompareTriageOptionsRequest) in
            try await self.telehealthTriageCalculation.compareTriageOptions(request)
        }
        let reply0 = try await port0.execute(outbound0)
        let selection1_4: String
        switch reply0.triage.origin {
        case .customer(let customer):
            selection1_4 = customer.displayName
        default: selection1_4 = .init()
        }
        let outbound1 = Acme_Metrics_V1_PreviewMetricSeriesRequest.with {
            $0.context = input.context
            $0.details = Acme_Metrics_V1_PreviewMetricSeriesRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply0.triage.requester.email
                    $0.phone = reply0.triage.requester.phone
                }
            }
            $0.metricSeries = Acme_Metrics_V1_MetricSeries.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply0.triage.audit.etag
                }
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.displayName = selection1_4
                }
            }
        }
        let reply1 = try await self.metricsMetricSeriesValidation.previewMetricSeries(outbound1)
        return Acme_Telehealth_V1_SummarizeVideoVisitsResponse.with {
            $0.period = input.details.period
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.message = reply1.result.message
                $0.status = reply0.result.status
            }
        }
    }
}
