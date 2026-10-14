import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Composes the telehealth bounded context and exposes its services and background workers.
public enum TelehealthModule {
    public static func make(dependencies: any Dependencies) -> ServiceModule {
        let triageApprovalEndpoint = TriageApprovalEndpoint(
            dependencies: dependencies,
            careplansCarePlanQuery: Acme_Careplans_V1_CarePlanQueryService.Client(wrapping: dependencies.mesh),
            careplansVitalApproval: Acme_Careplans_V1_VitalApprovalService.Client(wrapping: dependencies.mesh),
            careplansVitalWorkflow: Acme_Careplans_V1_VitalWorkflowService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            identityUserValidation: Acme_Identity_V1_UserValidationService.Client(wrapping: dependencies.mesh),
            patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client(
                wrapping: dependencies.mesh),
            patientsPatient: Acme_Patients_V1_PatientService.Client(wrapping: dependencies.mesh),
            patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client(wrapping: dependencies.mesh),
            telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client(
                wrapping: dependencies.mesh),
            telehealthVisitNoteCalculation: Acme_Telehealth_V1_VisitNoteCalculationService.Client(
                wrapping: dependencies.mesh),
            telehealthVisitNoteQuery: Acme_Telehealth_V1_VisitNoteQueryService.Client(wrapping: dependencies.mesh)
        )
        let triageCalculationEndpoint = TriageCalculationEndpoint(
            dependencies: dependencies,
            careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client(
                wrapping: dependencies.mesh),
            careplansCareGoalQuery: Acme_Careplans_V1_CareGoalQueryService.Client(wrapping: dependencies.mesh),
            careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client(wrapping: dependencies.mesh),
            careplansCarePlanCalculation: Acme_Careplans_V1_CarePlanCalculationService.Client(
                wrapping: dependencies.mesh),
            careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client(
                wrapping: dependencies.mesh),
            careplansVitalValidation: Acme_Careplans_V1_VitalValidationService.Client(wrapping: dependencies.mesh),
            featureflagsFeatureFlagValidation: Acme_Featureflags_V1_FeatureFlagValidationService.Client(
                wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            metricsMetricSeries: Acme_Metrics_V1_MetricSeriesService.Client(wrapping: dependencies.mesh),
            telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client(
                wrapping: dependencies.mesh),
            telehealthVideoVisitValidation: Acme_Telehealth_V1_VideoVisitValidationService.Client(
                wrapping: dependencies.mesh),
            telehealthVisitNoteCalculation: Acme_Telehealth_V1_VisitNoteCalculationService.Client(
                wrapping: dependencies.mesh)
        )
        let triageLifecycleEndpoint = TriageLifecycleEndpoint(
            dependencies: dependencies,
            auditAuditEventValidation: Acme_Audit_V1_AuditEventValidationService.Client(wrapping: dependencies.mesh),
            authorizationAccessPolicyValidation: Acme_Authorization_V1_AccessPolicyValidationService.Client(
                wrapping: dependencies.mesh),
            careplansCarePlanApproval: Acme_Careplans_V1_CarePlanApprovalService.Client(wrapping: dependencies.mesh),
            collectionsCollectionCase: Acme_Collections_V1_CollectionCaseService.Client(wrapping: dependencies.mesh),
            configurationConfigSet: Acme_Configuration_V1_ConfigSetService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            identityUserQuery: Acme_Identity_V1_UserQueryService.Client(wrapping: dependencies.mesh),
            metricsMetricSeriesQuery: Acme_Metrics_V1_MetricSeriesQueryService.Client(wrapping: dependencies.mesh),
            metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client(
                wrapping: dependencies.mesh),
            notificationsNotificationValidation: Acme_Notifications_V1_NotificationValidationService.Client(
                wrapping: dependencies.mesh),
            patientsAllergyValidation: Acme_Patients_V1_AllergyValidationService.Client(wrapping: dependencies.mesh),
            patientsPatient: Acme_Patients_V1_PatientService.Client(wrapping: dependencies.mesh),
            telehealthTriageCalculation: Acme_Telehealth_V1_TriageCalculationService.Client(
                wrapping: dependencies.mesh),
            telehealthTriageValidation: Acme_Telehealth_V1_TriageValidationService.Client(wrapping: dependencies.mesh),
            telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client(wrapping: dependencies.mesh),
            telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client(
                wrapping: dependencies.mesh),
            telehealthVideoVisitValidation: Acme_Telehealth_V1_VideoVisitValidationService.Client(
                wrapping: dependencies.mesh),
            telehealthVisitNoteCalculation: Acme_Telehealth_V1_VisitNoteCalculationService.Client(
                wrapping: dependencies.mesh),
            telehealthVisitNoteValidation: Acme_Telehealth_V1_VisitNoteValidationService.Client(
                wrapping: dependencies.mesh),
            venuesVenueQuery: Acme_Venues_V1_VenueQueryService.Client(wrapping: dependencies.mesh)
        )
        let triageValidationEndpoint = TriageValidationEndpoint(
            dependencies: dependencies,
            careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client(wrapping: dependencies.mesh),
            careplansCarePlanCalculation: Acme_Careplans_V1_CarePlanCalculationService.Client(
                wrapping: dependencies.mesh),
            careplansCarePlanQuery: Acme_Careplans_V1_CarePlanQueryService.Client(wrapping: dependencies.mesh),
            documentsDocumentQuery: Acme_Documents_V1_DocumentQueryService.Client(wrapping: dependencies.mesh),
            featureflagsFeatureFlag: Acme_Featureflags_V1_FeatureFlagService.Client(wrapping: dependencies.mesh),
            featureflagsFeatureFlagQuery: Acme_Featureflags_V1_FeatureFlagQueryService.Client(
                wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            searchSearchIndexQuery: Acme_Search_V1_SearchIndexQueryService.Client(wrapping: dependencies.mesh),
            telehealthTriageCalculation: Acme_Telehealth_V1_TriageCalculationService.Client(
                wrapping: dependencies.mesh),
            telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client(
                wrapping: dependencies.mesh),
            telehealthVisitNoteCalculation: Acme_Telehealth_V1_VisitNoteCalculationService.Client(
                wrapping: dependencies.mesh),
            telehealthVisitNoteValidation: Acme_Telehealth_V1_VisitNoteValidationService.Client(
                wrapping: dependencies.mesh)
        )
        let triageWorkflowEndpoint = TriageWorkflowEndpoint(
            dependencies: dependencies,
            careplansCareGoalApproval: Acme_Careplans_V1_CareGoalApprovalService.Client(wrapping: dependencies.mesh),
            careplansCarePlanWorkflow: Acme_Careplans_V1_CarePlanWorkflowService.Client(wrapping: dependencies.mesh),
            careplansVitalApproval: Acme_Careplans_V1_VitalApprovalService.Client(wrapping: dependencies.mesh),
            careplansVitalWorkflow: Acme_Careplans_V1_VitalWorkflowService.Client(wrapping: dependencies.mesh),
            deliveriesDelivery: Acme_Deliveries_V1_DeliveryService.Client(wrapping: dependencies.mesh),
            fleetVehicle: Acme_Fleet_V1_VehicleService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            ledgerLedgerAccountValidation: Acme_Ledger_V1_LedgerAccountValidationService.Client(
                wrapping: dependencies.mesh),
            notificationsNotification: Acme_Notifications_V1_NotificationService.Client(wrapping: dependencies.mesh),
            patientsPatient: Acme_Patients_V1_PatientService.Client(wrapping: dependencies.mesh),
            patientsPatientCalculation: Acme_Patients_V1_PatientCalculationService.Client(wrapping: dependencies.mesh),
            patientsPatientValidation: Acme_Patients_V1_PatientValidationService.Client(wrapping: dependencies.mesh),
            telehealthTriageApproval: Acme_Telehealth_V1_TriageApprovalService.Client(wrapping: dependencies.mesh),
            telehealthVideoVisitWorkflow: Acme_Telehealth_V1_VideoVisitWorkflowService.Client(
                wrapping: dependencies.mesh),
            telehealthVisitNoteWorkflow: Acme_Telehealth_V1_VisitNoteWorkflowService.Client(
                wrapping: dependencies.mesh),
            venuesVenueQuery: Acme_Venues_V1_VenueQueryService.Client(wrapping: dependencies.mesh)
        )
        let videoVisitApprovalEndpoint = VideoVisitApprovalEndpoint(
            dependencies: dependencies,
            careplansCarePlanApproval: Acme_Careplans_V1_CarePlanApprovalService.Client(wrapping: dependencies.mesh),
            careplansVitalReporting: Acme_Careplans_V1_VitalReportingService.Client(wrapping: dependencies.mesh),
            featureflagsFeatureFlagValidation: Acme_Featureflags_V1_FeatureFlagValidationService.Client(
                wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            notificationsNotificationValidation: Acme_Notifications_V1_NotificationValidationService.Client(
                wrapping: dependencies.mesh),
            patientsAllergyCalculation: Acme_Patients_V1_AllergyCalculationService.Client(wrapping: dependencies.mesh),
            patientsPatientValidation: Acme_Patients_V1_PatientValidationService.Client(wrapping: dependencies.mesh),
            prescriptionsPrescription: Acme_Prescriptions_V1_PrescriptionService.Client(wrapping: dependencies.mesh),
            ratelimitingRateLimitCalculation: Acme_Ratelimiting_V1_RateLimitCalculationService.Client(
                wrapping: dependencies.mesh),
            telehealthTriageCalculation: Acme_Telehealth_V1_TriageCalculationService.Client(
                wrapping: dependencies.mesh),
            telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client(
                wrapping: dependencies.mesh),
            telehealthVisitNoteQuery: Acme_Telehealth_V1_VisitNoteQueryService.Client(wrapping: dependencies.mesh),
            telehealthVisitNoteValidation: Acme_Telehealth_V1_VisitNoteValidationService.Client(
                wrapping: dependencies.mesh),
            venuesVenueQuery: Acme_Venues_V1_VenueQueryService.Client(wrapping: dependencies.mesh)
        )
        let videoVisitCalculationEndpoint = VideoVisitCalculationEndpoint(
            dependencies: dependencies,
            authorizationAccessPolicyValidation: Acme_Authorization_V1_AccessPolicyValidationService.Client(
                wrapping: dependencies.mesh),
            boxofficeBoxOfficeSale: Acme_Boxoffice_V1_BoxOfficeSaleService.Client(wrapping: dependencies.mesh),
            careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client(wrapping: dependencies.mesh),
            careplansCarePlanQuery: Acme_Careplans_V1_CarePlanQueryService.Client(wrapping: dependencies.mesh),
            concessionsConcessionStandCalculation: Acme_Concessions_V1_ConcessionStandCalculationService.Client(
                wrapping: dependencies.mesh),
            featureflagsFeatureFlag: Acme_Featureflags_V1_FeatureFlagService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            ledgerLedgerAccountValidation: Acme_Ledger_V1_LedgerAccountValidationService.Client(
                wrapping: dependencies.mesh),
            metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client(
                wrapping: dependencies.mesh),
            notificationsNotification: Acme_Notifications_V1_NotificationService.Client(wrapping: dependencies.mesh),
            toursTour: Acme_Tours_V1_TourService.Client(wrapping: dependencies.mesh)
        )
        let videoVisitQueryEndpoint = VideoVisitQueryEndpoint(
            dependencies: dependencies,
            careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client(wrapping: dependencies.mesh),
            careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client(
                wrapping: dependencies.mesh),
            documentsDocumentQuery: Acme_Documents_V1_DocumentQueryService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            metricsMetricSeriesQuery: Acme_Metrics_V1_MetricSeriesQueryService.Client(wrapping: dependencies.mesh),
            metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client(
                wrapping: dependencies.mesh),
            telehealthTriageCalculation: Acme_Telehealth_V1_TriageCalculationService.Client(
                wrapping: dependencies.mesh),
            telehealthVisitNoteCalculation: Acme_Telehealth_V1_VisitNoteCalculationService.Client(
                wrapping: dependencies.mesh)
        )
        let videoVisitEndpoint = VideoVisitEndpoint(
            dependencies: dependencies,
            careplansCareGoalQuery: Acme_Careplans_V1_CareGoalQueryService.Client(wrapping: dependencies.mesh),
            careplansCareGoalValidation: Acme_Careplans_V1_CareGoalValidationService.Client(
                wrapping: dependencies.mesh),
            careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client(wrapping: dependencies.mesh),
            careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client(
                wrapping: dependencies.mesh),
            careplansVitalValidation: Acme_Careplans_V1_VitalValidationService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            ledgerLedgerAccount: Acme_Ledger_V1_LedgerAccountService.Client(wrapping: dependencies.mesh),
            seatingSeatMap: Acme_Seating_V1_SeatMapService.Client(wrapping: dependencies.mesh),
            telehealthTriageValidation: Acme_Telehealth_V1_TriageValidationService.Client(wrapping: dependencies.mesh),
            telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client(
                wrapping: dependencies.mesh),
            telehealthVideoVisitValidation: Acme_Telehealth_V1_VideoVisitValidationService.Client(
                wrapping: dependencies.mesh),
            telehealthVisitNoteCalculation: Acme_Telehealth_V1_VisitNoteCalculationService.Client(
                wrapping: dependencies.mesh),
            telehealthVisitNoteQuery: Acme_Telehealth_V1_VisitNoteQueryService.Client(wrapping: dependencies.mesh),
            venuesVenueValidation: Acme_Venues_V1_VenueValidationService.Client(wrapping: dependencies.mesh)
        )
        let videoVisitValidationEndpoint = VideoVisitValidationEndpoint(
            dependencies: dependencies,
            careplansCareGoalQuery: Acme_Careplans_V1_CareGoalQueryService.Client(wrapping: dependencies.mesh),
            careplansCareGoalValidation: Acme_Careplans_V1_CareGoalValidationService.Client(
                wrapping: dependencies.mesh),
            careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client(wrapping: dependencies.mesh),
            careplansCarePlanQuery: Acme_Careplans_V1_CarePlanQueryService.Client(wrapping: dependencies.mesh),
            careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client(
                wrapping: dependencies.mesh),
            featureflagsFeatureFlagQuery: Acme_Featureflags_V1_FeatureFlagQueryService.Client(
                wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            ledgerLedgerAccountQuery: Acme_Ledger_V1_LedgerAccountQueryService.Client(wrapping: dependencies.mesh),
            notificationsNotificationValidation: Acme_Notifications_V1_NotificationValidationService.Client(
                wrapping: dependencies.mesh),
            searchSearchIndex: Acme_Search_V1_SearchIndexService.Client(wrapping: dependencies.mesh),
            sponsorshipsSponsor: Acme_Sponsorships_V1_SponsorService.Client(wrapping: dependencies.mesh),
            telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client(
                wrapping: dependencies.mesh),
            telehealthVisitNoteCalculation: Acme_Telehealth_V1_VisitNoteCalculationService.Client(
                wrapping: dependencies.mesh)
        )
        let videoVisitWorkflowEndpoint = VideoVisitWorkflowEndpoint(
            dependencies: dependencies,
            careplansCareGoalApproval: Acme_Careplans_V1_CareGoalApprovalService.Client(wrapping: dependencies.mesh),
            careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client(
                wrapping: dependencies.mesh),
            careplansCarePlanApproval: Acme_Careplans_V1_CarePlanApprovalService.Client(wrapping: dependencies.mesh),
            careplansCarePlanWorkflow: Acme_Careplans_V1_CarePlanWorkflowService.Client(wrapping: dependencies.mesh),
            careplansVitalWorkflow: Acme_Careplans_V1_VitalWorkflowService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            patientsAllergyValidation: Acme_Patients_V1_AllergyValidationService.Client(wrapping: dependencies.mesh),
            patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client(
                wrapping: dependencies.mesh),
            patientsMedicalRecordValidation: Acme_Patients_V1_MedicalRecordValidationService.Client(
                wrapping: dependencies.mesh),
            patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client(wrapping: dependencies.mesh),
            telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client(wrapping: dependencies.mesh),
            telehealthVideoVisitApproval: Acme_Telehealth_V1_VideoVisitApprovalService.Client(
                wrapping: dependencies.mesh),
            telehealthVisitNoteApproval: Acme_Telehealth_V1_VisitNoteApprovalService.Client(
                wrapping: dependencies.mesh),
            venuesVenueQuery: Acme_Venues_V1_VenueQueryService.Client(wrapping: dependencies.mesh)
        )
        let visitNoteApprovalEndpoint = VisitNoteApprovalEndpoint(
            dependencies: dependencies,
            authorizationAccessPolicyQuery: Acme_Authorization_V1_AccessPolicyQueryService.Client(
                wrapping: dependencies.mesh),
            careplansCareGoalApproval: Acme_Careplans_V1_CareGoalApprovalService.Client(wrapping: dependencies.mesh),
            careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client(wrapping: dependencies.mesh),
            careplansCarePlanApproval: Acme_Careplans_V1_CarePlanApprovalService.Client(wrapping: dependencies.mesh),
            careplansVitalWorkflow: Acme_Careplans_V1_VitalWorkflowService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            ledgerLedgerAccountValidation: Acme_Ledger_V1_LedgerAccountValidationService.Client(
                wrapping: dependencies.mesh),
            patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client(wrapping: dependencies.mesh),
            prescriptionsPrescriptionCalculation: Acme_Prescriptions_V1_PrescriptionCalculationService.Client(
                wrapping: dependencies.mesh),
            telehealthTriageCalculation: Acme_Telehealth_V1_TriageCalculationService.Client(
                wrapping: dependencies.mesh),
            telehealthVisitNoteCalculation: Acme_Telehealth_V1_VisitNoteCalculationService.Client(
                wrapping: dependencies.mesh),
            telehealthVisitNoteValidation: Acme_Telehealth_V1_VisitNoteValidationService.Client(
                wrapping: dependencies.mesh)
        )
        let visitNoteCalculationEndpoint = VisitNoteCalculationEndpoint(
            dependencies: dependencies,
            authorizationAccessPolicyQuery: Acme_Authorization_V1_AccessPolicyQueryService.Client(
                wrapping: dependencies.mesh),
            careplansCareGoalQuery: Acme_Careplans_V1_CareGoalQueryService.Client(wrapping: dependencies.mesh),
            careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client(wrapping: dependencies.mesh),
            careplansCarePlanQuery: Acme_Careplans_V1_CarePlanQueryService.Client(wrapping: dependencies.mesh),
            documentsDocument: Acme_Documents_V1_DocumentService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            ledgerLedgerAccount: Acme_Ledger_V1_LedgerAccountService.Client(wrapping: dependencies.mesh),
            notificationsNotificationValidation: Acme_Notifications_V1_NotificationValidationService.Client(
                wrapping: dependencies.mesh),
            searchSearchIndexQuery: Acme_Search_V1_SearchIndexQueryService.Client(wrapping: dependencies.mesh),
            telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client(
                wrapping: dependencies.mesh)
        )
        let visitNoteLifecycleEndpoint = VisitNoteLifecycleEndpoint(
            dependencies: dependencies,
            auditAuditEventQuery: Acme_Audit_V1_AuditEventQueryService.Client(wrapping: dependencies.mesh),
            careplansVitalReporting: Acme_Careplans_V1_VitalReportingService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            identityUserQuery: Acme_Identity_V1_UserQueryService.Client(wrapping: dependencies.mesh),
            metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client(
                wrapping: dependencies.mesh),
            patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client(wrapping: dependencies.mesh),
            prescriptionsPrescription: Acme_Prescriptions_V1_PrescriptionService.Client(wrapping: dependencies.mesh),
            searchSearchIndex: Acme_Search_V1_SearchIndexService.Client(wrapping: dependencies.mesh),
            searchSearchIndexQuery: Acme_Search_V1_SearchIndexQueryService.Client(wrapping: dependencies.mesh),
            telehealthTriageCalculation: Acme_Telehealth_V1_TriageCalculationService.Client(
                wrapping: dependencies.mesh),
            telehealthTriageValidation: Acme_Telehealth_V1_TriageValidationService.Client(wrapping: dependencies.mesh),
            telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client(
                wrapping: dependencies.mesh),
            telehealthVideoVisitQuery: Acme_Telehealth_V1_VideoVisitQueryService.Client(wrapping: dependencies.mesh),
            telehealthVisitNoteCalculation: Acme_Telehealth_V1_VisitNoteCalculationService.Client(
                wrapping: dependencies.mesh),
            yardsYardCalculation: Acme_Yards_V1_YardCalculationService.Client(wrapping: dependencies.mesh)
        )
        let visitNoteQueryEndpoint = VisitNoteQueryEndpoint(
            dependencies: dependencies,
            auditAuditEvent: Acme_Audit_V1_AuditEventService.Client(wrapping: dependencies.mesh),
            careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client(wrapping: dependencies.mesh),
            careplansVitalCalculation: Acme_Careplans_V1_VitalCalculationService.Client(wrapping: dependencies.mesh),
            featureflagsFeatureFlagValidation: Acme_Featureflags_V1_FeatureFlagValidationService.Client(
                wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            telehealthTriageCalculation: Acme_Telehealth_V1_TriageCalculationService.Client(
                wrapping: dependencies.mesh),
            telehealthTriageValidation: Acme_Telehealth_V1_TriageValidationService.Client(wrapping: dependencies.mesh),
            telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client(
                wrapping: dependencies.mesh),
            telehealthVideoVisitQuery: Acme_Telehealth_V1_VideoVisitQueryService.Client(wrapping: dependencies.mesh),
            telehealthVisitNoteValidation: Acme_Telehealth_V1_VisitNoteValidationService.Client(
                wrapping: dependencies.mesh)
        )
        let visitNoteValidationEndpoint = VisitNoteValidationEndpoint(
            dependencies: dependencies,
            authorizationAccessPolicy: Acme_Authorization_V1_AccessPolicyService.Client(wrapping: dependencies.mesh),
            authorizationAccessPolicyValidation: Acme_Authorization_V1_AccessPolicyValidationService.Client(
                wrapping: dependencies.mesh),
            careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client(wrapping: dependencies.mesh),
            careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client(
                wrapping: dependencies.mesh),
            featureflagsFeatureFlag: Acme_Featureflags_V1_FeatureFlagService.Client(wrapping: dependencies.mesh),
            featureflagsFeatureFlagValidation: Acme_Featureflags_V1_FeatureFlagValidationService.Client(
                wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            sponsorshipsSponsorCalculation: Acme_Sponsorships_V1_SponsorCalculationService.Client(
                wrapping: dependencies.mesh),
            telehealthTriageCalculation: Acme_Telehealth_V1_TriageCalculationService.Client(
                wrapping: dependencies.mesh),
            telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client(
                wrapping: dependencies.mesh),
            telehealthVideoVisitValidation: Acme_Telehealth_V1_VideoVisitValidationService.Client(
                wrapping: dependencies.mesh),
            telehealthVisitNoteCalculation: Acme_Telehealth_V1_VisitNoteCalculationService.Client(
                wrapping: dependencies.mesh)
        )
        let visitNoteWorkflowEndpoint = VisitNoteWorkflowEndpoint(
            dependencies: dependencies,
            anomaliesAnomalyQuery: Acme_Anomalies_V1_AnomalyQueryService.Client(wrapping: dependencies.mesh),
            appointmentsClinicSlotValidation: Acme_Appointments_V1_ClinicSlotValidationService.Client(
                wrapping: dependencies.mesh),
            appointmentsProviderQuery: Acme_Appointments_V1_ProviderQueryService.Client(wrapping: dependencies.mesh),
            contentArticle: Acme_Content_V1_ArticleService.Client(wrapping: dependencies.mesh),
            driversDriver: Acme_Drivers_V1_DriverService.Client(wrapping: dependencies.mesh),
            featureflagsFeatureFlag: Acme_Featureflags_V1_FeatureFlagService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client(
                wrapping: dependencies.mesh),
            patientsPatient: Acme_Patients_V1_PatientService.Client(wrapping: dependencies.mesh),
            patientsPatientValidation: Acme_Patients_V1_PatientValidationService.Client(wrapping: dependencies.mesh),
            telehealthVideoVisitApproval: Acme_Telehealth_V1_VideoVisitApprovalService.Client(
                wrapping: dependencies.mesh),
            telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client(
                wrapping: dependencies.mesh),
            telehealthVideoVisitValidation: Acme_Telehealth_V1_VideoVisitValidationService.Client(
                wrapping: dependencies.mesh),
            telehealthVideoVisitWorkflow: Acme_Telehealth_V1_VideoVisitWorkflowService.Client(
                wrapping: dependencies.mesh),
            telehealthVisitNoteCalculation: Acme_Telehealth_V1_VisitNoteCalculationService.Client(
                wrapping: dependencies.mesh),
            telehealthVisitNoteQuery: Acme_Telehealth_V1_VisitNoteQueryService.Client(wrapping: dependencies.mesh),
            venuesVenue: Acme_Venues_V1_VenueService.Client(wrapping: dependencies.mesh)
        )
        return ServiceModule(
            services: [
                triageApprovalEndpoint,
                triageCalculationEndpoint,
                triageLifecycleEndpoint,
                triageValidationEndpoint,
                triageWorkflowEndpoint,
                videoVisitApprovalEndpoint,
                videoVisitCalculationEndpoint,
                videoVisitQueryEndpoint,
                videoVisitEndpoint,
                videoVisitValidationEndpoint,
                videoVisitWorkflowEndpoint,
                visitNoteApprovalEndpoint,
                visitNoteCalculationEndpoint,
                visitNoteLifecycleEndpoint,
                visitNoteQueryEndpoint,
                visitNoteValidationEndpoint,
                visitNoteWorkflowEndpoint,
            ],
            workers: [
                { try await triageCalculationEndpoint.runFollowUps() },
                { try await triageValidationEndpoint.runFollowUps() },
                { try await videoVisitApprovalEndpoint.runFollowUps() },
                { try await videoVisitQueryEndpoint.runFollowUps() },
                { try await videoVisitValidationEndpoint.runFollowUps() },
                { try await visitNoteApprovalEndpoint.runFollowUps() },
                { try await visitNoteLifecycleEndpoint.runFollowUps() },
                { try await visitNoteValidationEndpoint.runFollowUps() },
            ]
        )
    }
}
