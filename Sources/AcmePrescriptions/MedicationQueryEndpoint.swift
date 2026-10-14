import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Answers read-only questions about medications, for screens and reports.
final class MedicationQueryEndpoint: Acme_Prescriptions_V1_MedicationQueryService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let careplansCareGoalValidation: Acme_Careplans_V1_CareGoalValidationService.Client<MeshTransport>
    let documentsDocumentQuery: Acme_Documents_V1_DocumentQueryService.Client<MeshTransport>
    let featureflagsFeatureFlagQuery: Acme_Featureflags_V1_FeatureFlagQueryService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let metricsMetricSeries: Acme_Metrics_V1_MetricSeriesService.Client<MeshTransport>
    let prescriptionsMedicationCalculation: Acme_Prescriptions_V1_MedicationCalculationService.Client<MeshTransport>
    let prescriptionsPrescriptionQuery: Acme_Prescriptions_V1_PrescriptionQueryService.Client<MeshTransport>
    let prescriptionsPrescriptionValidation: Acme_Prescriptions_V1_PrescriptionValidationService.Client<MeshTransport>
    let seatingSeatMap: Acme_Seating_V1_SeatMapService.Client<MeshTransport>
    let sponsorshipsSponsor: Acme_Sponsorships_V1_SponsorService.Client<MeshTransport>
    let telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client<MeshTransport>
    let telehealthVisitNoteValidation: Acme_Telehealth_V1_VisitNoteValidationService.Client<MeshTransport>
    let exportMedicationsStep1:
        any RPCPort<Acme_Careplans_V1_ValidateCareGoalRequest, Acme_Careplans_V1_ValidateCareGoalResponse>
    let lookupMedicationStep1:
        @Sendable (Acme_Featureflags_V1_SuggestFeatureFlagsRequest) async throws ->
            Acme_Featureflags_V1_SuggestFeatureFlagsResponse
    let resolveMedicationsStep0:
        [String:
            @Sendable (Acme_Sponsorships_V1_CloneSponsorRequest) async throws ->
            Acme_Sponsorships_V1_CloneSponsorResponse]

    init(
        dependencies: any Dependencies,
        careplansCareGoalValidation: Acme_Careplans_V1_CareGoalValidationService.Client<MeshTransport>,
        documentsDocumentQuery: Acme_Documents_V1_DocumentQueryService.Client<MeshTransport>,
        featureflagsFeatureFlagQuery: Acme_Featureflags_V1_FeatureFlagQueryService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        metricsMetricSeries: Acme_Metrics_V1_MetricSeriesService.Client<MeshTransport>,
        prescriptionsMedicationCalculation: Acme_Prescriptions_V1_MedicationCalculationService.Client<MeshTransport>,
        prescriptionsPrescriptionQuery: Acme_Prescriptions_V1_PrescriptionQueryService.Client<MeshTransport>,
        prescriptionsPrescriptionValidation: Acme_Prescriptions_V1_PrescriptionValidationService.Client<MeshTransport>,
        seatingSeatMap: Acme_Seating_V1_SeatMapService.Client<MeshTransport>,
        sponsorshipsSponsor: Acme_Sponsorships_V1_SponsorService.Client<MeshTransport>,
        telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client<MeshTransport>,
        telehealthVisitNoteValidation: Acme_Telehealth_V1_VisitNoteValidationService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.careplansCareGoalValidation = careplansCareGoalValidation
        self.documentsDocumentQuery = documentsDocumentQuery
        self.featureflagsFeatureFlagQuery = featureflagsFeatureFlagQuery
        self.identityUser = identityUser
        self.metricsMetricSeries = metricsMetricSeries
        self.prescriptionsMedicationCalculation = prescriptionsMedicationCalculation
        self.prescriptionsPrescriptionQuery = prescriptionsPrescriptionQuery
        self.prescriptionsPrescriptionValidation = prescriptionsPrescriptionValidation
        self.seatingSeatMap = seatingSeatMap
        self.sponsorshipsSponsor = sponsorshipsSponsor
        self.telehealthVideoVisit = telehealthVideoVisit
        self.telehealthVisitNoteValidation = telehealthVisitNoteValidation
        self.exportMedicationsStep1 = ClosurePort<
            Acme_Careplans_V1_ValidateCareGoalRequest, Acme_Careplans_V1_ValidateCareGoalResponse
        >({ request in try await careplansCareGoalValidation.validateCareGoal(request) })
        self.lookupMedicationStep1 = { request in try await featureflagsFeatureFlagQuery.suggestFeatureFlags(request) }
        self.resolveMedicationsStep0 = ["primary": { request in try await sponsorshipsSponsor.cloneSponsor(request) }]
    }
}
