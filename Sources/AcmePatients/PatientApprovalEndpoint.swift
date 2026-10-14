import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Routes patients through approval, with escalation and delegation.
final class PatientApprovalEndpoint: Acme_Patients_V1_PatientApprovalService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let appointmentsAppointmentApproval: Acme_Appointments_V1_AppointmentApprovalService.Client<MeshTransport>
    let authorizationAccessPolicyValidation: Acme_Authorization_V1_AccessPolicyValidationService.Client<MeshTransport>
    let careplansCareGoalApproval: Acme_Careplans_V1_CareGoalApprovalService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let itsmIncidentCalculation: Acme_Itsm_V1_IncidentCalculationService.Client<MeshTransport>
    let patientsAllergyCalculation: Acme_Patients_V1_AllergyCalculationService.Client<MeshTransport>
    let patientsAllergySync: Acme_Patients_V1_AllergySyncService.Client<MeshTransport>
    let patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>
    let patientsMedicalRecordQuery: Acme_Patients_V1_MedicalRecordQueryService.Client<MeshTransport>
    let patientsMedicalRecordSync: Acme_Patients_V1_MedicalRecordSyncService.Client<MeshTransport>
    let patientsPatientReporting: Acme_Patients_V1_PatientReportingService.Client<MeshTransport>
    let patientsPatientSync: Acme_Patients_V1_PatientSyncService.Client<MeshTransport>
    let prescriptionsRefillApproval: Acme_Prescriptions_V1_RefillApprovalService.Client<MeshTransport>
    let searchSearchIndexValidation: Acme_Search_V1_SearchIndexValidationService.Client<MeshTransport>
    let delegatePatientApprovalStep0:
        any RPCPort<Acme_Authorization_V1_ScoreAccessPolicyRequest, Acme_Authorization_V1_ScoreAccessPolicyResponse>
    let escalatePatientStep1:
        @Sendable (Acme_Careplans_V1_EscalateCareGoalRequest) async throws -> Acme_Careplans_V1_EscalateCareGoalResponse
    let getPatientApprovalStatusStep0:
        [String:
            @Sendable (Acme_Appointments_V1_RejectAppointmentRequest) async throws ->
            Acme_Appointments_V1_RejectAppointmentResponse]

    init(
        dependencies: any Dependencies,
        appointmentsAppointmentApproval: Acme_Appointments_V1_AppointmentApprovalService.Client<MeshTransport>,
        authorizationAccessPolicyValidation: Acme_Authorization_V1_AccessPolicyValidationService.Client<MeshTransport>,
        careplansCareGoalApproval: Acme_Careplans_V1_CareGoalApprovalService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        itsmIncidentCalculation: Acme_Itsm_V1_IncidentCalculationService.Client<MeshTransport>,
        patientsAllergyCalculation: Acme_Patients_V1_AllergyCalculationService.Client<MeshTransport>,
        patientsAllergySync: Acme_Patients_V1_AllergySyncService.Client<MeshTransport>,
        patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>,
        patientsMedicalRecordQuery: Acme_Patients_V1_MedicalRecordQueryService.Client<MeshTransport>,
        patientsMedicalRecordSync: Acme_Patients_V1_MedicalRecordSyncService.Client<MeshTransport>,
        patientsPatientReporting: Acme_Patients_V1_PatientReportingService.Client<MeshTransport>,
        patientsPatientSync: Acme_Patients_V1_PatientSyncService.Client<MeshTransport>,
        prescriptionsRefillApproval: Acme_Prescriptions_V1_RefillApprovalService.Client<MeshTransport>,
        searchSearchIndexValidation: Acme_Search_V1_SearchIndexValidationService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.appointmentsAppointmentApproval = appointmentsAppointmentApproval
        self.authorizationAccessPolicyValidation = authorizationAccessPolicyValidation
        self.careplansCareGoalApproval = careplansCareGoalApproval
        self.identityUser = identityUser
        self.itsmIncidentCalculation = itsmIncidentCalculation
        self.patientsAllergyCalculation = patientsAllergyCalculation
        self.patientsAllergySync = patientsAllergySync
        self.patientsMedicalRecordCalculation = patientsMedicalRecordCalculation
        self.patientsMedicalRecordQuery = patientsMedicalRecordQuery
        self.patientsMedicalRecordSync = patientsMedicalRecordSync
        self.patientsPatientReporting = patientsPatientReporting
        self.patientsPatientSync = patientsPatientSync
        self.prescriptionsRefillApproval = prescriptionsRefillApproval
        self.searchSearchIndexValidation = searchSearchIndexValidation
        self.delegatePatientApprovalStep0 = ClosurePort<
            Acme_Authorization_V1_ScoreAccessPolicyRequest, Acme_Authorization_V1_ScoreAccessPolicyResponse
        >({ request in try await authorizationAccessPolicyValidation.scoreAccessPolicy(request) })
        self.escalatePatientStep1 = { request in try await careplansCareGoalApproval.escalateCareGoal(request) }
        self.getPatientApprovalStatusStep0 = [
            "primary": { request in try await appointmentsAppointmentApproval.rejectAppointment(request) }
        ]
    }
}
