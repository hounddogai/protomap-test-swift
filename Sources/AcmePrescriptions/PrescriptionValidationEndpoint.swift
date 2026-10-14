import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Checks prescriptions against the rules before anything acts on them.
final class PrescriptionValidationEndpoint: Acme_Prescriptions_V1_PrescriptionValidationService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client<MeshTransport>
    let featureflagsFeatureFlag: Acme_Featureflags_V1_FeatureFlagService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let metricsMetricSeriesQuery: Acme_Metrics_V1_MetricSeriesQueryService.Client<MeshTransport>
    let notificationsNotificationValidation: Acme_Notifications_V1_NotificationValidationService.Client<MeshTransport>
    let prescriptionsMedicationCalculation: Acme_Prescriptions_V1_MedicationCalculationService.Client<MeshTransport>
    let prescriptionsPrescriptionCalculation: Acme_Prescriptions_V1_PrescriptionCalculationService.Client<MeshTransport>
    let seatingSeatMapCalculation: Acme_Seating_V1_SeatMapCalculationService.Client<MeshTransport>
    let telehealthTriageCalculation: Acme_Telehealth_V1_TriageCalculationService.Client<MeshTransport>
    let telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client<MeshTransport>
    let telehealthVisitNoteCalculation: Acme_Telehealth_V1_VisitNoteCalculationService.Client<MeshTransport>
    let telehealthVisitNoteQuery: Acme_Telehealth_V1_VisitNoteQueryService.Client<MeshTransport>
    let normalizePrescriptionStep2:
        any RPCPort<Acme_Featureflags_V1_ListFeatureFlagsRequest, Acme_Featureflags_V1_ListFeatureFlagsResponse>
    let scorePrescriptionStep1:
        @Sendable (Acme_Prescriptions_V1_GetPrescriptionRatesRequest) async throws ->
            Acme_Prescriptions_V1_GetPrescriptionRatesResponse
    let validatePrescriptionStep0:
        [String:
            @Sendable (Acme_Prescriptions_V1_GetPrescriptionRatesRequest) async throws ->
            Acme_Prescriptions_V1_GetPrescriptionRatesResponse]

    init(
        dependencies: any Dependencies,
        careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client<MeshTransport>,
        featureflagsFeatureFlag: Acme_Featureflags_V1_FeatureFlagService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        metricsMetricSeriesQuery: Acme_Metrics_V1_MetricSeriesQueryService.Client<MeshTransport>,
        notificationsNotificationValidation: Acme_Notifications_V1_NotificationValidationService.Client<MeshTransport>,
        prescriptionsMedicationCalculation: Acme_Prescriptions_V1_MedicationCalculationService.Client<MeshTransport>,
        prescriptionsPrescriptionCalculation: Acme_Prescriptions_V1_PrescriptionCalculationService.Client<
            MeshTransport
        >,
        seatingSeatMapCalculation: Acme_Seating_V1_SeatMapCalculationService.Client<MeshTransport>,
        telehealthTriageCalculation: Acme_Telehealth_V1_TriageCalculationService.Client<MeshTransport>,
        telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client<MeshTransport>,
        telehealthVisitNoteCalculation: Acme_Telehealth_V1_VisitNoteCalculationService.Client<MeshTransport>,
        telehealthVisitNoteQuery: Acme_Telehealth_V1_VisitNoteQueryService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.careplansCarePlanValidation = careplansCarePlanValidation
        self.featureflagsFeatureFlag = featureflagsFeatureFlag
        self.identityUser = identityUser
        self.metricsMetricSeriesQuery = metricsMetricSeriesQuery
        self.notificationsNotificationValidation = notificationsNotificationValidation
        self.prescriptionsMedicationCalculation = prescriptionsMedicationCalculation
        self.prescriptionsPrescriptionCalculation = prescriptionsPrescriptionCalculation
        self.seatingSeatMapCalculation = seatingSeatMapCalculation
        self.telehealthTriageCalculation = telehealthTriageCalculation
        self.telehealthVideoVisit = telehealthVideoVisit
        self.telehealthVisitNoteCalculation = telehealthVisitNoteCalculation
        self.telehealthVisitNoteQuery = telehealthVisitNoteQuery
        self.normalizePrescriptionStep2 = ClosurePort<
            Acme_Featureflags_V1_ListFeatureFlagsRequest, Acme_Featureflags_V1_ListFeatureFlagsResponse
        >({ request in try await featureflagsFeatureFlag.listFeatureFlags(request) })
        self.scorePrescriptionStep1 = { request in
            try await prescriptionsPrescriptionCalculation.getPrescriptionRates(request)
        }
        self.validatePrescriptionStep0 = [
            "primary": { request in try await prescriptionsPrescriptionCalculation.getPrescriptionRates(request) }
        ]
    }
}
