import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import GRPCNIOTransportHTTP2
import Logging

/// Command imaging-publisher publishers imaging's records between the services that hold them.
@main
enum CareImagingPublisher {
    static func main() async throws {
        let settings = Settings()
        let logger = Logger(label: "acme.imagingpublisher")
        try await withGRPCClient(
            transport: .http2NIOPosix(
                target: .dns(host: settings.meshHost, port: try settings.port(settings.meshPort)),
                transportSecurity: .plaintext
            ),
            interceptors: [MeshCredentials(settings: settings, token: settings.token)]
        ) { mesh in
            var failed = 0
            do {
                try await ForwardMedicalRecordEligibilityMessage.run(mesh)
            } catch {
                logger.error("forward medical record eligibility message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CopyPatientsStatus.run(mesh)
            } catch {
                logger.error("copy patients status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RelayDocumentsID.run(mesh)
            } catch {
                logger.error("relay documents id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await PushMedicationWorkflowMessage.run(mesh)
            } catch {
                logger.error("push medication workflow message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ForwardRefillStatus.run(mesh)
            } catch {
                logger.error("forward refill status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ForwardCarePlanStatus.run(mesh)
            } catch {
                logger.error("forward care plan status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ForwardPatientHomesToken.run(mesh)
            } catch {
                logger.error("forward patient homes token failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CarryPoliciesMessage.run(mesh)
            } catch {
                logger.error("carry policies message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await PropagateRefillOptionsMessage.run(mesh)
            } catch {
                logger.error("propagate refill options message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await MirrorComplianceCaseMessage.run(mesh)
            } catch {
                logger.error("mirror compliance case message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SettleDocumentID.run(mesh)
            } catch {
                logger.error("settle document id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SyncCareInboxWorkflowNotes.run(mesh)
            } catch {
                logger.error("sync care inbox workflow notes failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CarryRefillID.run(mesh)
            } catch {
                logger.error("carry refill id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CarryVehicleID.run(mesh)
            } catch {
                logger.error("carry vehicle id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await PropagateMedicalRecordReportID.run(mesh)
            } catch {
                logger.error("propagate medical record report id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await BackfillLoanApplicationNotes.run(mesh)
            } catch {
                logger.error("backfill loan application notes failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CarrySoftwareLicensesStatus.run(mesh)
            } catch {
                logger.error("carry software licenses status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SettleMedicalRecordSyncStateID.run(mesh)
            } catch {
                logger.error("settle medical record sync state id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RouteProviderWorkflowMessage.run(mesh)
            } catch {
                logger.error("route provider workflow message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SyncLoanApplicationNotes.run(mesh)
            } catch {
                logger.error("sync loan application notes failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RelayVitalDecisionID.run(mesh)
            } catch {
                logger.error("relay vital decision id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await MirrorVenueMessage.run(mesh)
            } catch {
                logger.error("mirror venue message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CopyIncidentID.run(mesh)
            } catch {
                logger.error("copy incident id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ForwardFanSessionsStatus.run(mesh)
            } catch {
                logger.error("forward fan sessions status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ForwardTicketNumber.run(mesh)
            } catch {
                logger.error("forward ticket number failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CopyMedicationCode.run(mesh)
            } catch {
                logger.error("copy medication code failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await HandOffFanSessionID.run(mesh)
            } catch {
                logger.error("hand off fan session id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ReplayAccessPolicyStatus.run(mesh)
            } catch {
                logger.error("replay access policy status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SettlePrescriptionMessage.run(mesh)
            } catch {
                logger.error("settle prescription message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ForwardReviewNumber.run(mesh)
            } catch {
                logger.error("forward review number failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CarryConcessionStandsStatus.run(mesh)
            } catch {
                logger.error("carry concession stands status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RelayPatientStatus.run(mesh)
            } catch {
                logger.error("relay patient status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CopyVideoVisitStatus.run(mesh)
            } catch {
                logger.error("copy video visit status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ReplayDocumentsStatus.run(mesh)
            } catch {
                logger.error("replay documents status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RelayToursMessage.run(mesh)
            } catch {
                logger.error("relay tours message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CopyVideoVisitID.run(mesh)
            } catch {
                logger.error("copy video visit id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RoutePatientHomeWorkflowsToken.run(mesh)
            } catch {
                logger.error("route patient home workflows token failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ExportFanSessionsStatus.run(mesh)
            } catch {
                logger.error("export fan sessions status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CopyVisitNoteCode.run(mesh)
            } catch {
                logger.error("copy visit note code failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ExportShowID.run(mesh)
            } catch {
                logger.error("export show id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CarryVitalSource.run(mesh)
            } catch {
                logger.error("carry vital source failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SettleMedicationID.run(mesh)
            } catch {
                logger.error("settle medication id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RouteNotificationsID.run(mesh)
            } catch {
                logger.error("route notifications id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await BackfillAuditEventID.run(mesh)
            } catch {
                logger.error("backfill audit event id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SyncConcessionStandID.run(mesh)
            } catch {
                logger.error("sync concession stand id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ReplayRefillID.run(mesh)
            } catch {
                logger.error("replay refill id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RelayCareInboxesID.run(mesh)
            } catch {
                logger.error("relay care inboxes id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CopyTicketsMessage.run(mesh)
            } catch {
                logger.error("copy tickets message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await PushVisitNoteStatus.run(mesh)
            } catch {
                logger.error("push visit note status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await BackfillSeatMapStatus.run(mesh)
            } catch {
                logger.error("backfill seat map status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RelayMedicationStatus.run(mesh)
            } catch {
                logger.error("relay medication status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            if failed > 0 {
                logger.error("Some jobs failed", metadata: ["failed": .stringConvertible(failed)])
            }
        }
    }
}
