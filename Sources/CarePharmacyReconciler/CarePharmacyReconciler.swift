import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import GRPCNIOTransportHTTP2
import Logging

/// Command pharmacy-reconciler reconcilers pharmacy's records between the services that hold them.
@main
enum CarePharmacyReconciler {
    static func main() async throws {
        let settings = Settings()
        let logger = Logger(label: "acme.pharmacyreconciler")
        try await withGRPCClient(
            transport: .http2NIOPosix(
                target: .dns(host: settings.meshHost, port: try settings.port(settings.meshPort)),
                transportSecurity: .plaintext
            ),
            interceptors: [MeshCredentials(settings: settings, token: settings.token)]
        ) { mesh in
            var failed = 0
            do {
                try await CarryPatientID.run(mesh)
            } catch {
                logger.error("carry patient id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await HandOffPatientReportsMessage.run(mesh)
            } catch {
                logger.error("hand off patient reports message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RouteCarePlanApprovalID.run(mesh)
            } catch {
                logger.error("route care plan approval id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CopyPatientHomeCatalogToken.run(mesh)
            } catch {
                logger.error("copy patient home catalog token failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await BackfillAllergiesKind.run(mesh)
            } catch {
                logger.error("backfill allergies kind failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CarryVideoVisitTitle.run(mesh)
            } catch {
                logger.error("carry video visit title failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SettleSoftwareLicenseMessage.run(mesh)
            } catch {
                logger.error("settle software license message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SettleBoxOfficeSaleNumber.run(mesh)
            } catch {
                logger.error("settle box office sale number failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ExportUserID.run(mesh)
            } catch {
                logger.error("export user id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SettleMedicationsStatus.run(mesh)
            } catch {
                logger.error("settle medications status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await PropagateTriageDecisionID.run(mesh)
            } catch {
                logger.error("propagate triage decision id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await PushCarePlanStatus.run(mesh)
            } catch {
                logger.error("push care plan status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SettleMedicationExpiryStatus.run(mesh)
            } catch {
                logger.error("settle medication expiry status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await PushAppointmentID.run(mesh)
            } catch {
                logger.error("push appointment id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ExportAppointmentsTimezone.run(mesh)
            } catch {
                logger.error("export appointments timezone failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ForwardTriageCode.run(mesh)
            } catch {
                logger.error("forward triage code failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RouteLedgerAccountRulesID.run(mesh)
            } catch {
                logger.error("route ledger account rules id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SyncConfigSetID.run(mesh)
            } catch {
                logger.error("sync config set id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ReplayUsersToken.run(mesh)
            } catch {
                logger.error("replay users token failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await HandOffPatientHomeUpdatesID.run(mesh)
            } catch {
                logger.error("hand off patient home updates id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CopyRefillWorkflowStatus.run(mesh)
            } catch {
                logger.error("copy refill workflow status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CopyConcessionStandOptionsCode.run(mesh)
            } catch {
                logger.error("copy concession stand options code failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CopyCollectionCaseStatus.run(mesh)
            } catch {
                logger.error("copy collection case status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CopyAccessPoliciesMessage.run(mesh)
            } catch {
                logger.error("copy access policies message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RelayLedgerAccountID.run(mesh)
            } catch {
                logger.error("relay ledger account id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ReplayPrescriptionOptionsCode.run(mesh)
            } catch {
                logger.error("replay prescription options code failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ExportAppointmentsStatus.run(mesh)
            } catch {
                logger.error("export appointments status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ReplayLedgerAccountEligibilityCode.run(mesh)
            } catch {
                logger.error("replay ledger account eligibility code failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await BackfillTriageApprovalStatusSubject.run(mesh)
            } catch {
                logger.error("backfill triage approval status subject failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ReplayVisitNoteDecisionStatus.run(mesh)
            } catch {
                logger.error("replay visit note decision status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await PushPerformerMessage.run(mesh)
            } catch {
                logger.error("push performer message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RouteClinicSlotsID.run(mesh)
            } catch {
                logger.error("route clinic slots id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ExportNotificationID.run(mesh)
            } catch {
                logger.error("export notification id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await MirrorBroadcastsID.run(mesh)
            } catch {
                logger.error("mirror broadcasts id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await PushRateLimitRatesDescription.run(mesh)
            } catch {
                logger.error("push rate limit rates description failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await PropagateSearchIndexName.run(mesh)
            } catch {
                logger.error("propagate search index name failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await HandOffPaymentCalculationNotes.run(mesh)
            } catch {
                logger.error("hand off payment calculation notes failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SyncProviderApprovalStatusID.run(mesh)
            } catch {
                logger.error("sync provider approval status id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ForwardPatientHomeWorkflowID.run(mesh)
            } catch {
                logger.error("forward patient home workflow id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ReplayTelemetryReadingKind.run(mesh)
            } catch {
                logger.error("replay telemetry reading kind failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SyncPrescriptionID.run(mesh)
            } catch {
                logger.error("sync prescription id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await BackfillShowsID.run(mesh)
            } catch {
                logger.error("backfill shows id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RouteMedicationMessage.run(mesh)
            } catch {
                logger.error("route medication message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SettlePatientHomeWorkflowSubject.run(mesh)
            } catch {
                logger.error("settle patient home workflow subject failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RelayPatientID.run(mesh)
            } catch {
                logger.error("relay patient id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await MirrorJobOpeningsStatus.run(mesh)
            } catch {
                logger.error("mirror job openings status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SettleClinicSlotWorkflowID.run(mesh)
            } catch {
                logger.error("settle clinic slot workflow id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            if failed > 0 {
                logger.error("Some jobs failed", metadata: ["failed": .stringConvertible(failed)])
            }
        }
    }
}
