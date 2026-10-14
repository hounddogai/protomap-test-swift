import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Connects external systems that send care inbox events.
final class CareInboxIntegrationEndpoint: Acme_Patientapp_V1_CareInboxIntegrationService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let followUps = WorkQueue<Acme_Identity_V1_GetUserRequest>()
    let fanportalFanSessionQuery: Acme_Fanportal_V1_FanSessionQueryService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let identityUserValidation: Acme_Identity_V1_UserValidationService.Client<MeshTransport>
    let patientappCareInboxWorkflow: Acme_Patientapp_V1_CareInboxWorkflowService.Client<MeshTransport>
    let patientappPatientHomeIntegration: Acme_Patientapp_V1_PatientHomeIntegrationService.Client<MeshTransport>
    let patientappPatientHomeWorkflow: Acme_Patientapp_V1_PatientHomeWorkflowService.Client<MeshTransport>
    let patientsAllergyApproval: Acme_Patients_V1_AllergyApprovalService.Client<MeshTransport>
    let patientsAllergyCalculation: Acme_Patients_V1_AllergyCalculationService.Client<MeshTransport>
    let patientsMedicalRecordApproval: Acme_Patients_V1_MedicalRecordApprovalService.Client<MeshTransport>
    let patientsMedicalRecordSync: Acme_Patients_V1_MedicalRecordSyncService.Client<MeshTransport>
    let patientsPatientApproval: Acme_Patients_V1_PatientApprovalService.Client<MeshTransport>
    let prescriptionsRefillReporting: Acme_Prescriptions_V1_RefillReportingService.Client<MeshTransport>
    let searchSearchIndex: Acme_Search_V1_SearchIndexService.Client<MeshTransport>
    let telehealthTriageApproval: Acme_Telehealth_V1_TriageApprovalService.Client<MeshTransport>
    let telehealthTriageLifecycle: Acme_Telehealth_V1_TriageLifecycleService.Client<MeshTransport>
    let venuesVenueValidation: Acme_Venues_V1_VenueValidationService.Client<MeshTransport>
    let acknowledgeCareInboxEventStep0:
        @Sendable (Acme_Search_V1_CreateSearchIndexRequest) async throws -> Acme_Search_V1_CreateSearchIndexResponse
    let acknowledgeCareInboxEventStep1:
        [String:
            @Sendable (Acme_Patientapp_V1_StartPatientHomeWorkflowRequest) async throws ->
            Acme_Patientapp_V1_StartPatientHomeWorkflowResponse]

    init(
        dependencies: any Dependencies,
        fanportalFanSessionQuery: Acme_Fanportal_V1_FanSessionQueryService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        identityUserValidation: Acme_Identity_V1_UserValidationService.Client<MeshTransport>,
        patientappCareInboxWorkflow: Acme_Patientapp_V1_CareInboxWorkflowService.Client<MeshTransport>,
        patientappPatientHomeIntegration: Acme_Patientapp_V1_PatientHomeIntegrationService.Client<MeshTransport>,
        patientappPatientHomeWorkflow: Acme_Patientapp_V1_PatientHomeWorkflowService.Client<MeshTransport>,
        patientsAllergyApproval: Acme_Patients_V1_AllergyApprovalService.Client<MeshTransport>,
        patientsAllergyCalculation: Acme_Patients_V1_AllergyCalculationService.Client<MeshTransport>,
        patientsMedicalRecordApproval: Acme_Patients_V1_MedicalRecordApprovalService.Client<MeshTransport>,
        patientsMedicalRecordSync: Acme_Patients_V1_MedicalRecordSyncService.Client<MeshTransport>,
        patientsPatientApproval: Acme_Patients_V1_PatientApprovalService.Client<MeshTransport>,
        prescriptionsRefillReporting: Acme_Prescriptions_V1_RefillReportingService.Client<MeshTransport>,
        searchSearchIndex: Acme_Search_V1_SearchIndexService.Client<MeshTransport>,
        telehealthTriageApproval: Acme_Telehealth_V1_TriageApprovalService.Client<MeshTransport>,
        telehealthTriageLifecycle: Acme_Telehealth_V1_TriageLifecycleService.Client<MeshTransport>,
        venuesVenueValidation: Acme_Venues_V1_VenueValidationService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.fanportalFanSessionQuery = fanportalFanSessionQuery
        self.identityUser = identityUser
        self.identityUserValidation = identityUserValidation
        self.patientappCareInboxWorkflow = patientappCareInboxWorkflow
        self.patientappPatientHomeIntegration = patientappPatientHomeIntegration
        self.patientappPatientHomeWorkflow = patientappPatientHomeWorkflow
        self.patientsAllergyApproval = patientsAllergyApproval
        self.patientsAllergyCalculation = patientsAllergyCalculation
        self.patientsMedicalRecordApproval = patientsMedicalRecordApproval
        self.patientsMedicalRecordSync = patientsMedicalRecordSync
        self.patientsPatientApproval = patientsPatientApproval
        self.prescriptionsRefillReporting = prescriptionsRefillReporting
        self.searchSearchIndex = searchSearchIndex
        self.telehealthTriageApproval = telehealthTriageApproval
        self.telehealthTriageLifecycle = telehealthTriageLifecycle
        self.venuesVenueValidation = venuesVenueValidation
        self.acknowledgeCareInboxEventStep0 = { request in try await searchSearchIndex.createSearchIndex(request) }
        self.acknowledgeCareInboxEventStep1 = [
            "primary": { request in try await patientappPatientHomeWorkflow.startPatientHomeWorkflow(request) }
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
}
