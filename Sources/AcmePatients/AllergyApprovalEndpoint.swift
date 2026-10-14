import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Routes allergies through approval, with escalation and delegation.
final class AllergyApprovalEndpoint: Acme_Patients_V1_AllergyApprovalService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let appointmentsAppointmentWorkflow: Acme_Appointments_V1_AppointmentWorkflowService.Client<MeshTransport>
    let authorizationAccessPolicyQuery: Acme_Authorization_V1_AccessPolicyQueryService.Client<MeshTransport>
    let careplansCareGoalWorkflow: Acme_Careplans_V1_CareGoalWorkflowService.Client<MeshTransport>
    let careplansVitalWorkflow: Acme_Careplans_V1_VitalWorkflowService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let patientsAllergyImport: Acme_Patients_V1_AllergyImportService.Client<MeshTransport>
    let patientsAllergyReporting: Acme_Patients_V1_AllergyReportingService.Client<MeshTransport>
    let patientsMedicalRecordApproval: Acme_Patients_V1_MedicalRecordApprovalService.Client<MeshTransport>
    let patientsMedicalRecordReporting: Acme_Patients_V1_MedicalRecordReportingService.Client<MeshTransport>
    let patientsMedicalRecordSync: Acme_Patients_V1_MedicalRecordSyncService.Client<MeshTransport>
    let patientsMedicalRecordValidation: Acme_Patients_V1_MedicalRecordValidationService.Client<MeshTransport>
    let patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client<MeshTransport>
    let patientsPatientWorkflow: Acme_Patients_V1_PatientWorkflowService.Client<MeshTransport>
    let pipelinesPipelineCalculation: Acme_Pipelines_V1_PipelineCalculationService.Client<MeshTransport>
    let prescriptionsPrescriptionSync: Acme_Prescriptions_V1_PrescriptionSyncService.Client<MeshTransport>
    let prescriptionsRefillSync: Acme_Prescriptions_V1_RefillSyncService.Client<MeshTransport>
    let venuesVenueQuery: Acme_Venues_V1_VenueQueryService.Client<MeshTransport>
    let venuesVenueValidation: Acme_Venues_V1_VenueValidationService.Client<MeshTransport>
    let approveAllergyStep0:
        any RPCPort<Acme_Patients_V1_SummarizePatientsRequest, Acme_Patients_V1_SummarizePatientsResponse>
    let commentAllergyApprovalStep0:
        @Sendable (Acme_Patients_V1_ReconcileMedicalRecordsRequest) async throws ->
            Acme_Patients_V1_ReconcileMedicalRecordsResponse
    let commentAllergyApprovalStep1:
        [String:
            @Sendable (Acme_Careplans_V1_CancelCareGoalWorkflowRequest) async throws ->
            Acme_Careplans_V1_CancelCareGoalWorkflowResponse]

    init(
        dependencies: any Dependencies,
        appointmentsAppointmentWorkflow: Acme_Appointments_V1_AppointmentWorkflowService.Client<MeshTransport>,
        authorizationAccessPolicyQuery: Acme_Authorization_V1_AccessPolicyQueryService.Client<MeshTransport>,
        careplansCareGoalWorkflow: Acme_Careplans_V1_CareGoalWorkflowService.Client<MeshTransport>,
        careplansVitalWorkflow: Acme_Careplans_V1_VitalWorkflowService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        patientsAllergyImport: Acme_Patients_V1_AllergyImportService.Client<MeshTransport>,
        patientsAllergyReporting: Acme_Patients_V1_AllergyReportingService.Client<MeshTransport>,
        patientsMedicalRecordApproval: Acme_Patients_V1_MedicalRecordApprovalService.Client<MeshTransport>,
        patientsMedicalRecordReporting: Acme_Patients_V1_MedicalRecordReportingService.Client<MeshTransport>,
        patientsMedicalRecordSync: Acme_Patients_V1_MedicalRecordSyncService.Client<MeshTransport>,
        patientsMedicalRecordValidation: Acme_Patients_V1_MedicalRecordValidationService.Client<MeshTransport>,
        patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client<MeshTransport>,
        patientsPatientWorkflow: Acme_Patients_V1_PatientWorkflowService.Client<MeshTransport>,
        pipelinesPipelineCalculation: Acme_Pipelines_V1_PipelineCalculationService.Client<MeshTransport>,
        prescriptionsPrescriptionSync: Acme_Prescriptions_V1_PrescriptionSyncService.Client<MeshTransport>,
        prescriptionsRefillSync: Acme_Prescriptions_V1_RefillSyncService.Client<MeshTransport>,
        venuesVenueQuery: Acme_Venues_V1_VenueQueryService.Client<MeshTransport>,
        venuesVenueValidation: Acme_Venues_V1_VenueValidationService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.appointmentsAppointmentWorkflow = appointmentsAppointmentWorkflow
        self.authorizationAccessPolicyQuery = authorizationAccessPolicyQuery
        self.careplansCareGoalWorkflow = careplansCareGoalWorkflow
        self.careplansVitalWorkflow = careplansVitalWorkflow
        self.identityUser = identityUser
        self.patientsAllergyImport = patientsAllergyImport
        self.patientsAllergyReporting = patientsAllergyReporting
        self.patientsMedicalRecordApproval = patientsMedicalRecordApproval
        self.patientsMedicalRecordReporting = patientsMedicalRecordReporting
        self.patientsMedicalRecordSync = patientsMedicalRecordSync
        self.patientsMedicalRecordValidation = patientsMedicalRecordValidation
        self.patientsPatientQuery = patientsPatientQuery
        self.patientsPatientWorkflow = patientsPatientWorkflow
        self.pipelinesPipelineCalculation = pipelinesPipelineCalculation
        self.prescriptionsPrescriptionSync = prescriptionsPrescriptionSync
        self.prescriptionsRefillSync = prescriptionsRefillSync
        self.venuesVenueQuery = venuesVenueQuery
        self.venuesVenueValidation = venuesVenueValidation
        self.approveAllergyStep0 = ClosurePort<
            Acme_Patients_V1_SummarizePatientsRequest, Acme_Patients_V1_SummarizePatientsResponse
        >({ request in try await patientsPatientQuery.summarizePatients(request) })
        self.commentAllergyApprovalStep0 = { request in
            try await patientsMedicalRecordSync.reconcileMedicalRecords(request)
        }
        self.commentAllergyApprovalStep1 = [
            "primary": { request in try await careplansCareGoalWorkflow.cancelCareGoalWorkflow(request) }
        ]
    }

    /// Approves an allergy.
    func approveAllergy(
        request: ServerRequest<Acme_Patients_V1_ApproveAllergyRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_ApproveAllergyResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processApproveAllergy(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Comments an allergy.
    func commentAllergyApproval(
        request: ServerRequest<Acme_Patients_V1_CommentAllergyApprovalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_CommentAllergyApprovalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCommentAllergyApproval(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Delegates an allergy.
    func delegateAllergyApproval(
        request: ServerRequest<Acme_Patients_V1_DelegateAllergyApprovalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_DelegateAllergyApprovalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processDelegateAllergyApproval(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Escalates an allergy.
    func escalateAllergy(
        request: ServerRequest<Acme_Patients_V1_EscalateAllergyRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_EscalateAllergyResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processEscalateAllergy(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns an allergy.
    func getAllergyApprovalStatus(
        request: ServerRequest<Acme_Patients_V1_GetAllergyApprovalStatusRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_GetAllergyApprovalStatusResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetAllergyApprovalStatus(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists allergies a page at a time.
    func listPendingAllergies(
        request: ServerRequest<Acme_Patients_V1_ListPendingAllergiesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_ListPendingAllergiesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListPendingAllergies(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Recalls an allergy.
    func recallAllergy(
        request: ServerRequest<Acme_Patients_V1_RecallAllergyRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_RecallAllergyResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRecallAllergy(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Rejects an allergy.
    func rejectAllergy(
        request: ServerRequest<Acme_Patients_V1_RejectAllergyRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_RejectAllergyResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRejectAllergy(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Submits an allergy.
    func submitAllergy(
        request: ServerRequest<Acme_Patients_V1_SubmitAllergyRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_SubmitAllergyResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSubmitAllergy(request.message)
            return ServerResponse(message: response)
        }
    }
}
