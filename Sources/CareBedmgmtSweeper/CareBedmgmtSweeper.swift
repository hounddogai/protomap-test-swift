import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import GRPCNIOTransportHTTP2
import Logging

/// Command bedmgmt-sweeper sweepers bedmgmt's records between the services that hold them.
@main
enum CareBedmgmtSweeper {
    static func main() async throws {
        let settings = Settings()
        let logger = Logger(label: "acme.bedmgmtsweeper")
        try await withGRPCClient(
            transport: .http2NIOPosix(
                target: .dns(host: settings.meshHost, port: try settings.port(settings.meshPort)),
                transportSecurity: .plaintext
            ),
            interceptors: [MeshCredentials(settings: settings, token: settings.token)]
        ) { mesh in
            var failed = 0
            do {
                try await SettleFanSessionID.run(mesh)
            } catch {
                logger.error("settle fan session id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await MirrorVenueID.run(mesh)
            } catch {
                logger.error("mirror venue id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RelayGetAudiencesToken.run(mesh)
            } catch {
                logger.error("relay get audiences token failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await HandOffCareInboxTestNoticeID.run(mesh)
            } catch {
                logger.error("hand off care inbox test notice id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await BackfillGetArticlesStatus.run(mesh)
            } catch {
                logger.error("backfill get articles status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RelayCarePlansNotes.run(mesh)
            } catch {
                logger.error("relay care plans notes failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SyncMedicalRecordRulesNumber.run(mesh)
            } catch {
                logger.error("sync medical record rules number failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await PushVehicleStatus.run(mesh)
            } catch {
                logger.error("push vehicle status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await PropagateBudgetsID.run(mesh)
            } catch {
                logger.error("propagate budgets id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await MirrorPatientMessage.run(mesh)
            } catch {
                logger.error("mirror patient message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ReplayVitalEligibilityID.run(mesh)
            } catch {
                logger.error("replay vital eligibility id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CopyAllergiesID.run(mesh)
            } catch {
                logger.error("copy allergies id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SyncTourID.run(mesh)
            } catch {
                logger.error("sync tour id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SettleFeatureFlagStatus.run(mesh)
            } catch {
                logger.error("settle feature flag status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SettlePatientHomeTestNoticeSubject.run(mesh)
            } catch {
                logger.error("settle patient home test notice subject failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await PropagateVehiclesToken.run(mesh)
            } catch {
                logger.error("propagate vehicles token failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ForwardVideoVisitApprovalID.run(mesh)
            } catch {
                logger.error("forward video visit approval id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await BackfillCareGoalID.run(mesh)
            } catch {
                logger.error("backfill care goal id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await PushAppointmentID.run(mesh)
            } catch {
                logger.error("push appointment id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SyncNotificationsStatus.run(mesh)
            } catch {
                logger.error("sync notifications status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CarryDispatchOrdersID.run(mesh)
            } catch {
                logger.error("carry dispatch orders id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await MirrorRefillReportMessage.run(mesh)
            } catch {
                logger.error("mirror refill report message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ReplayGetTicketsID.run(mesh)
            } catch {
                logger.error("replay get tickets id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await MirrorLoanApplicationRatesID.run(mesh)
            } catch {
                logger.error("mirror loan application rates id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await MirrorAllergiesStatus.run(mesh)
            } catch {
                logger.error("mirror allergies status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await PropagateDocumentMessage.run(mesh)
            } catch {
                logger.error("propagate document message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ExportPrescriptionsID.run(mesh)
            } catch {
                logger.error("export prescriptions id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ExportProviderWorkflowID.run(mesh)
            } catch {
                logger.error("export provider workflow id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ReplayAllergyWorkflowID.run(mesh)
            } catch {
                logger.error("replay allergy workflow id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await PropagateOnboardingPlansID.run(mesh)
            } catch {
                logger.error("propagate onboarding plans id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await SettleAppointmentWorkflowMessage.run(mesh)
            } catch {
                logger.error("settle appointment workflow message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await MirrorLedgerAccountsToken.run(mesh)
            } catch {
                logger.error("mirror ledger accounts token failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ReplaySearchIndexesStatus.run(mesh)
            } catch {
                logger.error("replay search indexes status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await HandOffProviderRulesMessage.run(mesh)
            } catch {
                logger.error("hand off provider rules message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await BackfillAllergyStatus.run(mesh)
            } catch {
                logger.error("backfill allergy status failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await RelayPrescriptionReportNotes.run(mesh)
            } catch {
                logger.error("relay prescription report notes failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await CarryCorporateEventMessage.run(mesh)
            } catch {
                logger.error("carry corporate event message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await MirrorMedicalRecordDecisionID.run(mesh)
            } catch {
                logger.error("mirror medical record decision id failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await ForwardAllergyOptionsCode.run(mesh)
            } catch {
                logger.error("forward allergy options code failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            do {
                try await PushCareGoalMessage.run(mesh)
            } catch {
                logger.error("push care goal message failed", metadata: ["error": .string("\(error)")])
                failed += 1
            }
            if failed > 0 {
                logger.error("Some jobs failed", metadata: ["failed": .stringConvertible(failed)])
            }
        }
    }
}
