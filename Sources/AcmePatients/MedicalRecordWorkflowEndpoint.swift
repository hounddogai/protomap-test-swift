import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Runs the long-lived workflow that takes a medical record from start to finish.
final class MedicalRecordWorkflowEndpoint: Acme_Patients_V1_MedicalRecordWorkflowService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let followUps = WorkQueue<Acme_Identity_V1_GetUserRequest>()
    let appointmentsProviderApproval: Acme_Appointments_V1_ProviderApprovalService.Client<MeshTransport>
    let careplansVitalReporting: Acme_Careplans_V1_VitalReportingService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client<MeshTransport>
    let patientsAllergyApproval: Acme_Patients_V1_AllergyApprovalService.Client<MeshTransport>
    let patientsAllergyReporting: Acme_Patients_V1_AllergyReportingService.Client<MeshTransport>
    let patientsAllergySync: Acme_Patients_V1_AllergySyncService.Client<MeshTransport>
    let patientsMedicalRecordApproval: Acme_Patients_V1_MedicalRecordApprovalService.Client<MeshTransport>
    let patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>
    let patientsMedicalRecordReporting: Acme_Patients_V1_MedicalRecordReportingService.Client<MeshTransport>
    let patientsMedicalRecordSync: Acme_Patients_V1_MedicalRecordSyncService.Client<MeshTransport>
    let patientsPatientApproval: Acme_Patients_V1_PatientApprovalService.Client<MeshTransport>
    let patientsPatientReporting: Acme_Patients_V1_PatientReportingService.Client<MeshTransport>
    let patientsPatientSync: Acme_Patients_V1_PatientSyncService.Client<MeshTransport>
    let patientsPatientWorkflow: Acme_Patients_V1_PatientWorkflowService.Client<MeshTransport>
    let performanceReviewQuery: Acme_Performance_V1_ReviewQueryService.Client<MeshTransport>
    let prescriptionsMedicationSync: Acme_Prescriptions_V1_MedicationSyncService.Client<MeshTransport>
    let searchSearchIndexQuery: Acme_Search_V1_SearchIndexQueryService.Client<MeshTransport>
    let venuesVenueQuery: Acme_Venues_V1_VenueQueryService.Client<MeshTransport>
    let inspectMedicalRecordWorkflowStep0:
        any RPCPort<Acme_Appointments_V1_ListPendingProvidersRequest, Acme_Appointments_V1_ListPendingProvidersResponse>
    let listMedicalRecordWorkflowsStep0:
        @Sendable (Acme_Patients_V1_ApproveAllergyRequest) async throws -> Acme_Patients_V1_ApproveAllergyResponse
    let listMedicalRecordWorkflowsStep1:
        [String:
            @Sendable (Acme_Patients_V1_RecallPatientRequest) async throws -> Acme_Patients_V1_RecallPatientResponse]

    init(
        dependencies: any Dependencies,
        appointmentsProviderApproval: Acme_Appointments_V1_ProviderApprovalService.Client<MeshTransport>,
        careplansVitalReporting: Acme_Careplans_V1_VitalReportingService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client<MeshTransport>,
        patientsAllergyApproval: Acme_Patients_V1_AllergyApprovalService.Client<MeshTransport>,
        patientsAllergyReporting: Acme_Patients_V1_AllergyReportingService.Client<MeshTransport>,
        patientsAllergySync: Acme_Patients_V1_AllergySyncService.Client<MeshTransport>,
        patientsMedicalRecordApproval: Acme_Patients_V1_MedicalRecordApprovalService.Client<MeshTransport>,
        patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>,
        patientsMedicalRecordReporting: Acme_Patients_V1_MedicalRecordReportingService.Client<MeshTransport>,
        patientsMedicalRecordSync: Acme_Patients_V1_MedicalRecordSyncService.Client<MeshTransport>,
        patientsPatientApproval: Acme_Patients_V1_PatientApprovalService.Client<MeshTransport>,
        patientsPatientReporting: Acme_Patients_V1_PatientReportingService.Client<MeshTransport>,
        patientsPatientSync: Acme_Patients_V1_PatientSyncService.Client<MeshTransport>,
        patientsPatientWorkflow: Acme_Patients_V1_PatientWorkflowService.Client<MeshTransport>,
        performanceReviewQuery: Acme_Performance_V1_ReviewQueryService.Client<MeshTransport>,
        prescriptionsMedicationSync: Acme_Prescriptions_V1_MedicationSyncService.Client<MeshTransport>,
        searchSearchIndexQuery: Acme_Search_V1_SearchIndexQueryService.Client<MeshTransport>,
        venuesVenueQuery: Acme_Venues_V1_VenueQueryService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.appointmentsProviderApproval = appointmentsProviderApproval
        self.careplansVitalReporting = careplansVitalReporting
        self.identityUser = identityUser
        self.metricsMetricSeriesValidation = metricsMetricSeriesValidation
        self.patientsAllergyApproval = patientsAllergyApproval
        self.patientsAllergyReporting = patientsAllergyReporting
        self.patientsAllergySync = patientsAllergySync
        self.patientsMedicalRecordApproval = patientsMedicalRecordApproval
        self.patientsMedicalRecordCalculation = patientsMedicalRecordCalculation
        self.patientsMedicalRecordReporting = patientsMedicalRecordReporting
        self.patientsMedicalRecordSync = patientsMedicalRecordSync
        self.patientsPatientApproval = patientsPatientApproval
        self.patientsPatientReporting = patientsPatientReporting
        self.patientsPatientSync = patientsPatientSync
        self.patientsPatientWorkflow = patientsPatientWorkflow
        self.performanceReviewQuery = performanceReviewQuery
        self.prescriptionsMedicationSync = prescriptionsMedicationSync
        self.searchSearchIndexQuery = searchSearchIndexQuery
        self.venuesVenueQuery = venuesVenueQuery
        self.inspectMedicalRecordWorkflowStep0 = ClosurePort<
            Acme_Appointments_V1_ListPendingProvidersRequest, Acme_Appointments_V1_ListPendingProvidersResponse
        >({ request in try await appointmentsProviderApproval.listPendingProviders(request) })
        self.listMedicalRecordWorkflowsStep0 = { request in try await patientsAllergyApproval.approveAllergy(request) }
        self.listMedicalRecordWorkflowsStep1 = [
            "primary": { request in try await patientsPatientApproval.recallPatient(request) }
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

    /// Advances a medical record.
    func advanceMedicalRecordWorkflow(
        request: ServerRequest<Acme_Patients_V1_AdvanceMedicalRecordWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_AdvanceMedicalRecordWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processAdvanceMedicalRecordWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Cancels a medical record.
    func cancelMedicalRecordWorkflow(
        request: ServerRequest<Acme_Patients_V1_CancelMedicalRecordWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_CancelMedicalRecordWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCancelMedicalRecordWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a medical record.
    func inspectMedicalRecordWorkflow(
        request: ServerRequest<Acme_Patients_V1_InspectMedicalRecordWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_InspectMedicalRecordWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processInspectMedicalRecordWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists medical records a page at a time.
    func listMedicalRecordWorkflows(
        request: ServerRequest<Acme_Patients_V1_ListMedicalRecordWorkflowsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_ListMedicalRecordWorkflowsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListMedicalRecordWorkflows(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Pauses a medical record.
    func pauseMedicalRecordWorkflow(
        request: ServerRequest<Acme_Patients_V1_PauseMedicalRecordWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_PauseMedicalRecordWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processPauseMedicalRecordWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Resumes a medical record.
    func resumeMedicalRecordWorkflow(
        request: ServerRequest<Acme_Patients_V1_ResumeMedicalRecordWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_ResumeMedicalRecordWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processResumeMedicalRecordWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Retrys a medical record.
    func retryMedicalRecordWorkflow(
        request: ServerRequest<Acme_Patients_V1_RetryMedicalRecordWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_RetryMedicalRecordWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRetryMedicalRecordWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Signals a medical record.
    func signalMedicalRecordWorkflow(
        request: ServerRequest<Acme_Patients_V1_SignalMedicalRecordWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_SignalMedicalRecordWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSignalMedicalRecordWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Starts a medical record.
    func startMedicalRecordWorkflow(
        request: ServerRequest<Acme_Patients_V1_StartMedicalRecordWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_StartMedicalRecordWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processStartMedicalRecordWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }
}
