import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Answers read-only questions about providers, for screens and reports.
final class ProviderQueryEndpoint: Acme_Appointments_V1_ProviderQueryService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let followUps = WorkQueue<Acme_Identity_V1_GetUserRequest>()
    let appointmentsAppointmentQuery: Acme_Appointments_V1_AppointmentQueryService.Client<MeshTransport>
    let appointmentsAppointmentValidation: Acme_Appointments_V1_AppointmentValidationService.Client<MeshTransport>
    let appointmentsClinicSlotCalculation: Acme_Appointments_V1_ClinicSlotCalculationService.Client<MeshTransport>
    let appointmentsProviderValidation: Acme_Appointments_V1_ProviderValidationService.Client<MeshTransport>
    let careplansCareGoalQuery: Acme_Careplans_V1_CareGoalQueryService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let identityUserValidation: Acme_Identity_V1_UserValidationService.Client<MeshTransport>
    let prescriptionsMedicationQuery: Acme_Prescriptions_V1_MedicationQueryService.Client<MeshTransport>
    let prescriptionsPrescription: Acme_Prescriptions_V1_PrescriptionService.Client<MeshTransport>
    let prescriptionsRefillCalculation: Acme_Prescriptions_V1_RefillCalculationService.Client<MeshTransport>
    let searchSearchIndexValidation: Acme_Search_V1_SearchIndexValidationService.Client<MeshTransport>
    let telehealthTriageValidation: Acme_Telehealth_V1_TriageValidationService.Client<MeshTransport>
    let lookupProviderStep0:
        any RPCPort<
            Acme_Prescriptions_V1_ExplainRefillCalculationRequest,
            Acme_Prescriptions_V1_ExplainRefillCalculationResponse
        >
    let peekProviderStep1:
        @Sendable (Acme_Careplans_V1_BrowseCareGoalsRequest) async throws -> Acme_Careplans_V1_BrowseCareGoalsResponse
    let resolveProvidersStep0:
        [String:
            @Sendable (Acme_Search_V1_ScoreSearchIndexRequest) async throws -> Acme_Search_V1_ScoreSearchIndexResponse]

    init(
        dependencies: any Dependencies,
        appointmentsAppointmentQuery: Acme_Appointments_V1_AppointmentQueryService.Client<MeshTransport>,
        appointmentsAppointmentValidation: Acme_Appointments_V1_AppointmentValidationService.Client<MeshTransport>,
        appointmentsClinicSlotCalculation: Acme_Appointments_V1_ClinicSlotCalculationService.Client<MeshTransport>,
        appointmentsProviderValidation: Acme_Appointments_V1_ProviderValidationService.Client<MeshTransport>,
        careplansCareGoalQuery: Acme_Careplans_V1_CareGoalQueryService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        identityUserValidation: Acme_Identity_V1_UserValidationService.Client<MeshTransport>,
        prescriptionsMedicationQuery: Acme_Prescriptions_V1_MedicationQueryService.Client<MeshTransport>,
        prescriptionsPrescription: Acme_Prescriptions_V1_PrescriptionService.Client<MeshTransport>,
        prescriptionsRefillCalculation: Acme_Prescriptions_V1_RefillCalculationService.Client<MeshTransport>,
        searchSearchIndexValidation: Acme_Search_V1_SearchIndexValidationService.Client<MeshTransport>,
        telehealthTriageValidation: Acme_Telehealth_V1_TriageValidationService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.appointmentsAppointmentQuery = appointmentsAppointmentQuery
        self.appointmentsAppointmentValidation = appointmentsAppointmentValidation
        self.appointmentsClinicSlotCalculation = appointmentsClinicSlotCalculation
        self.appointmentsProviderValidation = appointmentsProviderValidation
        self.careplansCareGoalQuery = careplansCareGoalQuery
        self.identityUser = identityUser
        self.identityUserValidation = identityUserValidation
        self.prescriptionsMedicationQuery = prescriptionsMedicationQuery
        self.prescriptionsPrescription = prescriptionsPrescription
        self.prescriptionsRefillCalculation = prescriptionsRefillCalculation
        self.searchSearchIndexValidation = searchSearchIndexValidation
        self.telehealthTriageValidation = telehealthTriageValidation
        self.lookupProviderStep0 = ClosurePort<
            Acme_Prescriptions_V1_ExplainRefillCalculationRequest,
            Acme_Prescriptions_V1_ExplainRefillCalculationResponse
        >({ request in try await prescriptionsRefillCalculation.explainRefillCalculation(request) })
        self.peekProviderStep1 = { request in try await careplansCareGoalQuery.browseCareGoals(request) }
        self.resolveProvidersStep0 = [
            "primary": { request in try await searchSearchIndexValidation.scoreSearchIndex(request) }
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

    /// Lists providers a page at a time.
    func browseProviders(
        request: ServerRequest<Acme_Appointments_V1_BrowseProvidersRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_BrowseProvidersResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processBrowseProviders(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Counts providers by status.
    func countProviders(
        request: ServerRequest<Acme_Appointments_V1_CountProvidersRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_CountProvidersResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCountProviders(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Streams every matching provider.
    func exportProviders(
        request: ServerRequest<Acme_Appointments_V1_ExportProvidersRequest>,
        context: ServerContext
    ) async throws -> StreamingServerResponse<Acme_Appointments_V1_ExportProvidersResponse> {
        return StreamingServerResponse { writer in
            try await CallerScope.$metadata.withValue(request.metadata) {
                let response = try await self.processExportProviders(request.message)
                try await writer.write(response)
                return [:]
            }
        }
    }

    /// Lists providers a page at a time.
    func findProviders(
        request: ServerRequest<Acme_Appointments_V1_FindProvidersRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_FindProvidersResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processFindProviders(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a provider.
    func lookupProvider(
        request: ServerRequest<Acme_Appointments_V1_LookupProviderRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_LookupProviderResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processLookupProvider(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a provider.
    func peekProvider(
        request: ServerRequest<Acme_Appointments_V1_PeekProviderRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_PeekProviderResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processPeekProvider(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns several providers at once.
    func resolveProviders(
        request: ServerRequest<Acme_Appointments_V1_ResolveProvidersRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_ResolveProvidersResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processResolveProviders(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists providers a page at a time.
    func suggestProviders(
        request: ServerRequest<Acme_Appointments_V1_SuggestProvidersRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_SuggestProvidersResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSuggestProviders(request.message)
            return ServerResponse(message: response)
        }
    }
}
