import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Composes the patients bounded context and exposes its services and background workers.
public enum PatientsModule {
    public static func make(dependencies: any Dependencies) -> ServiceModule {
        let allergyApprovalEndpoint = AllergyApprovalEndpoint(
            dependencies: dependencies,
            appointmentsAppointmentWorkflow: Acme_Appointments_V1_AppointmentWorkflowService.Client(
                wrapping: dependencies.mesh),
            authorizationAccessPolicyQuery: Acme_Authorization_V1_AccessPolicyQueryService.Client(
                wrapping: dependencies.mesh),
            careplansCareGoalWorkflow: Acme_Careplans_V1_CareGoalWorkflowService.Client(wrapping: dependencies.mesh),
            careplansVitalWorkflow: Acme_Careplans_V1_VitalWorkflowService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            patientsAllergyImport: Acme_Patients_V1_AllergyImportService.Client(wrapping: dependencies.mesh),
            patientsAllergyReporting: Acme_Patients_V1_AllergyReportingService.Client(wrapping: dependencies.mesh),
            patientsMedicalRecordApproval: Acme_Patients_V1_MedicalRecordApprovalService.Client(
                wrapping: dependencies.mesh),
            patientsMedicalRecordReporting: Acme_Patients_V1_MedicalRecordReportingService.Client(
                wrapping: dependencies.mesh),
            patientsMedicalRecordSync: Acme_Patients_V1_MedicalRecordSyncService.Client(wrapping: dependencies.mesh),
            patientsMedicalRecordValidation: Acme_Patients_V1_MedicalRecordValidationService.Client(
                wrapping: dependencies.mesh),
            patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client(wrapping: dependencies.mesh),
            patientsPatientWorkflow: Acme_Patients_V1_PatientWorkflowService.Client(wrapping: dependencies.mesh),
            pipelinesPipelineCalculation: Acme_Pipelines_V1_PipelineCalculationService.Client(
                wrapping: dependencies.mesh),
            prescriptionsPrescriptionSync: Acme_Prescriptions_V1_PrescriptionSyncService.Client(
                wrapping: dependencies.mesh),
            prescriptionsRefillSync: Acme_Prescriptions_V1_RefillSyncService.Client(wrapping: dependencies.mesh),
            venuesVenueQuery: Acme_Venues_V1_VenueQueryService.Client(wrapping: dependencies.mesh),
            venuesVenueValidation: Acme_Venues_V1_VenueValidationService.Client(wrapping: dependencies.mesh)
        )
        let allergyCalculationEndpoint = AllergyCalculationEndpoint(
            dependencies: dependencies,
            appointmentsClinicSlotValidation: Acme_Appointments_V1_ClinicSlotValidationService.Client(
                wrapping: dependencies.mesh),
            auditAuditEventValidation: Acme_Audit_V1_AuditEventValidationService.Client(wrapping: dependencies.mesh),
            documentsDocument: Acme_Documents_V1_DocumentService.Client(wrapping: dependencies.mesh),
            documentsDocumentValidation: Acme_Documents_V1_DocumentValidationService.Client(
                wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            metricsMetricSeriesQuery: Acme_Metrics_V1_MetricSeriesQueryService.Client(wrapping: dependencies.mesh),
            patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client(
                wrapping: dependencies.mesh),
            patientsPatientValidation: Acme_Patients_V1_PatientValidationService.Client(wrapping: dependencies.mesh),
            prescriptionsMedicationValidation: Acme_Prescriptions_V1_MedicationValidationService.Client(
                wrapping: dependencies.mesh),
            prescriptionsPrescriptionCalculation: Acme_Prescriptions_V1_PrescriptionCalculationService.Client(
                wrapping: dependencies.mesh),
            telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client(wrapping: dependencies.mesh)
        )
        let allergyImportEndpoint = AllergyImportEndpoint(
            dependencies: dependencies,
            careplansCareGoalApproval: Acme_Careplans_V1_CareGoalApprovalService.Client(wrapping: dependencies.mesh),
            careplansCareGoalWorkflow: Acme_Careplans_V1_CareGoalWorkflowService.Client(wrapping: dependencies.mesh),
            careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client(wrapping: dependencies.mesh),
            driversDriver: Acme_Drivers_V1_DriverService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            notificationsNotificationValidation: Acme_Notifications_V1_NotificationValidationService.Client(
                wrapping: dependencies.mesh),
            patientsAllergyCalculation: Acme_Patients_V1_AllergyCalculationService.Client(wrapping: dependencies.mesh),
            patientsAllergyValidation: Acme_Patients_V1_AllergyValidationService.Client(wrapping: dependencies.mesh),
            patientsPatient: Acme_Patients_V1_PatientService.Client(wrapping: dependencies.mesh),
            patientsPatientCalculation: Acme_Patients_V1_PatientCalculationService.Client(wrapping: dependencies.mesh),
            patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client(wrapping: dependencies.mesh),
            prescriptionsMedicationApproval: Acme_Prescriptions_V1_MedicationApprovalService.Client(
                wrapping: dependencies.mesh),
            prescriptionsRefillWorkflow: Acme_Prescriptions_V1_RefillWorkflowService.Client(
                wrapping: dependencies.mesh),
            sponsorshipsSponsorQuery: Acme_Sponsorships_V1_SponsorQueryService.Client(wrapping: dependencies.mesh),
            ticketingTicket: Acme_Ticketing_V1_TicketService.Client(wrapping: dependencies.mesh)
        )
        let allergyLifecycleEndpoint = AllergyLifecycleEndpoint(
            dependencies: dependencies,
            careplansCarePlanApproval: Acme_Careplans_V1_CarePlanApprovalService.Client(wrapping: dependencies.mesh),
            careplansCarePlanWorkflow: Acme_Careplans_V1_CarePlanWorkflowService.Client(wrapping: dependencies.mesh),
            documentsDocumentValidation: Acme_Documents_V1_DocumentValidationService.Client(
                wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            localizationTranslationKeyCalculation: Acme_Localization_V1_TranslationKeyCalculationService.Client(
                wrapping: dependencies.mesh),
            patientsAllergyImport: Acme_Patients_V1_AllergyImportService.Client(wrapping: dependencies.mesh),
            patientsMedicalRecordReporting: Acme_Patients_V1_MedicalRecordReportingService.Client(
                wrapping: dependencies.mesh),
            patientsMedicalRecordSync: Acme_Patients_V1_MedicalRecordSyncService.Client(wrapping: dependencies.mesh),
            patientsPatientCalculation: Acme_Patients_V1_PatientCalculationService.Client(wrapping: dependencies.mesh),
            patientsPatientSync: Acme_Patients_V1_PatientSyncService.Client(wrapping: dependencies.mesh),
            prescriptionsMedicationSync: Acme_Prescriptions_V1_MedicationSyncService.Client(
                wrapping: dependencies.mesh),
            telehealthVisitNoteApproval: Acme_Telehealth_V1_VisitNoteApprovalService.Client(wrapping: dependencies.mesh)
        )
        let allergyReportingEndpoint = AllergyReportingEndpoint(
            dependencies: dependencies,
            authorizationAccessPolicyValidation: Acme_Authorization_V1_AccessPolicyValidationService.Client(
                wrapping: dependencies.mesh),
            careplansVitalReporting: Acme_Careplans_V1_VitalReportingService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            identityUserValidation: Acme_Identity_V1_UserValidationService.Client(wrapping: dependencies.mesh),
            patientsAllergyImport: Acme_Patients_V1_AllergyImportService.Client(wrapping: dependencies.mesh),
            patientsAllergySync: Acme_Patients_V1_AllergySyncService.Client(wrapping: dependencies.mesh),
            patientsPatient: Acme_Patients_V1_PatientService.Client(wrapping: dependencies.mesh),
            patientsPatientCalculation: Acme_Patients_V1_PatientCalculationService.Client(wrapping: dependencies.mesh),
            patientsPatientLifecycle: Acme_Patients_V1_PatientLifecycleService.Client(wrapping: dependencies.mesh),
            patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client(wrapping: dependencies.mesh),
            prescriptionsPrescriptionSync: Acme_Prescriptions_V1_PrescriptionSyncService.Client(
                wrapping: dependencies.mesh),
            prescriptionsRefillImport: Acme_Prescriptions_V1_RefillImportService.Client(wrapping: dependencies.mesh),
            searchSearchIndex: Acme_Search_V1_SearchIndexService.Client(wrapping: dependencies.mesh),
            searchSearchIndexQuery: Acme_Search_V1_SearchIndexQueryService.Client(wrapping: dependencies.mesh)
        )
        let allergySyncEndpoint = AllergySyncEndpoint(
            dependencies: dependencies,
            careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client(wrapping: dependencies.mesh),
            careplansVitalWorkflow: Acme_Careplans_V1_VitalWorkflowService.Client(wrapping: dependencies.mesh),
            certificatesCertificate: Acme_Certificates_V1_CertificateService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            metricsMetricSeries: Acme_Metrics_V1_MetricSeriesService.Client(wrapping: dependencies.mesh),
            metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client(
                wrapping: dependencies.mesh),
            patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client(
                wrapping: dependencies.mesh),
            patientsMedicalRecordQuery: Acme_Patients_V1_MedicalRecordQueryService.Client(wrapping: dependencies.mesh),
            patientsPatientCalculation: Acme_Patients_V1_PatientCalculationService.Client(wrapping: dependencies.mesh),
            patientsPatientValidation: Acme_Patients_V1_PatientValidationService.Client(wrapping: dependencies.mesh),
            prescriptionsPrescriptionApproval: Acme_Prescriptions_V1_PrescriptionApprovalService.Client(
                wrapping: dependencies.mesh),
            prescriptionsRefillLifecycle: Acme_Prescriptions_V1_RefillLifecycleService.Client(
                wrapping: dependencies.mesh)
        )
        let allergyValidationEndpoint = AllergyValidationEndpoint(
            dependencies: dependencies,
            authorizationAccessPolicyValidation: Acme_Authorization_V1_AccessPolicyValidationService.Client(
                wrapping: dependencies.mesh),
            boxofficeBoxOfficeSaleCalculation: Acme_Boxoffice_V1_BoxOfficeSaleCalculationService.Client(
                wrapping: dependencies.mesh),
            documentsDocumentValidation: Acme_Documents_V1_DocumentValidationService.Client(
                wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client(
                wrapping: dependencies.mesh),
            patientsAllergyCalculation: Acme_Patients_V1_AllergyCalculationService.Client(wrapping: dependencies.mesh),
            patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client(
                wrapping: dependencies.mesh),
            patientsPatientValidation: Acme_Patients_V1_PatientValidationService.Client(wrapping: dependencies.mesh),
            prescriptionsMedicationValidation: Acme_Prescriptions_V1_MedicationValidationService.Client(
                wrapping: dependencies.mesh),
            prescriptionsPrescription: Acme_Prescriptions_V1_PrescriptionService.Client(wrapping: dependencies.mesh),
            sponsorshipsSponsorCalculation: Acme_Sponsorships_V1_SponsorCalculationService.Client(
                wrapping: dependencies.mesh)
        )
        let allergyWorkflowEndpoint = AllergyWorkflowEndpoint(
            dependencies: dependencies,
            auditAuditEventQuery: Acme_Audit_V1_AuditEventQueryService.Client(wrapping: dependencies.mesh),
            benefitsBenefitPlan: Acme_Benefits_V1_BenefitPlanService.Client(wrapping: dependencies.mesh),
            documentsDocumentValidation: Acme_Documents_V1_DocumentValidationService.Client(
                wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            notificationsNotificationQuery: Acme_Notifications_V1_NotificationQueryService.Client(
                wrapping: dependencies.mesh),
            patientsAllergyApproval: Acme_Patients_V1_AllergyApprovalService.Client(wrapping: dependencies.mesh),
            patientsAllergyCalculation: Acme_Patients_V1_AllergyCalculationService.Client(wrapping: dependencies.mesh),
            patientsAllergyImport: Acme_Patients_V1_AllergyImportService.Client(wrapping: dependencies.mesh),
            patientsAllergyReporting: Acme_Patients_V1_AllergyReportingService.Client(wrapping: dependencies.mesh),
            patientsMedicalRecordReporting: Acme_Patients_V1_MedicalRecordReportingService.Client(
                wrapping: dependencies.mesh),
            patientsPatientSync: Acme_Patients_V1_PatientSyncService.Client(wrapping: dependencies.mesh),
            prescriptionsPrescriptionSync: Acme_Prescriptions_V1_PrescriptionSyncService.Client(
                wrapping: dependencies.mesh),
            prescriptionsRefillSync: Acme_Prescriptions_V1_RefillSyncService.Client(wrapping: dependencies.mesh),
            telehealthVideoVisitWorkflow: Acme_Telehealth_V1_VideoVisitWorkflowService.Client(
                wrapping: dependencies.mesh)
        )
        let medicalRecordApprovalEndpoint = MedicalRecordApprovalEndpoint(
            dependencies: dependencies,
            appointmentsClinicSlotApproval: Acme_Appointments_V1_ClinicSlotApprovalService.Client(
                wrapping: dependencies.mesh),
            careplansVitalApproval: Acme_Careplans_V1_VitalApprovalService.Client(wrapping: dependencies.mesh),
            featureflagsFeatureFlag: Acme_Featureflags_V1_FeatureFlagService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            identityUserValidation: Acme_Identity_V1_UserValidationService.Client(wrapping: dependencies.mesh),
            ledgerLedgerAccountValidation: Acme_Ledger_V1_LedgerAccountValidationService.Client(
                wrapping: dependencies.mesh),
            metricsMetricSeriesQuery: Acme_Metrics_V1_MetricSeriesQueryService.Client(wrapping: dependencies.mesh),
            notificationsNotificationValidation: Acme_Notifications_V1_NotificationValidationService.Client(
                wrapping: dependencies.mesh),
            onboardingOnboardingPlanQuery: Acme_Onboarding_V1_OnboardingPlanQueryService.Client(
                wrapping: dependencies.mesh),
            patientsAllergyImport: Acme_Patients_V1_AllergyImportService.Client(wrapping: dependencies.mesh),
            patientsMedicalRecordLifecycle: Acme_Patients_V1_MedicalRecordLifecycleService.Client(
                wrapping: dependencies.mesh),
            patientsMedicalRecordReporting: Acme_Patients_V1_MedicalRecordReportingService.Client(
                wrapping: dependencies.mesh),
            patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client(wrapping: dependencies.mesh),
            patientsPatientSync: Acme_Patients_V1_PatientSyncService.Client(wrapping: dependencies.mesh),
            prescriptionsPrescription: Acme_Prescriptions_V1_PrescriptionService.Client(wrapping: dependencies.mesh),
            prescriptionsRefillReporting: Acme_Prescriptions_V1_RefillReportingService.Client(
                wrapping: dependencies.mesh),
            toursTourQuery: Acme_Tours_V1_TourQueryService.Client(wrapping: dependencies.mesh)
        )
        let medicalRecordCalculationEndpoint = MedicalRecordCalculationEndpoint(
            dependencies: dependencies,
            documentsDocumentValidation: Acme_Documents_V1_DocumentValidationService.Client(
                wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            ledgerLedgerAccount: Acme_Ledger_V1_LedgerAccountService.Client(wrapping: dependencies.mesh),
            patientsPatientCalculation: Acme_Patients_V1_PatientCalculationService.Client(wrapping: dependencies.mesh),
            prescriptionsPrescription: Acme_Prescriptions_V1_PrescriptionService.Client(wrapping: dependencies.mesh),
            prescriptionsPrescriptionQuery: Acme_Prescriptions_V1_PrescriptionQueryService.Client(
                wrapping: dependencies.mesh),
            prescriptionsRefillCalculation: Acme_Prescriptions_V1_RefillCalculationService.Client(
                wrapping: dependencies.mesh),
            telehealthVisitNoteQuery: Acme_Telehealth_V1_VisitNoteQueryService.Client(wrapping: dependencies.mesh),
            venuesVenue: Acme_Venues_V1_VenueService.Client(wrapping: dependencies.mesh)
        )
        let medicalRecordLifecycleEndpoint = MedicalRecordLifecycleEndpoint(
            dependencies: dependencies,
            careplansCarePlanWorkflow: Acme_Careplans_V1_CarePlanWorkflowService.Client(wrapping: dependencies.mesh),
            documentsDocumentValidation: Acme_Documents_V1_DocumentValidationService.Client(
                wrapping: dependencies.mesh),
            featureflagsFeatureFlagValidation: Acme_Featureflags_V1_FeatureFlagValidationService.Client(
                wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            metricsMetricSeriesQuery: Acme_Metrics_V1_MetricSeriesQueryService.Client(wrapping: dependencies.mesh),
            patientsAllergySync: Acme_Patients_V1_AllergySyncService.Client(wrapping: dependencies.mesh),
            patientsMedicalRecordReporting: Acme_Patients_V1_MedicalRecordReportingService.Client(
                wrapping: dependencies.mesh),
            patientsPatient: Acme_Patients_V1_PatientService.Client(wrapping: dependencies.mesh),
            prescriptionsMedicationReporting: Acme_Prescriptions_V1_MedicationReportingService.Client(
                wrapping: dependencies.mesh),
            prescriptionsRefillReporting: Acme_Prescriptions_V1_RefillReportingService.Client(
                wrapping: dependencies.mesh)
        )
        let medicalRecordQueryEndpoint = MedicalRecordQueryEndpoint(
            dependencies: dependencies,
            appointmentsAppointmentValidation: Acme_Appointments_V1_AppointmentValidationService.Client(
                wrapping: dependencies.mesh),
            careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client(wrapping: dependencies.mesh),
            documentsDocument: Acme_Documents_V1_DocumentService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client(
                wrapping: dependencies.mesh),
            patientsAllergyCalculation: Acme_Patients_V1_AllergyCalculationService.Client(wrapping: dependencies.mesh),
            patientsAllergyValidation: Acme_Patients_V1_AllergyValidationService.Client(wrapping: dependencies.mesh),
            patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client(
                wrapping: dependencies.mesh),
            patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client(wrapping: dependencies.mesh),
            patientsPatientValidation: Acme_Patients_V1_PatientValidationService.Client(wrapping: dependencies.mesh),
            prescriptionsPrescriptionValidation: Acme_Prescriptions_V1_PrescriptionValidationService.Client(
                wrapping: dependencies.mesh),
            telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client(
                wrapping: dependencies.mesh)
        )
        let medicalRecordReportingEndpoint = MedicalRecordReportingEndpoint(
            dependencies: dependencies,
            catalogProductCalculation: Acme_Catalog_V1_ProductCalculationService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            keymanagementCryptoKeyCalculation: Acme_Keymanagement_V1_CryptoKeyCalculationService.Client(
                wrapping: dependencies.mesh),
            metricsMetricSeries: Acme_Metrics_V1_MetricSeriesService.Client(wrapping: dependencies.mesh),
            notificationsNotification: Acme_Notifications_V1_NotificationService.Client(wrapping: dependencies.mesh),
            notificationsNotificationValidation: Acme_Notifications_V1_NotificationValidationService.Client(
                wrapping: dependencies.mesh),
            patientsAllergyImport: Acme_Patients_V1_AllergyImportService.Client(wrapping: dependencies.mesh),
            patientsAllergySync: Acme_Patients_V1_AllergySyncService.Client(wrapping: dependencies.mesh),
            patientsMedicalRecordSync: Acme_Patients_V1_MedicalRecordSyncService.Client(wrapping: dependencies.mesh),
            patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client(wrapping: dependencies.mesh),
            prescriptionsPrescriptionSync: Acme_Prescriptions_V1_PrescriptionSyncService.Client(
                wrapping: dependencies.mesh),
            prescriptionsRefillWorkflow: Acme_Prescriptions_V1_RefillWorkflowService.Client(
                wrapping: dependencies.mesh),
            searchSearchIndexQuery: Acme_Search_V1_SearchIndexQueryService.Client(wrapping: dependencies.mesh),
            telehealthVisitNoteLifecycle: Acme_Telehealth_V1_VisitNoteLifecycleService.Client(
                wrapping: dependencies.mesh)
        )
        let medicalRecordSyncEndpoint = MedicalRecordSyncEndpoint(
            dependencies: dependencies,
            careplansVitalApproval: Acme_Careplans_V1_VitalApprovalService.Client(wrapping: dependencies.mesh),
            careplansVitalWorkflow: Acme_Careplans_V1_VitalWorkflowService.Client(wrapping: dependencies.mesh),
            documentsDocumentQuery: Acme_Documents_V1_DocumentQueryService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            patientsAllergyCalculation: Acme_Patients_V1_AllergyCalculationService.Client(wrapping: dependencies.mesh),
            patientsAllergyValidation: Acme_Patients_V1_AllergyValidationService.Client(wrapping: dependencies.mesh),
            patientsMedicalRecordValidation: Acme_Patients_V1_MedicalRecordValidationService.Client(
                wrapping: dependencies.mesh),
            patientsPatient: Acme_Patients_V1_PatientService.Client(wrapping: dependencies.mesh),
            patientsPatientValidation: Acme_Patients_V1_PatientValidationService.Client(wrapping: dependencies.mesh),
            prescriptionsMedicationSync: Acme_Prescriptions_V1_MedicationSyncService.Client(
                wrapping: dependencies.mesh),
            prescriptionsPrescriptionApproval: Acme_Prescriptions_V1_PrescriptionApprovalService.Client(
                wrapping: dependencies.mesh),
            toursTourQuery: Acme_Tours_V1_TourQueryService.Client(wrapping: dependencies.mesh),
            venuesVenueValidation: Acme_Venues_V1_VenueValidationService.Client(wrapping: dependencies.mesh)
        )
        let medicalRecordValidationEndpoint = MedicalRecordValidationEndpoint(
            dependencies: dependencies,
            appointmentsAppointmentQuery: Acme_Appointments_V1_AppointmentQueryService.Client(
                wrapping: dependencies.mesh),
            appointmentsAppointmentValidation: Acme_Appointments_V1_AppointmentValidationService.Client(
                wrapping: dependencies.mesh),
            careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            notificationsNotification: Acme_Notifications_V1_NotificationService.Client(wrapping: dependencies.mesh),
            notificationsNotificationQuery: Acme_Notifications_V1_NotificationQueryService.Client(
                wrapping: dependencies.mesh),
            patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client(
                wrapping: dependencies.mesh),
            patientsPatientCalculation: Acme_Patients_V1_PatientCalculationService.Client(wrapping: dependencies.mesh),
            patientsPatientValidation: Acme_Patients_V1_PatientValidationService.Client(wrapping: dependencies.mesh),
            prescriptionsMedicationCalculation: Acme_Prescriptions_V1_MedicationCalculationService.Client(
                wrapping: dependencies.mesh),
            ticketingTicket: Acme_Ticketing_V1_TicketService.Client(wrapping: dependencies.mesh)
        )
        let medicalRecordWorkflowEndpoint = MedicalRecordWorkflowEndpoint(
            dependencies: dependencies,
            appointmentsProviderApproval: Acme_Appointments_V1_ProviderApprovalService.Client(
                wrapping: dependencies.mesh),
            careplansVitalReporting: Acme_Careplans_V1_VitalReportingService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client(
                wrapping: dependencies.mesh),
            patientsAllergyApproval: Acme_Patients_V1_AllergyApprovalService.Client(wrapping: dependencies.mesh),
            patientsAllergyReporting: Acme_Patients_V1_AllergyReportingService.Client(wrapping: dependencies.mesh),
            patientsAllergySync: Acme_Patients_V1_AllergySyncService.Client(wrapping: dependencies.mesh),
            patientsMedicalRecordApproval: Acme_Patients_V1_MedicalRecordApprovalService.Client(
                wrapping: dependencies.mesh),
            patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client(
                wrapping: dependencies.mesh),
            patientsMedicalRecordReporting: Acme_Patients_V1_MedicalRecordReportingService.Client(
                wrapping: dependencies.mesh),
            patientsMedicalRecordSync: Acme_Patients_V1_MedicalRecordSyncService.Client(wrapping: dependencies.mesh),
            patientsPatientApproval: Acme_Patients_V1_PatientApprovalService.Client(wrapping: dependencies.mesh),
            patientsPatientReporting: Acme_Patients_V1_PatientReportingService.Client(wrapping: dependencies.mesh),
            patientsPatientSync: Acme_Patients_V1_PatientSyncService.Client(wrapping: dependencies.mesh),
            patientsPatientWorkflow: Acme_Patients_V1_PatientWorkflowService.Client(wrapping: dependencies.mesh),
            performanceReviewQuery: Acme_Performance_V1_ReviewQueryService.Client(wrapping: dependencies.mesh),
            prescriptionsMedicationSync: Acme_Prescriptions_V1_MedicationSyncService.Client(
                wrapping: dependencies.mesh),
            searchSearchIndexQuery: Acme_Search_V1_SearchIndexQueryService.Client(wrapping: dependencies.mesh),
            venuesVenueQuery: Acme_Venues_V1_VenueQueryService.Client(wrapping: dependencies.mesh)
        )
        let patientApprovalEndpoint = PatientApprovalEndpoint(
            dependencies: dependencies,
            appointmentsAppointmentApproval: Acme_Appointments_V1_AppointmentApprovalService.Client(
                wrapping: dependencies.mesh),
            authorizationAccessPolicyValidation: Acme_Authorization_V1_AccessPolicyValidationService.Client(
                wrapping: dependencies.mesh),
            careplansCareGoalApproval: Acme_Careplans_V1_CareGoalApprovalService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            itsmIncidentCalculation: Acme_Itsm_V1_IncidentCalculationService.Client(wrapping: dependencies.mesh),
            patientsAllergyCalculation: Acme_Patients_V1_AllergyCalculationService.Client(wrapping: dependencies.mesh),
            patientsAllergySync: Acme_Patients_V1_AllergySyncService.Client(wrapping: dependencies.mesh),
            patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client(
                wrapping: dependencies.mesh),
            patientsMedicalRecordQuery: Acme_Patients_V1_MedicalRecordQueryService.Client(wrapping: dependencies.mesh),
            patientsMedicalRecordSync: Acme_Patients_V1_MedicalRecordSyncService.Client(wrapping: dependencies.mesh),
            patientsPatientReporting: Acme_Patients_V1_PatientReportingService.Client(wrapping: dependencies.mesh),
            patientsPatientSync: Acme_Patients_V1_PatientSyncService.Client(wrapping: dependencies.mesh),
            prescriptionsRefillApproval: Acme_Prescriptions_V1_RefillApprovalService.Client(
                wrapping: dependencies.mesh),
            searchSearchIndexValidation: Acme_Search_V1_SearchIndexValidationService.Client(wrapping: dependencies.mesh)
        )
        let patientCalculationEndpoint = PatientCalculationEndpoint(
            dependencies: dependencies,
            appointmentsAppointmentValidation: Acme_Appointments_V1_AppointmentValidationService.Client(
                wrapping: dependencies.mesh),
            authorizationAccessPolicyValidation: Acme_Authorization_V1_AccessPolicyValidationService.Client(
                wrapping: dependencies.mesh),
            careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client(wrapping: dependencies.mesh),
            careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client(
                wrapping: dependencies.mesh),
            careplansVitalCalculation: Acme_Careplans_V1_VitalCalculationService.Client(wrapping: dependencies.mesh),
            concessionsConcessionStandQuery: Acme_Concessions_V1_ConcessionStandQueryService.Client(
                wrapping: dependencies.mesh),
            documentsDocumentValidation: Acme_Documents_V1_DocumentValidationService.Client(
                wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            metricsMetricSeries: Acme_Metrics_V1_MetricSeriesService.Client(wrapping: dependencies.mesh),
            telehealthTriageCalculation: Acme_Telehealth_V1_TriageCalculationService.Client(
                wrapping: dependencies.mesh),
            venuesVenueValidation: Acme_Venues_V1_VenueValidationService.Client(wrapping: dependencies.mesh)
        )
        let patientLifecycleEndpoint = PatientLifecycleEndpoint(
            dependencies: dependencies,
            budgetingBudgetQuery: Acme_Budgeting_V1_BudgetQueryService.Client(wrapping: dependencies.mesh),
            careplansVitalApproval: Acme_Careplans_V1_VitalApprovalService.Client(wrapping: dependencies.mesh),
            featureflagsFeatureFlagQuery: Acme_Featureflags_V1_FeatureFlagQueryService.Client(
                wrapping: dependencies.mesh),
            featureflagsFeatureFlagValidation: Acme_Featureflags_V1_FeatureFlagValidationService.Client(
                wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client(
                wrapping: dependencies.mesh),
            patientsAllergyImport: Acme_Patients_V1_AllergyImportService.Client(wrapping: dependencies.mesh),
            patientsAllergySync: Acme_Patients_V1_AllergySyncService.Client(wrapping: dependencies.mesh),
            patientsMedicalRecordSync: Acme_Patients_V1_MedicalRecordSyncService.Client(wrapping: dependencies.mesh),
            patientsMedicalRecordValidation: Acme_Patients_V1_MedicalRecordValidationService.Client(
                wrapping: dependencies.mesh),
            patientsPatientReporting: Acme_Patients_V1_PatientReportingService.Client(wrapping: dependencies.mesh),
            patientsPatientSync: Acme_Patients_V1_PatientSyncService.Client(wrapping: dependencies.mesh),
            patientsPatientValidation: Acme_Patients_V1_PatientValidationService.Client(wrapping: dependencies.mesh),
            searchSearchIndexQuery: Acme_Search_V1_SearchIndexQueryService.Client(wrapping: dependencies.mesh)
        )
        let patientQueryEndpoint = PatientQueryEndpoint(
            dependencies: dependencies,
            auditAuditEventValidation: Acme_Audit_V1_AuditEventValidationService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            ledgerLedgerAccount: Acme_Ledger_V1_LedgerAccountService.Client(wrapping: dependencies.mesh),
            notificationsNotification: Acme_Notifications_V1_NotificationService.Client(wrapping: dependencies.mesh),
            notificationsNotificationValidation: Acme_Notifications_V1_NotificationValidationService.Client(
                wrapping: dependencies.mesh),
            patientsAllergyCalculation: Acme_Patients_V1_AllergyCalculationService.Client(wrapping: dependencies.mesh),
            prescriptionsRefillValidation: Acme_Prescriptions_V1_RefillValidationService.Client(
                wrapping: dependencies.mesh),
            telehealthTriageCalculation: Acme_Telehealth_V1_TriageCalculationService.Client(
                wrapping: dependencies.mesh),
            telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client(wrapping: dependencies.mesh)
        )
        let patientReportingEndpoint = PatientReportingEndpoint(
            dependencies: dependencies,
            accountingChartOfAccounts: Acme_Accounting_V1_ChartOfAccountsService.Client(wrapping: dependencies.mesh),
            auditAuditEventValidation: Acme_Audit_V1_AuditEventValidationService.Client(wrapping: dependencies.mesh),
            careplansCareGoalWorkflow: Acme_Careplans_V1_CareGoalWorkflowService.Client(wrapping: dependencies.mesh),
            contentArticleQuery: Acme_Content_V1_ArticleQueryService.Client(wrapping: dependencies.mesh),
            documentsDocumentQuery: Acme_Documents_V1_DocumentQueryService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            patientsAllergyImport: Acme_Patients_V1_AllergyImportService.Client(wrapping: dependencies.mesh),
            patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client(
                wrapping: dependencies.mesh),
            patientsMedicalRecordSync: Acme_Patients_V1_MedicalRecordSyncService.Client(wrapping: dependencies.mesh),
            patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client(wrapping: dependencies.mesh),
            patientsPatientSync: Acme_Patients_V1_PatientSyncService.Client(wrapping: dependencies.mesh),
            patientsPatientValidation: Acme_Patients_V1_PatientValidationService.Client(wrapping: dependencies.mesh),
            prescriptionsPrescription: Acme_Prescriptions_V1_PrescriptionService.Client(wrapping: dependencies.mesh),
            prescriptionsRefillApproval: Acme_Prescriptions_V1_RefillApprovalService.Client(
                wrapping: dependencies.mesh),
            telehealthVideoVisitWorkflow: Acme_Telehealth_V1_VideoVisitWorkflowService.Client(
                wrapping: dependencies.mesh)
        )
        let patientEndpoint = PatientEndpoint(
            dependencies: dependencies,
            appointmentsAppointmentQuery: Acme_Appointments_V1_AppointmentQueryService.Client(
                wrapping: dependencies.mesh),
            appointmentsProviderValidation: Acme_Appointments_V1_ProviderValidationService.Client(
                wrapping: dependencies.mesh),
            authorizationAccessPolicyQuery: Acme_Authorization_V1_AccessPolicyQueryService.Client(
                wrapping: dependencies.mesh),
            careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client(
                wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client(
                wrapping: dependencies.mesh),
            patientsMedicalRecordValidation: Acme_Patients_V1_MedicalRecordValidationService.Client(
                wrapping: dependencies.mesh),
            patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client(wrapping: dependencies.mesh),
            patientsPatientValidation: Acme_Patients_V1_PatientValidationService.Client(wrapping: dependencies.mesh),
            prescriptionsMedicationValidation: Acme_Prescriptions_V1_MedicationValidationService.Client(
                wrapping: dependencies.mesh),
            prescriptionsPrescription: Acme_Prescriptions_V1_PrescriptionService.Client(wrapping: dependencies.mesh),
            searchSearchIndexQuery: Acme_Search_V1_SearchIndexQueryService.Client(wrapping: dependencies.mesh),
            telehealthTriageCalculation: Acme_Telehealth_V1_TriageCalculationService.Client(wrapping: dependencies.mesh)
        )
        let patientSyncEndpoint = PatientSyncEndpoint(
            dependencies: dependencies,
            appointmentsClinicSlotApproval: Acme_Appointments_V1_ClinicSlotApprovalService.Client(
                wrapping: dependencies.mesh),
            careplansVitalWorkflow: Acme_Careplans_V1_VitalWorkflowService.Client(wrapping: dependencies.mesh),
            documentsDocument: Acme_Documents_V1_DocumentService.Client(wrapping: dependencies.mesh),
            featureflagsFeatureFlagValidation: Acme_Featureflags_V1_FeatureFlagValidationService.Client(
                wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            notificationsNotification: Acme_Notifications_V1_NotificationService.Client(wrapping: dependencies.mesh),
            patientsAllergyValidation: Acme_Patients_V1_AllergyValidationService.Client(wrapping: dependencies.mesh),
            patientsMedicalRecordQuery: Acme_Patients_V1_MedicalRecordQueryService.Client(wrapping: dependencies.mesh),
            patientsMedicalRecordValidation: Acme_Patients_V1_MedicalRecordValidationService.Client(
                wrapping: dependencies.mesh),
            paymentsPaymentCalculation: Acme_Payments_V1_PaymentCalculationService.Client(wrapping: dependencies.mesh),
            prescriptionsMedicationReporting: Acme_Prescriptions_V1_MedicationReportingService.Client(
                wrapping: dependencies.mesh),
            prescriptionsPrescriptionSync: Acme_Prescriptions_V1_PrescriptionSyncService.Client(
                wrapping: dependencies.mesh),
            prescriptionsPrescriptionWorkflow: Acme_Prescriptions_V1_PrescriptionWorkflowService.Client(
                wrapping: dependencies.mesh),
            prescriptionsRefillApproval: Acme_Prescriptions_V1_RefillApprovalService.Client(
                wrapping: dependencies.mesh),
            prescriptionsRefillReporting: Acme_Prescriptions_V1_RefillReportingService.Client(
                wrapping: dependencies.mesh),
            treasuryCashPosition: Acme_Treasury_V1_CashPositionService.Client(wrapping: dependencies.mesh),
            venuesVenueValidation: Acme_Venues_V1_VenueValidationService.Client(wrapping: dependencies.mesh)
        )
        let patientValidationEndpoint = PatientValidationEndpoint(
            dependencies: dependencies,
            appointmentsAppointment: Acme_Appointments_V1_AppointmentService.Client(wrapping: dependencies.mesh),
            careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client(wrapping: dependencies.mesh),
            careplansCarePlanCalculation: Acme_Careplans_V1_CarePlanCalculationService.Client(
                wrapping: dependencies.mesh),
            documentsDocument: Acme_Documents_V1_DocumentService.Client(wrapping: dependencies.mesh),
            featureflagsFeatureFlag: Acme_Featureflags_V1_FeatureFlagService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            ledgerLedgerAccount: Acme_Ledger_V1_LedgerAccountService.Client(wrapping: dependencies.mesh),
            patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client(
                wrapping: dependencies.mesh),
            patientsPatientCalculation: Acme_Patients_V1_PatientCalculationService.Client(wrapping: dependencies.mesh),
            prescriptionsMedicationQuery: Acme_Prescriptions_V1_MedicationQueryService.Client(
                wrapping: dependencies.mesh),
            prescriptionsMedicationValidation: Acme_Prescriptions_V1_MedicationValidationService.Client(
                wrapping: dependencies.mesh),
            telehealthTriageCalculation: Acme_Telehealth_V1_TriageCalculationService.Client(wrapping: dependencies.mesh)
        )
        let patientWorkflowEndpoint = PatientWorkflowEndpoint(
            dependencies: dependencies,
            authorizationAccessPolicy: Acme_Authorization_V1_AccessPolicyService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            ledgerLedgerAccountQuery: Acme_Ledger_V1_LedgerAccountQueryService.Client(wrapping: dependencies.mesh),
            patientsMedicalRecordApproval: Acme_Patients_V1_MedicalRecordApprovalService.Client(
                wrapping: dependencies.mesh),
            patientsPatientReporting: Acme_Patients_V1_PatientReportingService.Client(wrapping: dependencies.mesh),
            prescriptionsPrescriptionApproval: Acme_Prescriptions_V1_PrescriptionApprovalService.Client(
                wrapping: dependencies.mesh),
            prescriptionsPrescriptionSync: Acme_Prescriptions_V1_PrescriptionSyncService.Client(
                wrapping: dependencies.mesh),
            prescriptionsRefillApproval: Acme_Prescriptions_V1_RefillApprovalService.Client(
                wrapping: dependencies.mesh),
            searchSearchIndexQuery: Acme_Search_V1_SearchIndexQueryService.Client(wrapping: dependencies.mesh),
            venuesVenueValidation: Acme_Venues_V1_VenueValidationService.Client(wrapping: dependencies.mesh)
        )
        return ServiceModule(
            services: [
                allergyApprovalEndpoint,
                allergyCalculationEndpoint,
                allergyImportEndpoint,
                allergyLifecycleEndpoint,
                allergyReportingEndpoint,
                allergySyncEndpoint,
                allergyValidationEndpoint,
                allergyWorkflowEndpoint,
                medicalRecordApprovalEndpoint,
                medicalRecordCalculationEndpoint,
                medicalRecordLifecycleEndpoint,
                medicalRecordQueryEndpoint,
                medicalRecordReportingEndpoint,
                medicalRecordSyncEndpoint,
                medicalRecordValidationEndpoint,
                medicalRecordWorkflowEndpoint,
                patientApprovalEndpoint,
                patientCalculationEndpoint,
                patientLifecycleEndpoint,
                patientQueryEndpoint,
                patientReportingEndpoint,
                patientEndpoint,
                patientSyncEndpoint,
                patientValidationEndpoint,
                patientWorkflowEndpoint,
            ],
            workers: [
                { try await allergyCalculationEndpoint.runFollowUps() },
                { try await allergyLifecycleEndpoint.runFollowUps() },
                { try await allergySyncEndpoint.runFollowUps() },
                { try await allergyWorkflowEndpoint.runFollowUps() },
                { try await medicalRecordCalculationEndpoint.runFollowUps() },
                { try await medicalRecordQueryEndpoint.runFollowUps() },
                { try await medicalRecordSyncEndpoint.runFollowUps() },
                { try await medicalRecordWorkflowEndpoint.runFollowUps() },
                { try await patientCalculationEndpoint.runFollowUps() },
                { try await patientQueryEndpoint.runFollowUps() },
                { try await patientEndpoint.runFollowUps() },
                { try await patientValidationEndpoint.runFollowUps() },
            ]
        )
    }
}
