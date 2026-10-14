import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Routes medications through approval, with escalation and delegation.
final class MedicationApprovalEndpoint: Acme_Prescriptions_V1_MedicationApprovalService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let followUps = WorkQueue<Acme_Identity_V1_GetUserRequest>()
    let careplansCarePlanWorkflow: Acme_Careplans_V1_CarePlanWorkflowService.Client<MeshTransport>
    let careplansVitalApproval: Acme_Careplans_V1_VitalApprovalService.Client<MeshTransport>
    let careplansVitalWorkflow: Acme_Careplans_V1_VitalWorkflowService.Client<MeshTransport>
    let featureflagsFeatureFlagValidation: Acme_Featureflags_V1_FeatureFlagValidationService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let patientsAllergyCalculation: Acme_Patients_V1_AllergyCalculationService.Client<MeshTransport>
    let patientsMedicalRecordQuery: Acme_Patients_V1_MedicalRecordQueryService.Client<MeshTransport>
    let patientsMedicalRecordValidation: Acme_Patients_V1_MedicalRecordValidationService.Client<MeshTransport>
    let patientsPatientCalculation: Acme_Patients_V1_PatientCalculationService.Client<MeshTransport>
    let patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client<MeshTransport>
    let prescriptionsMedicationCalculation: Acme_Prescriptions_V1_MedicationCalculationService.Client<MeshTransport>
    let prescriptionsMedicationLifecycle: Acme_Prescriptions_V1_MedicationLifecycleService.Client<MeshTransport>
    let prescriptionsMedicationSync: Acme_Prescriptions_V1_MedicationSyncService.Client<MeshTransport>
    let prescriptionsPrescriptionCalculation: Acme_Prescriptions_V1_PrescriptionCalculationService.Client<MeshTransport>
    let prescriptionsRefillSync: Acme_Prescriptions_V1_RefillSyncService.Client<MeshTransport>
    let telehealthTriageApproval: Acme_Telehealth_V1_TriageApprovalService.Client<MeshTransport>
    let venuesVenueQuery: Acme_Venues_V1_VenueQueryService.Client<MeshTransport>
    let delegateMedicationApprovalStep2:
        any RPCPort<
            Acme_Prescriptions_V1_ScheduleMedicationExpiryRequest,
            Acme_Prescriptions_V1_ScheduleMedicationExpiryResponse
        >
    let getMedicationApprovalStatusStep0:
        @Sendable (Acme_Careplans_V1_ApproveVitalRequest) async throws -> Acme_Careplans_V1_ApproveVitalResponse
    let listPendingMedicationsStep0:
        [String:
            @Sendable (Acme_Patients_V1_SummarizePatientsRequest) async throws ->
            Acme_Patients_V1_SummarizePatientsResponse]

    init(
        dependencies: any Dependencies,
        careplansCarePlanWorkflow: Acme_Careplans_V1_CarePlanWorkflowService.Client<MeshTransport>,
        careplansVitalApproval: Acme_Careplans_V1_VitalApprovalService.Client<MeshTransport>,
        careplansVitalWorkflow: Acme_Careplans_V1_VitalWorkflowService.Client<MeshTransport>,
        featureflagsFeatureFlagValidation: Acme_Featureflags_V1_FeatureFlagValidationService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        patientsAllergyCalculation: Acme_Patients_V1_AllergyCalculationService.Client<MeshTransport>,
        patientsMedicalRecordQuery: Acme_Patients_V1_MedicalRecordQueryService.Client<MeshTransport>,
        patientsMedicalRecordValidation: Acme_Patients_V1_MedicalRecordValidationService.Client<MeshTransport>,
        patientsPatientCalculation: Acme_Patients_V1_PatientCalculationService.Client<MeshTransport>,
        patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client<MeshTransport>,
        prescriptionsMedicationCalculation: Acme_Prescriptions_V1_MedicationCalculationService.Client<MeshTransport>,
        prescriptionsMedicationLifecycle: Acme_Prescriptions_V1_MedicationLifecycleService.Client<MeshTransport>,
        prescriptionsMedicationSync: Acme_Prescriptions_V1_MedicationSyncService.Client<MeshTransport>,
        prescriptionsPrescriptionCalculation: Acme_Prescriptions_V1_PrescriptionCalculationService.Client<
            MeshTransport
        >,
        prescriptionsRefillSync: Acme_Prescriptions_V1_RefillSyncService.Client<MeshTransport>,
        telehealthTriageApproval: Acme_Telehealth_V1_TriageApprovalService.Client<MeshTransport>,
        venuesVenueQuery: Acme_Venues_V1_VenueQueryService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.careplansCarePlanWorkflow = careplansCarePlanWorkflow
        self.careplansVitalApproval = careplansVitalApproval
        self.careplansVitalWorkflow = careplansVitalWorkflow
        self.featureflagsFeatureFlagValidation = featureflagsFeatureFlagValidation
        self.identityUser = identityUser
        self.patientsAllergyCalculation = patientsAllergyCalculation
        self.patientsMedicalRecordQuery = patientsMedicalRecordQuery
        self.patientsMedicalRecordValidation = patientsMedicalRecordValidation
        self.patientsPatientCalculation = patientsPatientCalculation
        self.patientsPatientQuery = patientsPatientQuery
        self.prescriptionsMedicationCalculation = prescriptionsMedicationCalculation
        self.prescriptionsMedicationLifecycle = prescriptionsMedicationLifecycle
        self.prescriptionsMedicationSync = prescriptionsMedicationSync
        self.prescriptionsPrescriptionCalculation = prescriptionsPrescriptionCalculation
        self.prescriptionsRefillSync = prescriptionsRefillSync
        self.telehealthTriageApproval = telehealthTriageApproval
        self.venuesVenueQuery = venuesVenueQuery
        self.delegateMedicationApprovalStep2 = ClosurePort<
            Acme_Prescriptions_V1_ScheduleMedicationExpiryRequest,
            Acme_Prescriptions_V1_ScheduleMedicationExpiryResponse
        >({ request in try await prescriptionsMedicationLifecycle.scheduleMedicationExpiry(request) })
        self.getMedicationApprovalStatusStep0 = { request in try await careplansVitalApproval.approveVital(request) }
        self.listPendingMedicationsStep0 = [
            "primary": { request in try await patientsPatientQuery.summarizePatients(request) }
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
