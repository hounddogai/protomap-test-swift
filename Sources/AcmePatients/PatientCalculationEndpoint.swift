import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Computes the figures of a patient, such as totals, taxes, and estimates.
final class PatientCalculationEndpoint: Acme_Patients_V1_PatientCalculationService.ServiceProtocol {
    private let store: any RecordRepository
    private let logger: Logger
    private let settings: Settings
    private let followUps = WorkQueue<Acme_Identity_V1_GetUserRequest>()
    private let appointmentsAppointmentValidation:
        Acme_Appointments_V1_AppointmentValidationService.Client<MeshTransport>
    private let authorizationAccessPolicyValidation:
        Acme_Authorization_V1_AccessPolicyValidationService.Client<MeshTransport>
    private let careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>
    private let careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client<MeshTransport>
    private let careplansVitalCalculation: Acme_Careplans_V1_VitalCalculationService.Client<MeshTransport>
    private let concessionsConcessionStandQuery: Acme_Concessions_V1_ConcessionStandQueryService.Client<MeshTransport>
    private let documentsDocumentValidation: Acme_Documents_V1_DocumentValidationService.Client<MeshTransport>
    private let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    private let metricsMetricSeries: Acme_Metrics_V1_MetricSeriesService.Client<MeshTransport>
    private let telehealthTriageCalculation: Acme_Telehealth_V1_TriageCalculationService.Client<MeshTransport>
    private let venuesVenueValidation: Acme_Venues_V1_VenueValidationService.Client<MeshTransport>
    private let explainPatientCalculationStep0:
        any RPCPort<Acme_Careplans_V1_EstimateVitalRequest, Acme_Careplans_V1_EstimateVitalResponse>
    private let explainPatientCalculationStep2:
        @Sendable (Acme_Telehealth_V1_SimulateTriageRequest) async throws -> Acme_Telehealth_V1_SimulateTriageResponse
    private let explainPatientCalculationStep3:
        [String:
            @Sendable (Acme_Careplans_V1_ExplainCarePlanDecisionRequest) async throws ->
            Acme_Careplans_V1_ExplainCarePlanDecisionResponse]

    init(
        dependencies: any Dependencies,
        appointmentsAppointmentValidation: Acme_Appointments_V1_AppointmentValidationService.Client<MeshTransport>,
        authorizationAccessPolicyValidation: Acme_Authorization_V1_AccessPolicyValidationService.Client<MeshTransport>,
        careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>,
        careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client<MeshTransport>,
        careplansVitalCalculation: Acme_Careplans_V1_VitalCalculationService.Client<MeshTransport>,
        concessionsConcessionStandQuery: Acme_Concessions_V1_ConcessionStandQueryService.Client<MeshTransport>,
        documentsDocumentValidation: Acme_Documents_V1_DocumentValidationService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        metricsMetricSeries: Acme_Metrics_V1_MetricSeriesService.Client<MeshTransport>,
        telehealthTriageCalculation: Acme_Telehealth_V1_TriageCalculationService.Client<MeshTransport>,
        venuesVenueValidation: Acme_Venues_V1_VenueValidationService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.appointmentsAppointmentValidation = appointmentsAppointmentValidation
        self.authorizationAccessPolicyValidation = authorizationAccessPolicyValidation
        self.careplansCarePlan = careplansCarePlan
        self.careplansCarePlanValidation = careplansCarePlanValidation
        self.careplansVitalCalculation = careplansVitalCalculation
        self.concessionsConcessionStandQuery = concessionsConcessionStandQuery
        self.documentsDocumentValidation = documentsDocumentValidation
        self.identityUser = identityUser
        self.metricsMetricSeries = metricsMetricSeries
        self.telehealthTriageCalculation = telehealthTriageCalculation
        self.venuesVenueValidation = venuesVenueValidation
        self.explainPatientCalculationStep0 = ClosurePort<
            Acme_Careplans_V1_EstimateVitalRequest, Acme_Careplans_V1_EstimateVitalResponse
        >({ request in try await careplansVitalCalculation.estimateVital(request) })
        self.explainPatientCalculationStep2 = { request in try await telehealthTriageCalculation.simulateTriage(request)
        }
        self.explainPatientCalculationStep3 = [
            "primary": { request in try await careplansCarePlanValidation.explainCarePlanDecision(request) }
        ]
    }

    /// Resolve follow-up ownership outside the RPC's lifetime.
    func runFollowUps() async throws {
        for await event in followUps.events {
            try Task.checkCancellation()
            do {
                let user = try await self.identityUser.getUser(event)
                logger.info("Follow-up resolved", metadata: ["user": .string(user.user.userID)])
            } catch {
                logger.error("Follow-up failed", metadata: ["error": .string(String(describing: error))])
            }
        }
    }

    /// Calculates a patient.
    func calculatePatient(
        request: ServerRequest<Acme_Patients_V1_CalculatePatientRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_CalculatePatientResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCalculatePatient(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Estimates a patient.
    func estimatePatient(
        request: ServerRequest<Acme_Patients_V1_EstimatePatientRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_EstimatePatientResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processEstimatePatient(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Explains a patient.
    func explainPatientCalculation(
        request: ServerRequest<Acme_Patients_V1_ExplainPatientCalculationRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_ExplainPatientCalculationResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processExplainPatientCalculation(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a patient.
    func getPatientRates(
        request: ServerRequest<Acme_Patients_V1_GetPatientRatesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_GetPatientRatesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetPatientRates(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Quotes a patient.
    func quotePatient(
        request: ServerRequest<Acme_Patients_V1_QuotePatientRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_QuotePatientResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processQuotePatient(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Recalculates a patient.
    func recalculatePatients(
        request: ServerRequest<Acme_Patients_V1_RecalculatePatientsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_RecalculatePatientsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRecalculatePatients(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processCalculatePatient(_ input: Acme_Patients_V1_CalculatePatientRequest) async throws
        -> Acme_Patients_V1_CalculatePatientResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.destination.countryCode)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "audit", detail: input.details.destination.countryCode
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "CalculatePatient",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PatientRecord(input.patient, tenant: input.context.tenantID)
        try await store.save(record.stored)
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
        let outbound0 = Acme_Authorization_V1_CheckAccessPolicyEligibilityRequest.with {
            $0.context = input.context
            $0.details = Acme_Authorization_V1_CheckAccessPolicyEligibilityRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.preferredChannel = input.patient.contact.preferredChannel
                }
            }
        }
        let step0: @Sendable () async throws -> Acme_Authorization_V1_CheckAccessPolicyEligibilityResponse = {
            try await self.authorizationAccessPolicyValidation.checkAccessPolicyEligibility(outbound0)
        }
        let reply0 = try await step0()
        let outbound1 = Acme_Appointments_V1_LintAppointmentsRequest.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.patient.relationshipManager.displayName
                }
                $0.participants = [
                    Acme_Appointments_V1_AppointmentParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = reply0.accessPolicy.owner.email
                            $0.name = input.patient.contact.name
                            $0.preferredChannel = input.patient.contact.preferredChannel
                        }
                    }
                ]
            }
            $0.context = input.context
        }
        let reply1 = try await self.appointmentsAppointmentValidation.lintAppointments(outbound1)
        return Acme_Patients_V1_CalculatePatientResponse.with {
            $0.breakdown = Acme_Patients_V1_CalculatePatientResponse.Breakdown.with {
                $0.currencyCode = input.details.currencyCode
            }
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply1.appointment.audit.createdAt
                }
                $0.patientID = input.patientID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.result.message
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processEstimatePatient(_ input: Acme_Patients_V1_EstimatePatientRequest) async throws
        -> Acme_Patients_V1_EstimatePatientResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.currencyCode)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "audit", detail: input.details.currencyCode
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "EstimatePatient",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PatientRecord(input.patient, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Venues_V1_ScoreVenueRequest.with {
            $0.context = input.context
            $0.details = Acme_Venues_V1_ScoreVenueRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.locality = input.details.destination.locality
                }
            }
        }
        async let remote0 = self.venuesVenueValidation.scoreVenue(outbound0)
        async let persisted0 = store.count(tenant: input.context.tenantID)
        let (reply0, count0) = try await (remote0, persisted0)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count0)])
        return Acme_Patients_V1_EstimatePatientResponse.with {
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.attributes = input.patient.attributes
                $0.patientID = input.patientID
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = reply0.venue.address.countryCode
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processExplainPatientCalculation(_ input: Acme_Patients_V1_ExplainPatientCalculationRequest) async throws
        -> Acme_Patients_V1_ExplainPatientCalculationResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "audit", detail: input.details.contact.email
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ExplainPatientCalculation",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PatientRecord(input.patient, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Careplans_V1_EstimateVitalRequest.with {
            $0.context = input.context
            $0.details = Acme_Careplans_V1_EstimateVitalRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.locality = input.patient.primaryAddress.locality
                }
            }
        }
        let reply0 = try await self.explainPatientCalculationStep0.execute(outbound0)
        let outbound1 = Acme_Documents_V1_PreviewDocumentRequest.with {
            $0.context = input.context
            $0.document = Acme_Documents_V1_Document.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = input.patient.audit.updatedBy
                }
                $0.counterparty = Acme_Documents_V1_DocumentFolderRef.with {
                    $0.displayName = reply0.vital.subject.displayName
                }
            }
        }
        let port1 = RPCOperations.port { (request: Acme_Documents_V1_PreviewDocumentRequest) in
            try await self.documentsDocumentValidation.previewDocument(request)
        }
        let reply1 = try await port1.execute(outbound1)
        let outbound2 = Acme_Telehealth_V1_SimulateTriageRequest.with {
            $0.context = input.context
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply1.document.audit.updatedBy
                }
                $0.customer = Acme_Telehealth_V1_VideoVisitRef.with {
                    $0.startsAt = reply0.vital.subject.startsAt
                }
            }
        }
        let reply2 = try await self.explainPatientCalculationStep2(outbound2)
        let outbound3 = Acme_Careplans_V1_ExplainCarePlanDecisionRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.recipient = input.patient.primaryAddress.recipient
                }
            }
            $0.context = input.context
            $0.details = Acme_Careplans_V1_ExplainCarePlanDecisionRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply2.triage.assignee.email
                    $0.name = input.patient.contact.name
                }
            }
        }
        guard
            let execute3 = self.explainPatientCalculationStep3[settings.region]
                ?? self.explainPatientCalculationStep3["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply3 = try await execute3(outbound3)
        return Acme_Patients_V1_ExplainPatientCalculationResponse.with {
            $0.outcome = Acme_Patients_V1_ExplainPatientCalculationResponse.Outcome.with {
                $0.message = Projection.firstValue(
                    [
                        reply0.result.message,
                        reply3.outcome.message,
                    ], default: .init())
                $0.nextSteps = reply3.outcome.nextSteps
            }
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.name = input.patient.name
                $0.patientID = input.patientID
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = reply1.document.billingAddress.region
                }
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.userID = reply2.triage.assignee.userID
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processGetPatientRates(_ input: Acme_Patients_V1_GetPatientRatesRequest) async throws
        -> Acme_Patients_V1_GetPatientRatesResponse
    {
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "GetPatientRates",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "GetPatientRates", detail: input.context.traceID
        )
        let outbound0 = Acme_Metrics_V1_CloneMetricSeriesRequest.with {
            $0.context = input.context
            $0.metricSeries = Acme_Metrics_V1_MetricSeries.with {
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.email = input.context.actor.email
                    $0.userID = input.context.actor.userID
                }
            }
        }
        let reply0 = try await self.metricsMetricSeries.cloneMetricSeries(outbound0)
        return Acme_Patients_V1_GetPatientRatesResponse.with {
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.patientID = input.patientID
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = reply0.metricSeries.address.region
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processQuotePatient(_ input: Acme_Patients_V1_QuotePatientRequest) async throws
        -> Acme_Patients_V1_QuotePatientResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.destination.countryCode)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "audit", detail: input.details.destination.countryCode
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "QuotePatient",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PatientRecord(input.patient, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Metrics_V1_UpdateMetricSeriesRequest.with {
            $0.context = input.context
            $0.metricSeries = Acme_Metrics_V1_MetricSeries.with {
                $0.address = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = input.patient.primaryAddress.postalCode
                }
            }
        }
        let envelope0 = try Google_Protobuf_Any(message: outbound0)
        let unpacked0 = try Acme_Metrics_V1_UpdateMetricSeriesRequest(unpackingAny: envelope0)
        let reply0 = try await self.metricsMetricSeries.updateMetricSeries(unpacked0)
        let outbound1 = Acme_Telehealth_V1_CompareTriageOptionsRequest.with {
            $0.context = input.context
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.userID = reply0.metricSeries.owner.userID
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply0.metricSeries.audit.updatedBy
                }
            }
        }
        let json1 = try outbound1.jsonString()
        let decoded1 = try Acme_Telehealth_V1_CompareTriageOptionsRequest(jsonString: json1)
        let reply1 = try await self.telehealthTriageCalculation.compareTriageOptions(decoded1)
        return Acme_Patients_V1_QuotePatientResponse.with {
            $0.breakdown = Acme_Patients_V1_QuotePatientResponse.Breakdown.with {
                $0.currencyCode = input.details.currencyCode
            }
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.patientID = input.patientID
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply0.metricSeries.owner.displayName
                    $0.email = reply1.triage.requester.email
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processRecalculatePatients(_ input: Acme_Patients_V1_RecalculatePatientsRequest) async throws
        -> Acme_Patients_V1_RecalculatePatientsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.currencyCode)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "audit", detail: input.details.currencyCode
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "RecalculatePatients",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PatientRecord(input.patient, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Concessions_V1_ExportConcessionStandsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Concessions_V1_ExportConcessionStandsRequest.Filter.with {
                $0.createdAfter = input.patient.passport.expiresAt
                $0.ownerID = input.patient.relationshipManager.userID
                $0.region = input.details.destination.region
            }
        }
        let reply0 = try await self.concessionsConcessionStandQuery.exportConcessionStands(outbound0) { response in
            var latest = Acme_Concessions_V1_ExportConcessionStandsResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        _ = reply0
        let outbound1 = Acme_Identity_V1_CreateUserRequest.forPatientCalculationEndpointRecalculatePatients1(
            input
        )
        let reply1 = try await self.identityUser.createUser(outbound1)
        return Acme_Patients_V1_RecalculatePatientsResponse.with {
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.contact = input.patient.contact
                $0.patientID = input.patientID
                $0.relationshipManager = reply1.user.relationshipManager
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.status = "ok"
            }
        }
    }
}
