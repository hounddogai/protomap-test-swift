import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Manages video visits: creates, reads, changes, and lists them.
final class VideoVisitEndpoint: Acme_Telehealth_V1_VideoVisitService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let careplansCareGoalQuery: Acme_Careplans_V1_CareGoalQueryService.Client<MeshTransport>
    let careplansCareGoalValidation: Acme_Careplans_V1_CareGoalValidationService.Client<MeshTransport>
    let careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>
    let careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client<MeshTransport>
    let careplansVitalValidation: Acme_Careplans_V1_VitalValidationService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let ledgerLedgerAccount: Acme_Ledger_V1_LedgerAccountService.Client<MeshTransport>
    let seatingSeatMap: Acme_Seating_V1_SeatMapService.Client<MeshTransport>
    let telehealthTriageValidation: Acme_Telehealth_V1_TriageValidationService.Client<MeshTransport>
    let telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client<MeshTransport>
    let telehealthVideoVisitValidation: Acme_Telehealth_V1_VideoVisitValidationService.Client<MeshTransport>
    let telehealthVisitNoteCalculation: Acme_Telehealth_V1_VisitNoteCalculationService.Client<MeshTransport>
    let telehealthVisitNoteQuery: Acme_Telehealth_V1_VisitNoteQueryService.Client<MeshTransport>
    let venuesVenueValidation: Acme_Venues_V1_VenueValidationService.Client<MeshTransport>
    let batchGetVideoVisitsStep0:
        @Sendable (Acme_Venues_V1_NormalizeVenueRequest) async throws -> Acme_Venues_V1_NormalizeVenueResponse
    let cloneVideoVisitStep0:
        [String:
            @Sendable (Acme_Telehealth_V1_RecalculateVideoVisitsRequest) async throws ->
            Acme_Telehealth_V1_RecalculateVideoVisitsResponse]

    init(
        dependencies: any Dependencies,
        careplansCareGoalQuery: Acme_Careplans_V1_CareGoalQueryService.Client<MeshTransport>,
        careplansCareGoalValidation: Acme_Careplans_V1_CareGoalValidationService.Client<MeshTransport>,
        careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>,
        careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client<MeshTransport>,
        careplansVitalValidation: Acme_Careplans_V1_VitalValidationService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        ledgerLedgerAccount: Acme_Ledger_V1_LedgerAccountService.Client<MeshTransport>,
        seatingSeatMap: Acme_Seating_V1_SeatMapService.Client<MeshTransport>,
        telehealthTriageValidation: Acme_Telehealth_V1_TriageValidationService.Client<MeshTransport>,
        telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client<MeshTransport>,
        telehealthVideoVisitValidation: Acme_Telehealth_V1_VideoVisitValidationService.Client<MeshTransport>,
        telehealthVisitNoteCalculation: Acme_Telehealth_V1_VisitNoteCalculationService.Client<MeshTransport>,
        telehealthVisitNoteQuery: Acme_Telehealth_V1_VisitNoteQueryService.Client<MeshTransport>,
        venuesVenueValidation: Acme_Venues_V1_VenueValidationService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.careplansCareGoalQuery = careplansCareGoalQuery
        self.careplansCareGoalValidation = careplansCareGoalValidation
        self.careplansCarePlan = careplansCarePlan
        self.careplansCarePlanValidation = careplansCarePlanValidation
        self.careplansVitalValidation = careplansVitalValidation
        self.identityUser = identityUser
        self.ledgerLedgerAccount = ledgerLedgerAccount
        self.seatingSeatMap = seatingSeatMap
        self.telehealthTriageValidation = telehealthTriageValidation
        self.telehealthVideoVisitCalculation = telehealthVideoVisitCalculation
        self.telehealthVideoVisitValidation = telehealthVideoVisitValidation
        self.telehealthVisitNoteCalculation = telehealthVisitNoteCalculation
        self.telehealthVisitNoteQuery = telehealthVisitNoteQuery
        self.venuesVenueValidation = venuesVenueValidation
        self.batchGetVideoVisitsStep0 = { request in try await venuesVenueValidation.normalizeVenue(request) }
        self.cloneVideoVisitStep0 = [
            "primary": { request in try await telehealthVideoVisitCalculation.recalculateVideoVisits(request) }
        ]
    }
}
