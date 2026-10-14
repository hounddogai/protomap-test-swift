import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import GRPCNIOTransportHTTP2
import Logging

/// Command clinicalops-sync syncs clinicalops's records between the services that hold them.
@main
enum CareClinicalopsSync {
    static func main() async throws {
        let settings = Settings()
        let logger = Logger(label: "acme.clinicalopssync")
        try await withGRPCClient(
            transport: .http2NIOPosix(
                target: .dns(host: settings.meshHost, port: try settings.port(settings.meshPort)),
                transportSecurity: .plaintext
            ),
            interceptors: [MeshCredentials(settings: settings, token: settings.token)]
        ) { mesh in
            var failed = 0
            do {
                try await SyncFeatureFlagDecisionName.run(mesh)
            } catch {
                logger.error("sync feature flag decision name failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await PushMedicalRecordsID.run(mesh)
            } catch {
                logger.error("push medical records id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await PropagateMedicationID.run(mesh)
            } catch {
                logger.error("propagate medication id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RelayPrescriptionsNumber.run(mesh)
            } catch {
                logger.error("relay prescriptions number failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ForwardPatientHomeWorkflowSubject.run(mesh)
            } catch {
                logger.error("forward patient home workflow subject failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await PropagateVideoVisitStatus.run(mesh)
            } catch {
                logger.error("propagate video visit status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await PropagateCareGoalWorkflowStatus.run(mesh)
            } catch {
                logger.error("propagate care goal workflow status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RouteCareInboxSourcesMessage.run(mesh)
            } catch {
                logger.error("route care inbox sources message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ReplayMedicationID.run(mesh)
            } catch {
                logger.error("replay medication id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SettleLedgerAccountID.run(mesh)
            } catch {
                logger.error("settle ledger account id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CopyVitalWorkflowID.run(mesh)
            } catch {
                logger.error("copy vital workflow id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await BackfillAllergyReportMessage.run(mesh)
            } catch {
                logger.error("backfill allergy report message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await PropagateGetAppointmentsID.run(mesh)
            } catch {
                logger.error("propagate get appointments id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CopyMetricSeriesDecisionCode.run(mesh)
            } catch {
                logger.error("copy metric series decision code failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CarryVenuesID.run(mesh)
            } catch {
                logger.error("carry venues id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CopyVenueStatus.run(mesh)
            } catch {
                logger.error("copy venue status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RelayBoxOfficeSaleID.run(mesh)
            } catch {
                logger.error("relay box office sale id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await HandOffShowsID.run(mesh)
            } catch {
                logger.error("hand off shows id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await HandOffVideoVisitID.run(mesh)
            } catch {
                logger.error("hand off video visit id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CopyDocumentMessage.run(mesh)
            } catch {
                logger.error("copy document message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SyncPatientHomeWorkflowMessage.run(mesh)
            } catch {
                logger.error("sync patient home workflow message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CarryCarePlansMessage.run(mesh)
            } catch {
                logger.error("carry care plans message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SettleConcessionStandCalculationStatus.run(mesh)
            } catch {
                logger.error("settle concession stand calculation status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await HandOffSponsorStatus.run(mesh)
            } catch {
                logger.error("hand off sponsor status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ExportMetricSeriesesUri.run(mesh)
            } catch {
                logger.error("export metric serieses uri failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RelayTriageSubject.run(mesh)
            } catch {
                logger.error("relay triage subject failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SyncIncidentOptionsCode.run(mesh)
            } catch {
                logger.error("sync incident options code failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await BackfillCarePlanWorkflowNumber.run(mesh)
            } catch {
                logger.error("backfill care plan workflow number failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await BackfillPipelineCalculationID.run(mesh)
            } catch {
                logger.error("backfill pipeline calculation id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await HandOffPatientHomeMessage.run(mesh)
            } catch {
                logger.error("hand off patient home message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ReplayExpenseReportsMessage.run(mesh)
            } catch {
                logger.error("replay expense reports message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await BackfillMedicalRecordID.run(mesh)
            } catch {
                logger.error("backfill medical record id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RelayMedicationTotalsID.run(mesh)
            } catch {
                logger.error("relay medication totals id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SettlePrescriptionConflictsToken.run(mesh)
            } catch {
                logger.error("settle prescription conflicts token failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await PushMedicationCode.run(mesh)
            } catch {
                logger.error("push medication code failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ExportAppointmentWorkflowMessage.run(mesh)
            } catch {
                logger.error("export appointment workflow message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await BackfillMedicalRecordConflictStatus.run(mesh)
            } catch {
                logger.error("backfill medical record conflict status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await PropagateAccessPolicyName.run(mesh)
            } catch {
                logger.error("propagate access policy name failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await BackfillTriageWorkflowMessage.run(mesh)
            } catch {
                logger.error("backfill triage workflow message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SettleBoxOfficeSaleMessage.run(mesh)
            } catch {
                logger.error("settle box office sale message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RelayPatientDecisionStatus.run(mesh)
            } catch {
                logger.error("relay patient decision status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await BackfillMetricSeriesID.run(mesh)
            } catch {
                logger.error("backfill metric series id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await MirrorAllergySource.run(mesh)
            } catch {
                logger.error("mirror allergy source failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RouteDeliveriesMessage.run(mesh)
            } catch {
                logger.error("route deliveries message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CopyShowID.run(mesh)
            } catch {
                logger.error("copy show id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SettleCareGoalID.run(mesh)
            } catch {
                logger.error("settle care goal id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ForwardPrescriptionRatesID.run(mesh)
            } catch {
                logger.error("forward prescription rates id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ExportVideoVisitWorkflowTitle.run(mesh)
            } catch {
                logger.error("export video visit workflow title failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await MirrorUserID.run(mesh)
            } catch {
                logger.error("mirror user id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await BackfillFulfillmentsStatus.run(mesh)
            } catch {
                logger.error("backfill fulfillments status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            if failed > 0 {
                logger.error("Some jobs failed", metadata: ["failed": .stringConvertible(failed)])
            }
        }
    }
}
