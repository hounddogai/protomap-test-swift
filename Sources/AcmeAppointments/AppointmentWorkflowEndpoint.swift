import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Runs the long-lived workflow that takes an appointment from start to finish.
final class AppointmentWorkflowEndpoint: Acme_Appointments_V1_AppointmentWorkflowService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let followUps = WorkQueue<Acme_Identity_V1_GetUserRequest>()
    let appointmentsAppointmentApproval: Acme_Appointments_V1_AppointmentApprovalService.Client<MeshTransport>
    let appointmentsAppointmentQuery: Acme_Appointments_V1_AppointmentQueryService.Client<MeshTransport>
    let appointmentsClinicSlotValidation: Acme_Appointments_V1_ClinicSlotValidationService.Client<MeshTransport>
    let appointmentsProviderValidation: Acme_Appointments_V1_ProviderValidationService.Client<MeshTransport>
    let careplansCareGoalApproval: Acme_Careplans_V1_CareGoalApprovalService.Client<MeshTransport>
    let documentsDocumentQuery: Acme_Documents_V1_DocumentQueryService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let prescriptionsMedicationSync: Acme_Prescriptions_V1_MedicationSyncService.Client<MeshTransport>
    let prescriptionsRefillSync: Acme_Prescriptions_V1_RefillSyncService.Client<MeshTransport>
    let telehealthTriageApproval: Acme_Telehealth_V1_TriageApprovalService.Client<MeshTransport>
    let telehealthVisitNoteApproval: Acme_Telehealth_V1_VisitNoteApprovalService.Client<MeshTransport>
    let venuesVenueValidation: Acme_Venues_V1_VenueValidationService.Client<MeshTransport>

    init(
        dependencies: any Dependencies,
        appointmentsAppointmentApproval: Acme_Appointments_V1_AppointmentApprovalService.Client<MeshTransport>,
        appointmentsAppointmentQuery: Acme_Appointments_V1_AppointmentQueryService.Client<MeshTransport>,
        appointmentsClinicSlotValidation: Acme_Appointments_V1_ClinicSlotValidationService.Client<MeshTransport>,
        appointmentsProviderValidation: Acme_Appointments_V1_ProviderValidationService.Client<MeshTransport>,
        careplansCareGoalApproval: Acme_Careplans_V1_CareGoalApprovalService.Client<MeshTransport>,
        documentsDocumentQuery: Acme_Documents_V1_DocumentQueryService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        prescriptionsMedicationSync: Acme_Prescriptions_V1_MedicationSyncService.Client<MeshTransport>,
        prescriptionsRefillSync: Acme_Prescriptions_V1_RefillSyncService.Client<MeshTransport>,
        telehealthTriageApproval: Acme_Telehealth_V1_TriageApprovalService.Client<MeshTransport>,
        telehealthVisitNoteApproval: Acme_Telehealth_V1_VisitNoteApprovalService.Client<MeshTransport>,
        venuesVenueValidation: Acme_Venues_V1_VenueValidationService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.appointmentsAppointmentApproval = appointmentsAppointmentApproval
        self.appointmentsAppointmentQuery = appointmentsAppointmentQuery
        self.appointmentsClinicSlotValidation = appointmentsClinicSlotValidation
        self.appointmentsProviderValidation = appointmentsProviderValidation
        self.careplansCareGoalApproval = careplansCareGoalApproval
        self.documentsDocumentQuery = documentsDocumentQuery
        self.identityUser = identityUser
        self.prescriptionsMedicationSync = prescriptionsMedicationSync
        self.prescriptionsRefillSync = prescriptionsRefillSync
        self.telehealthTriageApproval = telehealthTriageApproval
        self.telehealthVisitNoteApproval = telehealthVisitNoteApproval
        self.venuesVenueValidation = venuesVenueValidation
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

    /// Advances an appointment.
    func advanceAppointmentWorkflow(
        request: ServerRequest<Acme_Appointments_V1_AdvanceAppointmentWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_AdvanceAppointmentWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processAdvanceAppointmentWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Cancels an appointment.
    func cancelAppointmentWorkflow(
        request: ServerRequest<Acme_Appointments_V1_CancelAppointmentWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_CancelAppointmentWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCancelAppointmentWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns an appointment.
    func inspectAppointmentWorkflow(
        request: ServerRequest<Acme_Appointments_V1_InspectAppointmentWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_InspectAppointmentWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processInspectAppointmentWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Pauses an appointment.
    func pauseAppointmentWorkflow(
        request: ServerRequest<Acme_Appointments_V1_PauseAppointmentWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_PauseAppointmentWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processPauseAppointmentWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Resumes an appointment.
    func resumeAppointmentWorkflow(
        request: ServerRequest<Acme_Appointments_V1_ResumeAppointmentWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_ResumeAppointmentWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processResumeAppointmentWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Retrys an appointment.
    func retryAppointmentWorkflow(
        request: ServerRequest<Acme_Appointments_V1_RetryAppointmentWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_RetryAppointmentWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRetryAppointmentWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Starts an appointment.
    func startAppointmentWorkflow(
        request: ServerRequest<Acme_Appointments_V1_StartAppointmentWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_StartAppointmentWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processStartAppointmentWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }
}
