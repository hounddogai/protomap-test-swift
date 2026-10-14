import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Moves a patient between the states of its lifecycle.
final class PatientLifecycleEndpoint: Acme_Patients_V1_PatientLifecycleService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let budgetingBudgetQuery: Acme_Budgeting_V1_BudgetQueryService.Client<MeshTransport>
    let careplansVitalApproval: Acme_Careplans_V1_VitalApprovalService.Client<MeshTransport>
    let featureflagsFeatureFlagQuery: Acme_Featureflags_V1_FeatureFlagQueryService.Client<MeshTransport>
    let featureflagsFeatureFlagValidation: Acme_Featureflags_V1_FeatureFlagValidationService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client<MeshTransport>
    let patientsAllergyImport: Acme_Patients_V1_AllergyImportService.Client<MeshTransport>
    let patientsAllergySync: Acme_Patients_V1_AllergySyncService.Client<MeshTransport>
    let patientsMedicalRecordSync: Acme_Patients_V1_MedicalRecordSyncService.Client<MeshTransport>
    let patientsMedicalRecordValidation: Acme_Patients_V1_MedicalRecordValidationService.Client<MeshTransport>
    let patientsPatientReporting: Acme_Patients_V1_PatientReportingService.Client<MeshTransport>
    let patientsPatientSync: Acme_Patients_V1_PatientSyncService.Client<MeshTransport>
    let patientsPatientValidation: Acme_Patients_V1_PatientValidationService.Client<MeshTransport>
    let searchSearchIndexQuery: Acme_Search_V1_SearchIndexQueryService.Client<MeshTransport>
    let suspendPatientStep0:
        any RPCPort<Acme_Metrics_V1_ValidateMetricSeriesRequest, Acme_Metrics_V1_ValidateMetricSeriesResponse>
    let suspendPatientStep2:
        @Sendable (Acme_Patients_V1_MapAllergyImportColumnsRequest) async throws ->
            Acme_Patients_V1_MapAllergyImportColumnsResponse
    let terminatePatientStep0:
        [String:
            @Sendable (Acme_Featureflags_V1_SuggestFeatureFlagsRequest) async throws ->
            Acme_Featureflags_V1_SuggestFeatureFlagsResponse]

    init(
        dependencies: any Dependencies,
        budgetingBudgetQuery: Acme_Budgeting_V1_BudgetQueryService.Client<MeshTransport>,
        careplansVitalApproval: Acme_Careplans_V1_VitalApprovalService.Client<MeshTransport>,
        featureflagsFeatureFlagQuery: Acme_Featureflags_V1_FeatureFlagQueryService.Client<MeshTransport>,
        featureflagsFeatureFlagValidation: Acme_Featureflags_V1_FeatureFlagValidationService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client<MeshTransport>,
        patientsAllergyImport: Acme_Patients_V1_AllergyImportService.Client<MeshTransport>,
        patientsAllergySync: Acme_Patients_V1_AllergySyncService.Client<MeshTransport>,
        patientsMedicalRecordSync: Acme_Patients_V1_MedicalRecordSyncService.Client<MeshTransport>,
        patientsMedicalRecordValidation: Acme_Patients_V1_MedicalRecordValidationService.Client<MeshTransport>,
        patientsPatientReporting: Acme_Patients_V1_PatientReportingService.Client<MeshTransport>,
        patientsPatientSync: Acme_Patients_V1_PatientSyncService.Client<MeshTransport>,
        patientsPatientValidation: Acme_Patients_V1_PatientValidationService.Client<MeshTransport>,
        searchSearchIndexQuery: Acme_Search_V1_SearchIndexQueryService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.budgetingBudgetQuery = budgetingBudgetQuery
        self.careplansVitalApproval = careplansVitalApproval
        self.featureflagsFeatureFlagQuery = featureflagsFeatureFlagQuery
        self.featureflagsFeatureFlagValidation = featureflagsFeatureFlagValidation
        self.identityUser = identityUser
        self.metricsMetricSeriesValidation = metricsMetricSeriesValidation
        self.patientsAllergyImport = patientsAllergyImport
        self.patientsAllergySync = patientsAllergySync
        self.patientsMedicalRecordSync = patientsMedicalRecordSync
        self.patientsMedicalRecordValidation = patientsMedicalRecordValidation
        self.patientsPatientReporting = patientsPatientReporting
        self.patientsPatientSync = patientsPatientSync
        self.patientsPatientValidation = patientsPatientValidation
        self.searchSearchIndexQuery = searchSearchIndexQuery
        self.suspendPatientStep0 = ClosurePort<
            Acme_Metrics_V1_ValidateMetricSeriesRequest, Acme_Metrics_V1_ValidateMetricSeriesResponse
        >({ request in try await metricsMetricSeriesValidation.validateMetricSeries(request) })
        self.suspendPatientStep2 = { request in try await patientsAllergyImport.mapAllergyImportColumns(request) }
        self.terminatePatientStep0 = [
            "primary": { request in try await featureflagsFeatureFlagQuery.suggestFeatureFlags(request) }
        ]
    }

    /// Activates a patient.
    func activatePatient(
        request: ServerRequest<Acme_Patients_V1_ActivatePatientRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_ActivatePatientResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processActivatePatient(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Expires a patient.
    func expirePatient(
        request: ServerRequest<Acme_Patients_V1_ExpirePatientRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_ExpirePatientResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processExpirePatient(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Renews a patient.
    func renewPatient(
        request: ServerRequest<Acme_Patients_V1_RenewPatientRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_RenewPatientResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRenewPatient(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Schedules a patient.
    func schedulePatientExpiry(
        request: ServerRequest<Acme_Patients_V1_SchedulePatientExpiryRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_SchedulePatientExpiryResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSchedulePatientExpiry(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Suspends a patient.
    func suspendPatient(
        request: ServerRequest<Acme_Patients_V1_SuspendPatientRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_SuspendPatientResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSuspendPatient(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Terminates a patient.
    func terminatePatient(
        request: ServerRequest<Acme_Patients_V1_TerminatePatientRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_TerminatePatientResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processTerminatePatient(request.message)
            return ServerResponse(message: response)
        }
    }
}
