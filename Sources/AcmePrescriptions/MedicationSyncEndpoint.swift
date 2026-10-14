import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Keeps medications in step with the systems of record in other regions.
final class MedicationSyncEndpoint: Acme_Prescriptions_V1_MedicationSyncService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let authorizationAccessPolicyQuery: Acme_Authorization_V1_AccessPolicyQueryService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client<MeshTransport>
    let patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>
    let patientsMedicalRecordValidation: Acme_Patients_V1_MedicalRecordValidationService.Client<MeshTransport>
    let patientsPatientCalculation: Acme_Patients_V1_PatientCalculationService.Client<MeshTransport>
    let patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client<MeshTransport>
    let prescriptionsMedicationCalculation: Acme_Prescriptions_V1_MedicationCalculationService.Client<MeshTransport>
    let prescriptionsMedicationQuery: Acme_Prescriptions_V1_MedicationQueryService.Client<MeshTransport>
    let prescriptionsPrescriptionSync: Acme_Prescriptions_V1_PrescriptionSyncService.Client<MeshTransport>
    let prescriptionsPrescriptionValidation: Acme_Prescriptions_V1_PrescriptionValidationService.Client<MeshTransport>
    let prescriptionsRefillImport: Acme_Prescriptions_V1_RefillImportService.Client<MeshTransport>
    let telehealthTriageWorkflow: Acme_Telehealth_V1_TriageWorkflowService.Client<MeshTransport>
    let syncMedicationsStep2:
        any RPCPort<
            Acme_Prescriptions_V1_CheckPrescriptionEligibilityRequest,
            Acme_Prescriptions_V1_CheckPrescriptionEligibilityResponse
        >

    init(
        dependencies: any Dependencies,
        authorizationAccessPolicyQuery: Acme_Authorization_V1_AccessPolicyQueryService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client<MeshTransport>,
        patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>,
        patientsMedicalRecordValidation: Acme_Patients_V1_MedicalRecordValidationService.Client<MeshTransport>,
        patientsPatientCalculation: Acme_Patients_V1_PatientCalculationService.Client<MeshTransport>,
        patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client<MeshTransport>,
        prescriptionsMedicationCalculation: Acme_Prescriptions_V1_MedicationCalculationService.Client<MeshTransport>,
        prescriptionsMedicationQuery: Acme_Prescriptions_V1_MedicationQueryService.Client<MeshTransport>,
        prescriptionsPrescriptionSync: Acme_Prescriptions_V1_PrescriptionSyncService.Client<MeshTransport>,
        prescriptionsPrescriptionValidation: Acme_Prescriptions_V1_PrescriptionValidationService.Client<MeshTransport>,
        prescriptionsRefillImport: Acme_Prescriptions_V1_RefillImportService.Client<MeshTransport>,
        telehealthTriageWorkflow: Acme_Telehealth_V1_TriageWorkflowService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.authorizationAccessPolicyQuery = authorizationAccessPolicyQuery
        self.identityUser = identityUser
        self.metricsMetricSeriesValidation = metricsMetricSeriesValidation
        self.patientsMedicalRecordCalculation = patientsMedicalRecordCalculation
        self.patientsMedicalRecordValidation = patientsMedicalRecordValidation
        self.patientsPatientCalculation = patientsPatientCalculation
        self.patientsPatientQuery = patientsPatientQuery
        self.prescriptionsMedicationCalculation = prescriptionsMedicationCalculation
        self.prescriptionsMedicationQuery = prescriptionsMedicationQuery
        self.prescriptionsPrescriptionSync = prescriptionsPrescriptionSync
        self.prescriptionsPrescriptionValidation = prescriptionsPrescriptionValidation
        self.prescriptionsRefillImport = prescriptionsRefillImport
        self.telehealthTriageWorkflow = telehealthTriageWorkflow
        self.syncMedicationsStep2 = ClosurePort<
            Acme_Prescriptions_V1_CheckPrescriptionEligibilityRequest,
            Acme_Prescriptions_V1_CheckPrescriptionEligibilityResponse
        >({ request in try await prescriptionsPrescriptionValidation.checkPrescriptionEligibility(request) })
    }

    /// Lists medications a page at a time.
    func listMedicationConflicts(
        request: ServerRequest<Acme_Prescriptions_V1_ListMedicationConflictsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ListMedicationConflictsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListMedicationConflicts(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Pulls a medication.
    func pullMedications(
        request: ServerRequest<Acme_Prescriptions_V1_PullMedicationsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_PullMedicationsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processPullMedications(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Pushs a medication.
    func pushMedication(
        request: ServerRequest<Acme_Prescriptions_V1_PushMedicationRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_PushMedicationResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processPushMedication(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Resolves a medication.
    func resolveMedicationConflict(
        request: ServerRequest<Acme_Prescriptions_V1_ResolveMedicationConflictRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ResolveMedicationConflictResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processResolveMedicationConflict(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Exchanges changes of medications with a peer.
    func streamMedicationChanges(
        request: StreamingServerRequest<Acme_Prescriptions_V1_StreamMedicationChangesRequest>,
        context: ServerContext
    ) async throws -> StreamingServerResponse<Acme_Prescriptions_V1_StreamMedicationChangesResponse> {
        return StreamingServerResponse { writer in
            try await CallerScope.$metadata.withValue(request.metadata) {
                for try await message in request.messages {
                    let response = try await self.processStreamMedicationChanges(message)
                    try await writer.write(response)
                }
                return [:]
            }
        }
    }

    /// Syncs a medication.
    func syncMedications(
        request: ServerRequest<Acme_Prescriptions_V1_SyncMedicationsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_SyncMedicationsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSyncMedications(request.message)
            return ServerResponse(message: response)
        }
    }
}
