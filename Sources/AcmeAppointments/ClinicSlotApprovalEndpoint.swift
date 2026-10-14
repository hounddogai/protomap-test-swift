import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Routes clinic slots through approval, with escalation and delegation.
final class ClinicSlotApprovalEndpoint: Acme_Appointments_V1_ClinicSlotApprovalService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let appointmentsAppointmentApproval: Acme_Appointments_V1_AppointmentApprovalService.Client<MeshTransport>
    let appointmentsAppointmentQuery: Acme_Appointments_V1_AppointmentQueryService.Client<MeshTransport>
    let appointmentsProviderApproval: Acme_Appointments_V1_ProviderApprovalService.Client<MeshTransport>
    let appointmentsProviderValidation: Acme_Appointments_V1_ProviderValidationService.Client<MeshTransport>
    let careplansCarePlanWorkflow: Acme_Careplans_V1_CarePlanWorkflowService.Client<MeshTransport>
    let documentsDocument: Acme_Documents_V1_DocumentService.Client<MeshTransport>
    let featureflagsFeatureFlagValidation: Acme_Featureflags_V1_FeatureFlagValidationService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let identityUserValidation: Acme_Identity_V1_UserValidationService.Client<MeshTransport>
    let metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client<MeshTransport>
    let prescriptionsPrescriptionSync: Acme_Prescriptions_V1_PrescriptionSyncService.Client<MeshTransport>
    let prescriptionsRefillReporting: Acme_Prescriptions_V1_RefillReportingService.Client<MeshTransport>
    let prescriptionsRefillWorkflow: Acme_Prescriptions_V1_RefillWorkflowService.Client<MeshTransport>
    let telehealthVideoVisitWorkflow: Acme_Telehealth_V1_VideoVisitWorkflowService.Client<MeshTransport>
    let telematicsTelemetryReadingQuery: Acme_Telematics_V1_TelemetryReadingQueryService.Client<MeshTransport>
    let approveClinicSlotStep2:
        any RPCPort<Acme_Appointments_V1_CountAppointmentsRequest, Acme_Appointments_V1_CountAppointmentsResponse>
    let commentClinicSlotApprovalStep0:
        @Sendable (Acme_Featureflags_V1_ExplainFeatureFlagDecisionRequest) async throws ->
            Acme_Featureflags_V1_ExplainFeatureFlagDecisionResponse
    let delegateClinicSlotApprovalStep0:
        [String:
            @Sendable (Acme_Appointments_V1_EscalateProviderRequest) async throws ->
            Acme_Appointments_V1_EscalateProviderResponse]

    init(
        dependencies: any Dependencies,
        appointmentsAppointmentApproval: Acme_Appointments_V1_AppointmentApprovalService.Client<MeshTransport>,
        appointmentsAppointmentQuery: Acme_Appointments_V1_AppointmentQueryService.Client<MeshTransport>,
        appointmentsProviderApproval: Acme_Appointments_V1_ProviderApprovalService.Client<MeshTransport>,
        appointmentsProviderValidation: Acme_Appointments_V1_ProviderValidationService.Client<MeshTransport>,
        careplansCarePlanWorkflow: Acme_Careplans_V1_CarePlanWorkflowService.Client<MeshTransport>,
        documentsDocument: Acme_Documents_V1_DocumentService.Client<MeshTransport>,
        featureflagsFeatureFlagValidation: Acme_Featureflags_V1_FeatureFlagValidationService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        identityUserValidation: Acme_Identity_V1_UserValidationService.Client<MeshTransport>,
        metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client<MeshTransport>,
        prescriptionsPrescriptionSync: Acme_Prescriptions_V1_PrescriptionSyncService.Client<MeshTransport>,
        prescriptionsRefillReporting: Acme_Prescriptions_V1_RefillReportingService.Client<MeshTransport>,
        prescriptionsRefillWorkflow: Acme_Prescriptions_V1_RefillWorkflowService.Client<MeshTransport>,
        telehealthVideoVisitWorkflow: Acme_Telehealth_V1_VideoVisitWorkflowService.Client<MeshTransport>,
        telematicsTelemetryReadingQuery: Acme_Telematics_V1_TelemetryReadingQueryService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.appointmentsAppointmentApproval = appointmentsAppointmentApproval
        self.appointmentsAppointmentQuery = appointmentsAppointmentQuery
        self.appointmentsProviderApproval = appointmentsProviderApproval
        self.appointmentsProviderValidation = appointmentsProviderValidation
        self.careplansCarePlanWorkflow = careplansCarePlanWorkflow
        self.documentsDocument = documentsDocument
        self.featureflagsFeatureFlagValidation = featureflagsFeatureFlagValidation
        self.identityUser = identityUser
        self.identityUserValidation = identityUserValidation
        self.metricsMetricSeriesValidation = metricsMetricSeriesValidation
        self.prescriptionsPrescriptionSync = prescriptionsPrescriptionSync
        self.prescriptionsRefillReporting = prescriptionsRefillReporting
        self.prescriptionsRefillWorkflow = prescriptionsRefillWorkflow
        self.telehealthVideoVisitWorkflow = telehealthVideoVisitWorkflow
        self.telematicsTelemetryReadingQuery = telematicsTelemetryReadingQuery
        self.approveClinicSlotStep2 = ClosurePort<
            Acme_Appointments_V1_CountAppointmentsRequest, Acme_Appointments_V1_CountAppointmentsResponse
        >({ request in try await appointmentsAppointmentQuery.countAppointments(request) })
        self.commentClinicSlotApprovalStep0 = { request in
            try await featureflagsFeatureFlagValidation.explainFeatureFlagDecision(request)
        }
        self.delegateClinicSlotApprovalStep0 = [
            "primary": { request in try await appointmentsProviderApproval.escalateProvider(request) }
        ]
    }
}
