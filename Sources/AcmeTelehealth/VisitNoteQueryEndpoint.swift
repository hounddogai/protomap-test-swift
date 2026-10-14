import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Answers read-only questions about visit notes, for screens and reports.
final class VisitNoteQueryEndpoint: Acme_Telehealth_V1_VisitNoteQueryService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let auditAuditEvent: Acme_Audit_V1_AuditEventService.Client<MeshTransport>
    let careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>
    let careplansVitalCalculation: Acme_Careplans_V1_VitalCalculationService.Client<MeshTransport>
    let featureflagsFeatureFlagValidation: Acme_Featureflags_V1_FeatureFlagValidationService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let telehealthTriageCalculation: Acme_Telehealth_V1_TriageCalculationService.Client<MeshTransport>
    let telehealthTriageValidation: Acme_Telehealth_V1_TriageValidationService.Client<MeshTransport>
    let telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client<MeshTransport>
    let telehealthVideoVisitQuery: Acme_Telehealth_V1_VideoVisitQueryService.Client<MeshTransport>
    let telehealthVisitNoteValidation: Acme_Telehealth_V1_VisitNoteValidationService.Client<MeshTransport>
    let suggestVisitNotesStep0:
        any RPCPort<Acme_Audit_V1_BatchGetAuditEventsRequest, Acme_Audit_V1_BatchGetAuditEventsResponse>
    let summarizeVisitNotesStep1:
        @Sendable (Acme_Telehealth_V1_NormalizeVisitNoteRequest) async throws ->
            Acme_Telehealth_V1_NormalizeVisitNoteResponse
    let summarizeVisitNotesStep2:
        [String:
            @Sendable (Acme_Telehealth_V1_CalculateVideoVisitRequest) async throws ->
            Acme_Telehealth_V1_CalculateVideoVisitResponse]

    init(
        dependencies: any Dependencies,
        auditAuditEvent: Acme_Audit_V1_AuditEventService.Client<MeshTransport>,
        careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>,
        careplansVitalCalculation: Acme_Careplans_V1_VitalCalculationService.Client<MeshTransport>,
        featureflagsFeatureFlagValidation: Acme_Featureflags_V1_FeatureFlagValidationService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        telehealthTriageCalculation: Acme_Telehealth_V1_TriageCalculationService.Client<MeshTransport>,
        telehealthTriageValidation: Acme_Telehealth_V1_TriageValidationService.Client<MeshTransport>,
        telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client<MeshTransport>,
        telehealthVideoVisitQuery: Acme_Telehealth_V1_VideoVisitQueryService.Client<MeshTransport>,
        telehealthVisitNoteValidation: Acme_Telehealth_V1_VisitNoteValidationService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.auditAuditEvent = auditAuditEvent
        self.careplansCarePlan = careplansCarePlan
        self.careplansVitalCalculation = careplansVitalCalculation
        self.featureflagsFeatureFlagValidation = featureflagsFeatureFlagValidation
        self.identityUser = identityUser
        self.telehealthTriageCalculation = telehealthTriageCalculation
        self.telehealthTriageValidation = telehealthTriageValidation
        self.telehealthVideoVisitCalculation = telehealthVideoVisitCalculation
        self.telehealthVideoVisitQuery = telehealthVideoVisitQuery
        self.telehealthVisitNoteValidation = telehealthVisitNoteValidation
        self.suggestVisitNotesStep0 = ClosurePort<
            Acme_Audit_V1_BatchGetAuditEventsRequest, Acme_Audit_V1_BatchGetAuditEventsResponse
        >({ request in try await auditAuditEvent.batchGetAuditEvents(request) })
        self.summarizeVisitNotesStep1 = { request in try await telehealthVisitNoteValidation.normalizeVisitNote(request)
        }
        self.summarizeVisitNotesStep2 = [
            "primary": { request in try await telehealthVideoVisitCalculation.calculateVideoVisit(request) }
        ]
    }
}
