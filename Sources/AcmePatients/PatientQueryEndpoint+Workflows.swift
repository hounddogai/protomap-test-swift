import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension PatientQueryEndpoint {
    /// Lists patients a page at a time.
    func browsePatients(
        request: ServerRequest<Acme_Patients_V1_BrowsePatientsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_BrowsePatientsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processBrowsePatients(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Counts patients by status.
    func countPatients(
        request: ServerRequest<Acme_Patients_V1_CountPatientsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_CountPatientsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCountPatients(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists patients a page at a time.
    func findPatients(
        request: ServerRequest<Acme_Patients_V1_FindPatientsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_FindPatientsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processFindPatients(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a patient.
    func lookupPatient(
        request: ServerRequest<Acme_Patients_V1_LookupPatientRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_LookupPatientResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processLookupPatient(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a patient.
    func peekPatient(
        request: ServerRequest<Acme_Patients_V1_PeekPatientRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_PeekPatientResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processPeekPatient(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns several patients at once.
    func resolvePatients(
        request: ServerRequest<Acme_Patients_V1_ResolvePatientsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_ResolvePatientsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processResolvePatients(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Summarizes a patient.
    func summarizePatients(
        request: ServerRequest<Acme_Patients_V1_SummarizePatientsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_SummarizePatientsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSummarizePatients(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processBrowsePatients(_ input: Acme_Patients_V1_BrowsePatientsRequest) async throws
        -> Acme_Patients_V1_BrowsePatientsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "BrowsePatients",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "BrowsePatients", detail: input.context.traceID
        )
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        try followUps.submit(
            Acme_Identity_V1_GetUserRequest.with {
                $0.context = input.context
                $0.userID = input.context.actor.userID
            })
        let importFrame = Acme_Telehealth_V1_BatchCreateVideoVisitsRequest.with {
            $0.context = input.context
        }
        _ = try await self.telehealthVideoVisit.batchCreateVideoVisits { writer in
            try await writer.write(importFrame)
        }
        let outbound0 = Acme_Telehealth_V1_QuoteTriageRequest.with {
            $0.context = input.context
            $0.details = Acme_Telehealth_V1_QuoteTriageRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
            }
        }
        let json0 = try outbound0.jsonString()
        let decoded0 = try Acme_Telehealth_V1_QuoteTriageRequest(jsonString: json0)
        let reply0 = try await self.telehealthTriageCalculation.quoteTriage(decoded0)
        return Acme_Patients_V1_BrowsePatientsResponse.with {
            $0.patients = [
                Acme_Patients_V1_Patient.with {
                    $0.contact = Acme_Common_V1_ContactInfo.with {
                        $0.email = reply0.triage.requester.email
                    }
                }
            ]
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processCountPatients(_ input: Acme_Patients_V1_CountPatientsRequest) async throws
        -> Acme_Patients_V1_CountPatientsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "CountPatients",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "CountPatients", detail: input.context.traceID
        )
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        return Acme_Patients_V1_CountPatientsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processFindPatients(_ input: Acme_Patients_V1_FindPatientsRequest) async throws
        -> Acme_Patients_V1_FindPatientsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "FindPatients",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "FindPatients", detail: input.context.traceID
        )
        let outbound0 = Acme_Patients_V1_RecalculateAllergiesRequest.forPatientQueryEndpointFindPatients0(
            input
        )
        let reply0 = try await self.patientsAllergyCalculation.recalculateAllergies(outbound0)
        let outbound1 = Acme_Ledger_V1_ListLedgerAccountsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Ledger_V1_ListLedgerAccountsRequest.Filter.with {
                $0.createdAfter = input.filter.createdAfter
            }
            $0.page = Acme_Common_V1_PageRequest.with {
                $0.pageSize = input.page.pageSize
                $0.pageToken = input.page.pageToken
            }
        }
        let reply1 = try await self.ledgerLedgerAccount.listLedgerAccounts(
            outbound1, metadata: ["x-acme-region": .string(settings.region)]
        )
        return Acme_Patients_V1_FindPatientsResponse.with {
            $0.pageInfo = Acme_Common_V1_PageInfo.with {
                $0.totalSize = reply1.pageInfo.totalSize
            }
            $0.patients = [
                Acme_Patients_V1_Patient.with {
                    $0.attributes = reply0.allergy.attributes
                }
            ]
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processLookupPatient(_ input: Acme_Patients_V1_LookupPatientRequest) async throws
        -> Acme_Patients_V1_LookupPatientResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "LookupPatient",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "LookupPatient", detail: input.context.traceID
        )
        let outbound0 = Acme_Audit_V1_ExplainAuditEventDecisionRequest.with {
            $0.context = input.context
            $0.details = Acme_Audit_V1_ExplainAuditEventDecisionRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.context.actor.email
                }
            }
        }
        let reply0 = try await RPCOperations.call(outbound0) { request in
            try await self.auditAuditEventValidation.explainAuditEventDecision(request)
        }
        return Acme_Patients_V1_LookupPatientResponse.with {
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.patientID = input.patientID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply0.outcome.status
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processPeekPatient(_ input: Acme_Patients_V1_PeekPatientRequest) async throws
        -> Acme_Patients_V1_PeekPatientResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "PeekPatient",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "PeekPatient", detail: input.context.traceID
        )
        let outbound0 = Acme_Notifications_V1_SearchNotificationsRequest.with {
            $0.context = Projection.read(input, at: \Acme_Patients_V1_PeekPatientRequest.context)
            $0.filter = Acme_Notifications_V1_SearchNotificationsRequest.Filter.with {
                $0.createdAfter = Projection.read(input, at: \Acme_Patients_V1_PeekPatientRequest.context.deadline)
                $0.labels = input.context.baggage
                $0.ownerID = Projection.read(input, at: \Acme_Patients_V1_PeekPatientRequest.patientID)
            }
        }
        let reply0 = try await self.notificationsNotification.searchNotifications(outbound0)
        return Acme_Patients_V1_PeekPatientResponse.with {
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.patientID = input.patientID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.status = reply0.result.status
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processResolvePatients(_ input: Acme_Patients_V1_ResolvePatientsRequest) async throws
        -> Acme_Patients_V1_ResolvePatientsResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ResolvePatients",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "ResolvePatients", detail: input.context.traceID
        )
        let outbound0 = Acme_Prescriptions_V1_ValidateRefillRequest.with {
            $0.context = input.context
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.email = input.context.actor.email
                }
            }
        }
        let step0: @Sendable () async throws -> Acme_Prescriptions_V1_ValidateRefillResponse = {
            try await self.prescriptionsRefillValidation.validateRefill(outbound0)
        }
        let reply0 = try await step0()
        let selection1_3: String
        switch reply0.refill.origin {
        case .customer(let customer):
            selection1_3 = customer.displayName
        default: selection1_3 = .init()
        }
        let outbound1 = Acme_Notifications_V1_CheckNotificationEligibilityRequest.with {
            $0.context = input.context
            $0.details = Acme_Notifications_V1_CheckNotificationEligibilityRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.name = reply0.refill.requester.name
                }
            }
            $0.notification = Acme_Notifications_V1_Notification.with {
                $0.customer = Acme_Notifications_V1_NotificationTemplateRef.with {
                    $0.displayName = selection1_3
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.preferredChannel = reply0.refill.requester.preferredChannel
                }
            }
        }
        let reply1 = try await self.notificationsNotificationValidation.checkNotificationEligibility(outbound1)
        return Acme_Patients_V1_ResolvePatientsResponse.with {
            $0.patients = [
                Acme_Patients_V1_Patient.with {
                    $0.audit = Acme_Common_V1_AuditInfo.with {
                        $0.createdAt = reply1.notification.audit.createdAt
                    }
                    $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                        $0.displayName = reply0.refill.assignee.displayName
                    }
                }
            ]
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processSummarizePatients(_ input: Acme_Patients_V1_SummarizePatientsRequest) async throws
        -> Acme_Patients_V1_SummarizePatientsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.cron)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "audit", detail: input.details.cron
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SummarizePatients",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "SummarizePatients", detail: input.context.traceID
        )
        var outbound0 = Acme_Patients_V1_RecalculateAllergiesRequest()
        outbound0.allergy = Acme_Patients_V1_Allergy.with {
            $0.subject = Acme_Patients_V1_PatientRef.with {
                $0.email = input.context.actor.email
                $0.patientID = input.patientID
            }
        }
        outbound0.annotations = input.annotations
        outbound0.context = input.context
        outbound0.reason = input.reason
        let reply0 = try await self.patientsAllergyCalculation.recalculateAllergies(outbound0)
        let outbound1 = Acme_Patients_V1_CalculateAllergyRequest.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.email = reply0.allergy.subject.email
                    $0.patientID = reply0.allergy.subject.patientID
                }
            }
            $0.context = input.context
        }
        let step1: @Sendable () async throws -> Acme_Patients_V1_CalculateAllergyResponse = {
            try await self.patientsAllergyCalculation.calculateAllergy(outbound1)
        }
        let reply1 = try await step1()
        return Acme_Patients_V1_SummarizePatientsResponse.with {
            $0.period = input.details.period
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.allergy.correlationID
                $0.details = reply0.result.details
                $0.status = "ok"
            }
        }
    }
}
