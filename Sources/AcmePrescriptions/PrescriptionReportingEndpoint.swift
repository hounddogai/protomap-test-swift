import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Builds and schedules reports about prescriptions.
final class PrescriptionReportingEndpoint: Acme_Prescriptions_V1_PrescriptionReportingService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let followUps = WorkQueue<Acme_Identity_V1_GetUserRequest>()
    let authorizationAccessPolicyQuery: Acme_Authorization_V1_AccessPolicyQueryService.Client<MeshTransport>
    let authorizationAccessPolicyValidation: Acme_Authorization_V1_AccessPolicyValidationService.Client<MeshTransport>
    let careplansCareGoalApproval: Acme_Careplans_V1_CareGoalApprovalService.Client<MeshTransport>
    let careplansCarePlanCalculation: Acme_Careplans_V1_CarePlanCalculationService.Client<MeshTransport>
    let fraudRiskAssessment: Acme_Fraud_V1_RiskAssessmentService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let patientsMedicalRecordQuery: Acme_Patients_V1_MedicalRecordQueryService.Client<MeshTransport>
    let patientsPatient: Acme_Patients_V1_PatientService.Client<MeshTransport>
    let patientsPatientCalculation: Acme_Patients_V1_PatientCalculationService.Client<MeshTransport>
    let patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client<MeshTransport>
    let paymentsPaymentCalculation: Acme_Payments_V1_PaymentCalculationService.Client<MeshTransport>
    let prescriptionsMedicationQuery: Acme_Prescriptions_V1_MedicationQueryService.Client<MeshTransport>
    let prescriptionsMedicationSync: Acme_Prescriptions_V1_MedicationSyncService.Client<MeshTransport>
    let prescriptionsPrescriptionSync: Acme_Prescriptions_V1_PrescriptionSyncService.Client<MeshTransport>
    let prescriptionsRefillImport: Acme_Prescriptions_V1_RefillImportService.Client<MeshTransport>
    let venuesVenueQuery: Acme_Venues_V1_VenueQueryService.Client<MeshTransport>
    let schedulePrescriptionReportStep0:
        any RPCPort<Acme_Fraud_V1_BatchGetRiskAssessmentsRequest, Acme_Fraud_V1_BatchGetRiskAssessmentsResponse>
    let sharePrescriptionReportStep0:
        @Sendable (Acme_Authorization_V1_CountAccessPoliciesRequest) async throws ->
            Acme_Authorization_V1_CountAccessPoliciesResponse
    let sharePrescriptionReportStep1:
        [String:
            @Sendable (Acme_Careplans_V1_EscalateCareGoalRequest) async throws ->
            Acme_Careplans_V1_EscalateCareGoalResponse]

    init(
        dependencies: any Dependencies,
        authorizationAccessPolicyQuery: Acme_Authorization_V1_AccessPolicyQueryService.Client<MeshTransport>,
        authorizationAccessPolicyValidation: Acme_Authorization_V1_AccessPolicyValidationService.Client<MeshTransport>,
        careplansCareGoalApproval: Acme_Careplans_V1_CareGoalApprovalService.Client<MeshTransport>,
        careplansCarePlanCalculation: Acme_Careplans_V1_CarePlanCalculationService.Client<MeshTransport>,
        fraudRiskAssessment: Acme_Fraud_V1_RiskAssessmentService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        patientsMedicalRecordQuery: Acme_Patients_V1_MedicalRecordQueryService.Client<MeshTransport>,
        patientsPatient: Acme_Patients_V1_PatientService.Client<MeshTransport>,
        patientsPatientCalculation: Acme_Patients_V1_PatientCalculationService.Client<MeshTransport>,
        patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client<MeshTransport>,
        paymentsPaymentCalculation: Acme_Payments_V1_PaymentCalculationService.Client<MeshTransport>,
        prescriptionsMedicationQuery: Acme_Prescriptions_V1_MedicationQueryService.Client<MeshTransport>,
        prescriptionsMedicationSync: Acme_Prescriptions_V1_MedicationSyncService.Client<MeshTransport>,
        prescriptionsPrescriptionSync: Acme_Prescriptions_V1_PrescriptionSyncService.Client<MeshTransport>,
        prescriptionsRefillImport: Acme_Prescriptions_V1_RefillImportService.Client<MeshTransport>,
        venuesVenueQuery: Acme_Venues_V1_VenueQueryService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.authorizationAccessPolicyQuery = authorizationAccessPolicyQuery
        self.authorizationAccessPolicyValidation = authorizationAccessPolicyValidation
        self.careplansCareGoalApproval = careplansCareGoalApproval
        self.careplansCarePlanCalculation = careplansCarePlanCalculation
        self.fraudRiskAssessment = fraudRiskAssessment
        self.identityUser = identityUser
        self.patientsMedicalRecordQuery = patientsMedicalRecordQuery
        self.patientsPatient = patientsPatient
        self.patientsPatientCalculation = patientsPatientCalculation
        self.patientsPatientQuery = patientsPatientQuery
        self.paymentsPaymentCalculation = paymentsPaymentCalculation
        self.prescriptionsMedicationQuery = prescriptionsMedicationQuery
        self.prescriptionsMedicationSync = prescriptionsMedicationSync
        self.prescriptionsPrescriptionSync = prescriptionsPrescriptionSync
        self.prescriptionsRefillImport = prescriptionsRefillImport
        self.venuesVenueQuery = venuesVenueQuery
        self.schedulePrescriptionReportStep0 = ClosurePort<
            Acme_Fraud_V1_BatchGetRiskAssessmentsRequest, Acme_Fraud_V1_BatchGetRiskAssessmentsResponse
        >({ request in try await fraudRiskAssessment.batchGetRiskAssessments(request) })
        self.sharePrescriptionReportStep0 = { request in
            try await authorizationAccessPolicyQuery.countAccessPolicies(request)
        }
        self.sharePrescriptionReportStep1 = [
            "primary": { request in try await careplansCareGoalApproval.escalateCareGoal(request) }
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
