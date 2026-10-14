import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension PatientSyncEndpoint {
    /// Returns a patient.
    func getPatientSyncState(
        request: ServerRequest<Acme_Patients_V1_GetPatientSyncStateRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_GetPatientSyncStateResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetPatientSyncState(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists patients a page at a time.
    func listPatientConflicts(
        request: ServerRequest<Acme_Patients_V1_ListPatientConflictsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_ListPatientConflictsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListPatientConflicts(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Pulls a patient.
    func pullPatients(
        request: ServerRequest<Acme_Patients_V1_PullPatientsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_PullPatientsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processPullPatients(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Pushs a patient.
    func pushPatient(
        request: ServerRequest<Acme_Patients_V1_PushPatientRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_PushPatientResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processPushPatient(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Reconciles a patient.
    func reconcilePatients(
        request: ServerRequest<Acme_Patients_V1_ReconcilePatientsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_ReconcilePatientsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processReconcilePatients(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Resolves a patient.
    func resolvePatientConflict(
        request: ServerRequest<Acme_Patients_V1_ResolvePatientConflictRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_ResolvePatientConflictResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processResolvePatientConflict(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Exchanges changes of patients with a peer.
    func streamPatientChanges(
        request: StreamingServerRequest<Acme_Patients_V1_StreamPatientChangesRequest>,
        context: ServerContext
    ) async throws -> StreamingServerResponse<Acme_Patients_V1_StreamPatientChangesResponse> {
        return StreamingServerResponse { writer in
            try await CallerScope.$metadata.withValue(request.metadata) {
                for try await message in request.messages {
                    let response = try await self.processStreamPatientChanges(message)
                    try await writer.write(response)
                }
                return [:]
            }
        }
    }

    /// Syncs a patient.
    func syncPatients(
        request: ServerRequest<Acme_Patients_V1_SyncPatientsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_SyncPatientsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSyncPatients(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processGetPatientSyncState(_ input: Acme_Patients_V1_GetPatientSyncStateRequest) async throws
        -> Acme_Patients_V1_GetPatientSyncStateResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "GetPatientSyncState",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "GetPatientSyncState", detail: input.context.traceID
        )
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        let archive = Data(try input.context.jsonString().utf8)
        let restoredContext = try Acme_Common_V1_RequestContext(
            jsonString: String(decoding: archive, as: UTF8.self)
        )
        _ = try await self.prescriptionsPrescriptionSync.reconcilePrescriptions(
            Acme_Prescriptions_V1_ReconcilePrescriptionsRequest.with {
                $0.context = restoredContext
                $0.details = Acme_Prescriptions_V1_ReconcilePrescriptionsRequest.Details.with {
                    $0.payload = archive
                }
            })
        let outbound0 = Acme_Prescriptions_V1_SubmitRefillRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_SubmitRefillRequest.Details.with {
                $0.approver = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.context.actor.userID
                }
            }
        }
        let reply0 = try await RPCOperations.call(outbound0) { request in
            try await self.prescriptionsRefillApproval.submitRefill(request)
        }
        return Acme_Patients_V1_GetPatientSyncStateResponse.with {
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.patientID = input.patientID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processListPatientConflicts(_ input: Acme_Patients_V1_ListPatientConflictsRequest) async throws
        -> Acme_Patients_V1_ListPatientConflictsResponse
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
            "ListPatientConflicts",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "ListPatientConflicts", detail: input.context.traceID
        )
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        return Acme_Patients_V1_ListPatientConflictsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processPullPatients(_ input: Acme_Patients_V1_PullPatientsRequest) async throws
        -> Acme_Patients_V1_PullPatientsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.checksum)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "audit", detail: input.details.checksum
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "PullPatients",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PatientRecord(input.patient, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Payments_V1_QuotePaymentRequest.with {
            $0.context = Projection.read(input, at: \Acme_Patients_V1_PullPatientsRequest.context)
            $0.payment = Acme_Payments_V1_Payment.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = Projection.read(
                        input, at: \Acme_Patients_V1_PullPatientsRequest.patient.primaryAddress.region)
                }
            }
        }
        let reply0 = try await self.paymentsPaymentCalculation.quotePayment(outbound0)
        let outbound1 = Acme_Patients_V1_CheckAllergyEligibilityRequest.with {
            $0.context = input.context
            $0.details = Acme_Patients_V1_CheckAllergyEligibilityRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.patient.contact.email
                    $0.phone = input.patient.contact.phone
                    $0.preferredChannel = input.patient.contact.preferredChannel
                }
            }
        }
        let step1: @Sendable () async throws -> Acme_Patients_V1_CheckAllergyEligibilityResponse = {
            try await self.patientsAllergyValidation.checkAllergyEligibility(outbound1)
        }
        let reply1 = try await step1()
        var outbound2 = Acme_Featureflags_V1_PreviewFeatureFlagRequest()
        outbound2.context = input.context
        outbound2.featureFlag = Acme_Featureflags_V1_FeatureFlag.with {
            $0.owner = Acme_Identity_V1_UserRef.with {
                $0.displayName = input.patient.relationshipManager.displayName
            }
        }
        let reply2 = try await self.featureflagsFeatureFlagValidation.previewFeatureFlag(outbound2)
        return Acme_Patients_V1_PullPatientsResponse.with {
            $0.outcome = Acme_Patients_V1_PullPatientsResponse.Outcome.with {
                $0.nextSteps = reply1.outcome.nextSteps + reply2.outcome.nextSteps
            }
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.name = input.patient.name
                $0.patientID = input.patientID
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.lines = reply0.payment.billingAddress.lines
                    $0.region = reply0.payment.billingAddress.region
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processPushPatient(_ input: Acme_Patients_V1_PushPatientRequest) async throws
        -> Acme_Patients_V1_PushPatientResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.checksum)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "audit", detail: input.details.checksum
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "PushPatient",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PatientRecord(input.patient, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Venues_V1_CheckVenueEligibilityRequest.with {
            $0.context = input.context
            $0.venue = Acme_Venues_V1_Venue.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = input.patient.audit.updatedBy
                }
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.patient.relationshipManager.displayName
                }
            }
        }
        let step0: @Sendable () async throws -> Acme_Venues_V1_CheckVenueEligibilityResponse = {
            try await self.venuesVenueValidation.checkVenueEligibility(outbound0)
        }
        let reply0 = try await step0()
        let outbound1 = Acme_Careplans_V1_ResumeVitalWorkflowRequest.with {
            $0.context = input.context
            $0.details = Acme_Careplans_V1_ResumeVitalWorkflowRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.preferredChannel = input.patient.contact.preferredChannel
                }
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.attributes = input.patient.attributes
                $0.subject = Acme_Appointments_V1_AppointmentRef.with {
                    $0.displayName = reply0.venue.owner.displayName
                }
            }
        }
        let reply1 = try await self.careplansVitalWorkflow.resumeVitalWorkflow(outbound1)
        let outbound2 = Acme_Venues_V1_LintVenuesRequest.with {
            $0.context = input.context
            $0.details = Acme_Venues_V1_LintVenuesRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.patient.relationshipManager.email
                    $0.phone = input.patient.contact.phone
                }
            }
            $0.venue = Acme_Venues_V1_Venue.with {
                $0.dimensions = Acme_Venues_V1_VenueDimensions.with {
                    $0.width = reply0.venue.dimensions.width
                }
            }
        }
        async let remote2 = self.venuesVenueValidation.lintVenues(outbound2)
        async let persisted2 = store.count(tenant: input.context.tenantID)
        let (reply2, count2) = try await (remote2, persisted2)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count2)])
        let selection3_1: String
        switch reply2.venue.locator {
        case .address(let address):
            selection3_1 = address.region
        default: selection3_1 = .init()
        }
        let outbound3 = Acme_Patients_V1_LintMedicalRecordsRequest.with {
            $0.context = input.context
            $0.details = Acme_Patients_V1_LintMedicalRecordsRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.preferredChannel = input.patient.contact.preferredChannel
                }
            }
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = selection3_1
                }
            }
        }
        let reply3 = try await self.patientsMedicalRecordValidation.lintMedicalRecords(outbound3)
        return Acme_Patients_V1_PushPatientResponse.with {
            $0.outcome = Acme_Patients_V1_PushPatientResponse.Outcome.with {
                $0.effectiveAt = reply1.outcome.effectiveAt
            }
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.attributes = input.patient.attributes
                $0.patientID = input.patientID
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.lines = reply0.venue.address.lines
                    $0.recipient = reply2.venue.address.recipient
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply3.result.correlationID
                $0.details = reply1.result.details
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processReconcilePatients(_ input: Acme_Patients_V1_ReconcilePatientsRequest) async throws
        -> Acme_Patients_V1_ReconcilePatientsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.checksum)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "audit", detail: input.details.checksum
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ReconcilePatients",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PatientRecord(input.patient, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Patients_V1_ResolveMedicalRecordsRequest.with {
            $0.context = input.context
        }
        let reply0 = try await self.reconcilePatientsStep0.execute(outbound0)
        let outbound1 = Acme_Prescriptions_V1_ResumePrescriptionWorkflowRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_ResumePrescriptionWorkflowRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.patient.contact.email
                }
            }
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.patient.audit.createdAt
                    $0.etag = input.patient.audit.etag
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.email = input.patient.relationshipManager.email
                }
            }
        }
        let port1 = RPCOperations.port { (request: Acme_Prescriptions_V1_ResumePrescriptionWorkflowRequest) in
            try await self.prescriptionsPrescriptionWorkflow.resumePrescriptionWorkflow(request)
        }
        let reply1 = try await port1.execute(outbound1)
        let outbound2 = Acme_Patients_V1_SummarizeMedicalRecordsRequest.with {
            $0.annotations = input.annotations
            $0.context = input.context
            $0.details = Acme_Patients_V1_SummarizeMedicalRecordsRequest.Details.with {
                $0.period = input.patient.preferences.quietHours
            }
            $0.reason = input.reason
        }
        let reply2 = try await self.reconcilePatientsStep2(outbound2)
        return Acme_Patients_V1_ReconcilePatientsResponse.with {
            $0.outcome = Acme_Patients_V1_ReconcilePatientsResponse.Outcome.with {
                $0.status = reply2.result.status
            }
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply1.prescription.audit.updatedBy
                }
                $0.patientID = input.patientID
                $0.primaryAddress = input.patient.primaryAddress
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply0.result.referenceIds
                $0.status = Projection.firstValue(
                    [
                        reply1.outcome.status,
                        reply2.result.status,
                    ], default: .init())
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processResolvePatientConflict(_ input: Acme_Patients_V1_ResolvePatientConflictRequest) async throws
        -> Acme_Patients_V1_ResolvePatientConflictResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.checksum)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "audit", detail: input.details.checksum
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ResolvePatientConflict",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PatientRecord(input.patient, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Patients_V1_NormalizeAllergyRequest.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.attributes = input.patient.attributes
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = input.patient.relationshipManager.displayName
                    $0.email = input.patient.contact.email
                }
            }
            $0.context = input.context
            $0.details = Acme_Patients_V1_NormalizeAllergyRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.phone = input.patient.contact.phone
                }
            }
        }
        guard
            let execute0 = self.resolvePatientConflictStep0[settings.region]
                ?? self.resolvePatientConflictStep0["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply0 = try await execute0(outbound0)
        let selection1_1: String
        switch input.patient.identityDocument {
        case .nationalID(let nationalID):
            selection1_1 = nationalID.number
        default: selection1_1 = .init()
        }
        let outbound1 = Acme_Treasury_V1_CreateCashPositionRequest.with {
            $0.cashPosition = Acme_Treasury_V1_CashPosition.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.name = input.patient.contact.name
                }
                $0.holder = Acme_Treasury_V1_FxHedgeRef.with {
                    $0.displayName = reply0.allergy.subject.displayName
                    $0.number = selection1_1
                }
            }
            $0.context = input.context
        }
        let reply1 = try await self.treasuryCashPosition.createCashPosition(outbound1)
        let outbound2 = Acme_Identity_V1_CloneUserRequest.with {
            $0.context = input.context
            $0.user = Acme_Identity_V1_User.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.patient.contact.email
                    $0.phone = input.patient.contact.phone
                    $0.preferredChannel = input.patient.contact.preferredChannel
                }
                $0.preferences = Acme_Identity_V1_UserPreferences.with {
                    $0.channels = input.patient.preferences.channels
                }
            }
        }
        let reply2 = try await self.identityUser.cloneUser(outbound2)
        return Acme_Patients_V1_ResolvePatientConflictResponse.with {
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply0.allergy.subject.email
                    $0.phone = reply2.user.contact.phone
                    $0.preferredChannel = reply2.user.contact.preferredChannel
                }
                $0.name = input.patient.name
                $0.patientID = input.patientID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply1.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processStreamPatientChanges(_ input: Acme_Patients_V1_StreamPatientChangesRequest) async throws
        -> Acme_Patients_V1_StreamPatientChangesResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.ack.status)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "audit", detail: input.ack.status
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "StreamPatientChanges",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "StreamPatientChanges", detail: input.context.traceID
        )
        let selection0_1: String
        switch input.frame {
        case .change(let change):
            selection0_1 = change.contact.preferredChannel
        default: selection0_1 = .init()
        }
        let selection0_2: String
        switch input.frame {
        case .change(let change):
            selection0_2 = change.contact.phone
        default: selection0_2 = .init()
        }
        let outbound0 = Acme_Appointments_V1_ApproveClinicSlotRequest.with {
            $0.clinicSlot = Acme_Appointments_V1_ClinicSlot.with {
                $0.participants = [
                    Acme_Appointments_V1_ClinicSlotParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.phone = selection0_2
                            $0.preferredChannel = selection0_1
                        }
                    }
                ]
            }
            $0.context = input.context
        }
        let reply0 = try await self.appointmentsClinicSlotApproval.approveClinicSlot(outbound0)
        let outbound1 = Acme_Prescriptions_V1_StreamMedicationMetricsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Prescriptions_V1_StreamMedicationMetricsRequest.Filter.with {
                $0.region = input.change.primaryAddress.region
            }
            $0.subscriber = Acme_Common_V1_ContactInfo.with {
                $0.email = reply0.clinicSlot.organizer.email
                $0.name = input.change.contact.name
                $0.phone = input.change.contact.phone
            }
        }
        let reply1 = try await self.prescriptionsMedicationReporting.streamMedicationMetrics(outbound1) { response in
            var latest = Acme_Prescriptions_V1_StreamMedicationMetricsResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        _ = reply1
        return Acme_Patients_V1_StreamPatientChangesResponse.with {
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.relationshipManager = input.change.relationshipManager
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply0.result.referenceIds
                $0.status = reply0.outcome.status
            }
            $0.sequence = input.ack.sequence
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processSyncPatients(_ input: Acme_Patients_V1_SyncPatientsRequest) async throws
        -> Acme_Patients_V1_SyncPatientsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.checksum)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "audit", detail: input.details.checksum
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SyncPatients",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PatientRecord(input.patient, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Prescriptions_V1_ShareRefillReportRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_ShareRefillReportRequest.Details.with {
                $0.recipient = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.patient.contact.email
                }
            }
        }
        let envelope0 = try Google_Protobuf_Any(message: outbound0)
        let unpacked0 = try Acme_Prescriptions_V1_ShareRefillReportRequest(unpackingAny: envelope0)
        let reply0 = try await self.prescriptionsRefillReporting.shareRefillReport(unpacked0)
        let outbound1 = Acme_Identity_V1_WatchUsersRequest.with {
            $0.context = input.context
            $0.filter = Acme_Identity_V1_WatchUsersRequest.Filter.with {
                $0.region = input.patient.primaryAddress.region
            }
            $0.subscriber = Acme_Common_V1_ContactInfo.with {
                $0.email = reply0.refill.requester.email
                $0.phone = input.patient.contact.phone
                $0.preferredChannel = reply0.refill.requester.preferredChannel
            }
        }
        let reply1 = try await self.identityUser.watchUsers(outbound1) { response in
            var latest = Acme_Identity_V1_WatchUsersResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        _ = reply1
        let outbound2 = Acme_Documents_V1_BatchGetDocumentsRequest.with {
            $0.context = input.context
        }
        let json2 = try outbound2.jsonString()
        let decoded2 = try Acme_Documents_V1_BatchGetDocumentsRequest(jsonString: json2)
        let reply2 = try await self.documentsDocument.batchGetDocuments(decoded2)
        let outbound3 = Acme_Notifications_V1_SearchNotificationsRequest.forPatientSyncEndpointSyncPatients3(
            input,
            reply0: reply0
        )
        let reply3 = try await self.notificationsNotification.searchNotifications(outbound3)
        return Acme_Patients_V1_SyncPatientsResponse.with {
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply0.refill.audit.createdAt
                }
                $0.patientID = input.patientID
                $0.status = input.patient.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply2.result.details
                $0.message = reply2.result.message
                $0.status = reply3.result.status
            }
        }
    }
}
