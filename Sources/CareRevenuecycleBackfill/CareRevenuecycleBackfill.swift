import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import GRPCNIOTransportHTTP2
import Logging

/// Command revenuecycle-backfill backfills revenuecycle's records between the services that hold them.
@main
enum CareRevenuecycleBackfill {
    static func main() async throws {
        let settings = Settings()
        let logger = Logger(label: "acme.revenuecyclebackfill")
        try await withGRPCClient(
            transport: .http2NIOPosix(
                target: .dns(host: settings.meshHost, port: try settings.port(settings.meshPort)),
                transportSecurity: .plaintext
            ),
            interceptors: [MeshCredentials(settings: settings, token: settings.token)]
        ) { mesh in
            var failed = 0
            do {
                try await CarryAllergyWorkflowID.run(mesh)
            } catch {
                logger.error("carry allergy workflow id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await PushBroadcastsToken.run(mesh)
            } catch {
                logger.error("push broadcasts token failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await HandOffSearchIndexID.run(mesh)
            } catch {
                logger.error("hand off search index id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RouteProductMessage.run(mesh)
            } catch {
                logger.error("route product message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ExportVisitNoteLifecycleNumber.run(mesh)
            } catch {
                logger.error("export visit note lifecycle number failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await PushDocumentNumber.run(mesh)
            } catch {
                logger.error("push document number failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RouteIncidentsID.run(mesh)
            } catch {
                logger.error("route incidents id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SettleLoanApplicationOptionsNumber.run(mesh)
            } catch {
                logger.error("settle loan application options number failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RouteSeatMapID.run(mesh)
            } catch {
                logger.error("route seat map id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RelayPrescriptionNotes.run(mesh)
            } catch {
                logger.error("relay prescription notes failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RelayTriageSubject.run(mesh)
            } catch {
                logger.error("relay triage subject failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ExportIncidentRatesID.run(mesh)
            } catch {
                logger.error("export incident rates id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SyncSearchIndexID.run(mesh)
            } catch {
                logger.error("sync search index id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ExportAudienceID.run(mesh)
            } catch {
                logger.error("export audience id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ExportRateLimitOptionsID.run(mesh)
            } catch {
                logger.error("export rate limit options id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await BackfillGetBenefitPlansToken.run(mesh)
            } catch {
                logger.error("backfill get benefit plans token failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await PushProductName.run(mesh)
            } catch {
                logger.error("push product name failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CopyProvidersStatus.run(mesh)
            } catch {
                logger.error("copy providers status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await BackfillReviewsTimezone.run(mesh)
            } catch {
                logger.error("backfill reviews timezone failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CarryVideoVisitsTitle.run(mesh)
            } catch {
                logger.error("carry video visits title failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SettleClinicSlotStatus.run(mesh)
            } catch {
                logger.error("settle clinic slot status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CopyGetDocumentsToken.run(mesh)
            } catch {
                logger.error("copy get documents token failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CopyVitalID.run(mesh)
            } catch {
                logger.error("copy vital id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await PushRecommendationSetNotes.run(mesh)
            } catch {
                logger.error("push recommendation set notes failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await PropagateBroadcastsID.run(mesh)
            } catch {
                logger.error("propagate broadcasts id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await PushCorporateEventsStatus.run(mesh)
            } catch {
                logger.error("push corporate events status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SyncCashPositionID.run(mesh)
            } catch {
                logger.error("sync cash position id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CarrySearchIndexesID.run(mesh)
            } catch {
                logger.error("carry search indexes id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ReplayCertificateID.run(mesh)
            } catch {
                logger.error("replay certificate id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RelayVitalID.run(mesh)
            } catch {
                logger.error("relay vital id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SettleProviderID.run(mesh)
            } catch {
                logger.error("settle provider id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CarryRateLimitCode.run(mesh)
            } catch {
                logger.error("carry rate limit code failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await HandOffPatientConflictsMessage.run(mesh)
            } catch {
                logger.error("hand off patient conflicts message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RoutePatientHomeWorkflowID.run(mesh)
            } catch {
                logger.error("route patient home workflow id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await MirrorTourStatus.run(mesh)
            } catch {
                logger.error("mirror tour status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CopyProductCalculationCode.run(mesh)
            } catch {
                logger.error("copy product calculation code failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RoutePromotionID.run(mesh)
            } catch {
                logger.error("route promotion id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await HandOffProductsMessage.run(mesh)
            } catch {
                logger.error("hand off products message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RelayAuditEventsToken.run(mesh)
            } catch {
                logger.error("relay audit events token failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ReplayFanSessionStatus.run(mesh)
            } catch {
                logger.error("replay fan session status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SyncRateLimitID.run(mesh)
            } catch {
                logger.error("sync rate limit id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SettleAllergyImportMessage.run(mesh)
            } catch {
                logger.error("settle allergy import message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RelayFeatureFlagID.run(mesh)
            } catch {
                logger.error("relay feature flag id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ExportFeatureFlagsToken.run(mesh)
            } catch {
                logger.error("export feature flags token failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            if failed > 0 {
                logger.error("Some jobs failed", metadata: ["failed": .stringConvertible(failed)])
            }
        }
    }
}
