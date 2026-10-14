@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreTierTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newRiskScoreTier("code-268", label: "label-263")
        #expect(item.status == CareManagement.RiskScoreTierStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = CareManagement.newRiskScoreTier("code-268", label: "label-263")
        try item.moveTo(CareManagement.RiskScoreTierStatus.running)
        #expect(item.status == CareManagement.RiskScoreTierStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newRiskScoreTier("code-268", label: "label-263")
        item.status = CareManagement.RiskScoreTierStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RiskScoreTierStatus.new) }
    }
}
