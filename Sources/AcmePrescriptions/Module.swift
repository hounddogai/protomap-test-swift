import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Composes the prescriptions bounded context and exposes its services and background workers.
public enum PrescriptionsModule {
    public static func make(dependencies: any Dependencies) -> ServiceModule {
        let medicationApprovalEndpoint = MedicationApprovalEndpoint(
            dependencies: dependencies,
            careplansCarePlanWorkflow: Acme_Careplans_V1_CarePlanWorkflowService.Client(wrapping: dependencies.mesh),
            careplansVitalApproval: Acme_Careplans_V1_VitalApprovalService.Client(wrapping: dependencies.mesh),
            careplansVitalWorkflow: Acme_Careplans_V1_VitalWorkflowService.Client(wrapping: dependencies.mesh),
            featureflagsFeatureFlagValidation: Acme_Featureflags_V1_FeatureFlagValidationService.Client(
                wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            patientsAllergyCalculation: Acme_Patients_V1_AllergyCalculationService.Client(wrapping: dependencies.mesh),
            patientsMedicalRecordQuery: Acme_Patients_V1_MedicalRecordQueryService.Client(wrapping: dependencies.mesh),
            patientsMedicalRecordValidation: Acme_Patients_V1_MedicalRecordValidationService.Client(
                wrapping: dependencies.mesh),
            patientsPatientCalculation: Acme_Patients_V1_PatientCalculationService.Client(wrapping: dependencies.mesh),
            patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client(wrapping: dependencies.mesh),
            prescriptionsMedicationCalculation: Acme_Prescriptions_V1_MedicationCalculationService.Client(
                wrapping: dependencies.mesh),
            prescriptionsMedicationLifecycle: Acme_Prescriptions_V1_MedicationLifecycleService.Client(
                wrapping: dependencies.mesh),
            prescriptionsMedicationSync: Acme_Prescriptions_V1_MedicationSyncService.Client(
                wrapping: dependencies.mesh),
            prescriptionsPrescriptionCalculation: Acme_Prescriptions_V1_PrescriptionCalculationService.Client(
                wrapping: dependencies.mesh),
            prescriptionsRefillSync: Acme_Prescriptions_V1_RefillSyncService.Client(wrapping: dependencies.mesh),
            telehealthTriageApproval: Acme_Telehealth_V1_TriageApprovalService.Client(wrapping: dependencies.mesh),
            venuesVenueQuery: Acme_Venues_V1_VenueQueryService.Client(wrapping: dependencies.mesh)
        )
        let medicationCalculationEndpoint = MedicationCalculationEndpoint(
            dependencies: dependencies,
            boxofficeBoxOfficeSale: Acme_Boxoffice_V1_BoxOfficeSaleService.Client(wrapping: dependencies.mesh),
            careplansCarePlanQuery: Acme_Careplans_V1_CarePlanQueryService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            identityUserValidation: Acme_Identity_V1_UserValidationService.Client(wrapping: dependencies.mesh),
            metricsMetricSeriesQuery: Acme_Metrics_V1_MetricSeriesQueryService.Client(wrapping: dependencies.mesh),
            prescriptionsPrescriptionCalculation: Acme_Prescriptions_V1_PrescriptionCalculationService.Client(
                wrapping: dependencies.mesh),
            searchSearchIndex: Acme_Search_V1_SearchIndexService.Client(wrapping: dependencies.mesh),
            searchSearchIndexValidation: Acme_Search_V1_SearchIndexValidationService.Client(
                wrapping: dependencies.mesh),
            sponsorshipsSponsorCalculation: Acme_Sponsorships_V1_SponsorCalculationService.Client(
                wrapping: dependencies.mesh),
            telehealthTriageValidation: Acme_Telehealth_V1_TriageValidationService.Client(wrapping: dependencies.mesh),
            telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client(wrapping: dependencies.mesh),
            venuesVenue: Acme_Venues_V1_VenueService.Client(wrapping: dependencies.mesh),
            venuesVenueQuery: Acme_Venues_V1_VenueQueryService.Client(wrapping: dependencies.mesh)
        )
        let medicationLifecycleEndpoint = MedicationLifecycleEndpoint(
            dependencies: dependencies,
            careplansCareGoalApproval: Acme_Careplans_V1_CareGoalApprovalService.Client(wrapping: dependencies.mesh),
            careplansVitalApproval: Acme_Careplans_V1_VitalApprovalService.Client(wrapping: dependencies.mesh),
            corporateeventsCorporateEventQuery: Acme_Corporateevents_V1_CorporateEventQueryService.Client(
                wrapping: dependencies.mesh),
            documentsDocument: Acme_Documents_V1_DocumentService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            inventoryStockItem: Acme_Inventory_V1_StockItemService.Client(wrapping: dependencies.mesh),
            ledgerLedgerAccountQuery: Acme_Ledger_V1_LedgerAccountQueryService.Client(wrapping: dependencies.mesh),
            metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client(
                wrapping: dependencies.mesh),
            notificationsNotificationQuery: Acme_Notifications_V1_NotificationQueryService.Client(
                wrapping: dependencies.mesh),
            patientsAllergyCalculation: Acme_Patients_V1_AllergyCalculationService.Client(wrapping: dependencies.mesh),
            patientsAllergyValidation: Acme_Patients_V1_AllergyValidationService.Client(wrapping: dependencies.mesh),
            patientsPatient: Acme_Patients_V1_PatientService.Client(wrapping: dependencies.mesh),
            prescriptionsMedicationReporting: Acme_Prescriptions_V1_MedicationReportingService.Client(
                wrapping: dependencies.mesh),
            prescriptionsMedicationSync: Acme_Prescriptions_V1_MedicationSyncService.Client(
                wrapping: dependencies.mesh),
            prescriptionsMedicationValidation: Acme_Prescriptions_V1_MedicationValidationService.Client(
                wrapping: dependencies.mesh),
            prescriptionsRefillSync: Acme_Prescriptions_V1_RefillSyncService.Client(wrapping: dependencies.mesh)
        )
        let medicationQueryEndpoint = MedicationQueryEndpoint(
            dependencies: dependencies,
            careplansCareGoalValidation: Acme_Careplans_V1_CareGoalValidationService.Client(
                wrapping: dependencies.mesh),
            documentsDocumentQuery: Acme_Documents_V1_DocumentQueryService.Client(wrapping: dependencies.mesh),
            featureflagsFeatureFlagQuery: Acme_Featureflags_V1_FeatureFlagQueryService.Client(
                wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            metricsMetricSeries: Acme_Metrics_V1_MetricSeriesService.Client(wrapping: dependencies.mesh),
            prescriptionsMedicationCalculation: Acme_Prescriptions_V1_MedicationCalculationService.Client(
                wrapping: dependencies.mesh),
            prescriptionsPrescriptionQuery: Acme_Prescriptions_V1_PrescriptionQueryService.Client(
                wrapping: dependencies.mesh),
            prescriptionsPrescriptionValidation: Acme_Prescriptions_V1_PrescriptionValidationService.Client(
                wrapping: dependencies.mesh),
            seatingSeatMap: Acme_Seating_V1_SeatMapService.Client(wrapping: dependencies.mesh),
            sponsorshipsSponsor: Acme_Sponsorships_V1_SponsorService.Client(wrapping: dependencies.mesh),
            telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client(wrapping: dependencies.mesh),
            telehealthVisitNoteValidation: Acme_Telehealth_V1_VisitNoteValidationService.Client(
                wrapping: dependencies.mesh)
        )
        let medicationReportingEndpoint = MedicationReportingEndpoint(
            dependencies: dependencies,
            careplansVitalApproval: Acme_Careplans_V1_VitalApprovalService.Client(wrapping: dependencies.mesh),
            careplansVitalLifecycle: Acme_Careplans_V1_VitalLifecycleService.Client(wrapping: dependencies.mesh),
            expensesExpenseReportQuery: Acme_Expenses_V1_ExpenseReportQueryService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            notificationsNotification: Acme_Notifications_V1_NotificationService.Client(wrapping: dependencies.mesh),
            patientsAllergyValidation: Acme_Patients_V1_AllergyValidationService.Client(wrapping: dependencies.mesh),
            patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client(
                wrapping: dependencies.mesh),
            patientsPatientCalculation: Acme_Patients_V1_PatientCalculationService.Client(wrapping: dependencies.mesh),
            prescriptionsMedicationSync: Acme_Prescriptions_V1_MedicationSyncService.Client(
                wrapping: dependencies.mesh),
            prescriptionsPrescription: Acme_Prescriptions_V1_PrescriptionService.Client(wrapping: dependencies.mesh),
            prescriptionsPrescriptionQuery: Acme_Prescriptions_V1_PrescriptionQueryService.Client(
                wrapping: dependencies.mesh),
            prescriptionsPrescriptionValidation: Acme_Prescriptions_V1_PrescriptionValidationService.Client(
                wrapping: dependencies.mesh),
            prescriptionsRefillValidation: Acme_Prescriptions_V1_RefillValidationService.Client(
                wrapping: dependencies.mesh),
            telehealthTriageApproval: Acme_Telehealth_V1_TriageApprovalService.Client(wrapping: dependencies.mesh),
            telehealthVideoVisitWorkflow: Acme_Telehealth_V1_VideoVisitWorkflowService.Client(
                wrapping: dependencies.mesh),
            timekeepingTimesheetQuery: Acme_Timekeeping_V1_TimesheetQueryService.Client(wrapping: dependencies.mesh)
        )
        let medicationSyncEndpoint = MedicationSyncEndpoint(
            dependencies: dependencies,
            authorizationAccessPolicyQuery: Acme_Authorization_V1_AccessPolicyQueryService.Client(
                wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client(
                wrapping: dependencies.mesh),
            patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client(
                wrapping: dependencies.mesh),
            patientsMedicalRecordValidation: Acme_Patients_V1_MedicalRecordValidationService.Client(
                wrapping: dependencies.mesh),
            patientsPatientCalculation: Acme_Patients_V1_PatientCalculationService.Client(wrapping: dependencies.mesh),
            patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client(wrapping: dependencies.mesh),
            prescriptionsMedicationCalculation: Acme_Prescriptions_V1_MedicationCalculationService.Client(
                wrapping: dependencies.mesh),
            prescriptionsMedicationQuery: Acme_Prescriptions_V1_MedicationQueryService.Client(
                wrapping: dependencies.mesh),
            prescriptionsPrescriptionSync: Acme_Prescriptions_V1_PrescriptionSyncService.Client(
                wrapping: dependencies.mesh),
            prescriptionsPrescriptionValidation: Acme_Prescriptions_V1_PrescriptionValidationService.Client(
                wrapping: dependencies.mesh),
            prescriptionsRefillImport: Acme_Prescriptions_V1_RefillImportService.Client(wrapping: dependencies.mesh),
            telehealthTriageWorkflow: Acme_Telehealth_V1_TriageWorkflowService.Client(wrapping: dependencies.mesh)
        )
        let medicationValidationEndpoint = MedicationValidationEndpoint(
            dependencies: dependencies,
            careplansCareGoalValidation: Acme_Careplans_V1_CareGoalValidationService.Client(
                wrapping: dependencies.mesh),
            careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client(wrapping: dependencies.mesh),
            careplansVitalCalculation: Acme_Careplans_V1_VitalCalculationService.Client(wrapping: dependencies.mesh),
            careplansVitalValidation: Acme_Careplans_V1_VitalValidationService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            prescriptionsMedicationCalculation: Acme_Prescriptions_V1_MedicationCalculationService.Client(
                wrapping: dependencies.mesh),
            prescriptionsPrescriptionCalculation: Acme_Prescriptions_V1_PrescriptionCalculationService.Client(
                wrapping: dependencies.mesh),
            prescriptionsRefillCalculation: Acme_Prescriptions_V1_RefillCalculationService.Client(
                wrapping: dependencies.mesh),
            telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client(
                wrapping: dependencies.mesh),
            telehealthVideoVisitQuery: Acme_Telehealth_V1_VideoVisitQueryService.Client(wrapping: dependencies.mesh),
            telehealthVisitNoteQuery: Acme_Telehealth_V1_VisitNoteQueryService.Client(wrapping: dependencies.mesh)
        )
        let medicationWorkflowEndpoint = MedicationWorkflowEndpoint(
            dependencies: dependencies,
            auditAuditEvent: Acme_Audit_V1_AuditEventService.Client(wrapping: dependencies.mesh),
            authorizationAccessPolicyValidation: Acme_Authorization_V1_AccessPolicyValidationService.Client(
                wrapping: dependencies.mesh),
            careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client(wrapping: dependencies.mesh),
            careplansCarePlanApproval: Acme_Careplans_V1_CarePlanApprovalService.Client(wrapping: dependencies.mesh),
            careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client(
                wrapping: dependencies.mesh),
            featureflagsFeatureFlag: Acme_Featureflags_V1_FeatureFlagService.Client(wrapping: dependencies.mesh),
            featureflagsFeatureFlagQuery: Acme_Featureflags_V1_FeatureFlagQueryService.Client(
                wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            identityUserQuery: Acme_Identity_V1_UserQueryService.Client(wrapping: dependencies.mesh),
            metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client(
                wrapping: dependencies.mesh),
            patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client(
                wrapping: dependencies.mesh),
            patientsMedicalRecordQuery: Acme_Patients_V1_MedicalRecordQueryService.Client(wrapping: dependencies.mesh),
            prescriptionsMedicationApproval: Acme_Prescriptions_V1_MedicationApprovalService.Client(
                wrapping: dependencies.mesh),
            prescriptionsPrescriptionApproval: Acme_Prescriptions_V1_PrescriptionApprovalService.Client(
                wrapping: dependencies.mesh),
            prescriptionsPrescriptionQuery: Acme_Prescriptions_V1_PrescriptionQueryService.Client(
                wrapping: dependencies.mesh),
            prescriptionsPrescriptionReporting: Acme_Prescriptions_V1_PrescriptionReportingService.Client(
                wrapping: dependencies.mesh),
            prescriptionsPrescriptionSync: Acme_Prescriptions_V1_PrescriptionSyncService.Client(
                wrapping: dependencies.mesh),
            telehealthVideoVisitApproval: Acme_Telehealth_V1_VideoVisitApprovalService.Client(
                wrapping: dependencies.mesh),
            telehealthVisitNoteWorkflow: Acme_Telehealth_V1_VisitNoteWorkflowService.Client(wrapping: dependencies.mesh)
        )
        let prescriptionApprovalEndpoint = PrescriptionApprovalEndpoint(
            dependencies: dependencies,
            careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client(
                wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            ledgerLedgerAccountValidation: Acme_Ledger_V1_LedgerAccountValidationService.Client(
                wrapping: dependencies.mesh),
            patientsAllergyValidation: Acme_Patients_V1_AllergyValidationService.Client(wrapping: dependencies.mesh),
            patientsPatientValidation: Acme_Patients_V1_PatientValidationService.Client(wrapping: dependencies.mesh),
            prescriptionsMedicationSync: Acme_Prescriptions_V1_MedicationSyncService.Client(
                wrapping: dependencies.mesh),
            prescriptionsMedicationValidation: Acme_Prescriptions_V1_MedicationValidationService.Client(
                wrapping: dependencies.mesh),
            prescriptionsPrescriptionLifecycle: Acme_Prescriptions_V1_PrescriptionLifecycleService.Client(
                wrapping: dependencies.mesh),
            prescriptionsPrescriptionReporting: Acme_Prescriptions_V1_PrescriptionReportingService.Client(
                wrapping: dependencies.mesh),
            prescriptionsRefillImport: Acme_Prescriptions_V1_RefillImportService.Client(wrapping: dependencies.mesh),
            prescriptionsRefillLifecycle: Acme_Prescriptions_V1_RefillLifecycleService.Client(
                wrapping: dependencies.mesh),
            prescriptionsRefillSync: Acme_Prescriptions_V1_RefillSyncService.Client(wrapping: dependencies.mesh),
            telehealthTriageWorkflow: Acme_Telehealth_V1_TriageWorkflowService.Client(wrapping: dependencies.mesh),
            telehealthVisitNoteApproval: Acme_Telehealth_V1_VisitNoteApprovalService.Client(wrapping: dependencies.mesh)
        )
        let prescriptionCalculationEndpoint = PrescriptionCalculationEndpoint(
            dependencies: dependencies,
            auditAuditEventValidation: Acme_Audit_V1_AuditEventValidationService.Client(wrapping: dependencies.mesh),
            careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client(
                wrapping: dependencies.mesh),
            careplansCareGoalValidation: Acme_Careplans_V1_CareGoalValidationService.Client(
                wrapping: dependencies.mesh),
            careplansCarePlanQuery: Acme_Careplans_V1_CarePlanQueryService.Client(wrapping: dependencies.mesh),
            careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client(
                wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            ledgerLedgerAccountQuery: Acme_Ledger_V1_LedgerAccountQueryService.Client(wrapping: dependencies.mesh),
            metricsMetricSeries: Acme_Metrics_V1_MetricSeriesService.Client(wrapping: dependencies.mesh),
            showsShowCalculation: Acme_Shows_V1_ShowCalculationService.Client(wrapping: dependencies.mesh),
            telehealthTriageValidation: Acme_Telehealth_V1_TriageValidationService.Client(wrapping: dependencies.mesh),
            telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client(wrapping: dependencies.mesh),
            telehealthVideoVisitValidation: Acme_Telehealth_V1_VideoVisitValidationService.Client(
                wrapping: dependencies.mesh),
            telehealthVisitNoteQuery: Acme_Telehealth_V1_VisitNoteQueryService.Client(wrapping: dependencies.mesh),
            venuesVenueValidation: Acme_Venues_V1_VenueValidationService.Client(wrapping: dependencies.mesh)
        )
        let prescriptionLifecycleEndpoint = PrescriptionLifecycleEndpoint(
            dependencies: dependencies,
            auditAuditEventQuery: Acme_Audit_V1_AuditEventQueryService.Client(wrapping: dependencies.mesh),
            careplansVitalReporting: Acme_Careplans_V1_VitalReportingService.Client(wrapping: dependencies.mesh),
            complianceComplianceCase: Acme_Compliance_V1_ComplianceCaseService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client(
                wrapping: dependencies.mesh),
            patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client(
                wrapping: dependencies.mesh),
            patientsMedicalRecordQuery: Acme_Patients_V1_MedicalRecordQueryService.Client(wrapping: dependencies.mesh),
            patientsMedicalRecordValidation: Acme_Patients_V1_MedicalRecordValidationService.Client(
                wrapping: dependencies.mesh),
            prescriptionsMedicationCalculation: Acme_Prescriptions_V1_MedicationCalculationService.Client(
                wrapping: dependencies.mesh),
            prescriptionsMedicationQuery: Acme_Prescriptions_V1_MedicationQueryService.Client(
                wrapping: dependencies.mesh),
            prescriptionsMedicationSync: Acme_Prescriptions_V1_MedicationSyncService.Client(
                wrapping: dependencies.mesh),
            prescriptionsPrescriptionQuery: Acme_Prescriptions_V1_PrescriptionQueryService.Client(
                wrapping: dependencies.mesh),
            prescriptionsRefillCalculation: Acme_Prescriptions_V1_RefillCalculationService.Client(
                wrapping: dependencies.mesh),
            prescriptionsRefillImport: Acme_Prescriptions_V1_RefillImportService.Client(wrapping: dependencies.mesh),
            prescriptionsRefillSync: Acme_Prescriptions_V1_RefillSyncService.Client(wrapping: dependencies.mesh),
            searchSearchIndexValidation: Acme_Search_V1_SearchIndexValidationService.Client(
                wrapping: dependencies.mesh),
            telehealthTriageApproval: Acme_Telehealth_V1_TriageApprovalService.Client(wrapping: dependencies.mesh),
            telehealthVideoVisitWorkflow: Acme_Telehealth_V1_VideoVisitWorkflowService.Client(
                wrapping: dependencies.mesh)
        )
        let prescriptionQueryEndpoint = PrescriptionQueryEndpoint(
            dependencies: dependencies,
            authorizationAccessPolicy: Acme_Authorization_V1_AccessPolicyService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            metricsMetricSeries: Acme_Metrics_V1_MetricSeriesService.Client(wrapping: dependencies.mesh),
            prescriptionsMedicationCalculation: Acme_Prescriptions_V1_MedicationCalculationService.Client(
                wrapping: dependencies.mesh),
            prescriptionsMedicationValidation: Acme_Prescriptions_V1_MedicationValidationService.Client(
                wrapping: dependencies.mesh),
            prescriptionsPrescriptionValidation: Acme_Prescriptions_V1_PrescriptionValidationService.Client(
                wrapping: dependencies.mesh),
            prescriptionsRefillCalculation: Acme_Prescriptions_V1_RefillCalculationService.Client(
                wrapping: dependencies.mesh),
            searchSearchIndex: Acme_Search_V1_SearchIndexService.Client(wrapping: dependencies.mesh),
            searchSearchIndexQuery: Acme_Search_V1_SearchIndexQueryService.Client(wrapping: dependencies.mesh),
            telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client(wrapping: dependencies.mesh)
        )
        let prescriptionReportingEndpoint = PrescriptionReportingEndpoint(
            dependencies: dependencies,
            authorizationAccessPolicyQuery: Acme_Authorization_V1_AccessPolicyQueryService.Client(
                wrapping: dependencies.mesh),
            authorizationAccessPolicyValidation: Acme_Authorization_V1_AccessPolicyValidationService.Client(
                wrapping: dependencies.mesh),
            careplansCareGoalApproval: Acme_Careplans_V1_CareGoalApprovalService.Client(wrapping: dependencies.mesh),
            careplansCarePlanCalculation: Acme_Careplans_V1_CarePlanCalculationService.Client(
                wrapping: dependencies.mesh),
            fraudRiskAssessment: Acme_Fraud_V1_RiskAssessmentService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            patientsMedicalRecordQuery: Acme_Patients_V1_MedicalRecordQueryService.Client(wrapping: dependencies.mesh),
            patientsPatient: Acme_Patients_V1_PatientService.Client(wrapping: dependencies.mesh),
            patientsPatientCalculation: Acme_Patients_V1_PatientCalculationService.Client(wrapping: dependencies.mesh),
            patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client(wrapping: dependencies.mesh),
            paymentsPaymentCalculation: Acme_Payments_V1_PaymentCalculationService.Client(wrapping: dependencies.mesh),
            prescriptionsMedicationQuery: Acme_Prescriptions_V1_MedicationQueryService.Client(
                wrapping: dependencies.mesh),
            prescriptionsMedicationSync: Acme_Prescriptions_V1_MedicationSyncService.Client(
                wrapping: dependencies.mesh),
            prescriptionsPrescriptionSync: Acme_Prescriptions_V1_PrescriptionSyncService.Client(
                wrapping: dependencies.mesh),
            prescriptionsRefillImport: Acme_Prescriptions_V1_RefillImportService.Client(wrapping: dependencies.mesh),
            venuesVenueQuery: Acme_Venues_V1_VenueQueryService.Client(wrapping: dependencies.mesh)
        )
        let prescriptionEndpoint = PrescriptionEndpoint(
            dependencies: dependencies,
            auditAuditEvent: Acme_Audit_V1_AuditEventService.Client(wrapping: dependencies.mesh),
            authorizationAccessPolicyQuery: Acme_Authorization_V1_AccessPolicyQueryService.Client(
                wrapping: dependencies.mesh),
            boxofficeBoxOfficeSale: Acme_Boxoffice_V1_BoxOfficeSaleService.Client(wrapping: dependencies.mesh),
            careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client(
                wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            identityUserQuery: Acme_Identity_V1_UserQueryService.Client(wrapping: dependencies.mesh),
            identityUserValidation: Acme_Identity_V1_UserValidationService.Client(wrapping: dependencies.mesh),
            prescriptionsMedicationCalculation: Acme_Prescriptions_V1_MedicationCalculationService.Client(
                wrapping: dependencies.mesh),
            prescriptionsMedicationValidation: Acme_Prescriptions_V1_MedicationValidationService.Client(
                wrapping: dependencies.mesh),
            prescriptionsPrescriptionCalculation: Acme_Prescriptions_V1_PrescriptionCalculationService.Client(
                wrapping: dependencies.mesh),
            prescriptionsPrescriptionValidation: Acme_Prescriptions_V1_PrescriptionValidationService.Client(
                wrapping: dependencies.mesh),
            prescriptionsRefillCalculation: Acme_Prescriptions_V1_RefillCalculationService.Client(
                wrapping: dependencies.mesh),
            prescriptionsRefillValidation: Acme_Prescriptions_V1_RefillValidationService.Client(
                wrapping: dependencies.mesh),
            searchSearchIndex: Acme_Search_V1_SearchIndexService.Client(wrapping: dependencies.mesh),
            sponsorshipsSponsorQuery: Acme_Sponsorships_V1_SponsorQueryService.Client(wrapping: dependencies.mesh),
            telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client(wrapping: dependencies.mesh)
        )
        let prescriptionSyncEndpoint = PrescriptionSyncEndpoint(
            dependencies: dependencies,
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client(
                wrapping: dependencies.mesh),
            patientsMedicalRecordQuery: Acme_Patients_V1_MedicalRecordQueryService.Client(wrapping: dependencies.mesh),
            patientsPatientCalculation: Acme_Patients_V1_PatientCalculationService.Client(wrapping: dependencies.mesh),
            prescriptionsMedicationCalculation: Acme_Prescriptions_V1_MedicationCalculationService.Client(
                wrapping: dependencies.mesh),
            prescriptionsMedicationQuery: Acme_Prescriptions_V1_MedicationQueryService.Client(
                wrapping: dependencies.mesh),
            prescriptionsMedicationValidation: Acme_Prescriptions_V1_MedicationValidationService.Client(
                wrapping: dependencies.mesh),
            prescriptionsPrescription: Acme_Prescriptions_V1_PrescriptionService.Client(wrapping: dependencies.mesh),
            prescriptionsPrescriptionCalculation: Acme_Prescriptions_V1_PrescriptionCalculationService.Client(
                wrapping: dependencies.mesh),
            prescriptionsPrescriptionValidation: Acme_Prescriptions_V1_PrescriptionValidationService.Client(
                wrapping: dependencies.mesh),
            prescriptionsRefillValidation: Acme_Prescriptions_V1_RefillValidationService.Client(
                wrapping: dependencies.mesh),
            searchSearchIndexValidation: Acme_Search_V1_SearchIndexValidationService.Client(wrapping: dependencies.mesh)
        )
        let prescriptionValidationEndpoint = PrescriptionValidationEndpoint(
            dependencies: dependencies,
            careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client(
                wrapping: dependencies.mesh),
            featureflagsFeatureFlag: Acme_Featureflags_V1_FeatureFlagService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            metricsMetricSeriesQuery: Acme_Metrics_V1_MetricSeriesQueryService.Client(wrapping: dependencies.mesh),
            notificationsNotificationValidation: Acme_Notifications_V1_NotificationValidationService.Client(
                wrapping: dependencies.mesh),
            prescriptionsMedicationCalculation: Acme_Prescriptions_V1_MedicationCalculationService.Client(
                wrapping: dependencies.mesh),
            prescriptionsPrescriptionCalculation: Acme_Prescriptions_V1_PrescriptionCalculationService.Client(
                wrapping: dependencies.mesh),
            seatingSeatMapCalculation: Acme_Seating_V1_SeatMapCalculationService.Client(wrapping: dependencies.mesh),
            telehealthTriageCalculation: Acme_Telehealth_V1_TriageCalculationService.Client(
                wrapping: dependencies.mesh),
            telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client(wrapping: dependencies.mesh),
            telehealthVisitNoteCalculation: Acme_Telehealth_V1_VisitNoteCalculationService.Client(
                wrapping: dependencies.mesh),
            telehealthVisitNoteQuery: Acme_Telehealth_V1_VisitNoteQueryService.Client(wrapping: dependencies.mesh)
        )
        let prescriptionWorkflowEndpoint = PrescriptionWorkflowEndpoint(
            dependencies: dependencies,
            careplansCareGoalApproval: Acme_Careplans_V1_CareGoalApprovalService.Client(wrapping: dependencies.mesh),
            featureflagsFeatureFlag: Acme_Featureflags_V1_FeatureFlagService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            onboardingOnboardingPlanQuery: Acme_Onboarding_V1_OnboardingPlanQueryService.Client(
                wrapping: dependencies.mesh),
            patientsMedicalRecordQuery: Acme_Patients_V1_MedicalRecordQueryService.Client(wrapping: dependencies.mesh),
            patientsPatientValidation: Acme_Patients_V1_PatientValidationService.Client(wrapping: dependencies.mesh),
            prescriptionsMedicationApproval: Acme_Prescriptions_V1_MedicationApprovalService.Client(
                wrapping: dependencies.mesh),
            prescriptionsMedicationQuery: Acme_Prescriptions_V1_MedicationQueryService.Client(
                wrapping: dependencies.mesh),
            prescriptionsMedicationSync: Acme_Prescriptions_V1_MedicationSyncService.Client(
                wrapping: dependencies.mesh),
            prescriptionsPrescriptionApproval: Acme_Prescriptions_V1_PrescriptionApprovalService.Client(
                wrapping: dependencies.mesh),
            prescriptionsPrescriptionReporting: Acme_Prescriptions_V1_PrescriptionReportingService.Client(
                wrapping: dependencies.mesh),
            prescriptionsRefillReporting: Acme_Prescriptions_V1_RefillReportingService.Client(
                wrapping: dependencies.mesh),
            prescriptionsRefillSync: Acme_Prescriptions_V1_RefillSyncService.Client(wrapping: dependencies.mesh),
            prescriptionsRefillValidation: Acme_Prescriptions_V1_RefillValidationService.Client(
                wrapping: dependencies.mesh),
            telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client(wrapping: dependencies.mesh),
            telehealthVisitNoteApproval: Acme_Telehealth_V1_VisitNoteApprovalService.Client(
                wrapping: dependencies.mesh),
            telehealthVisitNoteWorkflow: Acme_Telehealth_V1_VisitNoteWorkflowService.Client(wrapping: dependencies.mesh)
        )
        let refillApprovalEndpoint = RefillApprovalEndpoint(
            dependencies: dependencies,
            auditAuditEventValidation: Acme_Audit_V1_AuditEventValidationService.Client(wrapping: dependencies.mesh),
            authorizationAccessPolicyQuery: Acme_Authorization_V1_AccessPolicyQueryService.Client(
                wrapping: dependencies.mesh),
            careplansCareGoalApproval: Acme_Careplans_V1_CareGoalApprovalService.Client(wrapping: dependencies.mesh),
            careplansVitalReporting: Acme_Careplans_V1_VitalReportingService.Client(wrapping: dependencies.mesh),
            datasetsDatasetQuery: Acme_Datasets_V1_DatasetQueryService.Client(wrapping: dependencies.mesh),
            documentsDocumentQuery: Acme_Documents_V1_DocumentQueryService.Client(wrapping: dependencies.mesh),
            featureflagsFeatureFlagValidation: Acme_Featureflags_V1_FeatureFlagValidationService.Client(
                wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            itsmIncidentQuery: Acme_Itsm_V1_IncidentQueryService.Client(wrapping: dependencies.mesh),
            ledgerLedgerAccountQuery: Acme_Ledger_V1_LedgerAccountQueryService.Client(wrapping: dependencies.mesh),
            metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client(
                wrapping: dependencies.mesh),
            patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client(
                wrapping: dependencies.mesh),
            patientsMedicalRecordValidation: Acme_Patients_V1_MedicalRecordValidationService.Client(
                wrapping: dependencies.mesh),
            prescriptionsPrescriptionSync: Acme_Prescriptions_V1_PrescriptionSyncService.Client(
                wrapping: dependencies.mesh),
            prescriptionsRefillImport: Acme_Prescriptions_V1_RefillImportService.Client(wrapping: dependencies.mesh),
            prescriptionsRefillLifecycle: Acme_Prescriptions_V1_RefillLifecycleService.Client(
                wrapping: dependencies.mesh),
            prescriptionsRefillReporting: Acme_Prescriptions_V1_RefillReportingService.Client(
                wrapping: dependencies.mesh)
        )
        let refillCalculationEndpoint = RefillCalculationEndpoint(
            dependencies: dependencies,
            boxofficeBoxOfficeSaleCalculation: Acme_Boxoffice_V1_BoxOfficeSaleCalculationService.Client(
                wrapping: dependencies.mesh),
            careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client(
                wrapping: dependencies.mesh),
            careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client(wrapping: dependencies.mesh),
            concessionsConcessionStandQuery: Acme_Concessions_V1_ConcessionStandQueryService.Client(
                wrapping: dependencies.mesh),
            documentsDocumentQuery: Acme_Documents_V1_DocumentQueryService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            ledgerLedgerAccountValidation: Acme_Ledger_V1_LedgerAccountValidationService.Client(
                wrapping: dependencies.mesh),
            prescriptionsPrescriptionCalculation: Acme_Prescriptions_V1_PrescriptionCalculationService.Client(
                wrapping: dependencies.mesh),
            sponsorshipsSponsorCalculation: Acme_Sponsorships_V1_SponsorCalculationService.Client(
                wrapping: dependencies.mesh),
            telehealthVisitNoteQuery: Acme_Telehealth_V1_VisitNoteQueryService.Client(wrapping: dependencies.mesh),
            venuesVenueQuery: Acme_Venues_V1_VenueQueryService.Client(wrapping: dependencies.mesh),
            venuesVenueValidation: Acme_Venues_V1_VenueValidationService.Client(wrapping: dependencies.mesh)
        )
        let refillImportEndpoint = RefillImportEndpoint(
            dependencies: dependencies,
            authorizationAccessPolicy: Acme_Authorization_V1_AccessPolicyService.Client(wrapping: dependencies.mesh),
            careplansCareGoalApproval: Acme_Careplans_V1_CareGoalApprovalService.Client(wrapping: dependencies.mesh),
            documentsDocumentQuery: Acme_Documents_V1_DocumentQueryService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            ledgerLedgerAccountValidation: Acme_Ledger_V1_LedgerAccountValidationService.Client(
                wrapping: dependencies.mesh),
            patientsPatient: Acme_Patients_V1_PatientService.Client(wrapping: dependencies.mesh),
            patientsPatientCalculation: Acme_Patients_V1_PatientCalculationService.Client(wrapping: dependencies.mesh),
            patientsPatientValidation: Acme_Patients_V1_PatientValidationService.Client(wrapping: dependencies.mesh),
            prescriptionsPrescription: Acme_Prescriptions_V1_PrescriptionService.Client(wrapping: dependencies.mesh),
            prescriptionsPrescriptionQuery: Acme_Prescriptions_V1_PrescriptionQueryService.Client(
                wrapping: dependencies.mesh),
            prescriptionsRefillValidation: Acme_Prescriptions_V1_RefillValidationService.Client(
                wrapping: dependencies.mesh),
            telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client(wrapping: dependencies.mesh),
            telehealthVideoVisitWorkflow: Acme_Telehealth_V1_VideoVisitWorkflowService.Client(
                wrapping: dependencies.mesh),
            venuesVenueValidation: Acme_Venues_V1_VenueValidationService.Client(wrapping: dependencies.mesh)
        )
        let refillLifecycleEndpoint = RefillLifecycleEndpoint(
            dependencies: dependencies,
            careplansCareGoalApproval: Acme_Careplans_V1_CareGoalApprovalService.Client(wrapping: dependencies.mesh),
            careplansVitalWorkflow: Acme_Careplans_V1_VitalWorkflowService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            ledgerLedgerAccountQuery: Acme_Ledger_V1_LedgerAccountQueryService.Client(wrapping: dependencies.mesh),
            patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client(
                wrapping: dependencies.mesh),
            patientsMedicalRecordValidation: Acme_Patients_V1_MedicalRecordValidationService.Client(
                wrapping: dependencies.mesh),
            patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client(wrapping: dependencies.mesh),
            prescriptionsMedicationSync: Acme_Prescriptions_V1_MedicationSyncService.Client(
                wrapping: dependencies.mesh),
            prescriptionsMedicationValidation: Acme_Prescriptions_V1_MedicationValidationService.Client(
                wrapping: dependencies.mesh),
            prescriptionsRefillImport: Acme_Prescriptions_V1_RefillImportService.Client(wrapping: dependencies.mesh),
            prescriptionsRefillSync: Acme_Prescriptions_V1_RefillSyncService.Client(wrapping: dependencies.mesh),
            searchSearchIndexValidation: Acme_Search_V1_SearchIndexValidationService.Client(wrapping: dependencies.mesh)
        )
        let refillReportingEndpoint = RefillReportingEndpoint(
            dependencies: dependencies,
            careplansCareGoalApproval: Acme_Careplans_V1_CareGoalApprovalService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            notificationsNotification: Acme_Notifications_V1_NotificationService.Client(wrapping: dependencies.mesh),
            prescriptionsMedicationCalculation: Acme_Prescriptions_V1_MedicationCalculationService.Client(
                wrapping: dependencies.mesh),
            prescriptionsMedicationSync: Acme_Prescriptions_V1_MedicationSyncService.Client(
                wrapping: dependencies.mesh),
            prescriptionsMedicationValidation: Acme_Prescriptions_V1_MedicationValidationService.Client(
                wrapping: dependencies.mesh),
            prescriptionsPrescriptionReporting: Acme_Prescriptions_V1_PrescriptionReportingService.Client(
                wrapping: dependencies.mesh),
            prescriptionsPrescriptionSync: Acme_Prescriptions_V1_PrescriptionSyncService.Client(
                wrapping: dependencies.mesh),
            prescriptionsRefillImport: Acme_Prescriptions_V1_RefillImportService.Client(wrapping: dependencies.mesh),
            telehealthTriageWorkflow: Acme_Telehealth_V1_TriageWorkflowService.Client(wrapping: dependencies.mesh)
        )
        let refillSyncEndpoint = RefillSyncEndpoint(
            dependencies: dependencies,
            careplansCareGoalApproval: Acme_Careplans_V1_CareGoalApprovalService.Client(wrapping: dependencies.mesh),
            careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client(wrapping: dependencies.mesh),
            careplansVitalReporting: Acme_Careplans_V1_VitalReportingService.Client(wrapping: dependencies.mesh),
            catalogProductQuery: Acme_Catalog_V1_ProductQueryService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            patientsPatient: Acme_Patients_V1_PatientService.Client(wrapping: dependencies.mesh),
            patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client(wrapping: dependencies.mesh),
            prescriptionsPrescriptionValidation: Acme_Prescriptions_V1_PrescriptionValidationService.Client(
                wrapping: dependencies.mesh),
            prescriptionsRefillImport: Acme_Prescriptions_V1_RefillImportService.Client(wrapping: dependencies.mesh),
            telehealthVideoVisitApproval: Acme_Telehealth_V1_VideoVisitApprovalService.Client(
                wrapping: dependencies.mesh),
            telehealthVisitNoteLifecycle: Acme_Telehealth_V1_VisitNoteLifecycleService.Client(
                wrapping: dependencies.mesh)
        )
        let refillValidationEndpoint = RefillValidationEndpoint(
            dependencies: dependencies,
            authorizationAccessPolicyQuery: Acme_Authorization_V1_AccessPolicyQueryService.Client(
                wrapping: dependencies.mesh),
            careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client(
                wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            metricsMetricSeriesQuery: Acme_Metrics_V1_MetricSeriesQueryService.Client(wrapping: dependencies.mesh),
            metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client(
                wrapping: dependencies.mesh),
            notificationsNotificationValidation: Acme_Notifications_V1_NotificationValidationService.Client(
                wrapping: dependencies.mesh),
            prescriptionsMedicationValidation: Acme_Prescriptions_V1_MedicationValidationService.Client(
                wrapping: dependencies.mesh),
            prescriptionsPrescriptionCalculation: Acme_Prescriptions_V1_PrescriptionCalculationService.Client(
                wrapping: dependencies.mesh),
            prescriptionsRefillCalculation: Acme_Prescriptions_V1_RefillCalculationService.Client(
                wrapping: dependencies.mesh),
            searchSearchIndexQuery: Acme_Search_V1_SearchIndexQueryService.Client(wrapping: dependencies.mesh),
            telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client(wrapping: dependencies.mesh),
            venuesVenueValidation: Acme_Venues_V1_VenueValidationService.Client(wrapping: dependencies.mesh)
        )
        let refillWorkflowEndpoint = RefillWorkflowEndpoint(
            dependencies: dependencies,
            boxofficeBoxOfficeSale: Acme_Boxoffice_V1_BoxOfficeSaleService.Client(wrapping: dependencies.mesh),
            careplansCareGoalWorkflow: Acme_Careplans_V1_CareGoalWorkflowService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            ledgerLedgerAccount: Acme_Ledger_V1_LedgerAccountService.Client(wrapping: dependencies.mesh),
            patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client(
                wrapping: dependencies.mesh),
            patientsPatientValidation: Acme_Patients_V1_PatientValidationService.Client(wrapping: dependencies.mesh),
            prescriptionsMedicationWorkflow: Acme_Prescriptions_V1_MedicationWorkflowService.Client(
                wrapping: dependencies.mesh),
            prescriptionsPrescriptionReporting: Acme_Prescriptions_V1_PrescriptionReportingService.Client(
                wrapping: dependencies.mesh),
            prescriptionsPrescriptionWorkflow: Acme_Prescriptions_V1_PrescriptionWorkflowService.Client(
                wrapping: dependencies.mesh),
            prescriptionsRefillCalculation: Acme_Prescriptions_V1_RefillCalculationService.Client(
                wrapping: dependencies.mesh),
            prescriptionsRefillImport: Acme_Prescriptions_V1_RefillImportService.Client(wrapping: dependencies.mesh),
            prescriptionsRefillSync: Acme_Prescriptions_V1_RefillSyncService.Client(wrapping: dependencies.mesh),
            promotionsPromotionCalculation: Acme_Promotions_V1_PromotionCalculationService.Client(
                wrapping: dependencies.mesh),
            searchSearchIndexQuery: Acme_Search_V1_SearchIndexQueryService.Client(wrapping: dependencies.mesh),
            searchSearchIndexValidation: Acme_Search_V1_SearchIndexValidationService.Client(
                wrapping: dependencies.mesh),
            telehealthVideoVisitValidation: Acme_Telehealth_V1_VideoVisitValidationService.Client(
                wrapping: dependencies.mesh),
            venuesVenue: Acme_Venues_V1_VenueService.Client(wrapping: dependencies.mesh)
        )
        return ServiceModule(
            services: [
                medicationApprovalEndpoint,
                medicationCalculationEndpoint,
                medicationLifecycleEndpoint,
                medicationQueryEndpoint,
                medicationReportingEndpoint,
                medicationSyncEndpoint,
                medicationValidationEndpoint,
                medicationWorkflowEndpoint,
                prescriptionApprovalEndpoint,
                prescriptionCalculationEndpoint,
                prescriptionLifecycleEndpoint,
                prescriptionQueryEndpoint,
                prescriptionReportingEndpoint,
                prescriptionEndpoint,
                prescriptionSyncEndpoint,
                prescriptionValidationEndpoint,
                prescriptionWorkflowEndpoint,
                refillApprovalEndpoint,
                refillCalculationEndpoint,
                refillImportEndpoint,
                refillLifecycleEndpoint,
                refillReportingEndpoint,
                refillSyncEndpoint,
                refillValidationEndpoint,
                refillWorkflowEndpoint,
            ],
            workers: [
                { try await medicationApprovalEndpoint.runFollowUps() },
                { try await medicationLifecycleEndpoint.runFollowUps() },
                { try await medicationReportingEndpoint.runFollowUps() },
                { try await medicationValidationEndpoint.runFollowUps() },
                { try await prescriptionApprovalEndpoint.runFollowUps() },
                { try await prescriptionLifecycleEndpoint.runFollowUps() },
                { try await prescriptionReportingEndpoint.runFollowUps() },
                { try await prescriptionSyncEndpoint.runFollowUps() },
                { try await prescriptionWorkflowEndpoint.runFollowUps() },
                { try await refillCalculationEndpoint.runFollowUps() },
                { try await refillLifecycleEndpoint.runFollowUps() },
                { try await refillSyncEndpoint.runFollowUps() },
                { try await refillWorkflowEndpoint.runFollowUps() },
            ]
        )
    }
}
