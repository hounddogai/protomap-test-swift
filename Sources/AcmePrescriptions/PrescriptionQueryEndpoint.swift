import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Answers read-only questions about prescriptions, for screens and reports.
final class PrescriptionQueryEndpoint: Acme_Prescriptions_V1_PrescriptionQueryService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let authorizationAccessPolicy: Acme_Authorization_V1_AccessPolicyService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let metricsMetricSeries: Acme_Metrics_V1_MetricSeriesService.Client<MeshTransport>
    let prescriptionsMedicationCalculation: Acme_Prescriptions_V1_MedicationCalculationService.Client<MeshTransport>
    let prescriptionsMedicationValidation: Acme_Prescriptions_V1_MedicationValidationService.Client<MeshTransport>
    let prescriptionsPrescriptionValidation: Acme_Prescriptions_V1_PrescriptionValidationService.Client<MeshTransport>
    let prescriptionsRefillCalculation: Acme_Prescriptions_V1_RefillCalculationService.Client<MeshTransport>
    let searchSearchIndex: Acme_Search_V1_SearchIndexService.Client<MeshTransport>
    let searchSearchIndexQuery: Acme_Search_V1_SearchIndexQueryService.Client<MeshTransport>
    let telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client<MeshTransport>
    let browsePrescriptionsStep0:
        any RPCPort<Acme_Search_V1_BatchGetSearchIndexesRequest, Acme_Search_V1_BatchGetSearchIndexesResponse>
    let exportPrescriptionsStep2:
        @Sendable (Acme_Prescriptions_V1_CalculateMedicationRequest) async throws ->
            Acme_Prescriptions_V1_CalculateMedicationResponse
    let peekPrescriptionStep0:
        [String:
            @Sendable (Acme_Authorization_V1_ListAccessPoliciesRequest) async throws ->
            Acme_Authorization_V1_ListAccessPoliciesResponse]

    init(
        dependencies: any Dependencies,
        authorizationAccessPolicy: Acme_Authorization_V1_AccessPolicyService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        metricsMetricSeries: Acme_Metrics_V1_MetricSeriesService.Client<MeshTransport>,
        prescriptionsMedicationCalculation: Acme_Prescriptions_V1_MedicationCalculationService.Client<MeshTransport>,
        prescriptionsMedicationValidation: Acme_Prescriptions_V1_MedicationValidationService.Client<MeshTransport>,
        prescriptionsPrescriptionValidation: Acme_Prescriptions_V1_PrescriptionValidationService.Client<MeshTransport>,
        prescriptionsRefillCalculation: Acme_Prescriptions_V1_RefillCalculationService.Client<MeshTransport>,
        searchSearchIndex: Acme_Search_V1_SearchIndexService.Client<MeshTransport>,
        searchSearchIndexQuery: Acme_Search_V1_SearchIndexQueryService.Client<MeshTransport>,
        telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.authorizationAccessPolicy = authorizationAccessPolicy
        self.identityUser = identityUser
        self.metricsMetricSeries = metricsMetricSeries
        self.prescriptionsMedicationCalculation = prescriptionsMedicationCalculation
        self.prescriptionsMedicationValidation = prescriptionsMedicationValidation
        self.prescriptionsPrescriptionValidation = prescriptionsPrescriptionValidation
        self.prescriptionsRefillCalculation = prescriptionsRefillCalculation
        self.searchSearchIndex = searchSearchIndex
        self.searchSearchIndexQuery = searchSearchIndexQuery
        self.telehealthVideoVisit = telehealthVideoVisit
        self.browsePrescriptionsStep0 = ClosurePort<
            Acme_Search_V1_BatchGetSearchIndexesRequest, Acme_Search_V1_BatchGetSearchIndexesResponse
        >({ request in try await searchSearchIndex.batchGetSearchIndexes(request) })
        self.exportPrescriptionsStep2 = { request in
            try await prescriptionsMedicationCalculation.calculateMedication(request)
        }
        self.peekPrescriptionStep0 = [
            "primary": { request in try await authorizationAccessPolicy.listAccessPolicies(request) }
        ]
    }

    /// Lists prescriptions a page at a time.
    func browsePrescriptions(
        request: ServerRequest<Acme_Prescriptions_V1_BrowsePrescriptionsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_BrowsePrescriptionsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processBrowsePrescriptions(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Counts prescriptions by status.
    func countPrescriptions(
        request: ServerRequest<Acme_Prescriptions_V1_CountPrescriptionsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_CountPrescriptionsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCountPrescriptions(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Streams every matching prescription.
    func exportPrescriptions(
        request: ServerRequest<Acme_Prescriptions_V1_ExportPrescriptionsRequest>,
        context: ServerContext
    ) async throws -> StreamingServerResponse<Acme_Prescriptions_V1_ExportPrescriptionsResponse> {
        return StreamingServerResponse { writer in
            try await CallerScope.$metadata.withValue(request.metadata) {
                let response = try await self.processExportPrescriptions(request.message)
                try await writer.write(response)
                return [:]
            }
        }
    }

    /// Lists prescriptions a page at a time.
    func findPrescriptions(
        request: ServerRequest<Acme_Prescriptions_V1_FindPrescriptionsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_FindPrescriptionsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processFindPrescriptions(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a prescription.
    func lookupPrescription(
        request: ServerRequest<Acme_Prescriptions_V1_LookupPrescriptionRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_LookupPrescriptionResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processLookupPrescription(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a prescription.
    func peekPrescription(
        request: ServerRequest<Acme_Prescriptions_V1_PeekPrescriptionRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_PeekPrescriptionResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processPeekPrescription(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns several prescriptions at once.
    func resolvePrescriptions(
        request: ServerRequest<Acme_Prescriptions_V1_ResolvePrescriptionsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ResolvePrescriptionsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processResolvePrescriptions(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists prescriptions a page at a time.
    func suggestPrescriptions(
        request: ServerRequest<Acme_Prescriptions_V1_SuggestPrescriptionsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_SuggestPrescriptionsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSuggestPrescriptions(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Summarizes a prescription.
    func summarizePrescriptions(
        request: ServerRequest<Acme_Prescriptions_V1_SummarizePrescriptionsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_SummarizePrescriptionsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSummarizePrescriptions(request.message)
            return ServerResponse(message: response)
        }
    }
}
