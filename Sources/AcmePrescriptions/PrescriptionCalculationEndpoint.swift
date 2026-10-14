import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Computes the figures of a prescription, such as totals, taxes, and estimates.
final class PrescriptionCalculationEndpoint: Acme_Prescriptions_V1_PrescriptionCalculationService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let auditAuditEventValidation: Acme_Audit_V1_AuditEventValidationService.Client<MeshTransport>
    let careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>
    let careplansCareGoalValidation: Acme_Careplans_V1_CareGoalValidationService.Client<MeshTransport>
    let careplansCarePlanQuery: Acme_Careplans_V1_CarePlanQueryService.Client<MeshTransport>
    let careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let ledgerLedgerAccountQuery: Acme_Ledger_V1_LedgerAccountQueryService.Client<MeshTransport>
    let metricsMetricSeries: Acme_Metrics_V1_MetricSeriesService.Client<MeshTransport>
    let showsShowCalculation: Acme_Shows_V1_ShowCalculationService.Client<MeshTransport>
    let telehealthTriageValidation: Acme_Telehealth_V1_TriageValidationService.Client<MeshTransport>
    let telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client<MeshTransport>
    let telehealthVideoVisitValidation: Acme_Telehealth_V1_VideoVisitValidationService.Client<MeshTransport>
    let telehealthVisitNoteQuery: Acme_Telehealth_V1_VisitNoteQueryService.Client<MeshTransport>
    let venuesVenueValidation: Acme_Venues_V1_VenueValidationService.Client<MeshTransport>
    let comparePrescriptionOptionsStep0:
        any RPCPort<Acme_Telehealth_V1_LintVideoVisitsRequest, Acme_Telehealth_V1_LintVideoVisitsResponse>
    let estimatePrescriptionStep0:
        @Sendable (Acme_Telehealth_V1_CountVisitNotesRequest) async throws -> Acme_Telehealth_V1_CountVisitNotesResponse
    let estimatePrescriptionStep1:
        [String:
            @Sendable (Acme_Telehealth_V1_SuggestVisitNotesRequest) async throws ->
            Acme_Telehealth_V1_SuggestVisitNotesResponse]

    init(
        dependencies: any Dependencies,
        auditAuditEventValidation: Acme_Audit_V1_AuditEventValidationService.Client<MeshTransport>,
        careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>,
        careplansCareGoalValidation: Acme_Careplans_V1_CareGoalValidationService.Client<MeshTransport>,
        careplansCarePlanQuery: Acme_Careplans_V1_CarePlanQueryService.Client<MeshTransport>,
        careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        ledgerLedgerAccountQuery: Acme_Ledger_V1_LedgerAccountQueryService.Client<MeshTransport>,
        metricsMetricSeries: Acme_Metrics_V1_MetricSeriesService.Client<MeshTransport>,
        showsShowCalculation: Acme_Shows_V1_ShowCalculationService.Client<MeshTransport>,
        telehealthTriageValidation: Acme_Telehealth_V1_TriageValidationService.Client<MeshTransport>,
        telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client<MeshTransport>,
        telehealthVideoVisitValidation: Acme_Telehealth_V1_VideoVisitValidationService.Client<MeshTransport>,
        telehealthVisitNoteQuery: Acme_Telehealth_V1_VisitNoteQueryService.Client<MeshTransport>,
        venuesVenueValidation: Acme_Venues_V1_VenueValidationService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.auditAuditEventValidation = auditAuditEventValidation
        self.careplansCareGoalCalculation = careplansCareGoalCalculation
        self.careplansCareGoalValidation = careplansCareGoalValidation
        self.careplansCarePlanQuery = careplansCarePlanQuery
        self.careplansCarePlanValidation = careplansCarePlanValidation
        self.identityUser = identityUser
        self.ledgerLedgerAccountQuery = ledgerLedgerAccountQuery
        self.metricsMetricSeries = metricsMetricSeries
        self.showsShowCalculation = showsShowCalculation
        self.telehealthTriageValidation = telehealthTriageValidation
        self.telehealthVideoVisit = telehealthVideoVisit
        self.telehealthVideoVisitValidation = telehealthVideoVisitValidation
        self.telehealthVisitNoteQuery = telehealthVisitNoteQuery
        self.venuesVenueValidation = venuesVenueValidation
        self.comparePrescriptionOptionsStep0 = ClosurePort<
            Acme_Telehealth_V1_LintVideoVisitsRequest, Acme_Telehealth_V1_LintVideoVisitsResponse
        >({ request in try await telehealthVideoVisitValidation.lintVideoVisits(request) })
        self.estimatePrescriptionStep0 = { request in try await telehealthVisitNoteQuery.countVisitNotes(request) }
        self.estimatePrescriptionStep1 = [
            "primary": { request in try await telehealthVisitNoteQuery.suggestVisitNotes(request) }
        ]
    }
}
