import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Moves a visit note between the states of its lifecycle.
final class VisitNoteLifecycleEndpoint: Acme_Telehealth_V1_VisitNoteLifecycleService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let followUps = WorkQueue<Acme_Identity_V1_GetUserRequest>()
    let auditAuditEventQuery: Acme_Audit_V1_AuditEventQueryService.Client<MeshTransport>
    let careplansVitalReporting: Acme_Careplans_V1_VitalReportingService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let identityUserQuery: Acme_Identity_V1_UserQueryService.Client<MeshTransport>
    let metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client<MeshTransport>
    let patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client<MeshTransport>
    let prescriptionsPrescription: Acme_Prescriptions_V1_PrescriptionService.Client<MeshTransport>
    let searchSearchIndex: Acme_Search_V1_SearchIndexService.Client<MeshTransport>
    let searchSearchIndexQuery: Acme_Search_V1_SearchIndexQueryService.Client<MeshTransport>
    let telehealthTriageCalculation: Acme_Telehealth_V1_TriageCalculationService.Client<MeshTransport>
    let telehealthTriageValidation: Acme_Telehealth_V1_TriageValidationService.Client<MeshTransport>
    let telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client<MeshTransport>
    let telehealthVideoVisitQuery: Acme_Telehealth_V1_VideoVisitQueryService.Client<MeshTransport>
    let telehealthVisitNoteCalculation: Acme_Telehealth_V1_VisitNoteCalculationService.Client<MeshTransport>
    let yardsYardCalculation: Acme_Yards_V1_YardCalculationService.Client<MeshTransport>
    let expireVisitNoteStep2:
        any RPCPort<Acme_Search_V1_ResolveSearchIndexesRequest, Acme_Search_V1_ResolveSearchIndexesResponse>
    let reinstateVisitNoteStep2:
        @Sendable (Acme_Telehealth_V1_ValidateTriageRequest) async throws -> Acme_Telehealth_V1_ValidateTriageResponse
    let renewVisitNoteStep0:
        [String:
            @Sendable (Acme_Telehealth_V1_RecalculateTriagesRequest) async throws ->
            Acme_Telehealth_V1_RecalculateTriagesResponse]

    init(
        dependencies: any Dependencies,
        auditAuditEventQuery: Acme_Audit_V1_AuditEventQueryService.Client<MeshTransport>,
        careplansVitalReporting: Acme_Careplans_V1_VitalReportingService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        identityUserQuery: Acme_Identity_V1_UserQueryService.Client<MeshTransport>,
        metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client<MeshTransport>,
        patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client<MeshTransport>,
        prescriptionsPrescription: Acme_Prescriptions_V1_PrescriptionService.Client<MeshTransport>,
        searchSearchIndex: Acme_Search_V1_SearchIndexService.Client<MeshTransport>,
        searchSearchIndexQuery: Acme_Search_V1_SearchIndexQueryService.Client<MeshTransport>,
        telehealthTriageCalculation: Acme_Telehealth_V1_TriageCalculationService.Client<MeshTransport>,
        telehealthTriageValidation: Acme_Telehealth_V1_TriageValidationService.Client<MeshTransport>,
        telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client<MeshTransport>,
        telehealthVideoVisitQuery: Acme_Telehealth_V1_VideoVisitQueryService.Client<MeshTransport>,
        telehealthVisitNoteCalculation: Acme_Telehealth_V1_VisitNoteCalculationService.Client<MeshTransport>,
        yardsYardCalculation: Acme_Yards_V1_YardCalculationService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.auditAuditEventQuery = auditAuditEventQuery
        self.careplansVitalReporting = careplansVitalReporting
        self.identityUser = identityUser
        self.identityUserQuery = identityUserQuery
        self.metricsMetricSeriesValidation = metricsMetricSeriesValidation
        self.patientsPatientQuery = patientsPatientQuery
        self.prescriptionsPrescription = prescriptionsPrescription
        self.searchSearchIndex = searchSearchIndex
        self.searchSearchIndexQuery = searchSearchIndexQuery
        self.telehealthTriageCalculation = telehealthTriageCalculation
        self.telehealthTriageValidation = telehealthTriageValidation
        self.telehealthVideoVisitCalculation = telehealthVideoVisitCalculation
        self.telehealthVideoVisitQuery = telehealthVideoVisitQuery
        self.telehealthVisitNoteCalculation = telehealthVisitNoteCalculation
        self.yardsYardCalculation = yardsYardCalculation
        self.expireVisitNoteStep2 = ClosurePort<
            Acme_Search_V1_ResolveSearchIndexesRequest, Acme_Search_V1_ResolveSearchIndexesResponse
        >({ request in try await searchSearchIndexQuery.resolveSearchIndexes(request) })
        self.reinstateVisitNoteStep2 = { request in try await telehealthTriageValidation.validateTriage(request) }
        self.renewVisitNoteStep0 = [
            "primary": { request in try await telehealthTriageCalculation.recalculateTriages(request) }
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

    /// Activates a visit note.
    func activateVisitNote(
        request: ServerRequest<Acme_Telehealth_V1_ActivateVisitNoteRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_ActivateVisitNoteResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processActivateVisitNote(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Expires a visit note.
    func expireVisitNote(
        request: ServerRequest<Acme_Telehealth_V1_ExpireVisitNoteRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_ExpireVisitNoteResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processExpireVisitNote(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a visit note.
    func getVisitNoteLifecycle(
        request: ServerRequest<Acme_Telehealth_V1_GetVisitNoteLifecycleRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_GetVisitNoteLifecycleResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetVisitNoteLifecycle(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Reinstates a visit note.
    func reinstateVisitNote(
        request: ServerRequest<Acme_Telehealth_V1_ReinstateVisitNoteRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_ReinstateVisitNoteResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processReinstateVisitNote(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Renews a visit note.
    func renewVisitNote(
        request: ServerRequest<Acme_Telehealth_V1_RenewVisitNoteRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_RenewVisitNoteResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRenewVisitNote(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Schedules a visit note.
    func scheduleVisitNoteExpiry(
        request: ServerRequest<Acme_Telehealth_V1_ScheduleVisitNoteExpiryRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_ScheduleVisitNoteExpiryResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processScheduleVisitNoteExpiry(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Suspends a visit note.
    func suspendVisitNote(
        request: ServerRequest<Acme_Telehealth_V1_SuspendVisitNoteRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_SuspendVisitNoteResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSuspendVisitNote(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Terminates a visit note.
    func terminateVisitNote(
        request: ServerRequest<Acme_Telehealth_V1_TerminateVisitNoteRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_TerminateVisitNoteResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processTerminateVisitNote(request.message)
            return ServerResponse(message: response)
        }
    }
}
