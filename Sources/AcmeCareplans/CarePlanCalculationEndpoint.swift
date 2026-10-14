import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Computes the figures of a care plan, such as totals, taxes, and estimates.
final class CarePlanCalculationEndpoint: Acme_Careplans_V1_CarePlanCalculationService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let followUps = WorkQueue<Acme_Identity_V1_GetUserRequest>()
    let authorizationAccessPolicyValidation: Acme_Authorization_V1_AccessPolicyValidationService.Client<MeshTransport>
    let boxofficeBoxOfficeSaleCalculation: Acme_Boxoffice_V1_BoxOfficeSaleCalculationService.Client<MeshTransport>
    let broadcastsBroadcastQuery: Acme_Broadcasts_V1_BroadcastQueryService.Client<MeshTransport>
    let documentsDocumentValidation: Acme_Documents_V1_DocumentValidationService.Client<MeshTransport>
    let featureflagsFeatureFlagValidation: Acme_Featureflags_V1_FeatureFlagValidationService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let identityUserQuery: Acme_Identity_V1_UserQueryService.Client<MeshTransport>
    let identityUserValidation: Acme_Identity_V1_UserValidationService.Client<MeshTransport>
    let ledgerLedgerAccountQuery: Acme_Ledger_V1_LedgerAccountQueryService.Client<MeshTransport>
    let metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client<MeshTransport>
    let notificationsNotificationQuery: Acme_Notifications_V1_NotificationQueryService.Client<MeshTransport>
    let notificationsNotificationValidation: Acme_Notifications_V1_NotificationValidationService.Client<MeshTransport>
    let showsShow: Acme_Shows_V1_ShowService.Client<MeshTransport>
    let showsShowCalculation: Acme_Shows_V1_ShowCalculationService.Client<MeshTransport>
    let calculateCarePlanStep2:
        @Sendable (Acme_Documents_V1_LintDocumentsRequest) async throws -> Acme_Documents_V1_LintDocumentsResponse
    let compareCarePlanOptionsStep0:
        [String:
            @Sendable (Acme_Featureflags_V1_LintFeatureFlagsRequest) async throws ->
            Acme_Featureflags_V1_LintFeatureFlagsResponse]
    let simulateCarePlanStep0:
        any RPCPort<
            Acme_Notifications_V1_NormalizeNotificationRequest, Acme_Notifications_V1_NormalizeNotificationResponse
        >

    init(
        dependencies: any Dependencies,
        authorizationAccessPolicyValidation: Acme_Authorization_V1_AccessPolicyValidationService.Client<MeshTransport>,
        boxofficeBoxOfficeSaleCalculation: Acme_Boxoffice_V1_BoxOfficeSaleCalculationService.Client<MeshTransport>,
        broadcastsBroadcastQuery: Acme_Broadcasts_V1_BroadcastQueryService.Client<MeshTransport>,
        documentsDocumentValidation: Acme_Documents_V1_DocumentValidationService.Client<MeshTransport>,
        featureflagsFeatureFlagValidation: Acme_Featureflags_V1_FeatureFlagValidationService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        identityUserQuery: Acme_Identity_V1_UserQueryService.Client<MeshTransport>,
        identityUserValidation: Acme_Identity_V1_UserValidationService.Client<MeshTransport>,
        ledgerLedgerAccountQuery: Acme_Ledger_V1_LedgerAccountQueryService.Client<MeshTransport>,
        metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client<MeshTransport>,
        notificationsNotificationQuery: Acme_Notifications_V1_NotificationQueryService.Client<MeshTransport>,
        notificationsNotificationValidation: Acme_Notifications_V1_NotificationValidationService.Client<MeshTransport>,
        showsShow: Acme_Shows_V1_ShowService.Client<MeshTransport>,
        showsShowCalculation: Acme_Shows_V1_ShowCalculationService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.authorizationAccessPolicyValidation = authorizationAccessPolicyValidation
        self.boxofficeBoxOfficeSaleCalculation = boxofficeBoxOfficeSaleCalculation
        self.broadcastsBroadcastQuery = broadcastsBroadcastQuery
        self.documentsDocumentValidation = documentsDocumentValidation
        self.featureflagsFeatureFlagValidation = featureflagsFeatureFlagValidation
        self.identityUser = identityUser
        self.identityUserQuery = identityUserQuery
        self.identityUserValidation = identityUserValidation
        self.ledgerLedgerAccountQuery = ledgerLedgerAccountQuery
        self.metricsMetricSeriesValidation = metricsMetricSeriesValidation
        self.notificationsNotificationQuery = notificationsNotificationQuery
        self.notificationsNotificationValidation = notificationsNotificationValidation
        self.showsShow = showsShow
        self.showsShowCalculation = showsShowCalculation
        self.calculateCarePlanStep2 = { request in try await documentsDocumentValidation.lintDocuments(request) }
        self.compareCarePlanOptionsStep0 = [
            "primary": { request in try await featureflagsFeatureFlagValidation.lintFeatureFlags(request) }
        ]
        self.simulateCarePlanStep0 = ClosurePort<
            Acme_Notifications_V1_NormalizeNotificationRequest, Acme_Notifications_V1_NormalizeNotificationResponse
        >({ request in try await notificationsNotificationValidation.normalizeNotification(request) })
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
}
