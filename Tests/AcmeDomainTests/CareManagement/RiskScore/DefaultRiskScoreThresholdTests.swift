@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementDefaultRiskScoreThresholdTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newDefaultRiskScoreThreshold("code-633", title: "title-406")
        #expect(item.status == CareManagement.DefaultRiskScoreThresholdStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = CareManagement.newDefaultRiskScoreThreshold("code-633", title: "title-406")
        try item.moveTo(CareManagement.DefaultRiskScoreThresholdStatus.rejected)
        #expect(item.status == CareManagement.DefaultRiskScoreThresholdStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newDefaultRiskScoreThreshold("code-633", title: "title-406")
        item.status = CareManagement.DefaultRiskScoreThresholdStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.DefaultRiskScoreThresholdStatus.proposed) }
    }
}
