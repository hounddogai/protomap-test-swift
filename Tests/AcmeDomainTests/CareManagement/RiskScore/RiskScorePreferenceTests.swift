@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScorePreferenceTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newRiskScorePreference("code-14", name: "name-68")
        #expect(item.status == CareManagement.RiskScorePreferenceStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = CareManagement.newRiskScorePreference("code-14", name: "name-68")
        try item.moveTo(CareManagement.RiskScorePreferenceStatus.rejected)
        #expect(item.status == CareManagement.RiskScorePreferenceStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newRiskScorePreference("code-14", name: "name-68")
        item.status = CareManagement.RiskScorePreferenceStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RiskScorePreferenceStatus.proposed) }
    }
}
