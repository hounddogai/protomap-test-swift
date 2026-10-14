@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreBundleTests {
    @Test func startsInIdle() throws {
        let item = CareManagement.newRiskScoreBundle("code-872", name: "name-280")
        #expect(item.status == CareManagement.RiskScoreBundleStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = CareManagement.newRiskScoreBundle("code-872", name: "name-280")
        try item.moveTo(CareManagement.RiskScoreBundleStatus.warming)
        #expect(item.status == CareManagement.RiskScoreBundleStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = CareManagement.newRiskScoreBundle("code-872", name: "name-280")
        item.status = CareManagement.RiskScoreBundleStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RiskScoreBundleStatus.idle) }
    }
}
