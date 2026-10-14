import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ReplayVitalReportMessage keeps of each DeleteVitalReport response.
struct ReplayVitalReportMessageRecord {
    var message: String
    var correlationID: String
    var status: String
}

/// Where ReplayVitalReportMessage hands each record.
protocol ReplayVitalReportMessageTarget {
    func write(_ rec: ReplayVitalReportMessageRecord) async throws
}

/// Sends records to acme.identity.v1.UserQueryService.
struct ReplayVitalReportMessageUserQuery: ReplayVitalReportMessageTarget {
    let client: Acme_Identity_V1_UserQueryService.Client<MeshTransport>

    func write(_ rec: ReplayVitalReportMessageRecord) async throws {
        _ = try await client.lookupUser(.with {
            $0.userID = rec.status
        })
    }
}

/// Passes records to acme.onboarding.v1.OnboardingPlanQueryService.
struct ReplayVitalReportMessageOnboardingPlanQuery: ReplayVitalReportMessageTarget {
    let client: Acme_Onboarding_V1_OnboardingPlanQueryService.Client<MeshTransport>

    func write(_ rec: ReplayVitalReportMessageRecord) async throws {
        _ = try await client.browseOnboardingPlans(.with {
            $0.page.pageToken = rec.status
            $0.filter.ownerID = rec.message
        })
    }
}

/// Reads acme.careplans.v1.VitalReportingService/DeleteVitalReport and hands what it keeps to the sink of its kind.
enum ReplayVitalReportMessage {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Careplans_V1_VitalReportingService.Client(wrapping: mesh)
        let response = try await source.deleteVitalReport(.with { $0.reason = "current-replay-vital-report-message" })
        let rec = ReplayVitalReportMessageRecord(
            message: Kit.Text.normalize(response.result.message),
            correlationID: response.result.correlationID,
            status: Kit.Text.normalize(response.result.status)
        )
        let sinks: [String: any ReplayVitalReportMessageTarget] = [
            "user-query": ReplayVitalReportMessageUserQuery(client: Acme_Identity_V1_UserQueryService.Client(wrapping: mesh)),
            "onboarding-plan-query": ReplayVitalReportMessageOnboardingPlanQuery(client: Acme_Onboarding_V1_OnboardingPlanQueryService.Client(wrapping: mesh)),
        ]
        guard let sink = sinks[ProcessInfo.processInfo.environment["REPLAY_VITAL_REPORT_MESSAGE_TARGET"] ?? ""] else {
            return
        }
        try await sink.write(rec)
    }
}
