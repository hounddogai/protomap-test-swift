import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Runs the long-lived workflow that takes a vital from start to finish.
final class VitalWorkflowEndpoint: Acme_Careplans_V1_VitalWorkflowService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let budgetingBudgetQuery: Acme_Budgeting_V1_BudgetQueryService.Client<MeshTransport>
    let careplansCarePlanApproval: Acme_Careplans_V1_CarePlanApprovalService.Client<MeshTransport>
    let careplansCarePlanWorkflow: Acme_Careplans_V1_CarePlanWorkflowService.Client<MeshTransport>
    let careplansVitalCalculation: Acme_Careplans_V1_VitalCalculationService.Client<MeshTransport>
    let careplansVitalLifecycle: Acme_Careplans_V1_VitalLifecycleService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let identityUserQuery: Acme_Identity_V1_UserQueryService.Client<MeshTransport>
    let notificationsNotificationValidation: Acme_Notifications_V1_NotificationValidationService.Client<MeshTransport>
    let patientsPatientCalculation: Acme_Patients_V1_PatientCalculationService.Client<MeshTransport>
    let patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client<MeshTransport>
    let prescriptionsRefillCalculation: Acme_Prescriptions_V1_RefillCalculationService.Client<MeshTransport>
    let telehealthTriageCalculation: Acme_Telehealth_V1_TriageCalculationService.Client<MeshTransport>
    let telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client<MeshTransport>
    let telehealthVideoVisitValidation: Acme_Telehealth_V1_VideoVisitValidationService.Client<MeshTransport>
    let startVitalWorkflowStep0:
        any RPCPort<Acme_Careplans_V1_SignalCarePlanWorkflowRequest, Acme_Careplans_V1_SignalCarePlanWorkflowResponse>

    init(
        dependencies: any Dependencies,
        budgetingBudgetQuery: Acme_Budgeting_V1_BudgetQueryService.Client<MeshTransport>,
        careplansCarePlanApproval: Acme_Careplans_V1_CarePlanApprovalService.Client<MeshTransport>,
        careplansCarePlanWorkflow: Acme_Careplans_V1_CarePlanWorkflowService.Client<MeshTransport>,
        careplansVitalCalculation: Acme_Careplans_V1_VitalCalculationService.Client<MeshTransport>,
        careplansVitalLifecycle: Acme_Careplans_V1_VitalLifecycleService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        identityUserQuery: Acme_Identity_V1_UserQueryService.Client<MeshTransport>,
        notificationsNotificationValidation: Acme_Notifications_V1_NotificationValidationService.Client<MeshTransport>,
        patientsPatientCalculation: Acme_Patients_V1_PatientCalculationService.Client<MeshTransport>,
        patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client<MeshTransport>,
        prescriptionsRefillCalculation: Acme_Prescriptions_V1_RefillCalculationService.Client<MeshTransport>,
        telehealthTriageCalculation: Acme_Telehealth_V1_TriageCalculationService.Client<MeshTransport>,
        telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client<MeshTransport>,
        telehealthVideoVisitValidation: Acme_Telehealth_V1_VideoVisitValidationService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.budgetingBudgetQuery = budgetingBudgetQuery
        self.careplansCarePlanApproval = careplansCarePlanApproval
        self.careplansCarePlanWorkflow = careplansCarePlanWorkflow
        self.careplansVitalCalculation = careplansVitalCalculation
        self.careplansVitalLifecycle = careplansVitalLifecycle
        self.identityUser = identityUser
        self.identityUserQuery = identityUserQuery
        self.notificationsNotificationValidation = notificationsNotificationValidation
        self.patientsPatientCalculation = patientsPatientCalculation
        self.patientsPatientQuery = patientsPatientQuery
        self.prescriptionsRefillCalculation = prescriptionsRefillCalculation
        self.telehealthTriageCalculation = telehealthTriageCalculation
        self.telehealthVideoVisit = telehealthVideoVisit
        self.telehealthVideoVisitValidation = telehealthVideoVisitValidation
        self.startVitalWorkflowStep0 = ClosurePort<
            Acme_Careplans_V1_SignalCarePlanWorkflowRequest, Acme_Careplans_V1_SignalCarePlanWorkflowResponse
        >({ request in try await careplansCarePlanWorkflow.signalCarePlanWorkflow(request) })
    }

    /// Advances a vital.
    func advanceVitalWorkflow(
        request: ServerRequest<Acme_Careplans_V1_AdvanceVitalWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_AdvanceVitalWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processAdvanceVitalWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Cancels a vital.
    func cancelVitalWorkflow(
        request: ServerRequest<Acme_Careplans_V1_CancelVitalWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_CancelVitalWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCancelVitalWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a vital.
    func inspectVitalWorkflow(
        request: ServerRequest<Acme_Careplans_V1_InspectVitalWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_InspectVitalWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processInspectVitalWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists vitals a page at a time.
    func listVitalWorkflows(
        request: ServerRequest<Acme_Careplans_V1_ListVitalWorkflowsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_ListVitalWorkflowsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListVitalWorkflows(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Pauses a vital.
    func pauseVitalWorkflow(
        request: ServerRequest<Acme_Careplans_V1_PauseVitalWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_PauseVitalWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processPauseVitalWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Resumes a vital.
    func resumeVitalWorkflow(
        request: ServerRequest<Acme_Careplans_V1_ResumeVitalWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_ResumeVitalWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processResumeVitalWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Retrys a vital.
    func retryVitalWorkflow(
        request: ServerRequest<Acme_Careplans_V1_RetryVitalWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_RetryVitalWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRetryVitalWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Starts a vital.
    func startVitalWorkflow(
        request: ServerRequest<Acme_Careplans_V1_StartVitalWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_StartVitalWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processStartVitalWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }
}
