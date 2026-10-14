import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Computes the figures of a care goal, such as totals, taxes, and estimates.
final class CareGoalCalculationEndpoint: Acme_Careplans_V1_CareGoalCalculationService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let followUps = WorkQueue<Acme_Identity_V1_GetUserRequest>()
    let careplansCarePlanCalculation: Acme_Careplans_V1_CarePlanCalculationService.Client<MeshTransport>
    let concessionsConcessionStandCalculation:
        Acme_Concessions_V1_ConcessionStandCalculationService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let ledgerLedgerAccount: Acme_Ledger_V1_LedgerAccountService.Client<MeshTransport>
    let metricsMetricSeriesQuery: Acme_Metrics_V1_MetricSeriesQueryService.Client<MeshTransport>
    let metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client<MeshTransport>
    let simulateCareGoalStep0:
        any RPCPort<Acme_Careplans_V1_CalculateCarePlanRequest, Acme_Careplans_V1_CalculateCarePlanResponse>

    init(
        dependencies: any Dependencies,
        careplansCarePlanCalculation: Acme_Careplans_V1_CarePlanCalculationService.Client<MeshTransport>,
        concessionsConcessionStandCalculation: Acme_Concessions_V1_ConcessionStandCalculationService.Client<
            MeshTransport
        >,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        ledgerLedgerAccount: Acme_Ledger_V1_LedgerAccountService.Client<MeshTransport>,
        metricsMetricSeriesQuery: Acme_Metrics_V1_MetricSeriesQueryService.Client<MeshTransport>,
        metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.careplansCarePlanCalculation = careplansCarePlanCalculation
        self.concessionsConcessionStandCalculation = concessionsConcessionStandCalculation
        self.identityUser = identityUser
        self.ledgerLedgerAccount = ledgerLedgerAccount
        self.metricsMetricSeriesQuery = metricsMetricSeriesQuery
        self.metricsMetricSeriesValidation = metricsMetricSeriesValidation
        self.simulateCareGoalStep0 = ClosurePort<
            Acme_Careplans_V1_CalculateCarePlanRequest, Acme_Careplans_V1_CalculateCarePlanResponse
        >({ request in try await careplansCarePlanCalculation.calculateCarePlan(request) })
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
