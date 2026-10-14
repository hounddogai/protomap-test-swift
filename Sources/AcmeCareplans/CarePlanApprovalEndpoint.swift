import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Routes care plans through approval, with escalation and delegation.
final class CarePlanApprovalEndpoint: Acme_Careplans_V1_CarePlanApprovalService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let appointmentsProviderQuery: Acme_Appointments_V1_ProviderQueryService.Client<MeshTransport>
    let careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>
    let careplansCareGoalQuery: Acme_Careplans_V1_CareGoalQueryService.Client<MeshTransport>
    let careplansCareGoalValidation: Acme_Careplans_V1_CareGoalValidationService.Client<MeshTransport>
    let careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>
    let careplansCarePlanCalculation: Acme_Careplans_V1_CarePlanCalculationService.Client<MeshTransport>
    let careplansCarePlanLifecycle: Acme_Careplans_V1_CarePlanLifecycleService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client<MeshTransport>
    let patientsAllergyValidation: Acme_Patients_V1_AllergyValidationService.Client<MeshTransport>
    let prescriptionsPrescriptionValidation: Acme_Prescriptions_V1_PrescriptionValidationService.Client<MeshTransport>
    let shippingShipment: Acme_Shipping_V1_ShipmentService.Client<MeshTransport>
    let telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client<MeshTransport>
    let telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client<MeshTransport>
    let telehealthVisitNoteCalculation: Acme_Telehealth_V1_VisitNoteCalculationService.Client<MeshTransport>
    let submitCarePlanStep0:
        any RPCPort<Acme_Careplans_V1_ResolveCareGoalsRequest, Acme_Careplans_V1_ResolveCareGoalsResponse>

    init(
        dependencies: any Dependencies,
        appointmentsProviderQuery: Acme_Appointments_V1_ProviderQueryService.Client<MeshTransport>,
        careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>,
        careplansCareGoalQuery: Acme_Careplans_V1_CareGoalQueryService.Client<MeshTransport>,
        careplansCareGoalValidation: Acme_Careplans_V1_CareGoalValidationService.Client<MeshTransport>,
        careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>,
        careplansCarePlanCalculation: Acme_Careplans_V1_CarePlanCalculationService.Client<MeshTransport>,
        careplansCarePlanLifecycle: Acme_Careplans_V1_CarePlanLifecycleService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client<MeshTransport>,
        patientsAllergyValidation: Acme_Patients_V1_AllergyValidationService.Client<MeshTransport>,
        prescriptionsPrescriptionValidation: Acme_Prescriptions_V1_PrescriptionValidationService.Client<MeshTransport>,
        shippingShipment: Acme_Shipping_V1_ShipmentService.Client<MeshTransport>,
        telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client<MeshTransport>,
        telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client<MeshTransport>,
        telehealthVisitNoteCalculation: Acme_Telehealth_V1_VisitNoteCalculationService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.appointmentsProviderQuery = appointmentsProviderQuery
        self.careplansCareGoalCalculation = careplansCareGoalCalculation
        self.careplansCareGoalQuery = careplansCareGoalQuery
        self.careplansCareGoalValidation = careplansCareGoalValidation
        self.careplansCarePlan = careplansCarePlan
        self.careplansCarePlanCalculation = careplansCarePlanCalculation
        self.careplansCarePlanLifecycle = careplansCarePlanLifecycle
        self.identityUser = identityUser
        self.metricsMetricSeriesValidation = metricsMetricSeriesValidation
        self.patientsAllergyValidation = patientsAllergyValidation
        self.prescriptionsPrescriptionValidation = prescriptionsPrescriptionValidation
        self.shippingShipment = shippingShipment
        self.telehealthVideoVisit = telehealthVideoVisit
        self.telehealthVideoVisitCalculation = telehealthVideoVisitCalculation
        self.telehealthVisitNoteCalculation = telehealthVisitNoteCalculation
        self.submitCarePlanStep0 = ClosurePort<
            Acme_Careplans_V1_ResolveCareGoalsRequest, Acme_Careplans_V1_ResolveCareGoalsResponse
        >({ request in try await careplansCareGoalQuery.resolveCareGoals(request) })
    }

    /// Approves a care plan.
    func approveCarePlan(
        request: ServerRequest<Acme_Careplans_V1_ApproveCarePlanRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_ApproveCarePlanResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processApproveCarePlan(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Comments a care plan.
    func commentCarePlanApproval(
        request: ServerRequest<Acme_Careplans_V1_CommentCarePlanApprovalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_CommentCarePlanApprovalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCommentCarePlanApproval(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Delegates a care plan.
    func delegateCarePlanApproval(
        request: ServerRequest<Acme_Careplans_V1_DelegateCarePlanApprovalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_DelegateCarePlanApprovalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processDelegateCarePlanApproval(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a care plan.
    func getCarePlanApprovalStatus(
        request: ServerRequest<Acme_Careplans_V1_GetCarePlanApprovalStatusRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_GetCarePlanApprovalStatusResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetCarePlanApprovalStatus(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists care plans a page at a time.
    func listPendingCarePlans(
        request: ServerRequest<Acme_Careplans_V1_ListPendingCarePlansRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_ListPendingCarePlansResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListPendingCarePlans(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Rejects a care plan.
    func rejectCarePlan(
        request: ServerRequest<Acme_Careplans_V1_RejectCarePlanRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_RejectCarePlanResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRejectCarePlan(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Submits a care plan.
    func submitCarePlan(
        request: ServerRequest<Acme_Careplans_V1_SubmitCarePlanRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_SubmitCarePlanResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSubmitCarePlan(request.message)
            return ServerResponse(message: response)
        }
    }
}
