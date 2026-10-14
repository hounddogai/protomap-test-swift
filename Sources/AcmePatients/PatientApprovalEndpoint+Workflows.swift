import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension PatientApprovalEndpoint {
    /// Approves a patient.
    func approvePatient(
        request: ServerRequest<Acme_Patients_V1_ApprovePatientRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_ApprovePatientResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processApprovePatient(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Delegates a patient.
    func delegatePatientApproval(
        request: ServerRequest<Acme_Patients_V1_DelegatePatientApprovalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_DelegatePatientApprovalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processDelegatePatientApproval(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Escalates a patient.
    func escalatePatient(
        request: ServerRequest<Acme_Patients_V1_EscalatePatientRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_EscalatePatientResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processEscalatePatient(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a patient.
    func getPatientApprovalStatus(
        request: ServerRequest<Acme_Patients_V1_GetPatientApprovalStatusRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_GetPatientApprovalStatusResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetPatientApprovalStatus(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists patients a page at a time.
    func listPendingPatients(
        request: ServerRequest<Acme_Patients_V1_ListPendingPatientsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_ListPendingPatientsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListPendingPatients(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Recalls a patient.
    func recallPatient(
        request: ServerRequest<Acme_Patients_V1_RecallPatientRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_RecallPatientResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRecallPatient(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Rejects a patient.
    func rejectPatient(
        request: ServerRequest<Acme_Patients_V1_RejectPatientRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_RejectPatientResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRejectPatient(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Submits a patient.
    func submitPatient(
        request: ServerRequest<Acme_Patients_V1_SubmitPatientRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_SubmitPatientResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSubmitPatient(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processApprovePatient(_ input: Acme_Patients_V1_ApprovePatientRequest) async throws
        -> Acme_Patients_V1_ApprovePatientResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "audit", detail: input.details.approver.email
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ApprovePatient",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PatientRecord(input.patient, tenant: input.context.tenantID)
        try await store.save(record.stored)
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        let archive = Data(try input.context.jsonString().utf8)
        let restoredContext = try Acme_Common_V1_RequestContext(
            jsonString: String(decoding: archive, as: UTF8.self)
        )
        _ = try await self.patientsMedicalRecordSync.resolveMedicalRecordConflict(
            Acme_Patients_V1_ResolveMedicalRecordConflictRequest.with {
                $0.context = restoredContext
                $0.details = Acme_Patients_V1_ResolveMedicalRecordConflictRequest.Details.with {
                    $0.payload = archive
                }
            })
        let outbound0 = Acme_Prescriptions_V1_ApproveRefillRequest.with {
            $0.context = input.context
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.email = input.patient.contact.email
                    $0.userID = input.patient.relationshipManager.userID
                }
                $0.customer = Acme_Prescriptions_V1_PrescriptionRef.with {
                    $0.displayName = input.details.approver.displayName
                }
            }
        }
        async let remote0 = self.prescriptionsRefillApproval.approveRefill(outbound0)
        async let persisted0 = store.count(tenant: input.context.tenantID)
        let (reply0, count0) = try await (remote0, persisted0)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count0)])
        return Acme_Patients_V1_ApprovePatientResponse.with {
            $0.outcome = Acme_Patients_V1_ApprovePatientResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
            }
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply0.refill.audit.etag
                }
                $0.patientID = input.patientID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processDelegatePatientApproval(_ input: Acme_Patients_V1_DelegatePatientApprovalRequest) async throws
        -> Acme_Patients_V1_DelegatePatientApprovalResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "audit", detail: input.details.approver.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "DelegatePatientApproval",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PatientRecord(input.patient, tenant: input.context.tenantID)
        try await store.save(record.stored)
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        let outbound0 = Acme_Authorization_V1_ScoreAccessPolicyRequest.with {
            $0.accessPolicy = Acme_Authorization_V1_AccessPolicy.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = input.patient.audit.createdBy
                }
            }
            $0.context = input.context
            $0.details = Acme_Authorization_V1_ScoreAccessPolicyRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = input.patient.primaryAddress.countryCode
                    $0.lines = input.patient.primaryAddress.lines
                }
            }
        }
        let reply0 = try await self.delegatePatientApprovalStep0.execute(outbound0)
        return Acme_Patients_V1_DelegatePatientApprovalResponse.with {
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.name = input.patient.name
                }
                $0.patientID = input.patientID
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply0.accessPolicy.owner.displayName
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processEscalatePatient(_ input: Acme_Patients_V1_EscalatePatientRequest) async throws
        -> Acme_Patients_V1_EscalatePatientResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "audit", detail: input.details.approver.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "EscalatePatient",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PatientRecord(input.patient, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Appointments_V1_EscalateAppointmentRequest.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.participants = [
                    Acme_Appointments_V1_AppointmentParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = input.patient.relationshipManager.email
                            $0.name = input.patient.contact.name
                            $0.preferredChannel = input.patient.contact.preferredChannel
                        }
                    }
                ]
            }
            $0.context = input.context
        }
        let port0 = RPCOperations.port { (request: Acme_Appointments_V1_EscalateAppointmentRequest) in
            try await self.appointmentsAppointmentApproval.escalateAppointment(request)
        }
        let reply0 = try await port0.execute(outbound0)
        let outbound1 = Acme_Careplans_V1_EscalateCareGoalRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.details.approver.userID
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = input.patient.audit.etag
                }
            }
            $0.context = input.context
        }
        let reply1 = try await self.escalatePatientStep1(outbound1)
        return Acme_Patients_V1_EscalatePatientResponse.with {
            $0.outcome = Acme_Patients_V1_EscalatePatientResponse.Outcome.with {
                $0.status = reply0.result.status
            }
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.contact = input.patient.contact
                $0.patientID = input.patientID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply1.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processGetPatientApprovalStatus(_ input: Acme_Patients_V1_GetPatientApprovalStatusRequest) async throws
        -> Acme_Patients_V1_GetPatientApprovalStatusResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "GetPatientApprovalStatus",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "GetPatientApprovalStatus", detail: input.context.traceID
        )
        let outbound0 = Acme_Appointments_V1_RejectAppointmentRequest.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = input.context.deadline
                }
                $0.participants = [
                    Acme_Appointments_V1_AppointmentParticipant.with {
                        $0.participantID = input.patientID
                    }
                ]
            }
            $0.context = input.context
            $0.details = Acme_Appointments_V1_RejectAppointmentRequest.Details.with {
                $0.approver = Acme_Identity_V1_UserRef.with {
                    $0.email = input.context.actor.email
                    $0.userID = input.context.actor.userID
                }
            }
        }
        guard
            let execute0 = self.getPatientApprovalStatusStep0[settings.region]
                ?? self.getPatientApprovalStatusStep0["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply0 = try await execute0(outbound0)
        return Acme_Patients_V1_GetPatientApprovalStatusResponse.with {
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.patientID = input.patientID
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = reply0.appointment.location.postalCode
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processListPendingPatients(_ input: Acme_Patients_V1_ListPendingPatientsRequest) async throws
        -> Acme_Patients_V1_ListPendingPatientsResponse
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
            "ListPendingPatients",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "ListPendingPatients", detail: input.context.traceID
        )
        let outbound0 = Acme_Search_V1_CheckSearchIndexEligibilityRequest.with {
            $0.context = input.context
            $0.details = Acme_Search_V1_CheckSearchIndexEligibilityRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.context.actor.email
                }
            }
            $0.searchIndex = Acme_Search_V1_SearchIndex.with {
                $0.address = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
            }
        }
        let reply0 = try await self.searchSearchIndexValidation.checkSearchIndexEligibility(outbound0)
        let outbound1 = Acme_Patients_V1_PushAllergyRequest.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.measurements = [
                    Acme_Patients_V1_AllergyMeasurement.with {
                        $0.unit = reply0.searchIndex.dimensions.unit
                    }
                ]
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.email = reply0.searchIndex.owner.email
                }
            }
            $0.context = input.context
        }
        let envelope1 = try Google_Protobuf_Any(message: outbound1)
        let unpacked1 = try Acme_Patients_V1_PushAllergyRequest(unpackingAny: envelope1)
        let reply1 = try await self.patientsAllergySync.pushAllergy(unpacked1)
        return Acme_Patients_V1_ListPendingPatientsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = Projection.firstValue(
                    [
                        reply0.result.message,
                        reply1.result.message,
                    ], default: .init())
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processRecallPatient(_ input: Acme_Patients_V1_RecallPatientRequest) async throws
        -> Acme_Patients_V1_RecallPatientResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approverEmail)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "audit", detail: input.details.approverEmail
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "RecallPatient",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PatientRecord(input.patient, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let selection0_2: Google_Protobuf_Timestamp
        switch input.patient.identityDocument {
        case .passport(let passport):
            selection0_2 = passport.expiresAt
        default: selection0_2 = .init()
        }
        let outbound0 = Acme_Patients_V1_CountPatientTotalsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Patients_V1_CountPatientTotalsRequest.Filter.with {
                $0.createdAfter = selection0_2
                $0.ownerID = input.details.approver.userID
                $0.region = input.patient.primaryAddress.region
            }
        }
        let reply0 = try await self.patientsPatientReporting.countPatientTotals(outbound0)
        let outbound1 = Acme_Careplans_V1_ApproveCareGoalRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.patient.relationshipManager.displayName
                }
                $0.comments = [
                    Acme_Careplans_V1_CareGoalComment.with {
                        $0.createdAt = input.patient.audit.createdAt
                    }
                ]
                $0.customer = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = input.details.approver.displayName
                    $0.email = input.details.approver.email
                }
            }
            $0.context = input.context
        }
        let json1 = try outbound1.jsonString()
        let decoded1 = try Acme_Careplans_V1_ApproveCareGoalRequest(jsonString: json1)
        let reply1 = try await self.careplansCareGoalApproval.approveCareGoal(decoded1)
        return Acme_Patients_V1_RecallPatientResponse.with {
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply1.careGoal.audit.createdAt
                }
                $0.name = input.patient.name
                $0.patientID = input.patientID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.status = reply0.result.status
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processRejectPatient(_ input: Acme_Patients_V1_RejectPatientRequest) async throws
        -> Acme_Patients_V1_RejectPatientResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "audit", detail: input.details.approver.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "RejectPatient",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PatientRecord(input.patient, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Patients_V1_CompareAllergyOptionsRequest.forPatientApprovalEndpointRejectPatient0(
            input
        )
        let reply0 = try await self.patientsAllergyCalculation.compareAllergyOptions(outbound0)
        let outbound1 = Acme_Patients_V1_ListPatientConflictsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Patients_V1_ListPatientConflictsRequest.Filter.with {
                $0.region = input.patient.primaryAddress.region
            }
        }
        let reply1 = try await self.patientsPatientSync.listPatientConflicts(
            outbound1, metadata: ["x-acme-region": .string(settings.region)]
        )
        return Acme_Patients_V1_RejectPatientResponse.with {
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply0.allergy.subject.email
                    $0.name = input.patient.name
                }
                $0.patientID = input.patientID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply1.result.status
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processSubmitPatient(_ input: Acme_Patients_V1_SubmitPatientRequest) async throws
        -> Acme_Patients_V1_SubmitPatientResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.approver.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "audit", detail: input.details.approver.displayName
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SubmitPatient",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PatientRecord(input.patient, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Careplans_V1_SubmitCareGoalRequest.with {
            $0.context = input.context
            $0.details = Acme_Careplans_V1_SubmitCareGoalRequest.Details.with {
                $0.approver = Acme_Identity_V1_UserRef.with {
                    $0.email = input.patient.contact.email
                }
            }
        }
        let reply0 = try await RPCOperations.call(outbound0) { request in
            try await self.careplansCareGoalApproval.submitCareGoal(request)
        }
        let outbound1 = Acme_Itsm_V1_EstimateIncidentRequest.with {
            $0.context = Projection.read(input, at: \Acme_Patients_V1_SubmitPatientRequest.context)
            $0.details = Acme_Itsm_V1_EstimateIncidentRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = Projection.read(
                        input, at: \Acme_Patients_V1_SubmitPatientRequest.patient.primaryAddress.countryCode)
                }
            }
            $0.incident = Acme_Itsm_V1_Incident.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = Projection.read(input, at: \Acme_Patients_V1_SubmitPatientRequest.patient.audit.etag)
                }
                $0.customer = Acme_Employees_V1_EmployeeRef.with {
                    $0.displayName = Projection.read(
                        input, at: \Acme_Patients_V1_SubmitPatientRequest.patient.relationshipManager.displayName)
                    $0.email = Projection.read(
                        reply0, at: \Acme_Careplans_V1_SubmitCareGoalResponse.careGoal.assignee.email)
                }
            }
        }
        let reply1 = try await self.itsmIncidentCalculation.estimateIncident(outbound1)
        let outbound2 = Acme_Patients_V1_SimulateMedicalRecordRequest.with {
            $0.context = input.context
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.email = input.patient.contact.email
                }
            }
        }
        let step2: @Sendable () async throws -> Acme_Patients_V1_SimulateMedicalRecordResponse = {
            try await self.patientsMedicalRecordCalculation.simulateMedicalRecord(outbound2)
        }
        let reply2 = try await step2()
        var outbound3 = Acme_Patients_V1_BrowseMedicalRecordsRequest()
        outbound3.context = input.context
        outbound3.filter = Acme_Patients_V1_BrowseMedicalRecordsRequest.Filter.with {
            $0.createdAfter = reply2.medicalRecord.dueAt
            $0.region = input.patient.primaryAddress.region
        }
        let reply3 = try await self.patientsMedicalRecordQuery.browseMedicalRecords(outbound3)
        return Acme_Patients_V1_SubmitPatientResponse.with {
            $0.outcome = Acme_Patients_V1_SubmitPatientResponse.Outcome.with {
                $0.message = reply2.result.message
            }
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.attributes = input.patient.attributes
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply1.incident.customer.email
                }
                $0.patientID = input.patientID
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = reply2.medicalRecord.billingAddress.countryCode
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = Projection.firstValue(
                    [
                        reply0.result.message,
                        reply3.result.message,
                    ], default: .init())
                $0.status = reply3.result.status
            }
        }
    }
}
