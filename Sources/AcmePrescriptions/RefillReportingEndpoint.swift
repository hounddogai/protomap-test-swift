import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Builds and schedules reports about refills.
final class RefillReportingEndpoint: Acme_Prescriptions_V1_RefillReportingService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let careplansCareGoalApproval: Acme_Careplans_V1_CareGoalApprovalService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let notificationsNotification: Acme_Notifications_V1_NotificationService.Client<MeshTransport>
    let prescriptionsMedicationCalculation: Acme_Prescriptions_V1_MedicationCalculationService.Client<MeshTransport>
    let prescriptionsMedicationSync: Acme_Prescriptions_V1_MedicationSyncService.Client<MeshTransport>
    let prescriptionsMedicationValidation: Acme_Prescriptions_V1_MedicationValidationService.Client<MeshTransport>
    let prescriptionsPrescriptionReporting: Acme_Prescriptions_V1_PrescriptionReportingService.Client<MeshTransport>
    let prescriptionsPrescriptionSync: Acme_Prescriptions_V1_PrescriptionSyncService.Client<MeshTransport>
    let prescriptionsRefillImport: Acme_Prescriptions_V1_RefillImportService.Client<MeshTransport>
    let telehealthTriageWorkflow: Acme_Telehealth_V1_TriageWorkflowService.Client<MeshTransport>
    let deleteRefillReportStep0:
        [String:
            @Sendable (Acme_Prescriptions_V1_ListMedicationConflictsRequest) async throws ->
            Acme_Prescriptions_V1_ListMedicationConflictsResponse]

    init(
        dependencies: any Dependencies,
        careplansCareGoalApproval: Acme_Careplans_V1_CareGoalApprovalService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        notificationsNotification: Acme_Notifications_V1_NotificationService.Client<MeshTransport>,
        prescriptionsMedicationCalculation: Acme_Prescriptions_V1_MedicationCalculationService.Client<MeshTransport>,
        prescriptionsMedicationSync: Acme_Prescriptions_V1_MedicationSyncService.Client<MeshTransport>,
        prescriptionsMedicationValidation: Acme_Prescriptions_V1_MedicationValidationService.Client<MeshTransport>,
        prescriptionsPrescriptionReporting: Acme_Prescriptions_V1_PrescriptionReportingService.Client<MeshTransport>,
        prescriptionsPrescriptionSync: Acme_Prescriptions_V1_PrescriptionSyncService.Client<MeshTransport>,
        prescriptionsRefillImport: Acme_Prescriptions_V1_RefillImportService.Client<MeshTransport>,
        telehealthTriageWorkflow: Acme_Telehealth_V1_TriageWorkflowService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.careplansCareGoalApproval = careplansCareGoalApproval
        self.identityUser = identityUser
        self.notificationsNotification = notificationsNotification
        self.prescriptionsMedicationCalculation = prescriptionsMedicationCalculation
        self.prescriptionsMedicationSync = prescriptionsMedicationSync
        self.prescriptionsMedicationValidation = prescriptionsMedicationValidation
        self.prescriptionsPrescriptionReporting = prescriptionsPrescriptionReporting
        self.prescriptionsPrescriptionSync = prescriptionsPrescriptionSync
        self.prescriptionsRefillImport = prescriptionsRefillImport
        self.telehealthTriageWorkflow = telehealthTriageWorkflow
        self.deleteRefillReportStep0 = [
            "primary": { request in try await prescriptionsMedicationSync.listMedicationConflicts(request) }
        ]
    }
}
