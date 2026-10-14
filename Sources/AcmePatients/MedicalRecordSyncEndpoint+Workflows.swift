import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension MedicalRecordSyncEndpoint {
    /// Returns a medical record.
    func getMedicalRecordSyncState(
        request: ServerRequest<Acme_Patients_V1_GetMedicalRecordSyncStateRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_GetMedicalRecordSyncStateResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetMedicalRecordSyncState(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists medical records a page at a time.
    func listMedicalRecordConflicts(
        request: ServerRequest<Acme_Patients_V1_ListMedicalRecordConflictsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_ListMedicalRecordConflictsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListMedicalRecordConflicts(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Pushs a medical record.
    func pushMedicalRecord(
        request: ServerRequest<Acme_Patients_V1_PushMedicalRecordRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_PushMedicalRecordResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processPushMedicalRecord(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Reconciles a medical record.
    func reconcileMedicalRecords(
        request: ServerRequest<Acme_Patients_V1_ReconcileMedicalRecordsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_ReconcileMedicalRecordsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processReconcileMedicalRecords(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Resolves a medical record.
    func resolveMedicalRecordConflict(
        request: ServerRequest<Acme_Patients_V1_ResolveMedicalRecordConflictRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_ResolveMedicalRecordConflictResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processResolveMedicalRecordConflict(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Exchanges changes of medical records with a peer.
    func streamMedicalRecordChanges(
        request: StreamingServerRequest<Acme_Patients_V1_StreamMedicalRecordChangesRequest>,
        context: ServerContext
    ) async throws -> StreamingServerResponse<Acme_Patients_V1_StreamMedicalRecordChangesResponse> {
        return StreamingServerResponse { writer in
            try await CallerScope.$metadata.withValue(request.metadata) {
                for try await message in request.messages {
                    let response = try await self.processStreamMedicalRecordChanges(message)
                    try await writer.write(response)
                }
                return [:]
            }
        }
    }

    /// Syncs a medical record.
    func syncMedicalRecords(
        request: ServerRequest<Acme_Patients_V1_SyncMedicalRecordsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_SyncMedicalRecordsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSyncMedicalRecords(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processGetMedicalRecordSyncState(_ input: Acme_Patients_V1_GetMedicalRecordSyncStateRequest) async throws
        -> Acme_Patients_V1_GetMedicalRecordSyncStateResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "GetMedicalRecordSyncState",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "GetMedicalRecordSyncState", detail: input.context.traceID
        )
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        try followUps.submit(
            Acme_Identity_V1_GetUserRequest.with {
                $0.context = input.context
                $0.userID = input.context.actor.userID
            })
        let archive = Data(try input.context.jsonString().utf8)
        let restoredContext = try Acme_Common_V1_RequestContext(
            jsonString: String(decoding: archive, as: UTF8.self)
        )
        _ = try await self.prescriptionsMedicationSync.pullMedications(
            Acme_Prescriptions_V1_PullMedicationsRequest.with {
                $0.context = restoredContext
                $0.details = Acme_Prescriptions_V1_PullMedicationsRequest.Details.with {
                    $0.payload = archive
                }
            })
        let outbound0 = Acme_Documents_V1_FindDocumentsRequest.with {
            $0.context = Projection.read(input, at: \Acme_Patients_V1_GetMedicalRecordSyncStateRequest.context)
            $0.filter = Acme_Documents_V1_FindDocumentsRequest.Filter.with {
                $0.ownerID = Projection.read(
                    input, at: \Acme_Patients_V1_GetMedicalRecordSyncStateRequest.medicalRecordID)
            }
        }
        let reply0 = try await self.documentsDocumentQuery.findDocuments(outbound0)
        return Acme_Patients_V1_GetMedicalRecordSyncStateResponse.with {
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.medicalRecordID = input.medicalRecordID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processListMedicalRecordConflicts(_ input: Acme_Patients_V1_ListMedicalRecordConflictsRequest) async throws
        -> Acme_Patients_V1_ListMedicalRecordConflictsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ListMedicalRecordConflicts",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "ListMedicalRecordConflicts", detail: input.context.traceID
        )
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        return Acme_Patients_V1_ListMedicalRecordConflictsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processPushMedicalRecord(_ input: Acme_Patients_V1_PushMedicalRecordRequest) async throws
        -> Acme_Patients_V1_PushMedicalRecordResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.checksum)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "audit", detail: input.details.checksum
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "PushMedicalRecord",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicalRecordRecord(input.medicalRecord, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Tours_V1_SummarizeToursRequest.with {
            $0.annotations = input.annotations
            $0.context = input.context
            $0.details = Acme_Tours_V1_SummarizeToursRequest.Details.with {
                $0.filters = input.medicalRecord.metadata
            }
            $0.reason = input.reason
        }
        let step0: @Sendable () async throws -> Acme_Tours_V1_SummarizeToursResponse = {
            try await self.toursTourQuery.summarizeTours(outbound0)
        }
        let reply0 = try await step0()
        return Acme_Patients_V1_PushMedicalRecordResponse.with {
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.billingAddress = input.medicalRecord.billingAddress
                $0.medicalRecordID = input.medicalRecordID
            }
            $0.outcome = Acme_Patients_V1_PushMedicalRecordResponse.Outcome.with {
                $0.message = reply0.result.message
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processReconcileMedicalRecords(_ input: Acme_Patients_V1_ReconcileMedicalRecordsRequest) async throws
        -> Acme_Patients_V1_ReconcileMedicalRecordsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.checksum)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "audit", detail: input.details.checksum
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ReconcileMedicalRecords",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicalRecordRecord(input.medicalRecord, tenant: input.context.tenantID)
        try await store.save(record.stored)
        var outbound0 = Acme_Careplans_V1_CommentVitalApprovalRequest()
        outbound0.context = input.context
        outbound0.details = Acme_Careplans_V1_CommentVitalApprovalRequest.Details.with {
            $0.approver = Acme_Identity_V1_UserRef.with {
                $0.email = input.medicalRecord.counterparty.email
            }
        }
        outbound0.reason = input.reason
        outbound0.vital = Acme_Careplans_V1_Vital.with {
            $0.subject = Acme_Appointments_V1_AppointmentRef.with {
                $0.displayName = input.medicalRecord.counterparty.displayName
            }
        }
        let reply0 = try await self.careplansVitalApproval.commentVitalApproval(outbound0)
        let outbound1 = Acme_Patients_V1_EstimateAllergyRequest.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.occurredAt = reply0.vital.occurredAt
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = reply0.vital.subject.displayName
                }
            }
            $0.context = input.context
            $0.details = Acme_Patients_V1_EstimateAllergyRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = input.medicalRecord.billingAddress.postalCode
                    $0.recipient = input.medicalRecord.billingAddress.recipient
                }
            }
        }
        let step1: @Sendable () async throws -> Acme_Patients_V1_EstimateAllergyResponse = {
            try await self.patientsAllergyCalculation.estimateAllergy(outbound1)
        }
        let reply1 = try await step1()
        let requests2 = input.medicalRecord.lines.map { element in
            Acme_Venues_V1_ScoreVenueRequest.with {
                $0.context = input.context
                $0.venue = Acme_Venues_V1_Venue.with {
                    $0.components = [
                        "primary": Acme_Venues_V1_VenueComponent.with {
                            $0.description_p = element.description_p
                            $0.quantity = element.quantity
                        }
                    ]
                }
            }
        }
        let replies2 = try await FanOut.map(requests2) { candidate in
            try await self.venuesVenueValidation.scoreVenue(candidate)
        }
        let reply2 = replies2.first ?? Acme_Venues_V1_ScoreVenueResponse()
        _ = reply2
        return Acme_Patients_V1_ReconcileMedicalRecordsResponse.with {
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.lines = [
                    Acme_Patients_V1_MedicalRecordLine.with {
                        $0.attributes = reply1.allergy.attributes
                    }
                ]
                $0.medicalRecordID = input.medicalRecordID
                $0.status = input.medicalRecord.status
                $0.total = reply1.breakdown.total
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processResolveMedicalRecordConflict(_ input: Acme_Patients_V1_ResolveMedicalRecordConflictRequest) async throws
        -> Acme_Patients_V1_ResolveMedicalRecordConflictResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.checksum)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "audit", detail: input.details.checksum
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ResolveMedicalRecordConflict",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicalRecordRecord(input.medicalRecord, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Careplans_V1_ListVitalWorkflowsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Careplans_V1_ListVitalWorkflowsRequest.Filter.with {
                $0.createdAfter = input.medicalRecord.issuedAt
                $0.region = input.medicalRecord.billingAddress.region
            }
        }
        let reply0 = try await self.careplansVitalWorkflow.listVitalWorkflows(outbound0)
        let outbound1 = Acme_Prescriptions_V1_ListPendingPrescriptionsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Prescriptions_V1_ListPendingPrescriptionsRequest.Filter.with {
                $0.region = input.medicalRecord.billingAddress.region
            }
        }
        async let remote1 = self.prescriptionsPrescriptionApproval.listPendingPrescriptions(outbound1)
        async let persisted1 = store.count(tenant: input.context.tenantID)
        let (reply1, count1) = try await (remote1, persisted1)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count1)])
        return Acme_Patients_V1_ResolveMedicalRecordConflictResponse.with {
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.medicalRecordID = input.medicalRecordID
                $0.notes = input.medicalRecord.notes
            }
            $0.outcome = Acme_Patients_V1_ResolveMedicalRecordConflictResponse.Outcome.with {
                $0.status = Projection.firstValue(
                    [
                        reply0.result.status,
                        reply1.result.status,
                    ], default: .init())
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply1.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processStreamMedicalRecordChanges(_ input: Acme_Patients_V1_StreamMedicalRecordChangesRequest) async throws
        -> Acme_Patients_V1_StreamMedicalRecordChangesResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.ack.status)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "audit", detail: input.ack.status
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "StreamMedicalRecordChanges",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "StreamMedicalRecordChanges", detail: input.context.traceID
        )
        let selection0_1: String
        switch input.frame {
        case .change(let change):
            selection0_1 = change.billingAddress.region
        default: selection0_1 = .init()
        }
        let selection0_2: Google_Protobuf_Timestamp
        switch input.frame {
        case .change(let change):
            selection0_2 = change.audit.updatedAt
        default: selection0_2 = .init()
        }
        let outbound0 = Acme_Patients_V1_SearchPatientsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Patients_V1_SearchPatientsRequest.Filter.with {
                $0.createdAfter = selection0_2
                $0.region = selection0_1
            }
        }
        let reply0 = try await self.patientsPatient.searchPatients(outbound0)
        let selection1_1: String
        switch input.frame {
        case .change(let change):
            selection1_1 = change.bank.accountHolder
        default: selection1_1 = .init()
        }
        let selection1_2: String
        switch input.frame {
        case .change(let change):
            selection1_2 = change.bank.bic
        default: selection1_2 = .init()
        }
        let outbound1 = Acme_Patients_V1_PreviewMedicalRecordRequest.with {
            $0.context = input.context
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.bank = Acme_Patients_V1_MedicalRecordBankSettlement.with {
                    $0.accountHolder = selection1_1
                    $0.bic = selection1_2
                }
            }
        }
        let reply1 = try await self.patientsMedicalRecordValidation.previewMedicalRecord(outbound1)
        return Acme_Patients_V1_StreamMedicalRecordChangesResponse.with {
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.issuedAt = input.change.issuedAt
                $0.metadata = input.change.metadata
                $0.notes = reply1.medicalRecord.notes
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.message = reply0.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processSyncMedicalRecords(_ input: Acme_Patients_V1_SyncMedicalRecordsRequest) async throws
        -> Acme_Patients_V1_SyncMedicalRecordsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.checksum)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "audit", detail: input.details.checksum
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SyncMedicalRecords",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicalRecordRecord(input.medicalRecord, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let requests0 = input.medicalRecord.lines.map { element in
            Acme_Patients_V1_NormalizeAllergyRequest.with {
                $0.allergy = Acme_Patients_V1_Allergy.with {
                    $0.attributes = element.attributes
                }
                $0.context = input.context
            }
        }
        let replies0 = try await FanOut.map(requests0) { candidate in
            try await self.patientsAllergyValidation.normalizeAllergy(candidate)
        }
        let reply0 = replies0.first ?? Acme_Patients_V1_NormalizeAllergyResponse()
        _ = reply0
        let outbound1 = Acme_Patients_V1_GetPatientRulesRequest.with {
            $0.context = input.context
            $0.patientID = input.medicalRecord.counterparty.patientID
        }
        let reply1 = try await self.syncMedicalRecordsStep1.execute(outbound1)
        return Acme_Patients_V1_SyncMedicalRecordsResponse.with {
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.counterparty = input.medicalRecord.counterparty
                $0.medicalRecordID = input.medicalRecordID
            }
            $0.outcome = Acme_Patients_V1_SyncMedicalRecordsResponse.Outcome.with {
                $0.message = reply1.result.message
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply1.result.details
                $0.status = "ok"
            }
        }
    }
}
