import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Moves a refill between the states of its lifecycle.
final class RefillLifecycleEndpoint: Acme_Prescriptions_V1_RefillLifecycleService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let followUps = WorkQueue<Acme_Identity_V1_GetUserRequest>()
    let careplansCareGoalApproval: Acme_Careplans_V1_CareGoalApprovalService.Client<MeshTransport>
    let careplansVitalWorkflow: Acme_Careplans_V1_VitalWorkflowService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let ledgerLedgerAccountQuery: Acme_Ledger_V1_LedgerAccountQueryService.Client<MeshTransport>
    let patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>
    let patientsMedicalRecordValidation: Acme_Patients_V1_MedicalRecordValidationService.Client<MeshTransport>
    let patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client<MeshTransport>
    let prescriptionsMedicationSync: Acme_Prescriptions_V1_MedicationSyncService.Client<MeshTransport>
    let prescriptionsMedicationValidation: Acme_Prescriptions_V1_MedicationValidationService.Client<MeshTransport>
    let prescriptionsRefillImport: Acme_Prescriptions_V1_RefillImportService.Client<MeshTransport>
    let prescriptionsRefillSync: Acme_Prescriptions_V1_RefillSyncService.Client<MeshTransport>
    let searchSearchIndexValidation: Acme_Search_V1_SearchIndexValidationService.Client<MeshTransport>
    let suspendRefillStep0:
        any RPCPort<Acme_Prescriptions_V1_CancelRefillImportRequest, Acme_Prescriptions_V1_CancelRefillImportResponse>
    let terminateRefillStep0:
        @Sendable (Acme_Search_V1_ScoreSearchIndexRequest) async throws -> Acme_Search_V1_ScoreSearchIndexResponse

    init(
        dependencies: any Dependencies,
        careplansCareGoalApproval: Acme_Careplans_V1_CareGoalApprovalService.Client<MeshTransport>,
        careplansVitalWorkflow: Acme_Careplans_V1_VitalWorkflowService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        ledgerLedgerAccountQuery: Acme_Ledger_V1_LedgerAccountQueryService.Client<MeshTransport>,
        patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>,
        patientsMedicalRecordValidation: Acme_Patients_V1_MedicalRecordValidationService.Client<MeshTransport>,
        patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client<MeshTransport>,
        prescriptionsMedicationSync: Acme_Prescriptions_V1_MedicationSyncService.Client<MeshTransport>,
        prescriptionsMedicationValidation: Acme_Prescriptions_V1_MedicationValidationService.Client<MeshTransport>,
        prescriptionsRefillImport: Acme_Prescriptions_V1_RefillImportService.Client<MeshTransport>,
        prescriptionsRefillSync: Acme_Prescriptions_V1_RefillSyncService.Client<MeshTransport>,
        searchSearchIndexValidation: Acme_Search_V1_SearchIndexValidationService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.careplansCareGoalApproval = careplansCareGoalApproval
        self.careplansVitalWorkflow = careplansVitalWorkflow
        self.identityUser = identityUser
        self.ledgerLedgerAccountQuery = ledgerLedgerAccountQuery
        self.patientsMedicalRecordCalculation = patientsMedicalRecordCalculation
        self.patientsMedicalRecordValidation = patientsMedicalRecordValidation
        self.patientsPatientQuery = patientsPatientQuery
        self.prescriptionsMedicationSync = prescriptionsMedicationSync
        self.prescriptionsMedicationValidation = prescriptionsMedicationValidation
        self.prescriptionsRefillImport = prescriptionsRefillImport
        self.prescriptionsRefillSync = prescriptionsRefillSync
        self.searchSearchIndexValidation = searchSearchIndexValidation
        self.suspendRefillStep0 = ClosurePort<
            Acme_Prescriptions_V1_CancelRefillImportRequest, Acme_Prescriptions_V1_CancelRefillImportResponse
        >({ request in try await prescriptionsRefillImport.cancelRefillImport(request) })
        self.terminateRefillStep0 = { request in try await searchSearchIndexValidation.scoreSearchIndex(request) }
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

    /// Activates a refill.
    func activateRefill(
        request: ServerRequest<Acme_Prescriptions_V1_ActivateRefillRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ActivateRefillResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processActivateRefill(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Expires a refill.
    func expireRefill(
        request: ServerRequest<Acme_Prescriptions_V1_ExpireRefillRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ExpireRefillResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processExpireRefill(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a refill.
    func getRefillLifecycle(
        request: ServerRequest<Acme_Prescriptions_V1_GetRefillLifecycleRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_GetRefillLifecycleResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetRefillLifecycle(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Reinstates a refill.
    func reinstateRefill(
        request: ServerRequest<Acme_Prescriptions_V1_ReinstateRefillRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ReinstateRefillResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processReinstateRefill(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Renews a refill.
    func renewRefill(
        request: ServerRequest<Acme_Prescriptions_V1_RenewRefillRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_RenewRefillResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRenewRefill(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Schedules a refill.
    func scheduleRefillExpiry(
        request: ServerRequest<Acme_Prescriptions_V1_ScheduleRefillExpiryRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ScheduleRefillExpiryResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processScheduleRefillExpiry(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Suspends a refill.
    func suspendRefill(
        request: ServerRequest<Acme_Prescriptions_V1_SuspendRefillRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_SuspendRefillResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSuspendRefill(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Terminates a refill.
    func terminateRefill(
        request: ServerRequest<Acme_Prescriptions_V1_TerminateRefillRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_TerminateRefillResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processTerminateRefill(request.message)
            return ServerResponse(message: response)
        }
    }
}
