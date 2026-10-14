import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Keeps prescriptions in step with the systems of record in other regions.
final class PrescriptionSyncEndpoint: Acme_Prescriptions_V1_PrescriptionSyncService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let followUps = WorkQueue<Acme_Identity_V1_GetUserRequest>()
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>
    let patientsMedicalRecordQuery: Acme_Patients_V1_MedicalRecordQueryService.Client<MeshTransport>
    let patientsPatientCalculation: Acme_Patients_V1_PatientCalculationService.Client<MeshTransport>
    let prescriptionsMedicationCalculation: Acme_Prescriptions_V1_MedicationCalculationService.Client<MeshTransport>
    let prescriptionsMedicationQuery: Acme_Prescriptions_V1_MedicationQueryService.Client<MeshTransport>
    let prescriptionsMedicationValidation: Acme_Prescriptions_V1_MedicationValidationService.Client<MeshTransport>
    let prescriptionsPrescription: Acme_Prescriptions_V1_PrescriptionService.Client<MeshTransport>
    let prescriptionsPrescriptionCalculation: Acme_Prescriptions_V1_PrescriptionCalculationService.Client<MeshTransport>
    let prescriptionsPrescriptionValidation: Acme_Prescriptions_V1_PrescriptionValidationService.Client<MeshTransport>
    let prescriptionsRefillValidation: Acme_Prescriptions_V1_RefillValidationService.Client<MeshTransport>
    let searchSearchIndexValidation: Acme_Search_V1_SearchIndexValidationService.Client<MeshTransport>
    let getPrescriptionSyncStateStep0:
        [String:
            @Sendable (Acme_Search_V1_PreviewSearchIndexRequest) async throws ->
            Acme_Search_V1_PreviewSearchIndexResponse]

    init(
        dependencies: any Dependencies,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>,
        patientsMedicalRecordQuery: Acme_Patients_V1_MedicalRecordQueryService.Client<MeshTransport>,
        patientsPatientCalculation: Acme_Patients_V1_PatientCalculationService.Client<MeshTransport>,
        prescriptionsMedicationCalculation: Acme_Prescriptions_V1_MedicationCalculationService.Client<MeshTransport>,
        prescriptionsMedicationQuery: Acme_Prescriptions_V1_MedicationQueryService.Client<MeshTransport>,
        prescriptionsMedicationValidation: Acme_Prescriptions_V1_MedicationValidationService.Client<MeshTransport>,
        prescriptionsPrescription: Acme_Prescriptions_V1_PrescriptionService.Client<MeshTransport>,
        prescriptionsPrescriptionCalculation: Acme_Prescriptions_V1_PrescriptionCalculationService.Client<
            MeshTransport
        >,
        prescriptionsPrescriptionValidation: Acme_Prescriptions_V1_PrescriptionValidationService.Client<MeshTransport>,
        prescriptionsRefillValidation: Acme_Prescriptions_V1_RefillValidationService.Client<MeshTransport>,
        searchSearchIndexValidation: Acme_Search_V1_SearchIndexValidationService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.identityUser = identityUser
        self.patientsMedicalRecordCalculation = patientsMedicalRecordCalculation
        self.patientsMedicalRecordQuery = patientsMedicalRecordQuery
        self.patientsPatientCalculation = patientsPatientCalculation
        self.prescriptionsMedicationCalculation = prescriptionsMedicationCalculation
        self.prescriptionsMedicationQuery = prescriptionsMedicationQuery
        self.prescriptionsMedicationValidation = prescriptionsMedicationValidation
        self.prescriptionsPrescription = prescriptionsPrescription
        self.prescriptionsPrescriptionCalculation = prescriptionsPrescriptionCalculation
        self.prescriptionsPrescriptionValidation = prescriptionsPrescriptionValidation
        self.prescriptionsRefillValidation = prescriptionsRefillValidation
        self.searchSearchIndexValidation = searchSearchIndexValidation
        self.getPrescriptionSyncStateStep0 = [
            "primary": { request in try await searchSearchIndexValidation.previewSearchIndex(request) }
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

    /// Returns a prescription.
    func getPrescriptionSyncState(
        request: ServerRequest<Acme_Prescriptions_V1_GetPrescriptionSyncStateRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_GetPrescriptionSyncStateResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetPrescriptionSyncState(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists prescriptions a page at a time.
    func listPrescriptionConflicts(
        request: ServerRequest<Acme_Prescriptions_V1_ListPrescriptionConflictsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ListPrescriptionConflictsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListPrescriptionConflicts(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Pushs a prescription.
    func pushPrescription(
        request: ServerRequest<Acme_Prescriptions_V1_PushPrescriptionRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_PushPrescriptionResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processPushPrescription(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Reconciles a prescription.
    func reconcilePrescriptions(
        request: ServerRequest<Acme_Prescriptions_V1_ReconcilePrescriptionsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ReconcilePrescriptionsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processReconcilePrescriptions(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Resolves a prescription.
    func resolvePrescriptionConflict(
        request: ServerRequest<Acme_Prescriptions_V1_ResolvePrescriptionConflictRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ResolvePrescriptionConflictResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processResolvePrescriptionConflict(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Exchanges changes of prescriptions with a peer.
    func streamPrescriptionChanges(
        request: StreamingServerRequest<Acme_Prescriptions_V1_StreamPrescriptionChangesRequest>,
        context: ServerContext
    ) async throws -> StreamingServerResponse<Acme_Prescriptions_V1_StreamPrescriptionChangesResponse> {
        return StreamingServerResponse { writer in
            try await CallerScope.$metadata.withValue(request.metadata) {
                for try await message in request.messages {
                    let response = try await self.processStreamPrescriptionChanges(message)
                    try await writer.write(response)
                }
                return [:]
            }
        }
    }

    /// Syncs a prescription.
    func syncPrescriptions(
        request: ServerRequest<Acme_Prescriptions_V1_SyncPrescriptionsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_SyncPrescriptionsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSyncPrescriptions(request.message)
            return ServerResponse(message: response)
        }
    }
}
