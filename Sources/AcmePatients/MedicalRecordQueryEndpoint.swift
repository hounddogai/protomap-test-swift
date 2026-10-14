import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Answers read-only questions about medical records, for screens and reports.
final class MedicalRecordQueryEndpoint: Acme_Patients_V1_MedicalRecordQueryService.ServiceProtocol {
    private let store: any RecordRepository
    private let logger: Logger
    private let settings: Settings
    private let followUps = WorkQueue<Acme_Identity_V1_GetUserRequest>()
    private let appointmentsAppointmentValidation:
        Acme_Appointments_V1_AppointmentValidationService.Client<MeshTransport>
    private let careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>
    private let documentsDocument: Acme_Documents_V1_DocumentService.Client<MeshTransport>
    private let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    private let metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client<MeshTransport>
    private let patientsAllergyCalculation: Acme_Patients_V1_AllergyCalculationService.Client<MeshTransport>
    private let patientsAllergyValidation: Acme_Patients_V1_AllergyValidationService.Client<MeshTransport>
    private let patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>
    private let patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client<MeshTransport>
    private let patientsPatientValidation: Acme_Patients_V1_PatientValidationService.Client<MeshTransport>
    private let prescriptionsPrescriptionValidation:
        Acme_Prescriptions_V1_PrescriptionValidationService.Client<MeshTransport>
    private let telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client<MeshTransport>
    private let findMedicalRecordsStep0:
        any RPCPort<Acme_Patients_V1_QuoteAllergyRequest, Acme_Patients_V1_QuoteAllergyResponse>
    private let peekMedicalRecordStep0:
        @Sendable (Acme_Patients_V1_PreviewAllergyRequest) async throws -> Acme_Patients_V1_PreviewAllergyResponse
    private let peekMedicalRecordStep1:
        [String:
            @Sendable (Acme_Telehealth_V1_ExplainVideoVisitCalculationRequest) async throws ->
            Acme_Telehealth_V1_ExplainVideoVisitCalculationResponse]

    init(
        dependencies: any Dependencies,
        appointmentsAppointmentValidation: Acme_Appointments_V1_AppointmentValidationService.Client<MeshTransport>,
        careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>,
        documentsDocument: Acme_Documents_V1_DocumentService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client<MeshTransport>,
        patientsAllergyCalculation: Acme_Patients_V1_AllergyCalculationService.Client<MeshTransport>,
        patientsAllergyValidation: Acme_Patients_V1_AllergyValidationService.Client<MeshTransport>,
        patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>,
        patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client<MeshTransport>,
        patientsPatientValidation: Acme_Patients_V1_PatientValidationService.Client<MeshTransport>,
        prescriptionsPrescriptionValidation: Acme_Prescriptions_V1_PrescriptionValidationService.Client<MeshTransport>,
        telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.appointmentsAppointmentValidation = appointmentsAppointmentValidation
        self.careplansCarePlan = careplansCarePlan
        self.documentsDocument = documentsDocument
        self.identityUser = identityUser
        self.metricsMetricSeriesValidation = metricsMetricSeriesValidation
        self.patientsAllergyCalculation = patientsAllergyCalculation
        self.patientsAllergyValidation = patientsAllergyValidation
        self.patientsMedicalRecordCalculation = patientsMedicalRecordCalculation
        self.patientsPatientQuery = patientsPatientQuery
        self.patientsPatientValidation = patientsPatientValidation
        self.prescriptionsPrescriptionValidation = prescriptionsPrescriptionValidation
        self.telehealthVideoVisitCalculation = telehealthVideoVisitCalculation
        self.findMedicalRecordsStep0 = ClosurePort<
            Acme_Patients_V1_QuoteAllergyRequest, Acme_Patients_V1_QuoteAllergyResponse
        >({ request in try await patientsAllergyCalculation.quoteAllergy(request) })
        self.peekMedicalRecordStep0 = { request in try await patientsAllergyValidation.previewAllergy(request) }
        self.peekMedicalRecordStep1 = [
            "primary": { request in try await telehealthVideoVisitCalculation.explainVideoVisitCalculation(request) }
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

    /// Lists medical records a page at a time.
    func browseMedicalRecords(
        request: ServerRequest<Acme_Patients_V1_BrowseMedicalRecordsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_BrowseMedicalRecordsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processBrowseMedicalRecords(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Counts medical records by status.
    func countMedicalRecords(
        request: ServerRequest<Acme_Patients_V1_CountMedicalRecordsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_CountMedicalRecordsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCountMedicalRecords(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Streams every matching medical record.
    func exportMedicalRecords(
        request: ServerRequest<Acme_Patients_V1_ExportMedicalRecordsRequest>,
        context: ServerContext
    ) async throws -> StreamingServerResponse<Acme_Patients_V1_ExportMedicalRecordsResponse> {
        return StreamingServerResponse { writer in
            try await CallerScope.$metadata.withValue(request.metadata) {
                let response = try await self.processExportMedicalRecords(request.message)
                try await writer.write(response)
                return [:]
            }
        }
    }

    /// Lists medical records a page at a time.
    func findMedicalRecords(
        request: ServerRequest<Acme_Patients_V1_FindMedicalRecordsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_FindMedicalRecordsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processFindMedicalRecords(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a medical record.
    func lookupMedicalRecord(
        request: ServerRequest<Acme_Patients_V1_LookupMedicalRecordRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_LookupMedicalRecordResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processLookupMedicalRecord(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a medical record.
    func peekMedicalRecord(
        request: ServerRequest<Acme_Patients_V1_PeekMedicalRecordRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_PeekMedicalRecordResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processPeekMedicalRecord(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns several medical records at once.
    func resolveMedicalRecords(
        request: ServerRequest<Acme_Patients_V1_ResolveMedicalRecordsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_ResolveMedicalRecordsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processResolveMedicalRecords(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists medical records a page at a time.
    func suggestMedicalRecords(
        request: ServerRequest<Acme_Patients_V1_SuggestMedicalRecordsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_SuggestMedicalRecordsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSuggestMedicalRecords(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Summarizes a medical record.
    func summarizeMedicalRecords(
        request: ServerRequest<Acme_Patients_V1_SummarizeMedicalRecordsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_SummarizeMedicalRecordsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSummarizeMedicalRecords(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processBrowseMedicalRecords(_ input: Acme_Patients_V1_BrowseMedicalRecordsRequest) async throws
        -> Acme_Patients_V1_BrowseMedicalRecordsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "audit", detail: input.filter.ownerID
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "BrowseMedicalRecords",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "BrowseMedicalRecords", detail: input.context.traceID
        )
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
        return Acme_Patients_V1_BrowseMedicalRecordsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processCountMedicalRecords(_ input: Acme_Patients_V1_CountMedicalRecordsRequest) async throws
        -> Acme_Patients_V1_CountMedicalRecordsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "audit", detail: input.filter.ownerID
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "CountMedicalRecords",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "CountMedicalRecords", detail: input.context.traceID
        )
        let outbound0 = Acme_Patients_V1_ScorePatientRequest.with {
            $0.context = input.context
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
            }
        }
        let step0: @Sendable () async throws -> Acme_Patients_V1_ScorePatientResponse = {
            try await self.patientsPatientValidation.scorePatient(outbound0)
        }
        let reply0 = try await step0()
        return Acme_Patients_V1_CountMedicalRecordsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processExportMedicalRecords(_ input: Acme_Patients_V1_ExportMedicalRecordsRequest) async throws
        -> Acme_Patients_V1_ExportMedicalRecordsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.destinationUri)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "audit", detail: input.destinationUri
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ExportMedicalRecords",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "ExportMedicalRecords", detail: input.context.traceID
        )
        var outbound0 = Acme_Prescriptions_V1_PreviewPrescriptionRequest()
        outbound0.context = input.context
        outbound0.details = Acme_Prescriptions_V1_PreviewPrescriptionRequest.Details.with {
            $0.contact = Acme_Common_V1_ContactInfo.with {
                $0.email = input.context.actor.email
            }
            $0.locale = input.context.locale
        }
        outbound0.prescription = Acme_Prescriptions_V1_Prescription.with {
            $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                $0.region = input.filter.region
            }
        }
        let reply0 = try await self.prescriptionsPrescriptionValidation.previewPrescription(outbound0)
        let outbound1 = Acme_Patients_V1_CompareAllergyOptionsRequest.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.patientID = reply0.prescription.counterparty.patientID
                }
            }
            $0.context = input.context
        }
        let step1: @Sendable () async throws -> Acme_Patients_V1_CompareAllergyOptionsResponse = {
            try await self.patientsAllergyCalculation.compareAllergyOptions(outbound1)
        }
        let reply1 = try await step1()
        let outbound2 = Acme_Telehealth_V1_CalculateVideoVisitRequest.with {
            $0.context = input.context
            $0.details = Acme_Telehealth_V1_CalculateVideoVisitRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.recipient = reply0.prescription.billingAddress.recipient
                }
            }
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply0.prescription.audit.etag
                }
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply0.prescription.counterparty.displayName
                }
                $0.participants = [
                    Acme_Telehealth_V1_VideoVisitParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = reply0.prescription.counterparty.email
                        }
                    }
                ]
            }
        }
        let reply2 = try await self.telehealthVideoVisitCalculation.calculateVideoVisit(outbound2)
        let outbound3 = Acme_Patients_V1_SummarizePatientsRequest.with {
            $0.context = input.context
            $0.patientID = reply0.prescription.counterparty.patientID
        }
        async let remote3 = self.patientsPatientQuery.summarizePatients(outbound3)
        async let persisted3 = store.count(tenant: input.context.tenantID)
        let (reply3, count3) = try await (remote3, persisted3)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count3)])
        return Acme_Patients_V1_ExportMedicalRecordsResponse.with {
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.lines = reply0.prescription.billingAddress.lines
                    $0.recipient = reply2.videoVisit.location.recipient
                    $0.region = input.filter.region
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply3.result.details
                $0.message = reply1.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processFindMedicalRecords(_ input: Acme_Patients_V1_FindMedicalRecordsRequest) async throws
        -> Acme_Patients_V1_FindMedicalRecordsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "audit", detail: input.filter.ownerID
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "FindMedicalRecords",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "FindMedicalRecords", detail: input.context.traceID
        )
        let outbound0 = Acme_Patients_V1_QuoteAllergyRequest.with {
            $0.context = input.context
            $0.details = Acme_Patients_V1_QuoteAllergyRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
            }
        }
        let reply0 = try await self.findMedicalRecordsStep0.execute(outbound0)
        return Acme_Patients_V1_FindMedicalRecordsResponse.with {
            $0.medicalRecords = [
                Acme_Patients_V1_MedicalRecord.with {
                    $0.counterparty = Acme_Patients_V1_PatientRef.with {
                        $0.email = reply0.allergy.subject.email
                    }
                }
            ]
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processLookupMedicalRecord(_ input: Acme_Patients_V1_LookupMedicalRecordRequest) async throws
        -> Acme_Patients_V1_LookupMedicalRecordResponse
    {
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "LookupMedicalRecord",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "LookupMedicalRecord", detail: input.context.traceID
        )
        let outbound0 = Acme_Metrics_V1_ExplainMetricSeriesDecisionRequest.with {
            $0.context = input.context
            $0.details = Acme_Metrics_V1_ExplainMetricSeriesDecisionRequest.Details.with {
                $0.locale = input.context.locale
            }
            $0.metricSeries = Acme_Metrics_V1_MetricSeries.with {
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.email = input.context.actor.email
                    $0.userID = input.context.actor.userID
                }
            }
        }
        let port0 = RPCOperations.port { (request: Acme_Metrics_V1_ExplainMetricSeriesDecisionRequest) in
            try await self.metricsMetricSeriesValidation.explainMetricSeriesDecision(request)
        }
        let reply0 = try await port0.execute(outbound0)
        return Acme_Patients_V1_LookupMedicalRecordResponse.with {
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = reply0.metricSeries.address.countryCode
                }
                $0.lines = [
                    Acme_Patients_V1_MedicalRecordLine.with {
                        $0.description_p = reply0.metricSeries.components["primary", default: .init()].description_p
                    }
                ]
                $0.medicalRecordID = input.medicalRecordID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processPeekMedicalRecord(_ input: Acme_Patients_V1_PeekMedicalRecordRequest) async throws
        -> Acme_Patients_V1_PeekMedicalRecordResponse
    {
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "PeekMedicalRecord",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "PeekMedicalRecord", detail: input.context.traceID
        )
        let outbound0 = Acme_Patients_V1_PreviewAllergyRequest.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.source = input.medicalRecordID
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.email = input.context.actor.email
                }
            }
            $0.context = input.context
            $0.details = Acme_Patients_V1_PreviewAllergyRequest.Details.with {
                $0.locale = input.context.locale
            }
        }
        let reply0 = try await self.peekMedicalRecordStep0(outbound0)
        let outbound1 = Acme_Telehealth_V1_ExplainVideoVisitCalculationRequest.with {
            $0.context = input.context
            $0.details = Acme_Telehealth_V1_ExplainVideoVisitCalculationRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply0.allergy.subject.email
                }
            }
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply0.allergy.subject.displayName
                    $0.email = input.context.actor.email
                    $0.userID = input.context.actor.userID
                }
            }
        }
        guard let execute1 = self.peekMedicalRecordStep1[settings.region] ?? self.peekMedicalRecordStep1["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply1 = try await execute1(outbound1)
        return Acme_Patients_V1_PeekMedicalRecordResponse.with {
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply1.videoVisit.audit.updatedBy
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = reply1.videoVisit.organizer.displayName
                }
                $0.medicalRecordID = input.medicalRecordID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processResolveMedicalRecords(_ input: Acme_Patients_V1_ResolveMedicalRecordsRequest) async throws
        -> Acme_Patients_V1_ResolveMedicalRecordsResponse
    {
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ResolveMedicalRecords",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "ResolveMedicalRecords", detail: input.context.traceID
        )
        let outbound0 = Acme_Documents_V1_ListDocumentsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Documents_V1_ListDocumentsRequest.Filter.with {
                $0.createdAfter = input.context.deadline
                $0.ownerID = input.context.traceID
            }
        }
        let reply0 = try await self.documentsDocument.listDocuments(outbound0)
        let outbound1 = Acme_Patients_V1_ExplainPatientDecisionRequest.with {
            $0.context = input.context
            $0.details = Acme_Patients_V1_ExplainPatientDecisionRequest.Details.with {
                $0.locale = input.context.locale
            }
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.attributes = reply0.result.details
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.context.actor.email
                }
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.context.actor.userID
                }
            }
        }
        let envelope1 = try Google_Protobuf_Any(message: outbound1)
        let unpacked1 = try Acme_Patients_V1_ExplainPatientDecisionRequest(unpackingAny: envelope1)
        let reply1 = try await self.patientsPatientValidation.explainPatientDecision(unpacked1)
        return Acme_Patients_V1_ResolveMedicalRecordsResponse.with {
            $0.medicalRecords = [
                Acme_Patients_V1_MedicalRecord.with {
                    $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                        $0.lines = reply1.patient.primaryAddress.lines
                    }
                }
            ]
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.message = reply1.outcome.message
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processSuggestMedicalRecords(_ input: Acme_Patients_V1_SuggestMedicalRecordsRequest) async throws
        -> Acme_Patients_V1_SuggestMedicalRecordsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.query)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "audit", detail: input.filter.query
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "SuggestMedicalRecords",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "SuggestMedicalRecords", detail: input.context.traceID
        )
        let outbound0 = Acme_Appointments_V1_ScoreAppointmentRequest.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.context.actor.userID
                }
                $0.participants = [
                    Acme_Appointments_V1_AppointmentParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = input.context.actor.email
                        }
                    }
                ]
            }
            $0.context = input.context
            $0.details = Acme_Appointments_V1_ScoreAppointmentRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
            }
        }
        let json0 = try outbound0.jsonString()
        let decoded0 = try Acme_Appointments_V1_ScoreAppointmentRequest(jsonString: json0)
        let reply0 = try await self.appointmentsAppointmentValidation.scoreAppointment(decoded0)
        let outbound1 = Acme_Patients_V1_FindPatientsRequest.forMedicalRecordQueryEndpointSuggestMedicalRecords1(
            input,
            reply0: reply0
        )
        let reply1 = try await self.patientsPatientQuery.findPatients(outbound1)
        return Acme_Patients_V1_SuggestMedicalRecordsResponse.with {
            $0.medicalRecords = [
                Acme_Patients_V1_MedicalRecord.with {
                    $0.audit = Acme_Common_V1_AuditInfo.with {
                        $0.createdAt = reply0.appointment.audit.createdAt
                    }
                }
            ]
            $0.pageInfo = Acme_Common_V1_PageInfo.with {
                $0.nextPageToken = reply1.pageInfo.nextPageToken
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply0.result.status
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processSummarizeMedicalRecords(_ input: Acme_Patients_V1_SummarizeMedicalRecordsRequest) async throws
        -> Acme_Patients_V1_SummarizeMedicalRecordsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.cron)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "audit", detail: input.details.cron
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "SummarizeMedicalRecords",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medical_record",
            action: "SummarizeMedicalRecords", detail: input.context.traceID
        )
        let outbound0 = Acme_Patients_V1_CalculateAllergyRequest.with {
            $0.context = input.context
            $0.reason = input.reason
        }
        let reply0 = try await self.patientsAllergyCalculation.calculateAllergy(
            outbound0, metadata: ["x-acme-region": .string(settings.region)]
        )
        let outbound1 = Acme_Prescriptions_V1_ExplainPrescriptionDecisionRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_ExplainPrescriptionDecisionRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply0.allergy.subject.email
                }
            }
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.lines = [
                    Acme_Prescriptions_V1_PrescriptionLine.with {
                        $0.attributes = reply0.allergy.attributes
                    }
                ]
            }
        }
        let reply1 = try await RPCOperations.call(outbound1) { request in
            try await self.prescriptionsPrescriptionValidation.explainPrescriptionDecision(request)
        }
        let outbound2 = Acme_Patients_V1_EstimateMedicalRecordRequest.with {
            $0.context = Projection.read(input, at: \Acme_Patients_V1_SummarizeMedicalRecordsRequest.context)
            $0.details = Acme_Patients_V1_EstimateMedicalRecordRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.region = Projection.read(
                        reply1,
                        at:
                            \Acme_Prescriptions_V1_ExplainPrescriptionDecisionResponse.prescription.billingAddress
                            .region)
                }
            }
        }
        let reply2 = try await self.patientsMedicalRecordCalculation.estimateMedicalRecord(outbound2)
        let outbound3 = Acme_Prescriptions_V1_ScorePrescriptionRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_ScorePrescriptionRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.region = reply2.medicalRecord.billingAddress.region
                }
            }
        }
        let step3: @Sendable () async throws -> Acme_Prescriptions_V1_ScorePrescriptionResponse = {
            try await self.prescriptionsPrescriptionValidation.scorePrescription(outbound3)
        }
        let reply3 = try await step3()
        return Acme_Patients_V1_SummarizeMedicalRecordsResponse.with {
            $0.period = input.details.period
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.details = reply3.result.details
                $0.message = reply1.result.message
                $0.referenceIds = reply1.result.referenceIds + reply2.result.referenceIds
                $0.status = Projection.firstValue(
                    [
                        reply0.result.status,
                        reply2.result.status,
                    ], default: .init())
            }
        }
    }
}
