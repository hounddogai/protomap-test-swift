import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Runs the long-lived workflow that takes a triage from start to finish.
final class TriageWorkflowEndpoint: Acme_Telehealth_V1_TriageWorkflowService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let careplansCareGoalApproval: Acme_Careplans_V1_CareGoalApprovalService.Client<MeshTransport>
    let careplansCarePlanWorkflow: Acme_Careplans_V1_CarePlanWorkflowService.Client<MeshTransport>
    let careplansVitalApproval: Acme_Careplans_V1_VitalApprovalService.Client<MeshTransport>
    let careplansVitalWorkflow: Acme_Careplans_V1_VitalWorkflowService.Client<MeshTransport>
    let deliveriesDelivery: Acme_Deliveries_V1_DeliveryService.Client<MeshTransport>
    let fleetVehicle: Acme_Fleet_V1_VehicleService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let ledgerLedgerAccountValidation: Acme_Ledger_V1_LedgerAccountValidationService.Client<MeshTransport>
    let notificationsNotification: Acme_Notifications_V1_NotificationService.Client<MeshTransport>
    let patientsPatient: Acme_Patients_V1_PatientService.Client<MeshTransport>
    let patientsPatientCalculation: Acme_Patients_V1_PatientCalculationService.Client<MeshTransport>
    let patientsPatientValidation: Acme_Patients_V1_PatientValidationService.Client<MeshTransport>
    let telehealthTriageApproval: Acme_Telehealth_V1_TriageApprovalService.Client<MeshTransport>
    let telehealthVideoVisitWorkflow: Acme_Telehealth_V1_VideoVisitWorkflowService.Client<MeshTransport>
    let telehealthVisitNoteWorkflow: Acme_Telehealth_V1_VisitNoteWorkflowService.Client<MeshTransport>
    let venuesVenueQuery: Acme_Venues_V1_VenueQueryService.Client<MeshTransport>
    let inspectTriageWorkflowStep0:
        any RPCPort<Acme_Careplans_V1_SignalCarePlanWorkflowRequest, Acme_Careplans_V1_SignalCarePlanWorkflowResponse>
    let resumeTriageWorkflowStep0:
        @Sendable (Acme_Telehealth_V1_ListVideoVisitWorkflowsRequest) async throws ->
            Acme_Telehealth_V1_ListVideoVisitWorkflowsResponse
    let retryTriageWorkflowStep0:
        [String:
            @Sendable (Acme_Notifications_V1_CloneNotificationRequest) async throws ->
            Acme_Notifications_V1_CloneNotificationResponse]

    init(
        dependencies: any Dependencies,
        careplansCareGoalApproval: Acme_Careplans_V1_CareGoalApprovalService.Client<MeshTransport>,
        careplansCarePlanWorkflow: Acme_Careplans_V1_CarePlanWorkflowService.Client<MeshTransport>,
        careplansVitalApproval: Acme_Careplans_V1_VitalApprovalService.Client<MeshTransport>,
        careplansVitalWorkflow: Acme_Careplans_V1_VitalWorkflowService.Client<MeshTransport>,
        deliveriesDelivery: Acme_Deliveries_V1_DeliveryService.Client<MeshTransport>,
        fleetVehicle: Acme_Fleet_V1_VehicleService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        ledgerLedgerAccountValidation: Acme_Ledger_V1_LedgerAccountValidationService.Client<MeshTransport>,
        notificationsNotification: Acme_Notifications_V1_NotificationService.Client<MeshTransport>,
        patientsPatient: Acme_Patients_V1_PatientService.Client<MeshTransport>,
        patientsPatientCalculation: Acme_Patients_V1_PatientCalculationService.Client<MeshTransport>,
        patientsPatientValidation: Acme_Patients_V1_PatientValidationService.Client<MeshTransport>,
        telehealthTriageApproval: Acme_Telehealth_V1_TriageApprovalService.Client<MeshTransport>,
        telehealthVideoVisitWorkflow: Acme_Telehealth_V1_VideoVisitWorkflowService.Client<MeshTransport>,
        telehealthVisitNoteWorkflow: Acme_Telehealth_V1_VisitNoteWorkflowService.Client<MeshTransport>,
        venuesVenueQuery: Acme_Venues_V1_VenueQueryService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.careplansCareGoalApproval = careplansCareGoalApproval
        self.careplansCarePlanWorkflow = careplansCarePlanWorkflow
        self.careplansVitalApproval = careplansVitalApproval
        self.careplansVitalWorkflow = careplansVitalWorkflow
        self.deliveriesDelivery = deliveriesDelivery
        self.fleetVehicle = fleetVehicle
        self.identityUser = identityUser
        self.ledgerLedgerAccountValidation = ledgerLedgerAccountValidation
        self.notificationsNotification = notificationsNotification
        self.patientsPatient = patientsPatient
        self.patientsPatientCalculation = patientsPatientCalculation
        self.patientsPatientValidation = patientsPatientValidation
        self.telehealthTriageApproval = telehealthTriageApproval
        self.telehealthVideoVisitWorkflow = telehealthVideoVisitWorkflow
        self.telehealthVisitNoteWorkflow = telehealthVisitNoteWorkflow
        self.venuesVenueQuery = venuesVenueQuery
        self.inspectTriageWorkflowStep0 = ClosurePort<
            Acme_Careplans_V1_SignalCarePlanWorkflowRequest, Acme_Careplans_V1_SignalCarePlanWorkflowResponse
        >({ request in try await careplansCarePlanWorkflow.signalCarePlanWorkflow(request) })
        self.resumeTriageWorkflowStep0 = { request in
            try await telehealthVideoVisitWorkflow.listVideoVisitWorkflows(request)
        }
        self.retryTriageWorkflowStep0 = [
            "primary": { request in try await notificationsNotification.cloneNotification(request) }
        ]
    }

    /// Advances a triage.
    func advanceTriageWorkflow(
        request: ServerRequest<Acme_Telehealth_V1_AdvanceTriageWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_AdvanceTriageWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processAdvanceTriageWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Cancels a triage.
    func cancelTriageWorkflow(
        request: ServerRequest<Acme_Telehealth_V1_CancelTriageWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_CancelTriageWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCancelTriageWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a triage.
    func inspectTriageWorkflow(
        request: ServerRequest<Acme_Telehealth_V1_InspectTriageWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_InspectTriageWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processInspectTriageWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists triages a page at a time.
    func listTriageWorkflows(
        request: ServerRequest<Acme_Telehealth_V1_ListTriageWorkflowsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_ListTriageWorkflowsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListTriageWorkflows(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Pauses a triage.
    func pauseTriageWorkflow(
        request: ServerRequest<Acme_Telehealth_V1_PauseTriageWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_PauseTriageWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processPauseTriageWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Resumes a triage.
    func resumeTriageWorkflow(
        request: ServerRequest<Acme_Telehealth_V1_ResumeTriageWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_ResumeTriageWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processResumeTriageWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Retrys a triage.
    func retryTriageWorkflow(
        request: ServerRequest<Acme_Telehealth_V1_RetryTriageWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_RetryTriageWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRetryTriageWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Starts a triage.
    func startTriageWorkflow(
        request: ServerRequest<Acme_Telehealth_V1_StartTriageWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_StartTriageWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processStartTriageWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }
}
