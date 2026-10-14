import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import GRPCNIOTransportHTTP2
import Logging

/// Command caremgmt-replicator replicators caremgmt's records between the services that hold them.
@main
enum CareCaremgmtReplicator {
    static func main() async throws {
        let settings = Settings()
        let logger = Logger(label: "acme.caremgmtreplicator")
        try await withGRPCClient(
            transport: .http2NIOPosix(
                target: .dns(host: settings.meshHost, port: try settings.port(settings.meshPort)),
                transportSecurity: .plaintext
            ),
            interceptors: [MeshCredentials(settings: settings, token: settings.token)]
        ) { mesh in
            var failed = 0
            do {
                try await SettleExpenseReportID.run(mesh)
            } catch {
                logger.error("settle expense report id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CarryPatientStatus.run(mesh)
            } catch {
                logger.error("carry patient status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SettleConcessionStandCode.run(mesh)
            } catch {
                logger.error("settle concession stand code failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SettleCareGoalWorkflowID.run(mesh)
            } catch {
                logger.error("settle care goal workflow id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RelayCollectionCaseStatus.run(mesh)
            } catch {
                logger.error("relay collection case status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ReplayTriageApprovalStatus.run(mesh)
            } catch {
                logger.error("replay triage approval status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ReplayPayRunsMessage.run(mesh)
            } catch {
                logger.error("replay pay runs message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await MirrorPatientApprovalMessage.run(mesh)
            } catch {
                logger.error("mirror patient approval message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ReplayPaymentRatesNumber.run(mesh)
            } catch {
                logger.error("replay payment rates number failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CarryProviderMessage.run(mesh)
            } catch {
                logger.error("carry provider message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RouteTriageWorkflowID.run(mesh)
            } catch {
                logger.error("route triage workflow id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SyncBudgetsStatus.run(mesh)
            } catch {
                logger.error("sync budgets status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RouteShipmentsMessage.run(mesh)
            } catch {
                logger.error("route shipments message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RelayCarePlanMessage.run(mesh)
            } catch {
                logger.error("relay care plan message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SyncMedicationMessage.run(mesh)
            } catch {
                logger.error("sync medication message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await PropagateAuditEventsToken.run(mesh)
            } catch {
                logger.error("propagate audit events token failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await MirrorLedgerAccountCode.run(mesh)
            } catch {
                logger.error("mirror ledger account code failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RoutePatientID.run(mesh)
            } catch {
                logger.error("route patient id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await MirrorVisitNoteWorkflowID.run(mesh)
            } catch {
                logger.error("mirror visit note workflow id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RelayPatientsID.run(mesh)
            } catch {
                logger.error("relay patients id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RelayPatientCalculationStatus.run(mesh)
            } catch {
                logger.error("relay patient calculation status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CopySponsorsStatus.run(mesh)
            } catch {
                logger.error("copy sponsors status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CarryJobOpeningMessage.run(mesh)
            } catch {
                logger.error("carry job opening message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await BackfillClinicSlotID.run(mesh)
            } catch {
                logger.error("backfill clinic slot id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await PushTelemetryReadingsToken.run(mesh)
            } catch {
                logger.error("push telemetry readings token failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await HandOffStockItemID.run(mesh)
            } catch {
                logger.error("hand off stock item id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await BackfillBoxOfficeSaleNotes.run(mesh)
            } catch {
                logger.error("backfill box office sale notes failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ForwardTicketsID.run(mesh)
            } catch {
                logger.error("forward tickets id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await HandOffCareGoalID.run(mesh)
            } catch {
                logger.error("hand off care goal id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await HandOffVitalApprovalStatus.run(mesh)
            } catch {
                logger.error("hand off vital approval status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await BackfillChartOfAccountsesID.run(mesh)
            } catch {
                logger.error("backfill chart of accountses id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await PushArticlesMessage.run(mesh)
            } catch {
                logger.error("push articles message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await PropagatePatientStatus.run(mesh)
            } catch {
                logger.error("propagate patient status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RelayProductRatesID.run(mesh)
            } catch {
                logger.error("relay product rates id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RouteCarePlanNumber.run(mesh)
            } catch {
                logger.error("route care plan number failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CarryCareInboxesUri.run(mesh)
            } catch {
                logger.error("carry care inboxes uri failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SettleGetSurveysToken.run(mesh)
            } catch {
                logger.error("settle get surveys token failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ForwardFanSessionsToken.run(mesh)
            } catch {
                logger.error("forward fan sessions token failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ReplayMedicationsID.run(mesh)
            } catch {
                logger.error("replay medications id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await PushVisitNoteNotes.run(mesh)
            } catch {
                logger.error("push visit note notes failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SyncMetricSeriesesToken.run(mesh)
            } catch {
                logger.error("sync metric serieses token failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await MirrorPendingPatientsMessage.run(mesh)
            } catch {
                logger.error("mirror pending patients message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CopyPrescriptionReportID.run(mesh)
            } catch {
                logger.error("copy prescription report id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SettleVideoVisitMessage.run(mesh)
            } catch {
                logger.error("settle video visit message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            if failed > 0 {
                logger.error("Some jobs failed", metadata: ["failed": .stringConvertible(failed)])
            }
        }
    }
}
