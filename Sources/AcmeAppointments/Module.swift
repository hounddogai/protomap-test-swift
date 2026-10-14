import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Composes the appointments bounded context and exposes its services and background workers.
public enum AppointmentsModule {
    public static func make(dependencies: any Dependencies) -> ServiceModule {
        let appointmentApprovalEndpoint = AppointmentApprovalEndpoint(
            dependencies: dependencies,
            appointmentsAppointment: Acme_Appointments_V1_AppointmentService.Client(wrapping: dependencies.mesh),
            appointmentsAppointmentQuery: Acme_Appointments_V1_AppointmentQueryService.Client(
                wrapping: dependencies.mesh),
            appointmentsProviderQuery: Acme_Appointments_V1_ProviderQueryService.Client(wrapping: dependencies.mesh),
            authorizationAccessPolicy: Acme_Authorization_V1_AccessPolicyService.Client(wrapping: dependencies.mesh),
            careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client(wrapping: dependencies.mesh),
            careplansVitalLifecycle: Acme_Careplans_V1_VitalLifecycleService.Client(wrapping: dependencies.mesh),
            featureflagsFeatureFlag: Acme_Featureflags_V1_FeatureFlagService.Client(wrapping: dependencies.mesh),
            featureflagsFeatureFlagValidation: Acme_Featureflags_V1_FeatureFlagValidationService.Client(
                wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            prescriptionsPrescriptionReporting: Acme_Prescriptions_V1_PrescriptionReportingService.Client(
                wrapping: dependencies.mesh),
            prescriptionsRefillWorkflow: Acme_Prescriptions_V1_RefillWorkflowService.Client(
                wrapping: dependencies.mesh),
            ratelimitingRateLimitCalculation: Acme_Ratelimiting_V1_RateLimitCalculationService.Client(
                wrapping: dependencies.mesh),
            telehealthVideoVisitApproval: Acme_Telehealth_V1_VideoVisitApprovalService.Client(
                wrapping: dependencies.mesh)
        )
        let appointmentQueryEndpoint = AppointmentQueryEndpoint(
            dependencies: dependencies,
            appointmentsAppointmentValidation: Acme_Appointments_V1_AppointmentValidationService.Client(
                wrapping: dependencies.mesh),
            appointmentsClinicSlotCalculation: Acme_Appointments_V1_ClinicSlotCalculationService.Client(
                wrapping: dependencies.mesh),
            careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client(
                wrapping: dependencies.mesh),
            careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client(wrapping: dependencies.mesh),
            careplansCarePlanCalculation: Acme_Careplans_V1_CarePlanCalculationService.Client(
                wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            notificationsNotificationValidation: Acme_Notifications_V1_NotificationValidationService.Client(
                wrapping: dependencies.mesh),
            performersPerformerQuery: Acme_Performers_V1_PerformerQueryService.Client(wrapping: dependencies.mesh),
            prescriptionsPrescription: Acme_Prescriptions_V1_PrescriptionService.Client(wrapping: dependencies.mesh),
            seatingSeatMap: Acme_Seating_V1_SeatMapService.Client(wrapping: dependencies.mesh)
        )
        let appointmentEndpoint = AppointmentEndpoint(
            dependencies: dependencies,
            appointmentsAppointmentQuery: Acme_Appointments_V1_AppointmentQueryService.Client(
                wrapping: dependencies.mesh),
            appointmentsClinicSlotCalculation: Acme_Appointments_V1_ClinicSlotCalculationService.Client(
                wrapping: dependencies.mesh),
            appointmentsClinicSlotValidation: Acme_Appointments_V1_ClinicSlotValidationService.Client(
                wrapping: dependencies.mesh),
            appointmentsProviderQuery: Acme_Appointments_V1_ProviderQueryService.Client(wrapping: dependencies.mesh),
            appointmentsProviderValidation: Acme_Appointments_V1_ProviderValidationService.Client(
                wrapping: dependencies.mesh),
            featureflagsFeatureFlagValidation: Acme_Featureflags_V1_FeatureFlagValidationService.Client(
                wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            prescriptionsMedicationQuery: Acme_Prescriptions_V1_MedicationQueryService.Client(
                wrapping: dependencies.mesh),
            showsShowQuery: Acme_Shows_V1_ShowQueryService.Client(wrapping: dependencies.mesh),
            telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client(wrapping: dependencies.mesh),
            telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client(
                wrapping: dependencies.mesh)
        )
        let appointmentValidationEndpoint = AppointmentValidationEndpoint(
            dependencies: dependencies,
            auditAuditEventQuery: Acme_Audit_V1_AuditEventQueryService.Client(wrapping: dependencies.mesh),
            authorizationAccessPolicy: Acme_Authorization_V1_AccessPolicyService.Client(wrapping: dependencies.mesh),
            authorizationAccessPolicyQuery: Acme_Authorization_V1_AccessPolicyQueryService.Client(
                wrapping: dependencies.mesh),
            authorizationAccessPolicyValidation: Acme_Authorization_V1_AccessPolicyValidationService.Client(
                wrapping: dependencies.mesh),
            careplansCareGoalQuery: Acme_Careplans_V1_CareGoalQueryService.Client(wrapping: dependencies.mesh),
            careplansCareGoalValidation: Acme_Careplans_V1_CareGoalValidationService.Client(
                wrapping: dependencies.mesh),
            careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            ledgerLedgerAccount: Acme_Ledger_V1_LedgerAccountService.Client(wrapping: dependencies.mesh),
            ledgerLedgerAccountQuery: Acme_Ledger_V1_LedgerAccountQueryService.Client(wrapping: dependencies.mesh),
            prescriptionsPrescriptionQuery: Acme_Prescriptions_V1_PrescriptionQueryService.Client(
                wrapping: dependencies.mesh),
            telehealthTriageValidation: Acme_Telehealth_V1_TriageValidationService.Client(wrapping: dependencies.mesh),
            telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client(wrapping: dependencies.mesh),
            telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client(
                wrapping: dependencies.mesh),
            telehealthVisitNoteQuery: Acme_Telehealth_V1_VisitNoteQueryService.Client(wrapping: dependencies.mesh)
        )
        let appointmentWorkflowEndpoint = AppointmentWorkflowEndpoint(
            dependencies: dependencies,
            appointmentsAppointmentApproval: Acme_Appointments_V1_AppointmentApprovalService.Client(
                wrapping: dependencies.mesh),
            appointmentsAppointmentQuery: Acme_Appointments_V1_AppointmentQueryService.Client(
                wrapping: dependencies.mesh),
            appointmentsClinicSlotValidation: Acme_Appointments_V1_ClinicSlotValidationService.Client(
                wrapping: dependencies.mesh),
            appointmentsProviderValidation: Acme_Appointments_V1_ProviderValidationService.Client(
                wrapping: dependencies.mesh),
            careplansCareGoalApproval: Acme_Careplans_V1_CareGoalApprovalService.Client(wrapping: dependencies.mesh),
            documentsDocumentQuery: Acme_Documents_V1_DocumentQueryService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            prescriptionsMedicationSync: Acme_Prescriptions_V1_MedicationSyncService.Client(
                wrapping: dependencies.mesh),
            prescriptionsRefillSync: Acme_Prescriptions_V1_RefillSyncService.Client(wrapping: dependencies.mesh),
            telehealthTriageApproval: Acme_Telehealth_V1_TriageApprovalService.Client(wrapping: dependencies.mesh),
            telehealthVisitNoteApproval: Acme_Telehealth_V1_VisitNoteApprovalService.Client(
                wrapping: dependencies.mesh),
            venuesVenueValidation: Acme_Venues_V1_VenueValidationService.Client(wrapping: dependencies.mesh)
        )
        let clinicSlotApprovalEndpoint = ClinicSlotApprovalEndpoint(
            dependencies: dependencies,
            appointmentsAppointmentApproval: Acme_Appointments_V1_AppointmentApprovalService.Client(
                wrapping: dependencies.mesh),
            appointmentsAppointmentQuery: Acme_Appointments_V1_AppointmentQueryService.Client(
                wrapping: dependencies.mesh),
            appointmentsProviderApproval: Acme_Appointments_V1_ProviderApprovalService.Client(
                wrapping: dependencies.mesh),
            appointmentsProviderValidation: Acme_Appointments_V1_ProviderValidationService.Client(
                wrapping: dependencies.mesh),
            careplansCarePlanWorkflow: Acme_Careplans_V1_CarePlanWorkflowService.Client(wrapping: dependencies.mesh),
            documentsDocument: Acme_Documents_V1_DocumentService.Client(wrapping: dependencies.mesh),
            featureflagsFeatureFlagValidation: Acme_Featureflags_V1_FeatureFlagValidationService.Client(
                wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            identityUserValidation: Acme_Identity_V1_UserValidationService.Client(wrapping: dependencies.mesh),
            metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client(
                wrapping: dependencies.mesh),
            prescriptionsPrescriptionSync: Acme_Prescriptions_V1_PrescriptionSyncService.Client(
                wrapping: dependencies.mesh),
            prescriptionsRefillReporting: Acme_Prescriptions_V1_RefillReportingService.Client(
                wrapping: dependencies.mesh),
            prescriptionsRefillWorkflow: Acme_Prescriptions_V1_RefillWorkflowService.Client(
                wrapping: dependencies.mesh),
            telehealthVideoVisitWorkflow: Acme_Telehealth_V1_VideoVisitWorkflowService.Client(
                wrapping: dependencies.mesh),
            telematicsTelemetryReadingQuery: Acme_Telematics_V1_TelemetryReadingQueryService.Client(
                wrapping: dependencies.mesh)
        )
        let clinicSlotCalculationEndpoint = ClinicSlotCalculationEndpoint(
            dependencies: dependencies,
            appointmentsAppointmentValidation: Acme_Appointments_V1_AppointmentValidationService.Client(
                wrapping: dependencies.mesh),
            broadcastsBroadcast: Acme_Broadcasts_V1_BroadcastService.Client(wrapping: dependencies.mesh),
            careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client(
                wrapping: dependencies.mesh),
            careplansCareGoalValidation: Acme_Careplans_V1_CareGoalValidationService.Client(
                wrapping: dependencies.mesh),
            careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client(wrapping: dependencies.mesh),
            concessionsConcessionStandCalculation: Acme_Concessions_V1_ConcessionStandCalculationService.Client(
                wrapping: dependencies.mesh),
            documentsDocumentQuery: Acme_Documents_V1_DocumentQueryService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            prescriptionsMedicationValidation: Acme_Prescriptions_V1_MedicationValidationService.Client(
                wrapping: dependencies.mesh),
            telehealthVisitNoteValidation: Acme_Telehealth_V1_VisitNoteValidationService.Client(
                wrapping: dependencies.mesh)
        )
        let clinicSlotValidationEndpoint = ClinicSlotValidationEndpoint(
            dependencies: dependencies,
            appointmentsClinicSlotCalculation: Acme_Appointments_V1_ClinicSlotCalculationService.Client(
                wrapping: dependencies.mesh),
            appointmentsProviderValidation: Acme_Appointments_V1_ProviderValidationService.Client(
                wrapping: dependencies.mesh),
            broadcastsBroadcast: Acme_Broadcasts_V1_BroadcastService.Client(wrapping: dependencies.mesh),
            careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client(
                wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            identityUserQuery: Acme_Identity_V1_UserQueryService.Client(wrapping: dependencies.mesh),
            ledgerLedgerAccountQuery: Acme_Ledger_V1_LedgerAccountQueryService.Client(wrapping: dependencies.mesh),
            prescriptionsPrescription: Acme_Prescriptions_V1_PrescriptionService.Client(wrapping: dependencies.mesh),
            showsShowCalculation: Acme_Shows_V1_ShowCalculationService.Client(wrapping: dependencies.mesh),
            venuesVenueValidation: Acme_Venues_V1_VenueValidationService.Client(wrapping: dependencies.mesh)
        )
        let clinicSlotWorkflowEndpoint = ClinicSlotWorkflowEndpoint(
            dependencies: dependencies,
            appointmentsAppointmentApproval: Acme_Appointments_V1_AppointmentApprovalService.Client(
                wrapping: dependencies.mesh),
            appointmentsAppointmentQuery: Acme_Appointments_V1_AppointmentQueryService.Client(
                wrapping: dependencies.mesh),
            appointmentsAppointmentValidation: Acme_Appointments_V1_AppointmentValidationService.Client(
                wrapping: dependencies.mesh),
            appointmentsAppointmentWorkflow: Acme_Appointments_V1_AppointmentWorkflowService.Client(
                wrapping: dependencies.mesh),
            appointmentsClinicSlotValidation: Acme_Appointments_V1_ClinicSlotValidationService.Client(
                wrapping: dependencies.mesh),
            appointmentsProviderWorkflow: Acme_Appointments_V1_ProviderWorkflowService.Client(
                wrapping: dependencies.mesh),
            authorizationAccessPolicyQuery: Acme_Authorization_V1_AccessPolicyQueryService.Client(
                wrapping: dependencies.mesh),
            authorizationAccessPolicyValidation: Acme_Authorization_V1_AccessPolicyValidationService.Client(
                wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            notificationsNotificationQuery: Acme_Notifications_V1_NotificationQueryService.Client(
                wrapping: dependencies.mesh),
            prescriptionsMedicationReporting: Acme_Prescriptions_V1_MedicationReportingService.Client(
                wrapping: dependencies.mesh),
            prescriptionsMedicationWorkflow: Acme_Prescriptions_V1_MedicationWorkflowService.Client(
                wrapping: dependencies.mesh),
            prescriptionsRefillSync: Acme_Prescriptions_V1_RefillSyncService.Client(wrapping: dependencies.mesh),
            promotionsPromotionCalculation: Acme_Promotions_V1_PromotionCalculationService.Client(
                wrapping: dependencies.mesh),
            searchSearchIndexValidation: Acme_Search_V1_SearchIndexValidationService.Client(
                wrapping: dependencies.mesh),
            telehealthVideoVisitWorkflow: Acme_Telehealth_V1_VideoVisitWorkflowService.Client(
                wrapping: dependencies.mesh),
            venuesVenue: Acme_Venues_V1_VenueService.Client(wrapping: dependencies.mesh),
            venuesVenueValidation: Acme_Venues_V1_VenueValidationService.Client(wrapping: dependencies.mesh)
        )
        let providerApprovalEndpoint = ProviderApprovalEndpoint(
            dependencies: dependencies,
            appointmentsAppointmentQuery: Acme_Appointments_V1_AppointmentQueryService.Client(
                wrapping: dependencies.mesh),
            appointmentsClinicSlotValidation: Acme_Appointments_V1_ClinicSlotValidationService.Client(
                wrapping: dependencies.mesh),
            appointmentsProviderQuery: Acme_Appointments_V1_ProviderQueryService.Client(wrapping: dependencies.mesh),
            appointmentsProviderValidation: Acme_Appointments_V1_ProviderValidationService.Client(
                wrapping: dependencies.mesh),
            careplansCareGoalApproval: Acme_Careplans_V1_CareGoalApprovalService.Client(wrapping: dependencies.mesh),
            careplansCarePlanApproval: Acme_Careplans_V1_CarePlanApprovalService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            itsmIncident: Acme_Itsm_V1_IncidentService.Client(wrapping: dependencies.mesh),
            ledgerLedgerAccount: Acme_Ledger_V1_LedgerAccountService.Client(wrapping: dependencies.mesh),
            prescriptionsPrescriptionApproval: Acme_Prescriptions_V1_PrescriptionApprovalService.Client(
                wrapping: dependencies.mesh),
            telehealthTriageApproval: Acme_Telehealth_V1_TriageApprovalService.Client(wrapping: dependencies.mesh),
            telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client(wrapping: dependencies.mesh)
        )
        let providerQueryEndpoint = ProviderQueryEndpoint(
            dependencies: dependencies,
            appointmentsAppointmentQuery: Acme_Appointments_V1_AppointmentQueryService.Client(
                wrapping: dependencies.mesh),
            appointmentsAppointmentValidation: Acme_Appointments_V1_AppointmentValidationService.Client(
                wrapping: dependencies.mesh),
            appointmentsClinicSlotCalculation: Acme_Appointments_V1_ClinicSlotCalculationService.Client(
                wrapping: dependencies.mesh),
            appointmentsProviderValidation: Acme_Appointments_V1_ProviderValidationService.Client(
                wrapping: dependencies.mesh),
            careplansCareGoalQuery: Acme_Careplans_V1_CareGoalQueryService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            identityUserValidation: Acme_Identity_V1_UserValidationService.Client(wrapping: dependencies.mesh),
            prescriptionsMedicationQuery: Acme_Prescriptions_V1_MedicationQueryService.Client(
                wrapping: dependencies.mesh),
            prescriptionsPrescription: Acme_Prescriptions_V1_PrescriptionService.Client(wrapping: dependencies.mesh),
            prescriptionsRefillCalculation: Acme_Prescriptions_V1_RefillCalculationService.Client(
                wrapping: dependencies.mesh),
            searchSearchIndexValidation: Acme_Search_V1_SearchIndexValidationService.Client(
                wrapping: dependencies.mesh),
            telehealthTriageValidation: Acme_Telehealth_V1_TriageValidationService.Client(wrapping: dependencies.mesh)
        )
        let providerValidationEndpoint = ProviderValidationEndpoint(
            dependencies: dependencies,
            appointmentsAppointmentValidation: Acme_Appointments_V1_AppointmentValidationService.Client(
                wrapping: dependencies.mesh),
            careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client(
                wrapping: dependencies.mesh),
            documentsDocumentQuery: Acme_Documents_V1_DocumentQueryService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            prescriptionsPrescriptionCalculation: Acme_Prescriptions_V1_PrescriptionCalculationService.Client(
                wrapping: dependencies.mesh),
            searchSearchIndex: Acme_Search_V1_SearchIndexService.Client(wrapping: dependencies.mesh),
            telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client(wrapping: dependencies.mesh),
            telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client(
                wrapping: dependencies.mesh),
            telehealthVideoVisitValidation: Acme_Telehealth_V1_VideoVisitValidationService.Client(
                wrapping: dependencies.mesh)
        )
        let providerWorkflowEndpoint = ProviderWorkflowEndpoint(
            dependencies: dependencies,
            appointmentsAppointment: Acme_Appointments_V1_AppointmentService.Client(wrapping: dependencies.mesh),
            appointmentsAppointmentApproval: Acme_Appointments_V1_AppointmentApprovalService.Client(
                wrapping: dependencies.mesh),
            appointmentsAppointmentQuery: Acme_Appointments_V1_AppointmentQueryService.Client(
                wrapping: dependencies.mesh),
            appointmentsAppointmentWorkflow: Acme_Appointments_V1_AppointmentWorkflowService.Client(
                wrapping: dependencies.mesh),
            appointmentsClinicSlotApproval: Acme_Appointments_V1_ClinicSlotApprovalService.Client(
                wrapping: dependencies.mesh),
            appointmentsClinicSlotCalculation: Acme_Appointments_V1_ClinicSlotCalculationService.Client(
                wrapping: dependencies.mesh),
            appointmentsClinicSlotValidation: Acme_Appointments_V1_ClinicSlotValidationService.Client(
                wrapping: dependencies.mesh),
            appointmentsProviderApproval: Acme_Appointments_V1_ProviderApprovalService.Client(
                wrapping: dependencies.mesh),
            auditAuditEvent: Acme_Audit_V1_AuditEventService.Client(wrapping: dependencies.mesh),
            careplansCarePlanWorkflow: Acme_Careplans_V1_CarePlanWorkflowService.Client(wrapping: dependencies.mesh),
            identityUser: Acme_Identity_V1_UserService.Client(wrapping: dependencies.mesh),
            notificationsNotificationQuery: Acme_Notifications_V1_NotificationQueryService.Client(
                wrapping: dependencies.mesh),
            prescriptionsPrescription: Acme_Prescriptions_V1_PrescriptionService.Client(wrapping: dependencies.mesh),
            prescriptionsPrescriptionReporting: Acme_Prescriptions_V1_PrescriptionReportingService.Client(
                wrapping: dependencies.mesh),
            searchSearchIndexValidation: Acme_Search_V1_SearchIndexValidationService.Client(
                wrapping: dependencies.mesh),
            sponsorshipsSponsorCalculation: Acme_Sponsorships_V1_SponsorCalculationService.Client(
                wrapping: dependencies.mesh)
        )
        return ServiceModule(
            services: [
                appointmentApprovalEndpoint,
                appointmentQueryEndpoint,
                appointmentEndpoint,
                appointmentValidationEndpoint,
                appointmentWorkflowEndpoint,
                clinicSlotApprovalEndpoint,
                clinicSlotCalculationEndpoint,
                clinicSlotValidationEndpoint,
                clinicSlotWorkflowEndpoint,
                providerApprovalEndpoint,
                providerQueryEndpoint,
                providerValidationEndpoint,
                providerWorkflowEndpoint,
            ],
            workers: [
                { try await appointmentApprovalEndpoint.runFollowUps() },
                { try await appointmentEndpoint.runFollowUps() },
                { try await appointmentWorkflowEndpoint.runFollowUps() },
                { try await clinicSlotCalculationEndpoint.runFollowUps() },
                { try await clinicSlotWorkflowEndpoint.runFollowUps() },
                { try await providerQueryEndpoint.runFollowUps() },
                { try await providerWorkflowEndpoint.runFollowUps() },
            ]
        )
    }
}
