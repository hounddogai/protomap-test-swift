import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import GRPCNIOTransportHTTP2
import Logging

/// Command labs-relay relays labs's records between the services that hold them.
@main
enum CareLabsRelay {
    static func main() async throws {
        let settings = Settings()
        let logger = Logger(label: "acme.labsrelay")
        try await withGRPCClient(
            transport: .http2NIOPosix(
                target: .dns(host: settings.meshHost, port: try settings.port(settings.meshPort)),
                transportSecurity: .plaintext
            ),
            interceptors: [MeshCredentials(settings: settings, token: settings.token)]
        ) { mesh in
            var failed = 0
            do {
                try await MirrorRefillMessage.run(mesh)
            } catch {
                logger.error("mirror refill message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CarryAppointmentWorkflowMessage.run(mesh)
            } catch {
                logger.error("carry appointment workflow message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await MirrorDeliveryNotes.run(mesh)
            } catch {
                logger.error("mirror delivery notes failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ExportPatientHomeFormID.run(mesh)
            } catch {
                logger.error("export patient home form id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ForwardCarePlanStatus.run(mesh)
            } catch {
                logger.error("forward care plan status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await PushCarePlanID.run(mesh)
            } catch {
                logger.error("push care plan id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await PropagateAdmissionID.run(mesh)
            } catch {
                logger.error("propagate admission id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CopyVitalID.run(mesh)
            } catch {
                logger.error("copy vital id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RelayVitalRulesID.run(mesh)
            } catch {
                logger.error("relay vital rules id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SettleNotificationsToken.run(mesh)
            } catch {
                logger.error("settle notifications token failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CopyNotificationSubject.run(mesh)
            } catch {
                logger.error("copy notification subject failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await PushCorporateEventsStatus.run(mesh)
            } catch {
                logger.error("push corporate events status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ReplayPatientHomeViewMessage.run(mesh)
            } catch {
                logger.error("replay patient home view message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SettlePerformersToken.run(mesh)
            } catch {
                logger.error("settle performers token failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CarryCarePlanID.run(mesh)
            } catch {
                logger.error("carry care plan id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ForwardVitalRatesID.run(mesh)
            } catch {
                logger.error("forward vital rates id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CarryBoxOfficeSaleID.run(mesh)
            } catch {
                logger.error("carry box office sale id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await PushPrescriptionWorkflowID.run(mesh)
            } catch {
                logger.error("push prescription workflow id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SettleProviderWorkflowID.run(mesh)
            } catch {
                logger.error("settle provider workflow id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RelayTriageExpiryStatus.run(mesh)
            } catch {
                logger.error("relay triage expiry status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ReplayRefillImportStatusSubject.run(mesh)
            } catch {
                logger.error("replay refill import status subject failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await BackfillVideoVisitTitle.run(mesh)
            } catch {
                logger.error("backfill video visit title failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ReplayOnboardingPlanID.run(mesh)
            } catch {
                logger.error("replay onboarding plan id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await PropagateClinicSlotID.run(mesh)
            } catch {
                logger.error("propagate clinic slot id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CopySearchIndexEligibilityID.run(mesh)
            } catch {
                logger.error("copy search index eligibility id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SyncArticleID.run(mesh)
            } catch {
                logger.error("sync article id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ExportAccessPoliciesMessage.run(mesh)
            } catch {
                logger.error("export access policies message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RouteFanSessionSubject.run(mesh)
            } catch {
                logger.error("route fan session subject failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ForwardPrescriptionWorkflowID.run(mesh)
            } catch {
                logger.error("forward prescription workflow id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await PushBoxOfficeSalesID.run(mesh)
            } catch {
                logger.error("push box office sales id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CopyUsersStatus.run(mesh)
            } catch {
                logger.error("copy users status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RouteFeatureFlagStatus.run(mesh)
            } catch {
                logger.error("route feature flag status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await HandOffUserEligibilityID.run(mesh)
            } catch {
                logger.error("hand off user eligibility id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ExportCareGoalCalculationMessage.run(mesh)
            } catch {
                logger.error("export care goal calculation message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await MirrorMedicalRecordConflictsMessage.run(mesh)
            } catch {
                logger.error("mirror medical record conflicts message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ForwardVisitNoteWorkflowStatus.run(mesh)
            } catch {
                logger.error("forward visit note workflow status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CarryAllergyRatesID.run(mesh)
            } catch {
                logger.error("carry allergy rates id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await PropagateShipmentNotes.run(mesh)
            } catch {
                logger.error("propagate shipment notes failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ForwardPrescriptionCode.run(mesh)
            } catch {
                logger.error("forward prescription code failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SyncDatasetsID.run(mesh)
            } catch {
                logger.error("sync datasets id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RelayStockItemMessage.run(mesh)
            } catch {
                logger.error("relay stock item message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RelayVideoVisitWorkflowMessage.run(mesh)
            } catch {
                logger.error("relay video visit workflow message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CarryMedicalRecordNotes.run(mesh)
            } catch {
                logger.error("carry medical record notes failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await BackfillCarePlansMessage.run(mesh)
            } catch {
                logger.error("backfill care plans message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SettleCareInboxWorkflowNumber.run(mesh)
            } catch {
                logger.error("settle care inbox workflow number failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ExportAppointmentsID.run(mesh)
            } catch {
                logger.error("export appointments id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RelayLedgerAccountCode.run(mesh)
            } catch {
                logger.error("relay ledger account code failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await PushShowID.run(mesh)
            } catch {
                logger.error("push show id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await BackfillVideoVisitWorkflowMessage.run(mesh)
            } catch {
                logger.error("backfill video visit workflow message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CopyRefillLifecycleID.run(mesh)
            } catch {
                logger.error("copy refill lifecycle id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ForwardVideoVisitOptionsID.run(mesh)
            } catch {
                logger.error("forward video visit options id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CarryAllergyWorkflowStatus.run(mesh)
            } catch {
                logger.error("carry allergy workflow status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await BackfillVisitNoteStatus.run(mesh)
            } catch {
                logger.error("backfill visit note status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ReplayVitalReportMessage.run(mesh)
            } catch {
                logger.error("replay vital report message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ReplayMedicalRecordNotes.run(mesh)
            } catch {
                logger.error("replay medical record notes failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            if failed > 0 {
                logger.error("Some jobs failed", metadata: ["failed": .stringConvertible(failed)])
            }
        }
    }
}
