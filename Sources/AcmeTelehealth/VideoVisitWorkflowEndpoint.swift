import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Runs the long-lived workflow that takes a video visit from start to finish.
final class VideoVisitWorkflowEndpoint: Acme_Telehealth_V1_VideoVisitWorkflowService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let careplansCareGoalApproval: Acme_Careplans_V1_CareGoalApprovalService.Client<MeshTransport>
    let careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>
    let careplansCarePlanApproval: Acme_Careplans_V1_CarePlanApprovalService.Client<MeshTransport>
    let careplansCarePlanWorkflow: Acme_Careplans_V1_CarePlanWorkflowService.Client<MeshTransport>
    let careplansVitalWorkflow: Acme_Careplans_V1_VitalWorkflowService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let patientsAllergyValidation: Acme_Patients_V1_AllergyValidationService.Client<MeshTransport>
    let patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>
    let patientsMedicalRecordValidation: Acme_Patients_V1_MedicalRecordValidationService.Client<MeshTransport>
    let patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client<MeshTransport>
    let telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client<MeshTransport>
    let telehealthVideoVisitApproval: Acme_Telehealth_V1_VideoVisitApprovalService.Client<MeshTransport>
    let telehealthVisitNoteApproval: Acme_Telehealth_V1_VisitNoteApprovalService.Client<MeshTransport>
    let venuesVenueQuery: Acme_Venues_V1_VenueQueryService.Client<MeshTransport>
    let listVideoVisitWorkflowsStep0:
        any RPCPort<Acme_Patients_V1_PreviewAllergyRequest, Acme_Patients_V1_PreviewAllergyResponse>
    let retryVideoVisitWorkflowStep0:
        @Sendable (Acme_Patients_V1_CheckMedicalRecordEligibilityRequest) async throws ->
            Acme_Patients_V1_CheckMedicalRecordEligibilityResponse
    let retryVideoVisitWorkflowStep1:
        [String:
            @Sendable (Acme_Telehealth_V1_ApproveVideoVisitRequest) async throws ->
            Acme_Telehealth_V1_ApproveVideoVisitResponse]

    init(
        dependencies: any Dependencies,
        careplansCareGoalApproval: Acme_Careplans_V1_CareGoalApprovalService.Client<MeshTransport>,
        careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>,
        careplansCarePlanApproval: Acme_Careplans_V1_CarePlanApprovalService.Client<MeshTransport>,
        careplansCarePlanWorkflow: Acme_Careplans_V1_CarePlanWorkflowService.Client<MeshTransport>,
        careplansVitalWorkflow: Acme_Careplans_V1_VitalWorkflowService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        patientsAllergyValidation: Acme_Patients_V1_AllergyValidationService.Client<MeshTransport>,
        patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>,
        patientsMedicalRecordValidation: Acme_Patients_V1_MedicalRecordValidationService.Client<MeshTransport>,
        patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client<MeshTransport>,
        telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client<MeshTransport>,
        telehealthVideoVisitApproval: Acme_Telehealth_V1_VideoVisitApprovalService.Client<MeshTransport>,
        telehealthVisitNoteApproval: Acme_Telehealth_V1_VisitNoteApprovalService.Client<MeshTransport>,
        venuesVenueQuery: Acme_Venues_V1_VenueQueryService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.careplansCareGoalApproval = careplansCareGoalApproval
        self.careplansCareGoalCalculation = careplansCareGoalCalculation
        self.careplansCarePlanApproval = careplansCarePlanApproval
        self.careplansCarePlanWorkflow = careplansCarePlanWorkflow
        self.careplansVitalWorkflow = careplansVitalWorkflow
        self.identityUser = identityUser
        self.patientsAllergyValidation = patientsAllergyValidation
        self.patientsMedicalRecordCalculation = patientsMedicalRecordCalculation
        self.patientsMedicalRecordValidation = patientsMedicalRecordValidation
        self.patientsPatientQuery = patientsPatientQuery
        self.telehealthVideoVisit = telehealthVideoVisit
        self.telehealthVideoVisitApproval = telehealthVideoVisitApproval
        self.telehealthVisitNoteApproval = telehealthVisitNoteApproval
        self.venuesVenueQuery = venuesVenueQuery
        self.listVideoVisitWorkflowsStep0 = ClosurePort<
            Acme_Patients_V1_PreviewAllergyRequest, Acme_Patients_V1_PreviewAllergyResponse
        >({ request in try await patientsAllergyValidation.previewAllergy(request) })
        self.retryVideoVisitWorkflowStep0 = { request in
            try await patientsMedicalRecordValidation.checkMedicalRecordEligibility(request)
        }
        self.retryVideoVisitWorkflowStep1 = [
            "primary": { request in try await telehealthVideoVisitApproval.approveVideoVisit(request) }
        ]
    }

    /// Advances a video visit.
    func advanceVideoVisitWorkflow(
        request: ServerRequest<Acme_Telehealth_V1_AdvanceVideoVisitWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_AdvanceVideoVisitWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processAdvanceVideoVisitWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Cancels a video visit.
    func cancelVideoVisitWorkflow(
        request: ServerRequest<Acme_Telehealth_V1_CancelVideoVisitWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_CancelVideoVisitWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCancelVideoVisitWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a video visit.
    func inspectVideoVisitWorkflow(
        request: ServerRequest<Acme_Telehealth_V1_InspectVideoVisitWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_InspectVideoVisitWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processInspectVideoVisitWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists video visits a page at a time.
    func listVideoVisitWorkflows(
        request: ServerRequest<Acme_Telehealth_V1_ListVideoVisitWorkflowsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_ListVideoVisitWorkflowsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListVideoVisitWorkflows(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Retrys a video visit.
    func retryVideoVisitWorkflow(
        request: ServerRequest<Acme_Telehealth_V1_RetryVideoVisitWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_RetryVideoVisitWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRetryVideoVisitWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Signals a video visit.
    func signalVideoVisitWorkflow(
        request: ServerRequest<Acme_Telehealth_V1_SignalVideoVisitWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_SignalVideoVisitWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSignalVideoVisitWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Starts a video visit.
    func startVideoVisitWorkflow(
        request: ServerRequest<Acme_Telehealth_V1_StartVideoVisitWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Telehealth_V1_StartVideoVisitWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processStartVideoVisitWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }
}
