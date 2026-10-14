import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Runs the long-lived workflow that takes a visit note from start to finish.
final class VisitNoteWorkflowEndpoint: Acme_Telehealth_V1_VisitNoteWorkflowService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let anomaliesAnomalyQuery: Acme_Anomalies_V1_AnomalyQueryService.Client<MeshTransport>
    let appointmentsClinicSlotValidation: Acme_Appointments_V1_ClinicSlotValidationService.Client<MeshTransport>
    let appointmentsProviderQuery: Acme_Appointments_V1_ProviderQueryService.Client<MeshTransport>
    let contentArticle: Acme_Content_V1_ArticleService.Client<MeshTransport>
    let driversDriver: Acme_Drivers_V1_DriverService.Client<MeshTransport>
    let featureflagsFeatureFlag: Acme_Featureflags_V1_FeatureFlagService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>
    let patientsPatient: Acme_Patients_V1_PatientService.Client<MeshTransport>
    let patientsPatientValidation: Acme_Patients_V1_PatientValidationService.Client<MeshTransport>
    let telehealthVideoVisitApproval: Acme_Telehealth_V1_VideoVisitApprovalService.Client<MeshTransport>
    let telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client<MeshTransport>
    let telehealthVideoVisitValidation: Acme_Telehealth_V1_VideoVisitValidationService.Client<MeshTransport>
    let telehealthVideoVisitWorkflow: Acme_Telehealth_V1_VideoVisitWorkflowService.Client<MeshTransport>
    let telehealthVisitNoteCalculation: Acme_Telehealth_V1_VisitNoteCalculationService.Client<MeshTransport>
    let telehealthVisitNoteQuery: Acme_Telehealth_V1_VisitNoteQueryService.Client<MeshTransport>
    let venuesVenue: Acme_Venues_V1_VenueService.Client<MeshTransport>
    let cancelVisitNoteWorkflowStep1:
        @Sendable (Acme_Content_V1_BatchGetArticlesRequest) async throws -> Acme_Content_V1_BatchGetArticlesResponse
    let listVisitNoteWorkflowsStep0:
        [String:
            @Sendable (Acme_Featureflags_V1_ListFeatureFlagsRequest) async throws ->
            Acme_Featureflags_V1_ListFeatureFlagsResponse]

    init(
        dependencies: any Dependencies,
        anomaliesAnomalyQuery: Acme_Anomalies_V1_AnomalyQueryService.Client<MeshTransport>,
        appointmentsClinicSlotValidation: Acme_Appointments_V1_ClinicSlotValidationService.Client<MeshTransport>,
        appointmentsProviderQuery: Acme_Appointments_V1_ProviderQueryService.Client<MeshTransport>,
        contentArticle: Acme_Content_V1_ArticleService.Client<MeshTransport>,
        driversDriver: Acme_Drivers_V1_DriverService.Client<MeshTransport>,
        featureflagsFeatureFlag: Acme_Featureflags_V1_FeatureFlagService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>,
        patientsPatient: Acme_Patients_V1_PatientService.Client<MeshTransport>,
        patientsPatientValidation: Acme_Patients_V1_PatientValidationService.Client<MeshTransport>,
        telehealthVideoVisitApproval: Acme_Telehealth_V1_VideoVisitApprovalService.Client<MeshTransport>,
        telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client<MeshTransport>,
        telehealthVideoVisitValidation: Acme_Telehealth_V1_VideoVisitValidationService.Client<MeshTransport>,
        telehealthVideoVisitWorkflow: Acme_Telehealth_V1_VideoVisitWorkflowService.Client<MeshTransport>,
        telehealthVisitNoteCalculation: Acme_Telehealth_V1_VisitNoteCalculationService.Client<MeshTransport>,
        telehealthVisitNoteQuery: Acme_Telehealth_V1_VisitNoteQueryService.Client<MeshTransport>,
        venuesVenue: Acme_Venues_V1_VenueService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.anomaliesAnomalyQuery = anomaliesAnomalyQuery
        self.appointmentsClinicSlotValidation = appointmentsClinicSlotValidation
        self.appointmentsProviderQuery = appointmentsProviderQuery
        self.contentArticle = contentArticle
        self.driversDriver = driversDriver
        self.featureflagsFeatureFlag = featureflagsFeatureFlag
        self.identityUser = identityUser
        self.patientsMedicalRecordCalculation = patientsMedicalRecordCalculation
        self.patientsPatient = patientsPatient
        self.patientsPatientValidation = patientsPatientValidation
        self.telehealthVideoVisitApproval = telehealthVideoVisitApproval
        self.telehealthVideoVisitCalculation = telehealthVideoVisitCalculation
        self.telehealthVideoVisitValidation = telehealthVideoVisitValidation
        self.telehealthVideoVisitWorkflow = telehealthVideoVisitWorkflow
        self.telehealthVisitNoteCalculation = telehealthVisitNoteCalculation
        self.telehealthVisitNoteQuery = telehealthVisitNoteQuery
        self.venuesVenue = venuesVenue
        self.cancelVisitNoteWorkflowStep1 = { request in try await contentArticle.batchGetArticles(request) }
        self.listVisitNoteWorkflowsStep0 = [
            "primary": { request in try await featureflagsFeatureFlag.listFeatureFlags(request) }
        ]
    }

    /// Advances a visit note.
    func advanceVisitNoteWorkflow(
        request: ServerRequest<Acme_Telehealth_V1_AdvanceVisitNoteWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_AdvanceVisitNoteWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processAdvanceVisitNoteWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Cancels a visit note.
    func cancelVisitNoteWorkflow(
        request: ServerRequest<Acme_Telehealth_V1_CancelVisitNoteWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_CancelVisitNoteWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCancelVisitNoteWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a visit note.
    func inspectVisitNoteWorkflow(
        request: ServerRequest<Acme_Telehealth_V1_InspectVisitNoteWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_InspectVisitNoteWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processInspectVisitNoteWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists visit notes a page at a time.
    func listVisitNoteWorkflows(
        request: ServerRequest<Acme_Telehealth_V1_ListVisitNoteWorkflowsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_ListVisitNoteWorkflowsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListVisitNoteWorkflows(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Pauses a visit note.
    func pauseVisitNoteWorkflow(
        request: ServerRequest<Acme_Telehealth_V1_PauseVisitNoteWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_PauseVisitNoteWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processPauseVisitNoteWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Resumes a visit note.
    func resumeVisitNoteWorkflow(
        request: ServerRequest<Acme_Telehealth_V1_ResumeVisitNoteWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_ResumeVisitNoteWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processResumeVisitNoteWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Retrys a visit note.
    func retryVisitNoteWorkflow(
        request: ServerRequest<Acme_Telehealth_V1_RetryVisitNoteWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_RetryVisitNoteWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRetryVisitNoteWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Signals a visit note.
    func signalVisitNoteWorkflow(
        request: ServerRequest<Acme_Telehealth_V1_SignalVisitNoteWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_SignalVisitNoteWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSignalVisitNoteWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Starts a visit note.
    func startVisitNoteWorkflow(
        request: ServerRequest<Acme_Telehealth_V1_StartVisitNoteWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_StartVisitNoteWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processStartVisitNoteWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }
}
