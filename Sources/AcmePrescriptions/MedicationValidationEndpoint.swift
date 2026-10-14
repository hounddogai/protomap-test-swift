import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Checks medications against the rules before anything acts on them.
final class MedicationValidationEndpoint: Acme_Prescriptions_V1_MedicationValidationService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let followUps = WorkQueue<Acme_Identity_V1_GetUserRequest>()
    let careplansCareGoalValidation: Acme_Careplans_V1_CareGoalValidationService.Client<MeshTransport>
    let careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>
    let careplansVitalCalculation: Acme_Careplans_V1_VitalCalculationService.Client<MeshTransport>
    let careplansVitalValidation: Acme_Careplans_V1_VitalValidationService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let prescriptionsMedicationCalculation: Acme_Prescriptions_V1_MedicationCalculationService.Client<MeshTransport>
    let prescriptionsPrescriptionCalculation: Acme_Prescriptions_V1_PrescriptionCalculationService.Client<MeshTransport>
    let prescriptionsRefillCalculation: Acme_Prescriptions_V1_RefillCalculationService.Client<MeshTransport>
    let telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client<MeshTransport>
    let telehealthVideoVisitQuery: Acme_Telehealth_V1_VideoVisitQueryService.Client<MeshTransport>
    let telehealthVisitNoteQuery: Acme_Telehealth_V1_VisitNoteQueryService.Client<MeshTransport>
    let explainMedicationDecisionStep1:
        @Sendable (Acme_Prescriptions_V1_CompareMedicationOptionsRequest) async throws ->
            Acme_Prescriptions_V1_CompareMedicationOptionsResponse
    let getMedicationRulesStep0:
        [String:
            @Sendable (Acme_Careplans_V1_ExplainVitalCalculationRequest) async throws ->
            Acme_Careplans_V1_ExplainVitalCalculationResponse]

    init(
        dependencies: any Dependencies,
        careplansCareGoalValidation: Acme_Careplans_V1_CareGoalValidationService.Client<MeshTransport>,
        careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>,
        careplansVitalCalculation: Acme_Careplans_V1_VitalCalculationService.Client<MeshTransport>,
        careplansVitalValidation: Acme_Careplans_V1_VitalValidationService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        prescriptionsMedicationCalculation: Acme_Prescriptions_V1_MedicationCalculationService.Client<MeshTransport>,
        prescriptionsPrescriptionCalculation: Acme_Prescriptions_V1_PrescriptionCalculationService.Client<
            MeshTransport
        >,
        prescriptionsRefillCalculation: Acme_Prescriptions_V1_RefillCalculationService.Client<MeshTransport>,
        telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client<MeshTransport>,
        telehealthVideoVisitQuery: Acme_Telehealth_V1_VideoVisitQueryService.Client<MeshTransport>,
        telehealthVisitNoteQuery: Acme_Telehealth_V1_VisitNoteQueryService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.careplansCareGoalValidation = careplansCareGoalValidation
        self.careplansCarePlan = careplansCarePlan
        self.careplansVitalCalculation = careplansVitalCalculation
        self.careplansVitalValidation = careplansVitalValidation
        self.identityUser = identityUser
        self.prescriptionsMedicationCalculation = prescriptionsMedicationCalculation
        self.prescriptionsPrescriptionCalculation = prescriptionsPrescriptionCalculation
        self.prescriptionsRefillCalculation = prescriptionsRefillCalculation
        self.telehealthVideoVisitCalculation = telehealthVideoVisitCalculation
        self.telehealthVideoVisitQuery = telehealthVideoVisitQuery
        self.telehealthVisitNoteQuery = telehealthVisitNoteQuery
        self.explainMedicationDecisionStep1 = { request in
            try await prescriptionsMedicationCalculation.compareMedicationOptions(request)
        }
        self.getMedicationRulesStep0 = [
            "primary": { request in try await careplansVitalCalculation.explainVitalCalculation(request) }
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
