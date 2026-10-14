import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Composes the patientapp bounded context and exposes its services and background workers.
public enum PatientappModule {
    public static func make(dependencies: any Dependencies) -> ServiceModule {
        let careInboxIntegrationEndpoint = CareInboxIntegrationEndpoint(
            dependencies: dependencies,
            fanportalFanSessionQuery: Acme_Fanportal_V1_FanSessionQueryService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            identityUserValidation: Acme_Identity_V1_UserValidationService.Client(wrapping: dependencies.mesh),
            patientappCareInboxWorkflow: Acme_Patientapp_V1_CareInboxWorkflowService.Client(
                wrapping: dependencies.mesh),
            patientappPatientHomeIntegration: Acme_Patientapp_V1_PatientHomeIntegrationService.Client(
                wrapping: dependencies.mesh),
            patientappPatientHomeWorkflow: Acme_Patientapp_V1_PatientHomeWorkflowService.Client(
                wrapping: dependencies.mesh),
            patientsAllergyApproval: Acme_Patients_V1_AllergyApprovalService.Client(wrapping: dependencies.mesh),
            patientsAllergyCalculation: Acme_Patients_V1_AllergyCalculationService.Client(wrapping: dependencies.mesh),
            patientsMedicalRecordApproval: Acme_Patients_V1_MedicalRecordApprovalService.Client(
                wrapping: dependencies.mesh),
            patientsMedicalRecordSync: Acme_Patients_V1_MedicalRecordSyncService.Client(wrapping: dependencies.mesh),
            patientsPatientApproval: Acme_Patients_V1_PatientApprovalService.Client(wrapping: dependencies.mesh),
            prescriptionsRefillReporting: Acme_Prescriptions_V1_RefillReportingService.Client(
                wrapping: dependencies.mesh),
            searchSearchIndex: Acme_Search_V1_SearchIndexService.Client(wrapping: dependencies.mesh),
            telehealthTriageApproval: Acme_Telehealth_V1_TriageApprovalService.Client(wrapping: dependencies.mesh),
            telehealthTriageLifecycle: Acme_Telehealth_V1_TriageLifecycleService.Client(wrapping: dependencies.mesh),
            venuesVenueValidation: Acme_Venues_V1_VenueValidationService.Client(wrapping: dependencies.mesh)
        )
        let careInboxNotificationEndpoint = CareInboxNotificationEndpoint(
            dependencies: dependencies,
            auditAuditEventQuery: Acme_Audit_V1_AuditEventQueryService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            metricsMetricSeries: Acme_Metrics_V1_MetricSeriesService.Client(wrapping: dependencies.mesh),
            notificationsNotification: Acme_Notifications_V1_NotificationService.Client(wrapping: dependencies.mesh),
            patientappCareInboxIntegration: Acme_Patientapp_V1_CareInboxIntegrationService.Client(
                wrapping: dependencies.mesh),
            patientappCareInboxWorkflow: Acme_Patientapp_V1_CareInboxWorkflowService.Client(
                wrapping: dependencies.mesh),
            patientappPatientHomeIntegration: Acme_Patientapp_V1_PatientHomeIntegrationService.Client(
                wrapping: dependencies.mesh),
            patientappPatientHomeNotification: Acme_Patientapp_V1_PatientHomeNotificationService.Client(
                wrapping: dependencies.mesh),
            patientsMedicalRecordWorkflow: Acme_Patients_V1_MedicalRecordWorkflowService.Client(
                wrapping: dependencies.mesh),
            patientsPatientSync: Acme_Patients_V1_PatientSyncService.Client(wrapping: dependencies.mesh),
            patientsPatientWorkflow: Acme_Patients_V1_PatientWorkflowService.Client(wrapping: dependencies.mesh),
            prescriptionsPrescriptionWorkflow: Acme_Prescriptions_V1_PrescriptionWorkflowService.Client(
                wrapping: dependencies.mesh),
            searchSearchIndexValidation: Acme_Search_V1_SearchIndexValidationService.Client(
                wrapping: dependencies.mesh),
            ticketingTicket: Acme_Ticketing_V1_TicketService.Client(wrapping: dependencies.mesh)
        )
        let careInboxQueryEndpoint = CareInboxQueryEndpoint(
            dependencies: dependencies,
            careplansCareGoalApproval: Acme_Careplans_V1_CareGoalApprovalService.Client(wrapping: dependencies.mesh),
            careplansCareGoalWorkflow: Acme_Careplans_V1_CareGoalWorkflowService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            insurancePolicyQuery: Acme_Insurance_V1_PolicyQueryService.Client(wrapping: dependencies.mesh),
            metricsMetricSeriesQuery: Acme_Metrics_V1_MetricSeriesQueryService.Client(wrapping: dependencies.mesh),
            notificationsNotification: Acme_Notifications_V1_NotificationService.Client(wrapping: dependencies.mesh),
            patientappCareInboxIntegration: Acme_Patientapp_V1_CareInboxIntegrationService.Client(
                wrapping: dependencies.mesh),
            patientappCareInboxNotification: Acme_Patientapp_V1_CareInboxNotificationService.Client(
                wrapping: dependencies.mesh),
            patientappPatientHomeNotification: Acme_Patientapp_V1_PatientHomeNotificationService.Client(
                wrapping: dependencies.mesh),
            patientappPatientHomeQuery: Acme_Patientapp_V1_PatientHomeQueryService.Client(wrapping: dependencies.mesh),
            patientsMedicalRecordApproval: Acme_Patients_V1_MedicalRecordApprovalService.Client(
                wrapping: dependencies.mesh),
            patientsMedicalRecordSync: Acme_Patients_V1_MedicalRecordSyncService.Client(wrapping: dependencies.mesh),
            prescriptionsMedicationSync: Acme_Prescriptions_V1_MedicationSyncService.Client(
                wrapping: dependencies.mesh),
            prescriptionsPrescriptionReporting: Acme_Prescriptions_V1_PrescriptionReportingService.Client(
                wrapping: dependencies.mesh)
        )
        let careInboxEndpoint = CareInboxEndpoint(
            dependencies: dependencies,
            careplansCarePlanWorkflow: Acme_Careplans_V1_CarePlanWorkflowService.Client(wrapping: dependencies.mesh),
            concessionsConcessionStand: Acme_Concessions_V1_ConcessionStandService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client(
                wrapping: dependencies.mesh),
            patientappCareInboxIntegration: Acme_Patientapp_V1_CareInboxIntegrationService.Client(
                wrapping: dependencies.mesh),
            patientappCareInboxNotification: Acme_Patientapp_V1_CareInboxNotificationService.Client(
                wrapping: dependencies.mesh),
            patientappCareInboxWorkflow: Acme_Patientapp_V1_CareInboxWorkflowService.Client(
                wrapping: dependencies.mesh),
            patientappPatientHomeQuery: Acme_Patientapp_V1_PatientHomeQueryService.Client(wrapping: dependencies.mesh),
            patientappPatientHomeWorkflow: Acme_Patientapp_V1_PatientHomeWorkflowService.Client(
                wrapping: dependencies.mesh),
            patientsAllergyApproval: Acme_Patients_V1_AllergyApprovalService.Client(wrapping: dependencies.mesh),
            patientsPatientSync: Acme_Patients_V1_PatientSyncService.Client(wrapping: dependencies.mesh),
            prescriptionsPrescriptionSync: Acme_Prescriptions_V1_PrescriptionSyncService.Client(
                wrapping: dependencies.mesh),
            telehealthTriageApproval: Acme_Telehealth_V1_TriageApprovalService.Client(wrapping: dependencies.mesh),
            telehealthVisitNoteWorkflow: Acme_Telehealth_V1_VisitNoteWorkflowService.Client(wrapping: dependencies.mesh)
        )
        let careInboxWorkflowEndpoint = CareInboxWorkflowEndpoint(
            dependencies: dependencies,
            appointmentsAppointmentWorkflow: Acme_Appointments_V1_AppointmentWorkflowService.Client(
                wrapping: dependencies.mesh),
            careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client(wrapping: dependencies.mesh),
            careplansCarePlanWorkflow: Acme_Careplans_V1_CarePlanWorkflowService.Client(wrapping: dependencies.mesh),
            careplansVitalReporting: Acme_Careplans_V1_VitalReportingService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            patientappPatientHomeWorkflow: Acme_Patientapp_V1_PatientHomeWorkflowService.Client(
                wrapping: dependencies.mesh),
            patientsMedicalRecordReporting: Acme_Patients_V1_MedicalRecordReportingService.Client(
                wrapping: dependencies.mesh),
            patientsPatientWorkflow: Acme_Patients_V1_PatientWorkflowService.Client(wrapping: dependencies.mesh),
            prescriptionsRefillLifecycle: Acme_Prescriptions_V1_RefillLifecycleService.Client(
                wrapping: dependencies.mesh)
        )
        let patientHomeGatewayEndpoint = PatientHomeGatewayEndpoint(
            dependencies: dependencies,
            careplansCareGoalWorkflow: Acme_Careplans_V1_CareGoalWorkflowService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            itsmIncident: Acme_Itsm_V1_IncidentService.Client(wrapping: dependencies.mesh),
            metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client(
                wrapping: dependencies.mesh),
            notificationsNotificationQuery: Acme_Notifications_V1_NotificationQueryService.Client(
                wrapping: dependencies.mesh),
            notificationsNotificationValidation: Acme_Notifications_V1_NotificationValidationService.Client(
                wrapping: dependencies.mesh),
            patientappCareInboxQuery: Acme_Patientapp_V1_CareInboxQueryService.Client(wrapping: dependencies.mesh),
            patientappPatientHome: Acme_Patientapp_V1_PatientHomeService.Client(wrapping: dependencies.mesh),
            patientappPatientHomeIntegration: Acme_Patientapp_V1_PatientHomeIntegrationService.Client(
                wrapping: dependencies.mesh),
            patientappPatientHomeWorkflow: Acme_Patientapp_V1_PatientHomeWorkflowService.Client(
                wrapping: dependencies.mesh),
            patientsAllergyWorkflow: Acme_Patients_V1_AllergyWorkflowService.Client(wrapping: dependencies.mesh),
            patientsPatientWorkflow: Acme_Patients_V1_PatientWorkflowService.Client(wrapping: dependencies.mesh),
            prescriptionsRefillWorkflow: Acme_Prescriptions_V1_RefillWorkflowService.Client(
                wrapping: dependencies.mesh),
            sponsorshipsSponsorQuery: Acme_Sponsorships_V1_SponsorQueryService.Client(wrapping: dependencies.mesh),
            venuesVenueValidation: Acme_Venues_V1_VenueValidationService.Client(wrapping: dependencies.mesh)
        )
        let patientHomeIntegrationEndpoint = PatientHomeIntegrationEndpoint(
            dependencies: dependencies,
            auditAuditEventQuery: Acme_Audit_V1_AuditEventQueryService.Client(wrapping: dependencies.mesh),
            careplansCarePlanApproval: Acme_Careplans_V1_CarePlanApprovalService.Client(wrapping: dependencies.mesh),
            documentsDocument: Acme_Documents_V1_DocumentService.Client(wrapping: dependencies.mesh),
            documentsDocumentQuery: Acme_Documents_V1_DocumentQueryService.Client(wrapping: dependencies.mesh),
            fanportalFanSession: Acme_Fanportal_V1_FanSessionService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            patientappCareInboxWorkflow: Acme_Patientapp_V1_CareInboxWorkflowService.Client(
                wrapping: dependencies.mesh),
            patientappPatientHomeWorkflow: Acme_Patientapp_V1_PatientHomeWorkflowService.Client(
                wrapping: dependencies.mesh),
            patientsAllergyApproval: Acme_Patients_V1_AllergyApprovalService.Client(wrapping: dependencies.mesh),
            patientsPatientApproval: Acme_Patients_V1_PatientApprovalService.Client(wrapping: dependencies.mesh),
            patientsPatientSync: Acme_Patients_V1_PatientSyncService.Client(wrapping: dependencies.mesh),
            patientsPatientWorkflow: Acme_Patients_V1_PatientWorkflowService.Client(wrapping: dependencies.mesh),
            payrollPayRunQuery: Acme_Payroll_V1_PayRunQueryService.Client(wrapping: dependencies.mesh),
            prescriptionsPrescriptionApproval: Acme_Prescriptions_V1_PrescriptionApprovalService.Client(
                wrapping: dependencies.mesh),
            telehealthVideoVisitWorkflow: Acme_Telehealth_V1_VideoVisitWorkflowService.Client(
                wrapping: dependencies.mesh)
        )
        let patientHomeNotificationEndpoint = PatientHomeNotificationEndpoint(
            dependencies: dependencies,
            appointmentsClinicSlotWorkflow: Acme_Appointments_V1_ClinicSlotWorkflowService.Client(
                wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            notificationsNotificationQuery: Acme_Notifications_V1_NotificationQueryService.Client(
                wrapping: dependencies.mesh),
            patientappCareInboxIntegration: Acme_Patientapp_V1_CareInboxIntegrationService.Client(
                wrapping: dependencies.mesh),
            patientappCareInboxWorkflow: Acme_Patientapp_V1_CareInboxWorkflowService.Client(
                wrapping: dependencies.mesh),
            patientappPatientHomeIntegration: Acme_Patientapp_V1_PatientHomeIntegrationService.Client(
                wrapping: dependencies.mesh),
            patientappPatientHomeWorkflow: Acme_Patientapp_V1_PatientHomeWorkflowService.Client(
                wrapping: dependencies.mesh),
            patientsAllergyImport: Acme_Patients_V1_AllergyImportService.Client(wrapping: dependencies.mesh),
            patientsPatientApproval: Acme_Patients_V1_PatientApprovalService.Client(wrapping: dependencies.mesh),
            patientsPatientSync: Acme_Patients_V1_PatientSyncService.Client(wrapping: dependencies.mesh),
            patientsPatientWorkflow: Acme_Patients_V1_PatientWorkflowService.Client(wrapping: dependencies.mesh),
            recruitingJobOpening: Acme_Recruiting_V1_JobOpeningService.Client(wrapping: dependencies.mesh),
            searchSearchIndex: Acme_Search_V1_SearchIndexService.Client(wrapping: dependencies.mesh),
            telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client(wrapping: dependencies.mesh),
            telehealthVideoVisitWorkflow: Acme_Telehealth_V1_VideoVisitWorkflowService.Client(
                wrapping: dependencies.mesh)
        )
        let patientHomeQueryEndpoint = PatientHomeQueryEndpoint(
            dependencies: dependencies,
            auditAuditEvent: Acme_Audit_V1_AuditEventService.Client(wrapping: dependencies.mesh),
            auditAuditEventQuery: Acme_Audit_V1_AuditEventQueryService.Client(wrapping: dependencies.mesh),
            documentsDocument: Acme_Documents_V1_DocumentService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            patientappPatientHomeNotification: Acme_Patientapp_V1_PatientHomeNotificationService.Client(
                wrapping: dependencies.mesh),
            patientsAllergyApproval: Acme_Patients_V1_AllergyApprovalService.Client(wrapping: dependencies.mesh),
            prescriptionsMedicationSync: Acme_Prescriptions_V1_MedicationSyncService.Client(
                wrapping: dependencies.mesh),
            prescriptionsPrescriptionSync: Acme_Prescriptions_V1_PrescriptionSyncService.Client(
                wrapping: dependencies.mesh)
        )
        let patientHomeEndpoint = PatientHomeEndpoint(
            dependencies: dependencies,
            appointmentsAppointmentWorkflow: Acme_Appointments_V1_AppointmentWorkflowService.Client(
                wrapping: dependencies.mesh),
            dispatchDispatchOrderQuery: Acme_Dispatch_V1_DispatchOrderQueryService.Client(wrapping: dependencies.mesh),
            fanportalFanSessionQuery: Acme_Fanportal_V1_FanSessionQueryService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            notificationsNotification: Acme_Notifications_V1_NotificationService.Client(wrapping: dependencies.mesh),
            notificationsNotificationQuery: Acme_Notifications_V1_NotificationQueryService.Client(
                wrapping: dependencies.mesh),
            notificationsNotificationValidation: Acme_Notifications_V1_NotificationValidationService.Client(
                wrapping: dependencies.mesh),
            patientappCareInboxIntegration: Acme_Patientapp_V1_CareInboxIntegrationService.Client(
                wrapping: dependencies.mesh),
            patientappCareInboxQuery: Acme_Patientapp_V1_CareInboxQueryService.Client(wrapping: dependencies.mesh),
            patientappPatientHomeQuery: Acme_Patientapp_V1_PatientHomeQueryService.Client(wrapping: dependencies.mesh),
            patientappPatientHomeWorkflow: Acme_Patientapp_V1_PatientHomeWorkflowService.Client(
                wrapping: dependencies.mesh),
            patientsPatientApproval: Acme_Patients_V1_PatientApprovalService.Client(wrapping: dependencies.mesh),
            patientsPatientWorkflow: Acme_Patients_V1_PatientWorkflowService.Client(wrapping: dependencies.mesh),
            prescriptionsMedicationSync: Acme_Prescriptions_V1_MedicationSyncService.Client(
                wrapping: dependencies.mesh),
            searchSearchIndexValidation: Acme_Search_V1_SearchIndexValidationService.Client(
                wrapping: dependencies.mesh),
            telehealthTriageWorkflow: Acme_Telehealth_V1_TriageWorkflowService.Client(wrapping: dependencies.mesh)
        )
        let patientHomeWorkflowEndpoint = PatientHomeWorkflowEndpoint(
            dependencies: dependencies,
            appointmentsAppointmentApproval: Acme_Appointments_V1_AppointmentApprovalService.Client(
                wrapping: dependencies.mesh),
            appointmentsClinicSlotApproval: Acme_Appointments_V1_ClinicSlotApprovalService.Client(
                wrapping: dependencies.mesh),
            audiencesAudience: Acme_Audiences_V1_AudienceService.Client(wrapping: dependencies.mesh),
            auditAuditEventQuery: Acme_Audit_V1_AuditEventQueryService.Client(wrapping: dependencies.mesh),
            careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client(wrapping: dependencies.mesh),
            fulfillmentFulfillmentQuery: Acme_Fulfillment_V1_FulfillmentQueryService.Client(
                wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            identityUserQuery: Acme_Identity_V1_UserQueryService.Client(wrapping: dependencies.mesh),
            ledgerLedgerAccount: Acme_Ledger_V1_LedgerAccountService.Client(wrapping: dependencies.mesh),
            licensingSoftwareLicenseQuery: Acme_Licensing_V1_SoftwareLicenseQueryService.Client(
                wrapping: dependencies.mesh),
            patientsAllergyApproval: Acme_Patients_V1_AllergyApprovalService.Client(wrapping: dependencies.mesh),
            patientsMedicalRecordApproval: Acme_Patients_V1_MedicalRecordApprovalService.Client(
                wrapping: dependencies.mesh),
            patientsMedicalRecordValidation: Acme_Patients_V1_MedicalRecordValidationService.Client(
                wrapping: dependencies.mesh),
            patientsMedicalRecordWorkflow: Acme_Patients_V1_MedicalRecordWorkflowService.Client(
                wrapping: dependencies.mesh),
            patientsPatientReporting: Acme_Patients_V1_PatientReportingService.Client(wrapping: dependencies.mesh),
            patientsPatientWorkflow: Acme_Patients_V1_PatientWorkflowService.Client(wrapping: dependencies.mesh),
            prescriptionsMedicationSync: Acme_Prescriptions_V1_MedicationSyncService.Client(
                wrapping: dependencies.mesh),
            prescriptionsPrescriptionLifecycle: Acme_Prescriptions_V1_PrescriptionLifecycleService.Client(
                wrapping: dependencies.mesh),
            prescriptionsRefillSync: Acme_Prescriptions_V1_RefillSyncService.Client(wrapping: dependencies.mesh),
            telehealthVisitNoteApproval: Acme_Telehealth_V1_VisitNoteApprovalService.Client(wrapping: dependencies.mesh)
        )
        return ServiceModule(
            services: [
                careInboxIntegrationEndpoint,
                careInboxNotificationEndpoint,
                careInboxQueryEndpoint,
                careInboxEndpoint,
                careInboxWorkflowEndpoint,
                patientHomeGatewayEndpoint,
                patientHomeIntegrationEndpoint,
                patientHomeNotificationEndpoint,
                patientHomeQueryEndpoint,
                patientHomeEndpoint,
                patientHomeWorkflowEndpoint,
            ],
            workers: [
                { try await careInboxIntegrationEndpoint.runFollowUps() },
                { try await careInboxQueryEndpoint.runFollowUps() },
                { try await careInboxWorkflowEndpoint.runFollowUps() },
                { try await patientHomeIntegrationEndpoint.runFollowUps() },
                { try await patientHomeQueryEndpoint.runFollowUps() },
                { try await patientHomeWorkflowEndpoint.runFollowUps() },
            ]
        )
    }
}
