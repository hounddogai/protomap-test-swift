import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Keeps patients in step with the systems of record in other regions.
final class PatientSyncEndpoint: Acme_Patients_V1_PatientSyncService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let appointmentsClinicSlotApproval: Acme_Appointments_V1_ClinicSlotApprovalService.Client<MeshTransport>
    let careplansVitalWorkflow: Acme_Careplans_V1_VitalWorkflowService.Client<MeshTransport>
    let documentsDocument: Acme_Documents_V1_DocumentService.Client<MeshTransport>
    let featureflagsFeatureFlagValidation: Acme_Featureflags_V1_FeatureFlagValidationService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let notificationsNotification: Acme_Notifications_V1_NotificationService.Client<MeshTransport>
    let patientsAllergyValidation: Acme_Patients_V1_AllergyValidationService.Client<MeshTransport>
    let patientsMedicalRecordQuery: Acme_Patients_V1_MedicalRecordQueryService.Client<MeshTransport>
    let patientsMedicalRecordValidation: Acme_Patients_V1_MedicalRecordValidationService.Client<MeshTransport>
    let paymentsPaymentCalculation: Acme_Payments_V1_PaymentCalculationService.Client<MeshTransport>
    let prescriptionsMedicationReporting: Acme_Prescriptions_V1_MedicationReportingService.Client<MeshTransport>
    let prescriptionsPrescriptionSync: Acme_Prescriptions_V1_PrescriptionSyncService.Client<MeshTransport>
    let prescriptionsPrescriptionWorkflow: Acme_Prescriptions_V1_PrescriptionWorkflowService.Client<MeshTransport>
    let prescriptionsRefillApproval: Acme_Prescriptions_V1_RefillApprovalService.Client<MeshTransport>
    let prescriptionsRefillReporting: Acme_Prescriptions_V1_RefillReportingService.Client<MeshTransport>
    let treasuryCashPosition: Acme_Treasury_V1_CashPositionService.Client<MeshTransport>
    let venuesVenueValidation: Acme_Venues_V1_VenueValidationService.Client<MeshTransport>
    let reconcilePatientsStep0:
        any RPCPort<Acme_Patients_V1_ResolveMedicalRecordsRequest, Acme_Patients_V1_ResolveMedicalRecordsResponse>
    let reconcilePatientsStep2:
        @Sendable (Acme_Patients_V1_SummarizeMedicalRecordsRequest) async throws ->
            Acme_Patients_V1_SummarizeMedicalRecordsResponse
    let resolvePatientConflictStep0:
        [String:
            @Sendable (Acme_Patients_V1_NormalizeAllergyRequest) async throws ->
            Acme_Patients_V1_NormalizeAllergyResponse]

    init(
        dependencies: any Dependencies,
        appointmentsClinicSlotApproval: Acme_Appointments_V1_ClinicSlotApprovalService.Client<MeshTransport>,
        careplansVitalWorkflow: Acme_Careplans_V1_VitalWorkflowService.Client<MeshTransport>,
        documentsDocument: Acme_Documents_V1_DocumentService.Client<MeshTransport>,
        featureflagsFeatureFlagValidation: Acme_Featureflags_V1_FeatureFlagValidationService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        notificationsNotification: Acme_Notifications_V1_NotificationService.Client<MeshTransport>,
        patientsAllergyValidation: Acme_Patients_V1_AllergyValidationService.Client<MeshTransport>,
        patientsMedicalRecordQuery: Acme_Patients_V1_MedicalRecordQueryService.Client<MeshTransport>,
        patientsMedicalRecordValidation: Acme_Patients_V1_MedicalRecordValidationService.Client<MeshTransport>,
        paymentsPaymentCalculation: Acme_Payments_V1_PaymentCalculationService.Client<MeshTransport>,
        prescriptionsMedicationReporting: Acme_Prescriptions_V1_MedicationReportingService.Client<MeshTransport>,
        prescriptionsPrescriptionSync: Acme_Prescriptions_V1_PrescriptionSyncService.Client<MeshTransport>,
        prescriptionsPrescriptionWorkflow: Acme_Prescriptions_V1_PrescriptionWorkflowService.Client<MeshTransport>,
        prescriptionsRefillApproval: Acme_Prescriptions_V1_RefillApprovalService.Client<MeshTransport>,
        prescriptionsRefillReporting: Acme_Prescriptions_V1_RefillReportingService.Client<MeshTransport>,
        treasuryCashPosition: Acme_Treasury_V1_CashPositionService.Client<MeshTransport>,
        venuesVenueValidation: Acme_Venues_V1_VenueValidationService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.appointmentsClinicSlotApproval = appointmentsClinicSlotApproval
        self.careplansVitalWorkflow = careplansVitalWorkflow
        self.documentsDocument = documentsDocument
        self.featureflagsFeatureFlagValidation = featureflagsFeatureFlagValidation
        self.identityUser = identityUser
        self.notificationsNotification = notificationsNotification
        self.patientsAllergyValidation = patientsAllergyValidation
        self.patientsMedicalRecordQuery = patientsMedicalRecordQuery
        self.patientsMedicalRecordValidation = patientsMedicalRecordValidation
        self.paymentsPaymentCalculation = paymentsPaymentCalculation
        self.prescriptionsMedicationReporting = prescriptionsMedicationReporting
        self.prescriptionsPrescriptionSync = prescriptionsPrescriptionSync
        self.prescriptionsPrescriptionWorkflow = prescriptionsPrescriptionWorkflow
        self.prescriptionsRefillApproval = prescriptionsRefillApproval
        self.prescriptionsRefillReporting = prescriptionsRefillReporting
        self.treasuryCashPosition = treasuryCashPosition
        self.venuesVenueValidation = venuesVenueValidation
        self.reconcilePatientsStep0 = ClosurePort<
            Acme_Patients_V1_ResolveMedicalRecordsRequest, Acme_Patients_V1_ResolveMedicalRecordsResponse
        >({ request in try await patientsMedicalRecordQuery.resolveMedicalRecords(request) })
        self.reconcilePatientsStep2 = { request in try await patientsMedicalRecordQuery.summarizeMedicalRecords(request)
        }
        self.resolvePatientConflictStep0 = [
            "primary": { request in try await patientsAllergyValidation.normalizeAllergy(request) }
        ]
    }
}
