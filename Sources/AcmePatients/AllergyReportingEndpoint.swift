import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Builds and schedules reports about allergies.
final class AllergyReportingEndpoint: Acme_Patients_V1_AllergyReportingService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let authorizationAccessPolicyValidation: Acme_Authorization_V1_AccessPolicyValidationService.Client<MeshTransport>
    let careplansVitalReporting: Acme_Careplans_V1_VitalReportingService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let identityUserValidation: Acme_Identity_V1_UserValidationService.Client<MeshTransport>
    let patientsAllergyImport: Acme_Patients_V1_AllergyImportService.Client<MeshTransport>
    let patientsAllergySync: Acme_Patients_V1_AllergySyncService.Client<MeshTransport>
    let patientsPatient: Acme_Patients_V1_PatientService.Client<MeshTransport>
    let patientsPatientCalculation: Acme_Patients_V1_PatientCalculationService.Client<MeshTransport>
    let patientsPatientLifecycle: Acme_Patients_V1_PatientLifecycleService.Client<MeshTransport>
    let patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client<MeshTransport>
    let prescriptionsPrescriptionSync: Acme_Prescriptions_V1_PrescriptionSyncService.Client<MeshTransport>
    let prescriptionsRefillImport: Acme_Prescriptions_V1_RefillImportService.Client<MeshTransport>
    let searchSearchIndex: Acme_Search_V1_SearchIndexService.Client<MeshTransport>
    let searchSearchIndexQuery: Acme_Search_V1_SearchIndexQueryService.Client<MeshTransport>
    let scheduleAllergyReportStep0:
        any RPCPort<Acme_Careplans_V1_ScheduleVitalReportRequest, Acme_Careplans_V1_ScheduleVitalReportResponse>
    let shareAllergyReportStep0:
        @Sendable (Acme_Prescriptions_V1_MapRefillImportColumnsRequest) async throws ->
            Acme_Prescriptions_V1_MapRefillImportColumnsResponse
    let shareAllergyReportStep2:
        [String:
            @Sendable (Acme_Patients_V1_RetryAllergyImportRequest) async throws ->
            Acme_Patients_V1_RetryAllergyImportResponse]

    init(
        dependencies: any Dependencies,
        authorizationAccessPolicyValidation: Acme_Authorization_V1_AccessPolicyValidationService.Client<MeshTransport>,
        careplansVitalReporting: Acme_Careplans_V1_VitalReportingService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        identityUserValidation: Acme_Identity_V1_UserValidationService.Client<MeshTransport>,
        patientsAllergyImport: Acme_Patients_V1_AllergyImportService.Client<MeshTransport>,
        patientsAllergySync: Acme_Patients_V1_AllergySyncService.Client<MeshTransport>,
        patientsPatient: Acme_Patients_V1_PatientService.Client<MeshTransport>,
        patientsPatientCalculation: Acme_Patients_V1_PatientCalculationService.Client<MeshTransport>,
        patientsPatientLifecycle: Acme_Patients_V1_PatientLifecycleService.Client<MeshTransport>,
        patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client<MeshTransport>,
        prescriptionsPrescriptionSync: Acme_Prescriptions_V1_PrescriptionSyncService.Client<MeshTransport>,
        prescriptionsRefillImport: Acme_Prescriptions_V1_RefillImportService.Client<MeshTransport>,
        searchSearchIndex: Acme_Search_V1_SearchIndexService.Client<MeshTransport>,
        searchSearchIndexQuery: Acme_Search_V1_SearchIndexQueryService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.authorizationAccessPolicyValidation = authorizationAccessPolicyValidation
        self.careplansVitalReporting = careplansVitalReporting
        self.identityUser = identityUser
        self.identityUserValidation = identityUserValidation
        self.patientsAllergyImport = patientsAllergyImport
        self.patientsAllergySync = patientsAllergySync
        self.patientsPatient = patientsPatient
        self.patientsPatientCalculation = patientsPatientCalculation
        self.patientsPatientLifecycle = patientsPatientLifecycle
        self.patientsPatientQuery = patientsPatientQuery
        self.prescriptionsPrescriptionSync = prescriptionsPrescriptionSync
        self.prescriptionsRefillImport = prescriptionsRefillImport
        self.searchSearchIndex = searchSearchIndex
        self.searchSearchIndexQuery = searchSearchIndexQuery
        self.scheduleAllergyReportStep0 = ClosurePort<
            Acme_Careplans_V1_ScheduleVitalReportRequest, Acme_Careplans_V1_ScheduleVitalReportResponse
        >({ request in try await careplansVitalReporting.scheduleVitalReport(request) })
        self.shareAllergyReportStep0 = { request in try await prescriptionsRefillImport.mapRefillImportColumns(request)
        }
        self.shareAllergyReportStep2 = [
            "primary": { request in try await patientsAllergyImport.retryAllergyImport(request) }
        ]
    }
}
