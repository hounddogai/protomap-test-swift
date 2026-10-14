import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import GRPCNIOTransportHTTP2
import Logging

/// Command staffing-exporter exporters staffing's records between the services that hold them.
@main
enum CareStaffingExporter {
    static func main() async throws {
        let settings = Settings()
        let logger = Logger(label: "acme.staffingexporter")
        try await withGRPCClient(
            transport: .http2NIOPosix(
                target: .dns(host: settings.meshHost, port: try settings.port(settings.meshPort)),
                transportSecurity: .plaintext
            ),
            interceptors: [MeshCredentials(settings: settings, token: settings.token)]
        ) { mesh in
            var failed = 0
            do {
                try await BackfillCareInboxEventsStatus.run(mesh)
            } catch {
                logger.error("backfill care inbox events status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await PropagateCarePlanExpiryNumber.run(mesh)
            } catch {
                logger.error("propagate care plan expiry number failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ForwardSearchIndexCode.run(mesh)
            } catch {
                logger.error("forward search index code failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await PushPendingTriagesToken.run(mesh)
            } catch {
                logger.error("push pending triages token failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SyncMedicationCode.run(mesh)
            } catch {
                logger.error("sync medication code failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await PropagateMedicalRecordWorkflowID.run(mesh)
            } catch {
                logger.error("propagate medical record workflow id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await HandOffCorporateEventsID.run(mesh)
            } catch {
                logger.error("hand off corporate events id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await PushPayRunsMessage.run(mesh)
            } catch {
                logger.error("push pay runs message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ReplayPrescriptionMessage.run(mesh)
            } catch {
                logger.error("replay prescription message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await HandOffPrescriptionApprovalNumber.run(mesh)
            } catch {
                logger.error("hand off prescription approval number failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CopyDocumentsStatus.run(mesh)
            } catch {
                logger.error("copy documents status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await MirrorAllergyImportStatusID.run(mesh)
            } catch {
                logger.error("mirror allergy import status id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await PropagateDispatchOrderStatus.run(mesh)
            } catch {
                logger.error("propagate dispatch order status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ExportVisitNoteOptionsID.run(mesh)
            } catch {
                logger.error("export visit note options id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RouteShipmentID.run(mesh)
            } catch {
                logger.error("route shipment id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await PropagatePrescriptionsID.run(mesh)
            } catch {
                logger.error("propagate prescriptions id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CarryGetAccessPoliciesStatus.run(mesh)
            } catch {
                logger.error("carry get access policies status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CopyVenuesMessage.run(mesh)
            } catch {
                logger.error("copy venues message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await HandOffFeatureFlagMessage.run(mesh)
            } catch {
                logger.error("hand off feature flag message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ReplayStockItemsID.run(mesh)
            } catch {
                logger.error("replay stock items id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CarryPrescriptionStatus.run(mesh)
            } catch {
                logger.error("carry prescription status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RelayRecommendationSetsStatus.run(mesh)
            } catch {
                logger.error("relay recommendation sets status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ForwardVideoVisitsID.run(mesh)
            } catch {
                logger.error("forward video visits id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SyncMedicalRecordNotes.run(mesh)
            } catch {
                logger.error("sync medical record notes failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ReplayAllergyRulesKind.run(mesh)
            } catch {
                logger.error("replay allergy rules kind failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await MirrorCareGoalsMessage.run(mesh)
            } catch {
                logger.error("mirror care goals message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SettleConfigSetName.run(mesh)
            } catch {
                logger.error("settle config set name failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await BackfillBoxOfficeSalesID.run(mesh)
            } catch {
                logger.error("backfill box office sales id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RelaySeatMapName.run(mesh)
            } catch {
                logger.error("relay seat map name failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await MirrorPatientHomeSubscriptionsID.run(mesh)
            } catch {
                logger.error("mirror patient home subscriptions id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await PropagateVisitNotesID.run(mesh)
            } catch {
                logger.error("propagate visit notes id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ReplayShowMessage.run(mesh)
            } catch {
                logger.error("replay show message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await HandOffAuditEventDecisionID.run(mesh)
            } catch {
                logger.error("hand off audit event decision id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await PropagateMedicalRecordsID.run(mesh)
            } catch {
                logger.error("propagate medical records id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CopyTriageWorkflowID.run(mesh)
            } catch {
                logger.error("copy triage workflow id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await MirrorCareInboxWorkflowMessage.run(mesh)
            } catch {
                logger.error("mirror care inbox workflow message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SyncPatientHomesStatus.run(mesh)
            } catch {
                logger.error("sync patient homes status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ForwardAllergySource.run(mesh)
            } catch {
                logger.error("forward allergy source failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await BackfillCareGoalsTimezone.run(mesh)
            } catch {
                logger.error("backfill care goals timezone failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ExportDispatchOrdersStatus.run(mesh)
            } catch {
                logger.error("export dispatch orders status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ReplayUserID.run(mesh)
            } catch {
                logger.error("replay user id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SettleMedicationReportTimezone.run(mesh)
            } catch {
                logger.error("settle medication report timezone failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ReplayCareInboxWatchersID.run(mesh)
            } catch {
                logger.error("replay care inbox watchers id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ForwardPrescriptionWorkflowID.run(mesh)
            } catch {
                logger.error("forward prescription workflow id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SettleConcessionStandsToken.run(mesh)
            } catch {
                logger.error("settle concession stands token failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            if failed > 0 {
                logger.error("Some jobs failed", metadata: ["failed": .stringConvertible(failed)])
            }
        }
    }
}
