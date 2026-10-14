import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension VisitNoteWorkflowEndpoint {
    /// Execute the telehealth workflow and project its upstream replies.
    func processAdvanceVisitNoteWorkflow(_ input: Acme_Telehealth_V1_AdvanceVisitNoteWorkflowRequest) async throws
        -> Acme_Telehealth_V1_AdvanceVisitNoteWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "audit", detail: input.details.initiatedBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "AdvanceVisitNoteWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VisitNoteRecord(input.visitNote, tenant: input.context.tenantID)
        try await store.save(record.stored)
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        let importFrame = Acme_Patients_V1_BatchCreatePatientsRequest.with {
            $0.context = input.context
        }
        _ = try await self.patientsPatient.batchCreatePatients { writer in
            try await writer.write(importFrame)
        }
        let outbound0 = Acme_Appointments_V1_NormalizeClinicSlotRequest.with {
            $0.clinicSlot = Acme_Appointments_V1_ClinicSlot.with {
                $0.participants = [
                    Acme_Appointments_V1_ClinicSlotParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.name = input.details.notify.name
                        }
                    }
                ]
            }
            $0.context = input.context
        }
        let port0 = RPCOperations.port { (request: Acme_Appointments_V1_NormalizeClinicSlotRequest) in
            try await self.appointmentsClinicSlotValidation.normalizeClinicSlot(request)
        }
        let reply0 = try await port0.execute(outbound0)
        return Acme_Telehealth_V1_AdvanceVisitNoteWorkflowResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply0.result.status
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.counterparty = input.visitNote.counterparty
                $0.visitNoteID = input.visitNoteID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processCancelVisitNoteWorkflow(_ input: Acme_Telehealth_V1_CancelVisitNoteWorkflowRequest) async throws
        -> Acme_Telehealth_V1_CancelVisitNoteWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "audit", detail: input.details.initiatedBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "CancelVisitNoteWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VisitNoteRecord(input.visitNote, tenant: input.context.tenantID)
        try await store.save(record.stored)
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        let selection0_2: String
        switch input.visitNote.settlement {
        case .bank(let bank):
            selection0_2 = bank.iban
        default: selection0_2 = .init()
        }
        let outbound0 = Acme_Patients_V1_ExplainMedicalRecordCalculationRequest.with {
            $0.context = input.context
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.bank = Acme_Patients_V1_MedicalRecordBankSettlement.with {
                    $0.iban = selection0_2
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = input.visitNote.billingAddress.postalCode
                    $0.recipient = input.visitNote.billingAddress.recipient
                }
            }
        }
        let reply0 = try await self.patientsMedicalRecordCalculation.explainMedicalRecordCalculation(outbound0)
        let outbound1 = Acme_Content_V1_BatchGetArticlesRequest.with {
            $0.context = input.context
        }
        let reply1 = try await self.cancelVisitNoteWorkflowStep1(outbound1)
        return Acme_Telehealth_V1_CancelVisitNoteWorkflowResponse.with {
            $0.outcome = Acme_Telehealth_V1_CancelVisitNoteWorkflowResponse.Outcome.with {
                $0.message = reply1.result.message
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply1.result.message
                $0.status = "ok"
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply0.medicalRecord.audit.createdAt
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = reply0.medicalRecord.billingAddress.countryCode
                }
                $0.issuedAt = input.visitNote.issuedAt
                $0.visitNoteID = input.visitNoteID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processInspectVisitNoteWorkflow(_ input: Acme_Telehealth_V1_InspectVisitNoteWorkflowRequest) async throws
        -> Acme_Telehealth_V1_InspectVisitNoteWorkflowResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "InspectVisitNoteWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "InspectVisitNoteWorkflow", detail: input.context.traceID
        )
        return Acme_Telehealth_V1_InspectVisitNoteWorkflowResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.visitNoteID = input.visitNoteID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processListVisitNoteWorkflows(_ input: Acme_Telehealth_V1_ListVisitNoteWorkflowsRequest) async throws
        -> Acme_Telehealth_V1_ListVisitNoteWorkflowsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ListVisitNoteWorkflows",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "ListVisitNoteWorkflows", detail: input.context.traceID
        )
        let outbound0 = Acme_Featureflags_V1_ListFeatureFlagsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Featureflags_V1_ListFeatureFlagsRequest.Filter.with {
                $0.labels = input.filter.labels
                $0.query = input.filter.query
                $0.region = input.filter.region
            }
        }
        guard
            let execute0 = self.listVisitNoteWorkflowsStep0[settings.region]
                ?? self.listVisitNoteWorkflowsStep0["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply0 = try await execute0(outbound0)
        let outbound1 = Acme_Anomalies_V1_ExportAnomaliesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Anomalies_V1_ExportAnomaliesRequest.Filter.with {
                $0.createdAfter = input.filter.createdAfter
                $0.labels = input.filter.labels
                $0.query = input.filter.query
            }
        }
        let reply1 = try await self.anomaliesAnomalyQuery.exportAnomalies(outbound1) { response in
            var latest = Acme_Anomalies_V1_ExportAnomaliesResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        _ = reply1
        return Acme_Telehealth_V1_ListVisitNoteWorkflowsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.status = reply0.result.status
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processPauseVisitNoteWorkflow(_ input: Acme_Telehealth_V1_PauseVisitNoteWorkflowRequest) async throws
        -> Acme_Telehealth_V1_PauseVisitNoteWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "audit", detail: input.details.initiatedBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "PauseVisitNoteWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VisitNoteRecord(input.visitNote, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Drivers_V1_UpdateDriverRequest.with {
            $0.context = input.context
            $0.driver = Acme_Drivers_V1_Driver.with {
                $0.name = input.details.notify.name
                $0.nationalID = Acme_Drivers_V1_DriverNationalId.with {
                    $0.number = input.visitNote.number
                }
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.visitNote.billingAddress.region
                }
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.email = input.visitNote.counterparty.email
                }
            }
        }
        let reply0 = try await self.driversDriver.updateDriver(outbound0)
        let outbound1 = Acme_Appointments_V1_BrowseProvidersRequest.with {
            $0.context = input.context
            $0.filter = Acme_Appointments_V1_BrowseProvidersRequest.Filter.with {
                $0.createdAfter = reply0.driver.audit.updatedAt
                $0.region = input.visitNote.billingAddress.region
            }
        }
        let envelope1 = try Google_Protobuf_Any(message: outbound1)
        let unpacked1 = try Acme_Appointments_V1_BrowseProvidersRequest(unpackingAny: envelope1)
        let reply1 = try await self.appointmentsProviderQuery.browseProviders(unpacked1)
        let outbound2 = Acme_Venues_V1_CreateVenueRequest.with {
            $0.context = input.context
            $0.venue = Acme_Venues_V1_Venue.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = input.visitNote.audit.updatedAt
                }
            }
        }
        let json2 = try outbound2.jsonString()
        let decoded2 = try Acme_Venues_V1_CreateVenueRequest(jsonString: json2)
        let reply2 = try await self.venuesVenue.createVenue(decoded2)
        return Acme_Telehealth_V1_PauseVisitNoteWorkflowResponse.with {
            $0.outcome = Acme_Telehealth_V1_PauseVisitNoteWorkflowResponse.Outcome.with {
                $0.message = reply0.result.message
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = Projection.firstValue(
                    [
                        reply1.result.status,
                        reply2.result.status,
                    ], default: .init())
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.lines = [
                    Acme_Telehealth_V1_VisitNoteLine.with {
                        $0.attributes = reply0.driver.attributes
                        $0.description_p = reply2.venue.components["primary", default: .init()].description_p
                    }
                ]
                $0.number = input.visitNote.number
                $0.visitNoteID = input.visitNoteID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processResumeVisitNoteWorkflow(_ input: Acme_Telehealth_V1_ResumeVisitNoteWorkflowRequest) async throws
        -> Acme_Telehealth_V1_ResumeVisitNoteWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "audit", detail: input.details.initiatedBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ResumeVisitNoteWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VisitNoteRecord(input.visitNote, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 =
            Acme_Patients_V1_CheckPatientEligibilityRequest.forVisitNoteWorkflowEndpointResumeVisitNoteWorkflow0(
                input
            )
        let reply0 = try await self.patientsPatientValidation.checkPatientEligibility(outbound0)
        let outbound1 = Acme_Telehealth_V1_RetryVideoVisitWorkflowRequest.with {
            $0.context = input.context
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.visitNote.billingAddress.region
                }
                $0.participants = [
                    Acme_Telehealth_V1_VideoVisitParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.phone = input.details.notify.phone
                            $0.preferredChannel = reply0.patient.contact.preferredChannel
                        }
                    }
                ]
            }
        }
        let reply1 = try await self.telehealthVideoVisitWorkflow.retryVideoVisitWorkflow(
            outbound1, metadata: ["x-acme-region": .string(settings.region)]
        )
        return Acme_Telehealth_V1_ResumeVisitNoteWorkflowResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply0.patient.audit.etag
                    $0.updatedBy = reply0.patient.audit.updatedBy
                }
                $0.billingAddress = input.visitNote.billingAddress
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = reply1.videoVisit.organizer.displayName
                }
                $0.visitNoteID = input.visitNoteID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processRetryVisitNoteWorkflow(_ input: Acme_Telehealth_V1_RetryVisitNoteWorkflowRequest) async throws
        -> Acme_Telehealth_V1_RetryVisitNoteWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "audit", detail: input.details.initiatedBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "RetryVisitNoteWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VisitNoteRecord(input.visitNote, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Telehealth_V1_CountVisitNotesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Telehealth_V1_CountVisitNotesRequest.Filter.with {
                $0.createdAfter = input.visitNote.audit.updatedAt
                $0.labels = input.details.parameters
                $0.region = input.visitNote.billingAddress.region
            }
        }
        let reply0 = try await RPCOperations.call(outbound0) { request in
            try await self.telehealthVisitNoteQuery.countVisitNotes(request)
        }
        let outbound1 = Acme_Telehealth_V1_GetVisitNoteRatesRequest.with {
            $0.context = Projection.read(input, at: \Acme_Telehealth_V1_RetryVisitNoteWorkflowRequest.context)
            $0.visitNoteID = Projection.read(
                input, at: \Acme_Telehealth_V1_RetryVisitNoteWorkflowRequest.visitNote.visitNoteID)
        }
        let reply1 = try await self.telehealthVisitNoteCalculation.getVisitNoteRates(outbound1)
        return Acme_Telehealth_V1_RetryVisitNoteWorkflowResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.result.message
                $0.referenceIds = reply1.result.referenceIds
                $0.status = "ok"
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.dueAt = input.visitNote.dueAt
                $0.visitNoteID = input.visitNoteID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processSignalVisitNoteWorkflow(_ input: Acme_Telehealth_V1_SignalVisitNoteWorkflowRequest) async throws
        -> Acme_Telehealth_V1_SignalVisitNoteWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "audit", detail: input.details.initiatedBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SignalVisitNoteWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VisitNoteRecord(input.visitNote, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Telehealth_V1_PreviewVideoVisitRequest.with {
            $0.context = input.context
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = input.visitNote.audit.updatedAt
                }
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.email = input.visitNote.counterparty.email
                }
            }
        }
        let step0: @Sendable () async throws -> Acme_Telehealth_V1_PreviewVideoVisitResponse = {
            try await self.telehealthVideoVisitValidation.previewVideoVisit(outbound0)
        }
        let reply0 = try await step0()
        var outbound1 = Acme_Telehealth_V1_QuoteVideoVisitRequest()
        outbound1.context = input.context
        outbound1.details = Acme_Telehealth_V1_QuoteVideoVisitRequest.Details.with {
            $0.destination = Acme_Common_V1_PostalAddress.with {
                $0.postalCode = input.visitNote.billingAddress.postalCode
            }
        }
        outbound1.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
            $0.location = Acme_Common_V1_PostalAddress.with {
                $0.countryCode = reply0.videoVisit.location.countryCode
            }
            $0.organizer = Acme_Identity_V1_UserRef.with {
                $0.email = reply0.videoVisit.organizer.email
            }
            $0.participants = [
                Acme_Telehealth_V1_VideoVisitParticipant.with {
                    $0.contact = Acme_Common_V1_ContactInfo.with {
                        $0.name = input.details.notify.name
                    }
                }
            ]
        }
        let reply1 = try await self.telehealthVideoVisitCalculation.quoteVideoVisit(outbound1)
        return Acme_Telehealth_V1_SignalVisitNoteWorkflowResponse.with {
            $0.outcome = Acme_Telehealth_V1_SignalVisitNoteWorkflowResponse.Outcome.with {
                $0.message = reply1.result.message
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply0.videoVisit.audit.createdAt
                }
                $0.status = input.visitNote.status
                $0.visitNoteID = input.visitNoteID
            }
        }
    }

    /// Execute the telehealth workflow and project its upstream replies.
    func processStartVisitNoteWorkflow(_ input: Acme_Telehealth_V1_StartVisitNoteWorkflowRequest) async throws
        -> Acme_Telehealth_V1_StartVisitNoteWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "visit_note",
            action: "audit", detail: input.details.initiatedBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "StartVisitNoteWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try VisitNoteRecord(input.visitNote, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Telehealth_V1_ApproveVideoVisitRequest.with {
            $0.context = input.context
            $0.details = Acme_Telehealth_V1_ApproveVideoVisitRequest.Details.with {
                $0.approver = Acme_Identity_V1_UserRef.with {
                    $0.email = input.details.notify.email
                }
            }
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = input.visitNote.audit.updatedAt
                }
                $0.participants = [
                    Acme_Telehealth_V1_VideoVisitParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.name = input.details.notify.name
                        }
                    }
                ]
            }
        }
        let step0: @Sendable () async throws -> Acme_Telehealth_V1_ApproveVideoVisitResponse = {
            try await self.telehealthVideoVisitApproval.approveVideoVisit(outbound0)
        }
        let reply0 = try await step0()
        return Acme_Telehealth_V1_StartVisitNoteWorkflowResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply0.outcome.status
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.metadata = input.visitNote.metadata
                $0.visitNoteID = input.visitNoteID
            }
        }
    }
}
