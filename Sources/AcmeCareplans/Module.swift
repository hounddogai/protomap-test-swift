import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Composes the careplans bounded context and exposes its services and background workers.
public enum CareplansModule {
    public static func make(dependencies: any Dependencies) -> ServiceModule {
        let careGoalApprovalEndpoint = CareGoalApprovalEndpoint(
            dependencies: dependencies,
            careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client(
                wrapping: dependencies.mesh),
            careplansCareGoalLifecycle: Acme_Careplans_V1_CareGoalLifecycleService.Client(wrapping: dependencies.mesh),
            careplansCarePlanApproval: Acme_Careplans_V1_CarePlanApprovalService.Client(wrapping: dependencies.mesh),
            careplansVitalValidation: Acme_Careplans_V1_VitalValidationService.Client(wrapping: dependencies.mesh),
            featureflagsFeatureFlagValidation: Acme_Featureflags_V1_FeatureFlagValidationService.Client(
                wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            notificationsNotificationQuery: Acme_Notifications_V1_NotificationQueryService.Client(
                wrapping: dependencies.mesh),
            patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client(
                wrapping: dependencies.mesh),
            patientsPatient: Acme_Patients_V1_PatientService.Client(wrapping: dependencies.mesh),
            prescriptionsMedicationCalculation: Acme_Prescriptions_V1_MedicationCalculationService.Client(
                wrapping: dependencies.mesh),
            promotionsPromotionCalculation: Acme_Promotions_V1_PromotionCalculationService.Client(
                wrapping: dependencies.mesh),
            telehealthTriageCalculation: Acme_Telehealth_V1_TriageCalculationService.Client(
                wrapping: dependencies.mesh),
            telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client(
                wrapping: dependencies.mesh),
            venuesVenue: Acme_Venues_V1_VenueService.Client(wrapping: dependencies.mesh)
        )
        let careGoalCalculationEndpoint = CareGoalCalculationEndpoint(
            dependencies: dependencies,
            careplansCarePlanCalculation: Acme_Careplans_V1_CarePlanCalculationService.Client(
                wrapping: dependencies.mesh),
            concessionsConcessionStandCalculation: Acme_Concessions_V1_ConcessionStandCalculationService.Client(
                wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            ledgerLedgerAccount: Acme_Ledger_V1_LedgerAccountService.Client(wrapping: dependencies.mesh),
            metricsMetricSeriesQuery: Acme_Metrics_V1_MetricSeriesQueryService.Client(wrapping: dependencies.mesh),
            metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client(
                wrapping: dependencies.mesh)
        )
        let careGoalLifecycleEndpoint = CareGoalLifecycleEndpoint(
            dependencies: dependencies,
            auditAuditEventQuery: Acme_Audit_V1_AuditEventQueryService.Client(wrapping: dependencies.mesh),
            careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client(
                wrapping: dependencies.mesh),
            careplansCarePlanCalculation: Acme_Careplans_V1_CarePlanCalculationService.Client(
                wrapping: dependencies.mesh),
            careplansVitalCalculation: Acme_Careplans_V1_VitalCalculationService.Client(wrapping: dependencies.mesh),
            careplansVitalReporting: Acme_Careplans_V1_VitalReportingService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            metricsMetricSeries: Acme_Metrics_V1_MetricSeriesService.Client(wrapping: dependencies.mesh),
            searchSearchIndex: Acme_Search_V1_SearchIndexService.Client(wrapping: dependencies.mesh),
            telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client(wrapping: dependencies.mesh),
            telehealthVisitNoteCalculation: Acme_Telehealth_V1_VisitNoteCalculationService.Client(
                wrapping: dependencies.mesh),
            telehealthVisitNoteQuery: Acme_Telehealth_V1_VisitNoteQueryService.Client(wrapping: dependencies.mesh)
        )
        let careGoalQueryEndpoint = CareGoalQueryEndpoint(
            dependencies: dependencies,
            careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client(
                wrapping: dependencies.mesh),
            careplansCareGoalValidation: Acme_Careplans_V1_CareGoalValidationService.Client(
                wrapping: dependencies.mesh),
            careplansCarePlanQuery: Acme_Careplans_V1_CarePlanQueryService.Client(wrapping: dependencies.mesh),
            careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client(
                wrapping: dependencies.mesh),
            careplansVitalCalculation: Acme_Careplans_V1_VitalCalculationService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh)
        )
        let careGoalValidationEndpoint = CareGoalValidationEndpoint(
            dependencies: dependencies,
            boxofficeBoxOfficeSale: Acme_Boxoffice_V1_BoxOfficeSaleService.Client(wrapping: dependencies.mesh),
            boxofficeBoxOfficeSaleQuery: Acme_Boxoffice_V1_BoxOfficeSaleQueryService.Client(
                wrapping: dependencies.mesh),
            careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client(
                wrapping: dependencies.mesh),
            careplansCarePlanCalculation: Acme_Careplans_V1_CarePlanCalculationService.Client(
                wrapping: dependencies.mesh),
            careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client(
                wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            ledgerLedgerAccountValidation: Acme_Ledger_V1_LedgerAccountValidationService.Client(
                wrapping: dependencies.mesh),
            metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client(
                wrapping: dependencies.mesh)
        )
        let careGoalWorkflowEndpoint = CareGoalWorkflowEndpoint(
            dependencies: dependencies,
            appointmentsAppointment: Acme_Appointments_V1_AppointmentService.Client(wrapping: dependencies.mesh),
            authorizationAccessPolicyValidation: Acme_Authorization_V1_AccessPolicyValidationService.Client(
                wrapping: dependencies.mesh),
            careplansCareGoalApproval: Acme_Careplans_V1_CareGoalApprovalService.Client(wrapping: dependencies.mesh),
            careplansCareGoalLifecycle: Acme_Careplans_V1_CareGoalLifecycleService.Client(wrapping: dependencies.mesh),
            careplansCarePlanApproval: Acme_Careplans_V1_CarePlanApprovalService.Client(wrapping: dependencies.mesh),
            careplansVitalCalculation: Acme_Careplans_V1_VitalCalculationService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            identityUserValidation: Acme_Identity_V1_UserValidationService.Client(wrapping: dependencies.mesh),
            ledgerLedgerAccountQuery: Acme_Ledger_V1_LedgerAccountQueryService.Client(wrapping: dependencies.mesh),
            lendingLoanApplicationCalculation: Acme_Lending_V1_LoanApplicationCalculationService.Client(
                wrapping: dependencies.mesh),
            metricsMetricSeries: Acme_Metrics_V1_MetricSeriesService.Client(wrapping: dependencies.mesh),
            notificationsNotificationValidation: Acme_Notifications_V1_NotificationValidationService.Client(
                wrapping: dependencies.mesh),
            patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client(
                wrapping: dependencies.mesh),
            prescriptionsPrescription: Acme_Prescriptions_V1_PrescriptionService.Client(wrapping: dependencies.mesh),
            searchSearchIndexQuery: Acme_Search_V1_SearchIndexQueryService.Client(wrapping: dependencies.mesh),
            telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client(wrapping: dependencies.mesh),
            telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client(
                wrapping: dependencies.mesh),
            venuesVenueQuery: Acme_Venues_V1_VenueQueryService.Client(wrapping: dependencies.mesh)
        )
        let carePlanApprovalEndpoint = CarePlanApprovalEndpoint(
            dependencies: dependencies,
            appointmentsProviderQuery: Acme_Appointments_V1_ProviderQueryService.Client(wrapping: dependencies.mesh),
            careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client(
                wrapping: dependencies.mesh),
            careplansCareGoalQuery: Acme_Careplans_V1_CareGoalQueryService.Client(wrapping: dependencies.mesh),
            careplansCareGoalValidation: Acme_Careplans_V1_CareGoalValidationService.Client(
                wrapping: dependencies.mesh),
            careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client(wrapping: dependencies.mesh),
            careplansCarePlanCalculation: Acme_Careplans_V1_CarePlanCalculationService.Client(
                wrapping: dependencies.mesh),
            careplansCarePlanLifecycle: Acme_Careplans_V1_CarePlanLifecycleService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client(
                wrapping: dependencies.mesh),
            patientsAllergyValidation: Acme_Patients_V1_AllergyValidationService.Client(wrapping: dependencies.mesh),
            prescriptionsPrescriptionValidation: Acme_Prescriptions_V1_PrescriptionValidationService.Client(
                wrapping: dependencies.mesh),
            shippingShipment: Acme_Shipping_V1_ShipmentService.Client(wrapping: dependencies.mesh),
            telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client(wrapping: dependencies.mesh),
            telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client(
                wrapping: dependencies.mesh),
            telehealthVisitNoteCalculation: Acme_Telehealth_V1_VisitNoteCalculationService.Client(
                wrapping: dependencies.mesh)
        )
        let carePlanCalculationEndpoint = CarePlanCalculationEndpoint(
            dependencies: dependencies,
            authorizationAccessPolicyValidation: Acme_Authorization_V1_AccessPolicyValidationService.Client(
                wrapping: dependencies.mesh),
            boxofficeBoxOfficeSaleCalculation: Acme_Boxoffice_V1_BoxOfficeSaleCalculationService.Client(
                wrapping: dependencies.mesh),
            broadcastsBroadcastQuery: Acme_Broadcasts_V1_BroadcastQueryService.Client(wrapping: dependencies.mesh),
            documentsDocumentValidation: Acme_Documents_V1_DocumentValidationService.Client(
                wrapping: dependencies.mesh),
            featureflagsFeatureFlagValidation: Acme_Featureflags_V1_FeatureFlagValidationService.Client(
                wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            identityUserQuery: Acme_Identity_V1_UserQueryService.Client(wrapping: dependencies.mesh),
            identityUserValidation: Acme_Identity_V1_UserValidationService.Client(wrapping: dependencies.mesh),
            ledgerLedgerAccountQuery: Acme_Ledger_V1_LedgerAccountQueryService.Client(wrapping: dependencies.mesh),
            metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client(
                wrapping: dependencies.mesh),
            notificationsNotificationQuery: Acme_Notifications_V1_NotificationQueryService.Client(
                wrapping: dependencies.mesh),
            notificationsNotificationValidation: Acme_Notifications_V1_NotificationValidationService.Client(
                wrapping: dependencies.mesh),
            showsShow: Acme_Shows_V1_ShowService.Client(wrapping: dependencies.mesh),
            showsShowCalculation: Acme_Shows_V1_ShowCalculationService.Client(wrapping: dependencies.mesh)
        )
        let carePlanLifecycleEndpoint = CarePlanLifecycleEndpoint(
            dependencies: dependencies,
            admissionsAdmissionCalculation: Acme_Admissions_V1_AdmissionCalculationService.Client(
                wrapping: dependencies.mesh),
            appointmentsAppointment: Acme_Appointments_V1_AppointmentService.Client(wrapping: dependencies.mesh),
            appointmentsProviderValidation: Acme_Appointments_V1_ProviderValidationService.Client(
                wrapping: dependencies.mesh),
            careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client(
                wrapping: dependencies.mesh),
            careplansCareGoalValidation: Acme_Careplans_V1_CareGoalValidationService.Client(
                wrapping: dependencies.mesh),
            careplansCarePlanCalculation: Acme_Careplans_V1_CarePlanCalculationService.Client(
                wrapping: dependencies.mesh),
            careplansCarePlanQuery: Acme_Careplans_V1_CarePlanQueryService.Client(wrapping: dependencies.mesh),
            careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client(
                wrapping: dependencies.mesh),
            careplansVitalCalculation: Acme_Careplans_V1_VitalCalculationService.Client(wrapping: dependencies.mesh),
            featureflagsFeatureFlagValidation: Acme_Featureflags_V1_FeatureFlagValidationService.Client(
                wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            ledgerLedgerAccountQuery: Acme_Ledger_V1_LedgerAccountQueryService.Client(wrapping: dependencies.mesh),
            patientsMedicalRecordQuery: Acme_Patients_V1_MedicalRecordQueryService.Client(wrapping: dependencies.mesh),
            patientsPatient: Acme_Patients_V1_PatientService.Client(wrapping: dependencies.mesh),
            prescriptionsPrescriptionQuery: Acme_Prescriptions_V1_PrescriptionQueryService.Client(
                wrapping: dependencies.mesh),
            recommendationsRecommendationSet: Acme_Recommendations_V1_RecommendationSetService.Client(
                wrapping: dependencies.mesh),
            telehealthVisitNoteValidation: Acme_Telehealth_V1_VisitNoteValidationService.Client(
                wrapping: dependencies.mesh)
        )
        let carePlanQueryEndpoint = CarePlanQueryEndpoint(
            dependencies: dependencies,
            careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client(
                wrapping: dependencies.mesh),
            careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client(
                wrapping: dependencies.mesh),
            careplansVitalCalculation: Acme_Careplans_V1_VitalCalculationService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            identityUserValidation: Acme_Identity_V1_UserValidationService.Client(wrapping: dependencies.mesh),
            notificationsNotification: Acme_Notifications_V1_NotificationService.Client(wrapping: dependencies.mesh),
            searchSearchIndexValidation: Acme_Search_V1_SearchIndexValidationService.Client(
                wrapping: dependencies.mesh),
            venuesVenueValidation: Acme_Venues_V1_VenueValidationService.Client(wrapping: dependencies.mesh)
        )
        let carePlanEndpoint = CarePlanEndpoint(
            dependencies: dependencies,
            admissionsAdmissionQuery: Acme_Admissions_V1_AdmissionQueryService.Client(wrapping: dependencies.mesh),
            authorizationAccessPolicy: Acme_Authorization_V1_AccessPolicyService.Client(wrapping: dependencies.mesh),
            authorizationAccessPolicyValidation: Acme_Authorization_V1_AccessPolicyValidationService.Client(
                wrapping: dependencies.mesh),
            careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client(
                wrapping: dependencies.mesh),
            careplansCarePlanCalculation: Acme_Careplans_V1_CarePlanCalculationService.Client(
                wrapping: dependencies.mesh),
            careplansCarePlanQuery: Acme_Careplans_V1_CarePlanQueryService.Client(wrapping: dependencies.mesh),
            careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client(
                wrapping: dependencies.mesh),
            careplansVitalCalculation: Acme_Careplans_V1_VitalCalculationService.Client(wrapping: dependencies.mesh),
            documentsDocumentQuery: Acme_Documents_V1_DocumentQueryService.Client(wrapping: dependencies.mesh),
            documentsDocumentValidation: Acme_Documents_V1_DocumentValidationService.Client(
                wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            ledgerLedgerAccountQuery: Acme_Ledger_V1_LedgerAccountQueryService.Client(wrapping: dependencies.mesh),
            sponsorshipsSponsorQuery: Acme_Sponsorships_V1_SponsorQueryService.Client(wrapping: dependencies.mesh)
        )
        let carePlanValidationEndpoint = CarePlanValidationEndpoint(
            dependencies: dependencies,
            boxofficeBoxOfficeSaleQuery: Acme_Boxoffice_V1_BoxOfficeSaleQueryService.Client(
                wrapping: dependencies.mesh),
            broadcastsBroadcastQuery: Acme_Broadcasts_V1_BroadcastQueryService.Client(wrapping: dependencies.mesh),
            careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client(
                wrapping: dependencies.mesh),
            careplansCarePlanCalculation: Acme_Careplans_V1_CarePlanCalculationService.Client(
                wrapping: dependencies.mesh),
            documentsDocumentQuery: Acme_Documents_V1_DocumentQueryService.Client(wrapping: dependencies.mesh),
            documentsDocumentValidation: Acme_Documents_V1_DocumentValidationService.Client(
                wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            identityUserQuery: Acme_Identity_V1_UserQueryService.Client(wrapping: dependencies.mesh),
            ledgerLedgerAccount: Acme_Ledger_V1_LedgerAccountService.Client(wrapping: dependencies.mesh),
            metricsMetricSeries: Acme_Metrics_V1_MetricSeriesService.Client(wrapping: dependencies.mesh)
        )
        let carePlanWorkflowEndpoint = CarePlanWorkflowEndpoint(
            dependencies: dependencies,
            appointmentsClinicSlotValidation: Acme_Appointments_V1_ClinicSlotValidationService.Client(
                wrapping: dependencies.mesh),
            appointmentsProviderValidation: Acme_Appointments_V1_ProviderValidationService.Client(
                wrapping: dependencies.mesh),
            auditAuditEvent: Acme_Audit_V1_AuditEventService.Client(wrapping: dependencies.mesh),
            careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client(
                wrapping: dependencies.mesh),
            careplansCareGoalQuery: Acme_Careplans_V1_CareGoalQueryService.Client(wrapping: dependencies.mesh),
            careplansCareGoalValidation: Acme_Careplans_V1_CareGoalValidationService.Client(
                wrapping: dependencies.mesh),
            careplansCarePlanQuery: Acme_Careplans_V1_CarePlanQueryService.Client(wrapping: dependencies.mesh),
            careplansVitalLifecycle: Acme_Careplans_V1_VitalLifecycleService.Client(wrapping: dependencies.mesh),
            documentsDocument: Acme_Documents_V1_DocumentService.Client(wrapping: dependencies.mesh),
            featureflagsFeatureFlagQuery: Acme_Featureflags_V1_FeatureFlagQueryService.Client(
                wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            patientsAllergyValidation: Acme_Patients_V1_AllergyValidationService.Client(wrapping: dependencies.mesh),
            patientsPatient: Acme_Patients_V1_PatientService.Client(wrapping: dependencies.mesh),
            prescriptionsPrescriptionCalculation: Acme_Prescriptions_V1_PrescriptionCalculationService.Client(
                wrapping: dependencies.mesh),
            telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client(
                wrapping: dependencies.mesh)
        )
        let vitalApprovalEndpoint = VitalApprovalEndpoint(
            dependencies: dependencies,
            appointmentsAppointment: Acme_Appointments_V1_AppointmentService.Client(wrapping: dependencies.mesh),
            careplansCareGoalApproval: Acme_Careplans_V1_CareGoalApprovalService.Client(wrapping: dependencies.mesh),
            careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client(
                wrapping: dependencies.mesh),
            careplansCarePlanApproval: Acme_Careplans_V1_CarePlanApprovalService.Client(wrapping: dependencies.mesh),
            careplansCarePlanCalculation: Acme_Careplans_V1_CarePlanCalculationService.Client(
                wrapping: dependencies.mesh),
            careplansCarePlanWorkflow: Acme_Careplans_V1_CarePlanWorkflowService.Client(wrapping: dependencies.mesh),
            careplansVitalCalculation: Acme_Careplans_V1_VitalCalculationService.Client(wrapping: dependencies.mesh),
            careplansVitalReporting: Acme_Careplans_V1_VitalReportingService.Client(wrapping: dependencies.mesh),
            featureflagsFeatureFlagQuery: Acme_Featureflags_V1_FeatureFlagQueryService.Client(
                wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client(
                wrapping: dependencies.mesh),
            notificationsNotification: Acme_Notifications_V1_NotificationService.Client(wrapping: dependencies.mesh),
            patientsPatientCalculation: Acme_Patients_V1_PatientCalculationService.Client(wrapping: dependencies.mesh),
            prescriptionsMedicationCalculation: Acme_Prescriptions_V1_MedicationCalculationService.Client(
                wrapping: dependencies.mesh),
            prescriptionsPrescription: Acme_Prescriptions_V1_PrescriptionService.Client(wrapping: dependencies.mesh),
            prescriptionsPrescriptionQuery: Acme_Prescriptions_V1_PrescriptionQueryService.Client(
                wrapping: dependencies.mesh),
            prescriptionsRefillCalculation: Acme_Prescriptions_V1_RefillCalculationService.Client(
                wrapping: dependencies.mesh),
            telematicsTelemetryReadingCalculation: Acme_Telematics_V1_TelemetryReadingCalculationService.Client(
                wrapping: dependencies.mesh)
        )
        let vitalCalculationEndpoint = VitalCalculationEndpoint(
            dependencies: dependencies,
            careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client(
                wrapping: dependencies.mesh),
            careplansCarePlanCalculation: Acme_Careplans_V1_CarePlanCalculationService.Client(
                wrapping: dependencies.mesh),
            careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client(
                wrapping: dependencies.mesh),
            documentsDocumentValidation: Acme_Documents_V1_DocumentValidationService.Client(
                wrapping: dependencies.mesh),
            featureflagsFeatureFlag: Acme_Featureflags_V1_FeatureFlagService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            searchSearchIndexQuery: Acme_Search_V1_SearchIndexQueryService.Client(wrapping: dependencies.mesh),
            seatingSeatMap: Acme_Seating_V1_SeatMapService.Client(wrapping: dependencies.mesh),
            sponsorshipsSponsor: Acme_Sponsorships_V1_SponsorService.Client(wrapping: dependencies.mesh),
            toursTour: Acme_Tours_V1_TourService.Client(wrapping: dependencies.mesh)
        )
        let vitalLifecycleEndpoint = VitalLifecycleEndpoint(
            dependencies: dependencies,
            appointmentsProviderQuery: Acme_Appointments_V1_ProviderQueryService.Client(wrapping: dependencies.mesh),
            auditAuditEventQuery: Acme_Audit_V1_AuditEventQueryService.Client(wrapping: dependencies.mesh),
            careplansCareGoalValidation: Acme_Careplans_V1_CareGoalValidationService.Client(
                wrapping: dependencies.mesh),
            careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client(wrapping: dependencies.mesh),
            careplansCarePlanQuery: Acme_Careplans_V1_CarePlanQueryService.Client(wrapping: dependencies.mesh),
            careplansVitalCalculation: Acme_Careplans_V1_VitalCalculationService.Client(wrapping: dependencies.mesh),
            careplansVitalReporting: Acme_Careplans_V1_VitalReportingService.Client(wrapping: dependencies.mesh),
            featureflagsFeatureFlagValidation: Acme_Featureflags_V1_FeatureFlagValidationService.Client(
                wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            identityUserQuery: Acme_Identity_V1_UserQueryService.Client(wrapping: dependencies.mesh),
            ledgerLedgerAccount: Acme_Ledger_V1_LedgerAccountService.Client(wrapping: dependencies.mesh),
            ledgerLedgerAccountValidation: Acme_Ledger_V1_LedgerAccountValidationService.Client(
                wrapping: dependencies.mesh),
            notificationsNotificationQuery: Acme_Notifications_V1_NotificationQueryService.Client(
                wrapping: dependencies.mesh),
            patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client(wrapping: dependencies.mesh),
            prescriptionsMedicationCalculation: Acme_Prescriptions_V1_MedicationCalculationService.Client(
                wrapping: dependencies.mesh),
            prescriptionsRefillValidation: Acme_Prescriptions_V1_RefillValidationService.Client(
                wrapping: dependencies.mesh),
            surveysSurvey: Acme_Surveys_V1_SurveyService.Client(wrapping: dependencies.mesh)
        )
        let vitalReportingEndpoint = VitalReportingEndpoint(
            dependencies: dependencies,
            appointmentsAppointment: Acme_Appointments_V1_AppointmentService.Client(wrapping: dependencies.mesh),
            appointmentsClinicSlotValidation: Acme_Appointments_V1_ClinicSlotValidationService.Client(
                wrapping: dependencies.mesh),
            careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client(
                wrapping: dependencies.mesh),
            careplansCarePlanCalculation: Acme_Careplans_V1_CarePlanCalculationService.Client(
                wrapping: dependencies.mesh),
            careplansCarePlanLifecycle: Acme_Careplans_V1_CarePlanLifecycleService.Client(wrapping: dependencies.mesh),
            careplansVitalCalculation: Acme_Careplans_V1_VitalCalculationService.Client(wrapping: dependencies.mesh),
            careplansVitalValidation: Acme_Careplans_V1_VitalValidationService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            ledgerLedgerAccount: Acme_Ledger_V1_LedgerAccountService.Client(wrapping: dependencies.mesh),
            notificationsNotification: Acme_Notifications_V1_NotificationService.Client(wrapping: dependencies.mesh),
            patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client(
                wrapping: dependencies.mesh),
            patientsPatient: Acme_Patients_V1_PatientService.Client(wrapping: dependencies.mesh),
            prescriptionsMedicationValidation: Acme_Prescriptions_V1_MedicationValidationService.Client(
                wrapping: dependencies.mesh),
            prescriptionsPrescriptionValidation: Acme_Prescriptions_V1_PrescriptionValidationService.Client(
                wrapping: dependencies.mesh),
            venuesVenueQuery: Acme_Venues_V1_VenueQueryService.Client(wrapping: dependencies.mesh)
        )
        let vitalValidationEndpoint = VitalValidationEndpoint(
            dependencies: dependencies,
            auditAuditEvent: Acme_Audit_V1_AuditEventService.Client(wrapping: dependencies.mesh),
            boxofficeBoxOfficeSaleCalculation: Acme_Boxoffice_V1_BoxOfficeSaleCalculationService.Client(
                wrapping: dependencies.mesh),
            careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client(
                wrapping: dependencies.mesh),
            careplansCareGoalValidation: Acme_Careplans_V1_CareGoalValidationService.Client(
                wrapping: dependencies.mesh),
            careplansCarePlanCalculation: Acme_Careplans_V1_CarePlanCalculationService.Client(
                wrapping: dependencies.mesh),
            careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client(
                wrapping: dependencies.mesh),
            featureflagsFeatureFlagValidation: Acme_Featureflags_V1_FeatureFlagValidationService.Client(
                wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            identityUserValidation: Acme_Identity_V1_UserValidationService.Client(wrapping: dependencies.mesh),
            notificationsNotification: Acme_Notifications_V1_NotificationService.Client(wrapping: dependencies.mesh),
            sponsorshipsSponsorCalculation: Acme_Sponsorships_V1_SponsorCalculationService.Client(
                wrapping: dependencies.mesh)
        )
        let vitalWorkflowEndpoint = VitalWorkflowEndpoint(
            dependencies: dependencies,
            budgetingBudgetQuery: Acme_Budgeting_V1_BudgetQueryService.Client(wrapping: dependencies.mesh),
            careplansCarePlanApproval: Acme_Careplans_V1_CarePlanApprovalService.Client(wrapping: dependencies.mesh),
            careplansCarePlanWorkflow: Acme_Careplans_V1_CarePlanWorkflowService.Client(wrapping: dependencies.mesh),
            careplansVitalCalculation: Acme_Careplans_V1_VitalCalculationService.Client(wrapping: dependencies.mesh),
            careplansVitalLifecycle: Acme_Careplans_V1_VitalLifecycleService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            identityUserQuery: Acme_Identity_V1_UserQueryService.Client(wrapping: dependencies.mesh),
            notificationsNotificationValidation: Acme_Notifications_V1_NotificationValidationService.Client(
                wrapping: dependencies.mesh),
            patientsPatientCalculation: Acme_Patients_V1_PatientCalculationService.Client(wrapping: dependencies.mesh),
            patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client(wrapping: dependencies.mesh),
            prescriptionsRefillCalculation: Acme_Prescriptions_V1_RefillCalculationService.Client(
                wrapping: dependencies.mesh),
            telehealthTriageCalculation: Acme_Telehealth_V1_TriageCalculationService.Client(
                wrapping: dependencies.mesh),
            telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client(wrapping: dependencies.mesh),
            telehealthVideoVisitValidation: Acme_Telehealth_V1_VideoVisitValidationService.Client(
                wrapping: dependencies.mesh)
        )
        return ServiceModule(
            services: [
                careGoalApprovalEndpoint,
                careGoalCalculationEndpoint,
                careGoalLifecycleEndpoint,
                careGoalQueryEndpoint,
                careGoalValidationEndpoint,
                careGoalWorkflowEndpoint,
                carePlanApprovalEndpoint,
                carePlanCalculationEndpoint,
                carePlanLifecycleEndpoint,
                carePlanQueryEndpoint,
                carePlanEndpoint,
                carePlanValidationEndpoint,
                carePlanWorkflowEndpoint,
                vitalApprovalEndpoint,
                vitalCalculationEndpoint,
                vitalLifecycleEndpoint,
                vitalReportingEndpoint,
                vitalValidationEndpoint,
                vitalWorkflowEndpoint,
            ],
            workers: [
                { try await careGoalCalculationEndpoint.runFollowUps() },
                { try await careGoalQueryEndpoint.runFollowUps() },
                { try await careGoalWorkflowEndpoint.runFollowUps() },
                { try await carePlanCalculationEndpoint.runFollowUps() },
                { try await carePlanQueryEndpoint.runFollowUps() },
                { try await carePlanValidationEndpoint.runFollowUps() },
                { try await vitalApprovalEndpoint.runFollowUps() },
                { try await vitalLifecycleEndpoint.runFollowUps() },
                { try await vitalValidationEndpoint.runFollowUps() },
            ]
        )
    }
}
