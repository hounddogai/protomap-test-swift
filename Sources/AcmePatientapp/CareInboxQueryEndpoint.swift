import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Answers read-only questions about care inboxes, for screens and reports.
final class CareInboxQueryEndpoint: Acme_Patientapp_V1_CareInboxQueryService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let followUps = WorkQueue<Acme_Identity_V1_GetUserRequest>()
    let careplansCareGoalApproval: Acme_Careplans_V1_CareGoalApprovalService.Client<MeshTransport>
    let careplansCareGoalWorkflow: Acme_Careplans_V1_CareGoalWorkflowService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let insurancePolicyQuery: Acme_Insurance_V1_PolicyQueryService.Client<MeshTransport>
    let metricsMetricSeriesQuery: Acme_Metrics_V1_MetricSeriesQueryService.Client<MeshTransport>
    let notificationsNotification: Acme_Notifications_V1_NotificationService.Client<MeshTransport>
    let patientappCareInboxIntegration: Acme_Patientapp_V1_CareInboxIntegrationService.Client<MeshTransport>
    let patientappCareInboxNotification: Acme_Patientapp_V1_CareInboxNotificationService.Client<MeshTransport>
    let patientappPatientHomeNotification: Acme_Patientapp_V1_PatientHomeNotificationService.Client<MeshTransport>
    let patientappPatientHomeQuery: Acme_Patientapp_V1_PatientHomeQueryService.Client<MeshTransport>
    let patientsMedicalRecordApproval: Acme_Patients_V1_MedicalRecordApprovalService.Client<MeshTransport>
    let patientsMedicalRecordSync: Acme_Patients_V1_MedicalRecordSyncService.Client<MeshTransport>
    let prescriptionsMedicationSync: Acme_Prescriptions_V1_MedicationSyncService.Client<MeshTransport>
    let prescriptionsPrescriptionReporting: Acme_Prescriptions_V1_PrescriptionReportingService.Client<MeshTransport>
    let findCareInboxesStep0:
        any RPCPort<Acme_Patientapp_V1_FindPatientHomesRequest, Acme_Patientapp_V1_FindPatientHomesResponse>
    let peekCareInboxStep0:
        @Sendable (Acme_Metrics_V1_BrowseMetricSeriesesRequest) async throws ->
            Acme_Metrics_V1_BrowseMetricSeriesesResponse
    let resolveCareInboxesStep0:
        [String:
            @Sendable (Acme_Notifications_V1_BatchGetNotificationsRequest) async throws ->
            Acme_Notifications_V1_BatchGetNotificationsResponse]

    init(
        dependencies: any Dependencies,
        careplansCareGoalApproval: Acme_Careplans_V1_CareGoalApprovalService.Client<MeshTransport>,
        careplansCareGoalWorkflow: Acme_Careplans_V1_CareGoalWorkflowService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        insurancePolicyQuery: Acme_Insurance_V1_PolicyQueryService.Client<MeshTransport>,
        metricsMetricSeriesQuery: Acme_Metrics_V1_MetricSeriesQueryService.Client<MeshTransport>,
        notificationsNotification: Acme_Notifications_V1_NotificationService.Client<MeshTransport>,
        patientappCareInboxIntegration: Acme_Patientapp_V1_CareInboxIntegrationService.Client<MeshTransport>,
        patientappCareInboxNotification: Acme_Patientapp_V1_CareInboxNotificationService.Client<MeshTransport>,
        patientappPatientHomeNotification: Acme_Patientapp_V1_PatientHomeNotificationService.Client<MeshTransport>,
        patientappPatientHomeQuery: Acme_Patientapp_V1_PatientHomeQueryService.Client<MeshTransport>,
        patientsMedicalRecordApproval: Acme_Patients_V1_MedicalRecordApprovalService.Client<MeshTransport>,
        patientsMedicalRecordSync: Acme_Patients_V1_MedicalRecordSyncService.Client<MeshTransport>,
        prescriptionsMedicationSync: Acme_Prescriptions_V1_MedicationSyncService.Client<MeshTransport>,
        prescriptionsPrescriptionReporting: Acme_Prescriptions_V1_PrescriptionReportingService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.careplansCareGoalApproval = careplansCareGoalApproval
        self.careplansCareGoalWorkflow = careplansCareGoalWorkflow
        self.identityUser = identityUser
        self.insurancePolicyQuery = insurancePolicyQuery
        self.metricsMetricSeriesQuery = metricsMetricSeriesQuery
        self.notificationsNotification = notificationsNotification
        self.patientappCareInboxIntegration = patientappCareInboxIntegration
        self.patientappCareInboxNotification = patientappCareInboxNotification
        self.patientappPatientHomeNotification = patientappPatientHomeNotification
        self.patientappPatientHomeQuery = patientappPatientHomeQuery
        self.patientsMedicalRecordApproval = patientsMedicalRecordApproval
        self.patientsMedicalRecordSync = patientsMedicalRecordSync
        self.prescriptionsMedicationSync = prescriptionsMedicationSync
        self.prescriptionsPrescriptionReporting = prescriptionsPrescriptionReporting
        self.findCareInboxesStep0 = ClosurePort<
            Acme_Patientapp_V1_FindPatientHomesRequest, Acme_Patientapp_V1_FindPatientHomesResponse
        >({ request in try await patientappPatientHomeQuery.findPatientHomes(request) })
        self.peekCareInboxStep0 = { request in try await metricsMetricSeriesQuery.browseMetricSerieses(request) }
        self.resolveCareInboxesStep0 = [
            "primary": { request in try await notificationsNotification.batchGetNotifications(request) }
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

    /// Lists care inboxes a page at a time.
    func browseCareInboxes(
        request: ServerRequest<Acme_Patientapp_V1_BrowseCareInboxesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_BrowseCareInboxesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processBrowseCareInboxes(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Counts care inboxes by status.
    func countCareInboxes(
        request: ServerRequest<Acme_Patientapp_V1_CountCareInboxesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_CountCareInboxesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCountCareInboxes(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Streams every matching care inbox.
    func exportCareInboxes(
        request: ServerRequest<Acme_Patientapp_V1_ExportCareInboxesRequest>,
        context: ServerContext
    ) async throws -> StreamingServerResponse<Acme_Patientapp_V1_ExportCareInboxesResponse> {
        return StreamingServerResponse { writer in
            try await CallerScope.$metadata.withValue(request.metadata) {
                let response = try await self.processExportCareInboxes(request.message)
                try await writer.write(response)
                return [:]
            }
        }
    }

    /// Lists care inboxes a page at a time.
    func findCareInboxes(
        request: ServerRequest<Acme_Patientapp_V1_FindCareInboxesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_FindCareInboxesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processFindCareInboxes(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a care inbox.
    func lookupCareInbox(
        request: ServerRequest<Acme_Patientapp_V1_LookupCareInboxRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_LookupCareInboxResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processLookupCareInbox(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a care inbox.
    func peekCareInbox(
        request: ServerRequest<Acme_Patientapp_V1_PeekCareInboxRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_PeekCareInboxResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processPeekCareInbox(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns several care inboxes at once.
    func resolveCareInboxes(
        request: ServerRequest<Acme_Patientapp_V1_ResolveCareInboxesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_ResolveCareInboxesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processResolveCareInboxes(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists care inboxes a page at a time.
    func suggestCareInboxes(
        request: ServerRequest<Acme_Patientapp_V1_SuggestCareInboxesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_SuggestCareInboxesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSuggestCareInboxes(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Summarizes a care inbox.
    func summarizeCareInboxes(
        request: ServerRequest<Acme_Patientapp_V1_SummarizeCareInboxesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_SummarizeCareInboxesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSummarizeCareInboxes(request.message)
            return ServerResponse(message: response)
        }
    }
}
