import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Routes refills through approval, with escalation and delegation.
final class RefillApprovalEndpoint: Acme_Prescriptions_V1_RefillApprovalService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let auditAuditEventValidation: Acme_Audit_V1_AuditEventValidationService.Client<MeshTransport>
    let authorizationAccessPolicyQuery: Acme_Authorization_V1_AccessPolicyQueryService.Client<MeshTransport>
    let careplansCareGoalApproval: Acme_Careplans_V1_CareGoalApprovalService.Client<MeshTransport>
    let careplansVitalReporting: Acme_Careplans_V1_VitalReportingService.Client<MeshTransport>
    let datasetsDatasetQuery: Acme_Datasets_V1_DatasetQueryService.Client<MeshTransport>
    let documentsDocumentQuery: Acme_Documents_V1_DocumentQueryService.Client<MeshTransport>
    let featureflagsFeatureFlagValidation: Acme_Featureflags_V1_FeatureFlagValidationService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let itsmIncidentQuery: Acme_Itsm_V1_IncidentQueryService.Client<MeshTransport>
    let ledgerLedgerAccountQuery: Acme_Ledger_V1_LedgerAccountQueryService.Client<MeshTransport>
    let metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client<MeshTransport>
    let patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>
    let patientsMedicalRecordValidation: Acme_Patients_V1_MedicalRecordValidationService.Client<MeshTransport>
    let prescriptionsPrescriptionSync: Acme_Prescriptions_V1_PrescriptionSyncService.Client<MeshTransport>
    let prescriptionsRefillImport: Acme_Prescriptions_V1_RefillImportService.Client<MeshTransport>
    let prescriptionsRefillLifecycle: Acme_Prescriptions_V1_RefillLifecycleService.Client<MeshTransport>
    let prescriptionsRefillReporting: Acme_Prescriptions_V1_RefillReportingService.Client<MeshTransport>
    let listPendingRefillsStep1:
        any RPCPort<
            Acme_Metrics_V1_ExplainMetricSeriesDecisionRequest, Acme_Metrics_V1_ExplainMetricSeriesDecisionResponse
        >
    let submitRefillStep0:
        @Sendable (Acme_Prescriptions_V1_ListRefillReportsRequest) async throws ->
            Acme_Prescriptions_V1_ListRefillReportsResponse

    init(
        dependencies: any Dependencies,
        auditAuditEventValidation: Acme_Audit_V1_AuditEventValidationService.Client<MeshTransport>,
        authorizationAccessPolicyQuery: Acme_Authorization_V1_AccessPolicyQueryService.Client<MeshTransport>,
        careplansCareGoalApproval: Acme_Careplans_V1_CareGoalApprovalService.Client<MeshTransport>,
        careplansVitalReporting: Acme_Careplans_V1_VitalReportingService.Client<MeshTransport>,
        datasetsDatasetQuery: Acme_Datasets_V1_DatasetQueryService.Client<MeshTransport>,
        documentsDocumentQuery: Acme_Documents_V1_DocumentQueryService.Client<MeshTransport>,
        featureflagsFeatureFlagValidation: Acme_Featureflags_V1_FeatureFlagValidationService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        itsmIncidentQuery: Acme_Itsm_V1_IncidentQueryService.Client<MeshTransport>,
        ledgerLedgerAccountQuery: Acme_Ledger_V1_LedgerAccountQueryService.Client<MeshTransport>,
        metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client<MeshTransport>,
        patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>,
        patientsMedicalRecordValidation: Acme_Patients_V1_MedicalRecordValidationService.Client<MeshTransport>,
        prescriptionsPrescriptionSync: Acme_Prescriptions_V1_PrescriptionSyncService.Client<MeshTransport>,
        prescriptionsRefillImport: Acme_Prescriptions_V1_RefillImportService.Client<MeshTransport>,
        prescriptionsRefillLifecycle: Acme_Prescriptions_V1_RefillLifecycleService.Client<MeshTransport>,
        prescriptionsRefillReporting: Acme_Prescriptions_V1_RefillReportingService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.auditAuditEventValidation = auditAuditEventValidation
        self.authorizationAccessPolicyQuery = authorizationAccessPolicyQuery
        self.careplansCareGoalApproval = careplansCareGoalApproval
        self.careplansVitalReporting = careplansVitalReporting
        self.datasetsDatasetQuery = datasetsDatasetQuery
        self.documentsDocumentQuery = documentsDocumentQuery
        self.featureflagsFeatureFlagValidation = featureflagsFeatureFlagValidation
        self.identityUser = identityUser
        self.itsmIncidentQuery = itsmIncidentQuery
        self.ledgerLedgerAccountQuery = ledgerLedgerAccountQuery
        self.metricsMetricSeriesValidation = metricsMetricSeriesValidation
        self.patientsMedicalRecordCalculation = patientsMedicalRecordCalculation
        self.patientsMedicalRecordValidation = patientsMedicalRecordValidation
        self.prescriptionsPrescriptionSync = prescriptionsPrescriptionSync
        self.prescriptionsRefillImport = prescriptionsRefillImport
        self.prescriptionsRefillLifecycle = prescriptionsRefillLifecycle
        self.prescriptionsRefillReporting = prescriptionsRefillReporting
        self.listPendingRefillsStep1 = ClosurePort<
            Acme_Metrics_V1_ExplainMetricSeriesDecisionRequest, Acme_Metrics_V1_ExplainMetricSeriesDecisionResponse
        >({ request in try await metricsMetricSeriesValidation.explainMetricSeriesDecision(request) })
        self.submitRefillStep0 = { request in try await prescriptionsRefillReporting.listRefillReports(request) }
    }

    /// Approves a refill.
    func approveRefill(
        request: ServerRequest<Acme_Prescriptions_V1_ApproveRefillRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ApproveRefillResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processApproveRefill(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Comments a refill.
    func commentRefillApproval(
        request: ServerRequest<Acme_Prescriptions_V1_CommentRefillApprovalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_CommentRefillApprovalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCommentRefillApproval(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Delegates a refill.
    func delegateRefillApproval(
        request: ServerRequest<Acme_Prescriptions_V1_DelegateRefillApprovalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_DelegateRefillApprovalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processDelegateRefillApproval(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Escalates a refill.
    func escalateRefill(
        request: ServerRequest<Acme_Prescriptions_V1_EscalateRefillRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_EscalateRefillResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processEscalateRefill(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a refill.
    func getRefillApprovalStatus(
        request: ServerRequest<Acme_Prescriptions_V1_GetRefillApprovalStatusRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_GetRefillApprovalStatusResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetRefillApprovalStatus(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists refills a page at a time.
    func listPendingRefills(
        request: ServerRequest<Acme_Prescriptions_V1_ListPendingRefillsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ListPendingRefillsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListPendingRefills(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Recalls a refill.
    func recallRefill(
        request: ServerRequest<Acme_Prescriptions_V1_RecallRefillRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_RecallRefillResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRecallRefill(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Submits a refill.
    func submitRefill(
        request: ServerRequest<Acme_Prescriptions_V1_SubmitRefillRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_SubmitRefillResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSubmitRefill(request.message)
            return ServerResponse(message: response)
        }
    }
}
