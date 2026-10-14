import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Routes vitals through approval, with escalation and delegation.
final class VitalApprovalEndpoint: Acme_Careplans_V1_VitalApprovalService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let followUps = WorkQueue<Acme_Identity_V1_GetUserRequest>()
    let appointmentsAppointment: Acme_Appointments_V1_AppointmentService.Client<MeshTransport>
    let careplansCareGoalApproval: Acme_Careplans_V1_CareGoalApprovalService.Client<MeshTransport>
    let careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>
    let careplansCarePlanApproval: Acme_Careplans_V1_CarePlanApprovalService.Client<MeshTransport>
    let careplansCarePlanCalculation: Acme_Careplans_V1_CarePlanCalculationService.Client<MeshTransport>
    let careplansCarePlanWorkflow: Acme_Careplans_V1_CarePlanWorkflowService.Client<MeshTransport>
    let careplansVitalCalculation: Acme_Careplans_V1_VitalCalculationService.Client<MeshTransport>
    let careplansVitalReporting: Acme_Careplans_V1_VitalReportingService.Client<MeshTransport>
    let featureflagsFeatureFlagQuery: Acme_Featureflags_V1_FeatureFlagQueryService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client<MeshTransport>
    let notificationsNotification: Acme_Notifications_V1_NotificationService.Client<MeshTransport>
    let patientsPatientCalculation: Acme_Patients_V1_PatientCalculationService.Client<MeshTransport>
    let prescriptionsMedicationCalculation: Acme_Prescriptions_V1_MedicationCalculationService.Client<MeshTransport>
    let prescriptionsPrescription: Acme_Prescriptions_V1_PrescriptionService.Client<MeshTransport>
    let prescriptionsPrescriptionQuery: Acme_Prescriptions_V1_PrescriptionQueryService.Client<MeshTransport>
    let prescriptionsRefillCalculation: Acme_Prescriptions_V1_RefillCalculationService.Client<MeshTransport>
    let telematicsTelemetryReadingCalculation:
        Acme_Telematics_V1_TelemetryReadingCalculationService.Client<MeshTransport>
    let approveVitalStep0: any RPCPort<Acme_Careplans_V1_QuoteCarePlanRequest, Acme_Careplans_V1_QuoteCarePlanResponse>
    let commentVitalApprovalStep0:
        @Sendable (Acme_Careplans_V1_DelegateCarePlanApprovalRequest) async throws ->
            Acme_Careplans_V1_DelegateCarePlanApprovalResponse
    let commentVitalApprovalStep1:
        [String:
            @Sendable (Acme_Metrics_V1_NormalizeMetricSeriesRequest) async throws ->
            Acme_Metrics_V1_NormalizeMetricSeriesResponse]

    init(
        dependencies: any Dependencies,
        appointmentsAppointment: Acme_Appointments_V1_AppointmentService.Client<MeshTransport>,
        careplansCareGoalApproval: Acme_Careplans_V1_CareGoalApprovalService.Client<MeshTransport>,
        careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>,
        careplansCarePlanApproval: Acme_Careplans_V1_CarePlanApprovalService.Client<MeshTransport>,
        careplansCarePlanCalculation: Acme_Careplans_V1_CarePlanCalculationService.Client<MeshTransport>,
        careplansCarePlanWorkflow: Acme_Careplans_V1_CarePlanWorkflowService.Client<MeshTransport>,
        careplansVitalCalculation: Acme_Careplans_V1_VitalCalculationService.Client<MeshTransport>,
        careplansVitalReporting: Acme_Careplans_V1_VitalReportingService.Client<MeshTransport>,
        featureflagsFeatureFlagQuery: Acme_Featureflags_V1_FeatureFlagQueryService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client<MeshTransport>,
        notificationsNotification: Acme_Notifications_V1_NotificationService.Client<MeshTransport>,
        patientsPatientCalculation: Acme_Patients_V1_PatientCalculationService.Client<MeshTransport>,
        prescriptionsMedicationCalculation: Acme_Prescriptions_V1_MedicationCalculationService.Client<MeshTransport>,
        prescriptionsPrescription: Acme_Prescriptions_V1_PrescriptionService.Client<MeshTransport>,
        prescriptionsPrescriptionQuery: Acme_Prescriptions_V1_PrescriptionQueryService.Client<MeshTransport>,
        prescriptionsRefillCalculation: Acme_Prescriptions_V1_RefillCalculationService.Client<MeshTransport>,
        telematicsTelemetryReadingCalculation: Acme_Telematics_V1_TelemetryReadingCalculationService.Client<
            MeshTransport
        >
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.appointmentsAppointment = appointmentsAppointment
        self.careplansCareGoalApproval = careplansCareGoalApproval
        self.careplansCareGoalCalculation = careplansCareGoalCalculation
        self.careplansCarePlanApproval = careplansCarePlanApproval
        self.careplansCarePlanCalculation = careplansCarePlanCalculation
        self.careplansCarePlanWorkflow = careplansCarePlanWorkflow
        self.careplansVitalCalculation = careplansVitalCalculation
        self.careplansVitalReporting = careplansVitalReporting
        self.featureflagsFeatureFlagQuery = featureflagsFeatureFlagQuery
        self.identityUser = identityUser
        self.metricsMetricSeriesValidation = metricsMetricSeriesValidation
        self.notificationsNotification = notificationsNotification
        self.patientsPatientCalculation = patientsPatientCalculation
        self.prescriptionsMedicationCalculation = prescriptionsMedicationCalculation
        self.prescriptionsPrescription = prescriptionsPrescription
        self.prescriptionsPrescriptionQuery = prescriptionsPrescriptionQuery
        self.prescriptionsRefillCalculation = prescriptionsRefillCalculation
        self.telematicsTelemetryReadingCalculation = telematicsTelemetryReadingCalculation
        self.approveVitalStep0 = ClosurePort<
            Acme_Careplans_V1_QuoteCarePlanRequest, Acme_Careplans_V1_QuoteCarePlanResponse
        >({ request in try await careplansCarePlanCalculation.quoteCarePlan(request) })
        self.commentVitalApprovalStep0 = { request in
            try await careplansCarePlanApproval.delegateCarePlanApproval(request)
        }
        self.commentVitalApprovalStep1 = [
            "primary": { request in try await metricsMetricSeriesValidation.normalizeMetricSeries(request) }
        ]
    }

    /// Resolve follow-up ownership outside the RPC's lifetime.
    func runFollowUps() async throws {
        for await event in followUps.events {
            try Task.checkCancellation()
            do {
                let user = try await self.identityUser.getUser(event)
                logger.info("Follow-up resolved", metadata: ["user": .string(user.user.userID)])
            } catch {
                logger.error("Follow-up failed", metadata: ["error": .string(String(describing: error))])
            }
        }
    }
}
