import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Builds and schedules reports about medical records.
final class MedicalRecordReportingEndpoint: Acme_Patients_V1_MedicalRecordReportingService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let catalogProductCalculation: Acme_Catalog_V1_ProductCalculationService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let keymanagementCryptoKeyCalculation: Acme_Keymanagement_V1_CryptoKeyCalculationService.Client<MeshTransport>
    let metricsMetricSeries: Acme_Metrics_V1_MetricSeriesService.Client<MeshTransport>
    let notificationsNotification: Acme_Notifications_V1_NotificationService.Client<MeshTransport>
    let notificationsNotificationValidation: Acme_Notifications_V1_NotificationValidationService.Client<MeshTransport>
    let patientsAllergyImport: Acme_Patients_V1_AllergyImportService.Client<MeshTransport>
    let patientsAllergySync: Acme_Patients_V1_AllergySyncService.Client<MeshTransport>
    let patientsMedicalRecordSync: Acme_Patients_V1_MedicalRecordSyncService.Client<MeshTransport>
    let patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client<MeshTransport>
    let prescriptionsPrescriptionSync: Acme_Prescriptions_V1_PrescriptionSyncService.Client<MeshTransport>
    let prescriptionsRefillWorkflow: Acme_Prescriptions_V1_RefillWorkflowService.Client<MeshTransport>
    let searchSearchIndexQuery: Acme_Search_V1_SearchIndexQueryService.Client<MeshTransport>
    let telehealthVisitNoteLifecycle: Acme_Telehealth_V1_VisitNoteLifecycleService.Client<MeshTransport>
    let deleteMedicalRecordReportStep3:
        any RPCPort<Acme_Patients_V1_ReconcileMedicalRecordsRequest, Acme_Patients_V1_ReconcileMedicalRecordsResponse>
    let listMedicalRecordReportsStep0:
        @Sendable (Acme_Patients_V1_ListMedicalRecordConflictsRequest) async throws ->
            Acme_Patients_V1_ListMedicalRecordConflictsResponse
    let scheduleMedicalRecordReportStep0:
        [String:
            @Sendable (Acme_Catalog_V1_ExplainProductCalculationRequest) async throws ->
            Acme_Catalog_V1_ExplainProductCalculationResponse]

    init(
        dependencies: any Dependencies,
        catalogProductCalculation: Acme_Catalog_V1_ProductCalculationService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        keymanagementCryptoKeyCalculation: Acme_Keymanagement_V1_CryptoKeyCalculationService.Client<MeshTransport>,
        metricsMetricSeries: Acme_Metrics_V1_MetricSeriesService.Client<MeshTransport>,
        notificationsNotification: Acme_Notifications_V1_NotificationService.Client<MeshTransport>,
        notificationsNotificationValidation: Acme_Notifications_V1_NotificationValidationService.Client<MeshTransport>,
        patientsAllergyImport: Acme_Patients_V1_AllergyImportService.Client<MeshTransport>,
        patientsAllergySync: Acme_Patients_V1_AllergySyncService.Client<MeshTransport>,
        patientsMedicalRecordSync: Acme_Patients_V1_MedicalRecordSyncService.Client<MeshTransport>,
        patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client<MeshTransport>,
        prescriptionsPrescriptionSync: Acme_Prescriptions_V1_PrescriptionSyncService.Client<MeshTransport>,
        prescriptionsRefillWorkflow: Acme_Prescriptions_V1_RefillWorkflowService.Client<MeshTransport>,
        searchSearchIndexQuery: Acme_Search_V1_SearchIndexQueryService.Client<MeshTransport>,
        telehealthVisitNoteLifecycle: Acme_Telehealth_V1_VisitNoteLifecycleService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.catalogProductCalculation = catalogProductCalculation
        self.identityUser = identityUser
        self.keymanagementCryptoKeyCalculation = keymanagementCryptoKeyCalculation
        self.metricsMetricSeries = metricsMetricSeries
        self.notificationsNotification = notificationsNotification
        self.notificationsNotificationValidation = notificationsNotificationValidation
        self.patientsAllergyImport = patientsAllergyImport
        self.patientsAllergySync = patientsAllergySync
        self.patientsMedicalRecordSync = patientsMedicalRecordSync
        self.patientsPatientQuery = patientsPatientQuery
        self.prescriptionsPrescriptionSync = prescriptionsPrescriptionSync
        self.prescriptionsRefillWorkflow = prescriptionsRefillWorkflow
        self.searchSearchIndexQuery = searchSearchIndexQuery
        self.telehealthVisitNoteLifecycle = telehealthVisitNoteLifecycle
        self.deleteMedicalRecordReportStep3 = ClosurePort<
            Acme_Patients_V1_ReconcileMedicalRecordsRequest, Acme_Patients_V1_ReconcileMedicalRecordsResponse
        >({ request in try await patientsMedicalRecordSync.reconcileMedicalRecords(request) })
        self.listMedicalRecordReportsStep0 = { request in
            try await patientsMedicalRecordSync.listMedicalRecordConflicts(request)
        }
        self.scheduleMedicalRecordReportStep0 = [
            "primary": { request in try await catalogProductCalculation.explainProductCalculation(request) }
        ]
    }

    /// Counts medical records by status.
    func countMedicalRecordTotals(
        request: ServerRequest<Acme_Patients_V1_CountMedicalRecordTotalsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_CountMedicalRecordTotalsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCountMedicalRecordTotals(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Deletes a medical record.
    func deleteMedicalRecordReport(
        request: ServerRequest<Acme_Patients_V1_DeleteMedicalRecordReportRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_DeleteMedicalRecordReportResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processDeleteMedicalRecordReport(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a medical record.
    func fetchMedicalRecordReport(
        request: ServerRequest<Acme_Patients_V1_FetchMedicalRecordReportRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_FetchMedicalRecordReportResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processFetchMedicalRecordReport(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Generates a medical record.
    func generateMedicalRecordReport(
        request: ServerRequest<Acme_Patients_V1_GenerateMedicalRecordReportRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_GenerateMedicalRecordReportResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGenerateMedicalRecordReport(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists medical records a page at a time.
    func listMedicalRecordReports(
        request: ServerRequest<Acme_Patients_V1_ListMedicalRecordReportsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_ListMedicalRecordReportsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListMedicalRecordReports(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Schedules a medical record.
    func scheduleMedicalRecordReport(
        request: ServerRequest<Acme_Patients_V1_ScheduleMedicalRecordReportRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_ScheduleMedicalRecordReportResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processScheduleMedicalRecordReport(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Shares a medical record.
    func shareMedicalRecordReport(
        request: ServerRequest<Acme_Patients_V1_ShareMedicalRecordReportRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_ShareMedicalRecordReportResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processShareMedicalRecordReport(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Streams the changes of medical records as they happen.
    func streamMedicalRecordMetrics(
        request: ServerRequest<Acme_Patients_V1_StreamMedicalRecordMetricsRequest>,
        context: ServerContext
    ) async throws -> StreamingServerResponse<Acme_Patients_V1_StreamMedicalRecordMetricsResponse> {
        return StreamingServerResponse { writer in
            try await CallerScope.$metadata.withValue(request.metadata) {
                let response = try await self.processStreamMedicalRecordMetrics(request.message)
                try await writer.write(response)
                return [:]
            }
        }
    }
}
