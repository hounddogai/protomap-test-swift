import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Runs the long-lived workflow that takes a care plan from start to finish.
final class CarePlanWorkflowEndpoint: Acme_Careplans_V1_CarePlanWorkflowService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let appointmentsClinicSlotValidation: Acme_Appointments_V1_ClinicSlotValidationService.Client<MeshTransport>
    let appointmentsProviderValidation: Acme_Appointments_V1_ProviderValidationService.Client<MeshTransport>
    let auditAuditEvent: Acme_Audit_V1_AuditEventService.Client<MeshTransport>
    let careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>
    let careplansCareGoalQuery: Acme_Careplans_V1_CareGoalQueryService.Client<MeshTransport>
    let careplansCareGoalValidation: Acme_Careplans_V1_CareGoalValidationService.Client<MeshTransport>
    let careplansCarePlanQuery: Acme_Careplans_V1_CarePlanQueryService.Client<MeshTransport>
    let careplansVitalLifecycle: Acme_Careplans_V1_VitalLifecycleService.Client<MeshTransport>
    let documentsDocument: Acme_Documents_V1_DocumentService.Client<MeshTransport>
    let featureflagsFeatureFlagQuery: Acme_Featureflags_V1_FeatureFlagQueryService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let patientsAllergyValidation: Acme_Patients_V1_AllergyValidationService.Client<MeshTransport>
    let patientsPatient: Acme_Patients_V1_PatientService.Client<MeshTransport>
    let prescriptionsPrescriptionCalculation: Acme_Prescriptions_V1_PrescriptionCalculationService.Client<MeshTransport>
    let telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client<MeshTransport>

    init(
        dependencies: any Dependencies,
        appointmentsClinicSlotValidation: Acme_Appointments_V1_ClinicSlotValidationService.Client<MeshTransport>,
        appointmentsProviderValidation: Acme_Appointments_V1_ProviderValidationService.Client<MeshTransport>,
        auditAuditEvent: Acme_Audit_V1_AuditEventService.Client<MeshTransport>,
        careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>,
        careplansCareGoalQuery: Acme_Careplans_V1_CareGoalQueryService.Client<MeshTransport>,
        careplansCareGoalValidation: Acme_Careplans_V1_CareGoalValidationService.Client<MeshTransport>,
        careplansCarePlanQuery: Acme_Careplans_V1_CarePlanQueryService.Client<MeshTransport>,
        careplansVitalLifecycle: Acme_Careplans_V1_VitalLifecycleService.Client<MeshTransport>,
        documentsDocument: Acme_Documents_V1_DocumentService.Client<MeshTransport>,
        featureflagsFeatureFlagQuery: Acme_Featureflags_V1_FeatureFlagQueryService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        patientsAllergyValidation: Acme_Patients_V1_AllergyValidationService.Client<MeshTransport>,
        patientsPatient: Acme_Patients_V1_PatientService.Client<MeshTransport>,
        prescriptionsPrescriptionCalculation: Acme_Prescriptions_V1_PrescriptionCalculationService.Client<
            MeshTransport
        >,
        telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.appointmentsClinicSlotValidation = appointmentsClinicSlotValidation
        self.appointmentsProviderValidation = appointmentsProviderValidation
        self.auditAuditEvent = auditAuditEvent
        self.careplansCareGoalCalculation = careplansCareGoalCalculation
        self.careplansCareGoalQuery = careplansCareGoalQuery
        self.careplansCareGoalValidation = careplansCareGoalValidation
        self.careplansCarePlanQuery = careplansCarePlanQuery
        self.careplansVitalLifecycle = careplansVitalLifecycle
        self.documentsDocument = documentsDocument
        self.featureflagsFeatureFlagQuery = featureflagsFeatureFlagQuery
        self.identityUser = identityUser
        self.patientsAllergyValidation = patientsAllergyValidation
        self.patientsPatient = patientsPatient
        self.prescriptionsPrescriptionCalculation = prescriptionsPrescriptionCalculation
        self.telehealthVideoVisitCalculation = telehealthVideoVisitCalculation
    }

    /// Advances a care plan.
    func advanceCarePlanWorkflow(
        request: ServerRequest<Acme_Careplans_V1_AdvanceCarePlanWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_AdvanceCarePlanWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processAdvanceCarePlanWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Cancels a care plan.
    func cancelCarePlanWorkflow(
        request: ServerRequest<Acme_Careplans_V1_CancelCarePlanWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_CancelCarePlanWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCancelCarePlanWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a care plan.
    func inspectCarePlanWorkflow(
        request: ServerRequest<Acme_Careplans_V1_InspectCarePlanWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_InspectCarePlanWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processInspectCarePlanWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists care plans a page at a time.
    func listCarePlanWorkflows(
        request: ServerRequest<Acme_Careplans_V1_ListCarePlanWorkflowsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_ListCarePlanWorkflowsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListCarePlanWorkflows(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Resumes a care plan.
    func resumeCarePlanWorkflow(
        request: ServerRequest<Acme_Careplans_V1_ResumeCarePlanWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_ResumeCarePlanWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processResumeCarePlanWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Signals a care plan.
    func signalCarePlanWorkflow(
        request: ServerRequest<Acme_Careplans_V1_SignalCarePlanWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_SignalCarePlanWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSignalCarePlanWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Starts a care plan.
    func startCarePlanWorkflow(
        request: ServerRequest<Acme_Careplans_V1_StartCarePlanWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_StartCarePlanWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processStartCarePlanWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }
}
