import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Moves a care plan between the states of its lifecycle.
final class CarePlanLifecycleEndpoint: Acme_Careplans_V1_CarePlanLifecycleService.ServiceProtocol {
    private let store: any RecordRepository
    private let logger: Logger
    private let settings: Settings
    private let admissionsAdmissionCalculation: Acme_Admissions_V1_AdmissionCalculationService.Client<MeshTransport>
    private let appointmentsAppointment: Acme_Appointments_V1_AppointmentService.Client<MeshTransport>
    private let appointmentsProviderValidation: Acme_Appointments_V1_ProviderValidationService.Client<MeshTransport>
    private let careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>
    private let careplansCareGoalValidation: Acme_Careplans_V1_CareGoalValidationService.Client<MeshTransport>
    private let careplansCarePlanCalculation: Acme_Careplans_V1_CarePlanCalculationService.Client<MeshTransport>
    private let careplansCarePlanQuery: Acme_Careplans_V1_CarePlanQueryService.Client<MeshTransport>
    private let careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client<MeshTransport>
    private let careplansVitalCalculation: Acme_Careplans_V1_VitalCalculationService.Client<MeshTransport>
    private let featureflagsFeatureFlagValidation:
        Acme_Featureflags_V1_FeatureFlagValidationService.Client<MeshTransport>
    private let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    private let ledgerLedgerAccountQuery: Acme_Ledger_V1_LedgerAccountQueryService.Client<MeshTransport>
    private let patientsMedicalRecordQuery: Acme_Patients_V1_MedicalRecordQueryService.Client<MeshTransport>
    private let patientsPatient: Acme_Patients_V1_PatientService.Client<MeshTransport>
    private let prescriptionsPrescriptionQuery: Acme_Prescriptions_V1_PrescriptionQueryService.Client<MeshTransport>
    private let recommendationsRecommendationSet: Acme_Recommendations_V1_RecommendationSetService.Client<MeshTransport>
    private let telehealthVisitNoteValidation: Acme_Telehealth_V1_VisitNoteValidationService.Client<MeshTransport>
    private let activateCarePlanStep1:
        @Sendable (Acme_Patients_V1_BrowseMedicalRecordsRequest) async throws ->
            Acme_Patients_V1_BrowseMedicalRecordsResponse
    private let expireCarePlanStep0:
        [String:
            @Sendable (Acme_Prescriptions_V1_SummarizePrescriptionsRequest) async throws ->
            Acme_Prescriptions_V1_SummarizePrescriptionsResponse]

    init(
        dependencies: any Dependencies,
        admissionsAdmissionCalculation: Acme_Admissions_V1_AdmissionCalculationService.Client<MeshTransport>,
        appointmentsAppointment: Acme_Appointments_V1_AppointmentService.Client<MeshTransport>,
        appointmentsProviderValidation: Acme_Appointments_V1_ProviderValidationService.Client<MeshTransport>,
        careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>,
        careplansCareGoalValidation: Acme_Careplans_V1_CareGoalValidationService.Client<MeshTransport>,
        careplansCarePlanCalculation: Acme_Careplans_V1_CarePlanCalculationService.Client<MeshTransport>,
        careplansCarePlanQuery: Acme_Careplans_V1_CarePlanQueryService.Client<MeshTransport>,
        careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client<MeshTransport>,
        careplansVitalCalculation: Acme_Careplans_V1_VitalCalculationService.Client<MeshTransport>,
        featureflagsFeatureFlagValidation: Acme_Featureflags_V1_FeatureFlagValidationService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        ledgerLedgerAccountQuery: Acme_Ledger_V1_LedgerAccountQueryService.Client<MeshTransport>,
        patientsMedicalRecordQuery: Acme_Patients_V1_MedicalRecordQueryService.Client<MeshTransport>,
        patientsPatient: Acme_Patients_V1_PatientService.Client<MeshTransport>,
        prescriptionsPrescriptionQuery: Acme_Prescriptions_V1_PrescriptionQueryService.Client<MeshTransport>,
        recommendationsRecommendationSet: Acme_Recommendations_V1_RecommendationSetService.Client<MeshTransport>,
        telehealthVisitNoteValidation: Acme_Telehealth_V1_VisitNoteValidationService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.admissionsAdmissionCalculation = admissionsAdmissionCalculation
        self.appointmentsAppointment = appointmentsAppointment
        self.appointmentsProviderValidation = appointmentsProviderValidation
        self.careplansCareGoalCalculation = careplansCareGoalCalculation
        self.careplansCareGoalValidation = careplansCareGoalValidation
        self.careplansCarePlanCalculation = careplansCarePlanCalculation
        self.careplansCarePlanQuery = careplansCarePlanQuery
        self.careplansCarePlanValidation = careplansCarePlanValidation
        self.careplansVitalCalculation = careplansVitalCalculation
        self.featureflagsFeatureFlagValidation = featureflagsFeatureFlagValidation
        self.identityUser = identityUser
        self.ledgerLedgerAccountQuery = ledgerLedgerAccountQuery
        self.patientsMedicalRecordQuery = patientsMedicalRecordQuery
        self.patientsPatient = patientsPatient
        self.prescriptionsPrescriptionQuery = prescriptionsPrescriptionQuery
        self.recommendationsRecommendationSet = recommendationsRecommendationSet
        self.telehealthVisitNoteValidation = telehealthVisitNoteValidation
        self.activateCarePlanStep1 = { request in try await patientsMedicalRecordQuery.browseMedicalRecords(request) }
        self.expireCarePlanStep0 = [
            "primary": { request in try await prescriptionsPrescriptionQuery.summarizePrescriptions(request) }
        ]
    }

    /// Activates a care plan.
    func activateCarePlan(
        request: ServerRequest<Acme_Careplans_V1_ActivateCarePlanRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_ActivateCarePlanResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processActivateCarePlan(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Expires a care plan.
    func expireCarePlan(
        request: ServerRequest<Acme_Careplans_V1_ExpireCarePlanRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_ExpireCarePlanResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processExpireCarePlan(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a care plan.
    func getCarePlanLifecycle(
        request: ServerRequest<Acme_Careplans_V1_GetCarePlanLifecycleRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_GetCarePlanLifecycleResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetCarePlanLifecycle(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Reinstates a care plan.
    func reinstateCarePlan(
        request: ServerRequest<Acme_Careplans_V1_ReinstateCarePlanRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_ReinstateCarePlanResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processReinstateCarePlan(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Renews a care plan.
    func renewCarePlan(
        request: ServerRequest<Acme_Careplans_V1_RenewCarePlanRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_RenewCarePlanResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRenewCarePlan(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Schedules a care plan.
    func scheduleCarePlanExpiry(
        request: ServerRequest<Acme_Careplans_V1_ScheduleCarePlanExpiryRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_ScheduleCarePlanExpiryResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processScheduleCarePlanExpiry(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Suspends a care plan.
    func suspendCarePlan(
        request: ServerRequest<Acme_Careplans_V1_SuspendCarePlanRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_SuspendCarePlanResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSuspendCarePlan(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processActivateCarePlan(_ input: Acme_Careplans_V1_ActivateCarePlanRequest) async throws
        -> Acme_Careplans_V1_ActivateCarePlanResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "audit", detail: input.details.newOwner.email
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ActivateCarePlan",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "ActivateCarePlan", detail: input.context.traceID
        )
        let importFrame = Acme_Patients_V1_BatchCreatePatientsRequest.with {
            $0.context = input.context
        }
        _ = try await self.patientsPatient.batchCreatePatients { writer in
            try await writer.write(importFrame)
        }
        let outbound0 = Acme_Careplans_V1_RecalculateVitalsRequest.with {
            $0.context = input.context
            $0.reason = input.reason
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.subject = Acme_Appointments_V1_AppointmentRef.with {
                    $0.displayName = input.details.newOwner.displayName
                }
            }
        }
        let port0 = RPCOperations.port { (request: Acme_Careplans_V1_RecalculateVitalsRequest) in
            try await self.careplansVitalCalculation.recalculateVitals(request)
        }
        let reply0 = try await port0.execute(outbound0)
        let outbound1 = Acme_Patients_V1_BrowseMedicalRecordsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Patients_V1_BrowseMedicalRecordsRequest.Filter.with {
                $0.createdAfter = reply0.vital.subject.startsAt
                $0.labels = reply0.vital.attributes
                $0.ownerID = input.details.newOwner.userID
            }
        }
        let reply1 = try await self.activateCarePlanStep1(outbound1)
        return Acme_Careplans_V1_ActivateCarePlanResponse.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.carePlanID = input.carePlanID
                $0.counterparty = Acme_Appointments_V1_AppointmentRef.with {
                    $0.startsAt = reply0.vital.subject.startsAt
                }
            }
            $0.outcome = Acme_Careplans_V1_ActivateCarePlanResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
                $0.message = reply1.result.message
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.vital.correlationID
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processExpireCarePlan(_ input: Acme_Careplans_V1_ExpireCarePlanRequest) async throws
        -> Acme_Careplans_V1_ExpireCarePlanResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "audit", detail: input.details.newOwner.email
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ExpireCarePlan",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "ExpireCarePlan", detail: input.context.traceID
        )
        let outbound0 = Acme_Prescriptions_V1_SummarizePrescriptionsRequest.with {
            $0.annotations = input.annotations
            $0.context = input.context
            $0.reason = input.reason
        }
        guard let execute0 = self.expireCarePlanStep0[settings.region] ?? self.expireCarePlanStep0["primary"] else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply0 = try await execute0(outbound0)
        let outbound1 = Acme_Careplans_V1_ExportCarePlansRequest.with {
            $0.context = input.context
            $0.filter = Acme_Careplans_V1_ExportCarePlansRequest.Filter.with {
                $0.createdAfter = input.details.effectiveAt
                $0.labels = reply0.summary
                $0.ownerID = reply0.result.correlationID
            }
        }
        let reply1 = try await self.careplansCarePlanQuery.exportCarePlans(outbound1) { response in
            var latest = Acme_Careplans_V1_ExportCarePlansResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        _ = reply1
        let outbound2 = Acme_Careplans_V1_ExplainCarePlanDecisionRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.counterparty = Acme_Appointments_V1_AppointmentRef.with {
                    $0.displayName = input.details.newOwner.displayName
                }
            }
            $0.context = input.context
            $0.details = Acme_Careplans_V1_ExplainCarePlanDecisionRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.notifyContact.email
                    $0.name = input.details.notifyContact.name
                    $0.preferredChannel = input.details.notifyContact.preferredChannel
                }
            }
        }
        let reply2 = try await self.careplansCarePlanValidation.explainCarePlanDecision(outbound2)
        let outbound3 = Acme_Ledger_V1_ExportLedgerAccountsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Ledger_V1_ExportLedgerAccountsRequest.Filter.with {
                $0.createdAfter = reply2.carePlan.issuedAt
                $0.labels = reply2.carePlan.metadata
                $0.ownerID = reply2.carePlan.counterparty.appointmentID
                $0.region = reply2.carePlan.billingAddress.region
            }
        }
        let reply3 = try await self.ledgerLedgerAccountQuery.exportLedgerAccounts(outbound3) { response in
            var latest = Acme_Ledger_V1_ExportLedgerAccountsResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        _ = reply3
        return Acme_Careplans_V1_ExpireCarePlanResponse.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.carePlanID = input.carePlanID
                $0.dueAt = reply2.carePlan.dueAt
                $0.notes = reply2.carePlan.notes
            }
            $0.outcome = Acme_Careplans_V1_ExpireCarePlanResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
                $0.message = reply0.result.message
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processGetCarePlanLifecycle(_ input: Acme_Careplans_V1_GetCarePlanLifecycleRequest) async throws
        -> Acme_Careplans_V1_GetCarePlanLifecycleResponse
    {
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "GetCarePlanLifecycle",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "GetCarePlanLifecycle", detail: input.context.traceID
        )
        let outbound0 = Acme_Careplans_V1_RecalculateCareGoalsRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.email = input.context.actor.email
                }
            }
            $0.context = input.context
        }
        let envelope0 = try Google_Protobuf_Any(message: outbound0)
        let unpacked0 = try Acme_Careplans_V1_RecalculateCareGoalsRequest(unpackingAny: envelope0)
        let reply0 = try await self.careplansCareGoalCalculation.recalculateCareGoals(unpacked0)
        return Acme_Careplans_V1_GetCarePlanLifecycleResponse.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply0.careGoal.audit.createdBy
                }
                $0.carePlanID = input.carePlanID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply0.result.status
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processReinstateCarePlan(_ input: Acme_Careplans_V1_ReinstateCarePlanRequest) async throws
        -> Acme_Careplans_V1_ReinstateCarePlanResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "audit", detail: input.details.newOwner.displayName
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ReinstateCarePlan",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "ReinstateCarePlan", detail: input.context.traceID
        )
        let outbound0 = Acme_Careplans_V1_SimulateCareGoalRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.details.newOwner.userID
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.newOwner.email
                    $0.phone = input.details.notifyContact.phone
                }
            }
            $0.context = input.context
        }
        let json0 = try outbound0.jsonString()
        let decoded0 = try Acme_Careplans_V1_SimulateCareGoalRequest(jsonString: json0)
        let reply0 = try await self.careplansCareGoalCalculation.simulateCareGoal(decoded0)
        let outbound1 = Acme_Careplans_V1_ScoreCarePlanRequest.forCarePlanLifecycleEndpointReinstateCarePlan1(
            input,
            reply0: reply0
        )
        let reply1 = try await self.careplansCarePlanValidation.scoreCarePlan(outbound1)
        let outbound2 = Acme_Featureflags_V1_PreviewFeatureFlagRequest.with {
            $0.context = input.context
            $0.details = Acme_Featureflags_V1_PreviewFeatureFlagRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.name = input.details.notifyContact.name
                    $0.phone = reply0.careGoal.requester.phone
                    $0.preferredChannel = input.details.notifyContact.preferredChannel
                }
            }
            $0.featureFlag = Acme_Featureflags_V1_FeatureFlag.with {
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.email = input.details.notifyContact.email
                }
            }
        }
        let reply2 = try await self.featureflagsFeatureFlagValidation.previewFeatureFlag(
            outbound2, metadata: ["x-acme-region": .string(settings.region)]
        )
        let outbound3 = Acme_Appointments_V1_PreviewProviderRequest.with {
            $0.context = input.context
            $0.details = Acme_Appointments_V1_PreviewProviderRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.newOwner.email
                }
            }
            $0.provider = Acme_Appointments_V1_Provider.with {
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.email = reply0.careGoal.assignee.email
                }
            }
        }
        let reply3 = try await RPCOperations.call(outbound3) { request in
            try await self.appointmentsProviderValidation.previewProvider(request)
        }
        return Acme_Careplans_V1_ReinstateCarePlanResponse.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = reply3.provider.primaryAddress.countryCode
                }
                $0.carePlanID = input.carePlanID
            }
            $0.outcome = Acme_Careplans_V1_ReinstateCarePlanResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
                $0.message = Projection.firstValue(
                    [
                        reply0.result.message,
                        reply2.result.message,
                    ], default: .init())
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply1.result.status
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processRenewCarePlan(_ input: Acme_Careplans_V1_RenewCarePlanRequest) async throws
        -> Acme_Careplans_V1_RenewCarePlanResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "audit", detail: input.details.newOwner.email
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "RenewCarePlan",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "RenewCarePlan", detail: input.context.traceID
        )
        let outbound0 = Acme_Telehealth_V1_ValidateVisitNoteRequest.with {
            $0.context = Projection.read(input, at: \Acme_Careplans_V1_RenewCarePlanRequest.context)
            $0.details = Acme_Telehealth_V1_ValidateVisitNoteRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = Projection.read(
                        input, at: \Acme_Careplans_V1_RenewCarePlanRequest.details.notifyContact.email)
                    $0.name = Projection.read(
                        input, at: \Acme_Careplans_V1_RenewCarePlanRequest.details.notifyContact.name)
                    $0.preferredChannel = Projection.read(
                        input, at: \Acme_Careplans_V1_RenewCarePlanRequest.details.notifyContact.preferredChannel)
                }
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = Projection.read(
                        input, at: \Acme_Careplans_V1_RenewCarePlanRequest.details.newOwner.displayName)
                }
            }
        }
        let reply0 = try await self.telehealthVisitNoteValidation.validateVisitNote(outbound0)
        return Acme_Careplans_V1_RenewCarePlanResponse.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply0.visitNote.audit.updatedBy
                }
                $0.carePlanID = input.carePlanID
            }
            $0.outcome = Acme_Careplans_V1_RenewCarePlanResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply0.result.status
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processScheduleCarePlanExpiry(_ input: Acme_Careplans_V1_ScheduleCarePlanExpiryRequest) async throws
        -> Acme_Careplans_V1_ScheduleCarePlanExpiryResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.carePlan.audit.etag)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "audit", detail: input.carePlan.audit.etag
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ScheduleCarePlanExpiry",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try CarePlanRecord(input.carePlan, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Admissions_V1_EstimateAdmissionRequest.with {
            $0.context = input.context
            $0.details = Acme_Admissions_V1_EstimateAdmissionRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = input.carePlan.billingAddress.countryCode
                    $0.locality = input.carePlan.billingAddress.locality
                    $0.postalCode = input.carePlan.billingAddress.postalCode
                    $0.recipient = input.carePlan.billingAddress.recipient
                }
            }
        }
        let step0: @Sendable () async throws -> Acme_Admissions_V1_EstimateAdmissionResponse = {
            try await self.admissionsAdmissionCalculation.estimateAdmission(outbound0)
        }
        let reply0 = try await step0()
        var outbound1 = Acme_Careplans_V1_LintCareGoalsRequest()
        outbound1.careGoal = Acme_Careplans_V1_CareGoal.with {
            $0.audit = Acme_Common_V1_AuditInfo.with {
                $0.createdBy = input.carePlan.audit.createdBy
            }
            $0.customer = Acme_Patients_V1_PatientRef.with {
                $0.displayName = input.carePlan.counterparty.displayName
            }
            $0.requester = Acme_Common_V1_ContactInfo.with {
                $0.email = input.details.notify.email
                $0.name = input.details.notify.name
            }
        }
        outbound1.context = input.context
        let reply1 = try await self.careplansCareGoalValidation.lintCareGoals(outbound1)
        return Acme_Careplans_V1_ScheduleCarePlanExpiryResponse.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.billingAddress = input.carePlan.billingAddress
                $0.carePlanID = input.carePlanID
                $0.counterparty = Acme_Appointments_V1_AppointmentRef.with {
                    $0.displayName = reply1.careGoal.customer.displayName
                }
            }
            $0.outcome = Acme_Careplans_V1_ScheduleCarePlanExpiryResponse.Outcome.with {
                $0.message = reply0.result.message
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processSuspendCarePlan(_ input: Acme_Careplans_V1_SuspendCarePlanRequest) async throws
        -> Acme_Careplans_V1_SuspendCarePlanResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.newOwner.displayName)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "audit", detail: input.details.newOwner.displayName
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "SuspendCarePlan",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "care_plan",
            action: "SuspendCarePlan", detail: input.context.traceID
        )
        let outbound0 = Acme_Appointments_V1_CreateAppointmentRequest.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.participants = [
                    Acme_Appointments_V1_AppointmentParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = input.details.newOwner.email
                        }
                    }
                ]
            }
            $0.context = input.context
        }
        let step0: @Sendable () async throws -> Acme_Appointments_V1_CreateAppointmentResponse = {
            try await self.appointmentsAppointment.createAppointment(outbound0)
        }
        let reply0 = try await step0()
        let outbound1 = Acme_Careplans_V1_NormalizeCarePlanRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply0.appointment.audit.updatedBy
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.recipient = reply0.appointment.location.recipient
                    $0.region = reply0.appointment.location.region
                }
            }
            $0.context = input.context
            $0.details = Acme_Careplans_V1_NormalizeCarePlanRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.preferredChannel = input.details.notifyContact.preferredChannel
                }
            }
        }
        let reply1 = try await self.careplansCarePlanValidation.normalizeCarePlan(outbound1)
        let selection2_2: String
        switch reply1.carePlan.settlement {
        case .bank(let bank):
            selection2_2 = bank.iban
        default: selection2_2 = .init()
        }
        let outbound2 = Acme_Careplans_V1_EstimateCarePlanRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply0.appointment.audit.updatedAt
                }
                $0.bank = Acme_Careplans_V1_CarePlanBankSettlement.with {
                    $0.iban = selection2_2
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = reply1.carePlan.billingAddress.postalCode
                }
            }
            $0.context = input.context
        }
        let reply2 = try await self.careplansCarePlanCalculation.estimateCarePlan(outbound2)
        let outbound3 = Acme_Recommendations_V1_ListRecommendationSetsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Recommendations_V1_ListRecommendationSetsRequest.Filter.with {
                $0.region = reply1.carePlan.billingAddress.region
            }
        }
        async let remote3 = self.recommendationsRecommendationSet.listRecommendationSets(outbound3)
        async let persisted3 = store.count(tenant: input.context.tenantID)
        let (reply3, count3) = try await (remote3, persisted3)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count3)])
        return Acme_Careplans_V1_SuspendCarePlanResponse.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.lines = reply1.carePlan.billingAddress.lines
                }
                $0.carePlanID = input.carePlanID
                $0.counterparty = Projection.updating(reply1.carePlan.counterparty) {
                    $0.displayName = reply2.carePlan.counterparty.displayName
                    $0.startsAt = reply2.carePlan.counterparty.startsAt
                }
            }
            $0.outcome = Acme_Careplans_V1_SuspendCarePlanResponse.Outcome.with {
                $0.effectiveAt = input.details.effectiveAt
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply3.result.referenceIds
                $0.status = Projection.firstValue(
                    [
                        reply0.result.status,
                        reply3.result.status,
                    ], default: .init())
            }
        }
    }
}
