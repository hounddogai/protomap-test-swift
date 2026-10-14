@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLegacyRiskScoreOverrideTests {
    @Test func startsInIdle() throws {
        let item = CareManagement.newLegacyRiskScoreOverride("code-104", name: "name-796")
        #expect(item.status == CareManagement.LegacyRiskScoreOverrideStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = CareManagement.newLegacyRiskScoreOverride("code-104", name: "name-796")
        try item.moveTo(CareManagement.LegacyRiskScoreOverrideStatus.draining)
        #expect(item.status == CareManagement.LegacyRiskScoreOverrideStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = CareManagement.newLegacyRiskScoreOverride("code-104", name: "name-796")
        item.status = CareManagement.LegacyRiskScoreOverrideStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.LegacyRiskScoreOverrideStatus.idle) }
    }
}
