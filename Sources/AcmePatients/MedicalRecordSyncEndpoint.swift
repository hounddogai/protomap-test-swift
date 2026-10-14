import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Keeps medical records in step with the systems of record in other regions.
final class MedicalRecordSyncEndpoint: Acme_Patients_V1_MedicalRecordSyncService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let followUps = WorkQueue<Acme_Identity_V1_GetUserRequest>()
    let careplansVitalApproval: Acme_Careplans_V1_VitalApprovalService.Client<MeshTransport>
    let careplansVitalWorkflow: Acme_Careplans_V1_VitalWorkflowService.Client<MeshTransport>
    let documentsDocumentQuery: Acme_Documents_V1_DocumentQueryService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let patientsAllergyCalculation: Acme_Patients_V1_AllergyCalculationService.Client<MeshTransport>
    let patientsAllergyValidation: Acme_Patients_V1_AllergyValidationService.Client<MeshTransport>
    let patientsMedicalRecordValidation: Acme_Patients_V1_MedicalRecordValidationService.Client<MeshTransport>
    let patientsPatient: Acme_Patients_V1_PatientService.Client<MeshTransport>
    let patientsPatientValidation: Acme_Patients_V1_PatientValidationService.Client<MeshTransport>
    let prescriptionsMedicationSync: Acme_Prescriptions_V1_MedicationSyncService.Client<MeshTransport>
    let prescriptionsPrescriptionApproval: Acme_Prescriptions_V1_PrescriptionApprovalService.Client<MeshTransport>
    let toursTourQuery: Acme_Tours_V1_TourQueryService.Client<MeshTransport>
    let venuesVenueValidation: Acme_Venues_V1_VenueValidationService.Client<MeshTransport>
    let syncMedicalRecordsStep1:
        any RPCPort<Acme_Patients_V1_GetPatientRulesRequest, Acme_Patients_V1_GetPatientRulesResponse>

    init(
        dependencies: any Dependencies,
        careplansVitalApproval: Acme_Careplans_V1_VitalApprovalService.Client<MeshTransport>,
        careplansVitalWorkflow: Acme_Careplans_V1_VitalWorkflowService.Client<MeshTransport>,
        documentsDocumentQuery: Acme_Documents_V1_DocumentQueryService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        patientsAllergyCalculation: Acme_Patients_V1_AllergyCalculationService.Client<MeshTransport>,
        patientsAllergyValidation: Acme_Patients_V1_AllergyValidationService.Client<MeshTransport>,
        patientsMedicalRecordValidation: Acme_Patients_V1_MedicalRecordValidationService.Client<MeshTransport>,
        patientsPatient: Acme_Patients_V1_PatientService.Client<MeshTransport>,
        patientsPatientValidation: Acme_Patients_V1_PatientValidationService.Client<MeshTransport>,
        prescriptionsMedicationSync: Acme_Prescriptions_V1_MedicationSyncService.Client<MeshTransport>,
        prescriptionsPrescriptionApproval: Acme_Prescriptions_V1_PrescriptionApprovalService.Client<MeshTransport>,
        toursTourQuery: Acme_Tours_V1_TourQueryService.Client<MeshTransport>,
        venuesVenueValidation: Acme_Venues_V1_VenueValidationService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.careplansVitalApproval = careplansVitalApproval
        self.careplansVitalWorkflow = careplansVitalWorkflow
        self.documentsDocumentQuery = documentsDocumentQuery
        self.identityUser = identityUser
        self.patientsAllergyCalculation = patientsAllergyCalculation
        self.patientsAllergyValidation = patientsAllergyValidation
        self.patientsMedicalRecordValidation = patientsMedicalRecordValidation
        self.patientsPatient = patientsPatient
        self.patientsPatientValidation = patientsPatientValidation
        self.prescriptionsMedicationSync = prescriptionsMedicationSync
        self.prescriptionsPrescriptionApproval = prescriptionsPrescriptionApproval
        self.toursTourQuery = toursTourQuery
        self.venuesVenueValidation = venuesVenueValidation
        self.syncMedicalRecordsStep1 = ClosurePort<
            Acme_Patients_V1_GetPatientRulesRequest, Acme_Patients_V1_GetPatientRulesResponse
        >({ request in try await patientsPatientValidation.getPatientRules(request) })
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
