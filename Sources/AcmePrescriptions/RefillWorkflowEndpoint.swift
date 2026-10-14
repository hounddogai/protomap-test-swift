import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Runs the long-lived workflow that takes a refill from start to finish.
final class RefillWorkflowEndpoint: Acme_Prescriptions_V1_RefillWorkflowService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let followUps = WorkQueue<Acme_Identity_V1_GetUserRequest>()
    let boxofficeBoxOfficeSale: Acme_Boxoffice_V1_BoxOfficeSaleService.Client<MeshTransport>
    let careplansCareGoalWorkflow: Acme_Careplans_V1_CareGoalWorkflowService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let ledgerLedgerAccount: Acme_Ledger_V1_LedgerAccountService.Client<MeshTransport>
    let patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>
    let patientsPatientValidation: Acme_Patients_V1_PatientValidationService.Client<MeshTransport>
    let prescriptionsMedicationWorkflow: Acme_Prescriptions_V1_MedicationWorkflowService.Client<MeshTransport>
    let prescriptionsPrescriptionReporting: Acme_Prescriptions_V1_PrescriptionReportingService.Client<MeshTransport>
    let prescriptionsPrescriptionWorkflow: Acme_Prescriptions_V1_PrescriptionWorkflowService.Client<MeshTransport>
    let prescriptionsRefillCalculation: Acme_Prescriptions_V1_RefillCalculationService.Client<MeshTransport>
    let prescriptionsRefillImport: Acme_Prescriptions_V1_RefillImportService.Client<MeshTransport>
    let prescriptionsRefillSync: Acme_Prescriptions_V1_RefillSyncService.Client<MeshTransport>
    let promotionsPromotionCalculation: Acme_Promotions_V1_PromotionCalculationService.Client<MeshTransport>
    let searchSearchIndexQuery: Acme_Search_V1_SearchIndexQueryService.Client<MeshTransport>
    let searchSearchIndexValidation: Acme_Search_V1_SearchIndexValidationService.Client<MeshTransport>
    let telehealthVideoVisitValidation: Acme_Telehealth_V1_VideoVisitValidationService.Client<MeshTransport>
    let venuesVenue: Acme_Venues_V1_VenueService.Client<MeshTransport>
    let listRefillWorkflowsStep0:
        any RPCPort<
            Acme_Prescriptions_V1_ResumePrescriptionWorkflowRequest,
            Acme_Prescriptions_V1_ResumePrescriptionWorkflowResponse
        >
    let pauseRefillWorkflowStep1:
        @Sendable (Acme_Careplans_V1_AdvanceCareGoalWorkflowRequest) async throws ->
            Acme_Careplans_V1_AdvanceCareGoalWorkflowResponse
    let pauseRefillWorkflowStep3:
        [String:
            @Sendable (Acme_Search_V1_ResolveSearchIndexesRequest) async throws ->
            Acme_Search_V1_ResolveSearchIndexesResponse]

    init(
        dependencies: any Dependencies,
        boxofficeBoxOfficeSale: Acme_Boxoffice_V1_BoxOfficeSaleService.Client<MeshTransport>,
        careplansCareGoalWorkflow: Acme_Careplans_V1_CareGoalWorkflowService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        ledgerLedgerAccount: Acme_Ledger_V1_LedgerAccountService.Client<MeshTransport>,
        patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>,
        patientsPatientValidation: Acme_Patients_V1_PatientValidationService.Client<MeshTransport>,
        prescriptionsMedicationWorkflow: Acme_Prescriptions_V1_MedicationWorkflowService.Client<MeshTransport>,
        prescriptionsPrescriptionReporting: Acme_Prescriptions_V1_PrescriptionReportingService.Client<MeshTransport>,
        prescriptionsPrescriptionWorkflow: Acme_Prescriptions_V1_PrescriptionWorkflowService.Client<MeshTransport>,
        prescriptionsRefillCalculation: Acme_Prescriptions_V1_RefillCalculationService.Client<MeshTransport>,
        prescriptionsRefillImport: Acme_Prescriptions_V1_RefillImportService.Client<MeshTransport>,
        prescriptionsRefillSync: Acme_Prescriptions_V1_RefillSyncService.Client<MeshTransport>,
        promotionsPromotionCalculation: Acme_Promotions_V1_PromotionCalculationService.Client<MeshTransport>,
        searchSearchIndexQuery: Acme_Search_V1_SearchIndexQueryService.Client<MeshTransport>,
        searchSearchIndexValidation: Acme_Search_V1_SearchIndexValidationService.Client<MeshTransport>,
        telehealthVideoVisitValidation: Acme_Telehealth_V1_VideoVisitValidationService.Client<MeshTransport>,
        venuesVenue: Acme_Venues_V1_VenueService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.boxofficeBoxOfficeSale = boxofficeBoxOfficeSale
        self.careplansCareGoalWorkflow = careplansCareGoalWorkflow
        self.identityUser = identityUser
        self.ledgerLedgerAccount = ledgerLedgerAccount
        self.patientsMedicalRecordCalculation = patientsMedicalRecordCalculation
        self.patientsPatientValidation = patientsPatientValidation
        self.prescriptionsMedicationWorkflow = prescriptionsMedicationWorkflow
        self.prescriptionsPrescriptionReporting = prescriptionsPrescriptionReporting
        self.prescriptionsPrescriptionWorkflow = prescriptionsPrescriptionWorkflow
        self.prescriptionsRefillCalculation = prescriptionsRefillCalculation
        self.prescriptionsRefillImport = prescriptionsRefillImport
        self.prescriptionsRefillSync = prescriptionsRefillSync
        self.promotionsPromotionCalculation = promotionsPromotionCalculation
        self.searchSearchIndexQuery = searchSearchIndexQuery
        self.searchSearchIndexValidation = searchSearchIndexValidation
        self.telehealthVideoVisitValidation = telehealthVideoVisitValidation
        self.venuesVenue = venuesVenue
        self.listRefillWorkflowsStep0 = ClosurePort<
            Acme_Prescriptions_V1_ResumePrescriptionWorkflowRequest,
            Acme_Prescriptions_V1_ResumePrescriptionWorkflowResponse
        >({ request in try await prescriptionsPrescriptionWorkflow.resumePrescriptionWorkflow(request) })
        self.pauseRefillWorkflowStep1 = { request in
            try await careplansCareGoalWorkflow.advanceCareGoalWorkflow(request)
        }
        self.pauseRefillWorkflowStep3 = [
            "primary": { request in try await searchSearchIndexQuery.resolveSearchIndexes(request) }
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
