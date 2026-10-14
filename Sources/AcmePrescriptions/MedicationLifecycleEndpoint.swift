import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Moves a medication between the states of its lifecycle.
final class MedicationLifecycleEndpoint: Acme_Prescriptions_V1_MedicationLifecycleService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let followUps = WorkQueue<Acme_Identity_V1_GetUserRequest>()
    let careplansCareGoalApproval: Acme_Careplans_V1_CareGoalApprovalService.Client<MeshTransport>
    let careplansVitalApproval: Acme_Careplans_V1_VitalApprovalService.Client<MeshTransport>
    let corporateeventsCorporateEventQuery: Acme_Corporateevents_V1_CorporateEventQueryService.Client<MeshTransport>
    let documentsDocument: Acme_Documents_V1_DocumentService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let inventoryStockItem: Acme_Inventory_V1_StockItemService.Client<MeshTransport>
    let ledgerLedgerAccountQuery: Acme_Ledger_V1_LedgerAccountQueryService.Client<MeshTransport>
    let metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client<MeshTransport>
    let notificationsNotificationQuery: Acme_Notifications_V1_NotificationQueryService.Client<MeshTransport>
    let patientsAllergyCalculation: Acme_Patients_V1_AllergyCalculationService.Client<MeshTransport>
    let patientsAllergyValidation: Acme_Patients_V1_AllergyValidationService.Client<MeshTransport>
    let patientsPatient: Acme_Patients_V1_PatientService.Client<MeshTransport>
    let prescriptionsMedicationReporting: Acme_Prescriptions_V1_MedicationReportingService.Client<MeshTransport>
    let prescriptionsMedicationSync: Acme_Prescriptions_V1_MedicationSyncService.Client<MeshTransport>
    let prescriptionsMedicationValidation: Acme_Prescriptions_V1_MedicationValidationService.Client<MeshTransport>
    let prescriptionsRefillSync: Acme_Prescriptions_V1_RefillSyncService.Client<MeshTransport>
    let getMedicationLifecycleStep0:
        any RPCPort<
            Acme_Corporateevents_V1_ResolveCorporateEventsRequest,
            Acme_Corporateevents_V1_ResolveCorporateEventsResponse
        >
    let reinstateMedicationStep0:
        @Sendable (Acme_Careplans_V1_RejectCareGoalRequest) async throws -> Acme_Careplans_V1_RejectCareGoalResponse
    let reinstateMedicationStep2:
        [String:
            @Sendable (Acme_Documents_V1_BatchGetDocumentsRequest) async throws ->
            Acme_Documents_V1_BatchGetDocumentsResponse]

    init(
        dependencies: any Dependencies,
        careplansCareGoalApproval: Acme_Careplans_V1_CareGoalApprovalService.Client<MeshTransport>,
        careplansVitalApproval: Acme_Careplans_V1_VitalApprovalService.Client<MeshTransport>,
        corporateeventsCorporateEventQuery: Acme_Corporateevents_V1_CorporateEventQueryService.Client<MeshTransport>,
        documentsDocument: Acme_Documents_V1_DocumentService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        inventoryStockItem: Acme_Inventory_V1_StockItemService.Client<MeshTransport>,
        ledgerLedgerAccountQuery: Acme_Ledger_V1_LedgerAccountQueryService.Client<MeshTransport>,
        metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client<MeshTransport>,
        notificationsNotificationQuery: Acme_Notifications_V1_NotificationQueryService.Client<MeshTransport>,
        patientsAllergyCalculation: Acme_Patients_V1_AllergyCalculationService.Client<MeshTransport>,
        patientsAllergyValidation: Acme_Patients_V1_AllergyValidationService.Client<MeshTransport>,
        patientsPatient: Acme_Patients_V1_PatientService.Client<MeshTransport>,
        prescriptionsMedicationReporting: Acme_Prescriptions_V1_MedicationReportingService.Client<MeshTransport>,
        prescriptionsMedicationSync: Acme_Prescriptions_V1_MedicationSyncService.Client<MeshTransport>,
        prescriptionsMedicationValidation: Acme_Prescriptions_V1_MedicationValidationService.Client<MeshTransport>,
        prescriptionsRefillSync: Acme_Prescriptions_V1_RefillSyncService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.careplansCareGoalApproval = careplansCareGoalApproval
        self.careplansVitalApproval = careplansVitalApproval
        self.corporateeventsCorporateEventQuery = corporateeventsCorporateEventQuery
        self.documentsDocument = documentsDocument
        self.identityUser = identityUser
        self.inventoryStockItem = inventoryStockItem
        self.ledgerLedgerAccountQuery = ledgerLedgerAccountQuery
        self.metricsMetricSeriesValidation = metricsMetricSeriesValidation
        self.notificationsNotificationQuery = notificationsNotificationQuery
        self.patientsAllergyCalculation = patientsAllergyCalculation
        self.patientsAllergyValidation = patientsAllergyValidation
        self.patientsPatient = patientsPatient
        self.prescriptionsMedicationReporting = prescriptionsMedicationReporting
        self.prescriptionsMedicationSync = prescriptionsMedicationSync
        self.prescriptionsMedicationValidation = prescriptionsMedicationValidation
        self.prescriptionsRefillSync = prescriptionsRefillSync
        self.getMedicationLifecycleStep0 = ClosurePort<
            Acme_Corporateevents_V1_ResolveCorporateEventsRequest,
            Acme_Corporateevents_V1_ResolveCorporateEventsResponse
        >({ request in try await corporateeventsCorporateEventQuery.resolveCorporateEvents(request) })
        self.reinstateMedicationStep0 = { request in try await careplansCareGoalApproval.rejectCareGoal(request) }
        self.reinstateMedicationStep2 = [
            "primary": { request in try await documentsDocument.batchGetDocuments(request) }
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

    /// Activates a medication.
    func activateMedication(
        request: ServerRequest<Acme_Prescriptions_V1_ActivateMedicationRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ActivateMedicationResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processActivateMedication(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Expires a medication.
    func expireMedication(
        request: ServerRequest<Acme_Prescriptions_V1_ExpireMedicationRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ExpireMedicationResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processExpireMedication(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a medication.
    func getMedicationLifecycle(
        request: ServerRequest<Acme_Prescriptions_V1_GetMedicationLifecycleRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_GetMedicationLifecycleResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetMedicationLifecycle(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Reinstates a medication.
    func reinstateMedication(
        request: ServerRequest<Acme_Prescriptions_V1_ReinstateMedicationRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ReinstateMedicationResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processReinstateMedication(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Renews a medication.
    func renewMedication(
        request: ServerRequest<Acme_Prescriptions_V1_RenewMedicationRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_RenewMedicationResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRenewMedication(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Schedules a medication.
    func scheduleMedicationExpiry(
        request: ServerRequest<Acme_Prescriptions_V1_ScheduleMedicationExpiryRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ScheduleMedicationExpiryResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processScheduleMedicationExpiry(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Suspends a medication.
    func suspendMedication(
        request: ServerRequest<Acme_Prescriptions_V1_SuspendMedicationRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_SuspendMedicationResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSuspendMedication(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Terminates a medication.
    func terminateMedication(
        request: ServerRequest<Acme_Prescriptions_V1_TerminateMedicationRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_TerminateMedicationResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processTerminateMedication(request.message)
            return ServerResponse(message: response)
        }
    }
}
