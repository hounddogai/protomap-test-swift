import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Moves a medical record between the states of its lifecycle.
final class MedicalRecordLifecycleEndpoint: Acme_Patients_V1_MedicalRecordLifecycleService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let careplansCarePlanWorkflow: Acme_Careplans_V1_CarePlanWorkflowService.Client<MeshTransport>
    let documentsDocumentValidation: Acme_Documents_V1_DocumentValidationService.Client<MeshTransport>
    let featureflagsFeatureFlagValidation: Acme_Featureflags_V1_FeatureFlagValidationService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let metricsMetricSeriesQuery: Acme_Metrics_V1_MetricSeriesQueryService.Client<MeshTransport>
    let patientsAllergySync: Acme_Patients_V1_AllergySyncService.Client<MeshTransport>
    let patientsMedicalRecordReporting: Acme_Patients_V1_MedicalRecordReportingService.Client<MeshTransport>
    let patientsPatient: Acme_Patients_V1_PatientService.Client<MeshTransport>
    let prescriptionsMedicationReporting: Acme_Prescriptions_V1_MedicationReportingService.Client<MeshTransport>
    let prescriptionsRefillReporting: Acme_Prescriptions_V1_RefillReportingService.Client<MeshTransport>
    let activateMedicalRecordStep1:
        @Sendable (Acme_Featureflags_V1_ExplainFeatureFlagDecisionRequest) async throws ->
            Acme_Featureflags_V1_ExplainFeatureFlagDecisionResponse
    let expireMedicalRecordStep0:
        [String:
            @Sendable (Acme_Prescriptions_V1_ShareRefillReportRequest) async throws ->
            Acme_Prescriptions_V1_ShareRefillReportResponse]

    init(
        dependencies: any Dependencies,
        careplansCarePlanWorkflow: Acme_Careplans_V1_CarePlanWorkflowService.Client<MeshTransport>,
        documentsDocumentValidation: Acme_Documents_V1_DocumentValidationService.Client<MeshTransport>,
        featureflagsFeatureFlagValidation: Acme_Featureflags_V1_FeatureFlagValidationService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        metricsMetricSeriesQuery: Acme_Metrics_V1_MetricSeriesQueryService.Client<MeshTransport>,
        patientsAllergySync: Acme_Patients_V1_AllergySyncService.Client<MeshTransport>,
        patientsMedicalRecordReporting: Acme_Patients_V1_MedicalRecordReportingService.Client<MeshTransport>,
        patientsPatient: Acme_Patients_V1_PatientService.Client<MeshTransport>,
        prescriptionsMedicationReporting: Acme_Prescriptions_V1_MedicationReportingService.Client<MeshTransport>,
        prescriptionsRefillReporting: Acme_Prescriptions_V1_RefillReportingService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.careplansCarePlanWorkflow = careplansCarePlanWorkflow
        self.documentsDocumentValidation = documentsDocumentValidation
        self.featureflagsFeatureFlagValidation = featureflagsFeatureFlagValidation
        self.identityUser = identityUser
        self.metricsMetricSeriesQuery = metricsMetricSeriesQuery
        self.patientsAllergySync = patientsAllergySync
        self.patientsMedicalRecordReporting = patientsMedicalRecordReporting
        self.patientsPatient = patientsPatient
        self.prescriptionsMedicationReporting = prescriptionsMedicationReporting
        self.prescriptionsRefillReporting = prescriptionsRefillReporting
        self.activateMedicalRecordStep1 = { request in
            try await featureflagsFeatureFlagValidation.explainFeatureFlagDecision(request)
        }
        self.expireMedicalRecordStep0 = [
            "primary": { request in try await prescriptionsRefillReporting.shareRefillReport(request) }
        ]
    }
}
