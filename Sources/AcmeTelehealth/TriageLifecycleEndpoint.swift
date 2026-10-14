import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Moves a triage between the states of its lifecycle.
final class TriageLifecycleEndpoint: Acme_Telehealth_V1_TriageLifecycleService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let auditAuditEventValidation: Acme_Audit_V1_AuditEventValidationService.Client<MeshTransport>
    let authorizationAccessPolicyValidation: Acme_Authorization_V1_AccessPolicyValidationService.Client<MeshTransport>
    let careplansCarePlanApproval: Acme_Careplans_V1_CarePlanApprovalService.Client<MeshTransport>
    let collectionsCollectionCase: Acme_Collections_V1_CollectionCaseService.Client<MeshTransport>
    let configurationConfigSet: Acme_Configuration_V1_ConfigSetService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let identityUserQuery: Acme_Identity_V1_UserQueryService.Client<MeshTransport>
    let metricsMetricSeriesQuery: Acme_Metrics_V1_MetricSeriesQueryService.Client<MeshTransport>
    let metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client<MeshTransport>
    let notificationsNotificationValidation: Acme_Notifications_V1_NotificationValidationService.Client<MeshTransport>
    let patientsAllergyValidation: Acme_Patients_V1_AllergyValidationService.Client<MeshTransport>
    let patientsPatient: Acme_Patients_V1_PatientService.Client<MeshTransport>
    let telehealthTriageCalculation: Acme_Telehealth_V1_TriageCalculationService.Client<MeshTransport>
    let telehealthTriageValidation: Acme_Telehealth_V1_TriageValidationService.Client<MeshTransport>
    let telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client<MeshTransport>
    let telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client<MeshTransport>
    let telehealthVideoVisitValidation: Acme_Telehealth_V1_VideoVisitValidationService.Client<MeshTransport>
    let telehealthVisitNoteCalculation: Acme_Telehealth_V1_VisitNoteCalculationService.Client<MeshTransport>
    let telehealthVisitNoteValidation: Acme_Telehealth_V1_VisitNoteValidationService.Client<MeshTransport>
    let venuesVenueQuery: Acme_Venues_V1_VenueQueryService.Client<MeshTransport>
    let activateTriageStep1: any RPCPort<Acme_Venues_V1_CountVenuesRequest, Acme_Venues_V1_CountVenuesResponse>
    let activateTriageStep3:
        @Sendable (Acme_Telehealth_V1_NormalizeVisitNoteRequest) async throws ->
            Acme_Telehealth_V1_NormalizeVisitNoteResponse
    let expireTriageStep0:
        [String:
            @Sendable (Acme_Notifications_V1_PreviewNotificationRequest) async throws ->
            Acme_Notifications_V1_PreviewNotificationResponse]

    init(
        dependencies: any Dependencies,
        auditAuditEventValidation: Acme_Audit_V1_AuditEventValidationService.Client<MeshTransport>,
        authorizationAccessPolicyValidation: Acme_Authorization_V1_AccessPolicyValidationService.Client<MeshTransport>,
        careplansCarePlanApproval: Acme_Careplans_V1_CarePlanApprovalService.Client<MeshTransport>,
        collectionsCollectionCase: Acme_Collections_V1_CollectionCaseService.Client<MeshTransport>,
        configurationConfigSet: Acme_Configuration_V1_ConfigSetService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        identityUserQuery: Acme_Identity_V1_UserQueryService.Client<MeshTransport>,
        metricsMetricSeriesQuery: Acme_Metrics_V1_MetricSeriesQueryService.Client<MeshTransport>,
        metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client<MeshTransport>,
        notificationsNotificationValidation: Acme_Notifications_V1_NotificationValidationService.Client<MeshTransport>,
        patientsAllergyValidation: Acme_Patients_V1_AllergyValidationService.Client<MeshTransport>,
        patientsPatient: Acme_Patients_V1_PatientService.Client<MeshTransport>,
        telehealthTriageCalculation: Acme_Telehealth_V1_TriageCalculationService.Client<MeshTransport>,
        telehealthTriageValidation: Acme_Telehealth_V1_TriageValidationService.Client<MeshTransport>,
        telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client<MeshTransport>,
        telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client<MeshTransport>,
        telehealthVideoVisitValidation: Acme_Telehealth_V1_VideoVisitValidationService.Client<MeshTransport>,
        telehealthVisitNoteCalculation: Acme_Telehealth_V1_VisitNoteCalculationService.Client<MeshTransport>,
        telehealthVisitNoteValidation: Acme_Telehealth_V1_VisitNoteValidationService.Client<MeshTransport>,
        venuesVenueQuery: Acme_Venues_V1_VenueQueryService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.auditAuditEventValidation = auditAuditEventValidation
        self.authorizationAccessPolicyValidation = authorizationAccessPolicyValidation
        self.careplansCarePlanApproval = careplansCarePlanApproval
        self.collectionsCollectionCase = collectionsCollectionCase
        self.configurationConfigSet = configurationConfigSet
        self.identityUser = identityUser
        self.identityUserQuery = identityUserQuery
        self.metricsMetricSeriesQuery = metricsMetricSeriesQuery
        self.metricsMetricSeriesValidation = metricsMetricSeriesValidation
        self.notificationsNotificationValidation = notificationsNotificationValidation
        self.patientsAllergyValidation = patientsAllergyValidation
        self.patientsPatient = patientsPatient
        self.telehealthTriageCalculation = telehealthTriageCalculation
        self.telehealthTriageValidation = telehealthTriageValidation
        self.telehealthVideoVisit = telehealthVideoVisit
        self.telehealthVideoVisitCalculation = telehealthVideoVisitCalculation
        self.telehealthVideoVisitValidation = telehealthVideoVisitValidation
        self.telehealthVisitNoteCalculation = telehealthVisitNoteCalculation
        self.telehealthVisitNoteValidation = telehealthVisitNoteValidation
        self.venuesVenueQuery = venuesVenueQuery
        self.activateTriageStep1 = ClosurePort<Acme_Venues_V1_CountVenuesRequest, Acme_Venues_V1_CountVenuesResponse>({
            request in try await venuesVenueQuery.countVenues(request)
        })
        self.activateTriageStep3 = { request in try await telehealthVisitNoteValidation.normalizeVisitNote(request) }
        self.expireTriageStep0 = [
            "primary": { request in try await notificationsNotificationValidation.previewNotification(request) }
        ]
    }
}
