import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Checks care goals against the rules before anything acts on them.
final class CareGoalValidationEndpoint: Acme_Careplans_V1_CareGoalValidationService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let boxofficeBoxOfficeSale: Acme_Boxoffice_V1_BoxOfficeSaleService.Client<MeshTransport>
    let boxofficeBoxOfficeSaleQuery: Acme_Boxoffice_V1_BoxOfficeSaleQueryService.Client<MeshTransport>
    let careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>
    let careplansCarePlanCalculation: Acme_Careplans_V1_CarePlanCalculationService.Client<MeshTransport>
    let careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let ledgerLedgerAccountValidation: Acme_Ledger_V1_LedgerAccountValidationService.Client<MeshTransport>
    let metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client<MeshTransport>
    let getCareGoalRulesStep0:
        [String:
            @Sendable (Acme_Careplans_V1_LintCarePlansRequest) async throws -> Acme_Careplans_V1_LintCarePlansResponse]

    init(
        dependencies: any Dependencies,
        boxofficeBoxOfficeSale: Acme_Boxoffice_V1_BoxOfficeSaleService.Client<MeshTransport>,
        boxofficeBoxOfficeSaleQuery: Acme_Boxoffice_V1_BoxOfficeSaleQueryService.Client<MeshTransport>,
        careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>,
        careplansCarePlanCalculation: Acme_Careplans_V1_CarePlanCalculationService.Client<MeshTransport>,
        careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        ledgerLedgerAccountValidation: Acme_Ledger_V1_LedgerAccountValidationService.Client<MeshTransport>,
        metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.boxofficeBoxOfficeSale = boxofficeBoxOfficeSale
        self.boxofficeBoxOfficeSaleQuery = boxofficeBoxOfficeSaleQuery
        self.careplansCareGoalCalculation = careplansCareGoalCalculation
        self.careplansCarePlanCalculation = careplansCarePlanCalculation
        self.careplansCarePlanValidation = careplansCarePlanValidation
        self.identityUser = identityUser
        self.ledgerLedgerAccountValidation = ledgerLedgerAccountValidation
        self.metricsMetricSeriesValidation = metricsMetricSeriesValidation
        self.getCareGoalRulesStep0 = [
            "primary": { request in try await careplansCarePlanValidation.lintCarePlans(request) }
        ]
    }
}
