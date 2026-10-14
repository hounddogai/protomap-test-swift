import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Computes the figures of a medication, such as totals, taxes, and estimates.
final class MedicationCalculationEndpoint: Acme_Prescriptions_V1_MedicationCalculationService.ServiceProtocol {
    private let store: any RecordRepository
    private let logger: Logger
    private let settings: Settings
    private let boxofficeBoxOfficeSale: Acme_Boxoffice_V1_BoxOfficeSaleService.Client<MeshTransport>
    private let careplansCarePlanQuery: Acme_Careplans_V1_CarePlanQueryService.Client<MeshTransport>
    private let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    private let identityUserValidation: Acme_Identity_V1_UserValidationService.Client<MeshTransport>
    private let metricsMetricSeriesQuery: Acme_Metrics_V1_MetricSeriesQueryService.Client<MeshTransport>
    private let prescriptionsPrescriptionCalculation:
        Acme_Prescriptions_V1_PrescriptionCalculationService.Client<MeshTransport>
    private let searchSearchIndex: Acme_Search_V1_SearchIndexService.Client<MeshTransport>
    private let searchSearchIndexValidation: Acme_Search_V1_SearchIndexValidationService.Client<MeshTransport>
    private let sponsorshipsSponsorCalculation: Acme_Sponsorships_V1_SponsorCalculationService.Client<MeshTransport>
    private let telehealthTriageValidation: Acme_Telehealth_V1_TriageValidationService.Client<MeshTransport>
    private let telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client<MeshTransport>
    private let venuesVenue: Acme_Venues_V1_VenueService.Client<MeshTransport>
    private let venuesVenueQuery: Acme_Venues_V1_VenueQueryService.Client<MeshTransport>

    init(
        dependencies: any Dependencies,
        boxofficeBoxOfficeSale: Acme_Boxoffice_V1_BoxOfficeSaleService.Client<MeshTransport>,
        careplansCarePlanQuery: Acme_Careplans_V1_CarePlanQueryService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        identityUserValidation: Acme_Identity_V1_UserValidationService.Client<MeshTransport>,
        metricsMetricSeriesQuery: Acme_Metrics_V1_MetricSeriesQueryService.Client<MeshTransport>,
        prescriptionsPrescriptionCalculation: Acme_Prescriptions_V1_PrescriptionCalculationService.Client<
            MeshTransport
        >,
        searchSearchIndex: Acme_Search_V1_SearchIndexService.Client<MeshTransport>,
        searchSearchIndexValidation: Acme_Search_V1_SearchIndexValidationService.Client<MeshTransport>,
        sponsorshipsSponsorCalculation: Acme_Sponsorships_V1_SponsorCalculationService.Client<MeshTransport>,
        telehealthTriageValidation: Acme_Telehealth_V1_TriageValidationService.Client<MeshTransport>,
        telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client<MeshTransport>,
        venuesVenue: Acme_Venues_V1_VenueService.Client<MeshTransport>,
        venuesVenueQuery: Acme_Venues_V1_VenueQueryService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.boxofficeBoxOfficeSale = boxofficeBoxOfficeSale
        self.careplansCarePlanQuery = careplansCarePlanQuery
        self.identityUser = identityUser
        self.identityUserValidation = identityUserValidation
        self.metricsMetricSeriesQuery = metricsMetricSeriesQuery
        self.prescriptionsPrescriptionCalculation = prescriptionsPrescriptionCalculation
        self.searchSearchIndex = searchSearchIndex
        self.searchSearchIndexValidation = searchSearchIndexValidation
        self.sponsorshipsSponsorCalculation = sponsorshipsSponsorCalculation
        self.telehealthTriageValidation = telehealthTriageValidation
        self.telehealthVideoVisit = telehealthVideoVisit
        self.venuesVenue = venuesVenue
        self.venuesVenueQuery = venuesVenueQuery
    }

    /// Calculates a medication.
    func calculateMedication(
        request: ServerRequest<Acme_Prescriptions_V1_CalculateMedicationRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_CalculateMedicationResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCalculateMedication(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Compares a medication.
    func compareMedicationOptions(
        request: ServerRequest<Acme_Prescriptions_V1_CompareMedicationOptionsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_CompareMedicationOptionsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCompareMedicationOptions(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Estimates a medication.
    func estimateMedication(
        request: ServerRequest<Acme_Prescriptions_V1_EstimateMedicationRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_EstimateMedicationResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processEstimateMedication(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Explains a medication.
    func explainMedicationCalculation(
        request: ServerRequest<Acme_Prescriptions_V1_ExplainMedicationCalculationRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ExplainMedicationCalculationResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processExplainMedicationCalculation(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a medication.
    func getMedicationRates(
        request: ServerRequest<Acme_Prescriptions_V1_GetMedicationRatesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_GetMedicationRatesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetMedicationRates(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Recalculates a medication.
    func recalculateMedications(
        request: ServerRequest<Acme_Prescriptions_V1_RecalculateMedicationsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_RecalculateMedicationsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRecalculateMedications(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Simulates a medication.
    func simulateMedication(
        request: ServerRequest<Acme_Prescriptions_V1_SimulateMedicationRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_SimulateMedicationResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSimulateMedication(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processCalculateMedication(_ input: Acme_Prescriptions_V1_CalculateMedicationRequest) async throws
        -> Acme_Prescriptions_V1_CalculateMedicationResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.currencyCode)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "audit", detail: input.details.currencyCode
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "CalculateMedication",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicationRecord(input.medication, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let importFrame = Acme_Telehealth_V1_BatchCreateVideoVisitsRequest.with {
            $0.context = input.context
        }
        _ = try await self.telehealthVideoVisit.batchCreateVideoVisits { writer in
            try await writer.write(importFrame)
        }
        let outbound0 = Acme_Boxoffice_V1_UpdateBoxOfficeSaleRequest.with {
            $0.boxOfficeSale = Acme_Boxoffice_V1_BoxOfficeSale.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = input.details.destination.countryCode
                }
            }
            $0.context = input.context
        }
        let envelope0 = try Google_Protobuf_Any(message: outbound0)
        let unpacked0 = try Acme_Boxoffice_V1_UpdateBoxOfficeSaleRequest(unpackingAny: envelope0)
        let reply0 = try await self.boxofficeBoxOfficeSale.updateBoxOfficeSale(unpacked0)
        let selection1_1: String
        switch input.medication.locator {
        case .address(let address):
            selection1_1 = address.countryCode
        default: selection1_1 = .init()
        }
        let selection1_3: String
        switch input.medication.locator {
        case .address(let address):
            selection1_3 = address.postalCode
        default: selection1_3 = .init()
        }
        let selection1_4: String
        switch input.medication.locator {
        case .address(let address):
            selection1_4 = address.locality
        default: selection1_4 = .init()
        }
        let outbound1 = Acme_Prescriptions_V1_ComparePrescriptionOptionsRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_ComparePrescriptionOptionsRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = selection1_1
                    $0.locality = selection1_4
                    $0.region = reply0.boxOfficeSale.billingAddress.region
                }
            }
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = selection1_3
                }
            }
        }
        let reply1 = try await self.prescriptionsPrescriptionCalculation.comparePrescriptionOptions(outbound1)
        let outbound2 = Acme_Prescriptions_V1_CalculatePrescriptionRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_CalculatePrescriptionRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.lines = input.details.destination.lines
                }
            }
        }
        let json2 = try outbound2.jsonString()
        let decoded2 = try Acme_Prescriptions_V1_CalculatePrescriptionRequest(jsonString: json2)
        let reply2 = try await self.prescriptionsPrescriptionCalculation.calculatePrescription(decoded2)
        let outbound3 = Acme_Search_V1_UpdateSearchIndexRequest.forMedicationCalculationEndpointCalculateMedication3(
            input,
            reply0: reply0,
            reply2: reply2
        )
        let reply3 = try await self.searchSearchIndex.updateSearchIndex(outbound3)
        return Acme_Prescriptions_V1_CalculateMedicationResponse.with {
            $0.breakdown = Acme_Prescriptions_V1_CalculateMedicationResponse.Breakdown.with {
                $0.total = Projection.firstValue(
                    [
                        reply0.boxOfficeSale.total,
                        reply2.breakdown.total,
                    ], default: .init())
            }
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply0.boxOfficeSale.audit.createdAt
                }
                $0.medicationID = input.medicationID
                $0.owner = reply3.searchIndex.owner
                $0.specs = input.medication.specs
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply3.result.referenceIds
                $0.status = reply1.result.status
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processCompareMedicationOptions(_ input: Acme_Prescriptions_V1_CompareMedicationOptionsRequest) async throws
        -> Acme_Prescriptions_V1_CompareMedicationOptionsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.currencyCode)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "audit", detail: input.details.currencyCode
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "CompareMedicationOptions",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicationRecord(input.medication, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let selection0_1: String
        switch input.medication.locator {
        case .address(let address):
            selection0_1 = address.region
        default: selection0_1 = .init()
        }
        let outbound0 = Acme_Metrics_V1_CountMetricSeriesesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Metrics_V1_CountMetricSeriesesRequest.Filter.with {
                $0.createdAfter = input.medication.audit.createdAt
                $0.region = selection0_1
            }
        }
        let reply0 = try await self.metricsMetricSeriesQuery.countMetricSerieses(outbound0)
        let selection1_1: String
        switch input.medication.locator {
        case .address(let address):
            selection1_1 = address.region
        default: selection1_1 = .init()
        }
        let selection1_2: String
        switch input.medication.locator {
        case .address(let address):
            selection1_2 = address.postalCode
        default: selection1_2 = .init()
        }
        let selection1_3: [String]
        switch input.medication.locator {
        case .address(let address):
            selection1_3 = address.lines
        default: selection1_3 = .init()
        }
        let outbound1 = Acme_Prescriptions_V1_EstimatePrescriptionRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_EstimatePrescriptionRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.recipient = input.details.destination.recipient
                }
            }
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.lines = selection1_3
                    $0.postalCode = selection1_2
                    $0.region = selection1_1
                }
            }
        }
        let reply1 = try await self.prescriptionsPrescriptionCalculation.estimatePrescription(outbound1)
        let outbound2 = Acme_Careplans_V1_ResolveCarePlansRequest.with {
            $0.context = input.context
        }
        let reply2 = try await self.careplansCarePlanQuery.resolveCarePlans(
            outbound2, metadata: ["x-acme-region": .string(settings.region)]
        )
        return Acme_Prescriptions_V1_CompareMedicationOptionsResponse.with {
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.medicationID = input.medicationID
                $0.owner = input.medication.owner
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply2.result.message
                $0.referenceIds = reply1.result.referenceIds
                $0.status = Projection.firstValue(
                    [
                        reply0.result.status,
                        reply1.result.status,
                    ], default: .init())
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processEstimateMedication(_ input: Acme_Prescriptions_V1_EstimateMedicationRequest) async throws
        -> Acme_Prescriptions_V1_EstimateMedicationResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.currencyCode)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "audit", detail: input.details.currencyCode
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "EstimateMedication",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicationRecord(input.medication, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Venues_V1_CountVenuesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Venues_V1_CountVenuesRequest.Filter.with {
                $0.createdAfter = input.medication.audit.createdAt
                $0.ownerID = input.medication.components["primary", default: .init()].componentID
                $0.region = input.details.destination.region
            }
        }
        let reply0 = try await RPCOperations.call(outbound0) { request in
            try await self.venuesVenueQuery.countVenues(request)
        }
        let outbound1 = Acme_Telehealth_V1_LintTriagesRequest.with {
            $0.context = Projection.read(input, at: \Acme_Prescriptions_V1_EstimateMedicationRequest.context)
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = Projection.read(
                        input, at: \Acme_Prescriptions_V1_EstimateMedicationRequest.medication.audit.updatedAt)
                    $0.updatedBy = Projection.read(
                        input, at: \Acme_Prescriptions_V1_EstimateMedicationRequest.medication.audit.updatedBy)
                }
                $0.comments = [
                    Acme_Telehealth_V1_TriageComment.with {
                        $0.createdAt = Projection.read(
                            input, at: \Acme_Prescriptions_V1_EstimateMedicationRequest.medication.audit.createdAt)
                    }
                ]
            }
        }
        let reply1 = try await self.telehealthTriageValidation.lintTriages(outbound1)
        return Acme_Prescriptions_V1_EstimateMedicationResponse.with {
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.capacity = input.medication.capacity
                $0.medicationID = input.medicationID
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.email = reply1.triage.assignee.email
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.details = reply0.result.details
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processExplainMedicationCalculation(_ input: Acme_Prescriptions_V1_ExplainMedicationCalculationRequest)
        async throws -> Acme_Prescriptions_V1_ExplainMedicationCalculationResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.contact.email)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "audit", detail: input.details.contact.email
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "ExplainMedicationCalculation",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicationRecord(input.medication, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let selection0_1: String
        switch input.medication.locator {
        case .address(let address):
            selection0_1 = address.region
        default: selection0_1 = .init()
        }
        let outbound0 = Acme_Prescriptions_V1_EstimatePrescriptionRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_EstimatePrescriptionRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.region = selection0_1
                }
            }
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.medication.audit.createdAt
                }
            }
        }
        let reply0 = try await self.prescriptionsPrescriptionCalculation.estimatePrescription(outbound0)
        let selection1_2: String
        switch input.medication.locator {
        case .address(let address):
            selection1_2 = address.countryCode
        default: selection1_2 = .init()
        }
        let selection1_3: String
        switch input.medication.locator {
        case .address(let address):
            selection1_3 = address.locality
        default: selection1_3 = .init()
        }
        let outbound1 = Acme_Prescriptions_V1_CalculatePrescriptionRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_CalculatePrescriptionRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.locality = selection1_3
                }
            }
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = input.medication.audit.etag
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = selection1_2
                }
            }
        }
        let reply1 = try await self.prescriptionsPrescriptionCalculation.calculatePrescription(outbound1)
        let selection2_4: [String]
        switch input.medication.locator {
        case .address(let address):
            selection2_4 = address.lines
        default: selection2_4 = .init()
        }
        let outbound2 = Acme_Search_V1_ExplainSearchIndexDecisionRequest.with {
            $0.context = input.context
            $0.details = Acme_Search_V1_ExplainSearchIndexDecisionRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.name = input.details.contact.name
                    $0.phone = input.details.contact.phone
                }
            }
            $0.searchIndex = Acme_Search_V1_SearchIndex.with {
                $0.address = Acme_Common_V1_PostalAddress.with {
                    $0.lines = selection2_4
                    $0.postalCode = reply0.prescription.billingAddress.postalCode
                }
            }
        }
        let reply2 = try await self.searchSearchIndexValidation.explainSearchIndexDecision(outbound2)
        return Acme_Prescriptions_V1_ExplainMedicationCalculationResponse.with {
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply0.prescription.audit.updatedAt
                }
                $0.code = input.medication.code
                $0.components = [
                    "primary": Acme_Prescriptions_V1_MedicationComponent.with {
                        $0.description_p = reply2.searchIndex.components["primary", default: .init()].description_p
                    }
                ]
                $0.medicationID = input.medicationID
            }
            $0.outcome = Acme_Prescriptions_V1_ExplainMedicationCalculationResponse.Outcome.with {
                $0.message = reply1.result.message
                $0.status = reply0.result.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply2.result.details
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processGetMedicationRates(_ input: Acme_Prescriptions_V1_GetMedicationRatesRequest) async throws
        -> Acme_Prescriptions_V1_GetMedicationRatesResponse
    {
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "GetMedicationRates",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "GetMedicationRates", detail: input.context.traceID
        )
        return Acme_Prescriptions_V1_GetMedicationRatesResponse.with {
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.medicationID = input.medicationID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processRecalculateMedications(_ input: Acme_Prescriptions_V1_RecalculateMedicationsRequest) async throws
        -> Acme_Prescriptions_V1_RecalculateMedicationsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.currencyCode)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "audit", detail: input.details.currencyCode
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "RecalculateMedications",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicationRecord(input.medication, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let selection0_1: String
        switch input.medication.locator {
        case .address(let address):
            selection0_1 = address.postalCode
        default: selection0_1 = .init()
        }
        let outbound0 = Acme_Identity_V1_ValidateUserRequest.with {
            $0.context = input.context
            $0.user = Acme_Identity_V1_User.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = input.medication.audit.updatedAt
                }
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = input.details.destination.countryCode
                    $0.postalCode = selection0_1
                }
            }
        }
        let reply0 = try await self.identityUserValidation.validateUser(outbound0)
        let selection1_1: String
        switch input.medication.locator {
        case .address(let address):
            selection1_1 = address.postalCode
        default: selection1_1 = .init()
        }
        let selection1_2: String
        switch input.medication.locator {
        case .address(let address):
            selection1_2 = address.locality
        default: selection1_2 = .init()
        }
        let outbound1 = Acme_Venues_V1_UpdateVenueRequest.with {
            $0.context = input.context
            $0.venue = Acme_Venues_V1_Venue.with {
                $0.address = Acme_Common_V1_PostalAddress.with {
                    $0.lines = reply0.user.primaryAddress.lines
                    $0.locality = selection1_2
                    $0.postalCode = selection1_1
                    $0.region = reply0.user.primaryAddress.region
                }
            }
        }
        let reply1 = try await self.venuesVenue.updateVenue(outbound1)
        let selection2_2: String
        switch reply1.venue.locator {
        case .address(let address):
            selection2_2 = address.locality
        default: selection2_2 = .init()
        }
        let outbound2 = Acme_Sponsorships_V1_CalculateSponsorRequest.with {
            $0.context = input.context
            $0.details = Acme_Sponsorships_V1_CalculateSponsorRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.locality = input.details.destination.locality
                }
            }
            $0.sponsor = Acme_Sponsorships_V1_Sponsor.with {
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.locality = selection2_2
                    $0.postalCode = reply0.user.primaryAddress.postalCode
                    $0.region = input.details.destination.region
                }
            }
        }
        let reply2 = try await self.sponsorshipsSponsorCalculation.calculateSponsor(outbound2)
        let selection3_1: String
        switch reply1.venue.locator {
        case .address(let address):
            selection3_1 = address.locality
        default: selection3_1 = .init()
        }
        let outbound3 = Acme_Prescriptions_V1_ExplainPrescriptionCalculationRequest.with {
            $0.context = input.context
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = reply0.user.primaryAddress.countryCode
                    $0.locality = selection3_1
                    $0.postalCode = reply0.user.primaryAddress.postalCode
                }
            }
        }
        let reply3 = try await self.prescriptionsPrescriptionCalculation.explainPrescriptionCalculation(outbound3)
        return Acme_Prescriptions_V1_RecalculateMedicationsResponse.with {
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = reply3.prescription.audit.updatedBy
                }
                $0.dimensions = Acme_Prescriptions_V1_MedicationDimensions.with {
                    $0.weight = reply1.venue.dimensions.weight
                }
                $0.medicationID = input.medicationID
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply2.sponsor.relationshipManager.displayName
                    $0.userID = reply2.sponsor.relationshipManager.userID
                }
                $0.status = input.medication.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.referenceIds = reply0.result.referenceIds
                $0.status = reply3.result.status
            }
        }
    }

    /// Execute the prescriptions workflow and project its upstream replies.
    func processSimulateMedication(_ input: Acme_Prescriptions_V1_SimulateMedicationRequest) async throws
        -> Acme_Prescriptions_V1_SimulateMedicationResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.currencyCode)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "medication",
            action: "audit", detail: input.details.currencyCode
        )
        try Validation.context(input.context)
        try Task.checkCancellation()
        logger.info(
            "SimulateMedication",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try MedicationRecord(input.medication, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let selection0_2: String
        switch input.medication.locator {
        case .address(let address):
            selection0_2 = address.postalCode
        default: selection0_2 = .init()
        }
        let outbound0 = Acme_Prescriptions_V1_CalculatePrescriptionRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_CalculatePrescriptionRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = selection0_2
                }
            }
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = input.medication.audit.createdBy
                }
                $0.lines = [
                    Acme_Prescriptions_V1_PrescriptionLine.with {
                        $0.quantity = input.medication.components["primary", default: .init()].quantity
                    }
                ]
            }
        }
        let reply0 = try await self.prescriptionsPrescriptionCalculation.calculatePrescription(outbound0)
        return Acme_Prescriptions_V1_SimulateMedicationResponse.with {
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.medicationID = input.medicationID
                $0.specs = input.medication.specs
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.status = "ok"
            }
        }
    }
}
