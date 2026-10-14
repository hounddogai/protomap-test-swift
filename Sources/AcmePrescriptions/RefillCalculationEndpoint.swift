import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Computes the figures of a refill, such as totals, taxes, and estimates.
final class RefillCalculationEndpoint: Acme_Prescriptions_V1_RefillCalculationService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let followUps = WorkQueue<Acme_Identity_V1_GetUserRequest>()
    let boxofficeBoxOfficeSaleCalculation: Acme_Boxoffice_V1_BoxOfficeSaleCalculationService.Client<MeshTransport>
    let careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>
    let careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>
    let concessionsConcessionStandQuery: Acme_Concessions_V1_ConcessionStandQueryService.Client<MeshTransport>
    let documentsDocumentQuery: Acme_Documents_V1_DocumentQueryService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let ledgerLedgerAccountValidation: Acme_Ledger_V1_LedgerAccountValidationService.Client<MeshTransport>
    let prescriptionsPrescriptionCalculation: Acme_Prescriptions_V1_PrescriptionCalculationService.Client<MeshTransport>
    let sponsorshipsSponsorCalculation: Acme_Sponsorships_V1_SponsorCalculationService.Client<MeshTransport>
    let telehealthVisitNoteQuery: Acme_Telehealth_V1_VisitNoteQueryService.Client<MeshTransport>
    let venuesVenueQuery: Acme_Venues_V1_VenueQueryService.Client<MeshTransport>
    let venuesVenueValidation: Acme_Venues_V1_VenueValidationService.Client<MeshTransport>
    let calculateRefillStep0:
        [String:
            @Sendable (Acme_Documents_V1_SummarizeDocumentsRequest) async throws ->
            Acme_Documents_V1_SummarizeDocumentsResponse]
    let simulateRefillStep3:
        any RPCPort<Acme_Careplans_V1_CalculateCareGoalRequest, Acme_Careplans_V1_CalculateCareGoalResponse>

    init(
        dependencies: any Dependencies,
        boxofficeBoxOfficeSaleCalculation: Acme_Boxoffice_V1_BoxOfficeSaleCalculationService.Client<MeshTransport>,
        careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>,
        careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>,
        concessionsConcessionStandQuery: Acme_Concessions_V1_ConcessionStandQueryService.Client<MeshTransport>,
        documentsDocumentQuery: Acme_Documents_V1_DocumentQueryService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        ledgerLedgerAccountValidation: Acme_Ledger_V1_LedgerAccountValidationService.Client<MeshTransport>,
        prescriptionsPrescriptionCalculation: Acme_Prescriptions_V1_PrescriptionCalculationService.Client<
            MeshTransport
        >,
        sponsorshipsSponsorCalculation: Acme_Sponsorships_V1_SponsorCalculationService.Client<MeshTransport>,
        telehealthVisitNoteQuery: Acme_Telehealth_V1_VisitNoteQueryService.Client<MeshTransport>,
        venuesVenueQuery: Acme_Venues_V1_VenueQueryService.Client<MeshTransport>,
        venuesVenueValidation: Acme_Venues_V1_VenueValidationService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.boxofficeBoxOfficeSaleCalculation = boxofficeBoxOfficeSaleCalculation
        self.careplansCareGoalCalculation = careplansCareGoalCalculation
        self.careplansCarePlan = careplansCarePlan
        self.concessionsConcessionStandQuery = concessionsConcessionStandQuery
        self.documentsDocumentQuery = documentsDocumentQuery
        self.identityUser = identityUser
        self.ledgerLedgerAccountValidation = ledgerLedgerAccountValidation
        self.prescriptionsPrescriptionCalculation = prescriptionsPrescriptionCalculation
        self.sponsorshipsSponsorCalculation = sponsorshipsSponsorCalculation
        self.telehealthVisitNoteQuery = telehealthVisitNoteQuery
        self.venuesVenueQuery = venuesVenueQuery
        self.venuesVenueValidation = venuesVenueValidation
        self.calculateRefillStep0 = [
            "primary": { request in try await documentsDocumentQuery.summarizeDocuments(request) }
        ]
        self.simulateRefillStep3 = ClosurePort<
            Acme_Careplans_V1_CalculateCareGoalRequest, Acme_Careplans_V1_CalculateCareGoalResponse
        >({ request in try await careplansCareGoalCalculation.calculateCareGoal(request) })
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
