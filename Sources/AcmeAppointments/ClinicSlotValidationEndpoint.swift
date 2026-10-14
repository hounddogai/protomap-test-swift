import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Checks clinic slots against the rules before anything acts on them.
final class ClinicSlotValidationEndpoint: Acme_Appointments_V1_ClinicSlotValidationService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let appointmentsClinicSlotCalculation: Acme_Appointments_V1_ClinicSlotCalculationService.Client<MeshTransport>
    let appointmentsProviderValidation: Acme_Appointments_V1_ProviderValidationService.Client<MeshTransport>
    let broadcastsBroadcast: Acme_Broadcasts_V1_BroadcastService.Client<MeshTransport>
    let careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let identityUserQuery: Acme_Identity_V1_UserQueryService.Client<MeshTransport>
    let ledgerLedgerAccountQuery: Acme_Ledger_V1_LedgerAccountQueryService.Client<MeshTransport>
    let prescriptionsPrescription: Acme_Prescriptions_V1_PrescriptionService.Client<MeshTransport>
    let showsShowCalculation: Acme_Shows_V1_ShowCalculationService.Client<MeshTransport>
    let venuesVenueValidation: Acme_Venues_V1_VenueValidationService.Client<MeshTransport>
    let normalizeClinicSlotStep0:
        any RPCPort<Acme_Venues_V1_ExplainVenueDecisionRequest, Acme_Venues_V1_ExplainVenueDecisionResponse>
    let scoreClinicSlotStep0:
        @Sendable (Acme_Careplans_V1_QuoteCareGoalRequest) async throws -> Acme_Careplans_V1_QuoteCareGoalResponse
    let scoreClinicSlotStep1:
        [String:
            @Sendable (Acme_Broadcasts_V1_BatchGetBroadcastsRequest) async throws ->
            Acme_Broadcasts_V1_BatchGetBroadcastsResponse]

    init(
        dependencies: any Dependencies,
        appointmentsClinicSlotCalculation: Acme_Appointments_V1_ClinicSlotCalculationService.Client<MeshTransport>,
        appointmentsProviderValidation: Acme_Appointments_V1_ProviderValidationService.Client<MeshTransport>,
        broadcastsBroadcast: Acme_Broadcasts_V1_BroadcastService.Client<MeshTransport>,
        careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        identityUserQuery: Acme_Identity_V1_UserQueryService.Client<MeshTransport>,
        ledgerLedgerAccountQuery: Acme_Ledger_V1_LedgerAccountQueryService.Client<MeshTransport>,
        prescriptionsPrescription: Acme_Prescriptions_V1_PrescriptionService.Client<MeshTransport>,
        showsShowCalculation: Acme_Shows_V1_ShowCalculationService.Client<MeshTransport>,
        venuesVenueValidation: Acme_Venues_V1_VenueValidationService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.appointmentsClinicSlotCalculation = appointmentsClinicSlotCalculation
        self.appointmentsProviderValidation = appointmentsProviderValidation
        self.broadcastsBroadcast = broadcastsBroadcast
        self.careplansCareGoalCalculation = careplansCareGoalCalculation
        self.identityUser = identityUser
        self.identityUserQuery = identityUserQuery
        self.ledgerLedgerAccountQuery = ledgerLedgerAccountQuery
        self.prescriptionsPrescription = prescriptionsPrescription
        self.showsShowCalculation = showsShowCalculation
        self.venuesVenueValidation = venuesVenueValidation
        self.normalizeClinicSlotStep0 = ClosurePort<
            Acme_Venues_V1_ExplainVenueDecisionRequest, Acme_Venues_V1_ExplainVenueDecisionResponse
        >({ request in try await venuesVenueValidation.explainVenueDecision(request) })
        self.scoreClinicSlotStep0 = { request in try await careplansCareGoalCalculation.quoteCareGoal(request) }
        self.scoreClinicSlotStep1 = [
            "primary": { request in try await broadcastsBroadcast.batchGetBroadcasts(request) }
        ]
    }

    /// Checks a clinic slot.
    func checkClinicSlotEligibility(
        request: ServerRequest<Acme_Appointments_V1_CheckClinicSlotEligibilityRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_CheckClinicSlotEligibilityResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCheckClinicSlotEligibility(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Explains a clinic slot.
    func explainClinicSlotDecision(
        request: ServerRequest<Acme_Appointments_V1_ExplainClinicSlotDecisionRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_ExplainClinicSlotDecisionResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processExplainClinicSlotDecision(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lints a clinic slot.
    func lintClinicSlots(
        request: ServerRequest<Acme_Appointments_V1_LintClinicSlotsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_LintClinicSlotsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processLintClinicSlots(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Normalizes a clinic slot.
    func normalizeClinicSlot(
        request: ServerRequest<Acme_Appointments_V1_NormalizeClinicSlotRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_NormalizeClinicSlotResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processNormalizeClinicSlot(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Previews a clinic slot.
    func previewClinicSlot(
        request: ServerRequest<Acme_Appointments_V1_PreviewClinicSlotRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_PreviewClinicSlotResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processPreviewClinicSlot(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Scores a clinic slot.
    func scoreClinicSlot(
        request: ServerRequest<Acme_Appointments_V1_ScoreClinicSlotRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_ScoreClinicSlotResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processScoreClinicSlot(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Validates a clinic slot.
    func validateClinicSlot(
        request: ServerRequest<Acme_Appointments_V1_ValidateClinicSlotRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_ValidateClinicSlotResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processValidateClinicSlot(request.message)
            return ServerResponse(message: response)
        }
    }
}
